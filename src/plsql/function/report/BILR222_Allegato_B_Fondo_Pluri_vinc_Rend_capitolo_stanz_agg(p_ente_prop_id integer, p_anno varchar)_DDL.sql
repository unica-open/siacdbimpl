/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR222_Allegato_B_Fondo_Pluri_vinc_Rend_capitolo_stanz_agg" (
  p_ente_prop_id integer,
  p_anno varchar
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
  elem_id_fpv integer,
  bil_ele_code_fpv varchar,
  bil_ele_desc_fpv varchar,
  bil_ele_code2_fpv varchar,
  bil_ele_desc2_fpv varchar,
  elem_id_std integer,
  bil_ele_code_std varchar,
  bil_ele_desc_std varchar,
  bil_ele_code2_std varchar,
  bil_ele_desc2_std varchar,
  bil_ele_code3_std varchar,
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  riacc_colonna_x numeric,
  riacc_colonna_y numeric,
  fondo_plur_anno_g numeric,
  fpv_stanziato_anno numeric,
  imp_cronoprogramma numeric
) AS
$body$
DECLARE


classifBilRec record;
var_fondo_plur_anno_prec_a numeric;
var_spese_impe_anni_prec_b numeric;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;

BEGIN

/*
	Funzione identica alla "BILR221_Allegato_B_Fondo_Pluriennale_vincolato_Rend_capitolo"
    fatta eccezione per il calcolo del campo "fondo_plur_anno_prec_a" che in questa 
    funzione tiene conto anche delle varizioni avvenute durante l'anno. 
    
*/
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

var_fondo_plur_anno_prec_a=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
fondo_plur_anno_g=0;


select fnc_siac_random_user()
into	user_table;

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;


        
return query  
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'') a
            where a.missione_code::integer <= 19),
    capitoli_fpv as(
    	select 	programma.classif_id programma_id,
			macroaggr.classif_id macroaggregato_id,
        	p_anno anno_bilancio, r_bil_elem_fpv.elem_id elem_id_std,
       		capitolo.*
		from 
     		siac_d_class_tipo programma_tipo,
     		siac_t_class programma,
     		siac_d_class_tipo macroaggr_tipo,
     		siac_t_class macroaggr,
	 		siac_t_bil_elem capitolo
	/* 27/05/2019: SIAC-6849.
    	Aggiunta la gestione della tabella siac_r_bil_elem_fpv dove e' registrata
        la relazione tra i capitoli FPV e quelli STD.
        Gli importi estratti sono relativi ai capitoli standard perche' gli impegni
        sono associati solo a questo tipo di capitolo.
        Pero' il report deve presentare l'elenco dei capitoli FPV, quindi
        occorre estrarre il capitolo FPV a cui e' relazionato ogni record. */             
            	left join siac_r_bil_elem_fpv r_bil_elem_fpv
                	on (r_bil_elem_fpv.elem_fpv_id = capitolo.elem_id 
                    	and r_bil_elem_fpv.data_cancellazione IS NULL
                        and r_bil_elem_fpv.validita_fine IS NULL),
	 		siac_d_bil_elem_tipo tipo_elemento,
     		siac_r_bil_elem_class r_capitolo_programma,
     		siac_r_bil_elem_class r_capitolo_macroaggr,
     		siac_d_bil_elem_stato stato_capitolo, 
     		siac_r_bil_elem_stato r_capitolo_stato,
	 		siac_d_bil_elem_categoria cat_del_capitolo,
     		siac_r_bil_elem_categoria r_cat_capitolo
		where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	and
            programma.classif_tipo_id	=programma_tipo.classif_tipo_id and
            programma.classif_id	=r_capitolo_programma.classif_id and
            macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id and
    		macroaggr.classif_id	=r_capitolo_macroaggr.classif_id and			     		 
    		capitolo.elem_id=r_capitolo_programma.elem_id	and
    		capitolo.elem_id=r_capitolo_macroaggr.elem_id	and
    		capitolo.elem_id		=	r_capitolo_stato.elem_id and
			r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id and
			capitolo.elem_id				=	r_cat_capitolo.elem_id	and
			r_cat_capitolo.elem_cat_id	=cat_del_capitolo.elem_cat_id and
            capitolo.bil_id 				= id_bil and
            capitolo.ente_proprietario_id	=	p_ente_prop_id	and
    		tipo_elemento.elem_tipo_code = elemTipoCode		and	
			programma_tipo.classif_tipo_code	='PROGRAMMA'  and		        
    		macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO' and   
			stato_capitolo.elem_stato_code	=	'VA'	and
    		--cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC') and 
            cat_del_capitolo.elem_cat_code	in ('FPV','FPVC') and 
			programma_tipo.data_cancellazione			is null 	and
    		programma.data_cancellazione 				is null 	and
    		macroaggr_tipo.data_cancellazione	 		is null 	and
    		macroaggr.data_cancellazione 				is null 	and
    		tipo_elemento.data_cancellazione 			is null 	and
    		r_capitolo_programma.data_cancellazione 	is null 	and
    		r_capitolo_macroaggr.data_cancellazione 	is null 	and    		
    		stato_capitolo.data_cancellazione 			is null 	and 
    		r_capitolo_stato.data_cancellazione 		is null 	and
			cat_del_capitolo.data_cancellazione 		is null 	and
    		r_cat_capitolo.data_cancellazione 			is null 	and
			capitolo.data_cancellazione 				is null),  
