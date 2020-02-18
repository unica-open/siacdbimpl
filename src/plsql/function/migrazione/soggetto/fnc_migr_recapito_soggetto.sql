/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_recapito_soggetto ( soggettoId integer,
													    siacSoggettoId integer,
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

 SEPARATORE			CONSTANT  varchar :='||';

 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 countMigrRecapitoSoggetto integer:=0;
 migrRecapitoSoggetto record;

 recapitoId integer :=0;

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

 -- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
 nrecapiti integer:=0;
 -- DAVIDE - 21.09.015 : fine

begin
  -- fnc_migr_recapito_soggetto -- function che effettua il caricamento di recapiti del soggetto ( leggendo da migr_recapito_soggetto )
  --                                 per il  siacSoggettoId passato in input
  --                                 il soggetto deve essere presente in siac_t_soggetto con soggetto_id=siacSoggettoId
  --                                 soggettoId=migr_recapito_soggetto.soggetto_id = migr_soggetto.soggetto_id per ente
 -- effettua inserimento di
  -- siac_t_recapito_soggetto -- per i dati relativi a recapiti del soggetto (tel1, tel2, fax,email,PEC,etc etc )
  --                             eventualmente derivanti da indirizzi_alternativi (co.to)
  -- siac_r_migr_recapito_soggetto_recapito -- per tracciare il legame tra
  --  migr_recapito_soggetto.migr_recapito_id -- siac_t_recapito_soggetto.recapito_id
 -- la fnc restituisce
  -- messaggioRisultato = risulato elaborazine in formato testo
  -- codiceRisultato    = codice risultato elaborazione 0 ( elaborazione OK ) -1 (errore) -12 ( dati non presenti in migr_recapito_soggetto)
	messaggioRisultato:='';
    codiceRisultato:=0;

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Gestione inserimento recapiti soggetto per soggetto_id '||soggettoId||' in migr_soggetto.';

	strMessaggio:='Verifica esistenza recapiti per il soggetto indicato.';

	select COALESCE(count(*),0) into countMigrRecapitoSoggetto
    from migr_recapito_soggetto ms
    where ms.soggetto_id=soggettoId and
          ms.ente_proprietario_id=enteProprietarioId and ms.fl_elab='N';

	if COALESCE(countMigrRecapitoSoggetto,0)=0 then
    	 messaggioRisultato:=strMessaggioFinale||'Nessun recapito presente per il soggetto indicato.';
         codiceRisultato:=-12;
         return;
    end if;


   -- migr_indirizzo_id
   -- recapito_id
   -- soggetto_id
   -- indirizzo_id
   -- tipo_recapito
   -- recapito
   -- avviso

    strMessaggio:='Letttura recapiti per il soggetto in migr_recapito_soggetto.';
    for migrRecapitoSoggetto in
    ( select migrRecSoggetto.*
     from migr_recapito_soggetto migrRecSoggetto
     where migrRecSoggetto.soggetto_id=soggettoId  and
           migrRecSoggetto.ente_proprietario_id=enteProprietarioId and
           migrRecSoggetto.fl_elab='N'
     order by migrRecSoggetto.recapito_id
    )
    loop


		-- siac_t_indirizzo_soggetto
        strMessaggio:='Inserimento siac_t_recapito_soggetto tipo '||migrRecapitoSoggetto.tipo_recapito||' soggetto_id= '||soggettoId||
		                       '(in migr_soggetto_id).';
	-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
		nrecapiti := 0;
		select count(*)
		into nrecapiti
		from siac_t_recapito_soggetto reca
		where reca.ente_proprietario_id=enteProprietarioId and
		      reca.soggetto_id=siacSoggettoId and
			  reca.recapito_code=migrRecapitoSoggetto.tipo_recapito and
			  reca.recapito_desc=migrRecapitoSoggetto.recapito;
					  
		if nrecapiti = 0 then	  

		    insert into siac_t_recapito_soggetto
            (soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
		     data_creazione, login_operazione, recapito_modo_id, avviso
	        )
	 	    (select siacSoggettoId,recapitoModo.recapito_modo_code,migrRecapitoSoggetto.recapito,dataInizioVal,enteProprietarioId,clock_timestamp(),
                    loginOperazione,recapitoModo.recapito_modo_id,migrRecapitoSoggetto.avviso
               from siac_d_recapito_modo recapitoModo
              where recapitoModo.recapito_modo_code=migrRecapitoSoggetto.tipo_recapito and
                    recapitoModo.ente_proprietario_id=enteProprietarioId and
                    recapitoModo.data_cancellazione is null and
           	        date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',recapitoModo.validita_inizio) and
		 	        (date_trunc('seconds',dataElaborazione)<=date_trunc('seconds',recapitoModo.validita_fine)
		             or recapitoModo.validita_fine is null)
		    )
            returning recapito_id into recapitoId;

            strMessaggio='Inserimento  siac_r_migr_recapito_soggetto_recapito tipo '||migrRecapitoSoggetto.tipo_recapito||
        		         ' soggetto_id= '||soggettoId||'(in migr_soggetto_id).';

            insert into siac_r_migr_recapito_soggetto_recapito
            (migr_recapito_id, recapito_id,data_creazione,ente_proprietario_id)
            values
            (migrRecapitoSoggetto.migr_recapito_id,recapitoId,clock_timestamp(),enteProprietarioId);
        end if;
	-- DAVIDE - 21.09.015 : fine
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