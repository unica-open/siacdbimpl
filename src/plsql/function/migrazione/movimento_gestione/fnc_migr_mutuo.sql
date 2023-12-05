/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_mutuo(
  enteproprietarioid integer,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out numerorecordinseriti integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
    strMessaggioScarto VARCHAR(1500):='';
    countRecordDaMigrare integer := 0;

    mutId integer := 0; -- id del record inserito sulla siac_t_mutuo
    mutSoggettoId integer := 0; -- id del record inserito sulla siac_r_mutuo_soggetto
    mutStatoRid integer := 0; -- id del record inserito sulla siac_r_mutuo_stato
    mutAttoAmmId integer := 0; -- id del record inserito sulla siac_r_mutuo_atto_amm

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
	--dataInizioVal timestamp :=annoBilancio||'-01-01';
	dataInizioVal timestamp :=null;

	migrRecord record;
    migrAttoAmm record; -- chiamata funzione fnc_migr_attoamm
    aggProgressivi record; -- chiamata funzione fnc_aggiorna_progressivi


BEGIN
    numerorecordinseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione mutui.';
    strMessaggio:='Lettura mutui da migrare.';

	begin
		select distinct 1 into strict countRecordDaMigrare from migr_mutuo mm
		where mm.ente_proprietario_id=enteProprietarioId and
		    mm.fl_elab='N';
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numerorecordinseriti:=-12;
		 return;
	end;

    DELETE FROM MIGR_MUTUO_SCARTO WHERE ente_proprietario_id = enteProprietarioId;
    for migrRecord IN
    (
    select mm.*
     from migr_mutuo mm
	 where mm.ente_proprietario_id=enteProprietarioId and
           mm.fl_elab='N'
     order by mm.migr_mutuo_id
     /*
    	select mm.*, t.mut_tipo_id,stato.mut_stato_id,sogg.soggetto_id
         from migr_mutuo mm
         left join siac_d_mutuo_tipo t
            on (t.mut_tipo_code = mm.tipo_mutuo and t.ente_proprietario_id = enteProprietarioId
                  and t.data_cancellazione is null
                  and date_trunc('day',dataElaborazione)>=date_trunc('day',t.validita_inizio)
                  and (date_trunc('day',dataElaborazione)<date_trunc('day',t.validita_fine) or t.validita_fine is null))
         left join siac_d_mutuo_stato stato
            ON (stato.mut_stato_code = mm.stato_operativo
                and stato.ente_proprietario_id =enteProprietarioId
                and stato.data_cancellazione is null
                and date_trunc('day',dataElaborazione)>=date_trunc('day',stato.validita_inizio)
                and (date_trunc('day',dataElaborazione)<date_trunc('day',stato.validita_fine) or stato.validita_fine is null))
        left join siac_t_soggetto sogg
             ON ( sogg.soggetto_code = mm.codice_soggetto::varchar
                  and sogg.ente_proprietario_id = enteProprietarioId
                  and sogg.data_cancellazione is null
                  and date_trunc('day',dataElaborazione)>=date_trunc('day',sogg.validita_inizio)
                  and (date_trunc('day',dataElaborazione)<date_trunc('day',sogg.validita_fine) or sogg.validita_fine is null))
         where mm.ente_proprietario_id=enteProprietarioId and mm.fl_elab='N'
         order by mm.migr_mutuo_id*/
     )
    loop
    	mutId := NULL;
        mutStatoRid := null;
        mutAttoAmmId := null;

    	-- mutuo.
-- usiamolo se la query del cursore non considera le tabelle di decoddifica,
        BEGIN
          /* da scommentare se usiamo la query complessa nel cursore
          strMessaggio := 'Verifica decodifiche valirizzate.' ;
		  if migrRecord.mut_tipo_id is null or
          	migrRecord.mut_stato_id is null or
            migrRecord.soggetto_id is null then

		  	if migrRecord.mut_tipo_id is null then
            	strMessaggioScarto := 'Il tipo mutuo '||migrRecord.tipo_mutuo||' manca come decodifica valida per l''ente '||enteProprietarioId;
          	elsif migrRecord.mut_stato_id is null then
            	strMessaggioScarto := 'Lo stato '||migrRecord.stato_operativo||' manca come decodifica valida per l''ente '||enteProprietarioId;
          	elsif migrRecord.soggetto_id is null then
            	strMessaggioScarto := 'Il soggetto con codice  '||migrRecord.codice_soggetto||' noon è presente nella siac_t_soggetto per l''ente '||enteProprietarioId;
          	end if;

            insert into
            migr_mutuo_scarto
            (mutuo_scarto_id,
                codice_mutuo,
                motivo_scarto,
                ente_proprietario_id)
            values
            (migrRecord.migr_mutuo_id
            ,migrRecord.codice_mutuo
            ,strMessaggioScarto
            ,enteProprietarioId);
            continue; --salta al record successivo
          end if;
			*/

          strMessaggio:='Inserimento nella tabella siac_t_mutuo per migr_mutuo_id '||migrRecord.migr_mutuo_id||'.';
          insert into siac_t_mutuo
            (mut_code,
            mut_desc,
            mut_tipo_id,
            mut_importo_iniziale,
            mut_importo_attuale,
            mut_durata,
            mut_num_registrazione,
            mut_data_inizio,
            mut_data_fine,
            mut_note,
            validita_inizio,
            data_creazione,
            ente_proprietario_id,
            login_operazione)
          (select
              migrRecord.codice_mutuo,
              migrRecord.descrizione,
              t.mut_tipo_id,
              migrRecord.importo_iniziale,
              migrRecord.importo_attuale,
              migrRecord.durata::integer,
              migrRecord.numero_registrazione
              ,migrRecord.data_inizio::timestamp
              ,migrRecord.data_fine::timestamp
              ,migrRecord.note
              ,dataInizioVal::timestamp
              ,clock_timestamp()
              ,enteProprietarioId
              ,loginoperazione
              from siac_d_mutuo_tipo t
              where t.mut_tipo_code = migrRecord.tipo_mutuo
              and t.ente_proprietario_id = enteProprietarioId
              and t.data_cancellazione is null
              and date_trunc('day',dataElaborazione)>=date_trunc('day',t.validita_inizio)
              and (date_trunc('day',dataElaborazione)<date_trunc('day',t.validita_fine) or t.validita_fine is null))
           returning mut_id into mutId;

        if mutId is null then
        	RAISE EXCEPTION ' % ', strMessaggio||'Verificare che il tipo mutuo '||migrRecord.tipo_mutuo||' sia una decodifica valida per l''ente '||enteProprietarioId;
        end if;

		-- togliere il blocco exception, e tutto il begin se vogliamo bloccare l'esecuzione senza gestire lo scarto, mi serve in fase di sviluppo per capire quani mutui sono scartati.
        EXCEPTION
        	when others  THEN
            	insert into
                migr_mutuo_scarto
                (migr_mutuo_id,
                  codice_mutuo,
                  motivo_scarto,
                  ente_proprietario_id)
                values
                (migrRecord.migr_mutuo_id
                ,migrRecord.codice_mutuo
                ,'Inserimento in siac_t_mutuo: '||substring(upper(SQLERRM) from 1 for 2400)
                ,enteProprietarioId);
                continue;
        END;

		-- stato.
        strMessaggio:='Inserimento nella tabella siac_r_mutuo_stato per migr_mutuo_id '||migrRecord.migr_mutuo_id||', codice stato '||migrRecord.stato_operativo||'.';
        insert into siac_r_mutuo_stato
        (  	mut_id,
            mut_stato_id,
            validita_inizio,
            ente_proprietario_id,
            data_creazione,
            login_operazione)
		(select
          mutId
          ,d.mut_stato_id
          ,dataInizioVal::timestamp
          ,enteProprietarioId
          ,clock_timestamp()
          ,loginoperazione
        from siac_d_mutuo_stato d
            where d.mut_stato_code = migrRecord.stato_operativo
            and d.ente_proprietario_id = enteProprietarioId
            and d.data_cancellazione is null
            and date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio)
			and (date_trunc('day',dataElaborazione)<date_trunc('day',d.validita_fine) or d.validita_fine is null))
        returning mut_stato_r_id into mutStatoRid;
        if mutStatoRid is null then
        	--RAISE EXCEPTION ' % ', strMessaggio||'Verificare che lo stato '||migrRecord.stato_operativo||' sia una decodifica valida per l''ente '||enteProprietarioId;
            -- x non bloccare l'esecuzione in fase di sviluppo inseriamo come scarto
                delete from siac_t_mutuo where mut_id = mutId;
            	insert into
                migr_mutuo_scarto
                (migr_mutuo_id,
  					codice_mutuo,
  					motivo_scarto,
					ente_proprietario_id)
                values
                (migrRecord.migr_mutuo_id
                ,migrRecord.codice_mutuo
                ,strMessaggio||'Verificare che lo stato '||migrRecord.stato_operativo||' sia una decodifica valida per l''ente '||enteProprietarioId
                ,enteProprietarioId);
                continue;
        end if;

		-- soggetto.
        strMessaggio:='Inserimento nella tabella siac_r_mutuo_soggetto per migr_mutuo_id '||migrRecord.migr_mutuo_id||', soggetto '||migrRecord.codice_soggetto||'.';
        insert into siac_r_mutuo_soggetto
        ( mut_id,
          soggetto_id,
          validita_inizio,
          ente_proprietario_id,
          data_creazione,
          login_operazione)
		(select
          mutId
          ,d.soggetto_id
          ,dataInizioVal::timestamp
          ,enteProprietarioId
          ,clock_timestamp()
          ,loginoperazione
          from siac_t_soggetto d
              where d.soggetto_code = migrRecord.codice_soggetto::varchar
              and d.ente_proprietario_id = enteProprietarioId
              and d.data_cancellazione is null
              and date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio)
              and (date_trunc('day',dataElaborazione)<date_trunc('day',d.validita_fine) or d.validita_fine is null)
              and exists (select 1 from siac_r_migr_soggetto_soggetto r where r.ente_proprietario_id = d.ente_proprietario_id and r.soggetto_id=d.soggetto_id))
        returning mut_soggetto_id into mutSoggettoId;

        if mutSoggettoId is null then
        	--RAISE EXCEPTION ' % ', strMessaggio||'Verificare che il soggetto con soggetto_code '||migrRecord.codice_soggetto||' sia presente per l''ente '||enteProprietarioId;
			-- x non bloccare l'esecuzione in fase di sviluppo inseriamo come scarto
            	delete from siac_r_mutuo_stato where mut_id = mutId;
                delete from siac_t_mutuo where mut_id = mutId;
            	insert into
                migr_mutuo_scarto
                (migr_mutuo_id,
  					codice_mutuo,
  					motivo_scarto,
					ente_proprietario_id)
                values
                (migrRecord.migr_mutuo_id
                ,migrRecord.codice_mutuo
                ,strMessaggio||'Verificare che il soggetto con soggetto_code '||migrRecord.codice_soggetto||' sia presente per l''ente '||enteProprietarioId
                ,enteProprietarioId);
                continue;

        end if;

        -- atto amministrativo
		strMessaggio:='call fnc_migr_attoamm.';
        if coalesce(migrRecord.numero_provvedimento,0)!=0
           --or migrRecord.tipo_provvedimento=SPR
           then
                  strMessaggio:='Provvedimento.';
                  select * into migrAttoAmm
                  from fnc_migr_attoamm (migrRecord.anno_provvedimento,migrRecord.numero_provvedimento,
				  -- DAVIDE - passaggio parametro direzione_provvedimento anche per i mutui
                                                 --migrRecord.tipo_provvedimento,NULL,
                                                 migrRecord.tipo_provvedimento,migrRecord.sac_provvedimento,
				  -- DAVIDE - Fine
                                                 migrRecord.oggetto_provvedimento,migrRecord.note_provvedimento,
                                                 migrRecord.stato_provvedimento,
                                                 enteProprietarioId,loginOperazione,dataElaborazione
                                                 , dataInizioVal);
                  if migrAttoAmm.codiceRisultato=-1 then
                      RAISE EXCEPTION ' % ', migrAttoAmm.messaggioRisultato;
                  ELSE
                  	strMessaggio:='Inserimento nella tabella siac_r_mutuo_atto_amm per migr_mutuo_id '||migrRecord.migr_mutuo_id||', id atto '||migrAttoAmm.id||'.';
                  	  insert into siac_r_mutuo_atto_amm
                        (mut_id,
                          attoamm_id,
                          validita_inizio,
                          ente_proprietario_id,
                          data_creazione,
                          login_operazione)
                          values
                          (mutId
                          ,migrAttoAmm.id
                          ,dataInizioVal::timestamp
                          ,enteProprietarioId
                          ,clock_timestamp()
                          ,loginOperazione)
                          returning mut_atto_amm_id into mutAttoAmmId;
                  end if;
          end if;
          strMessaggio:='Inserimento siac_r_migr_mutuo_t_mutuo per migr_mutuo_id= '
                               ||migrRecord.migr_mutuo_id||'.';
          insert into siac_r_migr_mutuo_t_mutuo
          (migr_mutuo_id,mut_id,ente_proprietario_id,data_creazione)
          values
          (migrRecord.migr_mutuo_id,mutId,enteProprietarioId,clock_timestamp());

          numerorecordinseriti:=numerorecordinseriti+1;

          -- valorizzare fl_elab = 'S'
          update migr_mutuo set fl_elab='S'
          where ente_proprietario_id=enteProprietarioId and
          migr_mutuo_id = migrRecord.migr_mutuo_id and
          fl_elab='N';
        end loop;

        RAISE NOTICE 'numerorecordinseriti %', numerorecordinseriti;

        -- aggiornamento progressivi
        select * into aggProgressivi
        from fnc_aggiorna_progressivi(enteProprietarioId, 'M', loginOperazione);

        if aggProgressivi.codresult=-1 then
        	RAISE EXCEPTION ' % ', aggProgressivi.messaggioRisultato;
        end if;
        messaggioRisultato:=strMessaggioFinale||'Inseriti '||numerorecordinseriti||' mutui.';
        return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;