/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR150_prosp_dimos_ris_amm_entrate" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  rr_totale_risc_residui numeric,
  rc_totale_risc_competenza numeric,
  r_totale_riacc_residui numeric,
  rs_totale_residui_attivi numeric,
  a_totale_accertamenti numeric
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp_int integer;
TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_movgest_tipo varchar:='A';
v_movgest_ts_tipo varchar :='T';

v_det_tipo_importo_attuale varchar:='A';
v_det_tipo_importo_iniziale varchar:='I';
v_ord_stato_code_annullato varchar:='A';
v_ord_tipo_code_incasso varchar:='I';
v_fam_titolotipologiacategoria varchar:='00003';


BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;  

TipoImpstanzresidui='SRI'; -- stanziamento residuo post (RS)
TipoImpstanz='STA'; -- stanziamento  (CP)
TipoImpCassa ='SCA'; ----- cassa	(CS)
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

rr_totale_risc_residui:=0;
rc_totale_risc_competenza:=0;
r_totale_riacc_residui:=0;
rs_totale_residui_attivi:=0;
a_totale_accertamenti:=0;

RTN_MESSAGGIO:='Estrazione dei dati delle riscossioni.';
raise notice '%',RTN_MESSAGGIO;

raise notice '5 - %' , clock_timestamp()::text;

 
return query
with capent as (
select e.elem_id
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
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	'CAP-EG'
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
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
-- 14/04/2017: corretto il controllo sulle date.
/*and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between rc.validita_inizio and COALESCE(rc.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
*/
and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
),
 riscossioni_res as (
select 	 r_capitolo_ordinativo.elem_id,
	 sum(ordinativo_imp.ord_ts_det_importo) riscossioni
from 		siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc, 
            siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
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
    where 	anno_eserc.anno						= 	p_anno											
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	bilancio.ente_proprietario_id	=	p_ente_prop_id
        and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
		and	tipo_ordinativo.ord_tipo_code		= 	v_ord_tipo_code_incasso		------ incasso
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
        and	stato_ordinativo.ord_stato_code			<> v_ord_stato_code_annullato --- 
        -----------------------------------------------------------------------------------------------
        and	ordinativo.bil_id					=	bilancio.bil_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	v_det_tipo_importo_attuale 	---- importo attuala
        ---------------------------------------------------------------------------------------------------------------------
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id
        and	movimento.movgest_anno				<	annoCapImp_int	
        and movimento.bil_id					=	bilancio.bil_id	
        --------------------------------------------------------------------------------------------------------------------		
        and	bilancio.data_cancellazione 				is null
        and	anno_eserc.data_cancellazione 				is null
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
riscossioni_comp as (
select 	 r_capitolo_ordinativo.elem_id,
	 sum(ordinativo_imp.ord_ts_det_importo) riscossioni
from 		siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc, 
            siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
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
    where 	anno_eserc.anno						= 	p_anno											
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	bilancio.ente_proprietario_id	=	p_ente_prop_id
        and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
		and	tipo_ordinativo.ord_tipo_code		= 	v_ord_tipo_code_incasso		------ incasso
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
        and	stato_ordinativo.ord_stato_code			<> v_ord_stato_code_annullato --- 
        -----------------------------------------------------------------------------------------------
        and	ordinativo.bil_id					=	bilancio.bil_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	v_det_tipo_importo_attuale 	---- importo attuala
        ---------------------------------------------------------------------------------------------------------------------
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id
        and	movimento.movgest_anno				=	annoCapImp_int	
        and movimento.bil_id					=	bilancio.bil_id	
        --------------------------------------------------------------------------------------------------------------------		
        and	bilancio.data_cancellazione 				is null
        and	anno_eserc.data_cancellazione 				is null
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
riacc_residui as(
 select    
   capitolo.elem_id,
   sum (t_movgest_ts_det_mod.movgest_ts_det_importo) riacc_residui
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
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
      siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
      siac_t_modifica t_modifica,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      and movimento.movgest_anno ::text  	< 	p_anno
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= v_movgest_tipo 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = v_movgest_ts_tipo
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = v_det_tipo_importo_attuale ----- importo attuale 
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and d_mod_stato.mod_stato_code='V'
      and r_mod_stato.mod_id=t_modifica.mod_id      	
      and now() 
		between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() 
 		between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now()
 		between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
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
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
      group by capitolo.elem_id )  ,
residui_attivi as (
select    
capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) residui
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
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
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno  			< 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= v_movgest_tipo
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = v_movgest_ts_tipo
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = v_det_tipo_importo_iniziale ----- importo attuale 
      -- INC000001913168 Inizio
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())        
      and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())         
      --and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
      --and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
      -- INC000001913168 Fine
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
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
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id)  ,
accertamenti as (
select    
capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) imp_accertamenti
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
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
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno 		  	= 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= v_movgest_tipo 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = v_movgest_ts_tipo 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = v_det_tipo_importo_attuale ----- importo attuale 	  
      and now() 
 		between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
      and now() 
 		between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now()) 
   	  and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
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
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id)  
select sum(riscossioni_res.riscossioni) rr_totale_risc_residui,
		sum(riscossioni_comp.riscossioni) rc_totale_risc_competenza,
        sum(riacc_residui.riacc_residui) r_totale_riacc_residui,
        sum(residui_attivi.residui) rs_totale_residui_attivi,
        sum(accertamenti.imp_accertamenti) a_totale_accertamenti             
	from capent
    	left join riscossioni_res
        	on capent.elem_id=riscossioni_res.elem_id
    	left join riscossioni_comp
        	on capent.elem_id=riscossioni_comp.elem_id
        left join riacc_residui
        	on capent.elem_id=riacc_residui.elem_id 
        left join residui_attivi
        	on capent.elem_id=residui_attivi.elem_id  
        left join accertamenti 
        	on capent.elem_id=accertamenti.elem_id ;   


exception
	when no_data_found THEN
		raise notice 'nessun dato trovato per le entrate.' ;
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
COST 100 ROWS 1000;