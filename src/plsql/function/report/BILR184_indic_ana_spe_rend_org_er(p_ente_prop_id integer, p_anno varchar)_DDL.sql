/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR184_indic_ana_spe_rend_org_er" (
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
  tipo_capitolo varchar,
  imp_impegnato_i numeric,
  imp_fondo_fpv numeric,
  imp_prev_def_comp_cp numeric,
  imp_residui_passivi_rs numeric,
  imp_prev_def_cassa_cs numeric,
  imp_pagam_comp_pc numeric,
  imp_pagam_res_pr numeric,
  imp_econ_comp_ecp numeric,
  display_error varchar
) AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;

    annoBilInt integer;   
    bilId integer;
    
    
BEGIN
 
/*
	Funzione che estrae i dati di rendiconto di spesa dell'anno di bilancio in input
    suddivisi per missione e programma.
    
    I dati restituiti sono:
  		- importo IMPEGNI (I);
        - importo FONDO PLURIENNALE VINCOLATO (FPV);
        - importo PREVISIONI DEFINITIVE DI COMPETENZA (CP);
  		- importo RESIDUI PASSIVI AL (RS) ;
        - importo PREVISIONI DEFINITIVE DI CASSA (CS);
        - importo PAGAMENTI IN C/COMPETENZA (PC);
        - importo PAGAMENTI IN C/RESIDUI (PR);
        - importo ECONOMIE DI COMPETENZA (ECP= CP-I-FPV).
*/

annoBilInt:=p_anno::integer;
     
	/* Leggo l'id dell'anno del rendiconto */     
bilId:=0;     
select a.bil_id 
	INTO bilId
from siac_t_bil a, siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.ente_proprietario_id=p_ente_prop_id
and b.anno = p_anno;
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
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
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
  i_impegni as (
    select-- t_periodo.anno anno_bil,     
        sum(t_movgest_ts_det.movgest_ts_det_importo) importo_impegno,
        r_movgest_bil_elem.elem_id
     from siac_t_movgest t_movgest,
          siac_d_movgest_tipo d_movgest_tipo,
          siac_t_movgest_ts t_movgest_ts,
          siac_d_movgest_ts_tipo d_movgest_ts_tipo,
          siac_r_movgest_ts_stato r_movgest_ts_stato,
          siac_d_movgest_stato d_movgest_stato,
          siac_t_movgest_ts_det t_movgest_ts_det,
          siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
          siac_r_movgest_bil_elem r_movgest_bil_elem
    where d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
    and t_movgest_ts.movgest_id=t_movgest.movgest_id
    and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
    and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and d_movgest_stato.movgest_stato_id=r_movgest_ts_stato.movgest_stato_id
    and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and t_movgest_ts_det.movgest_ts_det_tipo_id=d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
    and r_movgest_bil_elem.movgest_id = t_movgest_ts.movgest_id
    and t_movgest.ente_proprietario_id =p_ente_prop_id
    and d_movgest_tipo.movgest_tipo_code='I'
    and d_movgest_ts_tipo.movgest_ts_tipo_code='T'
    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
    --and d_movgest_stato.movgest_stato_code<>'A'
    -- D = DEFINITIVO
    -- N = DEFINITIVO NON LIQUIDABILE
    -- Devo prendere anche P - PROVVISORIO????
    and d_movgest_stato.movgest_stato_code in ('D','N') 
    and t_movgest.movgest_anno = annoBilInt
    and t_movgest.bil_id =bilId
    and now() BETWEEN d_movgest_stato.validita_inizio and COALESCE(d_movgest_stato.validita_fine,now())
    and r_movgest_ts_stato.validita_fine is NULL
    and t_movgest.data_cancellazione is null
    and d_movgest_tipo.data_cancellazione is null
    and t_movgest_ts.data_cancellazione is null
    and d_movgest_ts_tipo.data_cancellazione is null
    and r_movgest_ts_stato.data_cancellazione is null
    and r_movgest_bil_elem.data_cancellazione is null
    and t_movgest_ts_det.data_cancellazione is null
    and d_movgest_ts_det_tipo.data_cancellazione is null
  GROUP BY elem_id),
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
    and t_periodo.anno  = p_anno
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
cp_prev_def_comp as (
select t_bil_elem.elem_id, 
sum(coalesce (t_bil_elem_det.elem_det_importo,0))   as previsioni_definitive_comp
from siac_t_bil_elem t_bil_elem,
siac_r_bil_elem_stato r_bil_elem_stato, 
siac_d_bil_elem_stato d_bil_elem_stato,
siac_r_bil_elem_categoria r_bil_elem_categ,
siac_d_bil_elem_categoria d_bil_elem_categ,
siac_t_bil_elem_det t_bil_elem_det,
siac_d_bil_elem_det_tipo d_bil_elem_det_tipo
,siac_t_periodo t_periodo
where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
and r_bil_elem_categ.elem_id=t_bil_elem.elem_id 
and d_bil_elem_categ.elem_cat_id=r_bil_elem_categ.elem_cat_id
and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
and t_periodo.periodo_id=t_bil_elem_det.periodo_id
and d_bil_elem_stato.elem_stato_code='VA'
and t_bil_elem.ente_proprietario_id=p_ente_prop_id
and d_bil_elem_categ.elem_cat_code	in	('STD','FSC','FPV',  'FPVCC','FPVSC')
and d_bil_elem_det_tipo.elem_det_tipo_code='STA'
and t_periodo.anno=p_anno
and t_bil_elem.bil_id = bilId
and r_bil_elem_categ.validita_fine is NULL
and r_bil_elem_stato.validita_fine is NULL
and t_bil_elem.data_cancellazione is null
and r_bil_elem_stato.data_cancellazione is null
and d_bil_elem_stato.data_cancellazione is null
and r_bil_elem_categ.data_cancellazione is null
and d_bil_elem_categ.data_cancellazione is null
and t_bil_elem_det.data_cancellazione is null
and d_bil_elem_det_tipo.data_cancellazione is null
and t_periodo.data_cancellazione is null
group by t_bil_elem.elem_id),
rs_residui_pass as(
select r_movgest_bil_elem.elem_id,
	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) residui_passivi 
