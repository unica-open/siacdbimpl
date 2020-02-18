/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION fnc_migr_iva_aliquota(enteProprietarioId integer,
                                                 annobilancio varchar,
                                                 loginOperazione varchar,
                                                 dataElaborazione timestamp,
                                                 out numeroRecordInseriti integer,
                                                 out messaggioRisultato varchar);

CREATE OR REPLACE FUNCTION fnc_migr_iva_aliquota(enteProprietarioId integer,
                                                 annobilancio varchar,
                                                 loginOperazione varchar,
                                                 dataElaborazione timestamp,
                                                 idMin integer,
                                                 idMax integer,
                                                 out numeroRecordInseriti integer,
                                                 out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE

 strMessaggio VARCHAR(2500):='';
 strMessaggioFinale VARCHAR(2500):='';
 strMessaggioScarto VARCHAR(1500):='';
 countMigr integer := 0;

 migrAliquota record;

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

 scartoid		integer := null;
 ivaaliquotaid	integer := null;
 ivamovid		integer := null;

 h_imponibile    numeric := null;
 h_imposta       numeric := null;
 h_totale        numeric := null;

 TIPO_DOC_NCD    CONSTANT varchar := 'NCD';
 TIPO_DOC_NTE    CONSTANT varchar := 'NTE';

BEGIN

	numeroRecordInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

  	strMessaggioFinale:='Migrazione aliquota iva da id ['||idMin||'] a id ['||idMax||']';
	--strMessaggioFinale:='Migrazione aliquota iva.';

    strMessaggio:='Lettura dati da migrare.';
	begin
        select distinct 1 into countMigr
         from migr_docquo_spesa_iva_aliquota aliq,
         migr_docquo_spesa_iva iva,
         siac_r_migr_docquospesaiva_t_subdoc_iva r
         where aliq.ente_proprietario_id=enteProprietarioId
         and aliq.fl_elab='N'
         and aliq.docquo_spesa_iva_id=iva.docquo_spesa_iva_id
         and iva.fl_elab='S'
         and r.migr_docquo_spesa_iva_id=iva.migr_docquo_spesa_iva_id
   		 and aliq.migr_docquospesa_iva_aliquota_id >= idMin and aliq.migr_docquospesa_iva_aliquota_id <=idMax;
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroRecordInseriti:=-12;
		 return;
	end;

    strMessaggio:='Lettura dati da migrare.Inizio ciclo.';
    for migrAliquota IN
    (select aliq.*, r.subdociva_id
         from migr_docquo_spesa_iva_aliquota aliq,
         migr_docquo_spesa_iva iva,
         siac_r_migr_docquospesaiva_t_subdoc_iva r
         where aliq.ente_proprietario_id=enteProprietarioId
         and aliq.fl_elab='N'
         and aliq.docquo_spesa_iva_id=iva.docquo_spesa_iva_id
         and iva.fl_elab='S'
         and r.migr_docquo_spesa_iva_id=iva.migr_docquo_spesa_iva_id
 		 and aliq.migr_docquospesa_iva_aliquota_id >= idMin and aliq.migr_docquospesa_iva_aliquota_id <=idMax
     order by aliq.migr_docquospesa_iva_aliquota_id
     )
    loop
        ivaaliquotaid	:= null; -- pk siac_t_iva_aliquota
        ivamovid		:= null; -- pk siac_t_ivamov
        h_imponibile	:= null;
        h_imposta		:= null;
        h_totale		:= null;

        begin
          strMessaggio := 'Ricerca aliquota iva per codice '||migrAliquota.cod_aliquota||'.';

          select ivaaliquota_id into strict ivaaliquotaid
          from siac_t_iva_aliquota
          where ivaaliquota_code = migrAliquota.cod_aliquota
          and ente_proprietario_id = enteproprietarioid
          and data_cancellazione is null
          and date_trunc('day',dataelaborazione)>=date_trunc('day',validita_inizio)
          and (date_trunc('day',dataelaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

 		  exception
           when no_data_found then
        	strMessaggio := strMessaggio||' Scarto per dato non trovato.';
            INSERT INTO migr_docquo_spesa_iva_aliquota_scarto
            (migr_docquospesa_iva_aliquota_id,
             motivo_scarto,
             data_creazione,
             ente_proprietario_id
            )values(migrAliquota.migr_docquospesa_iva_aliquota_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);
        	continue;
          when too_many_rows THEN
        	strMessaggio := strMessaggio||' Scarto per troppi valori trovati.';
            INSERT INTO migr_docquo_spesa_iva_aliquota_scarto
            (migr_docquospesa_iva_aliquota_id,
             motivo_scarto,
             data_creazione,
             ente_proprietario_id
            )values(migrAliquota.migr_docquospesa_iva_aliquota_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);
        	continue;
          when others  THEN
              RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		end;

        h_imponibile := migrAliquota.importo_imponibile;
        h_imposta    := migrAliquota.imposta;
        h_totale 	 := migrAliquota.totale;

        if (migrAliquota.tipo = TIPO_DOC_NCD or migrAliquota.tipo = TIPO_DOC_NTE) then
        	if h_imponibile>0 then h_imponibile := h_imponibile * (-1); end if;
        	if h_imposta > 0 then h_imposta := h_imposta * (-1); end if;
            h_totale := h_imponibile + h_imposta;
        end if;

    	strMessaggio := 'Inserimento siac_t_ivamov.';
		insert into siac_t_ivamov
          (ivamov_imponibile,
		   ivamov_imposta,
  		   ivamov_totale,
  	       ivaaliquota_id,
  		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione)
         values
         ( h_imponibile
          ,h_imposta
          ,h_totale
          ,ivaaliquotaid
          ,dataInizioVal::timestamp
          ,enteproprietarioid
          ,loginOperazione)
        returning ivamov_id into ivamovid;

        if ivamovid is null then
        	strMessaggio := strMessaggio||' Scarto per inserimento non riuscito.';
            INSERT INTO migr_docquo_spesa_iva_aliquota_scarto
            (migr_docquospesa_iva_aliquota_id,
             motivo_scarto,
             data_creazione,
             ente_proprietario_id
            )values(migrAliquota.migr_docquospesa_iva_aliquota_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);
        	continue;
        end if;

		scartoId:=null;
        strMessaggio := 'Inserimento siac_r_ivamov.';
        insert into siac_r_ivamov
        (subdociva_id,
		 ivamov_id,
		 validita_inizio,
	     ente_proprietario_id,
		 login_operazione
         )
         values
         (
         migrAliquota.subdociva_id
         ,ivamovid
         , dataInizioVal::timestamp
         , enteproprietarioid
         , loginOperazione
         )
        returning subdocivamov_id into scartoId;

        if scartoId is null then
        	strMessaggio := strMessaggio||' Scarto per inserimento non riuscito.';
            INSERT INTO migr_docquo_spesa_iva_aliquota_scarto
            (migr_docquospesa_iva_aliquota_id,
             motivo_scarto,
             data_creazione,
             ente_proprietario_id
            )values(migrAliquota.migr_docquospesa_iva_aliquota_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);

			strMessaggio:=strMessaggio||' Cancellazione siac_t_ivamov.';
            delete from siac_t_ivamov where ivamov_id = ivamovid;
            continue;
        end if;

	   	strMessaggio:='Inserimento siac_r_migr_docquospesaivaaliq_t_ivamov per migr_docquospesa_iva_aliquota_id= '
                               ||migrAliquota.migr_docquospesa_iva_aliquota_id||'.';

        insert into siac_r_migr_docquospesaivaaliq_t_ivamov
        (migr_docquospesa_iva_aliquota_id,ivamov_id,ente_proprietario_id,data_creazione)
        values
        (migrAliquota.migr_docquospesa_iva_aliquota_id,ivamovid,enteProprietarioId,clock_timestamp());

        numeroRecordInseriti:=numeroRecordInseriti+1;

        update migr_docquo_spesa_iva_aliquota set fl_elab='S'
        where ente_proprietario_id=enteProprietarioId
        and   migr_docquospesa_iva_aliquota_id = migrAliquota.migr_docquospesa_iva_aliquota_id
        and   fl_elab='N';

    end loop;

    RAISE NOTICE 'numeroRecordInseriti %', numeroRecordInseriti;
    messaggioRisultato:=strMessaggioFinale||' Inserite '||numeroRecordInseriti||' aliquote iva.';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||quote_nullable(strMessaggio)||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
    when TOO_MANY_ROWS THEN
        raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||quote_nullable(strMessaggio)||' Diverse righe presenti in archivio.';
        numerorecordinseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||quote_nullable(strMessaggio)||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;