capitoli_std as (
    	select 	programma.classif_id programma_id,
			macroaggr.classif_id macroaggregato_id,
        	p_anno anno_bilancio,
       		capitolo.*
		from 
     		siac_d_class_tipo programma_tipo,
     		siac_t_class programma,
     		siac_d_class_tipo macroaggr_tipo,
     		siac_t_class macroaggr,
	 		siac_t_bil_elem capitolo,
	 		siac_d_bil_elem_tipo tipo_elemento,
     		siac_r_bil_elem_class r_capitolo_programma,
     		siac_r_bil_elem_class r_capitolo_macroaggr,
     		siac_d_bil_elem_stato stato_capitolo, 
     		siac_r_bil_elem_stato r_capitolo_stato,
	 		siac_d_bil_elem_categoria cat_del_capitolo,
     		siac_r_bil_elem_categoria r_cat_capitolo
		where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	and
            programma.classif_tipo_id	=programma_tipo.classif_tipo_id and
            programma.classif_id	=r_capitolo_programma.classif_id and
            macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id and
    		macroaggr.classif_id	=r_capitolo_macroaggr.classif_id and			     		 
    		capitolo.elem_id=r_capitolo_programma.elem_id	and
    		capitolo.elem_id=r_capitolo_macroaggr.elem_id	and
    		capitolo.elem_id		=	r_capitolo_stato.elem_id and
			r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id and
			capitolo.elem_id				=	r_cat_capitolo.elem_id	and
			r_cat_capitolo.elem_cat_id	=cat_del_capitolo.elem_cat_id and
            capitolo.bil_id 				= id_bil and
            capitolo.ente_proprietario_id	=	p_ente_prop_id	and
    		tipo_elemento.elem_tipo_code = elemTipoCode		and	
			programma_tipo.classif_tipo_code	='PROGRAMMA'  and		        
    		macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO' and   
			stato_capitolo.elem_stato_code	=	'VA'	and
            cat_del_capitolo.elem_cat_code	in ('STD','FSC') and 
			programma_tipo.data_cancellazione			is null 	and
    		programma.data_cancellazione 				is null 	and
    		macroaggr_tipo.data_cancellazione	 		is null 	and
    		macroaggr.data_cancellazione 				is null 	and
    		tipo_elemento.data_cancellazione 			is null 	and
    		r_capitolo_programma.data_cancellazione 	is null 	and
    		r_capitolo_macroaggr.data_cancellazione 	is null 	and    		
    		stato_capitolo.data_cancellazione 			is null 	and 
    		r_capitolo_stato.data_cancellazione 		is null 	and
			cat_del_capitolo.data_cancellazione 		is null 	and
    		r_cat_capitolo.data_cancellazione 			is null 	and
			capitolo.data_cancellazione 				is null),            
fpv_stanziamento_anno as (               
select 	 capitolo.elem_id,
	sum(capitolo_importi.elem_det_importo) importo_fpv_stanz_anno
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = elemTipoCode 
	and	t_periodo_bil.anno = p_anno	
	and	capitolo_imp_periodo.anno = p_anno	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
 GROUP BY capitolo.elem_id ),            
fpv_anno_prec_da_capitoli as (               
select 	 capitolo.elem_id,
		capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3,
	sum(capitolo_importi.elem_det_importo) importo_fpv_anno_prec
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = elemTipoCode 
	and	t_periodo_bil.anno = annoPrec	--anno bilancio -1	
	and	capitolo_imp_periodo.anno = annoPrec	--anno bilancio -1		  	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
  GROUP BY capitolo.elem_id, capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3 ),
fpv_variaz_anno_prec as (
select	dettaglio_variazione.elem_id,
			capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3,
            sum(dettaglio_variazione.elem_det_importo) importo_var            	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio ,
            siac_d_bil_elem_categoria 	cat_del_capitolo,
            siac_r_bil_elem_categoria 	r_cat_capitolo
  where 	r_variazione_stato.variazione_id =	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id  
    and 	r_cat_capitolo.elem_id = capitolo.elem_id
    and 	cat_del_capitolo.elem_cat_id = r_cat_capitolo.elem_cat_id
    and		testata_variazione.ente_proprietario_id				= p_ente_prop_id 
    and		anno_eserc.anno			= 	annoPrec
    and		tipologia_stato_var.variazione_stato_tipo_code not in ('D','A')
    and		tipo_capitolo.elem_tipo_code = 'CAP-UG'
    and	    tipo_elemento.elem_det_tipo_code in ('STA')
    and	    cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
    and   	anno_importo.anno = annoPrec 
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null  
    and 	r_cat_capitolo.data_cancellazione			is null 
    and 	cat_del_capitolo.data_cancellazione			is null 
    group by 	dettaglio_variazione.elem_id,
    	capitolo.elem_code, capitolo.elem_code2, capitolo.elem_code3),
