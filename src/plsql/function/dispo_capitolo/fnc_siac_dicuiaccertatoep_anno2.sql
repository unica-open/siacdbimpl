/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_dicuiaccertatoep_anno2 (id_in integer)
RETURNS numeric AS
$body$
DECLARE

diCuiAccertato numeric:=0;
annoBilancio varchar:=null;

diCuiAccertatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale accertato EP elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale accertato EP elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;



    strMessaggio:='Calcolo totale accertato EP elem_id='||id_in||'.';
    select * into diCuiAccertatoRec
    from  fnc_siac_dicuiaccertatoep_comp_anno (id_in,((annoBilancio::INTEGER)+1)::varchar);

diCuiAccertato:=diCuiAccertatoRec.diCuiAccertato;


return diCuiAccertato;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        diCuiAccertato:=0;
        return diCuiAccertato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        diCuiAccertato:=0;
        return diCuiAccertato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        diCuiAccertato:=0;
        return diCuiAccertato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;