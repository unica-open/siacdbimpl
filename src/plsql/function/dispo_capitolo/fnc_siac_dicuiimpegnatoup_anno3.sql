/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- SIAC-7349 04/08/2020 CM Inizio

DROP FUNCTION if exists siac.fnc_siac_dicuiimpegnatoup_anno3(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno3 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

diCuiImpegnato numeric:=0;
annoBilancio varchar:=null;

diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;

	/* SIAC-7349 mantengo questa chiamata perche cosi' il default del parametro verifica_mod_provv = TRUE 
	 * forza la restituzione delle modifiche provvisorie al valore dicuiimpegnato
	 * che qui servira' per il calcolo della disponibilita' ad impegnare  */
    strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||'.';
    select * into diCuiImpegnatoRec
    from  fnc_siac_dicuiimpegnatoup_comp_anno (id_in,((annoBilancio::INTEGER)+2)::varchar);
	
    diCuiImpegnato:=diCuiImpegnatoRec.diCuiImpegnato;


    return diCuiImpegnato;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
    when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        diCuiImpegnato:=0;
        return diCuiImpegnato;

	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno3 (integer)
  OWNER TO siac;
  
-- SIAC-7349 04/08/2020 CM Fine