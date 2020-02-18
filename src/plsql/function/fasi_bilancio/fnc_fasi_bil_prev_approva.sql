/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_approva
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

    strRec record;
    importiRec record;

BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Aprovazione bilancio di previsione per Anno bilancio='||annoBilancio::varchar||'.';

	strMessaggio:='Strutture.';
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
        strMessaggio:='Importi.';
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