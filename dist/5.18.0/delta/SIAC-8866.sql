/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--SIAC-8866 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."BILR011_allegato_fpv_previsione_con_dati_gestione"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."fnc_lancio_BILR011_anni_precedenti_gestione"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);

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
  
CREATE OR REPLACE FUNCTION siac."BILR011_allegato_fpv_previsione_con_dati_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  importi_capitoli numeric,
  spese_impegnate numeric,
  spese_impegnate_anno1 numeric,
  spese_impegnate_anno2 numeric,
  spese_impegnate_anno_succ numeric,
  importo_avanzo numeric,
  importo_avanzo_anno1 numeric,
  importo_avanzo_anno2 numeric,
  importo_avanzo_anno_succ numeric,
  elem_id integer,
  anno_esercizio varchar,
  spese_impegnate_da_prev numeric
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id integer;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;
annoprospetto_int integer;
annoprospetto_prec_int integer;

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della BILR171_allegato_fpv_previsione_con_dati_gestione che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR011.
		Poiche' il report BILR171 viene eliminato la funzione 
        BILR171_allegato_fpv_previsione_con_dati_gestione e' superflua ma NON viene
        cancellata perche' serve per gli anni precedenti il 2018.
*/

/*Se la fase di bilancio e' Previsione allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno-1 per tutte le colonne. 

Se la fase di bilancio e' Esercizio Provvisorio allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno per tutte le colonne tranne quella relativa agli importi dei capitolo (colonna a).
In questo caso l''anno di esercizio e il bilancio id saranno quelli di p_anno-1.

L'anno relativo agli importi dei capitoli e' anno_esercizio_prec
L'anno relativo agli importi degli impegni e' annoImpImpegni_int*/


-- SIAC-6063
/*Aggiunto parametro p_anno_prospetto
Variabile annoImpImpegni_int sostituita da annoprospetto_int
Azzerati importi  spese_impegnate_anno1
                  spese_impegnate_anno2
                  spese_impegnate_anno_succ
                  importo_avanzo_anno1
                  importo_avanzo_anno2
                  importo_avanzo_anno_succ*/

RTN_MESSAGGIO := 'select 1'; 

bilancio_id := null;
bilancio_id_prec := null;

select bil.bil_id, fase_operativa.fase_operativa_code
into   bilancio_id, cod_fase_operativa
from  siac_d_fase_operativa fase_operativa, 
      siac_r_bil_fase_operativa bil_fase_operativa, 
      siac_t_bil bil, 
      siac_t_periodo periodo
where fase_operativa.fase_operativa_id = bil_fase_operativa.fase_operativa_id
and   bil_fase_operativa.bil_id = bil.bil_id
and   periodo.periodo_id = bil.periodo_id
and   fase_operativa.fase_operativa_code in ('P','E','G') -- SIAC-5778 Aggiunto G
and   bil.ente_proprietario_id = p_ente_prop_id
and   periodo.anno = p_anno
and   fase_operativa.data_cancellazione is null
and   bil_fase_operativa.data_cancellazione is null 
and   bil.data_cancellazione is null 
and   periodo.data_cancellazione is null;
 
/*if cod_fase_operativa = 'P' then
  
  anno_esercizio := ((p_anno::integer)-1)::varchar;   

  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer-1;
  
elsif cod_fase_operativa in ('E','G') then

  anno_esercizio := p_anno;
  annoprospetto_int := p_anno_prospetto::integer;
   
end if;*/
 
  anno_esercizio := ((p_anno::integer)-1)::varchar;   


  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer;
  
  annoprospetto_prec_int := ((p_anno_prospetto::integer)-1);

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

-- annoImpImpegni_int := anno_esercizio::integer; 
-- annoImpImpegni_int := p_anno::integer; -- SIAC-6063
raise notice 'anno_esercizio = % - anno_esercizio_prec = %', anno_esercizio, anno_esercizio_prec;
raise notice 'bilancio_id = % - bilancio_id_prec = %', bilancio_id, bilancio_id_prec;
raise notice 'annoprospetto_int = %', annoprospetto_int;
raise notice 'annoprospetto_prec_int = %', annoprospetto_prec_int;