importi_anni_prec as (
select t_bil_elem.elem_id,
	sum(coalesce( r_movgest_ts.movgest_ts_importo ,0)) spese_impe_anni_prec    	
    from siac_t_movgest t_movgest,  
          siac_t_movgest_ts t_movgest_ts, siac_t_movgest_ts_det t_movgest_ts_det,
          siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, siac_t_bil_elem t_bil_elem, 
		  siac_r_movgest_bil_elem r_movgest_bil_elem,
          siac_r_movgest_ts_stato r_movgest_ts_stato, siac_d_movgest_stato d_movgest_stato,
          siac_r_bil_elem_class r_bil_elem_class,
          siac_t_class t_class, siac_d_class_tipo d_class_tipo, 
           siac_d_movgest_tipo d_mov_tipo,
           siac_r_movgest_ts r_movgest_ts, 
           siac_t_avanzovincolo t_avanzovincolo, 
           siac_d_avanzovincolo_tipo d_avanzovincolo_tipo
    where 
           t_movgest.movgest_id = t_movgest_ts.movgest_id  
          and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
          and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
          and r_bil_elem_class.classif_id = t_class.classif_id
          and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
          and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
          and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
          and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
          and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
          and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
		  and t_movgest.bil_id = id_bil
          and t_movgest.ente_proprietario_id= p_ente_prop_id      
          and d_class_tipo.classif_tipo_code='PROGRAMMA'
          and t_movgest.movgest_anno =  annoBilInt
          and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
          and d_movgest_stato.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          and d_avanzovincolo_tipo.avav_tipo_code like'FPV%'  
          and t_movgest_ts.movgest_ts_id_padre is NULL              
          and r_movgest_bil_elem.data_cancellazione is null
          and r_movgest_bil_elem.validita_fine is NULL          
          and r_movgest_ts_stato.data_cancellazione is null
          and r_movgest_ts_stato.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and r_bil_elem_class.data_cancellazione is null
          and r_bil_elem_class.validita_fine is null
          and t_movgest_ts_det.data_cancellazione is null
          and t_movgest_ts_det.validita_fine is null
          and r_movgest_ts.avav_id=t_avanzovincolo.avav_id                                  
          and r_movgest_ts.data_cancellazione is null
          and r_movgest_ts.validita_fine is null
		  and t_bil_elem.data_cancellazione is null
    group by t_bil_elem.elem_id ),
