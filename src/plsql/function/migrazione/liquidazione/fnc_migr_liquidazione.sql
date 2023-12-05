/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace function fnc_migr_liquidazione(
	enteproprietarioid integer,
    annobilancio varchar,
    loginoperazione varchar,
    dataelaborazione timestamp,
    idmin integer,
    idmax integer,
    out numerorecordinseriti integer,
    out messaggiorisultato varchar)
RETURNS record AS
$body$
DECLARE

   -- fnc_migr_liquidazione --> function che effettua il caricamento delle liquidazioni da migrare.
   -- leggendo da migr_liquidazione
   -- effettua inserimento di
	-- siac_t_liquidazione : tabella principale
	-- siac_r_liquidazione_soggetto: tabella di relazione liquidazione / soggetto. Dal soggetto individuato viene recuperata la mdp
    								 -- (nel caso in cui il soggetto ne abbia + d'una viene sceta quella di priorit? pi? alta (ricerca su siac_r_modpag_ordine)

	-- siac_r_liquidazione_stato: definizione dello stato della liquidazione
	-- siac_r_liquidazione_atto_amm: relazione tra liquidazione e attoamministrativo: vale sempre la regola secondo cui se l'atto non ? ancora presente viene inserito.
	-- siac_r_liquidazione_movgest: relazione tra liquidazione e attoamministrativo: vale sempre la regola secondo cui se l'atto non ? ancora presente viene inserito.
    -- siac_r_mutuo_voce_lliquidazione: relazione tra voce di mutuo e liquidazione. La voce di mutuo viene ricercata tra quelle migrate per
    	-- numero impegno,  anno impegno, anno esercizio, nro mutuo.

     -- richiama
     -- fnc_migr_attoamm per
        --  il caricamento di atto amministrativo <classificatore tipo CDR > ( impegno, subimpegno)
     -- fnc_get_bilancio -> per l'anno bilancio passato in input restituisce l'id della siac_t_bil

    -- restituisce
     -- messaggioRisultato valorizzato con il risultato della elaborazione in formato testo
     -- numerorecordinseriti valorizzato con
        -- -12 migr_liquidazione vuota
        -- -13 id bilancio non recuperato per l'anno passato in input.
        -- -1 errore
        -- N=numero record inseriti

    -- Punti di attenzione
     -- Atto Amministrativo
       -- si controlla esistenza di atto proveniente dal sistema di origine
       -- se esiste lo si utilizza per collegarlo alla liquidazione
       -- se non esiste lo si inserisce

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
    strMessaggioScarto VARCHAR(1500):='';
    strDettaglioScarto VARCHAR(1500):='';
    countRecordDaMigrare integer := 0;
    countRecordInseriti integer := 0;
    scarto integer := 0; -- 1 se esiste uno scarto per il numero_liquidazione da migrare, 0 se non esiste quindi viene inserito durante questa elaborazione.

	migrRecord RECORD;
    migrAttoAmm record;
    aggProgressivi record;

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
	--dataInizioVal timestamp :=annoBilancio||'-01-01';
	dataInizioVal timestamp :=null;

    recId varchar(100) :='';
    bilancioId INTEGER := 0; --pk tabella siac_t_bil
    soggettoId INTEGER := 0; --pk tabella siac_t_soggetto
    mdpId INTEGER := 0;	     --pk tabella siac_t_mdp
    soggettoRelazId integer:=0;
    movGestId  INTEGER := 0;
    movgestTsId INTEGER := 0;
    movGestTipoId INTEGER := 0;
    movGestTsTipoId_T INTEGER := 0;
    movGestTsTipoId_S INTEGER := 0;
    attoAmmId INTEGER:= 0;
    mutVoceId INTEGER:= 0;
    statoId INTEGER := 0;
    classif_siope_code varchar(50) :=''; -- 20.11.2015 Davide gestione siope

    SPR                   CONSTANT varchar:='SPR||';
	NVL_STR               CONSTANT VARCHAR:='';
    MOVGEST_IMPEGNO		  CONSTANT varchar:='I';  -- codice da ricercare  nella tabella siac_d_movgest_tipo
	MOVGEST_TS_IMPEGNI    CONSTANT varchar:='T';  -- codice da ricercare  nella tabella siac_d_movgest_ts_tipo
	MOVGEST_TS_SUBIMP     CONSTANT varchar:='S';  -- codice da ricercare  nella tabella siac_d_movgest_ts_tipo
    PDC_FIN_V_LIV         CONSTANT varchar:='PDC_V';
    GRUPPO_COFOG          CONSTANT varchar:='GRUPPO_COFOG';
    LIQAUTOMATICA 		  CONSTANT varchar:='N';
--    LIQCONVALIDA_MANUALE  CONSTANT varchar:='M';
    LIQCONVALIDA_MANUALE  CONSTANT varchar:= NULL; -- 28.12.2015 non impostato
	CL_SIOPE              CONSTANT varchar:='SIOPE_SPESA_I'; -- 20.11.2015 Davide gestione siope
    SIOPECOD_DEF          CONSTANT varchar :='XXXX';         -- 27.11.2015 Davide gestione siope

    liqId INTEGER := 0; -- pk tab. siac_t_liquidazione
	idClass_pdc integer:= 0;
	idClass_cofog integer:= 0;
	idClass_siope integer:= 0;                               -- 20.11.2015 Davide gestione siope

	mmdp_id integer := 0;
    mmdp_sede_secondaria VARCHAR(1):= null;
    mmdp_cessione VARCHAR(20):= null;
    migr_modpag_id_principale integer := 0;
    modpag_id_principale integer := 0;
    soggetto_id_principale integer := 0;
    migr_soggetto_id_principale integer := 0;
    migr_modpag_id_altra integer := 0;
    modpag_id_altra  integer := 0;
    soggetto_id_altro integer := 0;

BEGIN
    numerorecordinseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione liquidazioni.';

    -- lettura id bilancio
    -- COTO 1 - 16
	strMessaggio:='Lettura id bilancio per anno '||annoBilancio||'.';
    select bilancio.idbilancio, bilancio.messaggiorisultato into bilancioid,messaggioRisultato
	from fnc_get_bilancio(enteProprietarioId,annoBilancio) bilancio;
	if (bilancioid=-1) then
		messaggioRisultato:=strMessaggioFinale||messaggioRisultato;
		numerorecordinseriti:=-13;
		return;
	end if;

    strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_IMPEGNO||'.';
    -- Per coto, id 1 = 1
    select d.movgest_tipo_id into strict movGestTipoId
    from siac_d_movgest_tipo d
    where d.ente_proprietario_id=enteproprietarioid
    and d.movgest_tipo_code = MOVGEST_IMPEGNO
    and d.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                or d.validita_fine is null);

	begin
    	 strMessaggio:='Lettura record da migrare.';
         select distinct 1 into strict countRecordDaMigrare from migr_liquidazione m
         inner join siac_t_movgest mov on (
                                    mov.ente_proprietario_id=m.ente_proprietario_id
                                    and mov.bil_id=bilancioid--16
                                    and mov.movgest_tipo_id=movGestTipoId--1
                                    and mov.movgest_anno = m.anno_impegno::INTEGER
                                    and mov.movgest_numero= m.numero_impegno::NUMERIC
                                    and mov.data_cancellazione is null and
                                          date_trunc('day',dataelaborazione)>=date_trunc('day',mov.validita_inizio) and
                                          (date_trunc('day',dataelaborazione)<=date_trunc('day',mov.validita_fine)
                                              or mov.validita_fine is null))
          where m.ente_proprietario_id=enteProprietarioId and m.fl_elab='N'
          and m.migr_liquidazione_id >= idmin and m.migr_liquidazione_id <= idmax;
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||', idmin '||idmin||', idmax '||idmax||'.';
		 numerorecordinseriti:=-12;
		 return;
	end;

    -- variabili usate nel ciclo che devono essere presenti sul sistema.
    begin
    	strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_TS_IMPEGNI||'.';
    	select d.movgest_ts_tipo_id into strict movGestTsTipoId_T
        from siac_d_movgest_ts_tipo d
        where d.ente_proprietario_id=enteproprietarioid
        and d.movgest_ts_tipo_code = MOVGEST_TS_IMPEGNI
		and d.data_cancellazione is null and
              	date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
                (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                    or d.validita_fine is null);

    	strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_TS_SUBIMP||'.';
    	select d.movgest_ts_tipo_id into strict movGestTsTipoId_S
        from siac_d_movgest_ts_tipo d
        where d.ente_proprietario_id=enteproprietarioid
        and d.movgest_ts_tipo_code = MOVGEST_TS_SUBIMP
		and d.data_cancellazione is null and
              	date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
                (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                    or d.validita_fine is null);

	    strMessaggio:='Lettura classificatore tipo_code '||PDC_FIN_V_LIV||'.';
        select tipoPdcFin.classif_tipo_id into strict idClass_pdc
        from siac_d_class_tipo tipoPdcFin
              where tipoPdcFin.ente_proprietario_id=enteProprietarioId
              and tipoPdcFin.classif_tipo_code=PDC_FIN_V_LIV
              and tipoPdcFin.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine)
                        or tipoPdcFin.validita_fine is null);

		strMessaggio:='Lettura classificatore tipo_code '||GRUPPO_COFOG||'.';
        select tipoCofog.classif_tipo_id into strict idClass_cofog
        from siac_d_class_tipo tipoCofog
              where tipoCofog.ente_proprietario_id=enteProprietarioId and
                    tipoCofog.classif_tipo_code=GRUPPO_COFOG
                    and tipoCofog.data_cancellazione is null and
                    date_trunc('day',dataElaborazione)>=date_trunc('day',tipoCofog.validita_inizio) and
                    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoCofog.validita_fine)
                       or tipoCofog.validita_fine is null);

		-- 20.11.2015 Davide gestione siope
		strMessaggio:='Lettura classificatore tipo_code '||CL_SIOPE||'.';
        select tipoSiope.classif_tipo_id into strict idClass_siope
        from siac_d_class_tipo tipoSiope
              where tipoSiope.ente_proprietario_id=enteProprietarioId and
                    tipoSiope.classif_tipo_code=CL_SIOPE
                    and tipoSiope.data_cancellazione is null and
                    date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSiope.validita_inizio) and
                    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoSiope.validita_fine)
                       or tipoSiope.validita_fine is null);

	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||strMessaggio||' NO_DATA_FOUND per ente '||enteProprietarioId||'.';
		 numerorecordinseriti:=-1;
		 return;
        when TOO_MANY_ROWS then
		 messaggioRisultato:=strMessaggioFinale||strMessaggio||' TOO_MANY_ROWS per ente '||enteProprietarioId||'.';
		 numerorecordinseriti:=-1;
		 return;
    end;

    for migrRecord IN
        (
         -- consideriamo i soli casi per cui il soggetto ed il movimento relativi sono stati migrati
         -- 26.05.2015 consideriamo i soli casi per cui il movimento relativi sono stati migrati
		select m.*, mov.movgest_id
         from migr_liquidazione m
		 inner join siac_t_movgest mov on (
          							mov.ente_proprietario_id=m.ente_proprietario_id
          							and mov.bil_id=bilancioid--16
          							and mov.movgest_tipo_id=movGestTipoId--1
                                    and mov.movgest_anno = m.anno_impegno::INTEGER
                                    and mov.movgest_numero= m.numero_impegno::NUMERIC
                                    and mov.data_cancellazione is null and
                                          date_trunc('day',dataelaborazione)>=date_trunc('day',mov.validita_inizio) and
                                          (date_trunc('day',dataelaborazione)<=date_trunc('day',mov.validita_fine)
                                              or mov.validita_fine is null))
		-- condizioni restrizione record da migrare
         where m.ente_proprietario_id=enteproprietarioid
               and m.fl_elab='N'
               and m.migr_liquidazione_id >= idmin and m.migr_liquidazione_id <= idmax
         order by m.migr_liquidazione_id
		)
    LOOP
   	     strDettaglioScarto := null;
		 strMessaggioScarto := null;

         liqId := 0;
         soggettoId := null;
         mdpId := null;
         soggettoRelazId:=null;
         movgestTsId := null;
         attoAmmId := 0;
         mutVoceId := null;
         scarto := 0;

         mmdp_id := 0;
         mmdp_sede_secondaria := null;
         mmdp_cessione := null;
	     migr_modpag_id_principale := 0;
         modpag_id_principale := 0;
 		 soggetto_id_principale := 0;
         migr_soggetto_id_principale := 0;
         migr_modpag_id_altra := 0;
         modpag_id_altra  := 0;
         soggetto_id_altro := 0;

         recId := migrRecord.migr_liquidazione_id ||'/'||migrRecord.numero_liquidazione||'/'||migrRecord.anno_esercizio||'.';

         -- Alcuni enti passano la mdp definita nella liquidazione (REGP) alcuni non per tutte le liquidazioni (COTO), altri per nessuna (PVTO)
         if migrRecord.codice_progben is null THEN

         	if migrRecord.sede_id is not null and migrRecord.sede_id>0 then
	            strMessaggio:='Ricerca idSoggetto per sede secondaria codice: '||migrRecord.sede_id||'.';
                select sr.soggetto_id_a into soggettoId
                from
                migr_sede_secondaria mss, siac_r_migr_sede_secondaria_rel_sede rss, siac_r_soggetto_relaz sr
                 where
                 mss.ente_proprietario_id = enteproprietarioid
                 and mss.sede_id=migrRecord.sede_id
                 and rss.migr_sede_id=mss.migr_sede_id
                 and rss.soggetto_relaz_id=sr.soggetto_relaz_id;
            else
              strMessaggio:='Ricerca soggetto per codice: '||migrRecord.codice_soggetto||'.';
              -- esclusione dei delegati nella ricerca del soggetto
              -- considerata la mdp con maggiore priorit? nel caso ce ne sia + d'una.
              -- soggetto
              select sogg.soggetto_id into soggettoId
              from siac_t_soggetto sogg,siac_r_migr_soggetto_soggetto r
              where sogg.soggetto_code = migrRecord.codice_soggetto::varchar
              and   sogg.ente_proprietario_id = enteproprietarioid
              and   sogg.data_cancellazione is null
              and date_trunc('day',dataElaborazione)>=date_trunc('day',sogg.validita_inizio)
              and (date_trunc('day',dataElaborazione)<date_trunc('day',sogg.validita_fine) or sogg.validita_fine is null)
              and r.ente_proprietario_id= sogg.ente_proprietario_id
              and r.soggetto_id=sogg.soggetto_id;
            end if;
            if soggettoId is null then
              select 1 into scarto from migr_liquidazione_scarto where migr_liquidazione_id=migrRecord.migr_liquidazione_id;
              if scarto is null then
                  strMessaggioScarto := 'Soggetto non migrato.';
                  strDettaglioScarto := '[codice_soggetto]['||migrRecord.codice_soggetto||'].';
                  insert into migr_liquidazione_scarto
                  (migr_liquidazione_id,numero_liquidazione,anno_esercizio,motivo_scarto,dettaglio_scarto, ente_proprietario_id)
                  values
                  (migrRecord.migr_liquidazione_id,migrRecord.numero_liquidazione,migrRecord.anno_esercizio,strMessaggioScarto,strDettaglioScarto,enteProprietarioId);
                end if;
                continue;
            end if;
            -- mdp
            strMessaggio:='Ricerca mdp per soggetto id: '||soggettoId||'.';
		    select mdp.modpag_id into mdpId
            from siac_t_modpag mdp, siac_d_accredito_tipo acc
            where mdp.soggetto_id = soggettoId
            and mdp.data_cancellazione is null
            and date_trunc('day',dataElaborazione)>=date_trunc('day',mdp.validita_inizio)
            and (date_trunc('day',dataElaborazione)<date_trunc('day',mdp.validita_fine) or mdp.validita_fine is null)
            and acc.accredito_tipo_id=mdp.accredito_tipo_id
            order by acc.accredito_priorita limit 1;
			if mdpId is null then
         	-- scartare qui il record e proseguire con l'elaborazione successiva se non si vuole gestire come punto di rottura la mancanza della mdp.
