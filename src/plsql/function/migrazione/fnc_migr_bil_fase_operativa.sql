/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_bil_fase_operativa (
  enteproprietarioid integer,
  annobilancio varchar,
  fasebilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
 migrBilancioId record;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 bilFaseId integer:=0;
 faseOpId integer:=0;

-- FASE_PREV  CONSTANT VARCHAR:='P';
-- FASE_PROVV  CONSTANT VARCHAR:='E';
-- FASE_GEST  CONSTANT VARCHAR:='G';

BEGIN

    codiceRisultato:=0;
    messaggioRisultato:='';

	strMessaggioFinale:='Migrazione capitoli in faseBilancio='||faseBilancio||' per anno bilancio '||annoBilancio||'.Gestione fase operativa.';

    strMessaggio:='Lettura bilancioId.';
	select *  into migrBilancioId
    from fnc_get_bilancio     (enteProprietarioId,annoBilancio);
    if migrBilancioId.idBilancio=-1 then
    	RAISE EXCEPTION ' % ', migrBilancioId.messaggioRisultato;
    end if;

	begin
    	strMessaggio:='Lettura identificativo fase bilancio.';
    	select faseOp.fase_operativa_id into strict faseOpId
        from siac_d_fase_operativa faseOp
        where faseOp.ente_proprietario_id=enteProprietarioId and
        	  faseOp.fase_operativa_code=faseBilancio and
              faseOp.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',faseOp.validita_inizio) and
	          date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(faseOp.validita_fine,statement_timestamp()));

	   exception
    	 when NO_DATA_FOUND THEN
         	RAISE EXCEPTION 'Non esistente';
         when others then
	        RAISE EXCEPTION ' % ','ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500);

    end;

    begin
     strMessaggio:='Lettura fase operativa per bilancioId='||migrBilancioId.idBilancio||'.';
  	 select bilFase.bil_fase_operativa_id  into strict bilFaseId
     from  siac_r_bil_fase_operativa bilFase
     where    bilFase.bil_id = migrBilancioId.idBilancio and
		      bilFase.data_cancellazione is null and
              bilfase.validita_fine is null;
           --   date_trunc('day',dataElaborazione)>=date_trunc('day',bilFase.validita_inizio) and
	       --   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(bilFase.validita_fine,statement_timestamp()));
--- 06.02.2015 Sofia Vitelli richiede di non caricare la nuova fase se ne esiste gia una
---              bilFase.fase_operativa_id=faseOpId;


 -- 	 select bilFase.bil_fase_operativa_id  into strict bilFaseId
--     from siac_t_bil bil, siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
--     where bil.bil_id=migrBilancioId.idBilancio and
--              bil.ente_proprietario_id=enteProprietarioId and
--              bilFase.bil_id = bil.bil_id and
--              bilFase.ente_proprietario_id=bil.ente_proprietario_id and
--              bilFase.fase_operativa_id=faseOp.fase_operativa_id and
--              faseOp.ente_proprietario_id=bilFase.ente_proprietario_id and
--              faseOp.fase_operativa_code=faseBilancio and
--              faseOp.data_cancellazione is null and
--              date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',faseOp.validita_inizio) and
--	          (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',faseOp.validita_fine)
--    	            or faseOp.validita_fine is null);


     messaggioRisultato:=strMessaggioFinale||'Fase operativa per bilancioId='||migrBilancioId.idBilancio||'.Presente in archivio.';
   exception
     when NO_DATA_FOUND THEN
         	-- inserimento fase operativa bilancio di previsione
            strMessaggio:='Inserimento fase operativa bilancio per bilancioId='||migrBilancioId.idBilancio||'.';
            INSERT INTO siac_r_bil_fase_operativa
		    (bil_id,fase_operativa_id,validita_inizio,ente_proprietario_id,
	         data_creazione, login_operazione
            )
            values
            (migrBilancioId.idBilancio,faseOpId,statement_timestamp(),
             enteProprietarioId,statement_timestamp(),loginOperazione);

--            (select migrBilancioId.idBilancio,faseBilancioOp.fase_operativa_id,statement_timestamp(),
--                    faseBilancioOp.ente_proprietario_id,statement_timestamp(),loginOperazione
--             from siac_d_fase_operativa faseBilancioOp
--             where faseBilancioOp.fase_operativa_code=faseBilancio and
--                   faseBilancioOp.ente_proprietario_id= enteProprietarioId and
--                   faseBilancioOp.data_cancellazione is null and
--                   date_trunc('day',dataElaborazione)>=date_trunc('day',faseBilancioOp.validita_inizio) and
--	               date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(faseBilancioOp.validita_fine,statement_timestamp()));

            messaggioRisultato:=strMessaggioFinale||'Fase operativa per bilancioId='||migrBilancioId.idBilancio||'.Inserita in archivio.';

     when TOO_MANY_ROWS THEN
         RAISE EXCEPTION ' % ','Impossibile identificare fase, troppi valori per ente '||enteProprietarioId||' fase '||faseBilancio||'.';
     when others  THEN
         RAISE EXCEPTION ' % ','ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500);
    end;

exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 800) ;
        codiceRisultato:=-1;
        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;