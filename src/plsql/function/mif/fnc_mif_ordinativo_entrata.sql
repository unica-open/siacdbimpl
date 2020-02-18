/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- 20.04.2016 Sofia - compilata in prod bilmult
-- 18.04.2016 Sofia - versione per chiamata da batch
-- 27.05.2016 Sofia - JIRA-3619- aggiunto parametro di ritorno x restituire flussoElabMifDistOilId
drop FUNCTION fnc_mif_ordinativo_entrata
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out flussoElabMifId integer,
  out numeroOrdinativiTrasm integer,
  out nomeFileMif varchar,
  out codiceRisultato integer,
  out messaggioRisultato varchar );

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_entrata
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out flussoElabMifDistOilId integer, -- 27.05.2016 Sofia - JIRA-3619
  out flussoElabMifId integer,
  out numeroOrdinativiTrasm integer,
  out nomeFileMif varchar,
  out codiceRisultato integer,
  out messaggioRisultato varchar )
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 mifOrdinativoRec record;


BEGIN

	strMessaggioFinale:='Invio ordinativi di entrata al MIF.';


	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;
    flussoElabMifDistOilId:=null; -- 27.05.2016 Sofia - JIRA-3619

    strMessaggio:='Richiamo fnc_mif_ordinativo_entrata interno.';
	select *  into mifOrdinativoRec
    from fnc_mif_ordinativo_entrata
         (enteProprietarioId,
		  nomeEnte,
		  annobilancio,
		  loginOperazione,
		  dataElaborazione,
          null);

	numeroOrdinativiTrasm:=mifOrdinativoRec.numeroOrdinativiTrasm;
    codiceRisultato:=mifOrdinativoRec.codiceRisultato;
    messaggioRisultato:=mifOrdinativoRec.messaggioRisultato;
	flussoElabMifId:=mifOrdinativoRec.flussoElabMifId;
    nomeFileMif:=mifOrdinativoRec.nomeFileMif;

    -- 27.05.2016 Sofia - JIRA-3619
    flussoElabMifDistOilId:=mifOrdinativoRec.flussoElabMifDistOilId;
    return;

exception
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500)||'.' ;
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;