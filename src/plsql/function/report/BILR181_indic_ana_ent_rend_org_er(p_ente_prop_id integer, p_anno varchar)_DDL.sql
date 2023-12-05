/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR181_indic_ana_ent_rend_org_er" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  id_titolo integer,
  code_titolo varchar,
  desc_titolo varchar,
  id_tipologia integer,
  code_tipologia varchar,
  desc_tipologia varchar,
  importo_accertato_a numeric,
  importo_prev_def_cassa_cs numeric,
  importo_res_attivi_rs numeric,
  importo_risc_conto_res_rr numeric,
  importo_risc_conto_comp_rc numeric,
  importo_tot_risc_tr numeric,
  importo_prev_def_comp_cp numeric,
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
	Funzione che estrae i dati di rendiconto di entrata dell'anno di bilancio in input
    suddivisi per titolo e tipologia.
    
    I dati restituiti sono:
    	- importo ACCERTAMENTI (A)
 		- importo PREVISIONI DEFINITIVE DI CASSA (CS)
  		- importo RESIDUI ATTIVI (RS)
  		- importo RISCOSSIONI IN C/RESIDUI (RR)
  		- importo RISCOSSIONI IN C/COMPETENZA (RC)
  		- importo TOTALE RISCOSSIONI (TR)
  		- importo PREVISIONI DEFINITIVE DI COMPETENZA (CP).
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
            from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
capitoli as(
select cl.classif_id categoria_id,
  anno_eserc.anno anno_bilancio,
  e.elem_id
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and e.bil_id in (bilId)
and tipo_elemento.elem_tipo_code 	= 	'CAP-EG'
and	stato_capitolo.elem_stato_code	=	'VA'
and ct.classif_tipo_code			=	'CATEGORIA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
),
 a_accertamenti as (
 	select capitolo.elem_id,
		sum (dt_movimento.movgest_ts_det_importo) importo_accert
    from 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id      
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id  
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id  
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and movimento.ente_proprietario_id   = p_ente_prop_id         
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno = annoBilInt 
      and movimento.bil_id =bilId
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N       
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and now() 
 		between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
      and now() 
 		between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now()) 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null      
group by capitolo.elem_id),
rr_riscos_residui as (
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_riscoss
from 		siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
            siac_t_ordinativo				ordinativo,
            siac_d_ordinativo_tipo			tipo_ordinativo,
            siac_r_ordinativo_stato			r_stato_ordinativo,
            siac_d_ordinativo_stato			stato_ordinativo,
            siac_t_ordinativo_ts 			ordinativo_det,
			siac_t_ordinativo_ts_det 		ordinativo_imp,
        	siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
            siac_t_movgest     				movimento,
            siac_t_movgest_ts    			ts_movimento, 
            siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
    where 	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id 
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id   ------		           
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id    
        and	ordinativo.ente_proprietario_id	=	p_ente_prop_id
        and movimento.movgest_anno < annoBilInt 
        and movimento.bil_id =bilId
		and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
        and	stato_ordinativo.ord_stato_code			<> 'A'      
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuala        
        and	r_capitolo_ordinativo.data_cancellazione	is null
        and	ordinativo.data_cancellazione				is null
        AND	tipo_ordinativo.data_cancellazione			is null
        and	r_stato_ordinativo.data_cancellazione		is null
        AND	stato_ordinativo.data_cancellazione			is null
        AND ordinativo_det.data_cancellazione			is null
 	  	aND ordinativo_imp.data_cancellazione			is null
        and ordinativo_imp_tipo.data_cancellazione		is null
        and	movimento.data_cancellazione				is null
        and	ts_movimento.data_cancellazione				is null
        and	r_ordinativo_movgest.data_cancellazione		is null
    and now()
between r_capitolo_ordinativo.validita_inizio 
    and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now()
between r_stato_ordinativo.validita_inizio 
    and COALESCE(r_stato_ordinativo.validita_fine,now())
    and now()
between r_ordinativo_movgest.validita_inizio 
    and COALESCE(r_ordinativo_movgest.validita_fine,now())
        group by r_capitolo_ordinativo.elem_id) ,
