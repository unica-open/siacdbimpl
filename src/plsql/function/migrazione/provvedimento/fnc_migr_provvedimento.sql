/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*DROP FUNCTION siac.fnc_migr_provvedimento (
  enteproprietarioid integer,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  idmin integer,
  idmax integer,
  out numerorecordinseriti integer,
  out messaggiorisultato varchar
)*/

CREATE OR REPLACE FUNCTION siac.fnc_migr_provvedimento (
  enteproprietarioid integer,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  idmin integer,
  idmax integer,
  out numerorecordinseriti integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
    -- fnc_migr_provvedimento --> function che richiama
     -- fnc_migr_attoamm  per il caricamneto dell'atto amministrativo
    -- restituisce
    -- messaggioRisultato valorizzato con il testo di risultato dell''elaborazione
    -- numerorecordinseriti  valorrizato con 0 (errore o dati non presenti in migr_provvedimento ) N- numero di provvedimenti inseriti

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
	--dataInizioVal timestamp :=annoBilancio||'-01-01';
	dataInizioVal timestamp :=null;

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	migrRecord record;
	migrAttoAmm record;

    countMigr Integer := 0;
begin

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione provvedimenti da id ['||idmin||'] a id ['||idmax||']';
    strMessaggio:='Lettura provvedimenti da migrare.';

	begin
		select distinct 1 into strict countMigr from migr_provvedimento mp
		where mp.ente_proprietario_id=enteProprietarioId and
		    mp.fl_elab='N'
		    and mp.migr_provvedimento_id >= idMin and mp.migr_provvedimento_id <=idMax;
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numerorecordinseriti:=-12;
		 return;
	end;

    countMigr := 0;
    for migrRecord IN
    (select ms.*
     from migr_provvedimento ms
	 where ms.ente_proprietario_id=enteProprietarioId and
           ms.fl_elab='N'
           and ms.migr_provvedimento_id >= idMin and ms.migr_provvedimento_id <=idMax
     order by ms.migr_provvedimento_id
     )
    loop
    	strMessaggio:='Richiamo funzione fnc_migr_attoamm.';
        select * into migrAttoAmm
        	from fnc_migr_attoamm (migrRecord.anno_provvedimento,migrRecord.numero_provvedimento,
                                                 migrRecord.tipo_provvedimento,migrRecord.sac_provvedimento,
                                                 migrRecord.oggetto_provvedimento,migrRecord.note_provvedimento,
                                                 migrRecord.stato_provvedimento,
                                                 enteProprietarioId,loginOperazione,dataElaborazione, dataInizioVal);
            if migrAttoAmm.codiceRisultato=-1 then
                RAISE EXCEPTION ' % ', migrAttoAmm.messaggioRisultato;
            end if;

        strMessaggio:='Inserimento siac_r_migr_provvedimento_attoamm per migr_provvedimento_id= '
                                     ||migrRecord.migr_provvedimento_id||'.';
        insert into siac_r_migr_provvedimento_attoamm
        (migr_provvedimento_id,attoamm_id,ente_proprietario_id,data_creazione)
        values
        (migrRecord.migr_provvedimento_id,migrAttoAmm.id,enteProprietarioId,clock_timestamp());
		countMigr := countMigr+1;
	end loop;

    strMessaggio:='Set fl_elab=S per record migrati';
	update migr_provvedimento p set fl_elab = 'S'
    where ente_proprietario_id = enteProprietarioId
    and migr_provvedimento_id >= idMin and migr_provvedimento_id <=idMax
    and exists (select 1 from siac_r_migr_provvedimento_attoamm r where r.migr_provvedimento_id = p.migr_provvedimento_id);

    messaggiorisultato := strMessaggioFinale || 'Provvedimenti migrati '||countMigr||'.';
	numerorecordinseriti := countMigr;
   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '%',substring(upper(SQLERRM) from 1 for 2000);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||substring(upper(SQLERRM) from 1 for 2000) ;
        numerorecordinseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 2000);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 2000) ;
        numerorecordinseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;