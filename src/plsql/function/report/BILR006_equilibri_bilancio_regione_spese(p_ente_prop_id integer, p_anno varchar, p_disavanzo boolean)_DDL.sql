/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR006_equilibri_bilancio_regione_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_disavanzo boolean
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  pdc varchar
) AS
$body$
DECLARE

capitoloRec record;
capitoloImportiRec record;
classifBilRec record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
tipologia_capitolo	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI';	 -- stanziamento residuo
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
pdc='';

---------------------------------------------------------------------------------------------------------------------------------------------------
 
--07/04/2020 funzione rivista per motivi prestazionali.

return query 
with dati_struttura as (select *
						from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
	capitoli as (select programma.classif_id programma_id,
                macroaggr.classif_id macroaggr_id,
                anno_eserc.anno anno_bilancio,
                capitolo.*,
                pdc.classif_code
          from siac_t_bil bilancio,
               siac_t_periodo anno_eserc,
               siac_d_class_tipo programma_tipo,
               siac_t_class programma,
               siac_d_class_tipo macroaggr_tipo,
               siac_t_class macroaggr,
               siac_t_bil_elem capitolo,
               siac_d_bil_elem_tipo tipo_elemento,
               siac_r_bil_elem_class r_capitolo_programma,
               siac_r_bil_elem_class r_capitolo_macroaggr,
               siac_r_bil_elem_class r_capitolo_pdc,
               siac_t_class pdc,
               siac_d_class_tipo pdc_tipo,
               siac_d_bil_elem_stato stato_capitolo, 
               siac_r_bil_elem_stato r_capitolo_stato,
               siac_d_bil_elem_categoria cat_del_capitolo,
               siac_r_bil_elem_categoria r_cat_capitolo
          where bilancio.periodo_id=anno_eserc.periodo_id 							and
              capitolo.bil_id=bilancio.bil_id 										and
              programma.classif_tipo_id	=programma_tipo.classif_tipo_id 			and
              programma.classif_id	=r_capitolo_programma.classif_id				and
              capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
              capitolo.elem_id=r_capitolo_programma.elem_id							and
              capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
              capitolo.elem_id				=	r_capitolo_stato.elem_id			and
              r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
              r_capitolo_pdc.classif_id 			= pdc.classif_id					and
              pdc.classif_tipo_id 				= pdc_tipo.classif_tipo_id			and
              capitolo.elem_id 					= 	r_capitolo_pdc.elem_id			and	
              macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id 			and
              macroaggr.classif_id	=r_capitolo_macroaggr.classif_id				and
              capitolo.elem_id				=	r_cat_capitolo.elem_id				and
              r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
              capitolo.ente_proprietario_id			=	p_ente_prop_id			and
              anno_eserc.anno= p_anno 											and    
              tipo_elemento.elem_tipo_code = elemTipoCode						and	
              programma_tipo.classif_tipo_code	='PROGRAMMA' 					and		    
              macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO'				and    			     		     
              stato_capitolo.elem_stato_code	=	'VA'								and    
              --03/08/2016: aggiunto FPVC
              cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')			and
              ---------cat_del_capitolo.elem_cat_code	=	'STD'								and   
              pdc_tipo.classif_tipo_code like 'PDC_%'									and												
              bilancio.data_cancellazione 				is null		and
              anno_eserc.data_cancellazione 				is null		and
              programma_tipo.data_cancellazione			is null 	and
              programma.data_cancellazione 				is null 	and
              macroaggr_tipo.data_cancellazione	 		is null 	and
              macroaggr.data_cancellazione 				is null 	and
              tipo_elemento.data_cancellazione 			is null 	and
              r_capitolo_programma.data_cancellazione 	is null 	and
              r_capitolo_macroaggr.data_cancellazione 	is null 	and
              r_capitolo_pdc.data_cancellazione 			is null 	and
              pdc.data_cancellazione 						is null 	and
              pdc_tipo.data_cancellazione 				is null 	and
              stato_capitolo.data_cancellazione 			is null 	and 
              r_capitolo_stato.data_cancellazione 		is null 	and
              cat_del_capitolo.data_cancellazione 		is null 	and
              r_cat_capitolo.data_cancellazione 			is null 	and
              capitolo.data_cancellazione 				is null),
    importi_stanz_anno as (select 	capitolo_importi.elem_id,
                      sum(capitolo_importi.elem_det_importo) importo       
          from 		siac_t_bil_elem_det capitolo_importi,
                      siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                      siac_t_periodo capitolo_imp_periodo,
                      siac_t_bil_elem capitolo,
                      siac_d_bil_elem_tipo tipo_elemento,
                      siac_t_bil bilancio,
                      siac_t_periodo anno_eserc, 
                      siac_d_bil_elem_stato 		stato_capitolo, 
                      siac_r_bil_elem_stato 		r_capitolo_stato,
                      siac_d_bil_elem_categoria 	cat_del_capitolo,
                      siac_r_bil_elem_categoria 	r_cat_capitolo
              where 	bilancio.periodo_id=anno_eserc.periodo_id 								
                  and	capitolo.bil_id=bilancio.bil_id 			 
                  and	capitolo.elem_id	=	capitolo_importi.elem_id 
                  and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                  and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
                  and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 
                  and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                  and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
                  and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
                  and	anno_eserc.anno= p_anno 						
                  and	tipo_elemento.elem_tipo_code = elemTipoCode                  			  
                  and	capitolo_imp_periodo.anno in (annoCapImp)  
                  and 	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --STA                		
                  and	stato_capitolo.elem_stato_code	=	'VA'								                                    	        		
                  and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')								
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
              group by   capitolo_importi.elem_id),
importi_stanz_anno1 as (select 	capitolo_importi.elem_id,
                      sum(capitolo_importi.elem_det_importo) importo       
          from 		siac_t_bil_elem_det capitolo_importi,
                      siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                      siac_t_periodo capitolo_imp_periodo,
                      siac_t_bil_elem capitolo,
                      siac_d_bil_elem_tipo tipo_elemento,
                      siac_t_bil bilancio,
                      siac_t_periodo anno_eserc, 
                      siac_d_bil_elem_stato 		stato_capitolo, 
                      siac_r_bil_elem_stato 		r_capitolo_stato,
                      siac_d_bil_elem_categoria 	cat_del_capitolo,
                      siac_r_bil_elem_categoria 	r_cat_capitolo
              where 	bilancio.periodo_id=anno_eserc.periodo_id 								
                  and	capitolo.bil_id=bilancio.bil_id 			 
                  and	capitolo.elem_id	=	capitolo_importi.elem_id 
                  and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                  and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
                  and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 
                  and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                  and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
                  and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
                  and	anno_eserc.anno= p_anno 						
                  and	tipo_elemento.elem_tipo_code = elemTipoCode                  			  
                  and	capitolo_imp_periodo.anno in (annoCapImp1)  
                  and 	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --STA                		
                  and	stato_capitolo.elem_stato_code	=	'VA'								                                    	        		
                  and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')								
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
              group by   capitolo_importi.elem_id),
importi_stanz_anno2 as (select 	capitolo_importi.elem_id,
                      sum(capitolo_importi.elem_det_importo) importo       
          from 		siac_t_bil_elem_det capitolo_importi,
                      siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                      siac_t_periodo capitolo_imp_periodo,
                      siac_t_bil_elem capitolo,
                      siac_d_bil_elem_tipo tipo_elemento,
                      siac_t_bil bilancio,
                      siac_t_periodo anno_eserc, 
                      siac_d_bil_elem_stato 		stato_capitolo, 
                      siac_r_bil_elem_stato 		r_capitolo_stato,
                      siac_d_bil_elem_categoria 	cat_del_capitolo,
                      siac_r_bil_elem_categoria 	r_cat_capitolo
              where 	bilancio.periodo_id=anno_eserc.periodo_id 								
                  and	capitolo.bil_id=bilancio.bil_id 			 
                  and	capitolo.elem_id	=	capitolo_importi.elem_id 
                  and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                  and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
                  and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 
                  and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                  and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
                  and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
                  and	anno_eserc.anno= p_anno 						
                  and	tipo_elemento.elem_tipo_code = elemTipoCode                  			  
                  and	capitolo_imp_periodo.anno in (annoCapImp2)  
                  and 	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --STA                		
                  and	stato_capitolo.elem_stato_code	=	'VA'								                                    	        		
                  and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')								
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
              group by   capitolo_importi.elem_id),
importi_cassa as (select 	capitolo_importi.elem_id,
                      sum(capitolo_importi.elem_det_importo) importo       
          from 		siac_t_bil_elem_det capitolo_importi,
                      siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                      siac_t_periodo capitolo_imp_periodo,
                      siac_t_bil_elem capitolo,
                      siac_d_bil_elem_tipo tipo_elemento,
                      siac_t_bil bilancio,
                      siac_t_periodo anno_eserc, 
                      siac_d_bil_elem_stato 		stato_capitolo, 
                      siac_r_bil_elem_stato 		r_capitolo_stato,
                      siac_d_bil_elem_categoria 	cat_del_capitolo,
                      siac_r_bil_elem_categoria 	r_cat_capitolo
              where 	bilancio.periodo_id=anno_eserc.periodo_id 								
                  and	capitolo.bil_id=bilancio.bil_id 			 
                  and	capitolo.elem_id	=	capitolo_importi.elem_id 
                  and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                  and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
                  and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 
                  and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                  and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
                  and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
                  and	anno_eserc.anno= p_anno 						
                  and	tipo_elemento.elem_tipo_code = elemTipoCode                  			  
                  and	capitolo_imp_periodo.anno in (annoCapImp)  
                  and 	capitolo_imp_tipo.elem_det_tipo_code = TipoImpCassa --SCA                		
                  and	stato_capitolo.elem_stato_code	=	'VA'								                                    	        		
                  and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')								
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
              group by   capitolo_importi.elem_id),
importi_residui as (select 	capitolo_importi.elem_id,
                      sum(capitolo_importi.elem_det_importo) importo       
          from 		siac_t_bil_elem_det capitolo_importi,
                      siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                      siac_t_periodo capitolo_imp_periodo,
                      siac_t_bil_elem capitolo,
                      siac_d_bil_elem_tipo tipo_elemento,
                      siac_t_bil bilancio,
                      siac_t_periodo anno_eserc, 
                      siac_d_bil_elem_stato 		stato_capitolo, 
                      siac_r_bil_elem_stato 		r_capitolo_stato,
                      siac_d_bil_elem_categoria 	cat_del_capitolo,
                      siac_r_bil_elem_categoria 	r_cat_capitolo
              where 	bilancio.periodo_id=anno_eserc.periodo_id 								
                  and	capitolo.bil_id=bilancio.bil_id 			 
                  and	capitolo.elem_id	=	capitolo_importi.elem_id 
                  and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                  and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
                  and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 
                  and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                  and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
                  and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
                  and	anno_eserc.anno= p_anno 						
                  and	tipo_elemento.elem_tipo_code = elemTipoCode                  			  
                  and	capitolo_imp_periodo.anno in (annoCapImp)  
                  and 	capitolo_imp_tipo.elem_det_tipo_code = TipoImpRes --STR                		
                  and	stato_capitolo.elem_stato_code	=	'VA'								                                    	        		
                  and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')								
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
              group by   capitolo_importi.elem_id),
importi_stanz_anno_prec as (select 	capitolo_importi.elem_id,
                      sum(capitolo_importi.elem_det_importo) importo       
          from 		siac_t_bil_elem_det capitolo_importi,
                      siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                      siac_t_periodo capitolo_imp_periodo,
                      siac_t_bil_elem capitolo,
                      siac_d_bil_elem_tipo tipo_elemento,
                      siac_t_bil bilancio,
                      siac_t_periodo anno_eserc, 
                      siac_d_bil_elem_stato 		stato_capitolo, 
                      siac_r_bil_elem_stato 		r_capitolo_stato,
                      siac_d_bil_elem_categoria 	cat_del_capitolo,
                      siac_r_bil_elem_categoria 	r_cat_capitolo
              where 	bilancio.periodo_id=anno_eserc.periodo_id 								
                  and	capitolo.bil_id=bilancio.bil_id 			 
                  and	capitolo.elem_id	=	capitolo_importi.elem_id 
                  and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                  and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
                  and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 
                  and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                  and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
                  and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
                  and	anno_eserc.anno= p_anno 						
                  and	tipo_elemento.elem_tipo_code = elemTipoCode                  			  
                  and	capitolo_imp_periodo.anno in (annoCapImp)  
                  and 	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --STI                		
                  and	stato_capitolo.elem_stato_code	=	'VA'								                                    	        		
                  and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')								
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
              group by   capitolo_importi.elem_id),
importi_stanz_fpv_anno as (select 	capitolo_importi.elem_id,
                      sum(capitolo_importi.elem_det_importo) importo       
          from 		siac_t_bil_elem_det capitolo_importi,
                      siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                      siac_t_periodo capitolo_imp_periodo,
                      siac_t_bil_elem capitolo,
                      siac_d_bil_elem_tipo tipo_elemento,
                      siac_t_bil bilancio,
                      siac_t_periodo anno_eserc, 
                      siac_d_bil_elem_stato 		stato_capitolo, 
                      siac_r_bil_elem_stato 		r_capitolo_stato,
                      siac_d_bil_elem_categoria 	cat_del_capitolo,
                      siac_r_bil_elem_categoria 	r_cat_capitolo
              where 	bilancio.periodo_id=anno_eserc.periodo_id 								
                  and	capitolo.bil_id=bilancio.bil_id 			 
                  and	capitolo.elem_id	=	capitolo_importi.elem_id 
                  and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                  and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
                  and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 
                  and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                  and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
                  and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
                  and	anno_eserc.anno= p_anno 						
                  and	tipo_elemento.elem_tipo_code = elemTipoCode                  			  
                  and	capitolo_imp_periodo.anno in (annoCapImp)  
                  and 	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --STA                		
                  and	stato_capitolo.elem_stato_code	=	'VA'								                                    	        		
                  and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')								
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
              group by   capitolo_importi.elem_id),
importi_stanz_fpv_anno1 as (select 	capitolo_importi.elem_id,
                      sum(capitolo_importi.elem_det_importo) importo       
          from 		siac_t_bil_elem_det capitolo_importi,
                      siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                      siac_t_periodo capitolo_imp_periodo,
                      siac_t_bil_elem capitolo,
                      siac_d_bil_elem_tipo tipo_elemento,
                      siac_t_bil bilancio,
                      siac_t_periodo anno_eserc, 
                      siac_d_bil_elem_stato 		stato_capitolo, 
                      siac_r_bil_elem_stato 		r_capitolo_stato,
                      siac_d_bil_elem_categoria 	cat_del_capitolo,
                      siac_r_bil_elem_categoria 	r_cat_capitolo
              where 	bilancio.periodo_id=anno_eserc.periodo_id 								
                  and	capitolo.bil_id=bilancio.bil_id 			 
                  and	capitolo.elem_id	=	capitolo_importi.elem_id 
                  and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                  and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
                  and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 
                  and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                  and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
                  and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
                  and	anno_eserc.anno= p_anno 						
                  and	tipo_elemento.elem_tipo_code = elemTipoCode                  			  
                  and	capitolo_imp_periodo.anno in (annoCapImp1)  
                  and 	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --STA                		
                  and	stato_capitolo.elem_stato_code	=	'VA'								                                    	        		
                  and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')								
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
              group by   capitolo_importi.elem_id),
importi_stanz_fpv_anno2 as (select 	capitolo_importi.elem_id,
                      sum(capitolo_importi.elem_det_importo) importo       
          from 		siac_t_bil_elem_det capitolo_importi,
                      siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                      siac_t_periodo capitolo_imp_periodo,
                      siac_t_bil_elem capitolo,
                      siac_d_bil_elem_tipo tipo_elemento,
                      siac_t_bil bilancio,
                      siac_t_periodo anno_eserc, 
                      siac_d_bil_elem_stato 		stato_capitolo, 
                      siac_r_bil_elem_stato 		r_capitolo_stato,
                      siac_d_bil_elem_categoria 	cat_del_capitolo,
                      siac_r_bil_elem_categoria 	r_cat_capitolo
              where 	bilancio.periodo_id=anno_eserc.periodo_id 								
                  and	capitolo.bil_id=bilancio.bil_id 			 
                  and	capitolo.elem_id	=	capitolo_importi.elem_id 
                  and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                  and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
                  and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 
                  and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                  and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
                  and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
                  and	anno_eserc.anno= p_anno 						
                  and	tipo_elemento.elem_tipo_code = elemTipoCode                  			  
                  and	capitolo_imp_periodo.anno in (annoCapImp2)  
                  and 	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --STA                		
                  and	stato_capitolo.elem_stato_code	=	'VA'								                                    	        		
                  and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')								
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
              group by   capitolo_importi.elem_id),
importi_stanz_fpv_anno_prec as (select 	capitolo_importi.elem_id,
                      sum(capitolo_importi.elem_det_importo) importo       
          from 		siac_t_bil_elem_det capitolo_importi,
                      siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                      siac_t_periodo capitolo_imp_periodo,
                      siac_t_bil_elem capitolo,
                      siac_d_bil_elem_tipo tipo_elemento,
                      siac_t_bil bilancio,
                      siac_t_periodo anno_eserc, 
                      siac_d_bil_elem_stato 		stato_capitolo, 
                      siac_r_bil_elem_stato 		r_capitolo_stato,
                      siac_d_bil_elem_categoria 	cat_del_capitolo,
                      siac_r_bil_elem_categoria 	r_cat_capitolo
              where 	bilancio.periodo_id=anno_eserc.periodo_id 								
                  and	capitolo.bil_id=bilancio.bil_id 			 
                  and	capitolo.elem_id	=	capitolo_importi.elem_id 
                  and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                  and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
                  and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 
                  and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
                  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                  and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
                  and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
                  and	anno_eserc.anno= p_anno 						
                  and	tipo_elemento.elem_tipo_code = elemTipoCode                  			  
                  and	capitolo_imp_periodo.anno in (annoCapImp)  
                  and 	capitolo_imp_tipo.elem_det_tipo_code =  TipoImpstanzresidui --STI               		
                  and	stato_capitolo.elem_stato_code	=	'VA'								                                    	        		
                  and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')								
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
              group by   capitolo_importi.elem_id)                                                                                                                                
select p_anno::varchar bil_anno,
  		''::varchar missione_tipo_code,
        dati_struttura.missione_tipo_desc::varchar  missione_tipo_desc,
  		dati_struttura.missione_code::varchar missione_code,
  		dati_struttura.missione_desc::varchar missione_desc,
  		''::varchar programma_tipo_code,
  		dati_struttura.programma_tipo_desc::varchar programma_tipo_desc,
  		dati_struttura.programma_code::varchar programma_code,
  		dati_struttura.programma_desc::varchar programma_desc,
  		''::varchar titusc_tipo_code,
  		dati_struttura.titusc_tipo_desc::varchar titusc_tipo_desc,
  		dati_struttura.titusc_code::varchar titusc_code,
  		dati_struttura.titusc_desc::varchar titusc_desc,
  		''::varchar macroag_tipo_code,
  		dati_struttura.macroag_tipo_desc::varchar macroag_tipo_desc,
  		dati_struttura.macroag_code::varchar macroag_code,
  		dati_struttura.macroag_desc::varchar macroag_desc,
  		capitoli.elem_code::varchar bil_ele_code,
  		capitoli.elem_desc::varchar bil_ele_desc ,
  		capitoli.elem_code2::varchar bil_ele_code2 ,
  		capitoli.elem_desc2::varchar bil_ele_desc2 ,
  		capitoli.elem_id::integer bil_ele_id ,
  		capitoli.elem_id_padre::integer bil_ele_id_padre ,
  		COALESCE(importi_residui.importo,0)::numeric stanziamento_prev_res_anno ,
  		COALESCE(importi_stanz_anno_prec.importo,0)::numeric stanziamento_anno_prec ,
  		COALESCE(importi_cassa.importo,0)::numeric stanziamento_prev_cassa_anno ,
  		COALESCE(importi_stanz_anno.importo,0)::numeric stanziamento_prev_anno ,
  		COALESCE(importi_stanz_anno1.importo,0)::numeric stanziamento_prev_anno1 ,
  		COALESCE(importi_stanz_anno2.importo,0)::numeric stanziamento_prev_anno2 ,
  		0::numeric impegnato_anno ,
  		0::numeric impegnato_anno1 ,
  		0::numeric impegnato_anno2 ,
  		COALESCE(importi_stanz_fpv_anno_prec.importo,0)::numeric stanziamento_fpv_anno_prec ,
  		COALESCE(importi_stanz_fpv_anno.importo,0)::numeric stanziamento_fpv_anno ,
  		COALESCE(importi_stanz_fpv_anno1.importo,0)::numeric stanziamento_fpv_anno1 ,
 		COALESCE(importi_stanz_fpv_anno2.importo,0)::numeric  stanziamento_fpv_anno2 ,
  		capitoli.classif_code::varchar pdc
from dati_struttura
	FULL JOIN capitoli
    	on  (dati_struttura.programma_id = capitoli.programma_id    
           	and	dati_struttura.macroag_id	= capitoli.macroaggr_id)
    left join importi_stanz_anno
    	on importi_stanz_anno.elem_id = capitoli.elem_id
    left join importi_stanz_anno1
    	on importi_stanz_anno1.elem_id = capitoli.elem_id
    left join importi_stanz_anno2
    	on importi_stanz_anno2.elem_id = capitoli.elem_id  
    left join importi_cassa
    	on importi_cassa.elem_id = capitoli.elem_id  
    left join importi_residui
    	on importi_residui.elem_id = capitoli.elem_id   
    left join importi_stanz_anno_prec
    	on importi_stanz_anno_prec.elem_id = capitoli.elem_id                        
    left join importi_stanz_fpv_anno
    	on importi_stanz_fpv_anno.elem_id = capitoli.elem_id   
    left join importi_stanz_fpv_anno1
    	on importi_stanz_fpv_anno1.elem_id = capitoli.elem_id   
    left join importi_stanz_fpv_anno2
    	on importi_stanz_fpv_anno2.elem_id = capitoli.elem_id                                                
    left join importi_stanz_fpv_anno_prec
    	on importi_stanz_fpv_anno_prec.elem_id = capitoli.elem_id                    
order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID ;                
              
raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;