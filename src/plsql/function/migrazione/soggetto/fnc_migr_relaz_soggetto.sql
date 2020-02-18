/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
<<<<<<< .mine
create or replace function fnc_migr_relaz_soggetto(  enteProprietarioId integer,
=======
Create or replace function fnc_migr_relaz_soggetto(  enteProprietarioId integer,
>>>>>>> .r10916
		                                             loginOperazione varchar,
         		                                     dataElaborazione timestamp,
                                                     annoBilancio varchar,
	                                             	 out codiceRisultato integer,
		                                             out messaggioRisultato varchar
         		                                   )
RETURNS record AS
$body$
DECLARE
 -- fnc_migr_relaz_soggetto -- function che effettua il caricamento delle relazione tra soggetti migrati
 --                            per ente_proprietario_id=enteProprietarioId, leggendo da migr_relaz_soggetto
 --                            i soggetti devono essere stati caricati in siac_t_soggetto
 -- LE RELAZIONE GESTITE ATTUALMENTE SONO DI TIPO CESSIONE
   -- CSC-CESSIONE CREDITO
   -- CSI-CESSIONE INCASSO
   -- CATENA - CATENA SOGGETTI COTO
 -- effettua inserimento di
  -- siac_r_soggetto_relaz -- relazione tra soggetti
  -- siac_r_soggrel_modpag -- relazione tra una MDP e una relazione tra soggetti (CSI-CSC)
  -- siac_r_migr_relaz_soggetto_relaz -- traccia migr_soggetto_relaz.migr_ralaz_id -- siac_r_soggetto_relaz.soggetto_relaz_id
  -- Per il tipo di relazione CSC
  -- soggetto_id_da = soggetto caricato in siac_t_soggetto < migr_soggetto.soggetto_id=migr_relaz_soggetto.soggetto_id_da per ente >
  -- soggetto_id_a  = soggetto caricaricato in siac_t_soggetto riferito modpag_id_a ( vedasi di seguito)
  -- modpag_id_a    = MDP caricata in siac_t_modpag <migr_modpag.modpag_id=migr_relaz_soggetto.modpag_id_a per ente >
  --                  se la MDP deriva da una sede <migr_modpag.sede_secondaria='S'>, allora il suo soggetto di riferimento
  --                  sara'' una sede
  -- Per il tipo di relazione CSI
  -- soggetto_id_da = se modpag_id_da non ha dato origine ad una sede
    -- soggetto caricato in siac_t_soggetto < migr_soggetto.soggetto_id=migr_relaz_soggetto.soggetto_id_da per ente >
    -- diversamente ricavato dalla sede (NOTA. in questo caso la MDP non esiste nel siac )
    -- sede_id= migr_modpag.sede_id < migr_modpag.modpag_id=migr_relaz_soggetto.modpag_id_da per ente >
    -- quindi da siac_r_migr_sede_secondaria_rel_sede si ricava il soggetto_id riferito alla sede
  -- soggetto_id_a,modpag_id_a  = ricavato come per CSC
  -- Per il tipo di relazione CATENA
  -- soggetto_id_da = soggetto caricato in siac_t_soggetto < migr_soggetto.soggetto_id=migr_relaz_soggetto.soggetto_id_da per ente >
     -- vecchio soggetto
  -- soggetto_id_a  = soggetto caricaricato in siac_t_soggetto < migr_soggetto.soggetto_id=migr_relaz_soggetto.soggetto_id_a per ente >
     -- nuovo soggetto
 -- la fnc restituisce
   -- messaggioRisultato = risulato elaborazine in formato testo
   -- codiceRisultato    = codice risultato elaborazione 0 ( elaborazione OK ) -1 (errore) -12 ( dati non presenti in migr_relaz_soggetto)


 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 countRelazSoggetto integer:=0;
 migrRelazSoggetto  record;

 migrDatiCessione record;
 migrDatiCessioneSede record;

 soggettoIdDa integer:=0;
 modpagIdDa integer:=0;

 soggettoIdA integer:=0;
 modpagIdA integer:=0;

 soggettoRelazId integer:=0;

 migrSoggettoId integer:=0;
 STATO_RELAZ_VALIDO CONSTANT varchar:='VALIDO';

 RELAZIONE_CSC    CONSTANT varchar:='CSC';
 RELAZIONE_CSI    CONSTANT varchar:='CSI';
 RELAZIONE_CATENA    CONSTANT varchar:='CATENA';

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

 code varchar(200):='';
 id_statoRelazValido integer := 0;
 soggrelmpagId integer := 0;
 ordineMdp integer :=0;
 modpagordId integer :=0;

begin

	messaggioRisultato:='';
    codiceRisultato:=0;

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Gestione inserimento relazioni soggetto ente='||enteProprietarioId||'.';

	strMessaggio:='Verifica esistenza relazioni soggetto.';

	select COALESCE(count(*),0) into countRelazSoggetto
    from migr_relaz_soggetto ms
    where ms.ente_proprietario_id=enteProprietarioId and
          ms.fl_elab='N';


	if COALESCE(countRelazSoggetto,0)=0 then
    	 messaggioRisultato:=strMessaggioFinale||'Nessuna relazione fra soggetti da creare.';
         codiceRisultato:=-12;
         return;
    end if;
	-- fk lette una sola volta
	begin
    	code := STATO_RELAZ_VALIDO;
		select relazStato.relaz_stato_id into strict id_statoRelazValido
			from siac_d_relaz_stato relazStato
            where relazStato.relaz_stato_code=STATO_RELAZ_VALIDO and
                  relazStato.ente_proprietario_id=enteProprietarioId and
                  relazStato.data_cancellazione is null and
                  date_trunc('day',dataElaborazione)>=date_trunc('day',relazStato.validita_inizio) and
                      (date_trunc('day',dataElaborazione)<=date_trunc('day',relazStato.validita_fine)
                   or relazStato.validita_fine is null);
	exception
    	when no_data_found then
			RAISE EXCEPTION 'Code % non presente in archivio',code;
        when others  THEN
           	RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

    -- migr_relaz_id
    -- tipo_relazione
    -- relaz_id
    -- soggetto_id_da
    -- modpag_id_da
    -- soggetto_id_a
    -- modpag_id_a
    strMessaggio:='Lettura  relazioni soggetto.';
   for migrRelazSoggetto in
    ( select migrRelSog.*
     from migr_relaz_soggetto migrRelSog
     where migrRelSog.ente_proprietario_id=enteProprietarioId and
           migrRelSog.fl_elab='N'
     order by migrRelSog.relaz_id
    )
    loop
    		if migrRelazSoggetto.tipo_relazione=RELAZIONE_CSC then -- CESSIONE CREDITO
				-- se CSC
				-- soggetto_id_da=codice_soggetto_da ( cedente )
				-- soggetto_id_a=codice_soggetto_a
				-- siac_r_soggrel_modpag.modpag_id=modpag_id_a codice_soggetto_a,codice_modpag_a
            	-- se modpag_id_a e riferito ad un sede il legame va creato rispetto al soggetto sede
	            -- (in realta ricavando il modpag_id in siac, si risale al soggetto_id che in caso di
                -- MDP da sede_secondaria e gia il soggetto relativo alla sede)
                -- verifico invece se il tipo di cessione passato sulla MDP corrisponde a CSC
                -- diversamente ERRORE

				strMessaggio:='Lettura dati tipo CESSIONE '||RELAZIONE_CSC||' MDP su cui e ceduto il credito modpag_id_a='
                			||migrRelazSoggetto.modpag_id_a||'su migr_relaz_soggetto relaz_id='||migrRelazSoggetto.relaz_id||'.';

    	        -- Lettura dati cessione sulla modalita di pagamento sulla quale e ceduto il credito
        	    select migrModPag.migr_modpag_id,migrModPag.cessione
                       into migrDatiCessione
	            from migr_modpag migrModPag
	           	where migrModPag.modpag_id=migrRelazSoggetto.modpag_id_a and
                  	  migrModPag.ente_proprietario_id=enteProprietarioId;

                if  migrDatiCessione.cessione!=RELAZIONE_CSC then
                	RAISE EXCEPTION 'Tipo CESSIONE errata per MDP su cui e ceduto il credito.';
                end if;

				strMessaggio:='Lettura siacModPagIdA,siacSoggettoIdA per CESSIONE '||RELAZIONE_CSC||' MDP su cui e ceduto il credito modpag_id_a='
                			||migrRelazSoggetto.modpag_id_a||'su migr_relaz_soggetto relaz_id='||migrRelazSoggetto.relaz_id||'.';
                --  Lettura modpag_id e soggetto_id in siac x _A, se sede secondaria, la MDP e associata al soggetto_id della sede
				select coalesce(siacModPag.modpag_id,0), coalesce(siacModPag.soggetto_id,0)
                	   into modpagIdA, soggettoIdA
	            from siac_r_migr_modpag_modpag  migrRelModPag,siac_t_modpag siacModPag
           		where migrRelModPag.migr_modpag_id=migrDatiCessione.migr_modpag_id and
                  	  siacModPag.modpag_id=migrRelModPag.modpag_id;

                if soggettoIdA=0 or modpagIdA=0 then
                	RAISE EXCEPTION 'Indetificativi non reperiti.';
                end if;

				strMessaggio:='Lettura siacSoggettoIdDa per CESSIONE '||RELAZIONE_CSC||' soggetto cedente il credito soggetto_id_da='
                			||migrRelazSoggetto.soggetto_id_da||'su migr_relaz_soggetto relaz_id='||migrRelazSoggetto.relaz_id||'.';

                -- Lettura soggetto_id in siac per _DA
                select coalesce(migrSoggettoRel.soggetto_id,0) into soggettoIdDa
                from siac_r_migr_soggetto_soggetto migrSoggettoRel, migr_soggetto migrSoggetto
                where migrSoggetto.soggetto_id=migrRelazSoggetto.soggetto_id_da and
                      migrSoggetto.ente_proprietario_id=enteProprietarioId and
                      migrSoggettoRel.migr_soggetto_id=migrSoggetto.migr_soggetto_id and
                      migrSoggettoRel.ente_proprietario_id=enteProprietarioId;

                 if soggettoIdDa = 0 then
                 	RAISE EXCEPTION 'Indetificativo non reperito.';
                 end if;
            elsif migrRelazSoggetto.tipo_relazione=RELAZIONE_CSI then --- CESSIONE INCASSO

				-- se CSI
				-- soggetto_id_da=codice_soggetto_da
                -- modpag_id_da = codice_modpag_da ( questa MDP non e inserita in siac ma puo avere dato origine ad una sede sec.
				-- soggetto_id_a=codice_soggetto_a (ceduto)
				-- siac_r_soggrel_modpag.modpag_id=modpag_id_a codice_soggetto_a,codice_modpag_a ( ceduto)
				-- se modpag_id_a e riferito ad un sede il legame va creato rispetto al soggetto sede
				-- (quindi cercare codice_modpag di modpag_id_a in migr_sede_secondaria e verificare se e diventata una sede)
				-- se modpag_id_da e riferito ad una sede, analogamente il legame creato rispetto al soggetto sede.

				strMessaggio:='Lettura dati tipo CESSIONE '||RELAZIONE_CSI||' MDP soggetto che cede incasso modpag_id_da='
                			||migrRelazSoggetto.modpag_id_da||'su migr_relaz_soggetto relaz_id='||migrRelazSoggetto.relaz_id||'.';

                -- Lettura dati cessione sulla modalita di pagamento
        	    select migrModPag.migr_modpag_id,migrModPag.cessione,migrModPag.sede_secondaria, migrModPag.sede_id
                       into migrDatiCessioneSede
	            from migr_modpag migrModPag
	           	where migrModPag.modpag_id=migrRelazSoggetto.modpag_id_da and
                  	  migrModPag.ente_proprietario_id=enteProprietarioId;

                if  migrDatiCessioneSede.cessione!=RELAZIONE_CSI then
                	RAISE EXCEPTION 'Tipo CESSIONE errata per MDP che cede incasso.';
                end if;

                --  Lettura soggetto_id in siac x _Da

                if migrDatiCessioneSede.sede_secondaria='S' then
   					strMessaggio:='Lettura siacSoggettoIdDa da soggetto sede sec. per CESSIONE '||RELAZIONE_CSI||' MDP soggetto che cede incasso modpag_id_da='
                			||migrRelazSoggetto.modpag_id_da||'su migr_relaz_soggetto relaz_id='||migrRelazSoggetto.relaz_id||'.';

                	select coalesce(soggettoRelaz.soggetto_id_a,0) into soggettoIdDa
           			from siac_r_migr_sede_secondaria_rel_sede migrRelSede, siac_r_soggetto_relaz soggettoRelaz,
                         migr_sede_secondaria migrSedeSec
		            where migrSedeSec.sede_id=migrDatiCessioneSede.sede_id and
        		          migrSedeSec.ente_proprietario_id=enteProprietarioId and
                		  migrRelSede.migr_sede_id=migrSedeSec.migr_sede_id and
		                  migrRelSede.ente_proprietario_id=enteProprietarioId and
        		          soggettoRelaz.soggetto_relaz_id=migrRelSede.soggetto_relaz_id and
                		  soggettoRelaz.ente_proprietario_id=enteProprietarioId;
                else

                    strMessaggio:='Lettura siacSoggettoIdDa per CESSIONE '||RELAZIONE_CSI||' MDP soggetto che cede incasso modpag_id_da='
                			||migrRelazSoggetto.modpag_id_da||'su migr_relaz_soggetto relaz_id='||migrRelazSoggetto.relaz_id||'.';

                    select coalesce (migrRelSogg.soggetto_id,0)  into  soggettoIdDa
		        	from siac_r_migr_soggetto_soggetto  migrRelSogg,migr_soggetto migrSoggetto
        	   		where migrSoggetto.soggetto_id=migrRelazSoggetto.soggetto_id_da and
            	  	  	  migrSoggetto.ente_proprietario_id=enteProprietarioId and
		        	      migrRelSogg.migr_soggetto_id=migrSoggetto.migr_soggetto_id;

                end if;

                if soggettoIdDa=0  then
                	RAISE EXCEPTION 'Indetificativo non reperito.';
                end if;

				strMessaggio:='Lettura siacModPagIdA,siacSoggettoIdA per CESSIONE '||RELAZIONE_CSI||' MDP su cui e ceduto incasso modpag_id_a='
                			||migrRelazSoggetto.modpag_id_a||'su migr_relaz_soggetto relaz_id='||migrRelazSoggetto.relaz_id||'.';

                 --  Lettura modpag_id e soggetto_id in siac x _A
				select coalesce(siacModPag.modpag_id,0), coalesce(siacModPag.soggetto_id,0)
                	   into modpagIdA, soggettoIdA
	            from siac_r_migr_modpag_modpag  migrRelModPag, migr_modpag migrModPag, siac_t_modpag siacModPag
           		where migrModPag.modpag_id=migrRelazSoggetto.modpag_id_a and
                	  migrModPag.ente_proprietario_id=enteProprietarioId and
                	  migrRelModPag.migr_modpag_id=migrModPag.migr_modpag_id and
                      siacModPag.modpag_id=migrRelModPag.modpag_id;

                if soggettoIdA=0 or modpagIdA=0 then
                	RAISE EXCEPTION 'Indetificativi non reperiti.';
                end if;
			else --- CATENA SOGGETTI        02.03.015 Sofia - aggiunta gestione relazione CATENA soggetti
                 -- se CATENA
				 -- soggetto_id_da=codice_soggetto_vecchio
                 -- soggetto_id_a =codice_soggetto_nuovo

                 strMessaggio:='Lettura siacSoggettoIdDa per relazione= '||RELAZIONE_CATENA||' soggetto vecchio soggetto_id_da='
                			||migrRelazSoggetto.soggetto_id_da||'su migr_relaz_soggetto relaz_id='||migrRelazSoggetto.relaz_id||'.';

                -- Lettura soggetto_id in siac per _DA
                select coalesce(migrSoggettoRel.soggetto_id,0) into soggettoIdDa
                from siac_r_migr_soggetto_soggetto migrSoggettoRel, migr_soggetto migrSoggetto
                where migrSoggetto.soggetto_id=migrRelazSoggetto.soggetto_id_da and
                      migrSoggetto.ente_proprietario_id=enteProprietarioId and
                      migrSoggettoRel.migr_soggetto_id=migrSoggetto.migr_soggetto_id and
                      migrSoggettoRel.ente_proprietario_id=enteProprietarioId;

                 if soggettoIdDa = 0 then
                 	RAISE EXCEPTION 'Indetificativo non reperito.';
                 end if;

                strMessaggio:='Lettura siacSoggettoIdA per relazione= '||RELAZIONE_CATENA||' soggetto nuovo soggetto_id_a='
	               			||migrRelazSoggetto.soggetto_id_a||'su migr_relaz_soggetto relaz_id='||migrRelazSoggetto.relaz_id||'.';

                -- Lettura soggetto_id in siac per _A
                select coalesce(migrSoggettoRel.soggetto_id,0) into soggettoIdA
                from siac_r_migr_soggetto_soggetto migrSoggettoRel, migr_soggetto migrSoggetto
                where migrSoggetto.soggetto_id=migrRelazSoggetto.soggetto_id_a and
                      migrSoggetto.ente_proprietario_id=enteProprietarioId and
                      migrSoggettoRel.migr_soggetto_id=migrSoggetto.migr_soggetto_id and
                      migrSoggettoRel.ente_proprietario_id=enteProprietarioId;

                 if soggettoIdA = 0 then
                 	RAISE EXCEPTION 'Indetificativo non reperito.';
                 end if;

            end if;

/*      11.03.2016 Sofia - tolto controllo di esistenza della relazione poiche da applicativo viene inserita una relazione nuova per ogni
        MDP   di cessione - potrebbe andare in errore in migrazione per un indice unico su soggetto_id_da, soggetto_id_a ,relaz_tipo_id, validita_inizio
        sulla validita inizio non viene aggiornato il timestamp in migrazione se andasse in errore dobbiamo fare in modo che venga aggiornato
	        begin
            	strMessaggio='Verifica esistenza  siac_r_soggetto_relaz tipo relazione '||migrRelazSoggetto.tipo_relazione||
				    	         ' migr_relaz_id='||migrRelazSoggetto.migr_relaz_id||'.';

            	select relaz.soggetto_relaz_id into strict soggettoRelazId
                from siac_r_soggetto_relaz relaz, siac_d_relaz_tipo relazTipo
                where relaz.soggetto_id_da = soggettoIdDa and
                      relaz.soggetto_id_a  = soggettoIdA AND
                      relaz.ente_proprietario_id=enteProprietarioId and
                      relazTipo.relaz_tipo_id=relaz.relaz_tipo_id and
                      relazTipo.ente_proprietario_id=enteProprietarioId and
                      relazTipo.data_cancellazione is null and
	           	  	   date_trunc('day',dataElaborazione)>=date_trunc('day',relazTipo.validita_inizio) and
			  		   (date_trunc('day',dataElaborazione)<=date_trunc('day',relazTipo.validita_fine)
	    	        	  or relazTipo.validita_fine is null) and
                      relazTipo.relaz_tipo_code=migrRelazSoggetto.tipo_relazione;

                exception
		           when no_data_found then*/
                   	strMessaggio='Inserimento  siac_r_soggetto_relaz tipo relazione '||migrRelazSoggetto.tipo_relazione||
				    	         ' migr_relaz_id='||migrRelazSoggetto.migr_relaz_id||'.';

					insert into siac_r_soggetto_relaz
	    		    (relaz_tipo_id,soggetto_id_da,soggetto_id_a,
					 validita_inizio, ente_proprietario_id, data_creazione,login_operazione)
--	    		    (select relazTipo.relaz_tipo_id,soggettoIdDa,soggettoIdA,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
-- 21.03.2016 Sofia validita_inizio=clock_timestamp() altrimenti va in errore sulle relazioni uguali
	    		    (select relazTipo.relaz_tipo_id,soggettoIdDa,soggettoIdA,clock_timestamp(),enteProprietarioId,clock_timestamp(),loginOperazione
		    	     from siac_d_relaz_tipo relazTipo
        			 where relazTipo.relaz_tipo_code=migrRelazSoggetto.tipo_relazione and
            			   relazTipo.ente_proprietario_id=enteProprietarioId and
			               relazTipo.data_cancellazione is null and
        		   	  	   date_trunc('day',dataElaborazione)>=date_trunc('day',relazTipo.validita_inizio) and
		  				   (date_trunc('day',dataElaborazione)<=date_trunc('day',relazTipo.validita_fine)
			            	  or relazTipo.validita_fine is null)
        		     )
		    	     returning soggetto_relaz_id into soggettoRelazId;

        		    strMessaggio='Inserimento  siac_r_soggetto_relaz_stato tipo relazione '||migrRelazSoggetto.tipo_relazione||
						          ' migr_relaz_id='||migrRelazSoggetto.migr_relaz_id||'.';
					 INSERT INTO siac_r_soggetto_relaz_stato
					 (soggetto_relaz_id, relaz_stato_id, validita_inizio, ente_proprietario_id,data_creazione, login_operazione)
                     values
                     (soggettoRelazId,id_statoRelazValido,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);
		        	 /*(select soggettoRelazId,relazStato.relaz_stato_id,CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
	    		      from siac_d_relaz_stato relazStato
		    	      where	relazStato.relaz_stato_code=STATO_RELAZ_VALIDO and
	    		            relazStato.ente_proprietario_id=enteProprietarioId and
		        		  	relazStato.data_cancellazione is null and
		        	    	date_trunc('day',dataElaborazione)>=date_trunc('day',relazStato.validita_inizio) and
							  	(date_trunc('day',dataElaborazione)<date_trunc('day',relazStato.validita_fine)
			    		     or relazStato.validita_fine is null)
		    	      );*/


/*  13.03.2016 Sofia vedi commento sopra --
              when others  THEN
    	         RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
            end;*/

            strMessaggio='Inserimento  siac_r_migr_relaz_soggetto_relaz tipo relazione '||migrRelazSoggetto.tipo_relazione||
			          ' migr_relaz_id='||migrRelazSoggetto.migr_relaz_id||'.';
		    INSERT INTO siac_r_migr_relaz_soggetto_relaz
        	(migr_relaz_id,soggetto_relaz_id, data_creazione, ente_proprietario_id)
			VALUES
    	    (migrRelazSoggetto.migr_relaz_id, soggettoRelazId,CURRENT_TIMESTAMP,enteProprietarioId);

            -- 02.03.015 Sofia - per RELAZIONE CATENA non serve inserire relazione rispetto a MDP
            if  ( migrRelazSoggetto.tipo_relazione!=RELAZIONE_CATENA) then
           	 strMessaggio='Ricerca  siac_r_soggrel_modpag tipo relazione '||migrRelazSoggetto.tipo_relazione||
				          ' migr_relaz_id='||migrRelazSoggetto.migr_relaz_id||'.'
                          ||'soggettoRelazId:'||soggettoRelazId
                          ||', modpagIdA:'||modpagIdA
                          ||', dataInizioVal:'||dataInizioVal;
			 begin
            	select soggrelmpag_id into strict soggrelmpagId
                from siac_r_soggrel_modpag
                where soggetto_relaz_id = soggettoRelazId and modpag_id = modpagIdA
                --and validita_inizio = dataInizioVal
                and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
		  				      (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine)
			            	  or validita_fine is null)
                and ente_proprietario_id = enteProprietarioId
                and data_cancellazione is null;
             exception
              when no_data_found THEN
            	strMessaggio='Inserimento  siac_r_soggrel_modpag tipo relazione '||migrRelazSoggetto.tipo_relazione||
				          ' migr_relaz_id='||migrRelazSoggetto.migr_relaz_id||'.';
                INSERT INTO siac_r_soggrel_modpag
                (soggetto_relaz_id,modpag_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione,login_creazione)
                VALUES
                (soggettoRelazId,modpagIdA,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione,loginOperazione)
                returning soggrelmpag_id into soggrelmpagId;
              when others then
              	RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
            end;
            -- 05.03.2015 Daniela: Inserimento record nella tab. siac_r_modpag_ordine
            strMessaggio:='Ricerca ordine in siac_r_modpag_ordine per soggetto_id= '||soggettoIdDa||'.';
            begin
              select ordine into strict ordineMdp
              from siac_r_modpag_ordine where soggetto_id = soggettoIdDa order by ordine desc limit 1;
            exception when no_data_found then
                ordineMdp := 0;
            end;
		    begin
				strMessaggio:='Ricerca in siac_r_modpag_ordine di un record valido per soggetto_id= '||soggettoIdDa
                          ||' ,relazione soggetti/mdp '||soggrelmpagId
                          ||' ,valido al '||date_trunc('day',dataElaborazione)||'.';
              -- ricerca di un record valido ad oggi
			  select modpagord_id into strict modpagordId  from siac_r_modpag_ordine
              where soggetto_id = soggettoIdDa and soggrelmpag_id = soggrelmpagId
  			  and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
		  				    (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine)
			            	  or validita_fine is null);
            exception
              when no_data_found THEN
				strMessaggio:='Inserimento siac_r_modpag_ordine  soggetto_id= '||soggettoIdDa
                          ||' per relazione soggetti/mdp '||soggrelmpagId||'.';
                insert into siac_r_modpag_ordine
                (soggetto_id,soggrelmpag_id,ordine,validita_inizio,ente_proprietario_id,
                 data_creazione, login_operazione, login_creazione)
                values
-- 01.07.2016 Sofia non incrementava ordine in questo caso e creava codici duplicati a parita di soggetto
---               (soggettoIdDa,soggrelmpagId,ordineMdp,dataInizioVal,
                (soggettoIdDa,soggrelmpagId,ordineMdp+1,dataInizioVal,
                 enteProprietarioId,clock_timestamp(),loginOperazione,loginOperazione);
              when others then
              	RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
            end;
           end if;
    end loop;

    update migr_relaz_soggetto set fl_elab='S'
     where ente_proprietario_id=enteProprietarioId and
           fl_elab='N';

    codiceRisultato:= codRet;
    messaggioRisultato:=strMessaggioFinale||'Elaborazione OK.';

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :  '||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;