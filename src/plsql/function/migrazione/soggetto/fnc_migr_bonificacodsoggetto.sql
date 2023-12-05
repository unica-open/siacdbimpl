/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace function fnc_migr_bonificacodsoggetto(
											 enteProprietarioId integer,
                                             loginOperazione varchar,
                                             out codiceRisultato integer,
                                             out messaggioRisultato varchar
                                           )
RETURNS record AS
$body$
DECLARE
 -- fnc_migr_bonificacodsoggetto  -- funzione richiamata da client penatho al termine della migrazione dei soggetti
 --	i delegati che sono stati inseriti come nuovi soggetti hanno un codice 'sporco' da bonificare. partendo dall'ultimo codice soggetto valido e incrementando per ogni codice da bonifiicare.
 -- effettua update del campo codice_soggetto sulla siac_t_soggetto
 -- richiama al termine dell'esecuzione la funzione fnc_aggiorna_progressivi.
 -- richiama al termine dell'esecuzione anche la funzione fnc_migr_bonifica_comuni, che elimina eventuali comuni inseriti dalla migrazione doppi per codice belfiore rispetto a quanto inserito da admin.

 KEY_PROGR CONSTANT varchar:='S';
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 codRet integer:=0;

 countBonSoggetti integer:=0;
 maxCodiceSoggetto integer:=0;
 numeroElementiBonificati integer:=0;

 bonSoggetti record;
 migrAggiornaProgr record;
 migrBonificaComuni record;

begin

	messaggioRisultato:='';
    codiceRisultato:=0;

	strMessaggioFinale:='Bonifica codice per soggetti migrati,ente  '||enteProprietarioId||'.';

    -- verifica della presenza di soggetti da bonificare
    strMessaggio:='count dei soggetti da bonificare ';
    begin
      select 1 into strict countBonSoggetti
       from siac_t_soggetto sogg
       where ente_proprietario_id = enteProprietarioId
       and soggetto_code like '%||D||%'
       order by sogg.soggetto_id limit 1;
	exception when no_data_found then
    	--messaggioRisultato := strMessaggioFinale || ' Nessun dato da bonificare';
        strMessaggioFinale := strMessaggioFinale || ' Nessun dato da bonificare.';
    	codRet := -12;
--        return;
	end;

	if codRet = 0 then
      strMessaggio:='Recupero max(soggetto_code).';

      select soggetto_code into strict maxCodiceSoggetto
      from siac_t_soggetto where ente_proprietario_id = enteProprietarioId
      and fnc_migr_isnumeric(soggetto_code)
      order by  fnc_migr_sortnum(soggetto_code) desc limit 1;

      strMessaggio:='Apertura cursore, inizio loop. ';
      for bonSoggetti in
      ( select sogg.*
       from siac_t_soggetto sogg
       where sogg.ente_proprietario_id = enteProprietarioId
          and sogg.soggetto_code like '%||D||%'
          order by sogg.soggetto_id
      )
      loop

          strMessaggio:='Bonifica per soggetto '||bonSoggetti.soggetto_id||', soggetto_code = '|| bonSoggetti.soggetto_code;
          maxCodiceSoggetto := maxCodiceSoggetto+1;
          update siac_t_soggetto set soggetto_code = maxCodiceSoggetto where soggetto_id = bonSoggetti.soggetto_id;
          numeroElementiBonificati:= numeroElementiBonificati+1;

      end loop;

      strMessaggio:='Aggiornamento progressivi per soggetto.';
      select *  into migrAggiornaProgr
      from fnc_aggiorna_progressivi(enteProprietarioId,KEY_PROGR,loginOperazione);
      if migrAggiornaProgr.codResult=-1 then
          RAISE EXCEPTION ' % ', migrAggiornaProgr.messaggioRisultato;
      end if;

      strMessaggioFinale := strMessaggioFinale || 'Numero soggetti bonificati: '||numeroElementiBonificati||'.';

    end if;

	strMessaggio:='Bonifica comuni doppi.';
    select * into migrBonificaComuni
    from fnc_migr_bonifica_comuni(enteProprietarioId);
    if migrBonificaComuni.codResult=-1 then
    	RAISE EXCEPTION ' % ', migrBonificaComuni.messaggioRisultato;
    end if;

    codiceRisultato := codRet;
    messaggioRisultato := strMessaggioFinale || migrBonificaComuni.messaggiorisultato;

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