riaccert_colonna_x as (
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno)
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo   
	select t_bil_elem.elem_id,
		sum(COALESCE(t_movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_x                
      from siac_r_modifica_stato r_modifica_stato, 
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
      siac_t_movgest_ts t_movgest_ts, siac_d_modifica_stato d_modifica_stato,
      siac_t_movgest t_movgest, siac_d_movgest_tipo d_movgest_tipo, 
      siac_t_modifica t_modifica, siac_d_modifica_tipo d_modifica_tipo,
      siac_t_bil_elem t_bil_elem, siac_r_movgest_bil_elem r_movgest_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class t_class, siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
      siac_t_atto_amm t_atto_amm ,
      siac_r_movgest_ts_stato r_movgest_ts_stato, 
      siac_d_movgest_stato d_movgest_stato    
      where t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
      and t_movgest_ts_det_mod.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and t_movgest.movgest_tipo_id=d_movgest_tipo.movgest_tipo_id
      and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id      
      and t_movgest.movgest_id=t_movgest_ts.movgest_id
      and t_modifica.mod_id=r_modifica_stato.mod_id
      and t_modifica.mod_tipo_id=d_modifica_tipo.mod_tipo_id
      and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
      and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
      and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
      and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
      and r_bil_elem_class.elem_id=t_bil_elem.elem_id
      and r_bil_elem_class.classif_id=t_class.classif_id
      and r_movgest_ts_stato.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and r_movgest_ts_stato.movgest_stato_id = d_movgest_stato.movgest_stato_id      
      and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
      and t_movgest.bil_id=id_bil
      and r_modifica_stato.ente_proprietario_id=p_ente_prop_id
      and d_modifica_stato.mod_stato_code='V'
      and d_movgest_tipo.movgest_tipo_code='I'
      and 
      (d_modifica_tipo.mod_tipo_code like  'ECON%'
         or d_modifica_tipo.mod_tipo_desc like  'ROR%')
      and d_modifica_tipo.mod_tipo_code <> 'REIMP'
      and d_class_tipo.classif_tipo_code='PROGRAMMA'
      and d_movgest_stato.movgest_stato_code in ('D', 'N')
      and t_movgest.movgest_anno = annoBilInt 
      and r_movgest_ts_stato.data_cancellazione is NULL
      and r_movgest_ts_stato.validita_fine is null
      and t_movgest_ts.movgest_ts_id_padre is null
      and r_modifica_stato.data_cancellazione is null
      and r_modifica_stato.validita_fine is null
      and t_movgest_ts_det_mod.data_cancellazione is null
      and t_movgest_ts_det_mod.validita_fine is null
      and t_movgest_ts.data_cancellazione is null
      and t_movgest_ts.validita_fine is null
      and d_modifica_stato.data_cancellazione is null
      and d_modifica_stato.validita_fine is null
      and t_movgest.data_cancellazione is null
      and t_movgest.validita_fine is null
      and d_movgest_tipo.data_cancellazione is null
      and d_movgest_tipo.validita_fine is null
      and t_modifica.data_cancellazione is null
      and t_modifica.validita_fine is null
      and d_modifica_tipo.data_cancellazione is null
      and d_modifica_tipo.validita_fine is null
      and t_bil_elem.data_cancellazione is null
      and t_bil_elem.validita_fine is null
      and r_movgest_bil_elem.data_cancellazione is null
      and r_movgest_bil_elem.validita_fine is null
      and r_bil_elem_class.data_cancellazione is null
      and r_bil_elem_class.validita_fine is null
      and t_class.data_cancellazione is null
      and t_class.validita_fine is null
      and d_class_tipo.data_cancellazione is null
      and d_class_tipo.validita_fine is null
      and t_atto_amm.data_cancellazione is null
      and t_atto_amm.validita_fine is null      
      and r_movgest_ts_atto_amm.data_cancellazione is null
      and r_movgest_ts_atto_amm.validita_fine is null
      and d_movgest_stato.data_cancellazione is null
      and d_movgest_stato.validita_fine is null      
      and exists (select 
          		1 
                from siac_r_movgest_ts r_movgest_ts, 
            	siac_t_avanzovincolo t_avanzovincolo, 
                siac_d_avanzovincolo_tipo d_avanzovincolo_tipo
			where r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                and d_avanzovincolo_tipo.avav_tipo_code like'FPV%'                 
                and r_movgest_ts.data_cancellazione is null
                and r_movgest_ts.validita_fine is null 
               )
      group by t_bil_elem.elem_id)  ,
riaccert_colonna_y as (
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno) su impegni pluriennali finanziati dal FPV e imputati agli esercizi successivi  a N
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo 
select t_bil_elem.elem_id,
	sum(COALESCE(t_movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_y
      from siac_r_modifica_stato r_modifica_stato, 
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
      siac_t_movgest_ts t_movgest_ts, 
      siac_d_modifica_stato d_modifica_stato,
      siac_t_movgest t_movgest, siac_d_movgest_tipo d_movgest_tipo,  
      siac_t_modifica t_modifica, siac_d_modifica_tipo d_modifica_tipo,
      siac_t_bil_elem t_bil_elem, siac_r_movgest_bil_elem r_movgest_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class t_class, siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
      siac_t_atto_amm t_atto_amm ,
      siac_r_movgest_ts_stato r_movgest_ts_stato, 
      siac_d_movgest_stato d_movgest_stato    
      where t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
      and t_movgest_ts_det_mod.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and t_movgest.movgest_tipo_id=d_movgest_tipo.movgest_tipo_id
      and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id      
      and t_movgest.movgest_id=t_movgest_ts.movgest_id
      and t_modifica.mod_id=r_modifica_stato.mod_id
      and t_modifica.mod_tipo_id=d_modifica_tipo.mod_tipo_id      
      and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
      and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
      and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
      and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
      and r_bil_elem_class.elem_id=t_bil_elem.elem_id
      and r_bil_elem_class.classif_id=t_class.classif_id
      and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id    
      and r_movgest_ts_stato.movgest_ts_id = t_movgest_ts.movgest_ts_id
      and r_movgest_ts_stato.movgest_stato_id = d_movgest_stato.movgest_stato_id  
      and t_movgest.bil_id= id_bil
      and r_modifica_stato.ente_proprietario_id=p_ente_prop_id
      and t_movgest.movgest_anno > annoBilInt 
      and d_modifica_stato.mod_stato_code='V'
      and d_movgest_tipo.movgest_tipo_code='I'
      and 
      (d_modifica_tipo.mod_tipo_code like  'ECON%'
         or d_modifica_tipo.mod_tipo_desc like  'ROR%')
      and d_modifica_tipo.mod_tipo_code <> 'REIMP'
      and d_class_tipo.classif_tipo_code='PROGRAMMA'
      and d_movgest_stato.movgest_stato_code in ('D', 'N')
      and r_movgest_ts_stato.data_cancellazione is NULL
      and r_movgest_ts_stato.validita_fine is null
      and t_movgest_ts.movgest_ts_id_padre is null
      and r_modifica_stato.data_cancellazione is null
      and r_modifica_stato.validita_fine is null
      and t_movgest_ts_det_mod.data_cancellazione is null
      and t_movgest_ts_det_mod.validita_fine is null
      and t_movgest_ts.data_cancellazione is null
      and t_movgest_ts.validita_fine is null
      and d_modifica_stato.data_cancellazione is null
      and d_modifica_stato.validita_fine is null
      and t_movgest.data_cancellazione is null
      and t_movgest.validita_fine is null
      and d_movgest_tipo.data_cancellazione is null
      and d_movgest_tipo.validita_fine is null
      and t_modifica.data_cancellazione is null
      and t_modifica.validita_fine is null
      and d_modifica_tipo.data_cancellazione is null
      and d_modifica_tipo.validita_fine is null
      and t_bil_elem.data_cancellazione is null
      and t_bil_elem.validita_fine is null
      and r_movgest_bil_elem.data_cancellazione is null
      and r_movgest_bil_elem.validita_fine is null
      and r_bil_elem_class.data_cancellazione is null
      and r_bil_elem_class.validita_fine is null
      and t_class.data_cancellazione is null
      and t_class.validita_fine is null
      and d_class_tipo.data_cancellazione is null
      and d_class_tipo.validita_fine is null
      and r_movgest_ts_atto_amm.data_cancellazione is null
      and r_movgest_ts_atto_amm.validita_fine is null
      and t_atto_amm.data_cancellazione is null
      and t_atto_amm.validita_fine is null
      and d_movgest_stato.data_cancellazione is null
      and d_movgest_stato.validita_fine is null
      and exists (select 
          		1 
                from siac_r_movgest_ts r_movgest_ts, 
            	siac_t_avanzovincolo t_avanzovincolo, 
                siac_d_avanzovincolo_tipo d_avanzovincolo_tipo
			where r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                and r_movgest_ts.data_cancellazione is null
                and r_movgest_ts.validita_fine is null )
      group by t_bil_elem.elem_id) ,
impegni_anno1_d as(
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
select x.elem_id,
	sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d   
from (
               (
              select t_bil_elem.elem_id,
              	sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno1_d              
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id      
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 1
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and dstacc.movgest_stato_code in ('D', 'N')   
                        and acc.movgest_anno = annoBilInt  
                        and t_movgest_ts.movgest_ts_id_padre is NULL                            
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null   
                        and t_movgest.data_cancellazione is null 
                        and t_movgest.validita_fine is null  
                        and t_bil_elem.data_cancellazione is null 
                        and t_bil_elem.validita_fine is null  
                        and t_class.data_cancellazione is null 
                        and t_class.validita_fine is null                                                                                                           
              	group by t_bil_elem.elem_id)
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno1_d
                from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id = p_ente_prop_id       
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 1
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and d_avanzovincolo_tipo.avav_tipo_code = 'AAM'
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                                                                                                       
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null                        
                   group by t_bil_elem.elem_id
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno1_d
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id                        
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_movgest.bil_id = id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id     
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 1
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I'
                        and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null                                                                         
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= t_movgest.ente_proprietario_id                             
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id                            
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   fasereimp.movgestnew_id = t_movgest.movgest_id                            
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_esito='OK'
                            and   pprec.anno=p_anno                            
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  r_movgest_ts.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by t_bil_elem.elem_id
              )    
              ) as x
                group by x.elem_id ),
impegni_anno2_e as(
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
select x.elem_id,
	sum(x.spese_da_impeg_anno2_e) as spese_da_impeg_anno2_e   
from (
               (
              select t_bil_elem.elem_id,
              	sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno2_e              
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id      
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and dstacc.movgest_stato_code in ('D', 'N')   
                        and acc.movgest_anno = annoBilInt  
                        and t_movgest_ts.movgest_ts_id_padre is NULL                            
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null   
                        and t_movgest.data_cancellazione is null 
                        and t_movgest.validita_fine is null  
                        and t_bil_elem.data_cancellazione is null 
                        and t_bil_elem.validita_fine is null  
                        and t_class.data_cancellazione is null 
                        and t_class.validita_fine is null                                                                                                           
              	group by t_bil_elem.elem_id)
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno2_e
                from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id = p_ente_prop_id       
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and d_avanzovincolo_tipo.avav_tipo_code = 'AAM'
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                                                                                                       
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null                        
                   group by t_bil_elem.elem_id
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anno2_e
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id                        
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_movgest.bil_id = id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id     
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno = annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I'
                        and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null                                                                         
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= t_movgest.ente_proprietario_id                             
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id                            
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   fasereimp.movgestnew_id = t_movgest.movgest_id                            
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_esito='OK'
                            and   pprec.anno=p_anno                            
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  r_movgest_ts.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by t_bil_elem.elem_id
              )    
              ) as x
                group by x.elem_id ),
