/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_sede_secondaria ( soggettoId integer,
												      siacSoggettoId integer,
                                                      siacSoggettoCode varchar,
                                                      ambitoId integer,
												      enteProprietarioId integer,
		  										      loginOperazione    varchar,
 												      dataElaborazione timestamp,
                                                      annobilancio varchar,
												      out codiceRisultato integer,
												      out messaggioRisultato varchar
												     )
RETURNS record AS
$body$
DECLARE
 -- fnc_sede_secondaria -- function che effettua il caricamento delle sedi secondarie ( leggendo da migr_sede_secondaria )
 --                        per il  siacSoggettoId passato in input
 --                        il soggetto deve essere presente in siac_t_soggetto con soggetto_id=siacSoggettoId
 --                        soggettoId=migr_soggetto.soggetto_id
 --                        siacSoggettoCode=valore presente in siac_t_soggetto.soggetto_code
 --                        ambitoId=siac_d_ambito.ambito_id per AMBITO_FIN per ente_proprietario_id=enteProprietarioId
 -- richiama fnc_migr_comune per ricavare comune_id per gli indirizzi delle sedi secondarie del soggetto
 -- effettua inserimento di
   -- siac_t_soggetto -- per anagrafica della sede (siac_r_soggetto_stato,siac_r_soggetto_attr<note>)
   -- siac_t_indirizzo_soggetto -- per indirizzo della sede (siac_r_indirizzo_soggetto_tipo)
   -- siac_t_recapito_soggetto  -- per gli eventuali recapiti da attruibuire alla sede stessa o al soggetto di riferimento
   --                              come indicato in migr_sede_secondaria
   -- siac_r_soggetto_relaz -- per inserimento della relazione SEDE_SECONDARIA tra soggetto principale e sede
   -- siac_r_migr_sede_secondaria_rel_sede -- per tracciare
    -- migr_sede_secondaria.migr_sede_id -- siac_r_soggetto_relaz.soggetto_relaz_id
 -- la fnc restituisce
  -- messaggioRisultato = risulato elaborazine in formato testo
  -- codiceRisultato    = codice risultato elaborazione 0 ( elaborazione OK ) -1 (errore) -12 ( dati non presenti in migr_sede_secondaria)

  SEPARATORE			CONSTANT  varchar :='||';

 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 countMigrSedeSec integer:=0;
 migrSedeSecondaria record;
 migrComune record;


 soggettoSedeId integer :=null;
 soggettoRecapitoId integer :=null;
 soggettoRelazId integer:=null;
 indirizzoId integer:=null;
 comuneId    integer:=null;
 progSedeSogg numeric(10):=0;
 strProgSede varchar(100):='';

 strToElab varchar(1000):='';
 riferimentoRecapito varchar(1000):='';
 avvisoRecapitoSede varchar(1000):='';
 recapitoSede varchar(1000):='';
 tipoRecapitoSede varchar(1000):='';

 STATO_SOGGETTO_SEDE_VALIDO CONSTANT varchar:='VALIDO';


 RECAPITO_RIF_SOGG CONSTANT varchar:='SO';

 RECAPITO_MODO_TEL CONSTANT varchar:='telefono';
 RECAPITO_MODO_FAX CONSTANT varchar:='fax';
 RECAPITO_MODO_WWW CONSTANT varchar:='sito';

 NOTE_SOGG_ATTR      CONSTANT  varchar :='NoteSoggetto';

 NOTE_SOGG_LENGTH CONSTANT integer :=500;

 NVL_STR CONSTANT varchar :='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
	--dataInizioVal timestamp :=annoBilancio||'-01-01';
	dataInizioVal timestamp :=null;

    -- dichiarazione variabili per fk lette una volta
    code varchar(200):='';
    idAttr_noteSoggetto integer := 0;
    idStatoSoggettoValido integer := 0;
    recapitoModoId_tel integer := 0;
    recapitoModoCode_tel varchar:=NULL;
    recapitoModoId_fax integer := 0;
    recapitoModoCode_fax varchar:=NULL;
    recapitoModoId_www integer := 0;
    recapitoModoCode_www varchar:=NULL;
	-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
    nrecapiti integer:=0;
	-- DAVIDE - 21.09.015 : fine

