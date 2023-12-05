/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR011_Allegato_B_Fondo_Pluriennale_vincolato" (
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
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  spese_da_impeg_non_def_g numeric,
  fondo_plur_anno_h numeric,
  spese_da_impeg_anno1_d2 numeric
) AS
$body$
DECLARE

classifBilRec record;
impegniPrecRec record;

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
bilancio_id_prec integer;

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
    BILR011_allegato_fpv_previsione_con_dati_gestione (ex BILR171).
*/

/* 25/01/2023: revisione per SIAC-8866.
 La funzione e' stata in parte semplificata perche' erano eseguite piu' volte le stesse query.
 Inoltre sono state introdotte le modifiche richieste nelle jira SIAC-8866 per le colonne D, E, F.


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

select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,
	siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno::integer = (p_anno::integer - 1)
 and a.data_cancellazione IS NULL
 and b.data_cancellazione IS NULL;

raise notice 'id_bil di anno % = %', p_anno, id_bil;
raise notice 'id_bil di anno precedente % = %', (p_anno::integer - 1), bilancio_id_prec;

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
        COALESCE(SUM(importi_capitoli_anno1.stanziamento_fpv_anno1),0) stanziamento_fpv_anno1,
        COALESCE(SUM(importi_capitoli_anno2.stanziamento_fpv_anno2),0) stanziamento_fpv_anno2,
        COALESCE(SUM(importi_capitoli_anno3.stanziamento_fpv_anno3),0) stanziamento_fpv_anno3,
        0 fondo_pluri_anno_prec
    from  strutt_capitoli 
        left join capitoli 
            on (capitoli.programma_id = strutt_capitoli.programma_id
                AND capitoli.macroag_id = strutt_capitoli.macroag_id)          
        left join importi_capitoli_anno1
            on importi_capitoli_anno1.elem_id = capitoli.elem_id
        left join importi_capitoli_anno2
            on importi_capitoli_anno2.elem_id = capitoli.elem_id
        left join importi_capitoli_anno3
            on importi_capitoli_anno3.elem_id = capitoli.elem_id
--27/12/2021 SIAC-8508
-- Occorre eliminare le missioni '20', '50', '60', '99'.             
    where strutt_capitoli.missione_code not in('20', '50', '60', '99')
    group by strutt_capitoli.missione_tipo_desc, strutt_capitoli.missione_code, 
    	strutt_capitoli.missione_desc, strutt_capitoli.programma_tipo_desc, 
        strutt_capitoli.programma_code, strutt_capitoli.programma_desc
loop
	missione_tipo_desc:= classifBilRec.missione_tipo_desc;
    missione_code:= classifBilRec.missione_code;
    missione_desc:= classifBilRec.missione_desc;
    programma_tipo_desc:= classifBilRec.programma_tipo_desc;
    programma_code:= classifBilRec.programma_code;
    programma_desc:= classifBilRec.programma_desc;

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
        
        /* 3.	Colonna (c) – e' data dalla differenza tra la colonna b e la colonna a genera e
        rappresenta il valore del fondo costituito che verra' utilizzato negli anni 2018 e seguenti; */
        quota_fond_plur_anni_prec_c=fondo_plur_anno_prec_a-spese_impe_anni_prec_b ;  
       -- raise notice 'quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;  
        
        /*
        Colonna D – Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata = anno Prospetto e anno di spesa uguale a anno Prospetto+1.
        25/01/2023 SIAC-8866: i progetti devono essere solo quelli di Previsione.
        */
        
         
          select COALESCE(sum(cronop_elem_det.cronop_elem_det_importo),0) 
          	into spese_da_impeg_anno1_d
          from siac_t_programma progetto, siac_t_cronop crono, 
              siac_t_bil bil, siac_t_periodo anno_bil, siac_d_programma_tipo tipo_prog,
              siac_t_cronop_elem cronop_elem, siac_d_bil_elem_tipo tipo_cap,
              siac_t_cronop_elem_det cronop_elem_det, siac_t_periodo anno_crono, 
              siac_r_cronop_elem_class r_cronop_elem_class, siac_d_class_tipo d_class_tipo, siac_t_class class,
              siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
              siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato
          where progetto.programma_id=crono.programma_id
              and crono.bil_id = bil.bil_id
              and bil.periodo_id=anno_bil.periodo_id
              and tipo_prog.programma_tipo_id = progetto.programma_tipo_id
              and cronop_elem.cronop_id=crono.cronop_id
              and cronop_elem.cronop_elem_id=cronop_elem_det.cronop_elem_id
              and tipo_cap.elem_tipo_id=cronop_elem.elem_tipo_id
              and cronop_elem_det.periodo_id = anno_crono.periodo_id
              and r_cronop_elem_class.cronop_elem_id = cronop_elem.cronop_elem_id
              and r_cronop_elem_class.classif_id=class.classif_id
              and class.classif_tipo_id=d_class_tipo.classif_tipo_id
              and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
              and r_cronop_stato.cronop_id=crono.cronop_id
              and r_progetto_stato.programma_id=progetto.programma_id
              and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id              
              and progetto.ente_proprietario_id= p_ente_prop_id
              and anno_bil.anno=p_anno -- anno bilancio
              and crono.usato_per_fpv::boolean = conflagfpv              
              and cronop_elem_det.anno_entrata = p_anno_prospetto -- anno prospetto               
              and anno_crono.anno::integer=p_anno_prospetto::integer+1  -- anno prospetto + 1              
              and d_class_tipo.classif_tipo_code='PROGRAMMA'
              and class.classif_code=classifBilRec.programma_code                            
              and cronop_stato.cronop_stato_code='VA'   
              and tipo_prog.programma_tipo_code ='P'  --Solo progetti della previsione.             
              and progetto_stato.programma_stato_code='VA'
              and r_progetto_stato.data_cancellazione is null
              and r_cronop_stato.data_cancellazione is null
              and crono.data_cancellazione is null
              and progetto.data_cancellazione is null
              and bil.data_cancellazione is null
              and anno_bil.data_cancellazione is null
              and cronop_elem.data_cancellazione is null
              and cronop_elem_det.data_cancellazione is null
              and r_cronop_elem_class.data_cancellazione is null;
             -- raise notice 'Query 3: Progr: % - campo D dopo = %', classifBilRec.programma_code,spese_da_impeg_anno1_d;
        
        raise notice 'Programma % - spese_da_impeg_anno1_d da progetti = %', classifBilRec.programma_code ,
        	spese_da_impeg_anno1_d;
        
        /*
        Colonna E - Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata = anno Prospetto e anno di spesa uguale a anno Prospetto+2.
        25/01/2023 SIAC-8866: i progetti devono essere solo quelli di Previsione.
        */
          select COALESCE(sum(cronop_elem_det.cronop_elem_det_importo),0) 
          	into spese_da_impeg_anno2_e
          from siac_t_programma progetto, siac_t_cronop crono, 
              siac_t_bil bil, siac_t_periodo anno_bil, siac_d_programma_tipo tipo_prog,
              siac_t_cronop_elem cronop_elem, siac_d_bil_elem_tipo tipo_cap,
              siac_t_cronop_elem_det cronop_elem_det, siac_t_periodo anno_crono, 
              siac_r_cronop_elem_class r_cronop_elem_class, siac_d_class_tipo d_class_tipo, siac_t_class class,
              siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
              siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato
          where progetto.programma_id=crono.programma_id
              and crono.bil_id = bil.bil_id
              and bil.periodo_id=anno_bil.periodo_id
              and tipo_prog.programma_tipo_id = progetto.programma_tipo_id
              and cronop_elem.cronop_id=crono.cronop_id
              and cronop_elem.cronop_elem_id=cronop_elem_det.cronop_elem_id
              and tipo_cap.elem_tipo_id=cronop_elem.elem_tipo_id
              and cronop_elem_det.periodo_id = anno_crono.periodo_id
              and r_cronop_elem_class.cronop_elem_id = cronop_elem.cronop_elem_id
              and r_cronop_elem_class.classif_id=class.classif_id
              and class.classif_tipo_id=d_class_tipo.classif_tipo_id
              and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
              and r_cronop_stato.cronop_id=crono.cronop_id
              and r_progetto_stato.programma_id=progetto.programma_id
              and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id              
              and progetto.ente_proprietario_id= p_ente_prop_id
              and anno_bil.anno=p_anno -- anno bilancio
              and crono.usato_per_fpv::boolean = conflagfpv              
              and cronop_elem_det.anno_entrata = p_anno_prospetto -- anno prospetto               
              and anno_crono.anno::integer=p_anno_prospetto::integer+2 -- anno prospetto + 2        
              and d_class_tipo.classif_tipo_code='PROGRAMMA'
              and class.classif_code=classifBilRec.programma_code                            
              and cronop_stato.cronop_stato_code='VA'   
              and tipo_prog.programma_tipo_code ='P'  --Solo progetti della previsione.             
              and progetto_stato.programma_stato_code='VA'
              and r_progetto_stato.data_cancellazione is null
              and r_cronop_stato.data_cancellazione is null
              and crono.data_cancellazione is null
              and progetto.data_cancellazione is null
              and bil.data_cancellazione is null
              and anno_bil.data_cancellazione is null
              and cronop_elem.data_cancellazione is null
              and cronop_elem_det.data_cancellazione is null
              and r_cronop_elem_class.data_cancellazione is null;
              
        
        
        /* Colonna F - Occorre prendere tutte le quote di 
        spesa previste nei cronoprogrammi con FPV selezionato, 
         con FPV selezionato, con anno di entrata = anno Prospetto e anno di spesa > anno Prospetto+2.
         25/01/2023 SIAC-8866: i progetti devono essere solo quelli di Previsione.
         */
         
          select COALESCE(sum(cronop_elem_det.cronop_elem_det_importo),0) 
          	into spese_da_impeg_anni_succ_f
          from siac_t_programma progetto, siac_t_cronop crono, 
              siac_t_bil bil, siac_t_periodo anno_bil, siac_d_programma_tipo tipo_prog,
              siac_t_cronop_elem cronop_elem, siac_d_bil_elem_tipo tipo_cap,
              siac_t_cronop_elem_det cronop_elem_det, siac_t_periodo anno_crono, 
              siac_r_cronop_elem_class r_cronop_elem_class, siac_d_class_tipo d_class_tipo, siac_t_class class,
              siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
              siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato
          where progetto.programma_id=crono.programma_id
              and crono.bil_id = bil.bil_id
              and bil.periodo_id=anno_bil.periodo_id
              and tipo_prog.programma_tipo_id = progetto.programma_tipo_id
              and cronop_elem.cronop_id=crono.cronop_id
              and cronop_elem.cronop_elem_id=cronop_elem_det.cronop_elem_id
              and tipo_cap.elem_tipo_id=cronop_elem.elem_tipo_id
              and cronop_elem_det.periodo_id = anno_crono.periodo_id
              and r_cronop_elem_class.cronop_elem_id = cronop_elem.cronop_elem_id
              and r_cronop_elem_class.classif_id=class.classif_id
              and class.classif_tipo_id=d_class_tipo.classif_tipo_id
              and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
              and r_cronop_stato.cronop_id=crono.cronop_id
              and r_progetto_stato.programma_id=progetto.programma_id
              and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id              
              and progetto.ente_proprietario_id= p_ente_prop_id
              and anno_bil.anno=p_anno -- anno bilancio
              and crono.usato_per_fpv::boolean = conflagfpv              
              and cronop_elem_det.anno_entrata = p_anno_prospetto -- anno prospetto               
              and anno_crono.anno::integer > p_anno_prospetto::integer+2 -- maggiore di anno prospetto + 2       
              and d_class_tipo.classif_tipo_code='PROGRAMMA'
              and class.classif_code=classifBilRec.programma_code                            
              and cronop_stato.cronop_stato_code='VA'   
              and tipo_prog.programma_tipo_code ='P'  --Solo progetti della previsione.             
              and progetto_stato.programma_stato_code='VA'
              and r_progetto_stato.data_cancellazione is null
              and r_cronop_stato.data_cancellazione is null
              and crono.data_cancellazione is null
              and progetto.data_cancellazione is null
              and bil.data_cancellazione is null
              and anno_bil.data_cancellazione is null
              and cronop_elem.data_cancellazione is null
              and cronop_elem_det.data_cancellazione is null
              and r_cronop_elem_class.data_cancellazione is null;
                            
          
        
        
        /*5.	La colonna h  e' la somma dalla colonna c alla colonna g.
        		In realta' NON e' piu' calcolata in questa procedura. */
        

        fondo_plur_anno_h=quota_fond_plur_anni_prec_c+spese_da_impeg_anno1_d+
            spese_da_impeg_anno2_e+spese_da_impeg_anni_succ_f+spese_da_impeg_non_def_g;
    