return query
select 
zz.*
from (
select 
tab1.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null) -- Potrebbe essere anche anno_esercizio_prec
),
capitoli_anno_prec as (
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
and capitolo.bil_id = bilancio_id_prec													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
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
capitoli_importo as ( -- Fondo pluriennale vincolato al 31 dicembre dell''esercizio N-1
select 		capitolo_importi.elem_id,
           	sum(capitolo_importi.elem_det_importo) importi_capitoli
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
where capitolo_importi.ente_proprietario_id = p_ente_prop_id  								 
and	capitolo.elem_id = capitolo_importi.elem_id 
and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
and	capitolo.elem_id = r_capitolo_stato.elem_id			
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
and	capitolo.bil_id = bilancio_id_prec							
and	tipo_elemento.elem_tipo_code = 'CAP-UG'
and	capitolo_imp_periodo.anno = annoprospetto_prec_int::varchar		  
--and	capitolo_imp_periodo.anno = anno_esercizio_prec	
and	stato_capitolo.elem_stato_code = 'VA'								
and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
and capitolo_imp_tipo.elem_det_tipo_code = 'STA'				
and	capitolo_importi.data_cancellazione 		is null
and	capitolo_imp_tipo.data_cancellazione 		is null
and	capitolo_imp_periodo.data_cancellazione 	is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
COALESCE(capitoli_importo.importi_capitoli,0)::numeric,
0::numeric spese_impegnate,
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
0::numeric importo_avanzo,
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli_anno_prec.elem_id::integer,
anno_esercizio::varchar,
0::numeric spese_impegnate_da_prev
from struttura
left join capitoli_anno_prec on struttura.programma_id = capitoli_anno_prec.programma_id
                   and struttura.macroag_id = capitoli_anno_prec.macroaggregato_id
left join capitoli_importo on capitoli_anno_prec.elem_id = capitoli_importo.elem_id
) tab1
union all
select 
tab2.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null)
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
and capitolo.bil_id = bilancio_id													
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
dati_impegni as (
with importo_impegni as (
with   impegni as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_impegno
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.movgest_anno  >= annoprospetto_int
-- and    movimento.movgest_anno  >= annoImpImpegni_int
and    movimento.bil_id = bilancio_id
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno
),
imp_impegni_accertamenti as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_accertamento,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo       
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_a_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    ts_impegni_legati.avav_id is null
and    movimento.bil_id = bilancio_id
and    movimento.movgest_anno <= annoprospetto_int+2
-- and    movimento.movgest_anno <= annoImpImpegni_int+2
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
imp_impegni_avanzo as (
select ts_impegni_legati.movgest_ts_b_id,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo,
       movimento.movgest_anno        
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_avanzovincolo avanzovincolo on ts_impegni_legati.avav_id = avanzovincolo.avav_id
inner  join siac_d_avanzovincolo_tipo tipo_avanzovincolo on avanzovincolo.avav_tipo_id = tipo_avanzovincolo.avav_tipo_id
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.bil_id = bilancio_id
and    ts_impegni_legati.movgest_ts_a_id is null
and    tipo_avanzovincolo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
and    movimento.movgest_anno >= annoprospetto_int
-- and    movimento.movgest_anno >= annoImpImpegni_int
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    avanzovincolo.data_cancellazione is null 
and    tipo_avanzovincolo.data_cancellazione is null
and    ts_movimento.data_cancellazione is null 
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
impegni_verif_previsione as(
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
                        and mov_acc.ente_proprietario_id= p_ente_prop_id
                        and mov_acc.movgest_anno = annoprospetto_prec_int--annoprospetto_int --accertamenti sempre dell'anno prospetto
                        --and mov_acc.movgest_anno = annoprospetto_int --accertamenti sempre dell'anno prospetto
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
                        and mov_imp.ente_proprietario_id= p_ente_prop_id
                        and mov_imp.bil_id = bilancio_id  --anno precedente di gestione
                        and mov_imp.movgest_anno >= annoprospetto_prec_int+1-- annoprospetto_int + 1 --impegni a partire dell'anno prospetto + 1
                        --and mov_imp.movgest_anno >=  annoprospetto_int + 1 --impegni a partire dell'anno prospetto + 1
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
                      and anno_bil.anno=p_anno -- anno bilancio
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
        and progetti.programma_id IS NULL ),
/* SIAC-8866 04/07/2023.
    	Devo verificare che l'impegno non sia legato ad un progetto per non contarlo 2 volte.
*/     
elenco_progetti_imp as (select r_mov_progr.movgest_ts_id, progetto.programma_id, progetto.programma_code
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
                      and anno_bil.anno=anno_esercizio_prec -- anno bilancio precedente
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null)         
select impegni.movgest_ts_b_id, COALESCE(elenco_progetti_imp.programma_code,'') progetto,
       case 
        when impegni.anno_impegno = annoprospetto_int and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,  
       case 
        when impegni.anno_impegno = annoprospetto_int+1 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno1,   
       case 
        when impegni.anno_impegno = annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno2,    
       case 
        when impegni.anno_impegno > annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+2 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno_succ,
       case 
        when impegni.anno_impegno = annoprospetto_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo,    
       case 
        when impegni.anno_impegno = annoprospetto_int+1 then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo_anno1,      
       case 
        when impegni.anno_impegno = annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno2,
       case 
        when impegni.anno_impegno > annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno_succ,
       case 
       	when impegni.anno_impegno = annoprospetto_int then --and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
       		sum(impegni_verif_previsione.importo_imp) 
        end spese_impegnate_da_prev                            
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
left   join impegni_verif_previsione on impegni.movgest_ts_b_id = impegni_verif_previsione.movgest_ts_b_id and
		annoprospetto_int > p_anno::integer 
left join elenco_progetti_imp on elenco_progetti_imp.movgest_ts_id = impegni.movgest_ts_b_id        
--left   join impegni_verif_previsione on 1000 = impegni_verif_previsione.movgest_ts_b_id
-- SIAC-8866 04/07/2023: solo se l'impegno non è collegato al progetto.
where  ((COALESCE(elenco_progetti_imp.programma_code,'') = '' ) OR
		(COALESCE(elenco_progetti_imp.programma_code,'') <> '' AND impegni_verif_previsione.movgest_ts_b_id IS NULL))
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento ,
	COALESCE(elenco_progetti_imp.programma_code,'')
),
capitoli_impegni as (
select capitolo.elem_id, ts_movimento.movgest_ts_id
from  siac_t_bil_elem                 capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where capitolo.ente_proprietario_id = p_ente_prop_id
and   capitolo.bil_id =	bilancio_id
and   movimento.bil_id = bilancio_id
and   t_capitolo.elem_tipo_code = 'CAP-UG'
and   movimento.movgest_anno >= annoprospetto_int
-- and   movimento.movgest_anno >= annoImpImpegni_int
and   stato.movgest_stato_code in ('D','N')-- SIAC-5778
and   capitolo.data_cancellazione is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione is null
and   movimento.data_cancellazione is null 
and   ts_movimento.data_cancellazione is null
and   ts_stato.data_cancellazione is null-- SIAC-5778
and   stato.data_cancellazione is null-- SIAC-5778 
)
select 
capitoli_impegni.elem_id,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.spese_impegnate_anno1) spese_impegnate_anno1,
sum(importo_impegni.spese_impegnate_anno2) spese_impegnate_anno2,
sum(importo_impegni.spese_impegnate_anno_succ) spese_impegnate_anno_succ,
sum(importo_impegni.importo_avanzo) importo_avanzo,
sum(importo_impegni.importo_avanzo_anno1) importo_avanzo_anno1,
sum(importo_impegni.importo_avanzo_anno2) importo_avanzo_anno2,
sum(importo_impegni.importo_avanzo_anno_succ) importo_avanzo_anno_succ,
sum(importo_impegni.spese_impegnate_da_prev) spese_impegnate_da_prev
from capitoli_impegni
	left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
