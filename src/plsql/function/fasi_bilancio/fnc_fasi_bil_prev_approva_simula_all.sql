/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 13.10.2016 Sofia  simulazione approvazione bilancio di previsione
-- stepPartenza --  step di partenza
--              --  1,99  STEP 1
--              --  >=2   STEP 2
-- STEP 1       -- capitoli di uscita
-- STEP 2       -- capitoli di entrata
CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_approva_simula_all
(
  annobilancio           integer,
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
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    faseBilElabId     integer:=null;

    strRec record;

    CAP_EP_STR          CONSTANT varchar:='CAP-EP';
    CAP_UP_STR          CONSTANT varchar:='CAP-UP';
    CAP_EG_STR          CONSTANT varchar:='CAP-EG';
    CAP_UG_STR          CONSTANT varchar:='CAP-UG';



BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Simulazione approvazione bilancio di previsione per Anno bilancio='||annoBilancio::varchar||
                        '.';

    if not (stepPartenza=99 or stepPartenza>=1) then
        strMessaggio:='Step ri-partenza non corretto valori ammessi >=1 99.';
        codiceRisultato:=-1;
    end if;

    -- STEP 1 - capitoli di uscita eseguiro per stepPartenza 1, 99
    if stepPartenza=1 or stepPartenza=99 then
 	 strMessaggio:='Capitolo di uscita.';
     select * into strRec
     from fnc_fasi_bil_prev_approva_simula
     (annobilancio,
      CAP_UP_STR,
      CAP_UG_STR,
      enteProprietarioId,
      loginOperazione
      );
     if strRec.codiceRisultato=0 then
      	faseBilElabId:=strRec.faseBilElabIdRet;
     else
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
     end if;
   end if;

   -- STEP 2 - capitoli di entrata eseguiro per stepPartenza >=2
   if codiceRisultato=0 and stepPartenza>=2 then
    	strMessaggio:='Capitolo di entrata.';
	    select * into strRec
    	from fnc_fasi_bil_prev_approva_simula_e
	    (annobilancio,
         CAP_EP_STR,
         CAP_EG_STR,
         enteProprietarioId,
         loginOperazione
        );
        if strRec.codiceRisultato=0 then
      		faseBilElabId:=strRec.faseBilElabIdRet;
	    else
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