from siac_t_movgest t_movgest,
	siac_t_movgest_ts t_movgest_ts,
    siac_t_movgest_ts_det t_movgest_ts_det,
	siac_r_movgest_bil_elem r_movgest_bil_elem,
    siac_d_movgest_tipo d_movgest_tipo,
    siac_r_movgest_ts_stato r_movgest_ts_stato,
    siac_d_movgest_stato d_movgest_stato,
	siac_d_movgest_ts_tipo d_movgest_ts_tipo,
    siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
 where  t_movgest_ts.movgest_id=t_movgest.movgest_id
     and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
     and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
     and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id  
     and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
     and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id  
     and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id 
     and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
     and t_bil.bil_id = t_movgest.bil_id
    and t_periodo.periodo_id= t_bil.periodo_id
     and t_movgest.ente_proprietario_id=p_ente_prop_id
     and t_movgest.movgest_anno < t_periodo.anno::integer
     and d_movgest_tipo.movgest_tipo_code='I'     
     and d_movgest_stato.movgest_stato_code in ('D','N')  
     and d_movgest_ts_tipo.movgest_ts_tipo_code='T'      
     and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
     and t_periodo.anno = p_anno   
     and r_movgest_ts_stato.validita_fine is NULL
     and t_movgest.data_cancellazione is null
     and t_movgest_ts.data_cancellazione is null
     and t_movgest_ts_det.data_cancellazione is null
     and r_movgest_bil_elem.data_cancellazione is null
     and d_movgest_tipo.data_cancellazione is null
     and r_movgest_ts_stato.data_cancellazione is null
     and d_movgest_stato.data_cancellazione is null
     and d_movgest_ts_tipo.data_cancellazione is null
     and d_movgest_ts_det_tipo.data_cancellazione is null
     and t_bil.data_cancellazione is null
     and t_periodo.data_cancellazione is null     
