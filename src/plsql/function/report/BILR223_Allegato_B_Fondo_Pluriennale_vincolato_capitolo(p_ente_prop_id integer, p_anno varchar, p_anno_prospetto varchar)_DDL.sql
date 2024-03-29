/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR223_Allegato_B_Fondo_Pluriennale_vincolato_capitolo" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
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
  bil_elem_code varchar,
  bil_elem_desc varchar,
  bil_elem_code2 varchar,
  bil_elem_desc2 varchar,
  bil_elem_code3 varchar,
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  spese_da_impeg_non_def_g numeric,
  fondo_plur_anno_h numeric
) AS
$body$
DECLARE

classifBilRec record;


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

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
conflagfpv:=TRUE;
a_dacapfpv:=false;
h_dacapfpv:=false;
flagretrocomp:=false;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione


annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
annoProspInt=p_anno_prospetto::INTEGER;
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

fondo_plur_anno_prec_a=0;
spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
spese_da_impeg_non_def_g=0;
fondo_plur_anno_h=0;

/* 08/03/2019: revisione per SIAC-6623 
	I campi fondo_plur_anno_prec_a, spese_impe_anni_prec_b, quota_fond_plur_anni_prec_c e
    fondo_plur_anno_h anche se valorizzati non sono utilizzati dal report perche'
    prende quelli di gestione calcolati tramite la funzione 
    BILR223_allegato_fpv_previsione_dati_gestione_capitolo che e' una copia di 
    BILR011_allegato_fpv_previsione_con_dati_gestione (ex BILR171).
*/

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

for classifBilRec in
	with strutt_capitoli as (select *
		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
	capitoli as (select programma.classif_id programma_id,
		macroaggr.classif_id macroag_id,
       	capitolo.*
	from siac_d_class_tipo programma_tipo,
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
	where macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    	macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    	programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    	programma.classif_id=r_capitolo_programma.classif_id					and    		       
    	capitolo.elem_id=r_capitolo_programma.elem_id							and
    	capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
   		capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    	capitolo.elem_id				=	r_capitolo_stato.elem_id			and
		r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
    	capitolo.elem_id				=	r_cat_capitolo.elem_id				and
		r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
        capitolo.ente_proprietario_id=p_ente_prop_id      						and
        capitolo.bil_id= id_bil													and   	
    	tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    	programma_tipo.classif_tipo_code='PROGRAMMA' 							and	        
		stato_capitolo.elem_stato_code	=	'VA'								and    
			--04/08/2016: aggiunto FPVC 
		cat_del_capitolo.elem_cat_code	in	('FPV','FPVC')								
    	and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
		and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
      	and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
        and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
        and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
        and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())        
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
    importi_capitoli_anno1 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno1      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,                 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where 	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp --p_anno       		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null            
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
            capitolo_imp_periodo.anno),
	importi_capitoli_anno2 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno2      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where  	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id            
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and	capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp1 --p_anno +1      		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    		capitolo_imp_periodo.anno),
    importi_capitoli_anno3 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno3      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,                 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where 	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp2 --p_anno +2      		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
            capitolo_imp_periodo.anno)           
    select strutt_capitoli.missione_tipo_desc			missione_tipo_desc,
		strutt_capitoli.missione_code				missione_code,
		strutt_capitoli.missione_desc				missione_desc,
		strutt_capitoli.programma_tipo_desc			programma_tipo_desc,
		strutt_capitoli.programma_code				programma_code,
		strutt_capitoli.programma_desc				programma_desc,
        capitoli.elem_code							elem_code, 
        capitoli.elem_desc							elem_desc, 
        capitoli.elem_code2							elem_code2,
        capitoli.elem_desc2							elem_desc2, 
        capitoli.elem_code3							elem_code3,
        capitoli.elem_id							elem_id,
        COALESCE(SUM(importi_capitoli_anno1.stanziamento_fpv_anno1),0) stanziamento_fpv_anno1,
        COALESCE(SUM(importi_capitoli_anno2.stanziamento_fpv_anno2),0) stanziamento_fpv_anno2,
        COALESCE(SUM(importi_capitoli_anno3.stanziamento_fpv_anno3),0) stanziamento_fpv_anno3,
        0 fondo_pluri_anno_prec
    from  strutt_capitoli 
        full join capitoli 
            on (capitoli.programma_id = strutt_capitoli.programma_id
                AND capitoli.macroag_id = strutt_capitoli.macroag_id)          
        left join importi_capitoli_anno1
            on importi_capitoli_anno1.elem_id = capitoli.elem_id
        left join importi_capitoli_anno2
            on importi_capitoli_anno2.elem_id = capitoli.elem_id
        left join importi_capitoli_anno3
            on importi_capitoli_anno3.elem_id = capitoli.elem_id
    group by strutt_capitoli.missione_tipo_desc, strutt_capitoli.missione_code, 
    	strutt_capitoli.missione_desc, strutt_capitoli.programma_tipo_desc, 
        strutt_capitoli.programma_code, strutt_capitoli.programma_desc,
        capitoli.elem_code, capitoli.elem_desc , capitoli.elem_code2 ,
        capitoli.elem_desc2 , capitoli.elem_code3, capitoli.elem_id
