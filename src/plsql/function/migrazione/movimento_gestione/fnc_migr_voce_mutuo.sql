/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_voce_mutuo(
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

    mutVoceId integer := 0; -- id del record inserito sulla siac_t_mutuo
    tipoMutVoceId integer := 0; -- id del tipo voce mutuo ricercato per codice.

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
	--dataInizioVal timestamp :=annoBilancio||'-01-01';
	dataInizioVal timestamp :=null;

	movGestTsId integer := 0; -- id del movimento ts a cui si riferisce la voce (tipo TESTATA)
	mutVoceCode integer := 0; --contatore della voce di mutuo per ente.

    migrRecord record;
    aggProgressivi record; -- chiamata funzione fnc_aggiorna_progressivi
    recordScarto boolean:=false;

    MOVGEST_IMPEGNO		  CONSTANT varchar:='I';  -- codice da ricercare  nella tabella siac_d_movgest_tipo
	MOVGEST_TS_IMPEGNI    CONSTANT varchar:='T';  -- codice da ricercare  nella tabella siac_d_movgest_ts_tipo
    movGestTipoId INTEGER := 0;
    movGestTsTipoId_T INTEGER := 0;

BEGIN
    numerorecordinseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione voci mutuo.';
    strMessaggio:='Lettura voci mutuo da migrare.';

	begin
		select distinct 1 into strict countRecordDaMigrare from migr_voce_mutuo mm
		where mm.ente_proprietario_id=enteProprietarioId and
		    mm.fl_elab='N';
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numerorecordinseriti:=-12;
		 return;
	end;

    DELETE FROM MIGR_VOCE_MUTUO_SCARTO WHERE ente_proprietario_id = enteProprietarioId;

    -- recupero dell'ultimo voce_mutuo_code per l'ente potremmo leggerlo dalla tabella siac_t_progressivo....
	select mut_voce_code::integer+1 into mutVoceCode
    from siac_t_mutuo_voce s
    where s.ente_proprietario_id=enteProprietarioId
    and fnc_migr_isnumeric(mut_voce_code)
	order by  fnc_migr_sortnum(mut_voce_code) desc limit 1;
    if mutVoceCode is null then mutVoceCode := 1; end if;

    -- variabili usate nel ciclo che devono essere presenti sul sistema.
    begin
      strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_IMPEGNO||'.';
      select d.movgest_tipo_id into strict movGestTipoId
      from siac_d_movgest_tipo d
      where d.ente_proprietario_id=enteproprietarioid
      and d.movgest_tipo_code = MOVGEST_IMPEGNO
      and d.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                  or d.validita_fine is null);

      strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_TS_IMPEGNI||'.';
      select d.movgest_ts_tipo_id into strict movGestTsTipoId_T
      from siac_d_movgest_ts_tipo d
      where d.ente_proprietario_id=enteproprietarioid
      and d.movgest_ts_tipo_code = MOVGEST_TS_IMPEGNI
      and d.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                  or d.validita_fine is null);
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



    -- considerate le voci legate a mutui migrati
    -- le voci che sarebbe da migrare il cui mutuo non è stato migrato sono inserite come scarto nella tabella migr_voce_mutuo_scarto.
    for migrRecord IN
    (
     select mm.*, rm.mut_id
     from migr_voce_mutuo mm, migr_mutuo m , siac_r_migr_mutuo_t_mutuo rm
	 where mm.ente_proprietario_id=enteProprietarioId and mm.fl_elab='N'
     and m.codice_mutuo=mm.nro_mutuo and m.ente_proprietario_id=enteProprietarioId
     and rm.migr_mutuo_id = m.migr_mutuo_id and rm.ente_proprietario_id=enteProprietarioId
     order by mm.migr_voce_mutuo_id
     )
    loop
          movGestTsId := NULL; -- identificativo dell'impegno di riferimento

          strMessaggio:='Lettura subimpegno testata di riferimento per la voce '||migrRecord.migr_voce_mutuo_id||
            ', impegno '||migrRecord.numero_impegno||'/'||migrRecord.anno_impegno||'/'||migrRecord.anno_esercizio||'.';

          /*select m.movgest_id into movGestId
          from siac_t_movgest m
          where m.movgest_anno = migrRecord.anno_impegno::INTEGER
          and m.movgest_numero= migrRecord.numero_impegno::NUMERIC
          and m.ente_proprietario_id = enteProprietarioId::INTEGER;*/
		  select ts.movgest_ts_id into movGestTsId
          from siac_t_movgest m, siac_t_movgest_ts ts
          where m.movgest_anno = migrRecord.anno_impegno::INTEGER
          and m.movgest_numero= migrRecord.numero_impegno::NUMERIC
          and m.ente_proprietario_id = enteProprietarioId::INTEGER
          and ts.movgest_id=m.movgest_id
          and ts.movgest_ts_id_padre is null   			-- MOVGESTTS TIPO TESTATA
          and ts.movgest_ts_tipo_id = movGestTsTipoId_T -- MOVGESTTS TIPO TESTATA
          and m.movgest_tipo_id = movGestTipoId; -- IMPEGNO

          if movGestTsId is null then
        	insert into migr_voce_mutuo_scarto
                  (migr_voce_mutuo_id,
                    nro_mutuo,
                    numero_impegno,
                    anno_impegno,
                    anno_esercizio,
                    motivo_scarto,
                    ente_proprietario_id)
                  values
                  (migrRecord.migr_voce_mutuo_id
                  ,migrRecord.nro_mutuo
                  ,migrRecord.numero_impegno
                  ,migrRecord.anno_impegno
                  ,migrRecord.anno_esercizio
                  ,'Impegno di riferimento non migrato.'
                  ,enteProprietarioId);
            continue;
    	  end if;
          BEGIN
              strMessaggio:='Inserimento nella tabella siac_t_mutuo_voce per migr_voce_mutuo_id '||migrRecord.migr_voce_mutuo_id||'.';
              insert into siac_t_mutuo_voce
                (mut_voce_code,
                mut_voce_desc,
                mut_voce_importo_iniziale,
                mut_voce_importo_attuale,
                mut_id,
                mut_voce_tipo_id,
                validita_inizio,
                data_creazione,
                ente_proprietario_id,
                login_operazione)
              (select
                  mutVoceCode::varchar
                  ,migrRecord.descrizione
                  ,migrRecord.importo_iniziale
                  ,migrRecord.importo_attuale
                  ,migrRecord.mut_id
                  ,t.mut_voce_tipo_id
                  ,dataInizioVal::timestamp
                  ,clock_timestamp()
                  ,enteProprietarioId
                  ,loginoperazione
                  from siac_d_mutuo_voce_tipo t
                  where t.mut_voce_tipo_code = migrRecord.tipo_voce_mutuo and t.ente_proprietario_id = enteProprietarioId
                  and t.data_cancellazione is null
                  and date_trunc('day',dataElaborazione)>=date_trunc('day',t.validita_inizio)
                  and (date_trunc('day',dataElaborazione)<date_trunc('day',t.validita_fine) or t.validita_fine is null))
               returning mut_voce_id into mutVoceId;

            if mutVoceId is null then
                RAISE EXCEPTION ' % ', strMessaggio||'Verificare che il tipo voce di mutuo '||migrRecord.tipo_voce_mutuo||' sia una decodifica valida per l''ente '||enteProprietarioId;
            end if;

            -- togliere il blocco exception, e tutto il begin se vogliamo bloccare l'esecuzione senza gestire lo scarto, mi serve in fase di sviluppo per capire quante voci sono scartate.
            EXCEPTION
                when others  THEN
                	strMessaggio:='Inserimento nella tabella migr_voce_mutuo_scarto per migr_voce_mutuo_id '||migrRecord.migr_voce_mutuo_id||'.';
                    insert into migr_voce_mutuo_scarto
                    (migr_voce_mutuo_id,
                      nro_mutuo,
                      numero_impegno,
                      anno_impegno,
                      anno_esercizio,
                      motivo_scarto,
                      ente_proprietario_id)
                    values
                    (migrRecord.migr_voce_mutuo_id
                    ,migrRecord.nro_mutuo
                    ,migrRecord.numero_impegno
                    ,migrRecord.anno_impegno
                    ,migrRecord.anno_esercizio
                    ,'Inserimento in siac_t_mutuo_voce: '||substring(upper(SQLERRM) from 1 for 2400)
                    ,enteProprietarioId);
                    continue;
            END;
          -- impegno.
          strMessaggio:='Inserimento nella tabella siac_r_mutuo_voce_movgest per migr_voce_mutuo_id '||migrRecord.migr_voce_mutuo_id
                      ||', impegno '||migrRecord.numero_impegno||'/'||migrRecord.anno_impegno||'/'||migrRecord.anno_esercizio;

          insert into siac_r_mutuo_voce_movgest
          (mut_voce_id,
            movgest_ts_id,
            validita_inizio,
            ente_proprietario_id,
            data_creazione,
            login_operazione)
          values (
            mutVoceId
            ,movGestTsId
            ,dataInizioVal::timestamp
            ,enteProprietarioId
            ,clock_timestamp()
            ,loginoperazione);

            strMessaggio:='Inserimento siac_r_migr_voce_mutuo_t_mutuo_voce per migr_voce_mutuo_id= '
                                 ||migrRecord.migr_voce_mutuo_id||' mut_voce_id '||mutVoceId;

            insert into siac_r_migr_voce_mutuo_t_mutuo_voce
            (migr_voce_mutuo_id,mut_voce_id,ente_proprietario_id,data_creazione)
            values
            (migrRecord.migr_voce_mutuo_id,mutVoceId,enteProprietarioId,clock_timestamp());

            -- valorizzare fl_elab = 'S'
            update migr_voce_mutuo set fl_elab='S'
            where ente_proprietario_id=enteProprietarioId and
            migr_voce_mutuo_id = migrRecord.migr_voce_mutuo_id and
            fl_elab='N';

			numerorecordinseriti:=numerorecordinseriti+1;
			mutVoceCode := mutVoceCode+1;

        end loop;
        -- inserisco nella tabella degli scarti le voci legate a mutui non migrati. valutare se puo andar bene o la mancanza del mutuo pe una voce da migrare deve bloccare l'esecuzione.
        insert into migr_voce_mutuo_scarto
        (migr_voce_mutuo_id,
         nro_mutuo,
         numero_impegno,
         anno_impegno,
         anno_esercizio,
         motivo_scarto,
          ente_proprietario_id)
        (select mm.migr_voce_mutuo_id
          , mm.nro_mutuo
          , mm.numero_impegno
          , mm.anno_impegno
          , mm.anno_esercizio
          , 'Mutuo di riferimento non migrato'
          , enteProprietarioId
         from migr_voce_mutuo mm, migr_mutuo m
         where mm.ente_proprietario_id=enteProprietarioId and mm.fl_elab='N'
         and mm.nro_mutuo = m.codice_mutuo
         and m.ente_proprietario_id=enteProprietarioId
         and not exists (select 1 from  siac_r_migr_mutuo_t_mutuo rm where rm.migr_mutuo_id=m.migr_mutuo_id and rm.ente_proprietario_id=enteProprietarioId));

        RAISE NOTICE 'numerorecordinseriti %', numerorecordinseriti;

        -- aggiornamento progressivi
        select * into aggProgressivi
        from fnc_aggiorna_progressivi(enteProprietarioId, 'VM', loginOperazione);

        if aggProgressivi.codresult=-1 then
        	RAISE EXCEPTION ' % ', aggProgressivi.messaggioRisultato;
        end if;
        messaggioRisultato:=strMessaggioFinale||'Inserite '||numerorecordinseriti||' voci di mutuo.';
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