group by r_movgest_bil_elem.elem_id),
cs_prev_def_cassa as (
select t_bil_elem.elem_id, 
sum(coalesce (t_bil_elem_det.elem_det_importo,0)) as previsioni_definitive_cassa
from siac_t_bil_elem t_bil_elem,
siac_r_bil_elem_stato r_bil_elem_stato, 
siac_d_bil_elem_stato d_bil_elem_stato,
siac_r_bil_elem_categoria r_bil_elem_categ,
siac_d_bil_elem_categoria d_bil_elem_categ,
siac_t_bil_elem_det t_bil_elem_det,
siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
siac_t_periodo t_periodo
where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
  and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
  and r_bil_elem_categ.elem_id=t_bil_elem.elem_id 
  and d_bil_elem_categ.elem_cat_id=r_bil_elem_categ.elem_cat_id
  and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
  and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
  and t_periodo.periodo_id=t_bil_elem_det.periodo_id
  and t_bil_elem.ente_proprietario_id=p_ente_prop_id
  and t_periodo.anno = p_anno
  and t_bil_elem.bil_id = bilId
  and d_bil_elem_stato.elem_stato_code='VA'
  and d_bil_elem_categ.elem_cat_code	in	('STD','FSC')
  and d_bil_elem_det_tipo.elem_det_tipo_code='SCA'
  and r_bil_elem_stato.validita_fine is NULL
  and r_bil_elem_categ.validita_fine is NULL
  and t_bil_elem.data_cancellazione is null
  and r_bil_elem_stato.data_cancellazione is null
  and d_bil_elem_stato.data_cancellazione is null
  and r_bil_elem_categ.data_cancellazione is null
  and d_bil_elem_categ.data_cancellazione is null
  and t_bil_elem_det.data_cancellazione is null
  and d_bil_elem_det_tipo.data_cancellazione is null
  and t_periodo.data_cancellazione is null
group by t_bil_elem.elem_id),
pc_pagam_comp as (
select 
	r_ord_bil_elem.elem_id,
    sum(coalesce(t_ord_ts_det.ord_ts_det_importo,0)) pagamenti_competenza
 from  siac_t_movgest t_movgest, 
 	siac_t_movgest_ts t_movgest_ts,
    siac_r_liquidazione_movgest r_liq_movgest,
    siac_r_liquidazione_ord r_liq_ord,
	siac_t_ordinativo_ts t_ord_ts,
    siac_t_ordinativo t_ord,
    siac_d_ordinativo_tipo d_ord_tipo,
    siac_r_ordinativo_stato r_ord_stato,
	siac_d_ordinativo_stato d_ord_stato,
    siac_r_ordinativo_bil_elem r_ord_bil_elem,
    siac_t_ordinativo_ts_det t_ord_ts_det,
	siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo
where t_movgest_ts.movgest_id=t_movgest.movgest_id
    and r_liq_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and r_liq_ord.liq_id=r_liq_movgest.liq_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and r_liq_ord.sord_id=t_ord_ts.ord_ts_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
    and r_ord_stato.ord_id=t_ord.ord_id
    and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
    and r_ord_bil_elem.ord_id=t_ord.ord_id
    and t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
    and t_movgest.ente_proprietario_id=p_ente_prop_id
    and d_ord_tipo.ord_tipo_code = 'P'
    and d_ord_stato.ord_stato_code <> 'A'
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code = 'A'
	and t_movgest.movgest_anno = annoBilInt 
    and t_movgest.bil_id=bilId
    and r_liq_movgest.validita_fine is NULL
    and r_liq_ord.validita_fine is NULL
    and r_ord_bil_elem.validita_fine is NULL
    and r_ord_stato.validita_fine is NULL
    and t_movgest.data_cancellazione is null
    and t_movgest_ts.data_cancellazione is null
    and r_liq_movgest.data_cancellazione is null
    and r_liq_ord.data_cancellazione is null
    and t_ord_ts.data_cancellazione is null
    and t_ord.data_cancellazione is null
    and d_ord_tipo.data_cancellazione is null
    and r_ord_stato.data_cancellazione is null
    and d_ord_stato.data_cancellazione is null
    and r_ord_bil_elem.data_cancellazione is null
    and t_ord_ts_det.data_cancellazione is null
    and d_ord_ts_det_tipo.data_cancellazione is null
group by r_ord_bil_elem.elem_id),
pr_pagamenti_residui as (
select 
	r_ord_bil_elem.elem_id,
	sum(coalesce(t_ord_ts_det.ord_ts_det_importo,0)) pagamenti_residui
 from  siac_t_movgest t_movgest, 
 	siac_t_movgest_ts t_movgest_ts,
    siac_r_liquidazione_movgest r_liq_movgest,
    siac_r_liquidazione_ord r_liq_ord,
	siac_t_ordinativo_ts t_ord_ts,
    siac_t_ordinativo t_ord,
    siac_d_ordinativo_tipo d_ord_tipo,
    siac_r_ordinativo_stato r_ord_stato,
	siac_d_ordinativo_stato d_ord_stato,
    siac_r_ordinativo_bil_elem r_ord_bil_elem,
    siac_t_ordinativo_ts_det t_ord_ts_det,
	siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
where t_movgest_ts.movgest_id=t_movgest.movgest_id
    and r_liq_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and r_liq_ord.liq_id=r_liq_movgest.liq_id
    and r_liq_ord.sord_id=t_ord_ts.ord_ts_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
    and t_ord.ord_id=t_ord_ts.ord_id
    and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
    and r_ord_bil_elem.ord_id=t_ord.ord_id
    and t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
    and r_ord_stato.ord_id=t_ord.ord_id    
    and t_bil.bil_id = t_movgest.bil_id
    and t_periodo.periodo_id= t_bil.periodo_id
    and t_movgest.ente_proprietario_id=p_ente_prop_id
    and t_movgest.movgest_anno < t_periodo.anno::integer
    and d_ord_tipo.ord_tipo_code='P'        
    and d_ord_stato.ord_stato_code<>'A'
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code='A'
    and t_periodo.anno = p_anno 
    and r_liq_movgest.validita_fine is NULL
    and r_liq_ord.validita_fine is NULL
    and r_ord_bil_elem.validita_fine is NULL
    and r_ord_stato.validita_fine is NULL
    and t_movgest.data_cancellazione is null
    and t_movgest_ts.data_cancellazione is null
    and r_liq_movgest.data_cancellazione is null
    and r_liq_ord.data_cancellazione is null
    and t_ord_ts.data_cancellazione is null
    and t_ord.data_cancellazione is null
    and d_ord_tipo.data_cancellazione is null
    and r_ord_stato.data_cancellazione is null
    and d_ord_stato.data_cancellazione is null
    and r_ord_bil_elem.data_cancellazione is null
    and t_ord_ts_det.data_cancellazione is null
    and d_ord_ts_det_tipo.data_cancellazione is null
    and t_bil.data_cancellazione is null
    and t_periodo.data_cancellazione is null
group by r_ord_bil_elem.elem_id)
SELECT  strut_bilancio.missione_id::integer id_missione,
		strut_bilancio.missione_code::varchar code_missione, 
		strut_bilancio.missione_desc::varchar desc_missione, 
        strut_bilancio.programma_id::integer id_programma,
        strut_bilancio.programma_code::varchar code_programma,
        strut_bilancio.programma_desc::varchar desc_programma,
        capitoli.tipo_capitolo::varchar tipo_capitolo,
        sum(COALESCE(i_impegni.importo_impegno,0))::numeric imp_impegnato_i,  
        sum(COALESCE(fpv.imp_fpv,0))::numeric imp_fondo_fpv,    
        sum(COALESCE(cp_prev_def_comp.previsioni_definitive_comp,0))::numeric imp_prev_def_comp_cp,
        sum(COALESCE(rs_residui_pass.residui_passivi,0))::numeric imp_residui_passivi_rs,
        sum(COALESCE(cs_prev_def_cassa.previsioni_definitive_cassa,0))::numeric imp_prev_def_cassa_cs,      
        sum(COALESCE(pc_pagam_comp.pagamenti_competenza,0))::numeric imp_pagam_comp_pc,         
        sum(COALESCE(pr_pagamenti_residui.pagamenti_residui,0))::numeric imp_pagam_res_pr, 
        sum(COALESCE(cp_prev_def_comp.previsioni_definitive_comp,0) -
        	COALESCE(i_impegni.importo_impegno,0) -
            COALESCE(fpv.imp_fpv,0)) imp_econ_comp_ecp,                        
        ''::varchar display_error
FROM strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    						AND strut_bilancio.macroag_id = capitoli.macroaggregato_id)
    LEFT JOIN i_impegni on i_impegni.elem_id = capitoli.elem_id
    LEFT JOIN fpv 	on fpv.elem_id = capitoli.elem_id    
    LEFT JOIN cp_prev_def_comp on cp_prev_def_comp.elem_id = capitoli.elem_id   
	LEFT JOIN rs_residui_pass on rs_residui_pass.elem_id = capitoli.elem_id             
    LEFT JOIN cs_prev_def_cassa on cs_prev_def_cassa.elem_id = capitoli.elem_id   
    LEFT JOIN pc_pagam_comp on pc_pagam_comp.elem_id = capitoli.elem_id  
    LEFT JOIN pr_pagamenti_residui on pr_pagamenti_residui.elem_id = capitoli.elem_id                      
GROUP BY id_missione, code_missione, desc_missione, 
		id_programma, code_programma, desc_programma, capitoli.tipo_capitolo
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