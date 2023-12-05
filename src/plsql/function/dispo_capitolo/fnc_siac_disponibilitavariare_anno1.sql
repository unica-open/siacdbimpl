/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-7349 04/08/2020 CM Inizio

DROP FUNCTION if exists siac.fnc_siac_disponibilitavariare_anno1(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariare_anno1(
	id_in integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

CAP_UG_TIPO constant varchar:='CAP-UG';
CAP_UP_TIPO constant varchar:='CAP-UP';

CAP_EG_TIPO constant varchar:='CAP-EG';
CAP_EP_TIPO constant varchar:='CAP-EP';

dispImpegnare numeric:=0;
dispAccertare numeric:=0;
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;

stanzEffettivoRec record;
diCuiImpegnatoRec record;
diCuiAccertatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	case
      when tipoCapitolo=CAP_UP_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_up_anno (id_in,annoBilancio);
		
		/* SIAC-7349 10:44
			sia per UP che per UG, il calcolo dell'impegnato ai fini del Calcolo della disponibilita' a variare
			dobbiamo restituire le ECONB ma non le modifiche negative provvisorie 
			-> modif<0 provvisorie non riconteggiate, danno disp. al capitolo
		*/
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	-- SIAC-7349 from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio);
   		from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio,false);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
      when  tipoCapitolo=CAP_EP_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EP_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ep_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EP_TIPO||
    	              '.Calcolo accertato per anno='||annobilancio||'.';
	    select * into diCuiAccertatoRec
    	from fnc_siac_dicuiaccertatoep_comp_anno (id_in,annoBilancio);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiAccertatoRec.diCuiAccertato;
      when tipoCapitolo=CAP_UG_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ug_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoug_comp_anno (id_in,annoBilancio, false);
        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
      when tipoCapitolo=CAP_EG_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EG_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_eg_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EG_TIPO||
    	              '.Calcolo accertato per anno='||annobilancio||'.';
	    select * into diCuiAccertatoRec
    	from fnc_siac_dicuiaccertatoeg_comp_anno (id_in,annoBilancio);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiAccertatoRec.diCuiAccertato;
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

ALTER FUNCTION siac.fnc_siac_disponibilitavariare_anno1(integer)
    OWNER TO siac;

-- SIAC-7349 04/08/2020 CM Fine