--            	RAISE EXCEPTION 'mdp per id soggetto=% non presente in archivio', soggettoId;
              --inserisco lo scarto solo se non c'? gi?
              select 1 into scarto from migr_liquidazione_scarto where migr_liquidazione_id=migrRecord.migr_liquidazione_id;
              if scarto is null then
                strMessaggioScarto := 'mdp non migrata';
                strDettaglioScarto := '[soggetto_id]['||soggettoId||'].';
                insert into migr_liquidazione_scarto
                (migr_liquidazione_id,numero_liquidazione,anno_esercizio,motivo_scarto,dettaglio_scarto, ente_proprietario_id)
                values
                (migrRecord.migr_liquidazione_id,migrRecord.numero_liquidazione,migrRecord.anno_esercizio,strMessaggioScarto,strDettaglioScarto,enteProprietarioId);
              end if;
              continue;
            end if;
         else
         -- MDP ###############
         -- l'esecuzione prosegue, partendo dal codice della mdp e del soggetto dobbiamo recuperare le info sulla mdp migrata,
         -- in modo da capire se siamo nel caso di sede secondaria o cessione di credito/incasso

         -- i dati relativi alla mdp principale corretti.
           /*select
              mdp.migr_modpag_id, mdp.sede_secondaria,mdp.cessione
              into mmdp_id, mmdp_sede_secondaria, mmdp_cessione
           from migr_modpag mdp, migr_soggetto ms
           where mdp.ente_proprietario_id = enteProprietarioId
           and mdp.soggetto_id=ms.soggetto_id
           and mdp.codice_modpag=migrRecord.codice_progben
           and coalesce(mdp.codice_modpag_del,'0') = coalesce(migrRecord.codice_modpag_del,'0')
           and ms.ente_proprietario_id = enteProprietarioId
           and ms.codice_soggetto=migrRecord.codice_soggetto;*/

           -- 29.06.2015
           -- recuperiamo prima i dati della mdp principale (per cui ? specificato se Sede secondaria o cessione)
           -- e poi i dati relativi all'eventuale altra mdp che fa riferimento ad un delegato.
           -- ordinando per cessione siamo sicuri che anche a fronte di + record restituiti quello preso in considerazione ha
		   -- il flag cessione valorizzato ( in caso di cessione)
		   -- il flag sede_secondaria valorizzato ( in caso di sede secondaria )

			strMessaggio:='Ricerca Mdp valorizzata.';