group by capitoli_impegni.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
0::numeric importi_capitoli,
COALESCE(dati_impegni.spese_impegnate,0)::numeric spese_impegnate,
/*COALESCE(dati_impegni.spese_impegnate_anno1,0)::numeric spese_impegnate_anno1,
COALESCE(dati_impegni.spese_impegnate_anno2,0)::numeric spese_impegnate_anno2,
COALESCE(dati_impegni.spese_impegnate_anno_succ,0)::numeric spese_impegnate_anno_succ,*/
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
COALESCE(dati_impegni.importo_avanzo,0)::numeric importo_avanzo,
/*COALESCE(dati_impegni.importo_avanzo_anno1,0)::numeric importo_avanzo_anno1,
COALESCE(dati_impegni.importo_avanzo_anno2,0)::numeric importo_avanzo_anno2,
COALESCE(dati_impegni.importo_avanzo_anno_succ,0)::numeric importo_avanzo_anno_succ,*/
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli.elem_id::integer,
anno_esercizio::varchar,
coalesce(dati_impegni.spese_impegnate_da_prev,0) spese_impegnate_da_prev
from struttura
left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
) tab2
) as zz;

-- raise notice 'Dati % - %',anno_esercizio::varchar,anno_esercizio_prec::varchar;
-- raise notice 'Dati % - %',bilancio_id::varchar,bilancio_id_prec::varchar;

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
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

