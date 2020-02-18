/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR186_indic_sint_spe_rend_FPV_anno_prec" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  id_missione integer,
  code_missione varchar,
  desc_missione varchar,
  id_programma integer,
  code_programma varchar,
  desc_programma varchar,
  code_titolo varchar,
  code_macroagg varchar,
  tipo_capitolo varchar,
  cap_id integer,
  pdce_code varchar,
  spese_fpv_anni_prec numeric,
  display_error varchar
) AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;

    annoBilInt integer;   
    annoBilAnnoPrecStr varchar;
    bilId integer;
    
    
BEGIN
 
/*
	Funzione che estrae i dati di rendiconto di spesa FPV dell'anno di bilancio 
    precedente quello in input suddivisi per missione, programma, titolo, macroaggregato 
    e capitolo.
    
    I dati restituiti sono:
  		- importo FPV.
*/

annoBilInt:=p_anno::integer-1;
annoBilAnnoPrecStr:=(p_anno::INTEGER-1)::varchar;
     
	/* Leggo l'id dell'anno del rendiconto -1 */     
bilId:=0;     
select a.bil_id 
	INTO bilId
from siac_t_bil a, siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.ente_proprietario_id=p_ente_prop_id
and b.anno = annoBilAnnoPrecStr;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    bilId:=0;
    display_error := 'Codice del bilancio non trovato per l''anno %', anno3;
    return next;
    return;
END IF;
   

return query 
with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, annoBilAnnoPrecStr,'')),
capitoli as(
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        cat_del_capitolo.elem_cat_code tipo_capitolo,
       	capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where 		
	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					    
    and capitolo.elem_id=	r_capitolo_stato.elem_id							
    and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
    and capitolo.elem_id=r_capitolo_programma.elem_id							
    and capitolo.elem_id=r_capitolo_macroaggr.elem_id							
    and programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
    and programma.classif_id=r_capitolo_programma.classif_id					    
    and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				
    and macroaggr.classif_id=r_capitolo_macroaggr.classif_id						
    and capitolo.elem_id				=	r_cat_capitolo.elem_id				
	and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		    
    and capitolo.ente_proprietario_id=p_ente_prop_id	
    and capitolo.bil_id =bilId												
    and programma_tipo.classif_tipo_code='PROGRAMMA'								
    and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
    and tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
    and stato_capitolo.elem_stato_code	='VA'     
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null), 
fpv as (
select t_bil_elem.elem_id, 
sum (coalesce(t_bil_elem_det.elem_det_importo,0)) as imp_fpv
from siac_t_bil_elem t_bil_elem,
	siac_r_bil_elem_stato r_bil_elem_stato, 
	siac_d_bil_elem_stato d_bil_elem_stato,
	siac_r_bil_elem_categoria r_bil_elem_categoria,
    siac_d_bil_elem_categoria d_bil_elem_categoria,
	siac_t_bil_elem_det t_bil_elem_det,
    siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
    and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
    and r_bil_elem_categoria.elem_id=t_bil_elem.elem_id 
    and d_bil_elem_categoria.elem_cat_id=r_bil_elem_categoria.elem_cat_id
    and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
    and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
    and t_bil.bil_id=t_bil_elem.bil_id
    and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.periodo_id=t_bil_elem_det.periodo_id
    and t_bil_elem.ente_proprietario_id=p_ente_prop_id	
    and t_periodo.anno  = annoBilAnnoPrecStr
    and d_bil_elem_stato.elem_stato_code='VA'
    and d_bil_elem_categoria.elem_cat_code	in	('FPV','FPVCC','FPVSC')
    and d_bil_elem_det_tipo.elem_det_tipo_code='STA'
    and r_bil_elem_categoria.validita_fine is NULL
    and r_bil_elem_stato.validita_fine is NULL
    and t_bil_elem.data_cancellazione is null
    and r_bil_elem_stato.data_cancellazione is null
    and d_bil_elem_stato.data_cancellazione is null
    and r_bil_elem_categoria.data_cancellazione is null
    and d_bil_elem_categoria.data_cancellazione is null
    and t_bil_elem_det.data_cancellazione is null
    and d_bil_elem_det_tipo.data_cancellazione is null
    and t_bil.data_cancellazione is null
    and t_periodo.data_cancellazione is null
group by t_bil_elem.elem_id),
conto_pdce as(
        select t_class_upb.classif_code, r_capitolo_upb.elem_id
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 
                and t_class_upb.classif_id=r_capitolo_upb.classif_id
                and t_class_upb.ente_proprietario_id=p_ente_prop_id
                and class_upb.classif_tipo_code like 'PDC_%'
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null)          
SELECT  strut_bilancio.missione_id::integer id_missione,
		strut_bilancio.missione_code::varchar code_missione, 
		strut_bilancio.missione_desc::varchar desc_missione, 
        strut_bilancio.programma_id::integer id_programma,
        strut_bilancio.programma_code::varchar code_programma,
        strut_bilancio.programma_desc::varchar desc_programma,
        strut_bilancio.titusc_code::varchar code_titolo,
        strut_bilancio.macroag_code::varchar  code_macroagg,
        case when capitoli.tipo_capitolo = 'FPVC'
        	then 'FPV'::varchar
            else capitoli.tipo_capitolo::varchar end tipo_capitolo,
        capitoli.elem_id::integer cap_id,
        conto_pdce.classif_code::varchar pdce_code,            
        sum(COALESCE(fpv.imp_fpv,0))::numeric spese_fpv_anni_prec,                    
        ''::varchar display_error
FROM strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    						AND strut_bilancio.macroag_id = capitoli.macroaggregato_id)       
    LEFT JOIN fpv 	on fpv.elem_id = capitoli.elem_id    
    LEFT JOIN conto_pdce on conto_pdce.elem_id = capitoli.elem_id        
GROUP BY id_missione, code_missione, desc_missione, 
		id_programma, code_programma, desc_programma, 
        code_titolo, code_macroagg, capitoli.tipo_capitolo,
        cap_id, pdce_code
ORDER BY code_missione, code_programma;
                    
EXCEPTION
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;