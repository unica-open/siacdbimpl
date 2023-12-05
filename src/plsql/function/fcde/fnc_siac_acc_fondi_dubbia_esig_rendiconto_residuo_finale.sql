/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_acc_fondi_dubbia_esig_rendiconto_residuo_finale(integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_rendiconto_residuo_finale (
  elem_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
residuo_finale numeric;
residui_attivi_RS numeric;
accertamenti_A numeric;
risc_conto_comp_RC numeric;
risc_conto_residui_RR numeric;
riaccertamenti_residui_R numeric;
v_anno_bil				 varchar;
BEGIN
residui_attivi_RS :=0.0;
accertamenti_A :=0.0;
risc_conto_comp_RC :=0.0;
risc_conto_residui_RR :=0.0;
riaccertamenti_residui_R :=0.0;

select siac_t_periodo.anno into v_anno_bil
from siac_t_bil_elem, siac_t_bil, siac_t_periodo
where siac_t_bil_elem.bil_id = siac_t_bil.bil_id
and siac_t_bil.periodo_id = siac_t_periodo.periodo_id 
and siac_t_bil_elem.data_cancellazione is null 
and siac_t_bil_elem.elem_id = elem_id_in;

select  coalesce( sum (dt_movimento.movgest_ts_det_importo),0) into residui_attivi_RS
from 
	siac_t_bil                 bilancio, 
	siac_t_periodo             anno_eserc, 
	siac_t_bil_elem            capitolo , 
	siac_r_movgest_bil_elem    r_mov_capitolo, 
	siac_d_bil_elem_tipo       t_capitolo, 
	siac_t_movgest             movimento, 
	siac_d_movgest_tipo        tipo_mov, 
	siac_t_movgest_ts          ts_movimento, 
	siac_r_movgest_ts_stato    r_movimento_stato, 
	siac_d_movgest_stato       tipo_stato, 
	siac_t_movgest_ts_det      dt_movimento, 
	siac_d_movgest_ts_tipo     ts_mov_tipo, 
	siac_d_movgest_ts_det_tipo dt_mov_tipo 
where 
		bilancio.periodo_id    		 	 = 	anno_eserc.periodo_id 
	and bilancio.bil_id      				 =	capitolo.bil_id
	and capitolo.elem_tipo_id      		     = 	t_capitolo.elem_tipo_id
	and movimento.bil_id					 =	bilancio.bil_id
	and r_mov_capitolo.elem_id    		     =	capitolo.elem_id
	and r_mov_capitolo.movgest_id    		 = 	movimento.movgest_id 
	and movimento.movgest_tipo_id    		 = 	tipo_mov.movgest_tipo_id 
	and movimento.movgest_id      		     = 	ts_movimento.movgest_id 
	and ts_movimento.movgest_ts_id    	     = 	r_movimento_stato.movgest_ts_id 
	and r_movimento_stato.movgest_stato_id   = tipo_stato.movgest_stato_id 
	and ts_movimento.movgest_ts_tipo_id      = ts_mov_tipo.movgest_ts_tipo_id 
	and ts_movimento.movgest_ts_id    	     = dt_movimento.movgest_ts_id 
	and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
	--and anno_eserc.ente_proprietario_id    = v_ente_proprietario_id 
	and capitolo.elem_id                     = elem_id_in
	and anno_eserc.anno       			     =   v_anno_bil
	and t_capitolo.elem_tipo_code    		 = 	'CAP-EG'
	and movimento.movgest_anno  	 < 	v_anno_bil::integer
	and tipo_mov.movgest_tipo_code    	     = 'A'
	and tipo_stato.movgest_stato_code   in ('D','N')       
	and ts_mov_tipo.movgest_ts_tipo_code     = 'T'
	and dt_mov_tipo.movgest_ts_det_tipo_code = 'I'--'A' 
	and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
	and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	and anno_eserc.data_cancellazione    	 is null 
	and bilancio.data_cancellazione     	 is null 
	and capitolo.data_cancellazione     	 is null 
	and r_mov_capitolo.data_cancellazione    is null 
	and t_capitolo.data_cancellazione    	 is null 
	and movimento.data_cancellazione     	 is null 
	and tipo_mov.data_cancellazione     	 is null 
	and r_movimento_stato.data_cancellazione is null 
	and ts_movimento.data_cancellazione      is null 
	and tipo_stato.data_cancellazione    	 is null 
	and dt_movimento.data_cancellazione      is null 
	and ts_mov_tipo.data_cancellazione       is null 
	and dt_mov_tipo.data_cancellazione       is null
;
           

select  coalesce( sum (dt_movimento.movgest_ts_det_importo),0) into accertamenti_A
from 
	siac_t_bil                 bilancio, 
	siac_t_periodo             anno_eserc, 
	siac_t_bil_elem            capitolo , 
	siac_r_movgest_bil_elem    r_mov_capitolo, 
	siac_d_bil_elem_tipo       t_capitolo, 
	siac_t_movgest             movimento, 
	siac_d_movgest_tipo        tipo_mov, 
	siac_t_movgest_ts          ts_movimento, 
	siac_r_movgest_ts_stato    r_movimento_stato, 
	siac_d_movgest_stato       tipo_stato, 
	siac_t_movgest_ts_det      dt_movimento, 
	siac_d_movgest_ts_tipo     ts_mov_tipo, 
	siac_d_movgest_ts_det_tipo dt_mov_tipo 
where 
		bilancio.periodo_id    		 	 = 	anno_eserc.periodo_id 
	and bilancio.bil_id      				 =	capitolo.bil_id
	and capitolo.elem_tipo_id      		     = 	t_capitolo.elem_tipo_id
	and movimento.bil_id					 =	bilancio.bil_id
	and r_mov_capitolo.elem_id    		     =	capitolo.elem_id
	and r_mov_capitolo.movgest_id    		 = 	movimento.movgest_id 
	and movimento.movgest_tipo_id    		 = 	tipo_mov.movgest_tipo_id 
	and movimento.movgest_id      		     = 	ts_movimento.movgest_id 
	and ts_movimento.movgest_ts_id    	     = 	r_movimento_stato.movgest_ts_id 
	and r_movimento_stato.movgest_stato_id   = tipo_stato.movgest_stato_id 
	and ts_movimento.movgest_ts_tipo_id      = ts_mov_tipo.movgest_ts_tipo_id 
	and ts_movimento.movgest_ts_id    	     = dt_movimento.movgest_ts_id 
	and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
	and capitolo.elem_id                     = elem_id_in
	and anno_eserc.anno       			     =   v_anno_bil 
	and t_capitolo.elem_tipo_code    		 = 	'CAP-EG'
	and movimento.movgest_anno  	         = 	v_anno_bil::integer
	and tipo_mov.movgest_tipo_code    	     = 'A'
	and tipo_stato.movgest_stato_code   in ('D','N')       
	and ts_mov_tipo.movgest_ts_tipo_code     = 'T'
	and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' 
	and now() between r_mov_capitolo.validita_inizio  and COALESCE(r_mov_capitolo.validita_fine,now())
	and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	and anno_eserc.data_cancellazione    	 is null 
	and bilancio.data_cancellazione     	 is null 
	and capitolo.data_cancellazione     	 is null 
	and r_mov_capitolo.data_cancellazione    is null 
	and t_capitolo.data_cancellazione    	 is null 
	and movimento.data_cancellazione     	 is null 
	and tipo_mov.data_cancellazione     	 is null 
	and r_movimento_stato.data_cancellazione is null 
	and ts_movimento.data_cancellazione      is null 
	and tipo_stato.data_cancellazione    	 is null 
	and dt_movimento.data_cancellazione      is null 
	and ts_mov_tipo.data_cancellazione       is null 
	and dt_mov_tipo.data_cancellazione       is null              
	;

select  coalesce( sum (ordinativo_imp.ord_ts_det_importo),0) into risc_conto_comp_RC
from 
	siac_t_bil 			            bilancio,
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
where 
		bilancio.periodo_id					    =	anno_eserc.periodo_id
	and	r_capitolo_ordinativo.ord_id		        =	ordinativo.ord_id
	and	ordinativo.ord_tipo_id				        =	tipo_ordinativo.ord_tipo_id
	and	ordinativo.ord_id					        =	r_stato_ordinativo.ord_id
	and	r_stato_ordinativo.ord_stato_id		        =	stato_ordinativo.ord_stato_id
	and	ordinativo.bil_id					        =	bilancio.bil_id
	and	ordinativo.ord_id					        =	ordinativo_det.ord_id
	and	ordinativo_det.ord_ts_id			        =	ordinativo_imp.ord_ts_id
	and	ordinativo_imp.ord_ts_det_tipo_id	        =	ordinativo_imp_tipo.ord_ts_det_tipo_id
	and	r_ordinativo_movgest.ord_ts_id		        =	ordinativo_det.ord_ts_id
	and	r_ordinativo_movgest.movgest_ts_id	        =	ts_movimento.movgest_ts_id
	and	ts_movimento.movgest_id				        =	movimento.movgest_id
	and movimento.bil_id					        =	bilancio.bil_id								   		
	and	r_capitolo_ordinativo.elem_id	            =	elem_id_in
	and	anno_eserc.anno						        = 	v_anno_bil
	and	tipo_ordinativo.ord_tipo_code		        = 	'I'	--Ordnativo di incasso
	and	stato_ordinativo.ord_stato_code		       <> 'A'
	and	ordinativo_imp_tipo.ord_ts_det_tipo_code	= 'A' -- importo attuala
	and	movimento.movgest_anno				        =	v_anno_bil::integer	        	
	and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
	and	r_capitolo_ordinativo.data_cancellazione	is null
	and	ordinativo.data_cancellazione				is null
	and	tipo_ordinativo.data_cancellazione			is null
	and	r_stato_ordinativo.data_cancellazione		is null
	and	stato_ordinativo.data_cancellazione			is null
	and ordinativo_det.data_cancellazione			is null
	and ordinativo_imp.data_cancellazione			is null
	and ordinativo_imp_tipo.data_cancellazione		is null
	and	movimento.data_cancellazione				is null
	and	ts_movimento.data_cancellazione				is null
	and	r_ordinativo_movgest.data_cancellazione		is null
	and now() between r_capitolo_ordinativo.validita_inizio and COALESCE(r_capitolo_ordinativo.validita_fine,now())
	and now() between r_stato_ordinativo.validita_inizio and COALESCE(r_stato_ordinativo.validita_fine,now())
	and now() between r_ordinativo_movgest.validita_inizio and COALESCE(r_ordinativo_movgest.validita_fine,now())  
;


select  coalesce( sum (ordinativo_imp.ord_ts_det_importo),0) into risc_conto_residui_RR
from 
	siac_t_bil 				        bilancio,
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
where
		bilancio.periodo_id					    =	anno_eserc.periodo_id
	and	r_capitolo_ordinativo.ord_id		        =	ordinativo.ord_id
	and	ordinativo.ord_tipo_id				        =	tipo_ordinativo.ord_tipo_id
	and	ordinativo.ord_id					        =	r_stato_ordinativo.ord_id
	and	r_stato_ordinativo.ord_stato_id		        =	stato_ordinativo.ord_stato_id
	and	ordinativo.bil_id					        =	bilancio.bil_id
	and	ordinativo.ord_id					        =	ordinativo_det.ord_id
	and	ordinativo_det.ord_ts_id			        =	ordinativo_imp.ord_ts_id
	and	ordinativo_imp.ord_ts_det_tipo_id	        =	ordinativo_imp_tipo.ord_ts_det_tipo_id
	and	r_ordinativo_movgest.ord_ts_id		        =	ordinativo_det.ord_ts_id
	and	r_ordinativo_movgest.movgest_ts_id	        =	ts_movimento.movgest_ts_id
	and	ts_movimento.movgest_id				        =	movimento.movgest_id
	and movimento.bil_id					        =	bilancio.bil_id								   		
	and r_capitolo_ordinativo.elem_id	            =	elem_id_in
	and	anno_eserc.anno						        = 	v_anno_bil
	and	tipo_ordinativo.ord_tipo_code		        = 	'I'	--Ordnativo di incasso
	and	stato_ordinativo.ord_stato_code		        <> 'A'
	and	ordinativo_imp_tipo.ord_ts_det_tipo_code	= 'A' -- importo attuala
	and	movimento.movgest_anno				        <	v_anno_bil::integer	        	
	and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
	and	r_capitolo_ordinativo.data_cancellazione	is null
	and	ordinativo.data_cancellazione				is null
	and	tipo_ordinativo.data_cancellazione			is null
	and	r_stato_ordinativo.data_cancellazione		is null
	and	stato_ordinativo.data_cancellazione			is null
	and ordinativo_det.data_cancellazione			is null
	and ordinativo_imp.data_cancellazione			is null
	and ordinativo_imp_tipo.data_cancellazione		is null
	and	movimento.data_cancellazione				is null
	and	ts_movimento.data_cancellazione				is null
	and	r_ordinativo_movgest.data_cancellazione		is null
	and now() between r_capitolo_ordinativo.validita_inizio and COALESCE(r_capitolo_ordinativo.validita_fine,now())
	and now() between r_stato_ordinativo.validita_inizio and COALESCE(r_stato_ordinativo.validita_fine,now())
	and now() between r_ordinativo_movgest.validita_inizio and COALESCE(r_ordinativo_movgest.validita_fine,now())  
;

select  coalesce( sum (t_movgest_ts_det_mod.movgest_ts_det_importo),0) into riaccertamenti_residui_R
from 
	siac_t_bil                 bilancio, 
	siac_t_periodo             anno_eserc, 
	siac_t_bil_elem            capitolo , 
	siac_r_movgest_bil_elem    r_mov_capitolo, 
	siac_d_bil_elem_tipo       t_capitolo, 
	siac_t_movgest             movimento, 
	siac_d_movgest_tipo        tipo_mov, 
	siac_t_movgest_ts          ts_movimento, 
	siac_r_movgest_ts_stato    r_movimento_stato, 
	siac_d_movgest_stato       tipo_stato, 
	siac_t_movgest_ts_det      dt_movimento, 
	siac_d_movgest_ts_tipo     ts_mov_tipo, 
	siac_d_movgest_ts_det_tipo dt_mov_tipo ,
	siac_t_modifica            t_modifica,
	siac_r_modifica_stato      r_mod_stato,
	siac_d_modifica_stato      d_mod_stato,
	siac_t_movgest_ts_det_mod  t_movgest_ts_det_mod
where
		bilancio.periodo_id    		 	 = 	anno_eserc.periodo_id
	and bilancio.bil_id      				 =	capitolo.bil_id
	and movimento.bil_id					 =	bilancio.bil_id
	and r_mov_capitolo.elem_id    		     =	capitolo.elem_id
	and r_mov_capitolo.movgest_id    		 = 	movimento.movgest_id 
	and movimento.movgest_tipo_id    		 = 	tipo_mov.movgest_tipo_id 
	and capitolo.elem_tipo_id      		     = 	t_capitolo.elem_tipo_id
	and movimento.movgest_id      		     = 	ts_movimento.movgest_id 
	and ts_movimento.movgest_ts_id    	     = 	r_movimento_stato.movgest_ts_id 
	and r_movimento_stato.movgest_stato_id   = tipo_stato.movgest_stato_id 
	and ts_movimento.movgest_ts_tipo_id      = ts_mov_tipo.movgest_ts_tipo_id
	and ts_movimento.movgest_ts_id    	     = dt_movimento.movgest_ts_id 
	and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
	and t_movgest_ts_det_mod.movgest_ts_id   =ts_movimento.movgest_ts_id      
	and t_movgest_ts_det_mod.mod_stato_r_id  =r_mod_stato.mod_stato_r_id
	and d_mod_stato.mod_stato_id             =r_mod_stato.mod_stato_id  
	and r_mod_stato.mod_id                   =t_modifica.mod_id      
	and capitolo.elem_id                     = elem_id_in        
	and anno_eserc.anno       			     =   v_anno_bil 
	and t_capitolo.elem_tipo_code    		 = 	'CAP-EG'
	and movimento.movgest_anno   			 < 	v_anno_bil::integer
	and tipo_mov.movgest_tipo_code    	     = 'A' --Accertamento 
	and tipo_stato.movgest_stato_code   in ('D','N')       
	and ts_mov_tipo.movgest_ts_tipo_code     = 'T' --Testata
	and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' --importo attuale 
	and d_mod_stato.mod_stato_code='V'            
	and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
	and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	and now()between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
	and anno_eserc.data_cancellazione    	    is null 
	and bilancio.data_cancellazione     	    is null 
	and capitolo.data_cancellazione     	    is null 
	and r_mov_capitolo.data_cancellazione       is null 
	and t_capitolo.data_cancellazione    	    is null 
	and movimento.data_cancellazione     	    is null 
	and tipo_mov.data_cancellazione     	    is null 
	and r_movimento_stato.data_cancellazione    is null 
	and ts_movimento.data_cancellazione         is null 
	and tipo_stato.data_cancellazione     	    is null 
	and dt_movimento.data_cancellazione         is null 
	and ts_mov_tipo.data_cancellazione          is null 
	and dt_mov_tipo.data_cancellazione          is null
	and t_movgest_ts_det_mod.data_cancellazione is null
	and r_mod_stato.data_cancellazione          is null
	and t_modifica.data_cancellazione           is null   
;

residuo_finale = (accertamenti_A - risc_conto_comp_RC) + (residui_attivi_RS - risc_conto_residui_RR + riaccertamenti_residui_R);

return residuo_finale;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;