loop
	missione_tipo_desc:= classifBilRec.missione_tipo_desc;
    missione_code:= classifBilRec.missione_code;
    missione_desc:= classifBilRec.missione_desc;
    programma_tipo_desc:= classifBilRec.programma_tipo_desc;
    programma_code:= classifBilRec.programma_code;
    programma_desc:= classifBilRec.programma_desc;
  	bil_elem_code:=  classifBilRec.elem_code;
  	bil_elem_desc:=  classifBilRec.elem_desc;
  	bil_elem_code2:=  classifBilRec.elem_code2;
  	bil_elem_desc2:=  classifBilRec.elem_desc2;
  	bil_elem_code3:=  classifBilRec.elem_code3;
    
    bil_anno:=p_anno;
    
    if annoProspInt = annoBilInt then
		fondo_plur_anno_prec_a=classifBilRec.fondo_pluri_anno_prec;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno1;
   	elsif  annoProspInt = annoBilInt+1 and a_dacapfpv=true then
    	fondo_plur_anno_prec_a=classifBilRec.stanziamento_fpv_anno1;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno2;
    elsif  annoProspInt = annoBilInt+2 and a_dacapfpv=true then
    	fondo_plur_anno_prec_a=classifBilRec.stanziamento_fpv_anno2;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno3;
    end if;      
    
    if  annoProspInt > annoBilInt and a_dacapfpv=false and flagretrocomp=false then

			--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
	      spese_impe_anni_prec_b=0;
           
        /*  select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer-1 -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno= (p_anno_prospetto::integer-1)::varchar -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;		*/
       	    
          spese_da_impeg_anno1_d=0;
        
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = (p_anno_prospetto::integer -1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anno2_e=0;  
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e  
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          --siac_r_cronop_elem_class rcl1, siac_d_class_tipo clt1,siac_t_class cl1, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::integer-1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+1 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anni_succ_f=0;
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::INTEGER-1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER+1 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;


        if  annoProspInt = annoBilInt+1 then
          	fondo_plur_anno_prec_a=classifBilRec.fondo_pluri_anno_prec - spese_impe_anni_prec_b +
            spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;
          	raise notice 'Anno prospetto = %',annoProspInt;
            
        elsif  annoProspInt = annoBilInt+2  then
          fondo_plur_anno_prec_a= - spese_impe_anni_prec_b +
          spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;
          	
          spese_impe_anni_prec_b=0;
            --il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
         /* select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer-2 -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno= (p_anno_prospetto::integer-2)::varchar -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;		*/
       	    
          spese_da_impeg_anno1_d=0;
        
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = (p_anno_prospetto::integer -2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer-1  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anno2_e=0;  
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e  
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::integer-2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3          
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anni_succ_f=0;
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::INTEGER-2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3          
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
          --and rcl1.data_cancellazione is null

		fondo_plur_anno_prec_a=fondo_plur_anno_prec_a+classifBilRec.fondo_pluri_anno_prec - spese_impe_anni_prec_b +
            spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;            
            
        end if; --if annoProspInt = annoBilInt+1 then 

       end if; -- if  annoProspInt > annoBilInt

/*raise notice 'programma_code = %', programma_code;
raise notice '  spese_impe_anni_prec_b = %', spese_impe_anni_prec_b;
raise notice '  quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;
raise notice '  spese_da_impeg_anno1_d = %', spese_da_impeg_anno1_d;
raise notice '  spese_da_impeg_anno2_e = %', spese_da_impeg_anno2_e;
raise notice '  spese_da_impeg_anni_succ_f = %', spese_da_impeg_anni_succ_f;
raise notice '  spese_da_impeg_non_def_g = %', spese_da_impeg_non_def_g;
*/

/* 17/05/2016: al momento questi campi sono impostati a zero in attesa di
	capire le modalita' di valorizzazione */
		spese_impe_anni_prec_b=0;
        quota_fond_plur_anni_prec_c=0;
        spese_da_impeg_anno1_d=0;
        spese_da_impeg_anno2_e=0;  
        spese_da_impeg_anni_succ_f=0;
        spese_da_impeg_non_def_g=0;
        
        /*COLONNA B -Spese impegnate negli anni precedenti con copertura costituita dal FPV e imputate all�esercizio N
		Occorre prendere tutte le quote di spesa previste nei cronoprogrammi con FPV selezionato, 
		con anno di entrata 2016 (o precedenti) e anno di spesa uguale al 2017.*/ 
       if flagretrocomp = false then
	   		--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
            
          /*select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno=p_anno_prospetto -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;*/
          
         -- raise notice 'spese_impe_anni_prec_b %' , spese_impe_anni_prec_b; 
        
        /* 3.	Colonna (c) � e' data dalla differenza tra la colonna b e la colonna a genera e
        rappresenta il valore del fondo costituito che verra' utilizzato negli anni 2018 e seguenti; */
        quota_fond_plur_anni_prec_c=fondo_plur_anno_prec_a-spese_impe_anni_prec_b ;  
       -- raise notice 'quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;  
        
        /*
        Colonna d � Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata 2017 e anno di spesa uguale al 2018;
        */
          
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+1  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3          
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
          --and rcl1.data_cancellazione is null;
              
        
        /*
        Colonna e - Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata 2017 e anno di spesa uguale al 2019;
        */
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+2 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3          
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

        
        
        /* Colonna f - Occorre prendere tutte le quote di 
        spesa previste nei cronoprogrammi con FPV selezionato, 
        con anno di entrata 2017 e anno di spesa uguale al 2020 e successivi;*/
                          
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER+2 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and d.cronop_elem_code=classifBilRec.elem_code 
  		  and d.cronop_elem_code2=classifBilRec.elem_code2 
  		  and d.cronop_elem_code3=classifBilRec.elem_code3          
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
        
        /*
        d.	Colonna g � Occorre prendere l�importo previsto nella sezione spese dei progetti. 
        E� necessario quindi implementare una tipologia �Cronoprogramma da  definire�, 
        agganciato al progetto per il quale sono necessarie solo due informazioni: 
        l�importo e la Missione/Programma. Rimane incognito l�anno relativo alla spesa 
        (anche se apparira' formalmente agganciato al 2017). 
        Nel momento in cui saranno note le altre informazioni relative al progetto, 
        l�ente operera' nel modo consueto, ovvero inserendo una nuova versione di cronoprogramma 
        e selezionandone il relativo FPV. Operativamente e' sufficiente inserire un flag "Cronoprogramma da definire". 
        L'operatore entrera' comunque nelle due maschere (cosi' come sono ad oggi) di entrata e 
        spesa e inserira' l'importo e la spesa agganciandola a uno o piu' missioni per la spesa e analogamente per le entrate... 
        Inserira' 2017 sia nelle entrate che nella spesa. Essendo anno entrata=anno spesa non si creera' FPV 
        ma avendo il Flag "Cronoprogramma da Definire" l'unione delle due informazione generera' il 
        popolamento della colonna G. Questo escamotage peraltro potra' essere utilizzato anche dagli enti 
        che vorranno tracciare la loro 
        programmazione anche laddove non ci sia la generazione di FPV, ovviamente senza flaggare il campo citato.
        */
         
        
        /*5.	La colonna h  e' la somma dalla colonna c alla colonna g. 
        	NON e' piu' calcolata in questa procedura. */
        
    	if h_dacapfpv = false then
        	fondo_plur_anno_h=quota_fond_plur_anni_prec_c+spese_da_impeg_anno1_d+
            	spese_da_impeg_anno2_e+spese_da_impeg_anni_succ_f+spese_da_impeg_non_def_g;
        end if;
     end if; --if flagretrocomp = false then
    
/*raise notice 'programma_codeXXX = %', programma_code;
raise notice '  spese_impe_anni_prec_b = %', spese_impe_anni_prec_b;
raise notice '  quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;
raise notice '  spese_da_impeg_anno1_d = %', spese_da_impeg_anno1_d;
raise notice '  spese_da_impeg_anno2_e = %', spese_da_impeg_anno2_e;
raise notice '  spese_da_impeg_anni_succ_f = %', spese_da_impeg_anni_succ_f;
raise notice '  spese_da_impeg_non_def_g = %', spese_da_impeg_non_def_g;*/
    
  return next;

  bil_anno='';
  missione_tipo_code='';
  missione_tipo_desc='';
  missione_code='';
  missione_desc='';
  programma_tipo_code='';
  programma_tipo_desc='';
  programma_code='';
  programma_desc='';

  fondo_plur_anno_prec_a=0;
  spese_impe_anni_prec_b=0;
  quota_fond_plur_anni_prec_c=0;
  spese_da_impeg_anno1_d=0;
  spese_da_impeg_anno2_e=0;
  spese_da_impeg_anni_succ_f=0;
  spese_da_impeg_non_def_g=0;
  fondo_plur_anno_h=0;        
end loop;  

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