/*select
              mdp.migr_modpag_id, mdp.modpag_id, mdp.sede_secondaria,mdp.cessione,mdp.soggetto_id, ms.migr_soggetto_id
              , altro.mdp_altra mdp_altra_migr, altro.modpag_id, altro.soggetto_altro
             -- into migr_modpag_id_principale, modpag_id_principale, mmdp_sede_secondaria, mmdp_cessione, soggetto_id_principale, migr_soggetto_id_principale
        --      ,  migr_modpag_id_altra, modpag_id_altra, soggetto_id_altro
            from migr_modpag mdp
            inner join  migr_soggetto ms on ( mdp.soggetto_id=ms.soggetto_id
                                              and ms.ente_proprietario_id = 1
                                              and ms.codice_soggetto=113987)
            LEFT OUTER JOIN
                          (select mdp_altra.ente_proprietario_id, mdp_altra.migr_modpag_id mdp_altra,mdp_altra.modpag_id,  mdp_altra.soggetto_id soggetto_altro , mdp_altra.codice_modpag, mdp_altra.codice_modpag_del
                           , ms_altro.codice_soggetto
                           from migr_modpag mdp_altra,migr_soggetto ms_altro
                           where mdp_altra.ente_proprietario_id=1
                            and mdp_altra.codice_modpag='4'
                            and coalesce(mdp_altra.codice_modpag_del,'0') = coalesce('1','0')
                            and mdp_altra.fl_genera_codice='S'
                            and ms_altro.codice_soggetto=113987
                            and ms_altro.ente_proprietario_id = 1
                            and ms_altro.soggetto_id=mdp_altra.soggetto_id
                            and ms_altro.fl_genera_codice='S' ) ALTRO on (altro.ente_proprietario_id=mdp.ente_proprietario_id
                                                                          and altro.codice_modpag=mdp.codice_modpag
                                                                           and coalesce(altro.codice_modpag_del,'0') = coalesce(mdp.codice_modpag_del,'0')
                                                                           and altro.codice_soggetto=ms.codice_soggetto)
            where mdp.ente_proprietario_id = 1
            and mdp.codice_modpag='4'
            and coalesce(mdp.codice_modpag_del,'0') = coalesce('1','0')
            order by mdp.cessione; 29.10.2015 Sofia-Daniela query originale sostituita con quella sotto */