impegni_annisucc_f as(
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
select x.elem_id,
	sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f   
from (
               (
              select t_bil_elem.elem_id,
              	sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anni_succ_f              
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id      
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno > annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and dstacc.movgest_stato_code in ('D', 'N')   
                        and acc.movgest_anno = annoBilInt  
                        and t_movgest_ts.movgest_ts_id_padre is NULL                            
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null   
                        and t_movgest.data_cancellazione is null 
                        and t_movgest.validita_fine is null  
                        and t_bil_elem.data_cancellazione is null 
                        and t_bil_elem.validita_fine is null  
                        and t_class.data_cancellazione is null 
                        and t_class.validita_fine is null                                                                                                           
              	group by t_bil_elem.elem_id)
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anni_succ_f
                from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
                        siac_t_atto_amm t_atto_amm, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id
                        and r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_atto_amm.attoamm_id = t_atto_amm.attoamm_id
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and t_movgest.bil_id =id_bil
                        and t_movgest.ente_proprietario_id = p_ente_prop_id       
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno > annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and d_avanzovincolo_tipo.avav_tipo_code = 'AAM'
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_movgest_ts_atto_amm.data_cancellazione is null
                        and r_movgest_ts_atto_amm.validita_fine is null                                                                                                       
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null                        
                   group by t_bil_elem.elem_id
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select t_bil_elem.elem_id,
              		sum(COALESCE(r_movgest_ts.movgest_ts_importo,0)) spese_da_impeg_anni_succ_f
                        from siac_t_movgest t_movgest,  
                        siac_t_movgest_ts t_movgest_ts, 
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_movgest_bil_elem,
                        siac_r_movgest_ts_stato r_movgest_ts_stato, 
                        siac_d_movgest_stato d_movgest_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class t_class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_avanzovincolo t_avanzovincolo, 
                        siac_d_avanzovincolo_tipo d_avanzovincolo_tipo 
                      where 
                        t_movgest.movgest_id = t_movgest_ts.movgest_id  
                        and t_movgest_ts.movgest_ts_id = t_movgest_ts_det.movgest_ts_id
                        and t_movgest_ts_det.movgest_ts_det_tipo_id =d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                        and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = t_class.classif_id
                        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_movgest_bil_elem.elem_id                        
                        and t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
                        and r_movgest_ts.avav_id=t_avanzovincolo.avav_id     
                        and t_avanzovincolo.avav_tipo_id=d_avanzovincolo_tipo.avav_tipo_id 
                        and t_movgest_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                        and t_movgest.bil_id = id_bil
                        and t_movgest.ente_proprietario_id= p_ente_prop_id     
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and t_movgest.movgest_anno > annoBilInt + 2
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_movgest_stato.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I'
                        and d_avanzovincolo_tipo.avav_tipo_code like'FPV%' 
                        and t_movgest_ts.movgest_ts_id_padre is NULL                             
                        and r_movgest_bil_elem.data_cancellazione is null
                        and r_movgest_bil_elem.validita_fine is NULL          
                        and r_movgest_ts_stato.data_cancellazione is null
                        and r_movgest_ts_stato.validita_fine is null
                        and t_movgest_ts_det.data_cancellazione is null
                        and t_movgest_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null                                                                         
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null 
                        and t_movgest.data_cancellazione is null
                        and t_movgest.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= t_movgest.ente_proprietario_id                             
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id                            
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   fasereimp.movgestnew_id = t_movgest.movgest_id                            
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_esito='OK'
                            and   pprec.anno=p_anno                            
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  r_movgest_ts.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by t_bil_elem.elem_id
              )    
              ) as x
                group by x.elem_id ),
