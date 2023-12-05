/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Function: fnc_migr_soggetto(character varying, integer, character varying, timestamp without time zone)

--DROP FUNCTION fnc_migr_soggetto_new( varchar, integer, varchar, timestamp without time zone, VARCHAR, integer, integer, integer varchar);

CREATE OR REPLACE FUNCTION fnc_migr_soggetto (
  tipoelab varchar,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  annobilancio varchar,
  idmin integer,
  idmax integer,
  out numerosoggettiinseriti integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
    -- ATTENZIONE da rivedere -- in base a modifiche fatte per tipoElab
    -- fnc_migr_soggetto --> function che effettua il caricamento dei soggetti migrati leggendo in tab migr_soggetto
    -- effettua inserimento di
     -- siac_t_soggetto -- per dati di anagrafica principale
     --                    (siac_r_soggetto_stato,siac_r_soggetto_attr<note,matricolaSPI>,siac_r_soggetto_tipo)
     -- siac_t_indirizzo_soggetto -- per indirizzo principale (siac_r_indirizzo_soggetto_tipo)
     -- siac_t_recapito_soggetto  -- per gli eventuali recapiti da attruibuire al soggetto stesso
     --                              tel1,tel2,fax,emal, contatto_generico
     -- siac_t_persona_fisica (tipoSoggetto=PF)
     -- siac_t_persona_giuridica , siac_r_forma_giuridica (tipoSoggetto!=PF)
     -- siac_d_soggetto_classe, siac_r_soggetto_classe per il campo  migr_soggetto.classif
     -- siac_r_migr_soggetto_soggetto per tracciare migr_soggetto.migr_soggetto_id -- siac_t_soggetto.soggetto_id
    -- richiama
     -- fnc_migr_comune per il reperimento del comune_id da associare a indirizzo principale soggetto o comune di nascita
     -- fnc_migr_forma_giuridica per il reperimento di forma_giuridica_id da associare alla persona non fisica (tipoSoggetto!=PF)
     -- fnc_migr_soggetto_classe per il caricamento delle relazioni tra classi  e soggetti migrati (migr_soggetto_classe)
     -- fnc_migr_indirizzo_secondario per il caricamento degli indirizzi secondari del soggetto (migr_indirizzo_secondario)
     -- fnc_migr_recapito_soggetto per il caricamento dei recapiti del soggetto (migr_recapito_soggetto)
     -- fnc_migr_sede_secondaria per il caricamento delle sedi secondarie del soggetto ( migr_sede_secondaria )
     -- fnc_migr_mogpag per il  caricamento delle MDP del soggetto
    -- restituisce
     -- messaggioRisultato valorizzato con il risultato della elaborazione in formato testo
     -- numeroSoggettiInseriti valorizzato con
        -- -12 dati da migrare non presenti in migr_soggetto
        -- -1 errore
        -- N=numero dei soggetti inseriti

    -- Punti di attenzione
     -- siac_t_soggetto.soggetto_code --> valorizzato con il campo migr_soggetto.codice_soggetto
     -- bisognerebbe verificare se valorizzato, in caso negativo calcolarlo
     -- (Co.To potrebbe inserire soggetti nuovi vedi Delegati )

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
	--dataInizioVal timestamp :=annoBilancio||'-01-01';
	dataInizioVal timestamp :=null;

	migrSoggetto  record;
    migrComune record;
    migrFormaGiuridica record;
    migrSoggettoClasse  record;
    migrIndirSec record;
    migrRecapitoSoggetto record;
    migrSedeSec record;
    migrModPag record;
	migrAggiornaProgr record;
    spacchettaCf record;

    v_soggettoId integer:=null;
    soggettoId integer:=0;
    indirizzoId integer:=0;
    ambitoId   integer:=0;
    comuneId   integer:=null;
    soggettoClasseId INTEGER:=null;
	numeroElementiInseriti   integer:=0;

	strToElab varchar(1000):='';
    tipoRecapitoSoggetto varchar(1000):='';
    avvisoRecapitoSoggetto varchar(1000):='';
    recapitoSoggetto varchar(1000):='';
	-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
    nrecapiti integer:=0;
	-- DAVIDE - 21.09.015 : fine

	countMigrSoggetto integer:=0;
    soggettoClasseTipoId integer:=0;
    formaGiuridica varchar(250):='';
    v_isDelegato integer:=0;

	--    costanti
    NOTE_SOGG_ATTR      CONSTANT  varchar :='NoteSoggetto';
    MATRSPI_SOGG_ATTR   CONSTANT  varchar :='Matricola';
	SOGGETTO_PF         CONSTANT  varchar :='PF';
	SOGGETTO_PFI         CONSTANT  varchar :='PFI';
    SEPARATORE			CONSTANT  varchar :='||';

	RECAPITO_MODO_FAX   CONSTANT  varchar :='fax';
    RECAPITO_MODO_TEL   CONSTANT  varchar :='telefono';
    RECAPITO_MODO_WWW   CONSTANT  varchar :='sito';

	AMBITO_SOGG         CONSTANT  varchar :='AMBITO_FIN';
    SOGG_CLASSE_TIPO_ND CONSTANT  varchar :='ND';

    NOTE_SOGG_LENGTH    CONSTANT integer:=500;
	NVL_STR             CONSTANT varchar:='';
	TIPO_ELAB_SOGGETTO	  CONSTANT varchar:='SO';
	TIPO_ELAB_SOGGCLASSE  CONSTANT varchar:='SC';
    TIPO_ELAB_INDIR_SEC   CONSTANT varchar:='SI';
    TIPO_ELAB_RECAPITO_SOGG CONSTANT varchar:='SR';
    TIPO_ELAB_SEDE_SEC CONSTANT varchar:='SS';
    TIPO_ELAB_MDP CONSTANT varchar:='SM';

	KEY_PROGR CONSTANT varchar:='S';

    DATA_NASCITA_DEF    varchar:='1900-01-01';
    SESSO_DEFAULT       varchar:='M';
    NOME_DEFAULT       varchar:=' ';
    COGNOME_DEFAULT       varchar:=' ';

	FORMA_GIUR_DI  CONSTANT varchar:='DI||DITTA INDIVIDUALE';

    -- dichiarazione variabili per fk lette una volta
    code varchar(200):='';
    idAttr_noteSoggetto integer := 0;
    idAttr_matrspi integer := 0;
    recapitoModoId_tel integer := 0;
    recapitoModoCode_tel varchar:=NULL;
    recapitoModoId_fax integer := 0;
    recapitoModoCode_fax varchar:=NULL;
    recapitoModoId_www integer := 0;
    recapitoModoCode_www varchar:=NULL;
    codice_soggetto VARCHAR(200) := null; -- è uguale al campo codice_soggetto della migr_soggetto se il soggetto da migrare nasce sul sistema di origine come soggetto
     										-- è uguale a codice_soggetto||D||seq_soggetto_delegato se il soggetto da migrare è sul sistema di origine un delegato
	seq_soggetto_delegato integer := 0; -- è il contatore da far seguire alla stringa codSoggetto||D|| per identificare
    									-- quei delegati che sono inseriti come soggetto
	comuneNascita varchar(200):=NULL; -- valorizzato con migrSoggetto.comune_nascita e se null proviamo a recuperarlo dal CF chiamando la function fnc_migr_spacchettacf
    datanascita varchar(10):=NULL; -- valorizzato con migrSoggetto.data_nascita e se null proviamo a recuperarlo dal CF chiamando la function fnc_migr_spacchettacf
    sesso varchar(1):=NULL; -- valorizzato con migrSoggetto.sesso e se null proviamo a recuperarlo dal CF chiamando la function fnc_migr_spacchettacf

BEGIN

    numeroSoggettiInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione soggetti.Tipo Elaborazione '||tipoElab||'.';


    strMessaggio:='Lettura AMBITO_FIN.';

    select ambito.ambito_id into ambitoId
    from siac_d_ambito ambito
    where ambito.ambito_code=AMBITO_SOGG and
          ambito.ente_proprietario_id=enteProprietarioId;

	if COALESCE(ambitoId,0)=0 then
	    RAISE EXCEPTION 'Ambito FIN inesistente per ente % ',enteProprietarioId ;
    end if;

    strMessaggio:='Lettura soggetto_classe_tipo_id per AMBITO='||ambito_sogg||' TIPO '||SOGG_CLASSE_TIPO_ND;
    strMessaggioFinale:=strMessaggio;

	select soggetto_classe_tipo_id into soggettoClasseTipoId
    from siac_d_soggetto_classe_tipo soggClasseTipo
    where soggClasseTipo.ambito_id=ambitoId and
          soggClasseTipo.ente_proprietario_id=enteProprietarioId and
          soggClasseTipo.soggetto_classe_tipo_code=SOGG_CLASSE_TIPO_ND;

	if COALESCE(soggettoClasseTipoId,0)=0 then
	    RAISE EXCEPTION 'SoggettoClasseTipo inesistente per ente % ',enteProprietarioId ;
    end if;

    strMessaggio:='Lettura soggetti migrati.';
        strMessaggioFinale:=strMessaggio;

	select COALESCE(count(*),0) into countMigrSoggetto
    from migr_soggetto ms
    where ms.ente_proprietario_id=enteProprietarioId and ms.fl_elab='N'
    and ms.migr_soggetto_id>= idmin and ms.migr_soggetto_id<=idmax ;

	if COALESCE(countMigrSoggetto,0)=0 then
         messaggioRisultato:=strMessaggioFinale||'Archivio migrazione vuoto per ente '||enteProprietarioId||' e range id [ '||idmin||'-'||idmax||'].';
         numeroSoggettiInseriti:=-12;
         return;
    end if;

	-- fk lette una sola volta
    if tipoElab=TIPO_ELAB_SOGGETTO then
      strMessaggio:='Lettura codifiche.';
      begin
          code := NOTE_SOGG_ATTR;
        select attrSoggetto.attr_id into strict idAttr_noteSoggetto
          from siac_t_attr attrSoggetto
          where attrSoggetto.ente_proprietario_id=enteProprietarioId and
                attrSoggetto.attr_code=NOTE_SOGG_ATTR and
                attrSoggetto.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',attrSoggetto.validita_inizio) and
               (date_trunc('day',dataElaborazione)<=date_trunc('day',attrSoggetto.validita_fine)
                          or attrSoggetto.validita_fine is null);

          code := MATRSPI_SOGG_ATTR;
         select attrSoggetto.attr_id into strict idAttr_matrspi
          from siac_t_attr attrSoggetto
          where attrSoggetto.ente_proprietario_id=enteProprietarioId and
               attrSoggetto.attr_code=MATRSPI_SOGG_ATTR and
               attrSoggetto.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',attrSoggetto.validita_inizio) and
               (date_trunc('day',dataElaborazione)<=date_trunc('day',attrSoggetto.validita_fine)
                          or attrSoggetto.validita_fine is null);

          code := RECAPITO_MODO_TEL;
         select recapitoModo.recapito_modo_id,recapitoModo.recapito_modo_code
         into strict recapitoModoId_tel,recapitoModoCode_tel
          from siac_d_recapito_modo recapitoModo
          where recapitoModo.recapito_modo_code=RECAPITO_MODO_TEL and
                recapitoModo.ente_proprietario_id=enteProprietarioId and
                recapitoModo.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
               (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
                  or recapitoModo.validita_fine is null);

          code:=RECAPITO_MODO_FAX;
        select recapitoModo.recapito_modo_id,recapitoModo.recapito_modo_code
        into strict recapitoModoId_fax,recapitoModoCode_fax
        from siac_d_recapito_modo recapitoModo
        where recapitoModo.recapito_modo_code=RECAPITO_MODO_FAX and
              recapitoModo.ente_proprietario_id=enteProprietarioId and
              recapitoModo.data_cancellazione is null and
             date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
             (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
                or recapitoModo.validita_fine is null);

          code:=RECAPITO_MODO_WWW;
        select recapitoModo.recapito_modo_id, recapitoModo.recapito_modo_code
        into strict recapitoModoId_www,recapitoModoCode_www
        from siac_d_recapito_modo recapitoModo
        where recapitoModo.recapito_modo_code=RECAPITO_MODO_WWW and
              recapitoModo.ente_proprietario_id=enteProprietarioId and
              recapitoModo.data_cancellazione is null and
             date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
             (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
                or recapitoModo.validita_fine is null);

          code:='SEQ SOGGETTO_CODE||D||';
         select coalesce(count(soggetto_id),0) into seq_soggetto_delegato
         from
         siac_t_soggetto where ente_proprietario_id = enteProprietarioId
         and soggetto_code like '%||D||%'; -- serve il doppio pipe prima e dopo per differenzire i record da quelli con cod_soggeto con una d come demo...

      exception
        when no_data_found then
            RAISE EXCEPTION 'Code % non presente in archivio',code;
            when others  THEN
                RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
      end;
	end if;

    for migrSoggetto IN
    (select ms.*
     from migr_soggetto ms
     where ms.ente_proprietario_id=enteProprietarioId and
	   (  tipoelab=TIPO_ELAB_SOGGETTO or tipoelab=TIPO_ELAB_MDP or
	      ( tipoelab=TIPO_ELAB_SOGGCLASSE and ms.soggetto_id in (select soggetto_id from migr_soggetto_classe where ente_proprietario_id=enteProprietarioId) ) or
	      ( tipoelab=TIPO_ELAB_SEDE_SEC and ms.soggetto_id in (select soggetto_id from migr_sede_secondaria where ente_proprietario_id=enteProprietarioId) ) or
		  ( tipoelab=TIPO_ELAB_INDIR_SEC and ms.soggetto_id in (select soggetto_id from migr_indirizzo_secondario where ente_proprietario_id=enteProprietarioId  )   )
	   )  and
       ms.fl_elab='N'
       and ms.migr_soggetto_id>= idmin and ms.migr_soggetto_id<=idmax
     order by ms.migr_soggetto_id)
    loop
    
     if tipoElab=TIPO_ELAB_SOGGETTO then
	    formaGiuridica:=null;
    	strMessaggio:='Inserimento siac_t_soggetto migr_soggetto_id= '||migrSoggetto.migr_soggetto_id;
	    -- siac_t_soggetto
	    -- xAnto : se migrSoggetto.fl_genera_codice = 'S' stiamo processando un delegato di COTO
        -- in questo caso controlliamo esistenza del soggetto per codice_fiscale, partita_iva, ragione_sociale
        -- se esiste recupero soggetto_id da siac_r_migr_soggetto_soggetto
        -- altrimenti giro attuale di inserimento di tutti i dati del soggetto
        
        
        
        if migrSoggetto.fl_genera_codice = 'S' then
			seq_soggetto_delegato=seq_soggetto_delegato+1;
            codice_soggetto = migrSoggetto.codice_soggetto||'||D||'||seq_soggetto_delegato;

			select soggetto_id into v_soggettoId from siac_t_soggetto 
			where ente_proprietario_id = enteProprietarioId 
			and (codice_fiscale= migrSoggetto.codice_fiscale OR partita_iva = migrSoggetto.partita_iva OR soggetto_desc = migrSoggetto.ragione_sociale);
			
			if v_soggettoId is not null then
				soggettoId := v_soggettoId;				
			end if;
			
			strMessaggio='sono in presenza di un delegato .';
            v_isDelegato := 1;
        ELSE
			codice_soggetto = migrSoggetto.codice_soggetto;
            v_isDelegato:=0;
        end if;
			
			-- se è un delegato controllo che sa stato già inserito o meno
			if v_isDelegato = 0 OR (v_isDelegato = 1 AND v_soggettoId is null ) then

			-- xAnto : aggiungere qui if ,  per non fare inserimento se il soggetto delegato esiste gia, vedi commento sopra
			insert into siac_t_soggetto
			(soggetto_code,soggetto_desc, codice_fiscale,codice_fiscale_estero,
			 validita_inizio,ambito_id,ente_proprietario_id,data_creazione,login_operazione,
			 partita_iva,login_creazione)
			 values
			(codice_soggetto,migrSoggetto.ragione_sociale,migrSoggetto.codice_fiscale,migrSoggetto.codice_fiscale_estero,
			 dataInizioVal,ambitoId,enteProprietarioId,clock_timestamp(),loginOperazione,
			 migrSoggetto.partita_iva,loginOperazione
			)
			returning soggetto_id into soggettoId;

			strMessaggio:='Inserimento siac_r_soggetto_attr migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
						  'campo note.';


			-- siac_r_soggetto_attr ( note, matricola_hr_spi )
			-- note
			insert into siac_r_soggetto_attr
			(soggetto_id,attr_id,validita_inizio, ente_proprietario_id,
			 data_creazione,login_operazione,testo
			)
			values
			(soggettoId,idAttr_noteSoggetto,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione,substring(migrSoggetto.note from 1 for NOTE_SOGG_LENGTH));

			/*
			(select soggettoId, attrSoggetto.attr_id ,CURRENT_TIMESTAMP,enteProprietarioId,
					CURRENT_TIMESTAMP,loginOperazione,substring(migrSoggetto.note from 1 for NOTE_SOGG_LENGTH)
			  from siac_t_attr attrSoggetto
			  where attrSoggetto.ente_proprietario_id=enteProprietarioId and
					attrSoggetto.attr_code=NOTE_SOGG_ATTR and
					attrSoggetto.data_cancellazione is null and
				   date_trunc('day',dataElaborazione)>=date_trunc('day',attrSoggetto.validita_inizio) and
				   (date_trunc('day',dataElaborazione)<date_trunc('day',attrSoggetto.validita_fine)
							  or attrSoggetto.validita_fine is null)
			 );*/

			 strMessaggio:='Inserimento siac_r_soggetto_attr migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
						   'campo matricola SPI.';

			 -- matricolaSpi
			 insert into siac_r_soggetto_attr
			 (soggetto_id,attr_id,validita_inizio, ente_proprietario_id,
			  data_creazione,login_operazione,testo
			 )
			 values
			 (soggettoId, idAttr_matrspi,dataInizioVal,enteProprietarioId, clock_timestamp(),loginOperazione,migrSoggetto.matricola_hr_spi);
			 /*
			 (select soggettoId, attrSoggetto.attr_id ,CURRENT_TIMESTAMP,enteProprietarioId,
					CURRENT_TIMESTAMP,loginOperazione, migrSoggetto.matricola_hr_spi
			  from siac_t_attr attrSoggetto
			  where attrSoggetto.ente_proprietario_id=enteProprietarioId and
				   attrSoggetto.attr_code=MATRSPI_SOGG_ATTR and
				   attrSoggetto.data_cancellazione is null and
				   date_trunc('day',dataElaborazione)>=date_trunc('day',attrSoggetto.validita_inizio) and
				   (date_trunc('day',dataElaborazione)<date_trunc('day',attrSoggetto.validita_fine)
							  or attrSoggetto.validita_fine is null)
			  );*/

			  -- inserimento della classe relativa al campo classif
			  if coalesce(migrSoggetto.classif,NVL_STR)!=NVL_STR then
				begin
					strMessaggio:='Inserimento classe  '||migrSoggetto.classif||' migr_soggetto_id='||
									migrSoggetto.migr_soggetto_id||'.';

					select coalesce(soggettoClasse.soggetto_classe_id)
						   into strict soggettoClasseId
					from siac_d_soggetto_classe soggettoClasse
					where soggettoClasse.ambito_id=ambitoId and
						  soggettoClasse.ente_proprietario_id=enteProprietarioId and
						  soggettoClasse.soggetto_classe_code=migrSoggetto.classif;

					exception
					 when no_data_found then
						strMessaggio:='Inserimento classe  '||migrSoggetto.classif||' migr_soggetto_id='||
									migrSoggetto.migr_soggetto_id||'.';

						insert into siac_d_soggetto_classe
						( soggetto_classe_tipo_id,soggetto_classe_code,soggetto_classe_desc,
						  validita_inizio, ambito_id,ente_proprietario_id,data_creazione,login_operazione)
						values
						( soggettoClasseTipoId,migrSoggetto.classif,migrSoggetto.classif,dataInizioVal,ambitoId,
						  enteProprietarioId,clock_timestamp(),loginOperazione)
						returning soggetto_classe_id into soggettoClasseId;
					 when others then
						 RAISE EXCEPTION 'ERRORE : %-% ', SQLSTATE,	substring(upper(SQLERRM) from 1 for 300);
				end;

				strMessaggio='Inserimento relazione  classe  '||migrSoggetto.classif||' migr_soggetto_id='||
									migrSoggetto.migr_soggetto_id||'.';
				insert into siac_r_soggetto_classe
				(soggetto_id,soggetto_classe_id,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
				values
				(soggettoId,soggettoClasseId,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);

			  end if;

			  strMessaggio:='Inserimento siac_r_soggetto_tipo migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
							'tipo '||migrSoggetto.tipo_soggetto||'.';

			  -- siac_r_soggetto_tipo
			  insert into siac_r_soggetto_tipo
			  (soggetto_id,soggetto_tipo_id,validita_inizio,ente_proprietario_id,
			   data_creazione,login_operazione)
			  (select soggettoId,tipoSoggetto.soggetto_tipo_id,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
			   from siac_d_soggetto_tipo tiposoggetto
			   where tipoSoggetto.soggetto_tipo_code=migrSoggetto.tipo_soggetto and
					 tipoSoggetto.ente_proprietario_id=enteProprietarioId and
					 tipoSoggetto.data_cancellazione is null and
					 date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSoggetto.validita_inizio) and
					(date_trunc('day',dataElaborazione)<=date_trunc('day',tipoSoggetto.validita_fine)
							  or tipoSoggetto.validita_fine is null)
			   );

			   strMessaggio:='Inserimento siac_r_soggetto_stato migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
							'tipo '||migrSoggetto.stato_soggetto||'.';

			   -- siac_r_soggetto_stato
			   INSERT INTO siac_r_soggetto_stato
			   (soggetto_id,soggetto_stato_id,validita_inizio,
				ente_proprietario_id,data_creazione,login_operazione)
			   (select soggettoId,statoSoggetto.soggetto_stato_id, dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
				from siac_d_soggetto_stato statoSoggetto
				where statoSoggetto.soggetto_stato_code=migrSoggetto.stato_soggetto and
					  statoSoggetto.ente_proprietario_id=enteProprietarioId and
					  statoSoggetto.data_cancellazione is null and
					  date_trunc('day',dataElaborazione)>=date_trunc('day',statoSoggetto.validita_inizio) and
					  (date_trunc('day',dataElaborazione)<=date_trunc('day',statoSoggetto.validita_fine)
							  or statoSoggetto.validita_fine is null)
				);

				if migrSoggetto.tipo_soggetto=SOGGETTO_PF or migrSoggetto.tipo_soggetto=SOGGETTO_PFI then
					 -- siac_t_persona_fisica  ( se PF,PFI )
					 strMessaggio:='Inserimento siac_t_persona_fisica migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
								   ' lettura comune nascita.';
					 comuneId:=null;
					 -- ricavo i dati del comune di nascita diversamente li inserisco con quanto passato
					 if coalesce (migrSoggetto.comune_nascita,NVL_STR)!=NVL_STR then
					  select * into migrComune
					  from fnc_migr_comune(migrSoggetto.comune_nascita,migrSoggetto.provincia_nascita,
										  migrSoggetto.nazione_nascita,enteProprietarioid,loginOperazione,dataElaborazione,annoBilancio);

					   if migrComune.codiceRisultato=0 then
						comuneId:=migrComune.comuneId;
					   else
						RAISE EXCEPTION ' % ', migrComune.messaggioRisultato;
					   end if;
					 end if;

					 -- SOLO SE PF ITALIANA -> PROVINCIA <> EE||
					 -- inizializzati coi dati letti da tabella di migrazione
					 if (migrSoggetto.provincia_nascita is null or migrSoggetto.provincia_nascita <> 'EE||') then
						 comunenascita := migrSoggetto.comune_nascita;
						 datanascita := migrSoggetto.data_nascita;
						 sesso := migrSoggetto.sesso;
						 -- se uno dei dati anagrafici fondamentali non viene passato da migrare si prova a dedurlo dal CF
						 if comunenascita is null or datanascita is null or sesso is null then
							 strMessaggio:='Inserimento siac_t_persona_fisica migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
									   ' spacchetta CF.';
							 select * into spacchettaCf from fnc_migr_spacchettacf(migrSoggetto.codice_fiscale) ;
							 if spacchettaCf.codiceRisultato=0 then
							  if comunenascita is null then
								comunenascita:=spacchettaCf.comunenascita;
								begin
								  select comune.comune_id into strict comuneId from siac_t_comune comune
								  where comune.comune_belfiore_catastale_code = comunenascita and comune.ente_proprietario_id=enteproprietarioid
								  order by comune_id limit 1;
								  --19.02.2016 Dani impostiamo come comune di nascita il primo inserito ancora valido
								exception
									when no_data_found then comuneId:=null;
									when too_many_rows then comuneId:=null;

									when others then RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
								end;
							  end if;
							  if datanascita is null then datanascita:=spacchettaCf.datanascita; end if;
							  if sesso is null then sesso:=spacchettaCf.sesso; end if;
							 else
								-- qualcosa è andato storto nella funzione. il flusso non viene interrotto e il soggetto è inserito nella tabella degli scarti ...
								insert into migr_soggetto_scarto
								( migr_soggetto_id ,soggetto_id , codice_soggetto , delegato_id , tipo_soggetto, codice_fiscale, partita_iva, ente_proprietario_id, data_creazione,motivo_scarto)
								VALUES
								(migrSoggetto.migr_soggetto_id,migrSoggetto.soggetto_id, migrSoggetto.codice_soggetto,migrSoggetto.delegato_id,migrSoggetto.tipo_soggetto
								, migrSoggetto.codice_fiscale, migrSoggetto.partita_iva, migrSoggetto.ente_proprietario_id, clock_timestamp(), spacchettaCf.messaggiorisultato);
							 end if;
						 end if;
					  end if;

					  strMessaggio:='Inserimento siac_t_persona_fisica migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
									 '.';
					  insert into siac_t_persona_fisica
					  (soggetto_id,nome,cognome,sesso,comune_id_nascita,nascita_data,
					   validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
					  values
					  (soggettoId,coalesce(migrSoggetto.nome,NOME_DEFAULT),coalesce(migrSoggetto.cognome,COGNOME_DEFAULT),
					   --coalesce(migrSoggetto.sesso,SESSO_DEFAULT)
					   coalesce(sesso,SESSO_DEFAULT),comuneId,
					   --date_trunc('day', coalesce( migrSoggetto.data_nascita, DATA_NASCITA_DEF )::timestamp )
					   date_trunc('day', coalesce( datanascita, DATA_NASCITA_DEF )::timestamp )
					   ,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);

					   if migrSoggetto.tipo_soggetto=SOGGETTO_PFI and
						  ( coalesce(migrSoggetto.forma_giuridica,NVL_STR) = NVL_STR or
							substring(migrSoggetto.forma_giuridica from 1
									  for position(SEPARATORE in migrSoggetto.forma_giuridica)-1) != SOGGETTO_PF) then

						strMessaggio:='Inserimento siac_r_forma_giuridica migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
									' lettura dati forma giuridica.';

						if coalesce(migrSoggetto.forma_giuridica,NVL_STR) != NVL_STR then
							formaGiuridica:=migrSoggetto.forma_giuridica;
						else
						   formaGiuridica:=FORMA_GIUR_DI;
						end if;


						 -- ricavo gli estremi della natura giuridica diversamente la inserisco con i dati passati
						 select * into migrFormaGiuridica
						 from fnc_migr_forma_giuridica(formaGiuridica,enteProprietarioid,loginOperazione,dataElaborazione,annoBilancio);

						 if migrFormaGiuridica.codiceRisultato=0 then
						  strMessaggio:='Inserimento siac_r_forma_giuridica migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
									  '.';
						  insert into siac_r_forma_giuridica
						  (soggetto_id,forma_giuridica_id,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
						  values
						 (soggettoId,migrFormaGiuridica.formaGiuridicaId,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);
						 else
						  RAISE EXCEPTION ' % ', migrFormaGiuridica.messaggioRisultato;
						end if;
					   end if;
				else
					if coalesce(migrSoggetto.forma_giuridica,NVL_STR) != NVL_STR then
						-- siac_r_forma_giuridica ( se !=PF,PFI )

					  strMessaggio:='Inserimento siac_r_forma_giuridica migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
									' lettura dati forma giuridica.';
						 -- ricavo gli estremi della natura giuridica diversamente la inserisco con i dati passati
					  select * into migrFormaGiuridica
					  from fnc_migr_forma_giuridica(migrSoggetto.forma_giuridica,enteProprietarioid,loginOperazione,dataElaborazione,annoBilancio);

					  if migrFormaGiuridica.codiceRisultato=0 then
						strMessaggio:='Inserimento siac_r_forma_giuridica migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
									  '.';
						insert into siac_r_forma_giuridica
						(soggetto_id,forma_giuridica_id,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
						values
						(soggettoId,migrFormaGiuridica.formaGiuridicaId,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);
					  else
						  RAISE EXCEPTION ' % ', migrFormaGiuridica.messaggioRisultato;
					  end if;
					end if;

					-- siac_t_persona_giuridica
					strMessaggio:='Inserimento siac_t_persona_giuridica migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
									  '.';
					INSERT INTO siac_t_persona_giuridica
					(soggetto_id,ragione_sociale,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
					VALUES
					(soggettoId,migrSoggetto.ragione_sociale,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);
				end if;

				strMessaggio:='Inserimento siac_t_indirizzo_soggetto principale migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
								   'lettura comune.';
				comuneId:=null;
				if  coalesce(migrSoggetto.comune,NVL_STR)!=NVL_STR then
				 -- ricavo i dati del comune dell'indirizzo diversamente li inserisco con quanto passato
				 select * into migrComune
				 from fnc_migr_comune(migrSoggetto.comune,migrSoggetto.prov,
									 migrSoggetto.nazione,enteProprietarioid,loginOperazione,dataElaborazione,annoBilancio);
				 if migrComune.codiceRisultato=0 then
					comuneId:=migrComune.comuneId;
				 else
					RAISE EXCEPTION ' % ', migrComune.messaggioRisultato;
				 end if;
				end if;

			-- inserisco indirizzo solo via,  comune sono valorizzati
				if coalesce(migrSoggetto.via,NVL_STR)!=NVL_STR and coalesce(migrSoggetto.comune,NVL_STR)!=NVL_STR then
				 -- siac_t_indirizzo_soggetto
					 strMessaggio:='Inserimento siac_t_indirizzo_soggetto principale migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
								   '.';
					if coalesce(migrSoggetto.tipo_via,NVL_STR)!=NVL_STR then
						INSERT INTO siac_t_indirizzo_soggetto
						(soggetto_id,via_tipo_id,toponimo, numero_civico,frazione,interno, zip_code, comune_id,
						 principale,validita_inizio, ente_proprietario_id, data_creazione, login_operazione, avviso
						 )
						 (select soggettoId,tipoVia.via_tipo_id,migrSoggetto.via,migrSoggetto.numero_civico,migrSoggetto.frazione,migrSoggetto.interno,
						  migrSoggetto.cap,comuneId,migrSoggetto.indirizzo_principale,
						  dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione,migrSoggetto.avviso
						   from siac_d_via_tipo tipoVia
							where tipoVia.via_tipo_code=migrSoggetto.tipo_via and
							tipoVia.ente_proprietario_id=enteProprietarioId AND
							tipoVia.data_cancellazione is null and
							date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',tipoVia.validita_inizio) and
							(date_trunc('seconds',dataElaborazione)<=date_trunc('seconds',tipoVia.validita_fine)
							  or tipoVia.validita_fine is null)
						  )
						  returning indirizzo_id into indirizzoId;
					else
						INSERT INTO siac_t_indirizzo_soggetto
						(soggetto_id,via_tipo_id,toponimo, numero_civico,frazione,interno, zip_code, comune_id,
						 principale,validita_inizio, ente_proprietario_id, data_creazione, login_operazione, avviso
						 )
						 values
						 (soggettoId,null,migrSoggetto.via,migrSoggetto.numero_civico,migrSoggetto.frazione,migrSoggetto.interno,
						  migrSoggetto.cap,comuneId,migrSoggetto.indirizzo_principale,
						  dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione,migrSoggetto.avviso
						  )
						  returning indirizzo_id into indirizzoId;
					end if;

			  strMessaggio:='indirizzoId : '||quote_nullable(indirizzoId)||' Inserimento siac_r_indirizzo_soggetto_tipo principale migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
									'.';
				  -- siac_r_indirizzo_soggetto_tipo
					  INSERT INTO siac_r_indirizzo_soggetto_tipo
			  (indirizzo_id,indirizzo_tipo_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
			  ( select indirizzoId,tipoIndirizzo.indirizzo_tipo_id,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
				from siac_d_indirizzo_tipo tipoIndirizzo
				where tipoIndirizzo.indirizzo_tipo_code=migrSoggetto.tipo_indirizzo and
					  tipoIndirizzo.ente_proprietario_id=enteProprietarioId and
					  tipoIndirizzo.data_cancellazione is null and
					   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoIndirizzo.validita_inizio) and
					   (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoIndirizzo.validita_fine)
							  or tipoIndirizzo.validita_fine is null)
			   );

			end if;

			strMessaggio:='Inserimento siac_t_recapito_soggetto migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
							 ' telefono 1.';
				-- siac_t_recapito_soggetto
				-- tel1
				if coalesce( migrSoggetto.tel1,NVL_STR)!=NVL_STR then
		-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
					nrecapiti := 0;
					select count(*)
					into nrecapiti
					from siac_t_recapito_soggetto reca
					where reca.ente_proprietario_id=enteProprietarioId and
						  reca.soggetto_id=soggettoId and
						  reca.recapito_code=recapitoModoCode_tel and
						  reca.recapito_desc=migrSoggetto.tel1;

					if nrecapiti = 0 then
						insert into siac_t_recapito_soggetto
						(soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
						 data_creazione, login_operazione, recapito_modo_id, avviso
						)
						values
						(soggettoId,recapitoModoCode_tel,migrSoggetto.tel1,dataInizioVal,enteProprietarioId,clock_timestamp() ,loginOperazione,recapitoModoId_tel,'N');
					/*(
					  select soggettoId,recapitoModo.recapito_modo_code,migrSoggetto.tel1,CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,
					  loginOperazione,recapitoModo.recapito_modo_id,'N'
					  from siac_d_recapito_modo recapitoModo
					  where recapitoModo.recapito_modo_code=RECAPITO_MODO_TEL and
							recapitoModo.ente_proprietario_id=enteProprietarioId and
							recapitoModo.data_cancellazione is null and
						   date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
						   (date_trunc('day',dataElaborazione)<date_trunc('day',recapitoModo.validita_fine)
							  or recapitoModo.validita_fine is null)
					);*/
					end if;
					-- DAVIDE - 21.09.015 : fine

				end if;

				strMessaggio:='Inserimento siac_t_recapito_soggetto migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
							  ' telefono 2.';

			if coalesce( migrSoggetto.tel2,NVL_STR)!=NVL_STR then
		-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
				nrecapiti := 0;
				select count(*)
				into nrecapiti
				from siac_t_recapito_soggetto reca
				where reca.ente_proprietario_id=enteProprietarioId and
					  reca.soggetto_id=soggettoId and
					  reca.recapito_code=recapitoModoCode_tel and
					  reca.recapito_desc=migrSoggetto.tel2;

				if nrecapiti = 0 then

					insert into siac_t_recapito_soggetto
					(soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
					 data_creazione, login_operazione, recapito_modo_id, avviso
					)
					values
					(soggettoId,recapitoModoCode_tel,migrSoggetto.tel2,dataInizioVal,enteProprietarioId,clock_timestamp() ,loginOperazione,recapitoModoId_tel,'N');
					/*(
					  select soggettoId,recapitoModo.recapito_modo_code,migrSoggetto.tel2,CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,
					  loginOperazione,recapitoModo.recapito_modo_id,'N'
					  from siac_d_recapito_modo recapitoModo
					  where recapitoModo.recapito_modo_code=RECAPITO_MODO_TEL and
							recapitoModo.ente_proprietario_id=enteProprietarioId and
							recapitoModo.data_cancellazione is null and
						   date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
						   (date_trunc('day',dataElaborazione)<date_trunc('day',recapitoModo.validita_fine)
							  or recapitoModo.validita_fine is null)
					);*/

				end if;
		-- DAVIDE - 21.09.015 : fine

			end if;

				strMessaggio:='Inserimento siac_t_recapito_soggetto migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
							  ' fax.';

				if coalesce(migrSoggetto.fax,NVL_STR)!=NVL_STR then
		-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
					nrecapiti := 0;
					select count(*)
					into nrecapiti
					from siac_t_recapito_soggetto reca
					where reca.ente_proprietario_id=enteProprietarioId and
						  reca.soggetto_id=soggettoId and
						  reca.recapito_code=recapitoModoCode_fax and
						  reca.recapito_desc=migrSoggetto.fax;

					if nrecapiti = 0 then
						insert into siac_t_recapito_soggetto
						(soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
						 data_creazione, login_operazione, recapito_modo_id, avviso
						)
						values
						(soggettoId,recapitoModoCode_fax,migrSoggetto.fax,dataInizioVal,enteProprietarioId,clock_timestamp(),
						 loginOperazione,recapitoModoId_fax,'N');
					/*(
					  select soggettoId,recapitoModo.recapito_modo_code,migrSoggetto.fax,CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,
					  loginOperazione,recapitoModo.recapito_modo_id,'N'
					  from siac_d_recapito_modo recapitoModo
					  where recapitoModo.recapito_modo_code=RECAPITO_MODO_FAX and
							recapitoModo.ente_proprietario_id=enteProprietarioId and
							recapitoModo.data_cancellazione is null and
						   date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
						   (date_trunc('day',dataElaborazione)<date_trunc('day',recapitoModo.validita_fine)
							  or recapitoModo.validita_fine is null)
					);*/
					end if;
		-- DAVIDE - 21.09.015 : fine
				end if;

				strMessaggio:='Inserimento siac_t_recapito_soggetto migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
							  ' sito_www.';

				if coalesce( migrSoggetto.sito_www,NVL_STR)!=NVL_STR  then
		-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
					nrecapiti := 0;
					select count(*)
					into nrecapiti
					from siac_t_recapito_soggetto reca
					where reca.ente_proprietario_id=enteProprietarioId and
						  reca.soggetto_id=soggettoId and
						  reca.recapito_code=recapitoModoCode_www and
						  reca.recapito_desc=migrSoggetto.sito_www;

					if nrecapiti = 0 then

						insert into siac_t_recapito_soggetto
						(soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
						 data_creazione, login_operazione, recapito_modo_id, avviso
						)
						values
						( soggettoId,recapitoModoCode_www, migrSoggetto.sito_www,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione,recapitoModoId_www,'N');
					/*
					(
					  select soggettoId,recapitoModo.recapito_modo_code,migrSoggetto.sito_www,CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,
					  loginOperazione,recapitoModo.recapito_modo_id,'N'
					  from siac_d_recapito_modo recapitoModo
					  where recapitoModo.recapito_modo_code=RECAPITO_MODO_WWW and
							recapitoModo.ente_proprietario_id=enteProprietarioId and
							recapitoModo.data_cancellazione is null and
						   date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
						   (date_trunc('day',dataElaborazione)<date_trunc('day',recapitoModo.validita_fine)
							  or recapitoModo.validita_fine is null)
					);*/
					end if;
		-- DAVIDE - 21.09.015 : fine
				end if;
				strMessaggio:='Inserimento siac_t_recapito_soggetto migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
							  ' email.';

				if coalesce( migrSoggetto.email,NVL_STR)!=NVL_STR  then
					strToElab:=migrSoggetto.email;
					tipoRecapitoSoggetto:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
					strToElab:=substring(migrSoggetto.email from
										 position(SEPARATORE in migrSoggetto.email)+2
										 for char_length(migrSoggetto.email)-position(SEPARATORE in migrSoggetto.email));
					recapitoSoggetto:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
					avvisoRecapitoSoggetto:=substring(strToElab from
													  position(SEPARATORE in strToElab)+2
													  for char_length(strToElab)-position(SEPARATORE in strToElab));
		-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
					nrecapiti := 0;
					select count(*)
					into nrecapiti
					from siac_t_recapito_soggetto reca
					where reca.ente_proprietario_id=enteProprietarioId and
						  reca.soggetto_id=soggettoId and
						  reca.recapito_code=tipoRecapitoSoggetto and
						  reca.recapito_desc=recapitoSoggetto;

					if nrecapiti = 0 then

						insert into siac_t_recapito_soggetto
						(soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
						 data_creazione, login_operazione, recapito_modo_id, avviso
						)
						(
						 select soggettoId,recapitoModo.recapito_modo_code,recapitoSoggetto,dataInizioVal,enteProprietarioId,clock_timestamp(),
						 loginOperazione,recapitoModo.recapito_modo_id,avvisoRecapitoSoggetto
						 from siac_d_recapito_modo recapitoModo
						 where recapitoModo.recapito_modo_code=tipoRecapitoSoggetto and
							   recapitoModo.ente_proprietario_id=enteProprietarioId and
							   recapitoModo.data_cancellazione is null and
							   date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
							   (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
								or recapitoModo.validita_fine is null)
						);
					end if;
		-- DAVIDE - 21.09.015 : fine
				end if;

				strMessaggio:='Inserimento siac_t_recapito_soggetto migr_soggetto_id= '||migrSoggetto.migr_soggetto_id||
							  ' contatto generico.';

				if coalesce(migrSoggetto.contatto_generico,NVL_STR)!=NVL_STR  then
					strToElab:=migrSoggetto.contatto_generico;
					tipoRecapitoSoggetto:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
					strToElab:=substring(migrSoggetto.contatto_generico from
										 position(SEPARATORE in migrSoggetto.contatto_generico)+2
										 for char_length(migrSoggetto.email)-position(SEPARATORE in migrSoggetto.contatto_generico));
					recapitoSoggetto:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
					avvisoRecapitoSoggetto:=substring(strToElab from
													  position(SEPARATORE in strToElab)+2
													  for char_length(strToElab)-position(SEPARATORE in strToElab));
		-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
					nrecapiti := 0;
					select count(*)
					into nrecapiti
					from siac_t_recapito_soggetto reca
					where reca.ente_proprietario_id=enteProprietarioId and
						  reca.soggetto_id=soggettoId and
						  reca.recapito_code=tipoRecapitoSoggetto and
						  reca.recapito_desc=recapitoSoggetto;

					if nrecapiti = 0 then

						insert into siac_t_recapito_soggetto
						(soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
						 data_creazione, login_operazione, recapito_modo_id, avviso
						)
						(
						 select soggettoId,recapitoModo.recapito_modo_code,recapitoSoggetto,dataInizioVal,enteProprietarioId,clock_timestamp(),
						 loginOperazione,recapitoModo.recapito_modo_id,avvisoRecapitoSoggetto
						 from siac_d_recapito_modo recapitoModo
						 where recapitoModo.recapito_modo_code=recapitoSoggetto and
							   recapitoModo.ente_proprietario_id=enteProprietarioId and
							   recapitoModo.data_cancellazione is null and
							   date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
							   (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
								or recapitoModo.validita_fine is null)
						);
					end if;
					-- DAVIDE - 21.09.015 : fine
				end if;

				---------ANTO
				end if;
			--ANTO 2 fine blocco eventuale delegato
			
            -- soggetto inserito correttamente
            -- inserimento della relazione tra il nuovo soggetto_id e migr_soggetto_id
            strMessaggio:='Inserimento siac_r_migr_soggetto_soggetto migr_soggetto_id= '||migrSoggetto.migr_soggetto_id;
			insert into siac_r_migr_soggetto_soggetto
		    (migr_soggetto_id,soggetto_id,data_creazione,ente_proprietario_id)
        	values
	        (migrSoggetto.migr_soggetto_id,soggettoId,clock_timestamp(),enteProprietarioId);

            numeroElementiInseriti:=numeroElementiInseriti+1;

		else
        	begin
            	strMessaggio:='Verifica esistenza soggetto.';
        	 	select coalesce ( migrSoggRel.soggetto_id,0) into strict soggettoId
            	from siac_r_migr_soggetto_soggetto migrSoggRel
	            where migrSoggRel.ente_proprietario_id=enteProprietarioId and
    	              migrSoggRel.migr_soggetto_id=migrSoggetto.migr_soggetto_id;

				exception
	         	 when no_data_found then
                 	RAISE EXCEPTION 'Soggetto inesistente per migr_soggetto_id=% ', migrSoggetto.migr_soggetto_id;
                 when others  THEN
      			 	RAISE EXCEPTION 'Errore lettura in soggetto per migr_soggetto_id=%: %-%.',
           					migrSoggetto.migr_soggetto_id,
             				SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
             end;
        end if;
--  fine ANTO

        if tipoElab=TIPO_ELAB_SOGGCLASSE then
			strMessaggio:='Soggetto classe.';
			select * into migrSoggettoClasse
            from fnc_migr_soggetto_classe ( migrSoggetto.soggetto_id,soggettoId,
                                            ambitoId, soggettoClasseTipoId,enteProprietarioId,
									  	    loginOperazione,dataElaborazione
                                            ,annoBilancio);
            if migrSoggettoClasse.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrSoggettoClasse.messaggioRisultato;
            end if;
       end if;

	   if tipoElab=TIPO_ELAB_INDIR_SEC then
			strMessaggio:='Indirizzi secondari.';
            select * into migrIndirSec
			from fnc_migr_indirizzo_secondario (  migrSoggetto.soggetto_id,soggettoId,
										          enteProprietarioId,loginOperazione,
 										          dataElaborazione
                                                  ,annoBilancio);

            strMessaggio := strMessaggio || migrIndirSec.messaggioRisultato;

            if migrIndirSec.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrIndirSec.messaggioRisultato;
            end if;
	   end if;

       if tipoElab=TIPO_ELAB_RECAPITO_SOGG then
            strMessaggio:='Recapiti soggetto.';
			select * into migrRecapitoSoggetto
			from fnc_migr_recapito_soggetto ( migrSoggetto.soggetto_id,soggettoId,
				  					          enteProprietarioId,loginOperazione,
										      dataElaborazione
                                              ,annoBilancio);
            if migrRecapitoSoggetto.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrRecapitoSoggetto.messaggioRisultato;
            end if;
        end if;

        if tipoElab=TIPO_ELAB_SEDE_SEC then
			strMessaggio:='Sedi secondarie.';
			select * into migrSedeSec
            from fnc_migr_sede_secondaria ( migrSoggetto.soggetto_id,soggettoId,
--            								to_char(migrSoggetto.codice_soggetto),
                                            migrSoggetto.codice_soggetto::varchar,
                                            ambitoId,enteProprietarioId,
										    loginOperazione, dataElaborazione
                                            , annoBilancio);
            if migrSedeSec.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrSedeSec.messaggioRisultato;
            end if;
		end if;

        if tipoElab=TIPO_ELAB_MDP then
            strMessaggio:='Modalita Pagamento.';
			select * into migrModPag
            from fnc_migr_modpag (migrSoggetto.soggetto_id,soggettoId,
								  enteProprietarioId,loginOperazione,dataElaborazione
                                  ,annoBilancio);
            if migrModPag.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrModPag.messaggioRisultato;
            end if;

		end if;

    end loop;

   if tipoElab=TIPO_ELAB_SOGGETTO then
    strMessaggio:='Aggiornamento progressivi.';
   	select *  into migrAggiornaProgr
    from fnc_aggiorna_progressivi(enteProprietarioId,KEY_PROGR,loginOperazione);
    if migrAggiornaProgr.codResult=-1 then
		RAISE EXCEPTION ' % ', migrAggiornaProgr.messaggioRisultato;
    end if;
   end if;

	if tipoElab=TIPO_ELAB_MDP then
   		strMessaggio:='Aggiornamento fl_elab migr_soggetto.';
   		UPDATE migr_soggetto
   		SET fl_elab='S'
   		where fl_elab='N'
   		and migr_soggetto_id>= idmin and migr_soggetto_id<=idmax;
	end if;

   if tipoElab=TIPO_ELAB_SOGGETTO then
	   RAISE NOTICE 'NumeroSoggettiInseriti %', numeroElementiInseriti;
       messaggioRisultato:=strMessaggioFinale||'Inseriti '||numeroElementiInseriti||' soggetti.';
   else    messaggioRisultato:=strMessaggioFinale||strMessaggio||'Elaborazione OK.';
   end if;

   numeroSoggettiInseriti:= numeroElementiInseriti;
   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 800);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 800) ;
        numeroSoggettiInseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 800);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 800) ;
        numeroSoggettiInseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;