/*			29.10.2015 Sofia-Daniela query di lettura soggetto, mdp spezzata in due
            rispetto a quella originale sopra commentata
            buone le performance quasi uguali a quella  di Giuliano di seguito commentata */
			select
              mdp.migr_modpag_id, mdp.modpag_id, mdp.sede_secondaria,mdp.cessione,mdp.soggetto_id, ms.migr_soggetto_id
              into migr_modpag_id_principale, modpag_id_principale, mmdp_sede_secondaria, mmdp_cessione, soggetto_id_principale, migr_soggetto_id_principale
            from migr_modpag mdp
            inner join  migr_soggetto ms on ( mdp.soggetto_id=ms.soggetto_id
                                              and ms.ente_proprietario_id = enteProprietarioId
                                              and ms.codice_soggetto=migrRecord.codice_soggetto)
            where mdp.ente_proprietario_id = enteProprietarioId
            and mdp.codice_modpag=migrRecord.codice_progben
            and coalesce(mdp.codice_modpag_del,'0') = coalesce(migrRecord.codice_modpag_del,'0')
            order by mdp.cessione;

            strMessaggio:='Ricerca Mdp altra valorizzata.';
			 select mdp_altra.migr_modpag_id ,mdp_altra.modpag_id,  mdp_altra.soggetto_id soggetto_altro
			 into migr_modpag_id_altra, modpag_id_altra, soggetto_id_altro
             from migr_modpag mdp_altra,migr_soggetto ms_altro
             where mdp_altra.ente_proprietario_id=enteProprietarioId
             and mdp_altra.codice_modpag=migrRecord.codice_progben
             and coalesce(mdp_altra.codice_modpag_del,'0') = coalesce(migrRecord.codice_modpag_del,'0')
             and mdp_altra.fl_genera_codice='S'
             and ms_altro.codice_soggetto=migrRecord.codice_soggetto
             and ms_altro.ente_proprietario_id = enteProprietarioId
             and ms_altro.soggetto_id=mdp_altra.soggetto_id
             and ms_altro.fl_genera_codice='S';

           /*  29.10.2015 Sofia-Daniela - versione di Giuliano
           with uno as(
select
c.ente_proprietario_id,c.codice_modpag,c.codice_modpag_del,d.codice_soggetto,
c.migr_modpag_id, c.modpag_id, c.sede_secondaria,c.cessione,c.soggetto_id, d.migr_soggetto_id
from migr_modpag c, migr_soggetto d where
c.soggetto_id=d.soggetto_id
and d.ente_proprietario_id = enteProprietarioId
and c.ente_proprietario_id = enteProprietarioId
--condizioni loop
and d.codice_soggetto=migrRecord.codice_soggetto
and c.codice_modpag=migrRecord.codice_progben
and coalesce(c.codice_modpag_del,'0') = coalesce(migrRecord.codice_modpag_del,'0')
)
, due as
(select
a.ente_proprietario_id, a.migr_modpag_id mdp_altra,
a.modpag_id, a.soggetto_id soggetto_altro , a.codice_modpag, a.codice_modpag_del, b.codice_soggetto
from
migr_modpag a,
migr_soggetto b
where
a.ente_proprietario_id=enteProprietarioId
and b.soggetto_id=a.soggetto_id
and a.fl_genera_codice='S'
and b.ente_proprietario_id = enteProprietarioId
and b.fl_genera_codice='S'
--condizioni loop
--and b.codice_soggetto=113987
--and a.codice_modpag='4'
--and coalesce(a.codice_modpag_del,'0') = coalesce('1','0')
and a.codice_modpag=migrRecord.codice_progben
and coalesce(a.codice_modpag_del,'0') = coalesce(migrRecord.codice_modpag_del,'0')
and b.codice_soggetto=migrRecord.codice_soggetto
)
select
uno.migr_modpag_id, uno.modpag_id, uno.sede_secondaria,uno.cessione,uno.soggetto_id,
uno.migr_soggetto_id
, due.mdp_altra mdp_altra_migr, due.modpag_id, due.soggetto_altro
into migr_modpag_id_principale, modpag_id_principale, mmdp_sede_secondaria, mmdp_cessione,
 soggetto_id_principale, migr_soggetto_id_principale,
 migr_modpag_id_altra, modpag_id_altra, soggetto_id_altro
from uno left join due on
uno.ente_proprietario_id=due.ente_proprietario_id
and uno.codice_modpag=due.codice_modpag
and coalesce(uno.codice_modpag_del,'0') = coalesce(due.codice_modpag_del,'0')
and uno.codice_soggetto=due.codice_soggetto;*/




           -- IDENTIFICAZIONE SOGGETTO
           if mmdp_sede_secondaria = 'N' then
              /*select rss.soggetto_id into soggettoId
              from
                  migr_modpag mdp, migr_soggetto ms, siac_r_migr_soggetto_soggetto rss
              where
               mdp.ente_proprietario_id = enteProprietarioId and ms.ente_proprietario_id = enteProprietarioId
              and ms.codice_soggetto = migrRecord.codice_soggetto
              and ms.soggetto_id = mdp.soggetto_id
              and mdp.codice_modpag=migrRecord.codice_progben
              and coalesce(mdp.codice_modpag_del,'0') = coalesce(migrRecord.codice_modpag_del,'0')
              and rss.ente_proprietario_id = enteProprietarioId
              and rss.migr_soggetto_id=ms.migr_soggetto_id;*/
              -- 29.06.2015
              -- la liquidazione sar? legata al soggetto principale recuperato.
              strMessaggio:='Ricerca Soggetto, SS N';
              select rss.soggetto_id into soggettoId
              from siac_r_migr_soggetto_soggetto rss
              where rss.migr_soggetto_id = migr_soggetto_id_principale
              and rss.ente_proprietario_id = enteProprietarioId;

           ELSE
            -- l'id del soggetto ? quello della sede secondaria migrata.
              /*select sr.soggetto_id_a into soggettoId
              from
              migr_modpag mdp, migr_soggetto ms, migr_sede_secondaria mss
              , siac_r_migr_sede_secondaria_rel_sede rss, siac_r_soggetto_relaz sr
               where
               mdp.ente_proprietario_id = enteProprietarioId and ms.ente_proprietario_id = enteProprietarioId
              and ms.codice_soggetto = migrRecord.codice_soggetto
              and ms.soggetto_id = mdp.soggetto_id
              and mdp.codice_modpag=migrRecord.codice_progben
              and coalesce(mdp.codice_modpag_del,'0') = coalesce(migrRecord.codice_modpag_del,'0')
              and mss.ente_proprietario_id = enteProprietarioId
              and mdp.sede_id=mss.sede_id
              and rss.migr_sede_id=mss.migr_sede_id
              and rss.soggetto_relaz_id=sr.soggetto_relaz_id;*/

              --29.06.2015
              strMessaggio:='Ricerca Soggetto, SS S';
			  select sr.soggetto_id_a into soggettoId
              from
              migr_modpag mdp, migr_sede_secondaria mss
              , siac_r_migr_sede_secondaria_rel_sede rss, siac_r_soggetto_relaz sr
               where
               mdp.ente_proprietario_id = enteProprietarioId
               and mdp.migr_modpag_id = migr_modpag_id_principale
               and mss.ente_proprietario_id = enteProprietarioId
               and mdp.sede_id=mss.sede_id
               and rss.migr_sede_id=mss.migr_sede_id
			   and rss.soggetto_relaz_id=sr.soggetto_relaz_id;

           end if;

           if soggettoId is null then
              select 1 into scarto from migr_liquidazione_scarto where migr_liquidazione_id=migrRecord.migr_liquidazione_id;
              if scarto is null then
                  strMessaggioScarto := 'Soggetto non migrato.';
                  strDettaglioScarto := '[sede_secondaria]['||mmdp_sede_secondaria||']
                                         [codice_progben]['||migrRecord.codice_progben||']
                                         [codice_modpag_del]['||migrRecord.codice_modpag_del||']
                                         [codice_soggetto]['||migrRecord.codice_soggetto||'].';
                  insert into migr_liquidazione_scarto
                  (migr_liquidazione_id,numero_liquidazione,anno_esercizio,motivo_scarto,dettaglio_scarto, ente_proprietario_id)
                  values
                  (migrRecord.migr_liquidazione_id,migrRecord.numero_liquidazione,migrRecord.anno_esercizio,strMessaggioScarto,strDettaglioScarto,enteProprietarioId);
                end if;
                continue;
           end if;
           -- IDENTIFICAZIONE MDP
           if mmdp_cessione is null then
              -- la modalit? di pagamento ? quella migrata per il soggetto trovato.
              /*select coalesce(mdp.modpag_id,0) into mdpId
                from siac_t_modpag mdp, siac_r_migr_modpag_modpag rmdp
                where
                  mdp.ente_proprietario_id=enteProprietarioId
                  and mdp.soggetto_id=soggettoId
                  and mdp.data_cancellazione is null and
                   date_trunc('day',dataElaborazione)>=date_trunc('day',mdp.validita_inizio) and
                   (date_trunc('day',dataElaborazione)<=date_trunc('day',mdp.validita_fine)
                   or mdp.validita_fine is null)
                  and rmdp.modpag_id=mdp.modpag_id
                  and rmdp.migr_modpag_id=mmdp_id;*/

              --29.06.2015
              strMessaggio:='Ricerca Mdp, Cessione Null.';
              if migr_modpag_id_altra is not null and migr_modpag_id_altra <> 0 then
				select coalesce(rmdp.modpag_id,0) into mdpId
                from siac_r_migr_modpag_modpag rmdp
                where rmdp.migr_modpag_id=migr_modpag_id_altra
                and rmdp.ente_proprietario_id=enteProprietarioId;
              else
				select coalesce(rmdp.modpag_id,0) into mdpId
                from siac_r_migr_modpag_modpag rmdp
                where rmdp.migr_modpag_id=migr_modpag_id_principale
                and rmdp.ente_proprietario_id=enteProprietarioId;
              end if;

           else
              -- cessione per incasso (CSI) o credito (CDC)
              /*select relMdp.modpag_id into mdpId
              from
              migr_modpag mdp, migr_soggetto ms
              , migr_relaz_soggetto mrs
              , siac_r_migr_relaz_soggetto_relaz rmr
              , siac_r_soggetto_relaz rs
              , siac_r_soggrel_modpag relMdp
              , siac_r_migr_soggetto_soggetto rss
              where mdp.ente_proprietario_id = enteProprietarioId and ms.ente_proprietario_id = enteProprietarioId
               and ms.codice_soggetto = migrRecord.codice_soggetto
               and ms.soggetto_id = mdp.soggetto_id
              and mdp.codice_modpag=coalesce(migrRecord.codice_progben, mdp.codice_modpag)
              and coalesce(mdp.codice_modpag_del,'0') = coalesce(migrRecord.codice_modpag_del,'0')
              and mrs.soggetto_id_da=ms.soggetto_id -- oracle
              and mrs.migr_relaz_id=rmr.migr_relaz_id
              and rs.soggetto_relaz_id = rmr.soggetto_relaz_id
              and relMdp.soggetto_relaz_id=rs.soggetto_relaz_id
              and rss.migr_soggetto_id=ms.migr_soggetto_id;*/
              --29.06.2015

