/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR174_indic_sint_spe_bp_org_er" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  code_missione varchar,
  desc_missione varchar,
  code_programma varchar,
  desc_programma varchar,
  code_titolo varchar,
  code_macroagg varchar,
  tipo_capitolo varchar,
  cap_id integer,
  pdce_code varchar,
  prev_stanz_anno1 numeric,
  prev_stanz_anno2 numeric,
  prev_stanz_anno3 numeric,
  prev_cassa_anno1 numeric,
  stanz_residuo_anno1 numeric,
  imp_fpv_anno_prec numeric
) AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;
    bilId INTEGER;
    bilIdPrec INTEGER;
    annoCap1 varchar;
    annoCap2 varchar;
    annoCap3 varchar;
    annoIniRend varchar;
    
BEGIN
 
/*
	Funzione che estrae i dati dei capitoli di entrata/previsione suddivisi per Missione, 
    Programma, Macroaggregato e Pdce.
    Gli importi sono restituiti nei 3 anni di previsione.
    Inoltre e' anche restituito l'importo dei soli capitoli FPV relativi all'anno
    precedente quello del bilancio.
    La funzione e' utilizzata dai report:
    	- BILR174 - Indicatori sintetici per Organismi ed enti strumentali delle Regioni e delle Province aut.
        - BILR177 - Indicatori sintetici per Regioni
    	- BILR180 - Indicatori sintetici per Enti Locali.

*/

--annoIniRend:= (p_anno::integer + 1)::varchar;
annoIniRend:= p_anno;

annoCap1 := annoIniRend;
annoCap2 := (annoIniRend::INTEGER+1)::varchar;
annoCap3 := (annoIniRend::INTEGER+2)::varchar;

SELECT t_bil.bil_id 
	into bilId 
FROM siac_t_bil t_bil,
    siac_t_periodo t_periodo
WHERE t_bil.periodo_id = t_periodo.periodo_id
	AND t_bil.ente_proprietario_id = p_ente_prop_id
    AND t_periodo.anno = annoIniRend
	AND t_bil.data_cancellazione IS NULL
    AND t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    raise exception 'Codice del bilancio non trovato per l''anno %', p_anno;
    return;
END IF;

SELECT t_bil.bil_id 
	into bilIdPrec 
FROM siac_t_bil t_bil,
    siac_t_periodo t_periodo
WHERE t_bil.periodo_id = t_periodo.periodo_id
	AND t_bil.ente_proprietario_id = p_ente_prop_id
    AND t_periodo.anno = (annoIniRend::INTEGER-1)::varchar
	AND t_bil.data_cancellazione IS NULL
    AND t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    raise exception 'Codice del bilancio non trovato per l''anno %', p_anno;
    return;
END IF;


return query 
select * from 
(with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,annoIniRend,'')),
capitoli as(
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        annoIniRend anno_bilancio,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id,
        cat_del_capitolo.elem_cat_code tipo_capitolo
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
	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    capitolo.elem_id=	r_capitolo_stato.elem_id							and	
    r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and	
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and    
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and	
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    capitolo.ente_proprietario_id=p_ente_prop_id							and 
    capitolo.bil_id = bilId													and            
    programma_tipo.classif_tipo_code='PROGRAMMA'							and	
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and	
    tipo_elemento.elem_tipo_code = 'CAP-UP'						     		and
    stato_capitolo.elem_stato_code	='VA'     
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
    and	r_cat_capitolo.data_cancellazione 			is null) ,
