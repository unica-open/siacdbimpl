/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaaccertareeg_anno3 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

dispAccertare numeric:=0;
annoBilancio varchar:=null;

stanzEffettivoRec record;
diCuiAccertatoRec record;

strMessaggio varchar(1500):=null;
---    ANNASILVIA CMTO FORZATURA
ente_prop_in NUMERIC:=0;
BEGIN

    strMessaggio:='Calcolo disponibilita accertare elem_id='||id_in||'.';


	strMessaggio:='Calcolo disponibilita accertare elem_id='||id_in||
    			  '.Lettura anno di bilancio.';
-- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione
---    ANNASILVIA CMTO FORZATURA 13-01-2017 INIZIO 
     
 /*   select a.ente_proprietario_id 
    into ente_prop_in from siac_t_bil_elem a
    where a.elem_id = id_in;
    
    if ente_prop_in = 3 then
        	dispAccertare := 9999999999;
			return dispAccertare;
    end if;*/
---    ANNASILVIA CMTO FORZATURA 13-01-2017 FINE 
-- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione
 


	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;

    annoBilancio:=((annoBilancio::INTEGER)+2)::varchar;

    strMessaggio:='Calcolo disponibilita accertare elem_id='||id_in||
    			  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
    select * into stanzEffettivoRec
	from fnc_siac_stanz_effettivo_eg_anno (id_in,annoBilancio);

    strMessaggio:='Calcolo disponibilita accertare elem_id='||id_in||
                  '.Calcolo accertato per anno='||annobilancio||'.';
    select * into diCuiAccertatoRec
    from fnc_siac_dicuiaccertatoeg_comp_anno (id_in,annoBilancio);

    dispAccertare:=stanzEffettivoRec.stanzEffettivo-diCuiAccertatoRec.diCuiAccertato;


return dispAccertare;

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