ALTER FUNCTION siac."BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;

CREATE OR REPLACE FUNCTION siac."fnc_lancio_BILR011_anni_precedenti_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione varchar,
  programma varchar,
  imp_colonna_h numeric,
  imp_colonna_d numeric
) AS
$body$
DECLARE

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della fnc_lancio_BILR171_anni_precedenti che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR011.
        Richiama la BILR011_allegato_fpv_previsione_con_dati_gestione con parametri 
        diversi a seconda dell'anno di prospetto.
		Poiche' il report BILR171 viene eliminato per l'anno 2018 la funzione 
        fnc_lancio_BILR171_anni_precedenti rimane per gli anni precedenti.
*/

/*
	21/12/2020: SIAC-7933.
    	Questa funzione serve per calcolare i dati della colonna H dell'anno precedente
        quando l'anno di prospetto e' maggiore di quello del bilancio.
        In questo caso tale colonna diventa la colonna A del report.
    	La funzione e' stata rivista in quanto prima la colonna H dell'anno precedente 
        del report era calcolata usando solo i dati della Gestione.
        Invece ora viene calcolata sommando i dati della Gestione delle colonne
        A e B e quelli di Previsione delle colonne D, E, F e G dell'anno precedente 
        cosi' come avviene anche quando l'anno di prospetto e' uguale all'anno del Bilancio. 
        Per questo motivo le query sono state riviste e viene richiamata anche la funzione
        "BILR011_Allegato_B_Fondo_Pluriennale_vincolato" che prende i dati di Previsione.
        
        Inoltre la funzione restituisce anche l'importo della colonna D anno precedente,
        in quanto e' stato richiesto che quando l'anno prospetto e' maggiore di quello
        del bilancio tale importo sia sommato alla colonna B.        

	28/02/2023: SIAC-8866.
    	Quando l'anno prospetto e' uguale a quallo del bilancio + 2, occorre sottrare per la colonna A l'importo
        "spese_impegnate_da_prev" che contiene l'importo degli impegni utilizzati per il calcolo 
*/

	--anno prospetto = anno bilancio + 1
if p_anno_prospetto::integer = (p_anno::integer)+1 then
   
  return query
 /*
  select missione_code, programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code;*/  
  
  	--  FPV = dati di Previsione, anno_prec = dati di gestione    
  with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    sum(spese_impegnate_da_prev) as spese_impegnate_da_prev,    
    missione_code||programma_code as missioneprogramma
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-(anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g) imp_colonna_h,
    FPV.spese_da_impeg_anno1_d imp_colonna_d
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro;
 
	--anno prospetto = anno bilancio + 2
elsif p_anno_prospetto::integer = (p_anno::integer)+2 then
-- quando l'anno prospette e' anno bilancio + 2, devo calcolare l'importo della 
-- colonna H del report con anno -2 perche' diventa la colonna A dell'anno -1.
  return query
   select anno_meno2.missione_code, anno_meno2.programma_code,
   (anno_meno2.importo_colonna_h -
    (anno_meno1.importo_avanzo+anno_meno1.spese_impegnate+ 
    anno_meno2.spese_da_impeg_anno1_d -anno_meno1.spese_impegnate_da_prev) + --devo aggiungere anche la colonna_B.
    anno_meno1.spese_da_impeg_anno1_d + anno_meno1.spese_da_impeg_anno2_e +
   	anno_meno1.spese_da_impeg_anni_succ_f + anno_meno1.spese_da_impeg_non_def_g) imp_colonna_h,
    anno_meno1.spese_da_impeg_anno1_d imp_colonna_d
  from (
  	--  FPV = dati di Previsione, anno_prec = dati di gestione, Anno prospetto -2.
  with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-2)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    sum(spese_impegnate_da_prev) as spese_impegnate_da_prev,  
    missione_code||programma_code as missioneprogramma 
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-2)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-
    (anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g ) importo_colonna_h,
    anno_prec.importo_avanzo, anno_prec.spese_impegnate, FPV.spese_da_impeg_anno1_d
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro) anno_meno2,
 ( --  FPV = dati di Previsione, anno_prec = dati di gestione. Anno prospetto -1.
 	with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    sum(spese_impegnate_da_prev) as spese_impegnate_da_prev,  
    missione_code||programma_code as missioneprogramma
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-
    (anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g) importo_colonna_h,
    FPV.spese_da_impeg_anno1_d, FPV.spese_da_impeg_anno2_e,
    FPV.spese_da_impeg_anni_succ_f, FPV.spese_da_impeg_non_def_g,
    anno_prec.spese_impegnate, anno_prec.importo_avanzo, anno_prec.spese_impegnate_da_prev
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro) anno_meno1
where anno_meno2.missione_code = anno_meno1.missione_code
  and   anno_meno2.programma_code = anno_meno1.programma_code;
  
  /*
    select a.missione_code, a.programma_code,
    (a.importo_colonna_h-b.importo_colonna_h) as imp_colonna_h
  from (
  select missione_code, 
         programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-2)::varchar
  )
  group by missione_code, programma_code
  ) a, 
  (select missione_code, programma_code, 
         sum((importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as  importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code
  ) b
  where a.missione_code = b.missione_code
  and   a.programma_code = b.programma_code;*/

