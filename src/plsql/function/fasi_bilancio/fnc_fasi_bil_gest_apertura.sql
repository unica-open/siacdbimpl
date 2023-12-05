/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 30.06.2016 Sofia -- apertura bilancio di gestione
-- la fnc opera in base a opzione di faseBilancio di arrivo richiesta (vedasi  commeno par faseBilancio)
-- la fnc opera in apertura al primo lancio
--                 aggiornamento dal secondo lancio
-- annoBilancio    ==> annoBilancio di gestione in fase di apertura
-- euElemTipo      ==> E entrata, U spesa
-- bilElemPrevTipo ==> tipo elemento di previsione da impostare in caso di apertura da previsione
-- bilElemGestTipo ==> tipo elemento di gestione da aprire
-- faseBilancio    ==> faseBilancio a cui passare
--   E ==> ESERCIZIO PROVVISORIO        - apertura gestione provvisoria da gestione eq. bilancio precendente
--   G ==> GESIONE ESERCIZIO DEFINITIVO - apertura gestione definitiva da bilancio di previsione eq. approvato
-- checkGest       ==> verifica esistenza e aggiornamento gestione corren
--   true  ==> il dato gestione corrente esistente viene aggiornato
--             al dato di gestione prec o di bilancio di previsione
--   false ==> il dato gestione corrente esistente non viene aggiornato e neanche controllato
-- impostaImporti  ==> gli importi del bilancio di gestione in fase di apertura vengono valorizzati o lasciati a zero
--   true  ==> vengono impostati uguali agli importi dellla gestione eq. precedente (annoBilancio+2=0)
--             vengono impostati uguali agli importi della previsione approvata
--   false ==> vengono impostati a zero

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura
(
  annobilancio           integer,
  euElemTipo             varchar,
  bilElemPrevTipo        varchar,
  bilElemGestTipo        varchar,
  faseBilancio           varchar,
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
    PROVVISORIO_FASE             CONSTANT varchar:='E';
    PROVVISORIO_DA_PREV_FASE     CONSTANT varchar:='EP';
    GESTIONE_FASE                CONSTANT varchar:='G';

    strRec record;
    importiRec record;

BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Apertura bilancio gestione per Anno bilancio='||annoBilancio::varchar||
                        '. Fase Bilancio di apertura='||faseBilancio||'.';

    -- se la fase di bilancio richiesta ==>  PROVVISORIO (E)
     -- si parte dal bilancio di gestione anno precedente
     -- si crea/aggiorna il nuovo bilancio di gestione provvisorio
    -- se la fase di bilancio richiesta ==>  PROVVISORIO (EP)
     -- si parte dal bilancio di previsione corrente
     -- si crea/aggiorna il nuovo bilancio di gestione provvisorio
    -- se la fase di bilancio richiesta ==> GESTIONE (G)
     -- significa che il bilancio di previsione approvato
     -- si parte dal bilancio di previsione
     -- si crea/aggiorna il nuovo bilancio di gestione defintivo
    if faseBilancio=PROVVISORIO_FASE then
    	strMessaggio:='Apertura bilancio gestione provvisorio - strutture.';
    	select * into strRec
        from fnc_fasi_bil_provv_apertura_struttura
		(annobilancio,
	     euElemTipo,
	     bilElemGestTipo,
	     checkGest,
	     enteproprietarioid,
	     loginoperazione,
	     dataelaborazione);
        if strRec.codiceRisultato=0 then
        	faseBilElabId:=strRec.faseBilElabIdRet;
            strMessaggio:='Apertura bilancio gestione provvisorio - importi.';
        	select * into importiRec
            from fnc_fasi_bil_provv_apertura_importi
			(annobilancio,
		     euElemTipo,
	         bilElemGestTipo,
			 checkGest,
			 impostaImporti,
  			 faseBilElabId,
		     enteproprietarioid,
		     loginoperazione,
		     dataelaborazione);
            if importiRec.codiceRisultato!=0 then
            	strMessaggio:=importiRec.messaggioRisultato;
                codiceRisultato:=importiRec.codiceRisultato;
            end if;
         else
           	strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;
    elseif faseBilancio=GESTIONE_FASE or faseBilancio=PROVVISORIO_DA_PREV_FASE then -- 13.10.2016 Sofia - aggiunto per gestiore ep da previsione
	    strMessaggio:='Apertura bilancio gestione definitivo - strutture.';
    	select * into strRec
        from fnc_fasi_bil_prev_approva_struttura
	    (annobilancio,
         faseBilancio, -- 13.10.2016 Sofia
		 euElemTipo,
	     bilElemPrevTipo,
		 bilElemGestTipo,
	     checkGest,
	     enteproprietarioid,
	     loginoperazione,
		 dataelaborazione);
         if strRec.codiceRisultato=0 then
         	faseBilElabId:=strRec.faseBilElabIdRet;
            strMessaggio:='Apertura bilancio gestione definitivo - importi.';
            select * into importiRec
            from fnc_fasi_bil_prev_approva_importi
		    (annobilancio,
		     euElemTipo,
			 bilElemPrevTipo,
		     bilElemGestTipo,
			 checkGest,
		     impostaImporti,
		     faseBilElabId,
		     enteproprietarioid,
			 loginoperazione,
			 dataelaborazione);
             if importiRec.codiceRisultato!=0 then
             	strMessaggio:=importiRec.messaggioRisultato;
                codiceRisultato:=importiRec.codiceRisultato;
             end if;
         else
	        strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;
    else raise exception  'Fase bilancio % non ammessa.',faseBilancio;
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