/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_disponibilitaimpegnareug_anno1 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

dispImpegnare numeric:=0;
annoBilancio varchar:=null;

stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||'.';


	strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;


    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
    select * into stanzEffettivoRec
	from fnc_siac_stanz_effettivo_ug_anno (id_in,annoBilancio);

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
                  '.Calcolo impegnato per anno='||annobilancio||'.';
    select * into diCuiImpegnatoRec
    from fnc_siac_dicuiimpegnatoug_comp_anno (id_in,annoBilancio);

    if stanzEffettivoRec.massimoimpegnabile is null then
     dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
    ELSE
     if stanzEffettivoRec.massimoimpegnabile<stanzEffettivoRec.stanzEffettivo then
     	dispImpegnare:=stanzEffettivoRec.massimoImpegnabile-diCuiImpegnatoRec.diCuiImpegnato;
     else
	    dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
     end if;
    end if;


return dispImpegnare;

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