--mdp_princ-ss-cess-sogg.prin-mdpaltra-sogg.altro
--142194 - N - CSI - 254592 - 142272 - 254591

			  strMessaggio:='Ricerca Mdp, Cessione '||mmdp_cessione||'.';
              if mmdp_cessione='CSI' then -- 31.12.2015 Sofia per CSC le relazioni sono invertite
               --select relMdp.modpag_id into mdpId
               -- 10.02.2016 Sofia - in caso di cessione incasso non bisogna impostare modpagId ma soggettoRelazId
               select relMdp.modpag_id, relMdp.soggetto_relaz_id into mdpId, soggettoRelazId
               from migr_relaz_soggetto mrs, siac_r_migr_relaz_soggetto_relaz rmr, siac_r_soggrel_modpag relMdp
                  where mrs.soggetto_id_da = soggetto_id_principale --sogg.prin
                  and mrs.soggetto_id_a = coalesce(soggetto_id_altro,mrs.soggetto_id_a) --sogg.altro
                  and mrs.modpag_id_da=modpag_id_principale --mdp_principale
                  and mrs.modpag_id_a= coalesce(modpag_id_altra,mrs.modpag_id_a)  --mdp_altra
                  and mrs.ente_proprietario_id=enteProprietarioId
                  and rmr.migr_relaz_id=mrs.migr_relaz_id
                  and relMdp.soggetto_relaz_id=rmr.soggetto_relaz_id;

              else

              	select relMdp.modpag_id into mdpId
                from migr_relaz_soggetto mrs, siac_r_migr_relaz_soggetto_relaz rmr, siac_r_soggrel_modpag relMdp
                  where mrs.soggetto_id_a = soggetto_id_principale --sogg.prin
                  and mrs.modpag_id_a=modpag_id_principale --mdp_principale
                  and mrs.ente_proprietario_id=enteProprietarioId
                  and rmr.migr_relaz_id=mrs.migr_relaz_id
                  and relMdp.soggetto_relaz_id=rmr.soggetto_relaz_id;
              end if;

              -- da commentare se la mdp ritornera da impostare
              if soggettoRelazId is not null then
              	mdpId:=null;
              end if;
           end if;

           if mmdp_cessione is not null and mmdp_cessione='CSI' THEN
           	if soggettoRelazId is null then
	          select 1 into scarto from migr_liquidazione_scarto where migr_liquidazione_id=migrRecord.migr_liquidazione_id;
              if scarto is null then
                strMessaggioScarto := 'soggettoRelazId non valorizzato';
                strDettaglioScarto := '[sede_secondaria]['||mmdp_sede_secondaria||']
                                       [cessione]['||mmdp_cessione||']
                                       [codice_soggetto]['||migrRecord.codice_soggetto||']
                					   [codice_progben]['||migrRecord.codice_progben||']
                                       [codice_modpag_del]['||migrRecord.codice_modpag_del||']
                                       [sede_secondaria]['||mmdp_sede_secondaria||'].';
                insert into migr_liquidazione_scarto
                (migr_liquidazione_id,numero_liquidazione,anno_esercizio,motivo_scarto,dettaglio_scarto, ente_proprietario_id)
                values
                (migrRecord.migr_liquidazione_id,migrRecord.numero_liquidazione,migrRecord.anno_esercizio,strMessaggioScarto,strDettaglioScarto,enteProprietarioId);
              end if;
              continue;
            end if;
           else
		    if mdpId is null then
         	-- scartare qui il record e proseguire con l'elaborazione successiva se non si vuole gestire come punto di rottura la mancanza della mdp.
