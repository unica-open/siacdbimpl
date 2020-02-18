/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_totaleincassatoeg (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

TIPO_ORD_I constant varchar:='I';

totIncassato numeric:=0;
strMessaggio varchar(1500):=null;

BEGIN

strMessaggio:='Totale incassato per elem_id='||id_in||'.';


totIncassato:=fnc_siac_totale_ordinativi(id_in,TIPO_ORD_I);


return totIncassato;

exception
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return totPagato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;