end if;
  
EXCEPTION
  when others  THEN
  RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(SQLERRM from 1 for 500);
  return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."fnc_lancio_BILR011_anni_precedenti_gestione" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;  
  
  
CREATE OR REPLACE FUNCTION siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  anno_prospetto varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  elem_id integer,
  numero_capitolo varchar,
  anno_impegno integer,
  numero_impegno numeric,
  spese_impegnate numeric,
  importo_avanzo numeric,
  importo_colonna_d_anno_prec numeric,
  spese_impegnate_da_prev numeric,
  progetto varchar,
  cronoprogramma varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;
annoprospetto_int integer;
annoprospetto_prec_int integer;

BEGIN

/*
	26/04/2022: SIAC-8634.
    	Funzione che estrae i dati di dettaglio relativi al report BILR011
        per la sola colonna B utilizzata dal report BILR260.
*/
/* Aggiornamenti per SIAC-8866 30/06/2023.

*/

--I dati letti in questa procedura riguardano la gestione dell'anno precedente di quello del bilancio in input.
bilancio_id_prec := null;
 
anno_esercizio := ((p_anno::integer)-1)::varchar;   

annoprospetto_int := p_anno_prospetto::integer;
  
annoprospetto_prec_int := ((p_anno_prospetto::integer)-1);

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

--leggo l'id del bilancio precedente.
select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

raise notice 'bilancio_id_prec = %', bilancio_id_prec;
raise notice 'anno_esercizio = % - anno_esercizio_prec = % - annoprospetto_int = %- annoprospetto_prec_int = %', 
anno_esercizio, anno_esercizio_prec, annoprospetto_int, annoprospetto_prec_int;


