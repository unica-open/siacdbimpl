/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop function if exists siac.fnc_siac_dicuiimpegnatoug_econb_anno1 
(
  id_in integer
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_econb_anno1 
(
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

totImportoEconB numeric:=0;
annoBilancio varchar:=null;

resultRec record;

strMessaggio varchar(1500):=null;
BEGIN


    strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'.';

    strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;


    strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||
                             '.Calcolo per anno='||annobilancio||'.';

    select * into resultRec
    from fnc_siac_dicuiimpegnatoug_econb_anno  (id_in,annoBilancio);
    totImportoEconB:=resultRec.dicuiimpegnato_econb;
	if totImportoEconB is null then totImportoEconB:=0; end if;


	return totImportoEconB;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
alter function siac.fnc_siac_dicuiimpegnatoug_econb_anno1(integer) owner to siac;