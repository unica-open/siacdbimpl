/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_modpag (
  soggettoid integer,
  siacsoggettoid integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  annobilancio varchar,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
 -- fnc_migr_modpag  -- function che effettua il caricamento delle MDP del soggetto ( leggendo da migr_modpag )
  --                                 per il  siacSoggettoId passato in input
  --                                 il soggetto deve essere presente in siac_t_soggetto con soggetto_id=siacSoggettoId
  --                                 soggettoId=migr_modpag.soggetto_id = migr_soggetto.soggetto_id per ente
 -- effettua inserimento di
  -- siac_t_modpag -- per i dati relativi alla MDP (siac_r_modpag_stato)
  --                  il soggetto cui riferisce la MDP puo'' essere il soggetto principale
  --                  o eventualmente la sede secondaria (se migr_modpag.secondaria='S' )
  --                  in tal caso viene ricavato soggetto_id della sede secondaria
  --                  sono esclude le MDP con cessione=CSI , non sono oggetto di inserimento come MDP
  -- siac_t_recapito_soggetto -- inserisce il recapito email eventualmente presente sulla MDP
  --                             come recapito email/PEC del soggetto principale, avviso='S' (RegP)
  -- siac_r_migr_modpag_modpag -- per tracciare il legame tra
  --  migr_modpag.migr_modpag_id -- siac_t_modpag.modpag_id
 -- la fnc restituisce
  -- messaggioRisultato = risulato elaborazine in formato testo
  -- codiceRisultato    = codice risultato elaborazione 0 ( elaborazione OK ) -1 (errore) -12 ( dati non presenti in migr_modpag)

 SEPARATORE			CONSTANT  varchar :='||';

 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 countMigrMDP integer:=0;
 migrMDP record;

 modpagId  integer:=0;
 soggettoMDPId integer :=0;
 accreditoTipoId integer:=0;


 emailSoggetto varchar(1000):='';
 tipoEmail varchar(1000):='';

 dataNascitaQuietDel timestamp;

 RELAZIONE_CSC    CONSTANT varchar:='CSC';
 RELAZIONE_CSI    CONSTANT varchar:='CSI';

 NVL_STR CONSTANT varchar:='';

--     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
--dataInizioVal timestamp :=annoBilancio||'-01-01';
dataInizioVal timestamp :=null;

ordineMdp integer :=0;
-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
nrecapiti integer:=0;
-- DAVIDE - 21.09.015 : fine

-- DAVIDE - 11.02.016 - non passare il conto corrente in presenza di IBAN SEPA
contapaese integer:=0;
-- DAVIDE - 11.02.016 - fine

begin

	messaggioRisultato:='';
    codiceRisultato:=0;

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Gestione inserimento MDP soggetto per soggetto_id '||soggettoId||' in migr_soggetto.';

	strMessaggio:='Verifica esistenza MDP per il soggetto indicato.';

    -- in caso di cessione=CSI la MDP non viene creata
    -- verra poi creata la relazione con la gestione della tabella migr_relaz_soggetti
    -- per questo queste MDP non vengono trattate
	select COALESCE(count(*),0) into countMigrMDP
    from migr_modpag ms
    where ms.soggetto_id=soggettoId and
          ms.ente_proprietario_id=enteProprietarioId and
          coalesce(ms.cessione,NVL_STR)!=RELAZIONE_CSI and
          ms.fl_elab='N';
	--raise notice 'NUMERO MDP %',countMigrMDP;


	if COALESCE(countMigrMDP,0)=0 then
    	 messaggioRisultato:=strMessaggioFinale||'Nessuna MDP presente per il soggetto indicato.';
         codiceRisultato:=-12;
         return;
    end if;

   -- migr_indirizzo_id
   -- modpag_id
   -- soggetto_id
   -- sede_id
   -- codice_modpag
   -- cessione
   -- sede_secondaria
   -- codice_accredito
   -- iban
   -- bic
   -- abi
   -- cab
   -- conto_corrente
   -- quietanzante
   -- codice_fiscale_quiet
   -- stato_modpag
   -- note
   -- email

    strMessaggio:='Lettura dell''ordine siac_r_modpag_ordine per il soggetto '||siacSoggettoId||'.';

	begin
      select ordine into strict ordineMdp
      from siac_r_modpag_ordine
      where soggetto_id = siacSoggettoId
      order by ordine desc limit 1;
	exception when no_data_found then
    	ordineMdp := 0;
	end;

    strMessaggio:='Lettura MDP per il soggetto in migr_modpag.';

    for migrMDP in
    ( select migrModPag.*
     from migr_modpag migrModPag
     where migrModPag.soggetto_id=soggettoId  and
           migrModPag.ente_proprietario_id=enteProprietarioId and
           coalesce(migrModPag.cessione,NVL_STR)!=RELAZIONE_CSI and
           migrModPag.fl_elab='N'
     order by migrModPag.modpag_id
    )
    loop
		--- se sede_secondaria='S' ricerco la sede in migr_sede per ricavare il soggetto_id della sede creata
        --- poiche la MDP va creata rispetto alla sede e non al soggetto principale
		if migrMDP.sede_secondaria='S' then
        	-- leggo migr_sed_id in migr_sede_secondaria  x sede_id
            -- quindi soggetto_relaz_id da siac_r_migr_sede_secondaria_rel_sede x migr_sede_id
            -- quindi soggetto_id_a da siac_r_soggetto_relaz x soggetto_relaz_id
            strMessaggio:='MDP legata a sede secondaria - lettura del soggetto relativo alla sede soggettoId '||soggettoId
                          ||'(in migr_soggetto_id) per modpag_id '||migrMDP.modpag_id||'.';

            select coalesce(soggettoRelaz.soggetto_id_a,0) into soggettoMDPId
            from siac_r_migr_sede_secondaria_rel_sede migrRelSede, siac_r_soggetto_relaz soggettoRelaz, migr_sede_secondaria migrSedeSec
            where coalesce(migrSedeSec.sede_id,0)=migrMDP.sede_id and
                  migrSedeSec.ente_proprietario_id=enteProprietarioId and
                  migrRelSede.migr_sede_id=migrSedeSec.migr_sede_id and
                  migrRelSede.ente_proprietario_id=enteProprietarioId and
                  soggettoRelaz.soggetto_relaz_id=migrRelSede.soggetto_relaz_id and
                  soggettoRelaz.ente_proprietario_id=enteProprietarioId;
		 else
            -- in questo caso il soggetto della MDP coincide con il soggetto principale passato in input
         	soggettoMDPId:=siacSoggettoId;
         end if;

		--raise notice 'QUI QUI';
		strMessaggio:='Lettura accredito_tipo codice='||migrMDP.codice_accredito||' siac_t_modpag  soggetto_id= '||soggettoId
                      ||'(in migr_soggetto_id) per modpag_id '||migrMDP.modpag_id||'.';
	--	raise notice 'QUI QUI2';

		accreditoTipoId:=null;
	       begin
                select accreTipo.accredito_tipo_id into strict accreditoTipoId
                from siac_r_migr_mod_accredito_accredito migrAccreditoRel, migr_mod_accredito migrAccredito,
                     siac_d_accredito_tipo accreTipo
                where migrAccredito.codice=migrMDP.codice_accredito and
                      migrAccredito.ente_proprietario_id=enteProprietarioId and
                      migrAccreditoRel.migr_accredito_id=migrAccredito.migr_accredito_id and
                      migrAccreditoRel.ente_proprietario_id=enteProprietarioId and
                      accreTipo.accredito_tipo_id=migrAccreditoRel.accredito_tipo_id and
                      accreTipo.ente_proprietario_id=enteProprietarioId;-- and
                      --accreTipo.data_cancellazione is null and
                      --date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',accreTipo.validita_inizio) and
			   --(date_trunc('seconds',dataElaborazione)<date_trunc('seconds',accreTipo.validita_fine)
			     --         or accreTipo.validita_fine is null);

		exception
                 when no_data_found then
        	        RAISE EXCEPTION 'ERRORE COD ACCREDITO NON TROVATO accreditoTipoId=%',accreditoTipoId;
    	         when others then
	    	         RAISE EXCEPTION 'ERRORE : %-% ', SQLSTATE,	substring(upper(SQLERRM) from 1 for 300);

		end;

	--	raise notice 'QUI QUI2 accreditoTIpoId= %',accreditoTipoId;



		strMessaggio:='Inserimento siac_t_modpag  soggetto_id= '||soggettoId
                      ||'(in migr_soggetto_id) per modpag_id '||migrMDP.modpag_id||' accreditoTipoId='||accreditoTipoId||'.';


       if coalesce(migrMDP.data_nascita_qdel,NVL_STR)!=NVL_STR then
	        dataNascitaQuietDel:=date_trunc('day', migrMDP.data_nascita_qdel::timestamp );
       else dataNascitaQuietDel:=null;
       end if;

	   -- DAVIDE - 11.02.016 - non passare il conto corrente in presenza di IBAN SEPA
       -- Controllare che i primi 2 crt del codice iban siano di un paese dell'area SEPA
	   -- se IBAN SEPA, concatena il conto corrente nelle note e mettilo a NULL, altrimenti
	   -- migra il tutto come adesso.

/*	   if (migrMDP.iban is not null) and (length(migrMDP.iban))>2 and
          (migrMDP.conto_corrente is not null) then 18.02.2016 Sofia */
       if coalesce(migrMDP.iban,NVL_STR)!=NVL_STR and length(migrMDP.iban)>2 and
          coalesce(migrMDP.conto_corrente,NVL_STR)!=NVL_STR then
--		  begin 18.02.2016 Sofia

		      contapaese := null;
		      select 1 into contapaese
	          from siac_t_sepa sepa
	          where sepa.ente_proprietario_id=enteProprietarioId and
		            sepa.sepa_iso_code = upper(substring(migrMDP.iban from 1 for 2))
              order by sepa.sepa_id
              limit 1;

--			  if contapaese > 0 then 18.02.2016 Sofia
   			  if contapaese is not null then
--              	  migrMDP.note := migrMDP.note || ' - CC numero : ' || migrMDP.conto_corrente;
                  if coalesce(migrMDP.note,NVL_STR)!=NVL_STR then
				      	migrMDP.note := migrMDP.note || ' - CC ' || migrMDP.conto_corrente;
                  else  migrMDP.note := 'CC ' || migrMDP.conto_corrente;
                  end if;
			      migrMDP.conto_corrente := null;
			  end if;
/*		  exception  18.02.2016 Sofia
		      when others null;
		  end;*/
	   end if;
       -- DAVIDE - 11.02.016 - fine


	    -- siac_t_modpag
		insert into siac_t_modpag
        (soggetto_id,accredito_tipo_id,
         quietanziante,quietanziante_codice_fiscale,
         quietanzante_nascita_data,quietanziante_nascita_luogo,quietanziante_nascita_stato,
		 bic, contocorrente,contocorrente_intestazione, iban, note, validita_inizio, ente_proprietario_id, data_creazione,
		 login_operazione, login_creazione)
        values
        (soggettoMDPId,accreditoTipoId,
         migrMDP.quietanzante,migrMDP.codice_fiscale_quiet,
         dataNascitaQuietDel,migrMDP.luogo_nascita_qdel,migrMDP.stato_nascita_qdel,
         migrMDP.bic,migrMDP.conto_corrente,migrMDP.conto_corrente_intest,migrMDP.iban,migrMDP.note,dataInizioVal,
         enteProprietarioId,clock_timestamp(),loginOperazione,loginOperazione
         ) returning modpag_id into modpagId;

         strMessaggio:='Inserimento siac_r_modpag_stato  soggetto_id= '||soggettoId
                      ||'(in migr_soggetto_id) per modpag_id '||migrMDP.modpag_id||'.';
        -- siac_r_modpag_stato
        insert into siac_r_modpag_stato
        ( modpag_id, modpag_stato_id, validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
        (select modpagId, MDPStato.modpag_stato_id,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
         from siac_d_modpag_stato MDPStato
         where MDPStato.modpag_stato_code=migrMDP.stato_modpag and
               MDPStato.ente_proprietario_id=enteProprietarioId and
               MDPStato.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',MDPStato.validita_inizio) and
			   (date_trunc('day',dataElaborazione)<=date_trunc('day',MDPStato.validita_fine)
			              or MDPStato.validita_fine is null)
        );

        strMessaggio:='Inserimento siac_r_modpag_ordine  soggetto_id= '||soggettoId
                      ||'(in migr_soggetto_id) per modpag_id '||migrMDP.modpag_id||'.';
        -- siac_r_modpag_ordine
        ordineMdp := ordineMdp + 1;
		/*insert into siac_r_modpag_ordine
		(soggetto_id,modpag_id,ordine,validita_inizio,ente_proprietario_id,
	     data_creazione, login_operazione, login_creazione)
        values
        (soggettoMDPId,modpagId,ordineMdp,dataElaborazione,
         enteProprietarioId,clock_timestamp(),loginOperazione,loginOperazione);*/
         -- 05.10.2015 Sofia - sostituito soggetto_id=soggetto_id di riferimento anziche soggettoMDPId che potrebbe essere quello della sedeSec
         insert into siac_r_modpag_ordine
		(soggetto_id,modpag_id,ordine,validita_inizio,ente_proprietario_id,
	     data_creazione, login_operazione, login_creazione)
        values
        (siacSoggettoId,modpagId,ordineMdp,dataElaborazione,
         enteProprietarioId,clock_timestamp(),loginOperazione,loginOperazione);

		 strMessaggio:='Inserimento siac_t_recapito_soggetto soggetto_id= '||soggettoId||
				       '(in migr_soggetto_id) modpag_id='||migrMDP.modpag_id||' email.';
        -- siac_t_recapito_soggetto
        -- email
        if coalesce( migrMDP.email,NVL_STR)!=NVL_STR then
                tipoEmail:=substring(migrMDP.email from 1 for position(SEPARATORE in migrMDP.email)-1);
                emailSoggetto:=substring(migrMDP.email from
					                 position(SEPARATORE in migrMDP.email)+2
				                     for char_length(migrMDP.email)-position(SEPARATORE in migrMDP.email));
	-- DAVIDE - 21.09.015 : controllo sui recapiti per evitare inserimenti doppi
			    nrecapiti := 0;
			    select count(*)
				into nrecapiti
				from siac_t_recapito_soggetto reca
				where reca.ente_proprietario_id=enteProprietarioId and
				      reca.soggetto_id=soggettoMDPId and
					  reca.recapito_code=tipoEmail and
					  reca.recapito_desc=emailSoggetto;

				if nrecapiti = 0 then

	       		    insert into siac_t_recapito_soggetto
    	            (soggetto_id, recapito_code, recapito_desc, validita_inizio,ente_proprietario_id,
		    	     data_creazione, login_operazione, recapito_modo_id, avviso
				    )
			        (
    	             select soggettoMDPId,recapitoModo.recapito_modo_code,emailSoggetto,dataInizioVal,enteProprietarioId,clock_timestamp(),
        	                loginOperazione,recapitoModo.recapito_modo_id,'S'
            	       from siac_d_recapito_modo recapitoModo
	                  where recapitoModo.recapito_modo_code=tipoEmail and
    	                    recapitoModo.ente_proprietario_id=enteProprietarioId and
        	                recapitoModo.data_cancellazione is null and
            	  	        date_trunc('day',dataElaborazione)>=date_trunc('day',recapitoModo.validita_inizio) and
			  		        (date_trunc('day',dataElaborazione)<=date_trunc('day',recapitoModo.validita_fine)
		            	     or recapitoModo.validita_fine is null)
				    );
                end if;
	-- DAVIDE - 21.09.015 : fine
         end if;


		strMessaggio='Inserimento  siac_r_migr_modpag_modpag soggetto_id= '||soggettoId||
				       '(in migr_soggetto_id) modpag_id='||migrMDP.modpag_id;

        insert into siac_r_migr_modpag_modpag
        (migr_modpag_id, modpag_id,ente_proprietario_id,data_creazione)
        values
        (migrMDP.migr_modpag_id,modpagId,enteProprietarioId,clock_timestamp());

    end loop;

    codiceRisultato:= codRet;
    messaggioRisultato:=strMessaggioFinale||'Elaborazione OK.';

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :  '||' '||substring(upper(SQLERRM) from 1 for 800) ;
        codiceRisultato:=-1;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 800) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;