rc_riscos_conto_comp as (
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_riscoss
from 		siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
            siac_t_ordinativo				ordinativo,
            siac_d_ordinativo_tipo			tipo_ordinativo,
            siac_r_ordinativo_stato			r_stato_ordinativo,
            siac_d_ordinativo_stato			stato_ordinativo,
            siac_t_ordinativo_ts 			ordinativo_det,
			siac_t_ordinativo_ts_det 		ordinativo_imp,
        	siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
            siac_t_movgest     				movimento,
            siac_t_movgest_ts    			ts_movimento, 
            siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
    where 	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id 
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id    
        and	ordinativo.ente_proprietario_id	=	p_ente_prop_id
        and movimento.movgest_anno = annoBilInt 
        and movimento.bil_id =bilId
		and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
        and	stato_ordinativo.ord_stato_code			<> 'A'      
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuala
        and	r_capitolo_ordinativo.data_cancellazione	is null
        and	ordinativo.data_cancellazione				is null
        AND	tipo_ordinativo.data_cancellazione			is null
        and	r_stato_ordinativo.data_cancellazione		is null
        AND	stato_ordinativo.data_cancellazione			is null
        AND ordinativo_det.data_cancellazione			is null
 	  	aND ordinativo_imp.data_cancellazione			is null
        and ordinativo_imp_tipo.data_cancellazione		is null
        and	movimento.data_cancellazione				is null
        and	ts_movimento.data_cancellazione				is null
        and	r_ordinativo_movgest.data_cancellazione		is null
    and now()
between r_capitolo_ordinativo.validita_inizio 
    and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now()
between r_stato_ordinativo.validita_inizio 
    and COALESCE(r_stato_ordinativo.validita_fine,now())
    and now()
between r_ordinativo_movgest.validita_inizio 
    and COALESCE(r_ordinativo_movgest.validita_fine,now())
        group by r_capitolo_ordinativo.elem_id),
prev_def_comp as (
select 		capitolo_importi.elem_id,
            sum(capitolo_importi.elem_det_importo) importo_prev_def_comp   
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						       
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno
        and	tipo_elemento.elem_tipo_code 		= 	'CAP-EG' 												
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo_imp_periodo.anno = 		p_anno
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and capitolo_imp_tipo.elem_det_tipo_code  = 'STA' -- stanziamento  (CP)
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
    group by capitolo_importi.elem_id),        
stanz_residui as (
select    
capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) importo_stanz_residui
    from       
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id      
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id       
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id       
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id       
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and capitolo.ente_proprietario_id   = p_ente_prop_id
      and capitolo.bil_id = bilId      
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno  	< p_anno::integer
      and tipo_mov.movgest_tipo_code    	= 'A'
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'I' 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
   	  and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
      and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())      
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
group by capitolo.elem_id      ) ,     
prev_def_cassa as (
select 		capitolo_importi.elem_id,
            sum(capitolo_importi.elem_det_importo) importo_prev_def_cassa  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						       
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno
        and	tipo_elemento.elem_tipo_code 		= 	'CAP-EG' 												
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo_imp_periodo.anno = 		p_anno
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and capitolo_imp_tipo.elem_det_tipo_code  = 'SCA' --  cassa	(CS)
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
    group by capitolo_importi.elem_id)      
SELECT  strut_bilancio.titolo_id::integer id_titolo,
		strut_bilancio.titolo_code::varchar code_titolo, 
		strut_bilancio.titolo_desc::varchar desc_titolo, 
        strut_bilancio.tipologia_id::integer id_tipologia,
        strut_bilancio.tipologia_code::varchar code_tipologia,
        strut_bilancio.tipologia_desc::varchar desc_tipologia,
        sum(COALESCE(a_accertamenti.importo_accert,0))::numeric importo_accertato_a,  
        sum(COALESCE(prev_def_cassa.importo_prev_def_cassa,0))::numeric importo_prev_def_cassa_cs,    
        sum(COALESCE(stanz_residui.importo_stanz_residui,0))::numeric importo_res_attivi_rs,
        sum(COALESCE(rr_riscos_residui.importo_riscoss,0))::numeric importo_risc_conto_res_rr,
        sum(COALESCE(rc_riscos_conto_comp.importo_riscoss,0))::numeric importo_risc_conto_comp_rc,
        sum(COALESCE(rr_riscos_residui.importo_riscoss,0)+
        	COALESCE(rc_riscos_conto_comp.importo_riscoss,0))::numeric importo_tot_risc_tr,
        sum(COALESCE(prev_def_comp.importo_prev_def_comp,0))::numeric importo_prev_def_comp_cp,
        ''::varchar display_error
FROM strut_bilancio
	LEFT JOIN capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
    LEFT JOIN a_accertamenti on a_accertamenti.elem_id = capitoli.elem_id
    LEFT JOIN rr_riscos_residui on rr_riscos_residui.elem_id = capitoli.elem_id   
    LEFT JOIN rc_riscos_conto_comp on rc_riscos_conto_comp.elem_id = capitoli.elem_id             
    LEFT JOIN prev_def_comp on prev_def_comp.elem_id = capitoli.elem_id   
    LEFT JOIN stanz_residui on stanz_residui.elem_id = capitoli.elem_id  
    LEFT JOIN prev_def_cassa on prev_def_cassa.elem_id = capitoli.elem_id                       
GROUP BY id_titolo, code_titolo, desc_titolo, 
		id_tipologia, code_tipologia, desc_tipologia
ORDER BY code_titolo, code_tipologia;
                    
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