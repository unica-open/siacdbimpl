/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_siac_disponibilitavariare_cassa(id_in integer)
  RETURNS numeric AS
$BODY$
DECLARE


CAP_UG_TIPO constant varchar:='CAP-UG';
CAP_UP_TIPO constant varchar:='CAP-UP';

CAP_EG_TIPO constant varchar:='CAP-EG';
CAP_EP_TIPO constant varchar:='CAP-EP';

FASE_OP_BIL_PREV constant VARCHAR:='P';
FASE_OP_BIL_PROV constant VARCHAR:='E';

annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;
tipoCapitoloEq  varchar:=null;
faseOpCode varchar:=null;
dispVariareCassa   numeric:=0;
totOrdinativi   numeric:=0;
stanzEffettivoRec record;
elemId INTEGER:=0;
bilancioId integer:=0;

strMessaggio varchar(1500):=null;
BEGIN


	strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||'.';

	strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
	select per.anno, tipo.elem_tipo_code,bil.bil_id into strict annoBilancio, tipoCapitolo, bilancioId
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

    if NOT FOUND THEN
      RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
    end if;

    strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
      	          'Tipo elemento di bilancio='||tipoCapitolo||
    			  '.Lettura fase bilancio anno='||annoBilancio||'.';

    select  faseOp.fase_operativa_code into  faseOpCode
    from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
    where bilFase.bil_id =bilancioId
     and bilfase.data_cancellazione is null
     and bilFase.validita_fine is null
     and faseOp.fase_operativa_id=bilFase.fase_operativa_id
     and faseOp.data_cancellazione is null
    order by bilFase.bil_fase_operativa_id desc;

    if NOT FOUND THEN
      RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
    end if;

  -- 29.06.015 Calcolabile anche in previsione su capitolo di previsione, restituisce lo stanziamento effettivo di cassa del capitolo di previsione

  --  if faseOpCode=FASE_OP_BIL_PREV then
  --  	RAISE EXCEPTION '% Fase non ammessa per il calcolo richiesto.',strMessaggio;
  --  end if;

    elemId:=id_in;

    if faseOpCode != FASE_OP_BIL_PREV then
    	if tipoCapitolo=CAP_UP_TIPO then
           tipoCapitoloEq=CAP_UG_TIPO;
        elsif tipoCapitolo=CAP_EP_TIPO then
           tipoCapitoloEq=CAP_EG_TIPO;
        end if;
        if tipoCapitoloEq is not null then
			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
                          'Fase di bilancio='||faseOpCode||
    					  '.Lettura capitolo equivalente tipo='||tipoCapitoloEq||
                          ' anno='||annoBilancio||'.';
			select bilElemGest.elem_id into  elemId
   			from siac_t_bil_elem bilElemPrev, siac_d_bil_elem_tipo tipoGest,
       			 siac_t_bil_elem bilElemGest
		    where bilElemPrev.elem_id=id_in and
    	          bilElemGest.elem_code=bilElemPrev.elem_code and
        	      bilElemGest.elem_code2=bilElemPrev.elem_code2 and
            	  bilElemGest.elem_code3=bilElemPrev.elem_code3 and
	              bilElemGest.ente_proprietario_id=bilElemPrev.ente_proprietario_id and
    	          bilElemGest.bil_id=bilElemPrev.bil_id and
        	      bilElemGest.data_cancellazione is null and bilElemGest.validita_fine is null and
            	  tipoGest.elem_tipo_id=bilElemGest.elem_tipo_id and
              	  tipoGest.elem_tipo_code=tipoCapitoloEq;
             if NOT FOUND THEN
		     	elemId:=0;
		     end if;
       end if;
    end if;

    if elemId!=0 then
     case
    	when faseOpCode = FASE_OP_BIL_PREV and tipoCapitolo in (CAP_UP_TIPO)  then
			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
			              'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo stanziamento effettivo cassa per anno='||annoBilancio||'.';

            select * into stanzEffettivoRec
			from fnc_siac_stanz_effettivo_up_anno (elemId,annoBilancio);

			if stanzEffettivoRec.stanzEffettivoCassa is not null then
	            dispVariareCassa:= stanzEffettivoRec.stanzEffettivoCassa;
			end if;

    	when faseOpCode = FASE_OP_BIL_PREV and tipoCapitolo in (CAP_EP_TIPO)  then
			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
                           'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo stanziamento effettivo cassa per anno='||annoBilancio||'.';

            select * into stanzEffettivoRec
			from fnc_siac_stanz_effettivo_ep_anno (elemId,annoBilancio);


            if stanzEffettivoRec.stanzEffettivoCassa is not null then
	            dispVariareCassa:= stanzEffettivoRec.stanzEffettivoCassa;
			end if;

    	when faseOpCode != FASE_OP_BIL_PREV and tipoCapitolo in (CAP_UP_TIPO, CAP_UG_TIPO)  then
			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
                           'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo stanziamento effettivo cassa per anno='||annoBilancio||'.';

            select * into stanzEffettivoRec
			from fnc_siac_stanz_effettivo_ug_anno (elemId,annoBilancio);

			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
						  'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo totale ordinativi per anno='||annoBilancio||'.';

            select * into totOrdinativi
            from fnc_siac_totalepagatoug(elemId);

            if totOrdinativi is null then
              totOrdinativi:=0;
            end if;

            if stanzEffettivoRec.stanzEffettivoCassa is not null then
	             dispVariareCassa:= stanzEffettivoRec.stanzEffettivoCassa - totOrdinativi;
            else dispVariareCassa:= -totOrdinativi;
            end if;


	    when faseOpCode != FASE_OP_BIL_PREV and tipoCapitolo in (CAP_EP_TIPO, CAP_EG_TIPO)  then

			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
						  'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo stanziamento effettivo cassa per anno='||annoBilancio||'.';
		    select * into stanzEffettivoRec
			from fnc_siac_stanz_effettivo_eg_anno (elemId,annoBilancio);

			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
						  'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo totale ordinativi per anno='||annoBilancio||'.';
            select * into totOrdinativi
            from fnc_siac_totaleincassatoeg(elemId);
			if totOrdinativi is null then
              totOrdinativi:=0;
            end if;

            if stanzEffettivoRec.stanzEffettivoCassa is not null then
	             dispVariareCassa:= stanzEffettivoRec.stanzEffettivoCassa - totOrdinativi;
            else dispVariareCassa:= -totOrdinativi;
            end if;
     end case;
    end if;


return dispVariareCassa;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return 0;
    when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return 0;
    when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return 0;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return 0;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;