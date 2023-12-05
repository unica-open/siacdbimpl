/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_mod_accredito (  enteProprietarioId integer,
		  											    loginOperazione    varchar,
 													    dataElaborazione timestamp,
                                                        annoBilancio varchar,
													    out codiceRisultato integer,
													    out messaggioRisultato varchar
												       )
RETURNS record AS
$body$
DECLARE


 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 migrModAccredito record;
 accreditoTipoId integer :=0;

 migrComune record;

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

begin
  -- fnc_migr_mod_accredito -- function che effettua il caricamento dei tipi di accredito ( leggendo da migr_mod_accredito )
  -- effettua inserimento di
  -- siac_d_accredito_tipo
  -- siac_r_migr_mod_accredito_accredito -- per tracciare il legame tra
   --  migr_mod_accredito.migr_accredito_id -- siac_d_accredito_tipo.accredito_tipo_id
   -- detto legame e creato anche per i tipi accredito gia esistenti per creare decodifica tra i dati del sistema di origine e quello nuovo
  -- la fnc restituisce
  -- messaggioRisultato = risulato elaborazine in formato testo
  -- codiceRisultato    = codice risultato elaborazione 0 ( elaborazione OK ) -1 (errore)
	messaggioRisultato:='';
    codiceRisultato:=0;

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Gestione inserimento siac_d_accredito_tipo per ente '||enteProprietarioId||'.';

    strMessaggio:='Letttura modAccredito  in migr_mod_accredito.';
    for migrModAccredito in
    ( select migrRecAccredito.*
     from migr_mod_accredito migrRecAccredito
     where migrRecAccredito.ente_proprietario_id=enteProprietarioId
     and fl_elab = 'N'
     order by migrRecAccredito.accredito_id
    )
    loop
    	accreditoTipoId:=0;

		begin
         strMessaggio:='Verifica esistenza siac_d_accredito_tipo.';
		 select coalesce(accreTipo.accredito_tipo_id,0) into strict accreditoTipoId
         from siac_d_accredito_tipo accreTipo
         where accreTipo.accredito_tipo_code=migrModAccredito.codice and
               accreTipo.ente_proprietario_id=enteProprietarioId and
               accreTipo.data_cancellazione is null and
           	   date_trunc('day',dataElaborazione)>=date_trunc('day',accreTipo.validita_inizio) and
		 	   (date_trunc('day',dataElaborazione)<=date_trunc('day',accreTipo.validita_fine)
		             or accreTipo.validita_fine is null);
         exception
         	when no_data_found then
            	null;
            when others  THEN
              RAISE EXCEPTION 'Errore per accredito codice  % : %-%.', migrModAccredito.codice,SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
        end;


        if accreditoTipoId=0 then
			-- siac_d_accredito_tipo
    	    strMessaggio:='Inserimento siac_d_accredito_tipo accredito_id= '||migrModAccredito.accredito_id||
		                       '(in migr_mod_accredito).';

			insert into siac_d_accredito_tipo
    	    (accredito_tipo_code, accredito_tipo_desc,accredito_priorita, validita_inizio,
			 ente_proprietario_id,data_creazione,  login_operazione,accredito_gruppo_id
		    )
	 		(select migrModAccredito.codice,migrModAccredito.descri,migrModAccredito.priorita,dataInizioVal,
        		    enteProprietarioId,clock_timestamp(),loginOperazione,accreGruppo.accredito_gruppo_id
	         from siac_d_accredito_gruppo accreGruppo
    	     where accreGruppo.accredito_gruppo_code=migrModAccredito.tipo_accredito and
               accreGruppo.ente_proprietario_id=enteProprietarioId and
               accreGruppo.data_cancellazione is null and
           	   date_trunc('day',dataElaborazione)>=date_trunc('day',accreGruppo.validita_inizio) and
		 	   (date_trunc('day',dataElaborazione)<date_trunc('day',accreGruppo.validita_fine)
		             or accreGruppo.validita_fine is null)
			)
	        returning accredito_tipo_id into accreditoTipoId;
		end if;

         strMessaggio:='Inserimento siac_r_migr_mod_accredito_accredito accredito_id= '||migrModAccredito.accredito_id||
		                       '(in migr_mod_accredito).';
			INSERT INTO siac_r_migr_mod_accredito_accredito
			( migr_accredito_id, accredito_tipo_id, data_creazione, ente_proprietario_id)
			VALUES
            (migrModAccredito.migr_accredito_id,accreditoTipoId,CURRENT_TIMESTAMP,enteProprietarioId);
    end loop;

	update migr_mod_accredito set fl_elab = 'S'
     where ente_proprietario_id=enteProprietarioId
     and fl_elab = 'N';

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