/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_mod_accertamento(
  enteproprietarioid integer,
  annobilancio varchar,
  tipomovgestusc varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  idmin integer,
  idmax integer,
  out numeroaccertamentiinseriti integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
    -- fnc_migr_mod_accertamento --> function che effettua il caricamento delle modifiche accertamenti/subaccertamenti migrate
    -- leggendo in tab migr_accertamento_mod
      -- tipoMovGestUsc=A per caricamento accertamenti
      -- tipoMovGestUsc=S per caricamento subaccertamenti
    -- effettua inserimento di
     -- siac_t_modifica           -- per tipoMovGestUsc=A caricamento di modifica accertamento
	 -- siac_r_modifica_stato     -- relazione rispetto allo stato della modifica
	 -- siac_t_movgest_ts_det_mod -- dettaglio modifica - mette in relazione la modiifca rispetto all'accertamento / subaccertamento
		
     -- richiama
     -- fnc_migr_attoamm_movgest per ricercare / inserire in Contabilia il Provvedimento qualora
	 --  non sia stato ancora caricato

	 -- restituisce
     -- messaggioRisultato valorizzato con il risultato della elaborazione in formato testo
     -- numeroAccertamentiInseriti valorizzato con
        -- -12 dati da migrare non presenti in migr_accertamento_mod
        -- -1 errore
        -- N=numero accertamenti-accertamenti inseriti

    -- Punti di attenzione

    codRet       integer      :=0;    
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	attoAmmId integer:=0;
	tipoModId integer := 0;
	statoModId integer := 0;
	accertamentoId integer := 0;
	movgestId integer:=0;
	movgestTsDetId integer := 0;
	movgestTsId integer := 0;
	movgestTipoId integer :=0;
	movgestTsTipoId integer :=0;
	movgestTsDetTipoId integer := 0;
	modificaId integer := 0;
	rmodificastatoId integer := 0;

	code varchar(500) := '';
	testata_tipo varchar(1) := '';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
	--dataInizioVal timestamp :=annoBilancio||'-01-01';
	dataInizioVal timestamp :=null;

	migrAccertamento  record;
	migrAttoAmmMovGest record;

	countMigrAccertamento integer:=0;

	numeroElementiInseriti   integer:=0;

	strToElab varchar(1000):='';

	--    costanti
    TIPO_MODIFICA          CONSTANT varchar:= 'ID TIPO MODIFICA';
    STATO_MODIFICA         CONSTANT varchar:= 'ID STATO MODIFICA';
    TIPO_MOVIMENTO         CONSTANT varchar:= 'ID TIPO MOVIMENTO';
	TIPO_TESTATA           CONSTANT varchar:= 'ID TIPO TESTATA';
	TIPO_DETTAGLIO         CONSTANT varchar:= 'ID TIPO DETTAGLIO';

	SPR                    CONSTANT varchar:='SPR||';
    TIPO_MOVIMENTO_I       CONSTANT varchar:='I';
    TIPO_MOVIMENTO_A       CONSTANT varchar:='A';
	TIPO_MOVIMENTO_TS_T    CONSTANT varchar:='T';
    TIPO_MOVIMENTO_TS_S    CONSTANT varchar:='S';
	TIPO_MOVIMENTO_DET_INI CONSTANT varchar:='I';  
	TIPO_MOVIMENTO_DET_ATT CONSTANT varchar:='A';  

BEGIN
    numeroAccertamentiInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione modifiche accertamenti.da id ['||idmin||'] a id ['||idmax||']';
    strMessaggio:='Lettura modifiche accertamenti da migrare.';
	
	-- Gestiamo tra Accertamenti e Subaccertamenti
    if tipoMovGestUsc != TIPO_MOVIMENTO_A then
	    tipoMovGestUsc := TIPO_MOVIMENTO_TS_S;
	end if;

	begin
		select distinct 1 into strict countMigrAccertamento from migr_accertamento_mod ms
		where ms.ente_proprietario_id=enteProprietarioId and
		    ms.tipo_movimento = tipoMovGestUsc and
		    ms.fl_elab='N'
		    and ms.accertamento_mod_id >= idMin and ms.accertamento_mod_id <=idMax;
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroAccertamentiInseriti:=-12;
		 return;
	end;

    for migrAccertamento IN
    (select ms.*
     from migr_accertamento_mod ms
	 where ms.ente_proprietario_id=enteProprietarioId and
     	   ms.tipo_movimento = tipoMovGestUsc and
           ms.fl_elab='N'
           and ms.accertamento_mod_id >= idMin and ms.accertamento_mod_id <=idMax
     order by ms.accertamento_mod_id
     )
    loop
        -- Id dati ricavati per inserimento relazioni
		codRet:=0;
	    attoAmmId:=0;
        tipoModId:=0;
        statoModId:=0;
		accertamentoId:=0;
	    movgestTsDetId:=0;
	    movgestTsId:=0;
	    movgestTipoId:=0;
	    movgestTsTipoId:=0;
	    movgestTsDetTipoId:=0;
	    modificaId:=0;
	    rmodificastatoId:=0;

		-- Lettura codici Id che servono nelle ricerche / inserimento
		begin
		    -- Lettura tipo modifica
            code := 'TIPO MODIFICA ['||TIPO_MODIFICA||']';
		    select stato_tipo.mod_tipo_id 
			  into tipoModId
			  from siac_d_modifica_tipo stato_tipo
			 where stato_tipo.ente_proprietario_id=enteProprietarioId and
			       stato_tipo.mod_tipo_code = migrAccertamento.tipo_modifica;
				   
		    -- Lettura stato modifica
            code := 'STATO MODIFICA ['||STATO_MODIFICA||']';
		    select stato_mod.mod_stato_id 
			  into statoModId
			  from siac_d_modifica_stato stato_mod
			 where stato_mod.ente_proprietario_id=enteProprietarioId and 
			       stato_mod.mod_stato_code = migrAccertamento.stato_operativo;
				   
		    -- Lettura tipo movimento
            code := 'TIPO MOVIMENTO ['||TIPO_MOVIMENTO||']';
			select tipo_movim.movgest_tipo_id 
			  into movgestTipoId
			  from siac_d_movgest_tipo tipo_movim
			 where tipo_movim.ente_proprietario_id=enteProprietarioId 
			   and tipo_movim.movgest_tipo_code=TIPO_MOVIMENTO_A;
			
		    -- Lettura tipo testata
			code := 'TIPO TESTATA ['||TIPO_TESTATA||']';
			if tipomovgestusc = TIPO_MOVIMENTO_A then
			    testata_tipo := TIPO_MOVIMENTO_TS_T;
            else 
			    testata_tipo := TIPO_MOVIMENTO_TS_S;
			end if;
			select tipo_test.movgest_ts_tipo_id 
			  into movgestTsTipoId
			  from siac_d_movgest_ts_tipo tipo_test
			 where tipo_test.ente_proprietario_id=enteProprietarioId and 
                   tipo_test.movgest_ts_tipo_code = testata_tipo;

		    -- Lettura tipo testata dettaglio (sarà sempre riferito all'importo attuale, altrimenti non sono possibili modifiche)
			code := 'TIPO DETTAGLIO ['||TIPO_DETTAGLIO||']';
			select tipo_dett.movgest_ts_det_tipo_id 
			  into movgestTsDetTipoId
			  from siac_d_movgest_ts_det_tipo tipo_dett
			 where tipo_dett.ente_proprietario_id=enteProprietarioId and 
			       tipo_dett.movgest_ts_det_tipo_code=TIPO_MOVIMENTO_DET_ATT;

	        if 	tipoModId = 0 or statoModId = 0 or movgestTipoId = 0 or movgestTsTipoId = 0 or movgestTsDetTipoId = 0 then
			    RAISE EXCEPTION 'Code cercato % non presente in archivio per la modifica Accertamento %.',code,migrAccertamento.accertamento_mod_id;
			end if;

		exception
		    when no_data_found then
			    RAISE EXCEPTION 'Code cercato % non presente in archivio per la modifica Accertamento %.',code,migrAccertamento.accertamento_mod_id;
		    when others  THEN
			    RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		end;
		
		-- Lettura Accertamento / Subaccertamento
       	begin
		    -- Prima leggo dalla migr_accertamento con chiave logica
		    select migrAcc.migr_accertamento_id 
			  into accertamentoId
			  from migr_accertamento migrAcc
		     where migrAcc.anno_esercizio = migrAccertamento.anno_esercizio
			   and migrAcc.anno_accertamento = migrAccertamento.anno_accertamento
			   and migrAcc.numero_accertamento = migrAccertamento.numero_accertamento
			   and migrAcc.numero_subaccertamento = migrAccertamento.numero_subaccertamento
			   and migrAcc.tipo_movimento = migrAccertamento.tipo_movimento
			   and migrAcc.ente_proprietario_id = enteProprietarioId;

 		    -- Poi ricavo movgest_ts_id dalla siac_r_migr_accertamento_movgest_ts
			select relaz.movgest_ts_id
			  into movgestTsId
			  from siac_r_migr_accertamento_movgest_ts relaz
			 where relaz.ente_proprietario_id=enteProprietarioId 	
			   and relaz.migr_accertamento_id = accertamentoId; 
			
            -- E dopo gli altri dati movgest_ts_det_id che serve ad inserire
            -- nella siac_t_movgest_ts_det_mod			
		    select accertamento_ts.movgest_ts_det_id
			  into movgestTsDetId
			  from siac_t_movgest_ts_det accertamento_ts
			 where accertamento_ts.ente_proprietario_id=enteProprietarioId
			   and accertamento_ts.movgest_ts_id = movgestTsId
			   and accertamento_ts.movgest_ts_det_tipo_id = movgestTsDetTipoId;

	        if 	accertamentoId = 0 or movgestTsId = 0 or movgestTsDetId = 0 then
			    RAISE EXCEPTION 'Accertamento non migrato per la modifica %.',migrAccertamento.accertamento_mod_id;
			end if;
				   
        exception
	      	when no_data_found then
		 	    RAISE EXCEPTION 'Accertamento non migrato per la modifica %.',migrAccertamento.accertamento_mod_id;
            when others  THEN
	            RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
        end;				
		
		-- Lettura Id Atto Amministrativo da utilizzare nell'inserimento della siac_t_modifica
		begin
			Select aaLetto.id, aaLetto.codiceRisultato,aaLetto.messaggioRisultato
              into attoAmmId, codRet, strMessaggio
              from fnc_migr_leggi_attoamm (migrAccertamento.anno_provvedimento,
			                               migrAccertamento.numero_provvedimento,
										   migrAccertamento.tipo_provvedimento,
										   migrAccertamento.direzione_provvedimento,
										   enteProprietarioId,
										   loginOperazione,
										   dataElaborazione) aaLetto;

            if codRet != 0 then
   		        RAISE EXCEPTION 'Errore nella lettura del Provvedimento legato alla modifica Accertamento : % - % ',migrAccertamento.accertamento_mod_id, strMessaggio;
            end if;

	        if 	attoAmmId = 0 then
		        -- Inserimento del Provvedimento legato a modifica Accertamento / Subaccertamento
	            strMessaggio:='Inserimento del Provvedimento legato alla modifica Accertamento : '||migrAccertamento.accertamento_mod_id||' - ';
		        select * into migrAttoAmmMovGest
                  from fnc_migr_attoamm_movgest (migrAccertamento.anno_provvedimento,migrAccertamento.numero_provvedimento,
           							     migrAccertamento.tipo_provvedimento,migrAccertamento.direzione_provvedimento,
										 migrAccertamento.oggetto_provvedimento,migrAccertamento.note_provvedimento,
										 migrAccertamento.stato_provvedimento,
            							 movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione, dataInizioVal::timestamp);

                if migrAttoAmmMovGest.codiceRisultato=-1 then
                    RAISE EXCEPTION 'Errore : Atto Amministrativo non inserito per la modifica Accertamento % - % ',migrAccertamento.accertamento_mod_id, migrAttoAmmMovGest.messaggioRisultato;
                end if;
				
				-- Leggi l'atto amministrativo appena inserito
                Select aaLetto.id, aaLetto.codiceRisultato,aaLetto.messaggioRisultato
                  into attoAmmId, codRet, strMessaggio
                  from fnc_migr_leggi_attoamm (migrAccertamento.anno_provvedimento,
			                                   migrAccertamento.numero_provvedimento,
										       migrAccertamento.tipo_provvedimento,
										       migrAccertamento.direzione_provvedimento,
										       enteProprietarioId,
										       loginOperazione,
										       dataElaborazione) aaLetto;

                if codRet != 0 then
   		            RAISE EXCEPTION 'Errore nella lettura del Provvedimento legato alla modifica Accertamento : % - %', migrAccertamento.accertamento_mod_id, strMessaggio;
                end if;

			end if;

		exception
	      	when no_data_found then
		 	    RAISE EXCEPTION 'Errore : Atto Amministrativo non presente o errato % ', migrAttoAmmMovGest.messaggioRisultato;
            when others  THEN
	            RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		end;
		
		-- Inserimento modifica Accertamento / Subaccertamento
		begin
		   	strMessaggio:='Inserimento siac_t_modifica accertamento_mod_id= '||migrAccertamento.accertamento_mod_id||'.';
            INSERT INTO siac_t_modifica
			(mod_num, mod_desc, mod_data, mod_tipo_id, attoamm_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
            values
            (migrAccertamento.numero_modifica,
             migrAccertamento.descrizione,
             migrAccertamento.data_modifica::timestamp,
             tipoModId,
			 attoAmmId,
             dataInizioVal,
             enteProprietarioid,CLOCK_TIMESTAMP(),loginOperazione)
	        returning mod_id into modificaId;

        exception
        	when others  THEN
	            RAISE EXCEPTION 'Errore inserimento siac_t_modifica accertamento_mod_id=% : %-%.',migrAccertamento.accertamento_mod_id,SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
        end;
		
		-- Inserimento relazione modifica stato
        begin 
		   	strMessaggio:='Inserimento siac_r_modifica_stato accertamento_mod_id= '||migrAccertamento.accertamento_mod_id||'.';
            INSERT INTO siac_r_modifica_stato
			(mod_id, mod_stato_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
            values
            (modificaId,
             statoModId,
             dataInizioVal,
             enteProprietarioid,CLOCK_TIMESTAMP(),loginOperazione)
	        returning mod_stato_r_id into rmodificastatoId;
        exception
        	when others  THEN
	            RAISE EXCEPTION 'Errore inserimento siac_r_modifica_stato accertamento_mod_id=% : %-%.',migrAccertamento.accertamento_mod_id,SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		end;
		
		-- Inserimento dettaglio modifica - mette in relazione la modifica rispetto all'accertamento / subaccertamento
        begin 
		   	strMessaggio:='Inserimento siac_t_movgest_ts_det_mod accertamento_mod_id= '||migrAccertamento.accertamento_mod_id||'.';
            INSERT INTO siac_t_movgest_ts_det_mod
			(mod_stato_r_id, movgest_ts_det_id, movgest_ts_id, movgest_ts_det_tipo_id, movgest_ts_det_importo, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
            values
            (rmodificastatoId,
             movgestTsDetId,
			 movgestTsId,
			 movgestTsDetTipoId,
			 migrAccertamento.importo,
             dataInizioVal,
             enteProprietarioid,CLOCK_TIMESTAMP(),loginOperazione);
        exception
        	when others  THEN
	            RAISE EXCEPTION 'Errore inserimento siac_t_movgest_ts_det_mod accertamento_mod_id=% : %-%.',migrAccertamento.accertamento_mod_id,SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		end;

        numeroElementiInseriti:=numeroElementiInseriti+1;
    end loop;


    RAISE NOTICE 'NumeroModificheAccertamentiInseriti %', numeroElementiInseriti;

    -- valorizzare fl_elab = 'S'
	strMessaggio:='UPDATE MIGR_ACCERTAMENTO_MOD CON FL_ELAB=S';
    update migr_accertamento_mod t
	   set fl_elab='S'
     where t.ente_proprietario_id=enteProprietarioId and
                t.tipo_movimento = tipoMovGestUsc and
                t.fl_elab='N'
                and t.accertamento_mod_id >= idMin and t.accertamento_mod_id <=idMax;

    messaggioRisultato:=strMessaggioFinale||'Inserite '||numeroElementiInseriti||' modifiche accertamenti.';
    numeroAccertamentiInseriti:= numeroElementiInseriti;

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroAccertamentiInseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroAccertamentiInseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;