/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_indirizzo_secondario ( soggettoId integer,
													       siacSoggettoId integer,
													       enteProprietarioId integer,
		  											       loginOperazione    varchar,
 													       dataElaborazione timestamp,
                                                           annoBilancio varchar,
													       out codiceRisultato integer,
													       out messaggioRisultato varchar
												          )
RETURNS record AS
$body$
DECLARE

 SEPARATORE			CONSTANT  varchar :='||';

 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 countMigrIndirizzoSec integer:=0;
 migrIndirizzoSec record;
 migrComune record;


 indirizzoId integer :=null;
 comuneId integer:=null;

 NVL_STR CONSTANT varchar:='';

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

begin
 -- fnc_migr_indirizzo_secondario -- function che effettua il caricamento degli indirizzi secondari del soggetto ( leggendo da migr_indirizzo_secondario )
  --                                 per il  siacSoggettoId passato in input
  --                                 il soggetto deve essere presente in siac_t_soggetto con soggetto_id=siacSoggettoId
  --                                 soggettoId=migr_indirizzo_secondario.soggetto_id = migr_soggetto.soggetto_id per ente
 -- effettua inserimento di
  -- siac_t_indirizzo_soggetto -- per i dati relativi all'' indirizzo (siac_r_indirizzo_soggetto_tipo)
  -- siac_r_migr_indirizzo_secondario_indirizzo -- per tracciare il legame tra
  --  migr_indirizzo_secondario.migr_indirizzo_id -- siac_t_indirizzo_soggetto.indirizzo_id
 -- la fnc restituisce
  -- messaggioRisultato = risulato elaborazine in formato testo
  -- codiceRisultato    = codice risultato elaborazione 0 ( elaborazione OK ) -1 (errore) -12 ( dati non presenti in migr_indirizzo_secondario)
	messaggioRisultato:='';
    codiceRisultato:=0;

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Gestione inserimento indirizzi secondari soggetto per soggetto_id '||soggettoId||' in migr_soggetto.';

	strMessaggio:='Verifica esistenza indirizzi sec. per il soggetto indicato.';

	select COALESCE(count(*),0) into countMigrIndirizzoSec
    from migr_indirizzo_secondario ms
    where ms.soggetto_id=soggettoId and
          ms.ente_proprietario_id=enteProprietarioId and
          ms.fl_elab='N';

	if COALESCE(countMigrIndirizzoSec,0)=0 then
    	 messaggioRisultato:=strMessaggioFinale||'Nessuna indirizzo presente per il soggetto indicato.';
         codiceRisultato:=-12;
         return;
    end if;


   -- migr_indirizzo_id
   -- indirizzo_id
   -- soggetto_id
   -- codice_indirizzo
   -- indirizzo_principale
   -- tipo_indirizzo
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


    strMessaggio:='Letttura indirizzi secondari per il soggetto in migr_indirizzo_secondario.';
    for migrIndirizzoSec in
    ( select migrIndirSec.*
      from migr_indirizzo_secondario migrIndirSec
      where migrIndirSec.soggetto_id=soggettoId  and
            migrIndirSec.ente_proprietario_id=enteProprietarioId and
            migrIndirSec.fl_elab='N'
     order by migrIndirSec.indirizzo_id
    )
    loop

		comuneId:=null;

		if coalesce(migrIndirizzoSec.comune,NVL_STR)!=NVL_STR then
     	 strMessaggio:='Inserimento siac_t_indirizzo_soggetto tipo '||migrIndirizzoSec.tipo_indirizzo||' soggetto_id= '||soggettoId||
                      '(in migr_soggetto_id) lettura comune.';
		 select * into migrComune
         from fnc_migr_comune(migrIndirizzoSec.comune,migrIndirizzoSec.prov,
          				      migrIndirizzoSec.nazione,enteProprietarioid,loginOperazione,dataElaborazione
                              ,annoBilancio);
          if migrComune.codiceRisultato=0 then
           comuneId=migrComune.comuneId;
          ELSE
	          RAISE EXCEPTION ' % ', migrComune.messaggioRisultato;
          end if;
        end if;

      	-- siac_t_indirizzo_soggetto
        strMessaggio:='Inserimento siac_t_indirizzo_soggetto tipo '||migrIndirizzoSec.tipo_indirizzo||' soggetto_id= '||soggettoId||
		                       '(in migr_soggetto_id).';
		if coalesce(migrIndirizzoSec.tipo_via,NVL_STR)!=NVL_STR then
        	INSERT INTO siac_t_indirizzo_soggetto
			(soggetto_id,via_tipo_id,toponimo, numero_civico,frazione,interno, zip_code, comune_id,
		 	 principale,validita_inizio, ente_proprietario_id, data_creazione, login_operazione, avviso
			)
        	(select siacSoggettoId,tipoVia.via_tipo_id,migrIndirizzoSec.via,migrIndirizzoSec.numero_civico,migrIndirizzoSec.frazione,migrIndirizzoSec.interno,
			    	migrIndirizzoSec.cap,comuneId,migrIndirizzoSec.indirizzo_principale,
           	   		dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione,migrIndirizzoSec.avviso
	      	from siac_d_via_tipo tipoVia
   	     	where tipoVia.via_tipo_code=migrIndirizzoSec.tipo_via and
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
        	(siacSoggettoId,null,migrIndirizzoSec.via,migrIndirizzoSec.numero_civico,migrIndirizzoSec.frazione,migrIndirizzoSec.interno,
			 migrIndirizzoSec.cap,comuneId,migrIndirizzoSec.indirizzo_principale,
           	 dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione,migrIndirizzoSec.avviso
	      	)
      	    returning indirizzo_id into indirizzoId;
        end if;

        strMessaggio:='Inserimento siac_r_indirizzo_soggetto_tipo tipo '||migrIndirizzoSec.tipo_indirizzo||' soggetto_id= '||soggettoId||
                          '(in migr_soggetto_id).';
	    -- siac_r_indirizzo_soggetto_tipo
        INSERT INTO siac_r_indirizzo_soggetto_tipo
		(indirizzo_id,indirizzo_tipo_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
		( select indirizzoId,tipoIndirizzo.indirizzo_tipo_id,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
          from siac_d_indirizzo_tipo tipoIndirizzo
          where tipoIndirizzo.indirizzo_tipo_code=migrIndirizzoSec.tipo_indirizzo and
                tipoIndirizzo.ente_proprietario_id=enteProprietarioId and
                tipoIndirizzo.data_cancellazione is null and
           	    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',tipoIndirizzo.validita_inizio) and
				(date_trunc('seconds',dataElaborazione)<=date_trunc('seconds',tipoIndirizzo.validita_fine)
			            or tipoIndirizzo.validita_fine is null)
            );


		strMessaggio='Inserimento  siac_r_migr_indirizzo_secondario_indirizzo tipo '||migrIndirizzoSec.tipo_indirizzo||
        		     ' soggetto_id= '||soggettoId||'(in migr_soggetto_id).';

        insert into siac_r_migr_indirizzo_secondario_indirizzo
        (migr_indirizzo_id, indirizzo_id,data_creazione,ente_proprietario_id)
        values
        (migrIndirizzoSec.migr_indirizzo_id,indirizzoId,clock_timestamp(),enteProprietarioId);

    end loop;

    codiceRisultato:= codRet;
    messaggioRisultato:=strMessaggioFinale||'Elaborazione OK.';

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :  '||' '||substring(upper(SQLERRM) from 1 for 100) ;
        codiceRisultato:=-1;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 100) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;