/* Per la gestione degli importi del cronoprogramma, come da indicazioni di Troiano, 
		occorre:
	- Prendere i dati dei progetti relativi all'ultimo cronoprogrogramma (data_creazione)
      con flag "usato_per_fpv" = true.
    - Se non esiste prendere i dati dell'ultimo cronoprogramma in bozza cioe' con
      "usato_per_fpv" = false i cui progetti non  abbiano impegni collegati.

*/                
 cronoprogrammi_fpv as (select cronop.* from 
 		(select a.cronop_id, a.cronop_code, d.cronop_elem_code,
			d.cronop_elem_code2, d.cronop_elem_code3,
    		COALESCE(sum(e.cronop_elem_det_importo),0)::numeric importo_crono			
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d,          	
          siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where  pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.periodo_id = f.periodo_id
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and pr.ente_proprietario_id=p_ente_prop_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = true          
          and clt2.classif_tipo_code='PROGRAMMA'        
          and stct.cronop_stato_code='VA'          
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null
          group by a.cronop_id, a.cronop_code, 
          d.cronop_elem_code,
	d.cronop_elem_code2,d.cronop_elem_code3) cronop,
 		(select t_cronop.cronop_id, 
    max(t_cronop.data_creazione) max_data_creazione
    from siac_t_cronop t_cronop, 
    	siac_t_bil t_bil, siac_t_periodo t_periodo
    where t_cronop.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
        and t_cronop.ente_proprietario_id=p_ente_prop_id
        and t_periodo.anno=p_anno
        and t_cronop.usato_per_fpv::boolean=true
        and t_cronop.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL
    group by t_cronop.cronop_id
   order by max_data_creazione DESC
   limit 1) id_cronop_last_versione 
where id_cronop_last_versione.cronop_id =  cronop.cronop_id ),
cronoprogrammi_bozza as(
	select cronop_bozza.* from 
    (select a.cronop_id, a.cronop_code, d.cronop_elem_code,
			d.cronop_elem_code2, d.cronop_elem_code3,
    		COALESCE(sum(e.cronop_elem_det_importo),0)::numeric importo_crono			
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d,          	
          siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where  pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.periodo_id = f.periodo_id
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and pr.ente_proprietario_id=p_ente_prop_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = false          
          and clt2.classif_tipo_code='PROGRAMMA'        
          and stct.cronop_stato_code='VA'          
          and stprt.programma_stato_code='VA'
          and pr.programma_id not in (
        	select r_movgest_ts_programma.programma_id
            	from siac_r_movgest_ts_programma r_movgest_ts_programma
            	where r_movgest_ts_programma.ente_proprietario_id=p_ente_prop_id
                	and r_movgest_ts_programma.data_cancellazione IS NULL
                    and r_movgest_ts_programma.validita_fine IS NULL)
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null
          group by a.cronop_id, a.cronop_code, 
          d.cronop_elem_code,
	d.cronop_elem_code2,d.cronop_elem_code3) cronop_bozza,  
    (select t_cronop.cronop_id, 
    max(t_cronop.data_creazione) max_data_creazione
    from siac_t_cronop t_cronop, 
    	siac_t_bil t_bil, siac_t_periodo t_periodo,
        siac_t_programma t_programma
    where t_cronop.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
        and t_programma.programma_id= t_cronop.programma_id
        and t_cronop.ente_proprietario_id=p_ente_prop_id
        and t_periodo.anno=p_anno
        and t_cronop.usato_per_fpv::boolean=false
        and t_cronop.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL
       and t_programma.programma_id not in (
        	select r_movgest_ts_programma.programma_id
            	from siac_r_movgest_ts_programma r_movgest_ts_programma
            	where r_movgest_ts_programma.ente_proprietario_id=p_ente_prop_id
                	and r_movgest_ts_programma.data_cancellazione IS NULL
                    and r_movgest_ts_programma.validita_fine IS NULL)
    group by t_cronop.cronop_id
   order by max_data_creazione DESC
   limit 1) id_cronop_bozza 
where id_cronop_bozza.cronop_id =  cronop_bozza.cronop_id ),
exist_last_versione as (select count(*) last_version
    from siac_t_cronop t_cronop, 
    	siac_t_bil t_bil, siac_t_periodo t_periodo
    where t_cronop.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
        and t_cronop.ente_proprietario_id=p_ente_prop_id
        and t_periodo.anno=p_anno
        and t_cronop.usato_per_fpv::boolean=true
        and t_cronop.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL)               
