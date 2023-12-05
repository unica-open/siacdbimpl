/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/



select fnc_siac_bko_inserisci_azione('OP-BKOF017-definisciVariazioneSenzaBonita', 'Variazioni - Backoffice definisci variazione senza Bonita', 
	'/../siacboapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE');
	
	
	
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_definisci_variazione(annobilancio integer, variazionenum integer, enteproprietarioid integer, loginoperazione character varying, dataelaborazione timestamp without time zone)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
  DECLARE
   strmessaggio       VARCHAR(1500):='';
   strmessaggiofinale VARCHAR(1500):='';
   codresult          INTEGER:=NULL;
   recResult record;

  messaggiorisultato text:=null;
  begin


    strMessaggioFinale:='Variazione bilancio - definizione.';
    raise notice 'strMessaggioFinale=%',strMessaggioFinale;

    raise notice 'annoBilancio=%', quote_nullable(annoBilancio::varchar);
    raise notice 'variazioneNum=%', quote_nullable(variazioneNum::varchar);

    if coalesce(annoBilancio::varchar,'0')='0'  or  coalesce(variazioneNum::varchar,'0')='0' then
    	strmessaggio:=' Anno bilancio o numero variazione non valorizzati. Impossibile determinare variazioni da trattare.';
        raise exception ' ';
    end if;

	codResult:=0;
    strMessaggio:='Esecuzione fnc_siac_bko_gestisci_variazione variazione_num='||variazioneNum::varchar||'.';
    raise notice 'strMessaggio=%',strMessaggio;

    select * into recResult
    from fnc_siac_bko_gestisci_variazione
    (
    enteProprietarioId,
    annoBilancio,
    variazioneNum,
    true,
    'D',
    true,
    loginOperazione,
    dataElaborazione
    );

    if recResult.codiceRisultato::integer=0 then
        strMessaggio:=strMessaggio||' Definizione effettuata.';
        codResult:=0;
    else
        strMessaggio:=strMessaggio||recResult.messaggioRisultato;
		codResult:=recResult.codiceRisultato::integer;
    end if;


    if codResult=0 then
		messaggioRisultato:=('0|'||strMessaggioFinale||strMessaggio)::text;
        
    else
	    messaggioRisultato:=('-1|'||strMessaggioFinale||strMessaggio)::text;
    end if;    
    
    raise notice 'messaggioRisultato=%',messaggioRisultato;



    RETURN messaggioRisultato;
  EXCEPTION
  WHEN raise_exception THEN

    messaggiorisultato:=(
    '-1'||
    strmessaggiofinale
    ||strmessaggio
    ||'ERRORE :'
    ||' '
    ||substring(upper(SQLERRM) FROM 1 FOR 1500))::text ;
    raise notice 'messaggiorisultato=%',messaggiorisultato;
    RETURN messaggioRisultato;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=
    ('-1'||
     strmessaggiofinale
     ||strmessaggio
     ||'Nessun elemento trovato.' )::text ;
    raise notice 'messaggiorisultato=%',messaggiorisultato;

    RETURN messaggiorisultato;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=
    ('-1'||
    strmessaggiofinale
    ||strmessaggio
    ||'Errore DB '
    ||SQLSTATE
    ||' '
    ||substring(upper(SQLERRM) FROM 1 FOR 1500))::text ;
    raise notice 'messaggiorisultato=%',messaggiorisultato;

    RETURN messaggioRisultato;
  END;
  $function$
;