return query
with tutto as (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null)
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
and capitolo.bil_id = bilancio_id_prec													
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
dati_impegni as (
with importo_impegni as (
with   impegni as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_impegno
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.movgest_anno  >= annoprospetto_int
-- and    movimento.movgest_anno  >= annoImpImpegni_int
and    movimento.bil_id = bilancio_id_prec
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno
),
imp_impegni_accertamenti as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_accertamento,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo       
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_a_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    ts_impegni_legati.avav_id is null
and    movimento.bil_id = bilancio_id_prec
and    movimento.movgest_anno <= annoprospetto_int+2
-- and    movimento.movgest_anno <= annoImpImpegni_int+2
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
imp_impegni_avanzo as (
select ts_impegni_legati.movgest_ts_b_id,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo,
       movimento.movgest_anno        
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_avanzovincolo avanzovincolo on ts_impegni_legati.avav_id = avanzovincolo.avav_id
inner  join siac_d_avanzovincolo_tipo tipo_avanzovincolo on avanzovincolo.avav_tipo_id = tipo_avanzovincolo.avav_tipo_id
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.bil_id = bilancio_id_prec
and    ts_impegni_legati.movgest_ts_a_id is null
and    tipo_avanzovincolo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
and    movimento.movgest_anno >= annoprospetto_int
-- and    movimento.movgest_anno >= annoImpImpegni_int
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    avanzovincolo.data_cancellazione is null 
and    tipo_avanzovincolo.data_cancellazione is null
and    ts_movimento.data_cancellazione is null 
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
dettaglio_impegni as(
select impegno.movgest_anno anno_impegno,
	impegno.movgest_numero numero_impegno, impegno_ts.movgest_ts_id
from siac_t_movgest impegno,
	siac_t_movgest_ts impegno_ts,
    siac_d_movgest_tipo movgest_tipo
where impegno.movgest_id=impegno_ts.movgest_id
	and impegno.movgest_tipo_id=movgest_tipo.movgest_tipo_id
	and impegno.ente_proprietario_id= p_ente_prop_id
    and impegno.bil_id=bilancio_id_prec
    and movgest_tipo.movgest_tipo_code='I'
    and impegno.data_cancellazione IS NULL
    and impegno_ts.data_cancellazione IS NULL)    
select impegni.movgest_ts_b_id,
	   dettaglio_impegni.anno_impegno,
       dettaglio_impegni.numero_impegno,
       case 
        when impegni.anno_impegno = annoprospetto_int and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,         
       case 
        when impegni.anno_impegno = annoprospetto_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo                           
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
left   join dettaglio_impegni on dettaglio_impegni.movgest_ts_id = impegni.movgest_ts_b_id
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento,
	dettaglio_impegni.anno_impegno, dettaglio_impegni.numero_impegno
), --importo_impegni
    capitoli_impegni as (
    select capitolo.elem_id, ts_movimento.movgest_ts_id,
    	capitolo.elem_code numero_capitolo
    from  siac_t_bil_elem                 capitolo
    inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
    inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
    inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
    inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
    inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
    inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
    where capitolo.ente_proprietario_id = p_ente_prop_id
    and   capitolo.bil_id =	bilancio_id_prec
    and   movimento.bil_id = bilancio_id_prec
    and   t_capitolo.elem_tipo_code = 'CAP-UG'
    and   movimento.movgest_anno >= annoprospetto_int
    -- and   movimento.movgest_anno >= annoImpImpegni_int
    and   stato.movgest_stato_code in ('D','N')-- SIAC-5778
    and   capitolo.data_cancellazione is null 
    and   r_mov_capitolo.data_cancellazione is null 
    and   t_capitolo.data_cancellazione is null
    and   movimento.data_cancellazione is null 
    and   ts_movimento.data_cancellazione is null
    and   ts_stato.data_cancellazione is null-- SIAC-5778
    and   stato.data_cancellazione is null-- SIAC-5778 
    ),
    /* SIAC-8866 26/06/2023.
    	Estraggo i dati degli impegni per verificare se un certo impegno era gia' stato utilizzato.
        Nel report il dato spese_impegnate_da_prev viene sottratto all'importo importo_colonna_d_anno_prec.
    */
    impegni_verif_previsione as(
    select distinct accert.*, imp.*,     ts_impegni_legati.movgest_ts_b_id
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
                        and mov_acc.ente_proprietario_id= p_ente_prop_id
                        and mov_acc.movgest_anno = annoprospetto_prec_int--annoprospetto_int --accertamenti sempre dell'anno prospetto
                        --and mov_acc.movgest_anno = annoprospetto_int --accertamenti sempre dell'anno prospetto
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
                        and mov_imp.ente_proprietario_id= p_ente_prop_id
                        and mov_imp.bil_id = bilancio_id_prec  --anno precedente di gestione
                        and mov_imp.movgest_anno >= annoprospetto_prec_int+1-- annoprospetto_int + 1 --impegni a partire dell'anno prospetto + 1
                        --and mov_imp.movgest_anno >=  annoprospetto_int + 1 --impegni a partire dell'anno prospetto + 1
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
                      and anno_bil.anno=p_anno--annoprospetto_prec_int::varchar -- anno bilancio precedente
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
    	and imp.anno_imp = annoprospetto_int --+1  
        and ts_impegni_legati.avav_id is null
        and ts_impegni_legati.data_cancellazione is null  
        	--progetti.programma_id IS NULL cioe' non sono compresi negli impegni legati ai progetti estratti
            --nelle query precedenti. In pratica non devo contarli 2 volte.
      and progetti.programma_id IS NULL  ),
/* SIAC-8866 04/07/2023.
    	Devo verificare che l'impegno non sia legato ad un progetto per non contarlo 2 volte.
*/     
elenco_progetti_imp as (select r_mov_progr.movgest_ts_id, progetto.programma_id, progetto.programma_code
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
                      and anno_bil.anno=anno_esercizio_prec -- anno bilancio precedente
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null)      
select 
capitoli_impegni.elem_id,
capitoli_impegni.numero_capitolo,
COALESCE(importo_impegni.anno_impegno,0) anno_impegno, 
COALESCE(importo_impegni.numero_impegno,0) numero_impegno,
COALESCE(elenco_progetti_imp.programma_code,'') progetto,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.importo_avanzo) importo_avanzo,
sum(impegni_verif_previsione.importo_imp) spese_impegnate_da_prev
--0::numeric spese_impegnate_da_prev
from capitoli_impegni
	left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
	left join impegni_verif_previsione on capitoli_impegni.movgest_ts_id = impegni_verif_previsione.movgest_ts_b_id and
		annoprospetto_int > p_anno::integer 
    left join elenco_progetti_imp on elenco_progetti_imp.movgest_ts_id = capitoli_impegni.movgest_ts_id-- importo_impegni.movgest_ts_b_id
