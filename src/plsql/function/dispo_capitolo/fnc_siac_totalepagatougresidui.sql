/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_totalepagatougresidui (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

TIPO_ORD_P constant varchar:='P';
totPagato numeric:=0;
strMessaggio varchar(1500):=null;

BEGIN

strMessaggio:='Totale pagato per elem_id='||id_in||'.';


totPagato:=fnc_siac_totale_ordinativi_su_residui(id_in,TIPO_ORD_P);


return totPagato;


exception
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        totPagato:=0;
        return totPagato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        totPagato:=0;
        return totOrdinativi;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;