importi_cap as  (
    select tab.elem_id, 
            sum(tab.importo_comp_anno1) importo_comp_anno1,
            sum(tab.importo_comp_anno2) importo_comp_anno2,
            sum(tab.importo_comp_anno3) importo_comp_anno3,
            sum(tab.importo_cassa_anno1) importo_cassa_anno1,
            sum(tab.importo_cassa_anno2) importo_cassa_anno2,
            sum(tab.importo_cassa_anno3) importo_cassa_anno3,
            sum(tab.importo_res_anno1) importo_res_anno1,
            sum(tab.importo_res_anno2) importo_res_anno2,
            sum(tab.importo_res_anno3) importo_res_anno3
from (select 	capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 			BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                case when capitolo_imp_periodo.anno =annoCap1 and capitolo_imp_tipo.elem_det_tipo_code = 'STA'
                	then sum(capitolo_importi.elem_det_importo) end importo_comp_anno1,
                case when capitolo_imp_periodo.anno =annoCap2 and capitolo_imp_tipo.elem_det_tipo_code = 'STA'
                	then sum(capitolo_importi.elem_det_importo) end importo_comp_anno2,   
                case when capitolo_imp_periodo.anno =annoCap3 and capitolo_imp_tipo.elem_det_tipo_code = 'STA'
                	then sum(capitolo_importi.elem_det_importo) end importo_comp_anno3,   
                case when capitolo_imp_periodo.anno =annoCap1 and capitolo_imp_tipo.elem_det_tipo_code = 'SCA'
                	then sum(capitolo_importi.elem_det_importo) end importo_cassa_anno1,                    
                case when capitolo_imp_periodo.anno =annoCap2 and capitolo_imp_tipo.elem_det_tipo_code = 'SCA'
                	then sum(capitolo_importi.elem_det_importo) end importo_cassa_anno2,  
                case when capitolo_imp_periodo.anno =annoCap3 and capitolo_imp_tipo.elem_det_tipo_code = 'SCA'
                	then sum(capitolo_importi.elem_det_importo) end importo_cassa_anno3, 
                case when capitolo_imp_periodo.anno =annoCap1 and capitolo_imp_tipo.elem_det_tipo_code = 'STR'
                	then sum(capitolo_importi.elem_det_importo) end importo_res_anno1,                      
                case when capitolo_imp_periodo.anno =annoCap2 and capitolo_imp_tipo.elem_det_tipo_code = 'STR'
                	then sum(capitolo_importi.elem_det_importo) end importo_res_anno2,      
                case when capitolo_imp_periodo.anno =annoCap3 and capitolo_imp_tipo.elem_det_tipo_code = 'STR'
                	then sum(capitolo_importi.elem_det_importo) end importo_res_anno3      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,
                siac_t_bil 					bilancio,
                siac_t_periodo 				anno_eserc, 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where bilancio.periodo_id				=anno_eserc.periodo_id 								
            and	capitolo.bil_id					=bilancio.bil_id 			 
            and	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						            
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			              
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		            								
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id
            and	anno_eserc.anno					= annoIniRend
            and	tipo_elemento.elem_tipo_code = 'CAP-UP'
            and	stato_capitolo.elem_stato_code	=	'VA'
            and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')
            and	capitolo_imp_periodo.anno in (annoCap1,annoCap2,annoCap3)						
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	bilancio.data_cancellazione 				is null
            and	anno_eserc.data_cancellazione 				is null 
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,
        capitolo_imp_tipo.elem_det_tipo_code,
        capitolo_imp_periodo.anno) tab
        group by elem_id),
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
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null)     
SELECT  annoIniRend::varchar bil_anno,
		strut_bilancio.missione_code::varchar code_missione, 
		strut_bilancio.missione_desc::varchar desc_missione, 
        strut_bilancio.programma_code::varchar code_programma,
        strut_bilancio.programma_desc::varchar desc_programma,
        strut_bilancio.titusc_code::varchar code_titolo,
        strut_bilancio.macroag_code::varchar  code_macroagg,        
        case when capitoli.tipo_capitolo = 'FPVC'
        	then 'FPV'::varchar
            else capitoli.tipo_capitolo::varchar end tipo_capitolo,
        capitoli.elem_id::integer cap_id,        
        conto_pdce.classif_code::varchar pdce_code,                
        importi_cap.importo_comp_anno1::numeric prev_stanz_anno1,          
        importi_cap.importo_comp_anno2::numeric prev_stanz_anno2,   
        importi_cap.importo_comp_anno3::numeric prev_stanz_anno3,   
        importi_cap.importo_cassa_anno1::numeric prev_cassa_anno1,
        importi_cap.importo_res_anno1::numeric stanz_residuo_anno1,
        0::numeric imp_fpv_anno_prec
FROM strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
    LEFT JOIN importi_cap on importi_cap.elem_id = capitoli.elem_id
    LEFT JOIN conto_pdce on conto_pdce.elem_id = capitoli.elem_id
-- 19/03/2020. SIAC-7446.
--	Devono essere esclusi i capitoli presenti nella tabella siac_t_bil_elem_escludi_indicatori,
--	creata per gestire un'esigenza di CMTO.     
WHERE capitoli.elem_id IS NULL OR capitoli.elem_id NOT IN (select elem_id
			from siac_t_bil_elem_escludi_indicatori escludi
            where escludi.ente_proprietario_id = p_ente_prop_id
            	and escludi.validita_fine IS NULL
                and escludi.data_cancellazione IS NULL)) tab1  
UNION -- Unisco i dati relativi agli importi FPV di COMPETENZA dell'anno precedente
  SELECT  (annoIniRend::integer-1)::varchar bil_anno,
		importi_fpv_anno_prec.missione_code::varchar code_missione, 
		''::varchar desc_missione, 
        importi_fpv_anno_prec.programma_code::varchar code_programma,
        ''::varchar desc_programma,
        importi_fpv_anno_prec.titolo_code::varchar code_titolo,
        importi_fpv_anno_prec.macroagg_code::varchar  code_macroagg,
        'FPV'::varchar tipo_capitolo,
        importi_fpv_anno_prec.elem_id::integer cap_id,
        ''::varchar pdce_code,                        
        0::numeric prev_stanz_anno1,          
        0::numeric prev_stanz_anno2,   
        0::numeric prev_stanz_anno3,   
        0::numeric prev_cassa_anno1,
        0::numeric stanz_residuo_anno1,
        importi_fpv_anno_prec.importo_competenza::numeric imp_fpv_anno_prec
         from  siac_t_cap_u_importi_anno_prec importi_fpv_anno_prec
    where importi_fpv_anno_prec.ente_proprietario_id=p_ente_prop_id
    	and importi_fpv_anno_prec.anno= (annoIniRend::integer-1)::varchar
        and importi_fpv_anno_prec.elem_cat_code in ('FPV','FPVC')
-- 19/03/2020. SIAC-7446.
--	Devono essere esclusi i capitoli presenti nella tabella siac_t_bil_elem_escludi_indicatori,
--	creata per gestire un'esigenza di CMTO.     
        and importi_fpv_anno_prec.elem_id NOT IN (select elem_id
                    from siac_t_bil_elem_escludi_indicatori escludi
                    where escludi.ente_proprietario_id = p_ente_prop_id
                        and escludi.validita_fine IS NULL
                        and escludi.data_cancellazione IS NULL);       
                    
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