/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*DROP FUNCTION fnc_migr_soggetti_new (tipoElab varchar(3),
											  enteProprietarioId integer,
  											  loginOperazione varchar,
											  dataElaborazione timestamp,
                                              annoBilancio varchar,
                                              idmin INTEGER,
                                              idmax INTEGER,
											  out numeroSoggettiInseriti integer,
											  out messaggioRisultato varchar
											 )*/

CREATE OR REPLACE FUNCTION fnc_migr_soggetti (tipoElab varchar(3),
											  enteProprietarioId integer,
  											  loginOperazione varchar,
											  dataElaborazione timestamp,
                                              annoBilancio varchar,
                                              idmin INTEGER,
                                              idmax INTEGER,
											  out numeroSoggettiInseriti integer,
											  out messaggioRisultato varchar
											 )
RETURNS record AS
$body$
DECLARE
    -- fnc_migr_soggetti --> function che richiama
     -- fnc_migr_classe  per il caricamneto di classi soggetti da migr_classe
     -- fnc_migr_soggetto per il caricamento dei dati dei soggetti migrati
     -- fnc_migr_relaz_soggetto per il caricamento delle relazioni tra i soggetti
    -- restituisce
    -- messaggioRisultato valorizzato con il testo di risultato dell''elaborazione
    -- numeroSoggettiInseriti  valorrizato con 0 (errore o dati non presenti in migr_soggetto ) N- numero di soggetti inseriti
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	migrSoggetto record;

    migrRelazSoggetto record;
    migrClasse record;

    TIPO_ELAB_CLASSI CONSTANT varchar:='CL';
    TIPO_ELAB_RELAZ_SOGG CONSTANT varchar:='RSS';

begin

	numeroSoggettiInseriti:=0;
    messaggioRisultato:='';

    strMessaggioFinale:='MIGRAZIONE SOGGETTI.';

	-- funzione che ad oggi non viene richiamata, quindi nessuna modifica di ottimizzazione del codice
	if tipoElab=TIPO_ELAB_CLASSI then
     strMessaggio:='CLASSI.';
     select *  into migrClasse
     from  fnc_migr_classe (enteProprietarioId, loginOperazione,dataElaborazione);
	 if migrClasse.codiceRisultato=-1 then
    	    RAISE EXCEPTION '%', migrClasse.msgRisultato;
	 else
	     messaggioRisultato:='ENTE '||enteProprietarioId||' '||migrClasse.msgRisultato;
     end if;
    end if;

	if substring(tipoElab from 1 for 1 )='S' then
	    strMessaggio:='SOGGETTO.';
		select * into  migrSoggetto
	    from     fnc_migr_soggetto (tipoElab,enteProprietarioId, loginOperazione,dataElaborazione, annoBilancio, idmin, idmax);

        if migrSoggetto.numeroSoggettiInseriti=-1 then
        	RAISE EXCEPTION '%', migrSoggetto.messaggioRisultato;
        else
    	    messaggioRisultato:='ENTE '||enteProprietarioId||' '||migrSoggetto.messaggioRisultato;
		    numeroSoggettiInseriti:= migrSoggetto.numeroSoggettiInseriti;
        end if;
    end if;

    if tipoElab=TIPO_ELAB_RELAZ_SOGG then
        strMessaggio:='RELAZ SOGGETTI.';
    	select *  into migrRelazSoggetto
        from fnc_migr_relaz_soggetto(enteProprietarioId ,loginOperazione, dataElaborazione,annoBilancio);

        if migrRelazSoggetto.codiceRisultato=-1 then
        	RAISE EXCEPTION '%', migrRelazSoggetto.messaggioRisultato;
        else
        	messaggioRisultato:='ENTE '||enteProprietarioId||' '||migrRelazSoggetto.messaggioRisultato;
        end if;
    end if;


   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '%',substring(upper(SQLERRM) from 1 for 2000);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||substring(upper(SQLERRM) from 1 for 2000) ;
        numeroSoggettiInseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 2000);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 2000) ;
        numeroSoggettiInseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;