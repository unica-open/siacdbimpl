/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa_splus
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out flussoElabMifDistOilId integer,
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
  	strMessaggioFinale:='Invio ordinativi di spesa SIOPE PLUS..';


	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;
    flussoElabMifDistOilId:=null;

    strMessaggio:='Richiamo fnc_mif_ordinativo_spesa_splus interno.';
	select *  into mifOrdinativoRec
    from fnc_mif_ordinativo_spesa_splus
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