--            	RAISE EXCEPTION 'mdp per id soggetto=% non presente in archivio', soggettoId;
              --inserisco lo scarto solo se non c'? gi?
              select 1 into scarto from migr_liquidazione_scarto where migr_liquidazione_id=migrRecord.migr_liquidazione_id;
              if scarto is null then
                strMessaggioScarto := 'mdp non migrata';
                strDettaglioScarto := '[sede_secondaria]['||mmdp_sede_secondaria||']
                                       [cessione]['||mmdp_cessione||']
                                       [codice_soggetto]['||migrRecord.codice_soggetto||']
                					   [codice_progben]['||migrRecord.codice_progben||']
                                       [codice_modpag_del]['||migrRecord.codice_modpag_del||']
                                       [sede_secondaria]['||mmdp_sede_secondaria||'].';
                insert into migr_liquidazione_scarto
                (migr_liquidazione_id,numero_liquidazione,anno_esercizio,motivo_scarto,dettaglio_scarto, ente_proprietario_id)
                values
                (migrRecord.migr_liquidazione_id,migrRecord.numero_liquidazione,migrRecord.anno_esercizio,strMessaggioScarto,strDettaglioScarto,enteProprietarioId);
              end if;
              continue;
             end if;
            end if;
		  end if;

--LEGAME CON SIAC_T_MOVGEST  ###############
          if migrRecord.numero_subimpegno = 0 then
          	-- la liquidazione ? legata ad un movimento di tipo IMPEGNO da ricercare nella siac_t_movgest_ts come TESTATA
            strMessaggio:='Lettura testata Impegno [siac_t_movgest_ts]';
            select coalesce(dett.movgest_ts_id,0) into movGestTsId
            from siac_t_movgest_ts dett
            where dett.ente_proprietario_id=enteProprietarioId::INTEGER
            and dett.movgest_ts_tipo_id=movGestTsTipoId_T
			and dett.movgest_id=migrRecord.movgest_id
            and dett.movgest_ts_code=migrRecord.numero_impegno::VARCHAR
            and movgest_ts_id_padre is null;
          else
            -- la liquidazione ? legata ad un movimento di tipo SUBIMPEGNO da ricercare nella siac_t_movgest_ts come SUB
            strMessaggio:='Lettura SubImpegno [siac_t_movgest_ts] ';
            select coalesce(dett.movgest_ts_id,0) into movGestTsId
            from siac_t_movgest_ts dett
            where dett.ente_proprietario_id=enteProprietarioId::INTEGER
            and dett.movgest_ts_tipo_id=movGestTsTipoId_S
			and dett.movgest_id=migrRecord.movgest_id
		    and dett.movgest_ts_code=migrRecord.numero_subimpegno::VARCHAR;
          end if;
          if movGestTsId is NULL then
          -- scartare qui il record e proseguire con l'elaborazione successiva se non si vuole gestire come punto di rottura la mancanza del record nella siac_t_movgest_ts.
--              RAISE EXCEPTION 'impegno %/%/% non presente in archivio', migrRecord.numero_impegno,migrRecord.numero_subimpegno, migrRecord.anno_impegno;

            --inserisco lo scarto solo se non c'? gi?
            select 1 into scarto from migr_liquidazione_scarto where migr_liquidazione_id=migrRecord.migr_liquidazione_id;
            if scarto is null then
 				strMessaggioScarto := 'movimento non presente in archivio';
            	strDettaglioScarto := 'nr imp/anno imp/nr sub = '||migrRecord.numero_impegno||'/'||migrRecord.anno_impegno||'/'||migrRecord.numero_subimpegno;
                insert into migr_liquidazione_scarto
                (migr_liquidazione_id,numero_liquidazione,anno_esercizio,motivo_scarto,dettaglio_scarto, ente_proprietario_id)
                values
                (migrRecord.migr_liquidazione_id,migrRecord.numero_liquidazione,migrRecord.anno_esercizio,strMessaggioScarto,strDettaglioScarto,enteProprietarioId);
		    end if;
            continue;
          end if;

--ATTO AMMINISTRATIVO  ###############

		strMessaggio:='call fnc_migr_attoam';
-- 18.09.2015
--        if coalesce(migrRecord.numero_provvedimento,0)!=0
        if coalesce(migrRecord.numero_provvedimento_calcolato,0)!=0
           or migrRecord.tipo_provvedimento=SPR
           then
                  strMessaggio:='Provvedimento.';
                  select * into migrAttoAmm
                  from fnc_migr_attoamm (migrRecord.anno_provvedimento
--                  							,migrRecord.numero_provvedimento,
                                            ,migrRecord.numero_provvedimento_calcolato,
                                                 migrRecord.tipo_provvedimento,migrRecord.sac_provvedimento,
                                                 migrRecord.oggetto_provvedimento,migrRecord.note_provvedimento,
                                                 migrRecord.stato_provvedimento,
                                                 enteProprietarioId,loginOperazione,dataElaborazione
                                                 , dataInizioVal);
                  if migrAttoAmm.codiceRisultato=-1 then
                      RAISE EXCEPTION ' % ', migrAttoAmm.messaggioRisultato;
                  ELSE
                  	attoAmmId := migrAttoAmm.id;

                  end if;
        end if;
        if attoAmmId = 0 then
        -- scartare qui il record e proseguire con l'elaborazione successiva se non si vuole gestire come punto di rottura la mancanza del record nella siac_t_movgest_ts.
