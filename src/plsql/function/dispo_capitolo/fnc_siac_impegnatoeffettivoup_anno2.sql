/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno2 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

impegnatoEffettivo numeric:=0;

annoBilancio varchar:=null;

impegnatoEffettivoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;



     strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'.';
     select * into impegnatoEffettivoRec
     from  fnc_siac_impegnatoeffettivoup_comp_anno (id_in,((annoBilancio::integer)+1)::varchar);

     
     impegnatoEffettivo:=impegnatoEffettivoRec.impegnatoEffettivo;
	
	
     return impegnatoEffettivo;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno2 (id_in integer)
  OWNER TO siac;
 
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno2 (id_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno2 (id_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno2 (id_in integer) TO siac;