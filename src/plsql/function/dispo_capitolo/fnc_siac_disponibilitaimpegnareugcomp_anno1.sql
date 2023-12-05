/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno1(
	id_in integer,
	idcomp_in integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

COMPONENTE_IMPEGNABILE varchar:='Si';

dispImpegnare numeric:=0;
enteProprietarioId integer:=0;
flagImpegnabileComponente varchar:=null;
annoBilancio varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
 ---    ANNASILVIA CMTO FORZATURA
ente_prop_in NUMERIC:=0;

BEGIN

 	strMessaggio:='Calcolo disponibile impegnare elem_id='||id_in||
        	          'idcomp_in='||idcomp_in||'.';

	strMessaggio:='Calcolo disponibile impegnare elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
    
 
    -- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione
    ---    ANNASILVIA CMTO FORZATURA 13-01-2017 INIZIO 

    /*    select a.ente_proprietario_id 
        into ente_prop_in from siac_t_bil_elem a
        where a.elem_id = id_in;

        if ente_prop_in = 3 then
            	dispImpegnare := 9999999999;
    			return dispImpegnare;
        end if;*/
    ---    ANNASILVIA CMTO FORZATURA 13-01-2017 FINE 
    -- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione

    

	select per.anno, bilElem.ente_proprietario_id into strict annoBilancio, enteProprietarioId
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
    
    --SIAC-7349 
    --Se componente ha flag impegnabile = No o AUTO, restituire dispImpegnare=0
    select tipo.elem_det_comp_tipo_imp_desc into flagImpegnabileComponente
    from siac_d_bil_elem_det_comp_tipo componente 
    join siac_d_bil_elem_det_comp_tipo_imp tipo
    on tipo.elem_det_comp_tipo_imp_id = componente.elem_det_comp_tipo_imp_id
    where componente.elem_det_comp_tipo_id=idcomp_in
    and componente.ente_proprietario_id=enteProprietarioId
    and tipo.ente_proprietario_id=enteProprietarioId;
    /*and componente.validita_fine is null
    and componente.data_cancellazione is null
    and tipo.validita_fine is null 
    and tipo.data_cancellazione is null*/

    if flagImpegnabileComponente <> COMPONENTE_IMPEGNABILE THEN
        dispImpegnare=0;
        return dispImpegnare;
    end if;


    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Calcolo stanziamento effettivo per anno='||annoBilancio|| 
				   ' idcomp_in='||idcomp_in||'.';

    select * into stanzEffettivoRec
	from fnc_siac_stanz_effettivo_ug_anno_comp (id_in,annoBilancio,idcomp_in);

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
                  '.Calcolo impegnato per anno='||annobilancio|| 
				  ' idcomp_in='||idcomp_in||'.';

    select * into diCuiImpegnatoRec
    from fnc_siac_dicuiimpegnatoug_comp_anno_comp (id_in,annoBilancio,idcomp_in);

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
$BODY$;

ALTER FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno1(integer, integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno1(integer, integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno1(integer, integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno1(integer, integer) TO siac;