--            RAISE EXCEPTION 'impegno %/%/% non presente in archivio', migrRecord.numero_impegno,migrRecord.numero_subimpegno, migrRecord.anno_impegno;
          --inserisco lo scarto solo se non c'? gi?
          select 1 into scarto from migr_liquidazione_scarto where migr_liquidazione_id=migrRecord.migr_liquidazione_id;
          if scarto is null then
 			strMessaggioScarto := 'Atto amm non presente in archivio';
            insert into migr_liquidazione_scarto
            (migr_liquidazione_id,numero_liquidazione,anno_esercizio,motivo_scarto,dettaglio_scarto, ente_proprietario_id)
            values
            (migrRecord.migr_liquidazione_id,migrRecord.numero_liquidazione,migrRecord.anno_esercizio,strMessaggioScarto,strDettaglioScarto,enteProprietarioId);
		  end if;
            continue;
        end if;

--MUTUO SE DEFINITO  ###############
		if migrRecord.numero_mutuo is not null then
        	strMessaggio:=recId||'Lettura Voce di mutuo.';
        --  La liquidazione ? da legare alla voce di mutuo migrata per il mutuo della liquidazione, che deve essere stato migrato.
        -- la voce di mutuo migrata deve essere stata legata alla testa dell'impegno a cui ? legat la liquidazione.
            select coalesce(r.mut_voce_id,0) into mutVoceId
            from
              migr_mutuo mm
              , siac_r_migr_mutuo_t_mutuo rm
              , siac_t_mutuo_voce vm
              , siac_r_mutuo_voce_movgest r
              , siac_t_movgest_ts mg
            where
              mm.codice_mutuo=migrRecord.numero_mutuo and mm.ente_proprietario_id=enteProprietarioId::INTEGER
              and rm.migr_mutuo_id=mm.migr_mutuo_id
              and vm.mut_id=rm.mut_id
              and mg.movgest_id=migrRecord.movgest_id -- id impegno della liquidazione.
              and mg.movgest_ts_id_padre is null -- testata
              and mg.movgest_ts_tipo_id=movGestTsTipoId_T  -- testata
              and r.mut_voce_id=vm.mut_voce_id
              and r.movgest_ts_id=mg.movgest_ts_id
              and rm.ente_proprietario_id=enteProprietarioId::INTEGER
              and vm.ente_proprietario_id=enteProprietarioId::INTEGER
              and r.ente_proprietario_id=enteProprietarioId::INTEGER;
          if mutVoceId is null then
          -- scartare qui il record e proseguire con l'elaborazione successiva se non si vuole gestire come punto di rottura la mancanza della voce di mutuo migrata.
--              RAISE EXCEPTION 'voce di mutuo per  %/% non presente in archivio', migrRecord.numero_mutuo,movGestTsId;
            --inserisco lo scarto solo se non c'? gi?
            select 1 into scarto from migr_liquidazione_scarto where migr_liquidazione_id=migrRecord.migr_liquidazione_id;
            if scarto is null then
              strMessaggioScarto := 'voce di mutuo non presente in archivio';
              strDettaglioScarto := 'nr mutuo/movGestTsId = '|| migrRecord.numero_mutuo||'/'||movGestTsId;
              insert into migr_liquidazione_scarto
              (migr_liquidazione_id,numero_liquidazione,anno_esercizio,motivo_scarto,dettaglio_scarto, ente_proprietario_id)
              values
              (migrRecord.migr_liquidazione_id,migrRecord.numero_liquidazione,migrRecord.anno_esercizio,strMessaggioScarto,strDettaglioScarto,enteProprietarioId);
            end if;
            continue;
          end if;
        end if;

--STATO ###############
       	strMessaggio:=recId||'Lettura Stato.';
        -- recupero dello stato codificato.
        select coalesce(d.liq_stato_id,0) into statoId
        from
          siac_d_liquidazione_stato d
        where
          d.liq_stato_code = migrRecord.stato_operativo
          and d.ente_proprietario_id=enteProprietarioId::INTEGER
          and d.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                or d.validita_fine is null);
        if statoId is null then
--            RAISE EXCEPTION 'Codice stato  % non presente in archivio', migrRecord.stato_operativo;
            --inserisco lo scarto solo se non c'? gi?
            select 1 into scarto from migr_liquidazione_scarto where migr_liquidazione_id=migrRecord.migr_liquidazione_id;
            if scarto is null then
              strMessaggioScarto := 'Codice stato non presente in archivio';
              strDettaglioScarto := 'Codice stato = '|| migrRecord.stato_operativo;
              insert into migr_liquidazione_scarto
              (migr_liquidazione_id,numero_liquidazione,anno_esercizio,motivo_scarto,dettaglio_scarto, ente_proprietario_id)
              values
              (migrRecord.migr_liquidazione_id,migrRecord.numero_liquidazione,migrRecord.anno_esercizio,strMessaggioScarto,strDettaglioScarto,enteProprietarioId);
			end if;
            continue;
        end if;