select 
p_anno::varchar  bil_anno ,
''::varchar  missione_tipo_code ,
strut_bilancio.missione_tipo_desc ,
strut_bilancio.missione_code ,
strut_bilancio.missione_desc ,
''::varchar programma_tipo_code ,
strut_bilancio.programma_tipo_desc ,
strut_bilancio.programma_code ,
strut_bilancio.programma_desc ,
capitoli_fpv.elem_id::integer elem_id_fpv,
capitoli_fpv.elem_code::varchar bil_ele_code_fpv,
capitoli_fpv.elem_desc::varchar bil_ele_desc_fpv,
capitoli_fpv.elem_code2::varchar bil_ele_code2_fpv,
capitoli_fpv.elem_desc2::varchar bil_ele_desc2_fpv,
capitoli_std.elem_id::integer elem_id_std,
capitoli_std.elem_code::varchar bil_ele_code_std,
capitoli_std.elem_desc::varchar bil_ele_desc_std,
capitoli_std.elem_code2::varchar bil_ele_code2_std,
capitoli_std.elem_desc2::varchar bil_ele_desc2_std,
capitoli_std.elem_code3::varchar bil_ele_code3_std,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,0) +
	COALESCE(fpv_variaz_anno_prec.importo_var,0)::numeric fondo_plur_anno_prec_a,
