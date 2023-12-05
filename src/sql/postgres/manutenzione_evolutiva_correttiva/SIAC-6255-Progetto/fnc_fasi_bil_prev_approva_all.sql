/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿--- ESEGUE
--- STEP 1 -- CAP-UP
--  STEP 2 -- CAP-EP
--  valire stepPartenza ammessi 99, >=2
--- stepPartenza -- 99  tutti e due gli step
---              -- >=2 entrata
--- faseBilancio=G --> in gestione definitiva
CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_approva_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,




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

	codResult         integer:=null;
    faseBilElabId     integer:=null;

    prevAggImpRec record;
    prevCapRec record;
    strRec record;

    CAP_EP_STR          CONSTANT varchar:='CAP-EP';
    CAP_UP_STR          CONSTANT varchar:='CAP-UP';
    CAP_EG_STR          CONSTANT varchar:='CAP-EG';
    CAP_UG_STR          CONSTANT varchar:='CAP-UG';

    U_STR               CONSTANT varchar:='U';
    E_STR               CONSTANT varchar:='E';

    GESTIONE_FASE               CONSTANT varchar:='G';

BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;

	strMessaggioFinale:='Approvazione bilancio di previsione per Anno bilancio='||annoBilancio::varchar||'.';

    if not (stepPartenza=99 or stepPartenza>=2) then
        strMessaggio:='Step ri-partenza non corretto valori ammessi >=2 99.';
        codiceRisultato:=-1;
    end if;

    if faseBilancio is null or faseBilancio!=GESTIONE_FASE then
    	raise exception 'Fase Bilancio da indicare %.',GESTIONE_FASE;
    end if;
    -- STEP 1 -- CAPITOLI USCITA
    -- ESEGUITO SOLO SE ESEGUITI TUTTI
    if codiceRisultato=0 and stepPartenza=99 then
  	 strMessaggio:='Capitoli uscita.';

     select * into prevCapRec
     from fnc_fasi_bil_prev_approva
	 (annobilancio,
      U_STR,
      CAP_UP_STR,
      CAP_UG_STR,
      faseBilancio,
      true,--checkGest
      true,--impostaImporti
	  enteProprietarioId,
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
        from fnc_fasi_bil_prev_approva
		(annobilancio,
		 E_STR,
		 CAP_EP_STR,
		 CAP_EG_STR,
         faseBilancio,
		 true,--checkGest
         true,--impostaImporti
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


    -- STEP 3 -- popolamento dei vincoli di gestione da previsione
    if codiceRisultato=0 and stepPartenza>=2 then
	    select * into strRec
        from fnc_fasi_bil_gest_ribaltamento_vincoli
        ('PREV-GEST',
         annoBilancio,
         enteProprietarioid,
         loginOperazione,
         dataElaborazione );

         if strRec.codiceRisultato=0 then
            faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;
    end if;


	-- STEP 5 -- popolamento dei programmi-cronoprogrammi di gestione
	if codiceRisultato=0 and stepPartenza>=2 then    -- deve essere stato eseguito sia spesa che entrata
    	strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di gestione da previsione corrente.';
       	select * into strRec
       	from fnc_fasi_bil_gest_apertura_programmi
             (
			  annoBilancio,
			  enteProprietarioId,
			  'G',
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