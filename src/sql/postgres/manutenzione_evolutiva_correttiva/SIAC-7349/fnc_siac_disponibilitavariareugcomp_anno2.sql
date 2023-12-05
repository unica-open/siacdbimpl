/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION if exists fnc_siac_disponibilitavariareugcomp_anno2(integer, integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno2 (
  id_in integer,
  id_comp integer
)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
DECLARE

/*Constants*/
CAP_UG_TIPO constant varchar:='CAP-UG';

/*Variables*/
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
	' - Id componente='||id_comp||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';

	/*Calcolo annoBilancio e TipoCapitolo*/
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	case
      when tipoCapitolo=CAP_UG_TIPO then
	  	/*Incremento anno di bilancio +1 - riferito all'anno 2*/
	  	annoBilancio:=((annoBilancio::INTEGER)+1)::varchar;

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
					  'Id componente='||id_comp||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ug_anno_comp (id_in, annoBilancio, id_comp);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoug_comp_anno_comp(id_in, annoBilancio, id_comp, false); --7349 Nel caso di disp var passo il parametro a false per non restituire le modifiche in negativo

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;

    end case;


return dispVariare;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;


ALTER FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno2 (id_in integer, id_comp integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno2 (id_in integer, id_comp integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno2 (id_in integer, id_comp integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno2 (id_in integer, id_comp integer) TO siac;