-- SIAC-8866 04/07/2023: solo se l'impegno non è collegato al progetto.
where  ((COALESCE(elenco_progetti_imp.programma_code,'') = '' ) OR
		(COALESCE(elenco_progetti_imp.programma_code,'') <> '' AND impegni_verif_previsione.movgest_ts_b_id IS NULL))    
group by capitoli_impegni.elem_id,capitoli_impegni.numero_capitolo,
importo_impegni.anno_impegno, importo_impegni.numero_impegno, COALESCE(elenco_progetti_imp.programma_code,'')
) --dati_impegni
select 
p_anno_prospetto::varchar anno_prosp,
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
dati_impegni.elem_id::integer,
dati_impegni.numero_capitolo,
COALESCE(dati_impegni.anno_impegno,0) anno_impegno, 
COALESCE(dati_impegni.numero_impegno,0) numero_impegno,
COALESCE(dati_impegni.spese_impegnate,0)::numeric spese_impegnate,
COALESCE(dati_impegni.importo_avanzo,0)::numeric importo_avanzo,
0::numeric importo_colonna_d_Anno_prec,
COALESCE(dati_impegni.spese_impegnate_da_prev,0) spese_impegnate_da_prev,
''::varchar programma,
''::varchar cronoprogramma 
from struttura
	left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
	left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
where dati_impegni.elem_id is not null
--estraggo i dati della colonna D dello stesso anno bilancio ma con
--anno prospetto precedente.
--Vale solo quando il prospetto e' > dell'anno bilancio.
union 
--SIAC-8866 21/06/2023
--il calcolo degll'importo dei progetti deve prendere solo quelli di Previsione
select p_anno_prospetto::varchar anno_prosp,
''::varchar missione_code,
''::varchar missione_desc, 
cl2.classif_code programma_code,
''::varchar programma_desc, 
0::integer elem_id,
crono_elem.cronop_elem_code numero_capitolo,
0::integer anno_impegno,
0::integer numero_impegno,
0::numeric spese_impegnate,
0::numeric importo_avanzo,
case when p_anno = p_anno_prospetto 
    	then 0
		else COALESCE(sum(crono_elem_det.cronop_elem_det_importo),0) end importo_colonna_d_Anno_prec,
0::numeric spese_impegnate_da_prev,
pr.programma_code progetto,
crono.cronop_code cronoprogramma
from siac_t_programma pr, siac_t_cronop crono, 
     siac_t_bil bil, siac_t_periodo anno_bil, siac_d_programma_tipo tipo_prog,
     siac_t_cronop_elem crono_elem, siac_d_bil_elem_tipo crono_elem_tipo,
     siac_t_cronop_elem_det crono_elem_det, siac_t_periodo anno_crono_elem_det,
     siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
     siac_r_cronop_stato stc , siac_d_cronop_stato stct,
     siac_r_programma_stato stpr, siac_d_programma_stato stprt
