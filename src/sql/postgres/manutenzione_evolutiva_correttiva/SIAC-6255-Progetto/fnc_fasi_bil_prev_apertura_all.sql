/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- ESEGUE
--- STEP 1 -- CAP-UP
--  STEP 2 -- CAP-EP
--  STEP 3 -- diCuiImpegnato e datiAnnoPrec
--  valire stepPartenza ammessi 99, >=2
--- stepPartenza -- 99 tutti e tre gli step
---              -- >=2 da entrata alla fine
CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_apertura_all
(
  annobilancio           integer,
  checkPrev              boolean,
  impostaImporti         boolean,
  stepPartenza           integer,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio 		VARCHAR(1500):='';
	strMessaggioFinale 	VARCHAR(1500):='';

	codResult         	integer:=null;
    faseBilElabId     	integer:=null;

    prevAggImpRec 		record;
    prevCapRec 			record;
    prevRibVincoli		record;

	strRec 				record;
    CAP_EP_STR          CONSTANT varchar:='CAP-EP';
    CAP_UP_STR          CONSTANT varchar:='CAP-UP';
    CAP_EG_STR          CONSTANT varchar:='CAP-EG';
    CAP_UG_STR          CONSTANT varchar:='CAP-UG';

    U_STR               CONSTANT varchar:='U';
    E_STR               CONSTANT varchar:='E';

BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;

	strMessaggioFinale:='Apertura bilancio di previsione per Anno bilancio='||annoBilancio::varchar||'.';

    if not (stepPartenza=99 or stepPartenza>=2) then
        strMessaggio:='Step ri-partenza non corretto valori ammessi >=2 99.';
        codiceRisultato:=-1;
    end if;

    -- STEP 1 -- CAPITOLI USCITA
    -- ESEGUITO SOLO SE ESEGUITI TUTTI
    if codiceRisultato=0 and stepPartenza=99 then
  	 strMessaggio:='Capitoli uscita.';

     select * into prevCapRec
     from fnc_fasi_bil_prev_apertura
     (
      annobilancio,
      U_STR,
      CAP_UP_STR,
      CAP_UG_STR,
      true,       -- checkPrev,
      true,       -- impostaImporti,
      enteproprietarioid,
      loginoperazione,
      dataelaborazione
     );

     if prevCapRec.codiceRisultato=0 then
    	faseBilElabId:=prevCapRec.faseBilElabIdRet;
     else
        strMessaggio:=prevCapRec.messaggioRisultato;
        codiceRisultato:=prevCapRec.codiceRisultato;
     end if;
    end if;

    -- STEP 2 -- CAPITOLI DI ENTRATA
    -- STEP DI RIPARTENZA
    if codiceRisultato=0  and stepPartenza>=2 then
		strMessaggio:='Capitoli entrata.';
        select * into prevCapRec
        from fnc_fasi_bil_prev_apertura
		(annobilancio,
		 E_STR,
		 CAP_EP_STR,
		 CAP_EG_STR,
		 true,       ---checkPrev,
		 true,       ---impostaImporti,
		 enteproprietarioid,
		 loginoperazione,
 	     dataelaborazione);
        if prevCapRec.codiceRisultato=0 then
    		faseBilElabId:=prevCapRec.faseBilElabIdRet;
        else
	        strMessaggio:=prevCapRec.messaggioRisultato;
    	    codiceRisultato:=prevCapRec.codiceRisultato;
        end if;
    end if;

	-- STEP 3 -- popolamento dei vincoli di previsione

	if codiceRisultato=0 and stepPartenza>=2 then    -- deve essere stato eseguito sia spesa che entrata
		strMessaggio:='vincoli entrata.';
        select * into prevRibVincoli
		from fnc_fasi_bil_prev_ribaltamento_vincoli (annoBilancio,enteProprietarioId,loginOperazione,dataElaborazione);

		if prevRibVincoli.codiceRisultato=0 then
            -- 05.12.2017 Sofia JIRA  SIAC-5630
    		-- faseBilElabId:=prevRibVincoli.faseBilElabIdRet;
        else
	        strMessaggio:=prevRibVincoli.messaggioRisultato;
    	    codiceRisultato:=prevRibVincoli.codiceRisultato;
        end if;
	end if;

    -- STEP 4 -- popolamento diCuiImpegnato e dati anno prec
    -- rieseguito ogni volta che si richiede esecuzione
    -- spesa-entrata o solo entrata
	if codiceRisultato=0 and stepPartenza>=1 then
		strMessaggio:='Capitoli previsione aggiorna importi e dati prec.';

        select *  into prevAggImpRec
        from  fnc_fasi_bil_aggiorna_importi_bilprev
        (annobilancio,
		 true,   --flagaggimpo boolean,
         true,   --flagdicuiimpe boolean,
	     faseBilElabId,
	     enteProprietarioId,
	     loginOperazione,
	     dataElaborazione
         );

        if prevAggImpRec.codiceRisultato!=0 then
        	strMessaggio:=prevAggImpRec.messaggioRisultato;
            codiceRisultato:=prevAggImpRec.codiceRisultato;
        end if;
    end if;

    -- STEP 5 -- popolamento dei programmi-cronoprogrammi di previsione
	if codiceRisultato=0 and stepPartenza>=2 then    -- deve essere stato eseguito sia spesa che entrata
    	strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di previsione da gestione precedente.';
       	select * into strRec
       	from fnc_fasi_bil_gest_apertura_programmi
             (
			  annoBilancio,
			  enteProprietarioId,
			  'P',
			  loginOperazione,
			  dataElaborazione
             );
       if strRec.codiceRisultato!=0 then
       	strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
       end if;
    end if;

    if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
        faseBilElabIdRet:=faseBilElabId;
    else messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;