COALESCE(importi_anni_prec.spese_impe_anni_prec,0)::numeric spese_impe_anni_prec_b,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,0) -
	COALESCE(importi_anni_prec.spese_impe_anni_prec,0) -
    COALESCE(riaccert_colonna_x.riacc_colonna_x,0) -
    COALESCE(riaccert_colonna_y.riacc_colonna_y,0)::numeric quota_fond_plur_anni_prec_c,
COALESCE(impegni_anno1_d.spese_da_impeg_anno1_d,0)::numeric spese_da_impeg_anno1_d,
COALESCE(impegni_anno2_e.spese_da_impeg_anno2_e,0)::numeric spese_da_impeg_anno2_e,
COALESCE(impegni_annisucc_f.spese_da_impeg_anni_succ_f,0)::numeric spese_da_impeg_anni_succ_f,
COALESCE(riaccert_colonna_x.riacc_colonna_x,0)::numeric riacc_colonna_x,
COALESCE(riaccert_colonna_y.riacc_colonna_y,0)::numeric riacc_colonna_y,
COALESCE(impegni_anno1_d.spese_da_impeg_anno1_d,0) +
	COALESCE(impegni_anno2_e.spese_da_impeg_anno2_e,0) +
    COALESCE(impegni_annisucc_f.spese_da_impeg_anni_succ_f,0)::numeric fondo_plur_anno_g,
COALESCE(fpv_stanziamento_anno.importo_fpv_stanz_anno,0)::numeric fpv_stanziato_anno,
	--se NON esiste una versione con "usato_per_fpv" = true prendo i dati di
    --cronoprogramma in BOZZA, altrimenti quelli della versione approvata.
CASE WHEN exist_last_versione.last_version = 0
	THEN COALESCE(cronoprogrammi_bozza.importo_crono,0)
    ELSE COALESCE(cronoprogrammi_fpv.importo_crono,0) end ::numeric imp_cronoprogramma
from strut_bilancio
left JOIN capitoli_fpv on (strut_bilancio.programma_id = capitoli_fpv.programma_id
			AND strut_bilancio.macroag_id = capitoli_fpv.macroaggregato_id)
left join capitoli_std
	on capitoli_fpv.elem_id_std = capitoli_std.elem_id            
left join fpv_anno_prec_da_capitoli
	on (capitoli_fpv.elem_code=fpv_anno_prec_da_capitoli.elem_code
    	AND capitoli_fpv.elem_code2=fpv_anno_prec_da_capitoli.elem_code2
        AND capitoli_fpv.elem_code3=fpv_anno_prec_da_capitoli.elem_code3)   
left join fpv_variaz_anno_prec 
	on (capitoli_fpv.elem_code=fpv_variaz_anno_prec.elem_code
    	AND capitoli_fpv.elem_code2=fpv_variaz_anno_prec.elem_code2
        AND capitoli_fpv.elem_code3=fpv_variaz_anno_prec.elem_code3)   
        --27/05/2019: SIAC-6849.   
        -- gli importi delle colonne a, b, x, y, c, d, e, f
        -- dipendono dai capitoli STD e non da quelli FPV.  
left join importi_anni_prec 
	on capitoli_std.elem_id = importi_anni_prec.elem_id 
left join riaccert_colonna_x
	on capitoli_std.elem_id = riaccert_colonna_x. elem_id
left join riaccert_colonna_y
	on capitoli_std.elem_id = riaccert_colonna_y.elem_id
left join impegni_anno1_d
	on capitoli_fpv.elem_id = impegni_anno1_d.elem_id
left join impegni_anno2_e
	on capitoli_fpv.elem_id = impegni_anno2_e.elem_id
left join impegni_annisucc_f
	on capitoli_fpv.elem_id = impegni_annisucc_f.elem_id 
    	--lo stanziato FPV e' legato ai capitoli FPV.
left join fpv_stanziamento_anno
	on capitoli_fpv.elem_id = fpv_stanziamento_anno.elem_id
left join cronoprogrammi_fpv
    on (capitoli_fpv.elem_code=cronoprogrammi_fpv.cronop_elem_code
    	AND capitoli_fpv.elem_code2=cronoprogrammi_fpv.cronop_elem_code2
        AND capitoli_fpv.elem_code3=cronoprogrammi_fpv.cronop_elem_code3)
left join cronoprogrammi_bozza
    on (capitoli_fpv.elem_code=cronoprogrammi_bozza.cronop_elem_code
    	AND capitoli_fpv.elem_code2=cronoprogrammi_bozza.cronop_elem_code2
        AND capitoli_fpv.elem_code3=cronoprogrammi_bozza.cronop_elem_code3),
exist_last_versione        ;            
raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='struttura bilancio altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;