--        strMessaggioFinale:=strMessaggioFinale||'Sto per inserire.';

         -- inserimento nella tabella principale siac_t_liquidazione.

        strmessaggio:= 'Insert into siac_t_liquidazione';
        insert into siac_t_liquidazione
        (liq_anno,liq_numero,liq_desc,liq_emissione_data,liq_importo,bil_id,modpag_id,soggetto_relaz_id,
         validita_inizio,liq_automatica, liq_convalida_manuale,ente_proprietario_id,data_creazione,login_operazione)
        values
        (migrRecord.anno_esercizio_orig::integer,migrRecord.numero_liquidazione_orig, migrRecord.descrizione
        , to_timestamp(migrRecord.data_emissione_orig,'dd/MM/yyyy')
        , migrRecord.importo,
         bilancioid,mdpId,soggettoRelazId, dataInizioVal::timestamp,LIQAUTOMATICA, LIQCONVALIDA_MANUALE,
         enteProprietarioId,clock_timestamp(),loginoperazione )
         returning liq_id into liqId;

	    strmessaggio:= 'Insert into siac_r_liquidazione_stato.';
        insert into siac_r_liquidazione_stato
        (liq_id, liq_stato_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
        values
        (liqId, statoId, dataInizioVal::timestamp, enteProprietarioId, clock_timestamp(), loginoperazione);

        strmessaggio:= 'Insert into siac_r_liquidazione_soggetto.';
        insert into siac_r_liquidazione_soggetto
        (liq_id, soggetto_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
        values
        (liqId, soggettoId, dataInizioVal::timestamp, enteProprietarioId, clock_timestamp(), loginoperazione);

        strmessaggio:= 'Insert into siac_r_liquidazione_movgest.';
        insert into siac_r_liquidazione_movgest
        (liq_id, movgest_ts_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
        values
        (liqId, movGestTsId, dataInizioVal::timestamp, enteProprietarioId, clock_timestamp(), loginoperazione);


        strmessaggio:= 'Insert into siac_r_liquidazione_atto_amm.';
        insert into siac_r_liquidazione_atto_amm
        (liq_id, attoamm_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
        values
        (liqId, attoAmmId, dataInizioVal::timestamp, enteProprietarioId, clock_timestamp(), loginoperazione);

  	    if migrRecord.numero_mutuo is not null then
          strmessaggio:= 'Insert into siac_r_mutuo_voce_liquidazione.';
          insert into siac_r_mutuo_voce_liquidazione
          (liq_id, mut_voce_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
          values
          (liqId, mutVoceId, dataInizioVal::timestamp, enteProprietarioId, clock_timestamp(), loginoperazione);
		end if;

        if coalesce(migrRecord.pdc_finanziario,NVL_STR)!=NVL_STR then
               strMessaggio:='Inserimento relazione con PDC_FIN_V_LIV su siac_r_liquidazione_class.';
              INSERT INTO siac_r_liquidazione_class
               (liq_Id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione)
               (select liqId,tipoPdcFinClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
                from siac_t_class tipoPdcFinClass
                where tipoPdcFinClass.classif_code=migrRecord.pdc_finanziario and
                      tipoPdcFinClass.ente_proprietario_id=enteProprietarioId and
                      tipoPdcFinClass.data_cancellazione is null and
                      date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFinClass.validita_inizio) and
                      (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFinClass.validita_fine)
                          or tipoPdcFinClass.validita_fine is null) and
                      tipoPdcFinClass.classif_tipo_id = idClass_pdc);
         end if;
         if coalesce(migrRecord.cofog,NVL_STR)!=NVL_STR then
               strMessaggio:='Inserimento relazione con COFOG su siac_r_liquidazione_class.';
              INSERT INTO siac_r_liquidazione_class
               (liq_Id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione)
               (select liqId,classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
                from siac_t_class
                where classif_code=migrRecord.cofog and
                      ente_proprietario_id=enteProprietarioId and
                      data_cancellazione is null and
                      date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
                      (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine)
                          or validita_fine is null) and
                      classif_tipo_id = idClass_cofog);
         end if;

		 -- 27.11.2015 Davide gestione siope :
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
		         if coalesce(migrRecord.siope_spesa,NVL_STR)!=NVL_STR then
		             classif_siope_code := migrRecord.siope_spesa;
		         else
				     --... altrimenti lo leggi dal movimento a cui ?ollegato
		             begin
                         strMessaggio:='Lettura del SIOPE dall''impegno / subimpegno collegato.';
  	                     select tipi_class.classif_code into strict classif_siope_code
			               from siac_t_class tipi_class, siac_r_movgest_class relaz_impclass
                          where relaz_impclass.ente_proprietario_id=enteproprietarioid
                        and tipi_class.ente_proprietario_id=relaz_impclass.ente_proprietario_id
                        and relaz_impclass.movgest_ts_id=movGestTsId
			            and tipi_class.classif_tipo_id=idClass_siope
			            and tipi_class.classif_id=relaz_impclass.classif_id;
			         exception
           	             when others  THEN
		                     classif_siope_code := '';
			         end;
                 end if;
		 end;

		 if coalesce(classif_siope_code,NVL_STR)!=NVL_STR then
             strMessaggio:='Inserimento relazione con SIOPE su siac_r_liquidazione_class.';

             INSERT INTO siac_r_liquidazione_class
               (liq_Id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione)
               (select liqId,classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
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

		strmessaggio:= 'Insert into siac_r_migr_liquidazione_t_liquidazione.';
		insert into siac_r_migr_liquidazione_t_liquidazione
        (migr_liquidazione_id, liquidazione_id, ente_proprietario_id)
        VALUES
        (migrRecord.migr_liquidazione_id, liqid, enteProprietarioId);

   		countRecordInseriti:=countRecordInseriti+1;

        -- valorizzare fl_elab = 'S'
        update migr_liquidazione set fl_elab='S'
        where ente_proprietario_id=enteProprietarioId
        and migr_liquidazione_id = migrRecord.migr_liquidazione_id;

  end loop;

   -- inserisco gli scarti per assenza di movgest

  insert into migr_liquidazione_scarto
  	(migr_liquidazione_id,numero_liquidazione,anno_esercizio,motivo_scarto,dettaglio_scarto, ente_proprietario_id)
  select m.migr_liquidazione_id, m.numero_liquidazione, m.anno_esercizio, 'Impegno non migrato.',null,enteProprietarioId
  from migr_liquidazione m
  where m.ente_proprietario_id=enteProprietarioId
  and m.fl_elab='N'
  and m.migr_liquidazione_id >= idmin and m.migr_liquidazione_id <= idmax
  and not exists (select 1 from siac_t_movgest mov
                  where mov.ente_proprietario_id=m.ente_proprietario_id
                  and mov.bil_id=bilancioid--16,17
                  and mov.movgest_tipo_id=movGestTipoId--1,4
                  and mov.movgest_anno = m.anno_impegno::INTEGER
                  and mov.movgest_numero= m.numero_impegno::NUMERIC
                  and mov.data_cancellazione is null and
                        date_trunc('day',dataElaborazione)>=date_trunc('day',mov.validita_inizio) and
                        (date_trunc('day',dataElaborazione)<=date_trunc('day',mov.validita_fine)
                            or mov.validita_fine is null))
   and not exists (select 1 from migr_liquidazione_scarto where migr_liquidazione_id = m.migr_liquidazione_id);

   RAISE NOTICE 'numerorecordinseriti %', countRecordInseriti;

   -- aggiornamento progressivi
   select * into aggProgressivi
   from fnc_aggiorna_progressivi(enteProprietarioId, 'L', loginOperazione);

    if aggProgressivi.codresult=-1 then
    	RAISE EXCEPTION ' % ', aggProgressivi.messaggioRisultato;
    end if;

   messaggioRisultato:=strMessaggioFinale||'Inserite '||countRecordInseriti||' liquidazioni.';
   numerorecordinseriti:= countRecordInseriti;
  return;
exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
	when others  THEN
		raise notice '% % % ERRORE DB: % %',strMessaggioFinale,recId,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||recId||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;