where pr.programma_id=crono.programma_id
      and crono.bil_id = bil.bil_id
      and bil.periodo_id=anno_bil.periodo_id
      and tipo_prog.programma_tipo_id = pr.programma_tipo_id
      and crono_elem.cronop_id=crono.cronop_id
      and crono_elem.cronop_elem_id=crono_elem_det.cronop_elem_id
      and crono_elem_tipo.elem_tipo_id=crono_elem.elem_tipo_id
      and rcl2.cronop_elem_id = crono_elem.cronop_elem_id
      and rcl2.classif_id=cl2.classif_id
      and cl2.classif_tipo_id=clt2.classif_tipo_id
      and crono_elem_det.periodo_id = anno_crono_elem_det.periodo_id
      and stc.cronop_id=crono.cronop_id
      and stc.cronop_stato_id=stct.cronop_stato_id
      and stpr.programma_id=pr.programma_id
      and stpr.programma_stato_id=stprt.programma_stato_id                          
      and pr.ente_proprietario_id= p_ente_prop_id
      and anno_bil.anno=p_anno -- anno bilancio
      and crono.usato_per_fpv::boolean = true
      and crono_elem_det.anno_entrata = annoprospetto_prec_int::varchar -- anno prospetto           
      and anno_crono_elem_det.anno::integer=annoprospetto_prec_int +1 -- anno prospetto
      and clt2.classif_tipo_code='PROGRAMMA'
      and stct.cronop_stato_code='VA'
--SIAC-8866 21/06/2023
--il calcolo degll'importo dei progetti deve prendere solo quelli di Previsione      
      and tipo_prog.programma_tipo_code ='P'  --Solo progetti della previsione.
      and stprt.programma_stato_code='VA'
      and stpr.data_cancellazione is null
      and stc.data_cancellazione is null
      and crono.data_cancellazione is null
      and pr.data_cancellazione is null
      and bil.data_cancellazione is null
      and anno_bil.data_cancellazione is null
      and crono_elem.data_cancellazione is null
      and crono_elem_det.data_cancellazione is null
      and rcl2.data_cancellazione is null
group by cl2.classif_code ,crono_elem.cronop_elem_code, pr.programma_code, crono.cronop_code
/* SIAC-8866 26/06/2023.
    Nel report BILR011 l'importo della colonna D anno precedente e' dato non solo dai progetti ma anche dagli impegni.
    Aggiungo la query.
*/
union
select *
from(
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
                        and mov_acc.movgest_anno = annoprospetto_prec_int --accertamenti sempre dell'anno prospetto
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
                        and mov_imp.movgest_anno >= annoprospetto_prec_int + 1 --impegni a partire dell'anno prospetto + 1
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
                      and anno_bil.anno::integer=p_anno::integer-1--annoprospetto_prec_int - 1 -- anno precedente quello del bilancio?
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
    p_anno_prospetto::varchar anno_prosp,
	struttura.missione_code::varchar missione_code,
	struttura.missione_desc::varchar missione_desc, 
	struttura.programma_code programma_code,
	struttura.programma_desc::varchar programma_desc, 
	capitoli.elem_id::integer elem_id,
	capitoli.elem_code::varchar numero_capitolo,
	impegni.anno_imp::integer anno_impegno,
	impegni.numero_imp::integer numero_impegno,
	0::numeric spese_impegnate,
	0::numeric importo_avanzo,
	case when p_anno = p_anno_prospetto 
    	then 0
        else COALESCE(sum(impegni.importo_imp),0) end importo_colonna_d_Anno_prec,
	0::numeric spese_impegnate_da_prev,
    ''::varchar programma,
    ''::varchar cronoprogramma 
    from impegni
        left join capitoli 
            on impegni.elem_id=capitoli.elem_id 
        left join struttura 
            on struttura.programma_id = capitoli.programma_id
                and struttura.macroag_id = capitoli.macroaggregato_id        
    where impegni.anno_imp = annoprospetto_int
    group by anno_prosp, struttura.missione_code,struttura. missione_desc, struttura.programma_code, struttura.programma_desc, 
    	capitoli.elem_id, capitoli.elem_code, impegni.anno_imp, impegni.numero_imp) aaa     ) 
select * from tutto 
union 
--aggiungo la riga dei totali
select tutto.anno_prosp anno_prospetto,
 '' missione_code,
 '' missione_desc,
 'Totale' programma_code ,
 '' programma_desc,  
 0 elem_id,
 '' numero_capitolo,
 0 anno_impegno,
 0 numero_impegno,
 sum(tutto.spese_impegnate) spese_impegnate,
 sum(tutto.importo_avanzo) importo_avanzo,
 sum(tutto.importo_colonna_d_Anno_prec) importo_colonna_d_Anno_prec,
 sum(tutto.spese_impegnate_da_prev) spese_impegnate_da_prev,
 ''::varchar programma,
 ''::varchar cronoprogramma 
from tutto
group by anno_prospetto;

exception
when no_data_found THEN
raise notice 'Nessun dato trovato';
return;
when others  THEN
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

ALTER FUNCTION siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;  
  
--SIAC-8866 - Maurizio - FINE
  