/*raise notice 'programma_codeXXX = %', programma_code;
raise notice '  spese_impe_anni_prec_b = %', spese_impe_anni_prec_b;
raise notice '  quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;
raise notice '  spese_da_impeg_anno1_d = %', spese_da_impeg_anno1_d;
raise notice '  spese_da_impeg_anno2_e = %', spese_da_impeg_anno2_e;
raise notice '  spese_da_impeg_anni_succ_f = %', spese_da_impeg_anni_succ_f;
raise notice '  spese_da_impeg_non_def_g = %', spese_da_impeg_non_def_g;*/
    
/* 25/01/2023 SIAC-8866.
	Occorre estrarre dalla gestione anno precedente l'anno del bilancio gli importi degli impegni secondo la seguente logica:
  - Colonna D
      Impegni anno = Anno di Prospetto+1 con vincolo ad Accertamento = Anno di Prospetto
  - Colonna E
      Impegni anno = Anno di Prospetto+2 con vincolo ad Accertamento = Anno di Prospetto
  - Colonna F
      Impegni anno > Anno di Prospetto+2 con vincolo ad Accertamento = Anno di Prospetto

Gli impegni estratti NON devono essere legati a progetti con cronoprogemmi con vincolo per FPV perche'
tali impegni sono giaì stati calcolati nelle query precedenti.

Gli importi estratti sono sommati a quelli delle query precedenti relativi agli impegni legati ai progetti.

*/
--raise notice 'bilancio_id_prec = %', bilancio_id_prec;
for impegniPrecRec in
    with struttura as (
    select *
    from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,(p_anno::integer - 1)::varchar, null)
    ),
    capitoli as (
    select 	programma.classif_id programma_id,
            macroaggr.classif_id macroaggregato_id,
            capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
            capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
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
    where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
    and capitolo.elem_id = r_capitolo_stato.elem_id							
    and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
    and	capitolo.elem_id = r_capitolo_programma.elem_id							
    and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
    and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
    and programma.classif_id = r_capitolo_programma.classif_id					
    and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
    and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
    and	capitolo.elem_id = r_cat_capitolo.elem_id				
    and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
    and capitolo.ente_proprietario_id = p_ente_prop_id							
    and capitolo.bil_id = bilancio_id_prec --anno precedente													
    and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
    and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
    and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
    and stato_capitolo.elem_stato_code = 'VA' 
    -- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
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
    and	r_cat_capitolo.data_cancellazione           is null
    ),
    impegni as(
    select distinct accert.*, imp.*, ts_impegni_legati.movgest_ts_b_id
    from siac_r_movgest_ts ts_impegni_legati    	
         join (	--accertamenti
         		select ts_mov_acc.movgest_ts_id,
                        mov_acc.movgest_anno anno_acc, 
                        mov_acc.movgest_numero numero_acc,
                        ts_mov_det_acc.movgest_ts_det_importo importo_acc
                    from siac_t_movgest mov_acc,
                         siac_t_movgest_ts ts_mov_acc,					
                         siac_t_movgest_ts_det ts_mov_det_acc,
                         siac_r_movgest_ts_stato r_stato_acc,
                         siac_d_movgest_stato stato_acc
                    where mov_acc.movgest_id=ts_mov_acc.movgest_id
                        and ts_mov_acc.movgest_ts_id=ts_mov_det_acc.movgest_ts_id
                        and ts_mov_acc.movgest_ts_id=r_stato_acc.movgest_ts_id
                        and r_stato_acc.movgest_stato_id=stato_acc.movgest_stato_id
                        and mov_acc.ente_proprietario_id=p_ente_prop_id
                        and mov_acc.movgest_anno = annoProspInt --accertamenti sempre dell'anno prospetto
                        and stato_acc.movgest_stato_code in ('D','N')
                        and r_stato_acc.data_cancellazione IS NULL
                        and mov_acc.data_cancellazione IS NULL
                        and ts_mov_acc.data_cancellazione IS NULL) accert
            on accert.movgest_ts_id =  ts_impegni_legati.movgest_ts_a_id
          join (--impegni
          		select ts_mov_imp.movgest_ts_id,
                        mov_imp.movgest_anno anno_imp, 
                        mov_imp.movgest_numero numero_imp,
                        r_imp_bil_elem.elem_id,
                        ts_mov_det_imp.movgest_ts_det_importo importo_imp
                    from siac_t_movgest mov_imp,
                         siac_t_movgest_ts ts_mov_imp,					
                         siac_t_movgest_ts_det ts_mov_det_imp,
                         siac_r_movgest_ts_stato r_stato_imp,
                         siac_d_movgest_stato stato_imp,
                         siac_r_movgest_bil_elem r_imp_bil_elem
                    where mov_imp.movgest_id=ts_mov_imp.movgest_id
                        and ts_mov_imp.movgest_ts_id=ts_mov_det_imp.movgest_ts_id
                        and ts_mov_imp.movgest_ts_id=r_stato_imp.movgest_ts_id
                        and r_stato_imp.movgest_stato_id=stato_imp.movgest_stato_id
                        and r_imp_bil_elem.movgest_id=mov_imp.movgest_id
                        and mov_imp.ente_proprietario_id=p_ente_prop_id
                        and mov_imp.bil_id = bilancio_id_prec --anno precedente di gestione
                        and mov_imp.movgest_anno >= annoProspInt + 1 --impegni a partire dell'anno prospetto + 1
                        and stato_imp.movgest_stato_code in ('D','N')
                        and r_stato_imp.data_cancellazione IS NULL
                        and mov_imp.data_cancellazione IS NULL
                        and ts_mov_imp.data_cancellazione IS NULL
                        and r_imp_bil_elem.data_cancellazione IS NULL) imp              
            on imp.movgest_ts_id =  ts_impegni_legati.movgest_ts_b_id
          left join (--legame con i progetti 
          		select r_mov_progr.movgest_ts_id, progetto.programma_id
                  from siac_t_programma progetto, siac_t_cronop crono, 
                      siac_t_bil bil, siac_t_periodo anno_bil,
                      siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
                      siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato,
                     siac_r_movgest_ts_programma r_mov_progr             
                  where progetto.programma_id=crono.programma_id
                      and crono.bil_id = bil.bil_id
                      and bil.periodo_id=anno_bil.periodo_id
                      and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
                      and r_cronop_stato.cronop_id=crono.cronop_id
                      and r_progetto_stato.programma_id=progetto.programma_id
                      and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id     
                      and r_mov_progr.programma_id=progetto.programma_id                      
                      and progetto.ente_proprietario_id= p_ente_prop_id
                      and anno_bil.anno::integer=annoBilInt - 1 -- anno precedente quello del bilancio?
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null) progetti
             on ts_impegni_legati.movgest_ts_b_id = progetti.movgest_ts_id
    where ts_impegni_legati.ente_proprietario_id=p_ente_prop_id      
        and ts_impegni_legati.avav_id is null
        and ts_impegni_legati.data_cancellazione is null  
        	--progetti.programma_id IS NULL cioe' non sono compresi negli impegni legati ai progetti estratti
            --nelle query precedenti. In pratica non devo contarli 2 volte.
        and progetti.programma_id IS NULL )
    select --struttura.programma_code::varchar programma,
        anno_imp anno_impegno,
        sum(impegni.importo_imp) importo_impegni
    from impegni
        left join capitoli 
            on impegni.elem_id=capitoli.elem_id 
        left join struttura 
            on struttura.programma_id = capitoli.programma_id
                and struttura.macroag_id = capitoli.macroaggregato_id        
    where struttura.programma_code = classifBilRec.programma_code
    group by anno_impegno