begin

	messaggioRisultato:='';
    codiceRisultato:=0;

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Gestione inserimento sedi secondarie soggetto per soggetto_id '||soggettoId||' in migr_soggetto.';

	strMessaggio:='Verifica esistenza sedi sec. per il soggetto indicato.';

	select COALESCE(count(*),0) into countMigrSedeSec
    from migr_sede_secondaria ms
    where ms.soggetto_id=soggettoId and
          ms.ente_proprietario_id=enteProprietarioId and
          ms.fl_elab='N';

	if COALESCE(countMigrSedeSec,0)=0 then
    	 messaggioRisultato:=strMessaggioFinale||'Nessuna sede secondaria presente per il soggetto indicato.';
         codiceRisultato:=-12;
         return;
    end if;


   -- migr_indirizzo_id
   -- sede_id
   -- soggetto_id
   -- codice_indirizzo
   -- codice_modpag
   -- ragione_sociale
   -- tel1
   -- tel2
   -- fax
   -- sito_www
   -- email
   -- contatto_generico
   -- note
   -- tipo_relazione
   -- tipo_indirizzo
   -- indirizzo_principale
   -- tipo_via
   -- via
   -- numero_civico
   -- interno
   -- frazione
   -- cap
   -- comune
   -- prov
   -- nazione
   -- avviso

	-- fk lette una sola volta
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

		code := STATO_SOGGETTO_SEDE_VALIDO;
	    select statoSoggetto.soggetto_stato_id into strict idStatoSoggettoValido
        from siac_d_soggetto_stato statoSoggetto
        where statoSoggetto.soggetto_stato_code=STATO_SOGGETTO_SEDE_VALIDO and
		      statoSoggetto.ente_proprietario_id=enteProprietarioId and
              statoSoggetto.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',statoSoggetto.validita_inizio) and
		      (date_trunc('day',dataElaborazione)<=date_trunc('day',statoSoggetto.validita_fine)
		            or statoSoggetto.validita_fine is null);

		code := RECAPITO_MODO_TEL;
         select recapitoModo.recapito_modo_code,recapitoModo.recapito_modo_id
         into strict recapitoModoCode_tel, recapitoModoId_tel
         from siac_d_recapito_modo recapitoModo
         where recapitoModo.recapito_modo_code=RECAPITO_MODO_TEL and
               recapitoModo.ente_proprietario_id=enteProprietarioId and
               recapitoModo.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
               (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
                  or recapitoModo.validita_fine is null);

		code := RECAPITO_MODO_FAX;
         select recapitoModo.recapito_modo_code,recapitoModo.recapito_modo_id
         into strict recapitoModoCode_fax, recapitoModoId_fax
         from siac_d_recapito_modo recapitoModo
         where recapitoModo.recapito_modo_code=RECAPITO_MODO_FAX and
               recapitoModo.ente_proprietario_id=enteProprietarioId and
               recapitoModo.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
               (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
                  or recapitoModo.validita_fine is null);

		code := RECAPITO_MODO_WWW;
         select recapitoModo.recapito_modo_code,recapitoModo.recapito_modo_id
         into strict recapitoModoCode_www, recapitoModoId_www
         from siac_d_recapito_modo recapitoModo
         where recapitoModo.recapito_modo_code=RECAPITO_MODO_WWW and
               recapitoModo.ente_proprietario_id=enteProprietarioId and
               recapitoModo.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
               (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
                  or recapitoModo.validita_fine is null);

	exception
      when no_data_found then
          RAISE EXCEPTION 'Code % non presente in archivio',code;
          when others  THEN
              RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
	end;

    strMessaggio:='Letttura sede secondarie per il soggetto in migr_sede_secondaria.';
    for migrSedeSecondaria in
    ( select migrSedeSec.*
     from migr_sede_secondaria migrSedeSec
     where migrSedeSec.soggetto_id=soggettoId  and
           migrSedeSec.ente_proprietario_id=enteProprietarioId and
           migrSedeSec.fl_elab='N'
     order by migrSedeSec.sede_id
    )
    loop

        progSedeSogg:=progSedeSogg+1;
		strProgSede:=progSedeSogg::varchar;

		strMessaggio:='Inserimento siac_t_soggetto  soggetto_id= '||soggettoId
                      ||'(in migr_soggetto_id) per sede_id '||migrSedeSecondaria.sede_id||'.';
	    -- siac_t_soggetto
    	insert into siac_t_soggetto
        (soggetto_code,soggetto_desc, validita_inizio,ambito_id,ente_proprietario_id,
         data_creazione,login_operazione,login_creazione)
         values
        (siacSoggettoCode
         --siacSoggettoCode||'S'||strProgSede
         ,migrSedeSecondaria.ragione_sociale,
         dataInizioVal,ambitoId,enteProprietarioId,clock_timestamp(),loginOperazione,loginOperazione
        )
        returning soggetto_id into soggettoSedeId;

        strMessaggio:='Inserimento siac_r_soggetto_attr soggetto_id= '||soggettoId
                      ||'(in migr_soggetto_id) per sede_id '||migrSedeSecondaria.sede_id||'campo note.';
        -- siac_r_soggetto_attr ( note )
        -- note
        insert into siac_r_soggetto_attr
        (soggetto_id,attr_id,validita_inizio, ente_proprietario_id,
	     data_creazione,login_operazione,testo
        )
        values
        (soggettoSedeId, idAttr_noteSoggetto,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione,substring(migrSedeSecondaria.note from 1 for NOTE_SOGG_LENGTH));
        /*(select soggettoSedeId, attrSoggetto.attr_id ,CURRENT_TIMESTAMP,enteProprietarioId,
                CURRENT_TIMESTAMP,loginOperazione,substring(migrSedeSecondaria.note from 1 for NOTE_SOGG_LENGTH)
          from siac_t_attr attrSoggetto
          where attrSoggetto.ente_proprietario_id=enteProprietarioId and
	            attrSoggetto.attr_code=NOTE_SOGG_ATTR and
	            attrSoggetto.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',attrSoggetto.validita_inizio) and
			   (date_trunc('day',dataElaborazione)<date_trunc('day',attrSoggetto.validita_fine)
			              or attrSoggetto.validita_fine is null)
         );*/

        strMessaggio:='Inserimento siac_r_soggetto_stato soggetto_id= '||soggettoId
                      ||'(in migr_soggetto_id) per sede_id '||migrSedeSecondaria.sede_id||'.';

	    -- siac_r_soggetto_stato
	 	INSERT INTO siac_r_soggetto_stato
		(soggetto_id,soggetto_stato_id,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
         values
         (soggettoSedeId, idStatoSoggettoValido, dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);
/*	    (select soggettoSedeId,statoSoggetto.soggetto_stato_id, CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
         from siac_d_soggetto_stato statoSoggetto
         where statoSoggetto.soggetto_stato_code=STATO_SOGGETTO_SEDE_VALIDO and
		       statoSoggetto.ente_proprietario_id=enteProprietarioId and
               statoSoggetto.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',statoSoggetto.validita_inizio) and
		       (date_trunc('day',dataElaborazione)<date_trunc('day',statoSoggetto.validita_fine)
		            or statoSoggetto.validita_fine is null)
         );*/

		if coalesce(migrSedeSecondaria.comune,NVL_STR)!=NVL_STR then
		   	strMessaggio:='Inserimento siac_t_indirizzo_soggetto tipo '||migrSedeSecondaria.tipo_indirizzo||' soggetto_id= '||soggettoId||
        	              '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id||' lettura comune.';
			select * into migrComune
    	    from fnc_migr_comune(migrSedeSecondaria.comune,migrSedeSecondaria.prov,
        	  				     migrSedeSecondaria.nazione,enteProprietarioid,loginOperazione,dataElaborazione
                                 , annobilancio);
	        if migrComune.codiceRisultato=0 then
            	comuneId:=migrComune.comuneId;
            else
	            RAISE EXCEPTION ' % ', migrComune.messaggioRisultato;
            end if;
        end if;

        -- inserisco indirizzo solo via,  comune sono valorizzati
        if coalesce(migrSedeSecondaria.via,NVL_STR)!=NVL_STR and coalesce(migrSedeSecondaria.comune,NVL_STR)!=NVL_STR then
     	 -- siac_t_indirizzo_soggetto
         strMessaggio:='Inserimento siac_t_indirizzo_soggetto tipo '||migrSedeSecondaria.tipo_indirizzo||' soggetto_id= '||soggettoId||
                      '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id||'.';

         if coalesce(migrSedeSecondaria.tipo_via,NVL_STR)!=NVL_STR then
         	INSERT INTO siac_t_indirizzo_soggetto
  	 		(soggetto_id,via_tipo_id,toponimo, numero_civico,frazione,interno, zip_code, comune_id,
             principale,validita_inizio, ente_proprietario_id, data_creazione, login_operazione, avviso
 	 		)
    	 	(select soggettoSedeId,tipoVia.via_tipo_id,migrSedeSecondaria.via,migrSedeSecondaria.numero_civico,migrSedeSecondaria.frazione,migrSedeSecondaria.interno,
			    	migrSedeSecondaria.cap,comuneId,migrSedeSecondaria.indirizzo_principale,
           	  		dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione,migrSedeSecondaria.avviso
          	from siac_d_via_tipo tipoVia
          	where tipoVia.via_tipo_code=migrSedeSecondaria.tipo_via and
   	         	  tipoVia.ente_proprietario_id=enteProprietarioId AND
       	     	  tipoVia.data_cancellazione is null and
           	 	  date_trunc('day',dataElaborazione)>=date_trunc('day',tipoVia.validita_inizio) and
   		  	   	  (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoVia.validita_fine)
	           	   or tipoVia.validita_fine is null)
  		   )
      	   returning indirizzo_id into indirizzoId;
         ELSE
           INSERT INTO siac_t_indirizzo_soggetto
  	 		(soggetto_id,via_tipo_id,toponimo, numero_civico,frazione,interno, zip_code, comune_id,
             principale,validita_inizio, ente_proprietario_id, data_creazione, login_operazione, avviso
 	 		)
            values
    	 	(soggettoSedeId,null,migrSedeSecondaria.via,migrSedeSecondaria.numero_civico,migrSedeSecondaria.frazione,migrSedeSecondaria.interno,
			 migrSedeSecondaria.cap,comuneId,migrSedeSecondaria.indirizzo_principale,
           	 dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione,migrSedeSecondaria.avviso
   		     )
      	     returning indirizzo_id into indirizzoId;
         end if;

 	 strMessaggio:='Inserimento siac_r_indirizzo_soggetto_tipo tipo '||migrSedeSecondaria.tipo_indirizzo||' soggetto_id= '||soggettoId||
                      '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id||'.';
	 -- siac_r_indirizzo_soggetto_tipo
         INSERT INTO siac_r_indirizzo_soggetto_tipo
		(indirizzo_id,indirizzo_tipo_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
		( select indirizzoId,tipoIndirizzo.indirizzo_tipo_id,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
          from siac_d_indirizzo_tipo tipoIndirizzo
          where tipoIndirizzo.indirizzo_tipo_code=migrSedeSecondaria.tipo_indirizzo and
                tipoIndirizzo.ente_proprietario_id=enteProprietarioId and
                tipoIndirizzo.data_cancellazione is null and
           	    date_trunc('day',dataElaborazione)>=date_trunc('day',tipoIndirizzo.validita_inizio) and
				(date_trunc('day',dataElaborazione)<=date_trunc('day',tipoIndirizzo.validita_fine)
			            or tipoIndirizzo.validita_fine is null)
          );

        end if;

	strMessaggio:='Inserimento siac_t_recapito_soggetto soggetto_id= '||soggettoId||
				       '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id||' telefono 1.';
        -- siac_t_recapito_soggetto
        -- tel1
        if coalesce(migrSedeSecondaria.tel1,NVL_STR)!=NVL_STR then
		        strToElab:=migrSedeSecondaria.tel1;
				riferimentoRecapito:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                strToElab:=substring(migrSedeSecondaria.tel1 from
					                 position(SEPARATORE in migrSedeSecondaria.tel1)+2
				                     for char_length(migrSedeSecondaria.tel1)-position(SEPARATORE in migrSedeSecondaria.tel1));
                recapitoSede:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                avvisoRecapitoSede:=substring(strToElab from
					          				      position(SEPARATORE in strToElab)+2
			 				                      for char_length(strToElab)-position(SEPARATORE in strToElab));

                if riferimentoRecapito=RECAPITO_RIF_SOGG then
                	soggettoRecapitoId:=siacSoggettoId;
                else
                	soggettoRecapitoId:=soggettoSedeId;
                end if;
	-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
			    nrecapiti := 0;
			    select count(*)
				into nrecapiti
				from siac_t_recapito_soggetto reca
				where reca.ente_proprietario_id=enteProprietarioId and
				      reca.soggetto_id=soggettoRecapitoId and
					  reca.recapito_code=recapitoModoCode_tel and
					  reca.recapito_desc=recapitoSede;
					  
				if nrecapiti = 0 then	  

	       		    insert into siac_t_recapito_soggetto
    	            (soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
		    	     data_creazione, login_operazione, recapito_modo_id, avviso
				    )
                    VALUES(soggettoRecapitoId, recapitoModoCode_tel,recapitoSede,dataInizioVal,enteProprietarioId,clock_timestamp()
                    ,loginOperazione,recapitoModoId_tel,avvisoRecapitoSede);
				/*
			    (
    	         select soggettoRecapitoId,recapitoModo.recapito_modo_code,recapitoSede,CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,
        	            loginOperazione,recapitoModo.recapito_modo_id,avvisoRecapitoSede
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

		strMessaggio:='Inserimento siac_t_recapito_soggetto soggetto_id= '||soggettoId||
				       '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id||' telefono 2.';
        -- siac_t_recapito_soggetto
        -- tel2
        if coalesce(migrSedeSecondaria.tel2,NVL_STR)!=NVL_STR  then
		        strToElab:=migrSedeSecondaria.tel2;
				riferimentoRecapito:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                strToElab:=substring(migrSedeSecondaria.tel2 from
					                 position(SEPARATORE in migrSedeSecondaria.tel2)+2
				                     for char_length(migrSedeSecondaria.tel2)-position(SEPARATORE in migrSedeSecondaria.tel2));
                recapitoSede:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                avvisoRecapitoSede:=substring(strToElab from
					          				      position(SEPARATORE in strToElab)+2
			 				                      for char_length(strToElab)-position(SEPARATORE in strToElab));

                if riferimentoRecapito=RECAPITO_RIF_SOGG then
                	soggettoRecapitoId:=siacSoggettoId;
                else
                	soggettoRecapitoId:=soggettoSedeId;
                end if;
				
	-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
			    nrecapiti := 0;
			    select count(*)
				into nrecapiti
				from siac_t_recapito_soggetto reca
				where reca.ente_proprietario_id=enteProprietarioId and
				      reca.soggetto_id=soggettoRecapitoId and
					  reca.recapito_code=recapitoModoCode_tel and
					  reca.recapito_desc=recapitoSede;
					  
				if nrecapiti = 0 then	  

	       		    insert into siac_t_recapito_soggetto
    	            (soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
		    	     data_creazione, login_operazione, recapito_modo_id, avviso
				    )
                    values
                    (soggettoRecapitoId, recapitoModoCode_tel,recapitoSede,dataInizioVal,enteProprietarioId,clock_timestamp()
                     , loginOperazione, recapitoModoId_tel,avvisoRecapitoSede);
			    /*(
    	         select soggettoRecapitoId,recapitoModo.recapito_modo_code,recapitoSede,CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,
        	            loginOperazione,recapitoModo.recapito_modo_id,avvisoRecapitoSede
            	 from siac_d_recapito_modo recapitoModo
	             where recapitoModo.recapito_modo_code=RECAPITO_MODO_TEL and
    	               recapitoModo.ente_proprietario_id=enteProprietarioId and
        	           recapitoModo.data_cancellazione is null and
            	  	   date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',recapitoModo.validita_inizio) and
			  		   (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',recapitoModo.validita_fine)
		            	  or recapitoModo.validita_fine is null)
				);*/
                end if;
	-- DAVIDE - 21.09.015 : fine
         end if;

		strMessaggio:='Inserimento siac_t_recapito_soggetto soggetto_id= '||soggettoId||
				       '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id||' fax.';
        -- siac_t_recapito_soggetto
        -- fax
        if coalesce(migrSedeSecondaria.fax,NVL_STR)!=NVL_STR then
		        strToElab:=migrSedeSecondaria.fax;
				riferimentoRecapito:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                strToElab:=substring(migrSedeSecondaria.fax from
					                 position(SEPARATORE in migrSedeSecondaria.fax)+2
				                     for char_length(migrSedeSecondaria.fax)-position(SEPARATORE in migrSedeSecondaria.fax));
                recapitoSede:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                avvisoRecapitoSede:=substring(strToElab from
					          				      position(SEPARATORE in strToElab)+2
			 				                      for char_length(strToElab)-position(SEPARATORE in strToElab));

                if riferimentoRecapito=RECAPITO_RIF_SOGG then
                	soggettoRecapitoId:=siacSoggettoId;
                else
                	soggettoRecapitoId:=soggettoSedeId;
                end if;
				
	-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
			    nrecapiti := 0;
			    select count(*)
				into nrecapiti
				from siac_t_recapito_soggetto reca
				where reca.ente_proprietario_id=enteProprietarioId and
				      reca.soggetto_id=soggettoRecapitoId and
					  reca.recapito_code=recapitoModoCode_fax and
					  reca.recapito_desc=recapitoSede;
					  
				if nrecapiti = 0 then	  

	       		    insert into siac_t_recapito_soggetto
    	            (soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
		    	     data_creazione, login_operazione, recapito_modo_id, avviso
				    )
                    values
                    (soggettoRecapitoId, recapitoModoCode_fax,recapitoSede, dataInizioVal, enteProprietarioId, clock_timestamp()
                    ,loginOperazione, recapitoModoId_fax,avvisoRecapitoSede);
                /*
			    (
    	         select soggettoRecapitoId,recapitoModo.recapito_modo_code,recapitoSede,CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,
        	            loginOperazione,recapitoModo.recapito_modo_id,avvisoRecapitoSede
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

		 strMessaggio:='Inserimento siac_t_recapito_soggetto soggetto_id= '||soggettoId||
				       '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id||' sito_www.';
        -- siac_t_recapito_soggetto
        -- sito_www
        if coalesce(migrSedeSecondaria.sito_www,NVL_STR)!=NVL_STR then
		        strToElab:=migrSedeSecondaria.sito_www;
				riferimentoRecapito:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                strToElab:=substring(migrSedeSecondaria.sito_www from
					                 position(SEPARATORE in migrSedeSecondaria.sito_www)+2
				                     for char_length(migrSedeSecondaria.sito_www)-position(SEPARATORE in migrSedeSecondaria.sito_www));
                recapitoSede:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                avvisoRecapitoSede:=substring(strToElab from
					          				      position(SEPARATORE in strToElab)+2
			 				                      for char_length(strToElab)-position(SEPARATORE in strToElab));

                if riferimentoRecapito=RECAPITO_RIF_SOGG then
                	soggettoRecapitoId:=siacSoggettoId;
                else
                	soggettoRecapitoId:=soggettoSedeId;
                end if;
				
	-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
			    nrecapiti := 0;
			    select count(*)
				into nrecapiti
				from siac_t_recapito_soggetto reca
				where reca.ente_proprietario_id=enteProprietarioId and
				      reca.soggetto_id=soggettoRecapitoId and
					  reca.recapito_code=recapitoModoCode_www and
					  reca.recapito_desc=recapitoSede;
					  
				if nrecapiti = 0 then	  

	       		    insert into siac_t_recapito_soggetto
    	            (soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
		    	     data_creazione, login_operazione, recapito_modo_id, avviso
				    )
                    values
                    (soggettoRecapitoId, recapitoModoCode_www,recapitoSede,dataInizioVal,enteProprietarioId,clock_timestamp()
                    ,loginOperazione,recapitoModoId_www,avvisoRecapitoSede );
/*
			    (
    	         select soggettoRecapitoId,recapitoModo.recapito_modo_code,recapitoSede,CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,
        	            loginOperazione,recapitoModo.recapito_modo_id,avvisoRecapitoSede
            	 from siac_d_recapito_modo recapitoModo
	             where recapitoModo.recapito_modo_code=RECAPITO_MODO_WWW and
    	               recapitoModo.ente_proprietario_id=enteProprietarioId and
        	           recapitoModo.data_cancellazione is null and
            	  	   date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
			  		   (date_trunc('day',dataElaborazione)<date_trunc('day',recapitoModo.validita_fine)
		            	  or recapitoModo.validita_fine is null)
				);
*/
                end if;
	-- DAVIDE - 21.09.015 : fine
         end if;


		 strMessaggio:='Inserimento siac_t_recapito_soggetto soggetto_id= '||soggettoId||
				       '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id||' email.';
        -- siac_t_recapito_soggetto
        -- email
        if coalesce(migrSedeSecondaria.email,NVL_STR)!=NVL_STR then
		        strToElab:=migrSedeSecondaria.email;
                riferimentoRecapito:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                strToElab:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
                tipoRecapitoSede:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                strToElab:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
                recapitoSede:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                avvisoRecapitoSede:=substring(strToElab from
					          				      position(SEPARATORE in strToElab)+2
			 				                      for char_length(strToElab)-position(SEPARATORE in strToElab));

                if riferimentoRecapito=RECAPITO_RIF_SOGG then
                	soggettoRecapitoId:=siacSoggettoId;
                else
                	soggettoRecapitoId:=soggettoSedeId;
                end if;
				
	-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
			    nrecapiti := 0;
			    select count(*)
				into nrecapiti
				from siac_t_recapito_soggetto reca
				where reca.ente_proprietario_id=enteProprietarioId and
				      reca.soggetto_id=soggettoRecapitoId and
					  reca.recapito_code=tipoRecapitoSede and
					  reca.recapito_desc=recapitoSede;
					  
				if nrecapiti = 0 then	  

	       		    insert into siac_t_recapito_soggetto
    	            (soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
		    	     data_creazione, login_operazione, recapito_modo_id, avviso
				    )
			        (
    	             select soggettoRecapitoId,recapitoModo.recapito_modo_code,recapitoSede,dataInizioVal,enteProprietarioId,clock_timestamp(),
        	                loginOperazione,recapitoModo.recapito_modo_id,avvisoRecapitoSede
            	       from siac_d_recapito_modo recapitoModo
	                  where recapitoModo.recapito_modo_code=tipoRecapitoSede and
    	                    recapitoModo.ente_proprietario_id=enteProprietarioId and
        	                recapitoModo.data_cancellazione is null and
            	  	        date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
			  		        (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
		            	     or recapitoModo.validita_fine is null)
				    );
                end if;
	-- DAVIDE - 21.09.015 : fine
         end if;

         strMessaggio:='Inserimento siac_t_recapito_soggetto soggetto_id= '||soggettoId||
				       '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id||' contatto_generico.';
         -- siac_t_recapito_soggetto
         -- contatto_generico
         if coalesce(migrSedeSecondaria.contatto_generico,NVL_STR)!=NVL_STR then
		        strToElab:=migrSedeSecondaria.contatto_generico;
				riferimentoRecapito:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                strToElab:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
                tipoRecapitoSede:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                strToElab:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
                recapitoSede:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                avvisoRecapitoSede:=substring(strToElab from
					          				      position(SEPARATORE in strToElab)+2
			 				                      for char_length(strToElab)-position(SEPARATORE in strToElab));

                if riferimentoRecapito=RECAPITO_RIF_SOGG then
                	soggettoRecapitoId:=siacSoggettoId;
                else
                	soggettoRecapitoId:=soggettoSedeId;
                end if;
				
	-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
			    nrecapiti := 0;
			    select count(*)
				into nrecapiti
				from siac_t_recapito_soggetto reca
				where reca.ente_proprietario_id=enteProprietarioId and
				      reca.soggetto_id=soggettoRecapitoId and
					  reca.recapito_code=tipoRecapitoSede and
					  reca.recapito_desc=recapitoSede;
					  
				if nrecapiti = 0 then	  

	       		    insert into siac_t_recapito_soggetto
    	            (soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
		    	     data_creazione, login_operazione, recapito_modo_id, avviso
				    )
			        (
    	             select soggettoRecapitoId,recapitoModo.recapito_modo_code,recapitoSede,dataInizioVal,enteProprietarioId,clock_timestamp(),
        	                loginOperazione,recapitoModo.recapito_modo_id,avvisoRecapitoSede
            	       from siac_d_recapito_modo recapitoModo
	                  where recapitoModo.recapito_modo_code=tipoRecapitoSede and
    	                    recapitoModo.ente_proprietario_id=enteProprietarioId and
        	                recapitoModo.data_cancellazione is null and
            	  	        date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
			  		        (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
		            	     or recapitoModo.validita_fine is null)
				    );
                end if;
	-- DAVIDE - 21.09.015 : fine
         end if;

		-- creare la relazione tra soggetto e sed
        strMessaggio='Inserimento  siac_r_soggetto_relaz soggetto_id= '||soggettoId||
				       '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id;
		insert into siac_r_soggetto_relaz
        (relaz_tipo_id,soggetto_id_da,soggetto_id_a,
		 validita_inizio, ente_proprietario_id, data_creazione,login_operazione)
        (select relazTipo.relaz_tipo_id,siacSoggettoId,soggettoSedeId,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
         from siac_d_relaz_tipo relazTipo
         where relazTipo.relaz_tipo_code=migrSedeSecondaria.tipo_relazione and
               relazTipo.ente_proprietario_id=enteProprietarioId and
               relazTipo.data_cancellazione is null and
            	  	   date_trunc('day',dataElaborazione)>=date_trunc('day',relazTipo.validita_inizio) and
			  		   (date_trunc('day',dataElaborazione)<=date_trunc('day',relazTipo.validita_fine)
		            	  or relazTipo.validita_fine is null))
         returning soggetto_relaz_id into soggettoRelazId;

		strMessaggio='Inserimento  siac_r_migr_sede_secondaria soggetto_id= '||soggettoId||
				       '(in migr_soggetto_id) sede_id='||migrSedeSecondaria.sede_id;

        insert into siac_r_migr_sede_secondaria_rel_sede
        (migr_sede_id, soggetto_relaz_id,data_creazione,ente_proprietario_id)
        values
        (migrSedeSecondaria.migr_sede_id,soggettoRelazId,clock_timestamp(),enteProprietarioId);

    end loop;

    codiceRisultato:= codRet;
    messaggioRisultato:=strMessaggioFinale||'Elaborazione OK.';

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 800);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :  '||' '||substring(upper(SQLERRM) from 1 for 800) ;
        codiceRisultato:=-1;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 800);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 800) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;