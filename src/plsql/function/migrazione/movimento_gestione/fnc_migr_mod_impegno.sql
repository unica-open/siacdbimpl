/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_mod_impegno(
  enteproprietarioid integer,
  annobilancio varchar,
  tipomovgestusc varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  idmin integer,
  idmax integer,
  out numeroimpegniinseriti integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
    -- fnc_migr_mod_impegno --> function che effettua il caricamento delle modifiche impegni/subimpegni migrate
    -- leggendo in tab migr_impegno_modifica
      -- tipoMovGestUsc=I per caricamento impegni
      -- tipoMovGestUsc=S per caricamento subimpegni
    -- effettua inserimento di
     -- siac_t_modifica           -- per tipoMovGestUsc=I caricamento di modifica impegno
	 -- siac_r_modifica_stato     -- relazione rispetto allo stato della modifica
	 -- siac_t_movgest_ts_det_mod -- dettaglio modifica - mette in relazione la modiifca rispetto all'impegno / subimpegno	
		
     -- richiama
     -- fnc_migr_attoamm_movgest per ricercare / inserire in Contabilia il Provvedimento qualora
	 --  non sia stato ancora caricato

	 -- restituisce
     -- messaggioRisultato valorizzato con il risultato della elaborazione in formato testo
     -- numeroImpegniInseriti valorizzato con
        -- -12 dati da migrare non presenti in migr_impegno_modifica
        -- -1 errore
        -- N=numero impegni-subimpegni inseriti

    -- Punti di attenzione

    codRet       integer      :=0;    
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	attoAmmId integer:=0;
	tipoModId integer := 0;
	statoModId integer := 0;
	impegnoId integer := 0;
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

	migrImpegno  record;
	migrAttoAmmMovGest record; 

	countMigrImpegno integer:=0;

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
    numeroImpegniInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione modifiche impegni.da id ['||idmin||'] a id ['||idmax||']';
    strMessaggio:='Lettura modifiche impegni da migrare.';
	
	-- Gestiamo tra Impegni e Subimpegni
    if tipoMovGestUsc != TIPO_MOVIMENTO_I then
	    tipoMovGestUsc := TIPO_MOVIMENTO_TS_S;
	end if;

	begin
		select distinct 1 into strict countMigrImpegno from migr_impegno_modifica ms
		where ms.ente_proprietario_id=enteProprietarioId and
		    ms.tipo_movimento = tipoMovGestUsc and
		    ms.fl_elab='N'
		    and ms.impegno_mod_id >= idMin and ms.impegno_mod_id <=idMax;
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroImpegniInseriti:=-12;
		 return;
	end;

    for migrImpegno IN
    (select ms.*
     from migr_impegno_modifica ms
	 where ms.ente_proprietario_id=enteProprietarioId and
     	   ms.tipo_movimento = tipoMovGestUsc and
           ms.fl_elab='N'
           and ms.impegno_mod_id >= idMin and ms.impegno_mod_id <=idMax
     order by ms.impegno_mod_id
     )
    loop
        -- Id dati ricavati per inserimento relazioni
		codRet:=0;
	    attoAmmId:=0;
        tipoModId:=0;
        statoModId:=0;
		impegnoId:=0;
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
			       stato_tipo.mod_tipo_code = migrImpegno.tipo_modifica;
		
		    -- Lettura stato modifica
            code := 'STATO MODIFICA ['||STATO_MODIFICA||']';
		    select stato_mod.mod_stato_id 
			  into statoModId
			  from siac_d_modifica_stato stato_mod
			 where stato_mod.ente_proprietario_id=enteProprietarioId and 
			       stato_mod.mod_stato_code = migrImpegno.stato_operativo;
				   
		    -- Lettura tipo movimento
            code := 'TIPO MOVIMENTO ['||TIPO_MOVIMENTO||']';
			select tipo_movim.movgest_tipo_id 
			  into movgestTipoId
			  from siac_d_movgest_tipo tipo_movim
			 where tipo_movim.ente_proprietario_id=enteProprietarioId 
			   and tipo_movim.movgest_tipo_code=TIPO_MOVIMENTO_I;
			
		    -- Lettura tipo testata
			code := 'TIPO TESTATA ['||TIPO_TESTATA||']';
			if tipomovgestusc = TIPO_MOVIMENTO_I then
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
			    RAISE EXCEPTION 'Code cercato % non presente in archivio per la modifica Impegno %.',code,migrImpegno.impegno_mod_id;
			end if;

	    exception
		    when no_data_found then
			    RAISE EXCEPTION 'Code cercato % non presente in archivio per la modifica Impegno %.',code,migrImpegno.impegno_mod_id;
		    when others  THEN
			    RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		end;
		
		-- Lettura Impegno / Subimpegno
       	begin
		    -- Prima leggo dalla migr_impegno con chiave logica
		    select migrImp.migr_impegno_id 
			  into impegnoId
			  from migr_impegno migrImp
		     where migrImp.anno_esercizio = migrImpegno.anno_esercizio
			   and migrImp.anno_impegno = migrImpegno.anno_impegno 
			   and migrImp.numero_impegno = migrImpegno.numero_impegno 
			   and migrImp.numero_subimpegno = migrImpegno.numero_subimpegno 
			   and migrImp.tipo_movimento = migrImpegno.tipo_movimento 
			   and migrImp.ente_proprietario_id = enteProprietarioId;

 		    -- Poi ricavo movgest_ts_id dalla siac_r_migr_impegno_movgest_ts
			select relaz.movgest_ts_id
			  into movgestTsId
			  from siac_r_migr_impegno_movgest_ts relaz
			 where relaz.ente_proprietario_id=enteProprietarioId			
			   and relaz.migr_impegno_id = impegnoId; 
			
            -- E dopo gli altri dati movgest_ts_det_id che serve ad inserire
            -- nella siac_t_movgest_ts_det_mod			
		    select impegno_ts.movgest_ts_det_id
			  into movgestTsDetId
			  from siac_t_movgest_ts_det impegno_ts
			 where impegno_ts.ente_proprietario_id=enteProprietarioId
			   and impegno_ts.movgest_ts_id = movgestTsId
			   and impegno_ts.movgest_ts_det_tipo_id = movgestTsDetTipoId;

	        if 	impegnoId = 0 or movgestTsId = 0 or movgestTsDetId = 0 then
			    RAISE EXCEPTION 'Impegno non migrato per la modifica %.',migrImpegno.impegno_mod_id;
			end if;
				   
        exception
	      	when no_data_found then
		 	    RAISE EXCEPTION 'Impegno non migrato per la modifica %.',migrImpegno.impegno_mod_id;
            when others  THEN
	            RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
        end;				
		
		-- Lettura Id Atto Amministrativo da utilizzare nell'inserimento della siac_t_modifica
		begin
			Select aaLetto.id, aaLetto.codiceRisultato,aaLetto.messaggioRisultato
              into attoAmmId, codRet, strMessaggio
              from fnc_migr_leggi_attoamm (migrImpegno.anno_provvedimento,
			                               migrImpegno.numero_provvedimento,
										   migrImpegno.tipo_provvedimento,
										   migrImpegno.direzione_provvedimento,
										   enteProprietarioId,
										   loginOperazione,
										   dataElaborazione) aaLetto;

            if codRet != 0 then
   		        RAISE EXCEPTION 'Errore nella lettura del Provvedimento legato alla modifica Impegno : % - % ',migrImpegno.impegno_mod_id, strMessaggio;
            end if;
   
	        if 	attoAmmId = 0 then		
		        -- Inserimento del Provvedimento legato a modifica Impegno / Subimpegno
                strMessaggio:='Inserimento del Provvedimento legato alla modifica Impegno : '||migrImpegno.impegno_mod_id||' - ';
		        select * into migrAttoAmmMovGest
                  from fnc_migr_attoamm_movgest (migrImpegno.anno_provvedimento,migrImpegno.numero_provvedimento,
           							     migrImpegno.tipo_provvedimento,migrImpegno.direzione_provvedimento,
										 migrImpegno.oggetto_provvedimento,migrImpegno.note_provvedimento,
										 migrImpegno.stato_provvedimento,
            							 movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione, dataInizioVal::timestamp);

                if migrAttoAmmMovGest.codiceRisultato=-1 then
                    RAISE EXCEPTION 'Errore : Atto Amministrativo non inserito per la modifica Impegno % - % ',migrImpegno.impegno_mod_id, migrAttoAmmMovGest.messaggioRisultato;
                end if;      

				-- Leggi l'atto amministrativo appena inserito
                Select aaLetto.id, aaLetto.codiceRisultato,aaLetto.messaggioRisultato
                  into attoAmmId, codRet, strMessaggio
                  from fnc_migr_leggi_attoamm (migrImpegno.anno_provvedimento,
			                                   migrImpegno.numero_provvedimento,
										       migrImpegno.tipo_provvedimento,
										       migrImpegno.direzione_provvedimento,
										       enteProprietarioId,
										       loginOperazione,
										       dataElaborazione) aaLetto;

                if codRet != 0 then
   		            RAISE EXCEPTION 'Errore nella lettura del Provvedimento legato alla modifica Impegno : % - %', migrImpegno.impegno_mod_id, strMessaggio;
                end if;
				
		    end if;

		exception
	      	when no_data_found then
		 	    RAISE EXCEPTION 'Errore : Atto Amministrativo non presente o errato % ', migrAttoAmmMovGest.messaggioRisultato;
            when others  THEN
	            RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		end;
		
		-- Inserimento modifica Impegno / Subimpegno
		begin
		   	strMessaggio:='Inserimento siac_t_modifica impegno_mod_id= '||migrImpegno.impegno_mod_id||'.';
            INSERT INTO siac_t_modifica
			(mod_num, mod_desc, mod_data, mod_tipo_id, attoamm_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
            values
            (migrImpegno.numero_modifica,
             migrImpegno.descrizione,
             migrImpegno.data_modifica::timestamp,
             tipoModId,
			 attoAmmId, 
             dataInizioVal,
             enteProprietarioid,CLOCK_TIMESTAMP(),loginOperazione)
	        returning mod_id into modificaId;

        exception
        	when others  THEN
	            RAISE EXCEPTION 'Errore inserimento siac_t_modifica impegno_mod_id=% : %-%.',migrImpegno.impegno_mod_id,SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
        end;
		
		-- Inserimento relazione modifica stato
        begin 
		   	strMessaggio:='Inserimento siac_r_modifica_stato impegno_mod_id= '||migrImpegno.impegno_mod_id||'.';
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
	            RAISE EXCEPTION 'Errore inserimento siac_r_modifica_stato impegno_mod_id=% : %-%.',migrImpegno.impegno_mod_id,SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		end;
		
		-- Inserimento dettaglio modifica - mette in relazione la modifica rispetto all'impegno / subimpegno
        begin 
		   	strMessaggio:='Inserimento siac_t_movgest_ts_det_mod impegno_mod_id= '||migrImpegno.impegno_mod_id||'.';
            INSERT INTO siac_t_movgest_ts_det_mod
			(mod_stato_r_id, movgest_ts_det_id, movgest_ts_id, movgest_ts_det_tipo_id, movgest_ts_det_importo, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
            values
            (rmodificastatoId,
             movgestTsDetId,
			 movgestTsId,
			 movgestTsDetTipoId,
			 migrImpegno.importo,
             dataInizioVal,
             enteProprietarioid,CLOCK_TIMESTAMP(),loginOperazione);
        exception
        	when others  THEN
	            RAISE EXCEPTION 'Errore inserimento siac_t_movgest_ts_det_mod impegno_mod_id=% : %-%.',migrImpegno.impegno_mod_id,SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		end;

        numeroElementiInseriti:=numeroElementiInseriti+1;
    end loop;


    RAISE NOTICE 'NumeroModificheImpegniInseriti %', numeroElementiInseriti;

    -- valorizzare fl_elab = 'S'
	strMessaggio:='UPDATE MIGR_IMPEGNO_MODIFICA CON FL_ELAB=S';
    update migr_impegno_modifica t
	   set fl_elab='S'
     where t.ente_proprietario_id=enteProprietarioId and
                t.tipo_movimento = tipoMovGestUsc and
                t.fl_elab='N'
                and t.impegno_mod_id >= idMin and t.impegno_mod_id <=idMax;

    messaggioRisultato:=strMessaggioFinale||'Inserite '||numeroElementiInseriti||' modifiche impegni.';
    numeroImpegniInseriti:= numeroElementiInseriti;

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroImpegniInseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroImpegniInseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;