loop
	--raise notice 'anno impegno = % - progetto = %', impegniPrecRec.anno_impegno, impegniPrecRec;
	case impegniPrecRec.anno_impegno
    	when annoProspInt +1 then
    		raise notice '% = Anno % - importo %',classifBilRec.programma_code,annoProspInt +1, impegniPrecRec.importo_impegni;
            spese_da_impeg_anno1_d:= spese_da_impeg_anno1_d + impegniPrecRec.importo_impegni;
            spese_da_impeg_anno1_d2:=impegniPrecRec.importo_impegni;
      	when annoProspInt +2 then
    		raise notice '% = Anno % - importo %',classifBilRec.programma_code, annoProspInt +2, impegniPrecRec.importo_impegni;
            spese_da_impeg_anno2_e:= spese_da_impeg_anno2_e + impegniPrecRec.importo_impegni;
	 	else -->  > annoProspInt +2 then
    		raise notice '% = Anno > % - importo %',classifBilRec.programma_code, annoProspInt +2, impegniPrecRec.importo_impegni;
            spese_da_impeg_anni_succ_f:= spese_da_impeg_anni_succ_f + impegniPrecRec.importo_impegni;
    end case;
end loop;

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
  spese_da_impeg_anno1_d2:=0;
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR011_Allegato_B_Fondo_Pluriennale_vincolato" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;