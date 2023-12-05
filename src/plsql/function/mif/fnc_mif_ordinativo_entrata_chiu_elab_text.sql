/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- 20.04.2016 Sofia - compilata in prod bilmult

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_entrata_chiu_elab_text
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  flussoElabMifId integer)
RETURNS text AS
$body$
DECLARE

strMessaggio VARCHAR(1500):='';
strMessaggioFinale VARCHAR(1500):='';

chiuElabRec record;

codiceRisultato integer:=0;
messaggioRisultato varchar:='OK';
messaggioResult varchar:='OK';

BEGIN


    strMessaggioFinale:='Chiusura elaborazione trasmissione ordinativi entrata.';

    strMessaggio:='Chiamata fnc_mif_ordinativo_entrata_chiu_elab.';
	select * into chiuElabRec
    from fnc_mif_ordinativo_entrata_chiu_elab
    (enteProprietarioId,nomeEnte,annobilancio,loginOperazione,dataElaborazione,flussoElabMifId);

    if chiuElabRec.codiceRisultato!=0 then
    	codiceRisultato:=-1;
        messaggioRisultato:=chiuElabRec.messaggioRisultato;
    end if;

    messaggioResult:='codiceRes='||codiceRisultato::varchar||'|'||
                     'messaggioRes='||messaggioRisultato;

    return messaggioResult;

exception
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        messaggioResult:='codiceRes='||codiceRisultato::varchar||'|'||
                         'messaggioRes='||messaggioRisultato;
        return messaggioResult;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;