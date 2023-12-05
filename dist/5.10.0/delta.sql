/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

--- 11.07.2022 Sofia SIAC-8759 - inizio 
drop view if exists siac.siac_v_dwh_vincoli_st_imp_acc;
CREATE OR REPLACE VIEW siac.siac_v_dwh_vincoli_st_imp_acc
(
    ente_proprietario_id,
    bil_code,
    anno_bilancio,
    anno_impegno,
    numero_impegno,
    anno_accertamento,
    numero_accertamento ,
    numero_subaccertamento
    )
AS
(
SELECT 
       bil.ente_proprietario_id,
       bil.bil_code,
       per.anno AS anno_bilancio,
       mov.movgest_anno as anno_impegno,
       mov.movgest_numero::integer AS numero_impegno,
       r.movgest_anno_acc  as anno_accertamento,
       r.movgest_numero_acc as numero_accertamento,
       r.movgest_subnumero_acc as  numero_subaccertamento
FROM  siac_t_movgest mov,siac_d_movgest_tipo tipo ,
              siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipo_ts,
              siac_t_bil bil,siac_t_periodo per,
              siac_r_movgest_ts_storico_imp_acc r 
where tipo.movgest_tipo_code='I'
and     mov.movgest_tipo_id=tipo.movgest_tipo_id 
and     ts.movgest_id=mov.movgest_id 
and     tipo_ts.movgest_ts_tipo_id=ts.movgest_ts_tipo_id 
and     tipo_ts.movgest_ts_tipo_code='T'
and     bil.bil_id=mov.bil_id 
and     per.periodo_id=bil.periodo_id 
and     r.movgest_ts_id =ts.movgest_ts_id 
and     mov.data_cancellazione IS NULL
AND   mov.validita_fine IS NULL
AND   ts.data_cancellazione IS NULL
AND   ts.validita_fine IS NULL
AND   r.data_cancellazione IS NULL
AND   r.validita_fine IS NULL
AND   bil.data_cancellazione IS NULL
AND   per.data_cancellazione IS null);

alter view siac.siac_v_dwh_vincoli_st_imp_acc owner to siac;
--  11.07.2022 Sofia SIAC-8759 - fine 

--SIAC-8758 - Maurizio - INIZIO

update siac_r_class_fam_tree
set data_modifica=now(),
	validita_fine=to_timestamp('31/12/2018','dd/MM/yyyy'),
    data_cancellazione=to_timestamp('31/12/2018','dd/MM/yyyy'),
    login_operazione= login_operazione||' - SIAC-8758'
where classif_classif_fam_tree_id in(select a.classif_classif_fam_tree_id    
from siac_r_class_fam_tree a,
	siac_t_class b
where a.classif_id=b.classif_id
and upper(a.ordine)='B.13.A'
and a.data_cancellazione IS NULL);

--SIAC-8758 - Maurizio - FINE


drop table if exists siac_t_parametro_config_ente;
create table if not exists siac_t_parametro_config_ente (
	parametro_id serial NOT NULL,
	ente_proprietario_id integer NOT NULL,
	parametro_nome varchar NOT NULL,
	parametro_valore varchar NULL,
	parametro_abilitato boolean not null default true,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT siac_t_ente_proprietario_siac_r_ordinativo_contotes_nodisp 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);

--SIAC-8767 INIZIO
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
--SIAC-8767 FINE

--SIAC-8768 INIZIO
DROP FUNCTION IF EXISTS siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil(INTEGER);
CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil(p_afde_bil_id INTEGER)
	RETURNS TABLE(
		versione                     INTEGER,
		fase_attributi_bilancio      VARCHAR,
		stato_attributi_bilancio     VARCHAR,
--		utente                       VARCHAR,
		data_ora_elaborazione        TIMESTAMP WITHOUT TIME ZONE,
		anni_esercizio               VARCHAR,
		riscossione_virtuosa		 BOOLEAN,
		quinquennio_riferimento      VARCHAR,
		capitolo                     VARCHAR,
		articolo                     VARCHAR,
		ueb                          VARCHAR,
		titolo_entrata               VARCHAR,
		tipologia                    VARCHAR,
		categoria                    VARCHAR,
		sac                          VARCHAR,
		incasso_conto_competenza     NUMERIC,
		accertato_conto_competenza   NUMERIC,
--		stanziato                    NUMERIC,
--		max_stanziato_accertato_0    NUMERIC,
--		max_stanziato_accertato_1    NUMERIC,
--		max_stanziato_accertato_2    NUMERIC,
		percentuale_incasso_gestione NUMERIC,
		percentuale_accantonamento   NUMERIC,
		tipo_precedente              VARCHAR,
		percentuale_precedente       NUMERIC,
		percentuale_minima           NUMERIC,
		percentuale_effettiva        NUMERIC,
		stanziamento_0               NUMERIC,
		stanziamento_1               NUMERIC,
		stanziamento_2               NUMERIC,
		accantonamento_fcde_0        NUMERIC,
		accantonamento_fcde_1        NUMERIC,
		accantonamento_fcde_2        NUMERIC,
		accantonamento_graduale      NUMERIC,
		--SIAC-8768
		stanz_senza_var_0              NUMERIC,
		stanz_senza_var_1              NUMERIC,
		stanz_senza_var_2              NUMERIC,
		delta_var_0                  NUMERIC,
		delta_var_1                  NUMERIC,
		delta_var_2                  NUMERIC
	) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		)
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				--SIAC-8513 la gestione ha subito delle modifiche, attualmente se non e' presente la media utente
				WHEN 'UTENTE'   THEN 
					v_componente_cento - COALESCE(
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente,
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali,
						--TODO ci sarebbe da mettere la percentuale sullo stanziamento
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto,
						0
					)
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			--SIAC-8768
			, COALESCE(comp_capitolo0.impSta, 0) AS stanz_senza_var_0
			, COALESCE(var_capitolo0.impSta, 0) AS delta_var_0
			, COALESCE(comp_capitolo1.impSta, 0) AS stanz_senza_var_1
			, COALESCE(var_capitolo1.impSta, 0) AS delta_var_1
			, COALESCE(comp_capitolo2.impSta, 0) AS stanz_senza_var_2
			, COALESCE(var_capitolo2.impSta, 0) AS delta_var_2
			--, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS stanziamento_0
			--, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS stanziamento_1
			--, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS stanziamento_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
		percentuale_effettiva := v_loop_var.acc_fde_media;
		--stanziamento_0        := v_loop_var.stanziamento_0;
		--stanziamento_1        := v_loop_var.stanziamento_1;
		--stanziamento_2        := v_loop_var.stanziamento_2;
		stanz_senza_var_0     := v_loop_var.stanz_senza_var_0;
		stanz_senza_var_1     := v_loop_var.stanz_senza_var_1;
		stanz_senza_var_2     := v_loop_var.stanz_senza_var_2;
		delta_var_0           := v_loop_var.delta_var_0;
		delta_var_1           := v_loop_var.delta_var_1;
		delta_var_2           := v_loop_var.delta_var_2;
		--SIAC-8768
		
		stanziamento_0 := v_loop_var.stanz_senza_var_0 + v_loop_var.delta_var_0;
		stanziamento_1 := v_loop_var.stanz_senza_var_1 + v_loop_var.delta_var_1;
		stanziamento_2 := v_loop_var.stanz_senza_var_2 + v_loop_var.delta_var_2;
		
		-- /10000 perche' ho due percentuali per cui moltiplico (v_loop_var.acc_fde_media e accantonamento_graduale)
		-- SIAC-8446: arrotondo gli importi a due cifre decimali
		accantonamento_fcde_0 := ROUND(stanziamento_0 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		accantonamento_fcde_1 := ROUND(stanziamento_1 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		accantonamento_fcde_2 := ROUND(stanziamento_2 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
			, siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_desc
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
--				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
--				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
		INTO
			  incasso_conto_competenza
			, accertato_conto_competenza
			, percentuale_incasso_gestione
			, percentuale_accantonamento
			, tipo_precedente
			, percentuale_precedente
			, percentuale_minima
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media_confronto ON (siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_conf_id AND siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.data_cancellazione IS NULL)
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-8768 FINE


-- SIAC 8703
ALTER table siac.siac_t_parametro_config_ente ADD if not exists parametro_note text NULL;



insert into siac_t_parametro_config_ente (
	ente_proprietario_id,
	parametro_nome,
	parametro_valore,
	parametro_note,
	validita_inizio,
	login_operazione 
) select 
	e.ente_proprietario_id ,
	x.nome,
	null,
	x.note,
	now(),
	'admin'
 from siac_t_ente_proprietario e, 
(values ('OOPP.progetto.defaultAttoAmm.id', 'Atto amministrativo di default per inserisciProgetto da OOPP')) as x (nome, note) 
where not exists ( select 1 from siac_t_parametro_config_ente p where parametro_nome = x.nome and e.ente_proprietario_id = p.ente_proprietario_id); 

-- SIAC 8703 FINE

--SIAC-8785 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR111_Allegato_9_bil_gest_spesa_mpt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_disavanzo boolean,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
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
  fase_bilancio varchar,
  capitolo_prec integer,
  bil_ele_code3 varchar,
  previsioni_anno_prec_comp numeric,
  previsioni_anno_prec_cassa numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;
ImpegniRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
esiste_siac_t_dicuiimpegnato_bilprev integer;
annoPrec VARCHAR;
annobilint integer :=0;
previsioni_anno_prec_cassa_app NUMERIC;
previsioni_anno_prec_comp_app NUMERIC;
tipo_categ_capitolo VARCHAR;
stanziamento_fpv_anno_prec_app NUMERIC;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
v_importo_imp   NUMERIC :=0;
v_importo_imp1  NUMERIC :=0;
v_importo_imp2  NUMERIC :=0;
v_conta_rec INTEGER :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
-- ALESSANDRO - SIAC-5208 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- ALESSANDRO - SIAC-5208 - FINE

contaParVarPeg integer;
contaParVarBil integer;

BEGIN

annobilint := p_anno::INTEGER;
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP-UG';	--- Capitolo gestione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
display_error='';
contaParVarPeg:=0;
contaParVarBil:=0;

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

--INC000004803136 10/03/2021.
--Controllo aggiunto per ovviare ad un errato passaggio di parametri dal report.
--Dovra' essere tolto quando il report sara' corretto.
if p_code_sac_direz_peg = '99' then
	p_code_sac_direz_peg:='999';
end if;
if p_code_sac_direz_bil = '99' then
	p_code_sac_direz_bil:='999';
end if;


/* 25/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;

select fnc_siac_random_user()
into	user_table;

raise notice '1: %', clock_timestamp()::varchar;  
-- raise notice 'user  %',user_table;

/* 06/09/2016: eliminata lettura fase di bilancio perche' NON necessaria.
begin
     RTN_MESSAGGIO:='lettura anno di bilancio''.';  
for classifBilRec in
select 	anno_eserc.anno BIL_ANNO, 
        r_fase.bil_fase_operativa_id, 
        fase.fase_operativa_desc, 
        fase.fase_operativa_code fase_bilancio
from 	siac_t_bil 						bilancio,
		siac_t_periodo 					anno_eserc,
        siac_d_periodo_tipo				tipo_periodo,
        siac_r_bil_fase_operativa 		r_fase,
        siac_d_fase_operativa  			fase
where	anno_eserc.anno						=	p_anno							and	
		bilancio.periodo_id					=	anno_eserc.periodo_id			and
        tipo_periodo.periodo_tipo_code		=	'SY'							and
        anno_eserc.ente_proprietario_id		=	p_ente_prop_id					and
        tipo_periodo.periodo_tipo_id		=	anno_eserc.periodo_tipo_id		and
        r_fase.bil_id						=	bilancio.bil_id					AND
        r_fase.fase_operativa_id			=	fase.fase_operativa_id			and
        bilancio.data_cancellazione			is null								and							
		anno_eserc.data_cancellazione		is null								and	
        tipo_periodo.data_cancellazione		is null								and	
       	r_fase.data_cancellazione			is null								and	
        fase.data_cancellazione				is null								and
        now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())			and		
        now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())		and
        now() between tipo_periodo.validita_inizio and coalesce (tipo_periodo.validita_fine, now())	and        
        now() between r_fase.validita_inizio and coalesce (r_fase.validita_fine, now())				and
		now() between fase.validita_inizio and coalesce (fase.validita_fine, now())

loop
   fase_bilancio:=classifBilRec.fase_bilancio;
--raise notice 'Fase bilancio  %',classifBilRec.fase_bilancio;

anno_bil_impegni:=p_anno;

  if classifBilRec.fase_bilancio = 'P'  then
      anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;
  else
      anno_bil_impegni:=p_anno;
  end if;
end loop;

exception
	when no_data_found THEN
		raise notice 'Fase del bilancio non trovata';
	return;
	when others  THEN
        RTN_MESSAGGIO:='errore ricerca fase bilancio';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
       return;
end; */

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
tipologia_capitolo='';
previsioni_anno_prec_comp=0;
previsioni_anno_prec_cassa=0;
stanziamento_fpv_anno_prec=0;
      
     RTN_MESSAGGIO:='lettura struttura del bilancio''.';  
raise notice '2: %', clock_timestamp()::varchar;  
/* insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
--------siac_v_mis_pro_tit_macr_anni 
 where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;
*/

-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 06/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;

raise notice '3: %', clock_timestamp()::varchar; 
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up''.';  
insert into siac_rep_cap_up 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
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
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    ---------and	cat_del_capitolo.elem_cat_code	=	'STD'	
    -- 06/09/2016: aggiunto FPVC
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
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
    and	r_cat_capitolo.data_cancellazione 	 		is null;	


--09/05/2016: carico nella tabella di appoggio con i capitoli gli eventuali 
-- capitoli presenti sulla tabella con gli importi previsti anni precedenti
-- che possono avere cambiato numero di capitolo. 
/*insert into siac_rep_cap_up 
select programma.classif_id, macroaggr.classif_id, p_anno, NULL, prec.elem_code, prec.elem_code2, 
      	prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, NULL, user_table utente
      from siac_t_cap_u_importi_anno_prec prec,
        siac_d_class_tipo programma_tipo,
        siac_d_class_tipo macroaggr_tipo,
        siac_t_class programma,
        siac_t_class macroaggr
      where programma_tipo.classif_tipo_id	=	programma.classif_tipo_id
      and programma.classif_code=prec.programma_code
      and programma_tipo.classif_tipo_code	=	'PROGRAMMA'
      and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 	
      and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'
      and macroaggr.classif_code=prec.macroagg_code
      and programma.ente_proprietario_id =prec.ente_proprietario_id
      and macroaggr.ente_proprietario_id =prec.ente_proprietario_id
      and prec.ente_proprietario_id=p_ente_prop_id       
      and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy')
		between programma.validita_inizio and
       COALESCE(programma.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
      and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy')
		between macroaggr.validita_inizio and
       COALESCE(macroaggr.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
      and not exists (select 1 from siac_rep_cap_up up
      				where up.elem_code=prec.elem_code
                    	AND up.elem_code2=prec.elem_code2
                        and up.elem_code3=prec.elem_code3
                        and up.macroaggregato_id = macroaggr.classif_id
                        and up.programma_id = programma.classif_id
                        and up.utente=user_table
                        and up.ente_proprietario_id=p_ente_prop_id);*/

-- REMEDY INC000001514672
-- Select ricostruita considerando la condizione sull'anno nella tabella siac_t_cap_u_importi_anno_prec                        
insert into siac_rep_cap_up                        
with prec as (       
select * From siac_t_cap_u_importi_anno_prec a
where a.anno=annoPrec       
and a.ente_proprietario_id=p_ente_prop_id
)
, progr as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'PROGRAMMA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)
, macro as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'MACROAGGREGATO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)
select progr.classif_id classif_id_programma, macro.classif_id classif_id_macroaggregato, p_anno,
NULL, prec.elem_code, prec.elem_code2,
       prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, NULL, user_table utente
 from prec
join progr on prec.programma_code=progr.classif_code
join macro on prec.macroagg_code=macro.classif_code
and not exists (select 1 from siac_rep_cap_up up
                      where up.elem_code=prec.elem_code
                        AND up.elem_code2=prec.elem_code2
                        and up.elem_code3=prec.elem_code3
                        and up.macroaggregato_id = macro.classif_id
                        and up.programma_id = progr.classif_id
                        and up.utente=user_table
                        and up.ente_proprietario_id=prec.ente_proprietario_id);
                    
-----------------   importo capitoli di tipo standard ------------------------

     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp standard''.';  
raise notice '4: %', clock_timestamp()::varchar; 
insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo       
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
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPV (che era in query successiva che 
        -- e' stata tolta) e FPVC
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')						
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

-----------------   importo capitoli di tipo fondo pluriennale vincolato ------------------------
  
-----------------------------------------------------------------------------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga STD''.';  


raise notice '5: %', clock_timestamp()::varchar; 
insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
         where			
    	tb1.elem_id	=	tb2.elem_id
        and 
        tb2.elem_id	=	tb3.elem_id
        and 
        tb3.elem_id	=	tb4.elem_id
        and 
        tb4.elem_id	=	tb5.elem_id
        and 
        tb5.elem_id	=	tb6.elem_id
        and
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp			and	tb1.tipo_capitolo 		in ('STD','FSC')
        AND
        tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp 		and	tb2.tipo_capitolo		in ('STD','FSC')
        and
        tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp		and	tb3.tipo_capitolo		in ('STD','FSC')		 
        and 
    	tb4.periodo_anno = tb1.periodo_anno AND	tb4.tipo_imp = 	TipoImpRes		and	tb4.tipo_capitolo		in ('STD','FSC')
        and 
    	tb5.periodo_anno = tb1.periodo_anno AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo	in ('STD','FSC')
        and 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa	and	tb6.tipo_capitolo		in ('STD','FSC')
        and tb1.utente 	= 	tb2.utente	
        and	tb2.utente	=	tb3.utente
        and	tb3.utente	=	tb4.utente
        and	tb4.utente	=	tb5.utente
        and tb5.utente	=	tb6.utente
        and	tb6.utente	=	user_table;

raise notice '6: %', clock_timestamp()::varchar; 
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga FPV''.'; 
     
     
/* SIAC-8785 03/08/2022.
   Per gli importi dei capitoli FPV occorre inserire anche la cassa e
   i residui per prevenire eventuali errori di importi inseriti come FPV che poi
   eventualmente potrebbero essere tolti tramite variazione */                    
/*      
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where		
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND -- 06/09/2016: aggiunto FPVC
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	IN ('FPV','FPVC')
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		IN ('FPV','FPVC')
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		IN ('FPV','FPVC')
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;
*/

-- insert modificata per SIAC-8785: inseriti anche cassa e residui per PFV.
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	tb11.importo	as		stanziamento_prev_res_anno,
    	0,
    	tb12.importo 	as 		stanziamento_prev_cassa_anno,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente 
from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10, siac_rep_cap_up_imp tb11, siac_rep_cap_up_imp tb12
where tb7.elem_id	=	tb8.elem_id 
and tb8.elem_id	=	tb9.elem_id
and  tb9.elem_id	=	tb10.elem_id 
and  tb10.elem_id	=	tb11.elem_id 
and  tb11.elem_id	=	tb12.elem_id 
AND  -- 06/09/2016: aggiunto FPVC
	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	IN ('FPV','FPVC')
and tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
AND tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		IN ('FPV','FPVC')
and tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		IN ('FPV','FPVC')
and tb11.periodo_anno = annoCapImp	AND	tb11.tipo_imp =	TipoImpRes			and	tb11.tipo_capitolo 		IN ('FPV','FPVC')
and tb12.periodo_anno = annoCapImp	AND	tb12.tipo_imp =	TipoImpCassa		and	tb12.tipo_capitolo 		IN ('FPV','FPVC')
and tb7.utente 	= 	tb8.utente	
and	tb8.utente	=	tb9.utente
and	tb9.utente	=	tb10.utente	
and	tb10.utente	=	tb11.utente	
and	tb11.utente	=	tb12.utente	
and	tb12.utente	=	user_table;              

     RTN_MESSAGGIO:='insert tabella siac_rep_mptm_up_cap_importi''.';  

-----------------------------------------------------------------------------------
raise notice '7: %', clock_timestamp()::varchar; 
insert into siac_rep_mptm_up_cap_importi
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno,
        v1.ente_proprietario_id,
        user_table utente,
        tbprec.elem_id_old,
        '',
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			FULL  join siac_rep_cap_up tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND v1.utente=user_table
                    and	TB.utente=V1.utente)
            left	join    siac_rep_cap_up_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
            left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id and tbprec.data_cancellazione is null
    where v1.utente = user_table
    		------and TB.utente=V1.utente
            ------and	tb1.utente	=	tb.utente
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;

raise notice '7.1: %', clock_timestamp()::varchar; 
/*
 if classifBilRec.fase_bilancio = 'P'  then
 	tipo_capitolo:=elemTipoCode_UG;
 else
 	tipo_capitolo:=elemTipoCode;
 end if;
 */
 
 tipo_capitolo:=elemTipoCode_UG;
 
 
 -------------------------------------
--25/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
/*25/09/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro e' stato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
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
            siac_t_bil                  bilancio  ';
           
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;          
       
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
    
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
  
    sql_query=sql_query || ' and testata_variazione.ente_proprietario_id	=  ' || p_ente_prop_id ||'     
    and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
   
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query|| ' AND stato_atto.attoamm_stato_code <> ''ANNULLATO''  
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
   
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;

    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
       
    sql_query=sql_query||'
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
raise notice '7.2: %', clock_timestamp()::varchar; 
   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp2
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table    ; 
end if;

-------------------------------------
 

       
-- PRIMA VERSIONE INIZIO      
----------------------------------------------------------------------------------------------------
--------  TABELLA TEMPORANEA PER ACQUISIRE L'IMPORTO DEL CUI GIA' IMPEGNATO 
--------  sostituisce momentaneamente le due query successive.
/*raise notice '9: %', clock_timestamp()::varchar;      
      RTN_MESSAGGIO:='insert tabella siac_rep_impegni_riga''.'; 
insert into  siac_rep_impegni_riga
select 	tb2.elem_id,
		tb2.dicuiimpegnato_anno1,
        tb2.dicuiimpegnato_anno2,
        tb2.dicuiimpegnato_anno3,
        p_ente_prop_id,
        user_table utente
from 	siac_t_dicuiimpegnato_bilprev 	tb2,
		siac_t_periodo 					anno_eserc,
    	siac_t_bil 						bilancio
where 	tb2.ente_proprietario_id = p_ente_prop_id				AND
		anno_eserc.anno= p_anno									and
        bilancio.periodo_id=anno_eserc.periodo_id				and
		tb2.bil_id = bilancio.bil_id;*/	
-- PRIMA VERSIONE FINE   
raise notice '8: %', clock_timestamp()::varchar; 

/* 13/05/2016: tolto il controllo sulla fase di bilancio 
select case when count(*) is null then 0 else 1 end into esiste_siac_t_dicuiimpegnato_bilprev 
from siac_t_dicuiimpegnato_bilprev where ente_proprietario_id=p_ente_prop_id limit 1;

if classifBilRec.fase_bilancio = 'P' and esiste_siac_t_dicuiimpegnato_bilprev<>1  then
  	for classifBilRec in */

-- NUOVA VERSIONE INIZIO
for ImpegniRec in
  select tb2.elem_id,
  tb.movgest_anno,
  p_ente_prop_id,
  user_table utente,
  tb.importo
  from (select    
  m.movgest_anno::VARCHAR, 
  e.elem_id,
  sum (tsd.movgest_ts_det_importo) importo
      from 
          siac_t_bil b, 
          siac_t_periodo p, 
          siac_t_bil_elem e,
          siac_d_bil_elem_tipo et,
          siac_r_movgest_bil_elem rm, 
          siac_t_movgest m,
          siac_d_movgest_tipo mt,
          siac_t_movgest_ts ts  ,
          siac_d_movgest_ts_tipo   tsti, 
          siac_r_movgest_ts_stato tsrs,
          siac_d_movgest_stato mst, 
          siac_t_movgest_ts_det   tsd ,
          siac_d_movgest_ts_det_tipo  tsdt
        where 
        b.periodo_id					=	p.periodo_id 
        and p.ente_proprietario_id   	= 	p_ente_prop_id
        and p.anno          			=   p_anno 
        and b.bil_id 					= 	e.bil_id
        and e.elem_tipo_id			=	et.elem_tipo_id
        and et.elem_tipo_code      	=  	elemTipoCode
        -------and et.elem_tipo_code      =  'CAP-UG'
        ----------and m.movgest_anno    <= annoCapImp_int
        and rm.elem_id      			= 	e.elem_id
        and rm.movgest_id      		=  	m.movgest_id 
        and now() between rm.validita_inizio and coalesce (rm.validita_fine, now())
        and m.movgest_anno::VARCHAR   			 in (annoCapImp, annoCapImp1, annoCapImp2)
        --and m.movgest_anno >= annobilint
        --------and m.bil_id     = b.bil_id --non serve
        and m.movgest_tipo_id			= 	mt.movgest_tipo_id 
        and mt.movgest_tipo_code		='I' 
        and m.movgest_id				=	ts.movgest_id
        and ts.movgest_ts_id			=	tsrs.movgest_ts_id 
        and tsrs.movgest_stato_id  	= 	mst.movgest_stato_id 
        and tsti.movgest_ts_tipo_code  = 'T' 
        and mst.movgest_stato_code   in ('D','N') ------ P,A,N 
        and now() between tsrs.validita_inizio and coalesce (tsrs.validita_fine, now())
        and ts.movgest_ts_tipo_id  	= 	tsti.movgest_ts_tipo_id 
        and ts.movgest_ts_id     		= 	tsd.movgest_ts_id 
        and tsd.movgest_ts_det_tipo_id  = tsdt.movgest_ts_det_tipo_id 
        and tsdt.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
        and now() between b.validita_inizio and coalesce (b.validita_fine, now())
        and now() between p.validita_inizio and coalesce (p.validita_fine, now())
        and now() between e.validita_inizio and coalesce (e.validita_fine, now())
        and now() between et.validita_inizio and coalesce (et.validita_fine, now())
        and now() between m.validita_inizio and coalesce (m.validita_fine, now())
        and now() between ts.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between mt.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between tsti.validita_inizio and coalesce (tsti.validita_fine, now())
        and now() between mst.validita_inizio and coalesce (mst.validita_fine, now())
        and now() between tsd.validita_inizio and coalesce (tsd.validita_fine, now())
        and now() between tsdt.validita_inizio and coalesce (tsdt.validita_fine, now())
        and p.data_cancellazione     	is null 
        and b.data_cancellazione      is null 
        and e.data_cancellazione      is null     
        and et.data_cancellazione     is null 
        and rm.data_cancellazione 	is null 
        and m.data_cancellazione      is null 
        and mt.data_cancellazione     is null 
        and ts.data_cancellazione   	is null 
        and tsti.data_cancellazione   is null 
        and tsrs.data_cancellazione   is null 
        and mst.data_cancellazione    is null 
        and tsd.data_cancellazione   	is null 
        and tsdt.data_cancellazione   is null      
  group by m.movgest_anno, e.elem_id )
  tb 
  ,
  (select * from  siac_t_bil_elem    			capitolo_ug,
                  siac_d_bil_elem_tipo    	t_capitolo_ug
        where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
        and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
  where
   tb2.elem_id	=	tb.elem_id
   
  LOOP
    
    v_importo_imp  :=0;
    v_importo_imp1 :=0;
    v_importo_imp2 :=0;
    
    IF ImpegniRec.movgest_anno = annoCapImp THEN
       v_importo_imp := ImpegniRec.importo;
    ELSIF ImpegniRec.movgest_anno = annoCapImp1 THEN
       v_importo_imp1 := ImpegniRec.importo;
    ELSIF ImpegniRec.movgest_anno = annoCapImp2 THEN  
       v_importo_imp2 := ImpegniRec.importo;
    END IF; 
        
    v_conta_rec := 0;
    SELECT count(elem_id)
    INTO   v_conta_rec
    FROM   SIAC_REP_IMPEGNI_RIGA
    WHERE  ente_proprietario = p_ente_prop_id
    AND    utente = ImpegniRec.utente
    AND    elem_id = ImpegniRec.elem_id;
    
    IF  v_conta_rec = 0 THEN
       
      INSERT INTO SIAC_REP_IMPEGNI_RIGA
          (elem_id,
           impegnato_anno,
           impegnato_anno1,
           impegnato_anno2,
           ente_proprietario,
           utente)
      VALUES
          (ImpegniRec.elem_id,
           v_importo_imp,
           v_importo_imp1,
           v_importo_imp2,
           p_ente_prop_id,
           ImpegniRec.utente
          );   
    ELSE
        IF ImpegniRec.movgest_anno = annoCapImp THEN
           UPDATE SIAC_REP_IMPEGNI_RIGA
           SET impegnato_anno = v_importo_imp
           WHERE  elem_id = ImpegniRec.elem_id
           AND    ente_proprietario = p_ente_prop_id
           AND    utente = ImpegniRec.utente;
        ELSIF  ImpegniRec.movgest_anno = annoCapImp1 THEN  
           UPDATE SIAC_REP_IMPEGNI_RIGA
           SET impegnato_anno1 = v_importo_imp1
           WHERE  elem_id = ImpegniRec.elem_id
           AND    ente_proprietario = p_ente_prop_id
           AND    utente = ImpegniRec.utente; 
        ELSIF ImpegniRec.movgest_anno = annoCapImp2 THEN                   
           UPDATE SIAC_REP_IMPEGNI_RIGA
           SET impegnato_anno2 = v_importo_imp2
           WHERE  elem_id = ImpegniRec.elem_id
           AND    ente_proprietario = p_ente_prop_id
           AND    utente = ImpegniRec.utente;   
        END IF;             
    END IF;
        
  END LOOP; 
   
-- NUOVA VERSIONE FINE  

 RTN_MESSAGGIO:='preparazione file output''.'; 
 
 for classifBilRec in
	select 	t1.missione_tipo_desc	missione_tipo_desc,
            t1.missione_code		missione_code,
            t1.missione_desc		missione_desc,
            t1.programma_tipo_desc	programma_tipo_desc,
            t1.programma_code		programma_code,
            t1.programma_desc		programma_desc,
            t1.titusc_tipo_desc		titusc_tipo_desc,
            t1.titusc_code			titusc_code,
            t1.titusc_desc			titusc_desc,
            t1.macroag_tipo_desc	macroag_tipo_desc,
            t1.macroag_code			macroag_code,
            t1.macroag_desc			macroag_desc,
            t1.bil_anno   			BIL_ANNO,
            t1.elem_code     		BIL_ELE_CODE,
            t1.elem_code2     		BIL_ELE_CODE2,
            t1.elem_code3			BIL_ELE_CODE3,
            t1.elem_desc     		BIL_ELE_DESC,
            t1.elem_desc2     		BIL_ELE_DESC2,
            t1.elem_id      		BIL_ELE_ID,
            t1.elem_id_padre    	BIL_ELE_ID_PADRE,
            COALESCE(t1.stanziamento_prev_anno,0)	stanziamento_prev_anno,
            COALESCE(t1.stanziamento_prev_anno1,0)	stanziamento_prev_anno1,
            COALESCE(t1.stanziamento_prev_anno2,0)	stanziamento_prev_anno2,
            COALESCE(t1.stanziamento_prev_res_anno,0)	stanziamento_prev_res_anno,
            COALESCE(t1.stanziamento_anno_prec,0)	stanziamento_anno_prec,
            COALESCE(t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
            COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        	COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        	COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        	COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2,  
            --------t1.elem_id_old		elem_id_old,
            COALESCE(t2.impegnato_anno,0) impegnato_anno,
            COALESCE(t2.impegnato_anno1,0) impegnato_anno1,
            COALESCE(t2.impegnato_anno2,0) impegnato_anno2,
            COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
            COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
            COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
            COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
            COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
            COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
            COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
            COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
            COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
            COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
            COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
            COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
            COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
            COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
            COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
            COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
            COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
            COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2
                      
    from siac_rep_mptm_up_cap_importi t1
            ----full join siac_rep_impegni_riga  t2
            left join siac_rep_impegni_riga  t2
            on (t1.elem_id	=	t2.elem_id)  ---------da sostituire con   --------t1.elem_id_old	=	t2.elem_id
                --and	t1.ente_proprietario_id	=	t2.ente_proprietario
                ----and	t1.utente	=	t2.utente
                ----and	t1.utente	=	user_table)
		left	join  siac_rep_var_spese_riga var_anno 
           			on (var_anno.elem_id	=	t1.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	t1.utente=user_table
                        and var_anno.utente	=	t1.utente)         
			left	join  siac_rep_var_spese_riga var_anno1
           			on (var_anno1.elem_id	=	t1.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	t1.utente=user_table
                        and var_anno1.utente	=	t1.utente)  
			left	join  siac_rep_var_spese_riga var_anno2
           			on (var_anno2.elem_id	=	t1.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	t1.utente=user_table
                        and var_anno2.utente	=	t1.utente)                    
            where t1.utente = user_table
         /*  06/09/2016: eliminate queste condizioni perche' il filtro
         		e' nella query di caricamento struttura
         	 and	(
        		(t1.missione_code < '20' and t1.titusc_code in ('1','2','3'))
        		or (t1.missione_code = '20' and t1.programma_code='2001' and t1.titusc_code = '1')
                or (t1.missione_code = '20' and t1.programma_code in ('2002','2003') and t1.titusc_code in ('1','2'))
                or (t1.missione_code = '50' and t1.programma_code='5001' and t1.titusc_code = '1')
                or (t1.missione_code = '50' and t1.programma_code='5002' and t1.titusc_code = '4')
                or (t1.missione_code = '60' and t1.programma_code = '6001' and t1.titusc_code in ('1','5'))
                or (t1.missione_code = '99' and t1.programma_code in ('9901','9902') and t1.titusc_code = '7')
                )*/
            order by missione_code,programma_code,titusc_code,macroag_code   	
loop
      missione_tipo_desc:= classifBilRec.missione_tipo_desc;
      missione_code:= classifBilRec.missione_code;
      missione_desc:= classifBilRec.missione_desc;
      programma_tipo_desc:= classifBilRec.programma_tipo_desc;
      programma_code:= classifBilRec.programma_code;
      programma_desc:= classifBilRec.programma_desc;
      titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
      titusc_code:= classifBilRec.titusc_code;
      titusc_desc:= classifBilRec.titusc_desc;
      macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
      macroag_code:= classifBilRec.macroag_code;
      macroag_desc:= classifBilRec.macroag_desc;
      bil_anno:=classifBilRec.bil_anno;
      bil_ele_code:=classifBilRec.bil_ele_code;
      bil_ele_desc:=classifBilRec.bil_ele_desc;
      bil_ele_code2:=classifBilRec.bil_ele_code2;
      bil_ele_desc2:=classifBilRec.bil_ele_desc2;
      bil_ele_id:=classifBilRec.bil_ele_id;
      bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
      bil_anno:=p_anno;
      stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
      stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
      stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
      stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
      stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
      stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
      --stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
      stanziamento_fpv_anno_prec_app:=classifBilRec.stanziamento_fpv_anno_prec;
      stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
      stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
      stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
      impegnato_anno:=classifBilRec.impegnato_anno;
      impegnato_anno1:=classifBilRec.impegnato_anno1;
      impegnato_anno2=classifBilRec.impegnato_anno2;
      
      --stanziamento_fpv_anno_prec

--25/07/2016: sommo gli eventuali valori delle variazioni

--stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
--            					    classifBilRec.variazione_diminuzione_stanziato;
                                    
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
--stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
--            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
--stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
--            					    classifBilRec.variazione_diminuzione_stanziato2;

stanziamento_prev_res_anno=stanziamento_prev_res_anno+classifBilRec.variazione_aumento_residuo+
            					    classifBilRec.variazione_diminuzione_residuo;

select b.elem_cat_code into cat_capitolo from siac_r_bil_elem_categoria a, siac_d_bil_elem_categoria b
where a.elem_id=classifBilRec.bil_ele_id 
and a.data_cancellazione is null
and a.validita_fine is null
and a.elem_cat_id=b.elem_cat_id;

--raise notice 'XXXX tipo_categ_capitolo = %', cat_capitolo;
--raise notice 'XXXX elem id = %', classifBilRec.bil_ele_id ;


if cat_capitolo = 'FPV' or cat_capitolo = 'FPVC' then 
stanziamento_fpv_anno=stanziamento_fpv_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;

stanziamento_fpv_anno1=stanziamento_fpv_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_fpv_anno2=stanziamento_fpv_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;
else

stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
	
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;

end if;

/* if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Missione = %, Programma = %, Titolo %', bil_ele_code, bil_ele_id, missione_code, programma_code, titusc_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;  */

--06/05/2016: cerco i dati relativi alle previsioni anno precedente.
IF bil_ele_code IS NOT NULL THEN
--raise notice 'Cerco: missione_code=%, programma_code=%, titolo_code=%, macroagg_code=%,  bil_ele_code=%, bil_ele_code2=%, bil_ele_code3= %, anno=%', missione_code, classifBilRec.programma_code, classifBilRec.titusc_code,classifBilRec.macroag_code,bil_ele_code,bil_ele_code2, classifBilRec.BIL_ELE_CODE3, annoPrec;

  SELECT COALESCE(imp_prev_anno_prec.importo_cassa,0) importo_cassa,
          COALESCE(imp_prev_anno_prec.importo_competenza, 0) importo_competenza,
          elem_cat_code
  INTO previsioni_anno_prec_cassa_app, previsioni_anno_prec_comp_app, tipo_categ_capitolo
  FROM siac_t_cap_u_importi_anno_prec  imp_prev_anno_prec 
  WHERE  --imp_prev_anno_prec.missione_code= classifBilRec.missione_code
       imp_prev_anno_prec.programma_code=classifBilRec.programma_code
      --AND imp_prev_anno_prec.titolo_code=classifBilRec.titusc_code      
      AND imp_prev_anno_prec.macroagg_code=classifBilRec.macroag_code
      AND imp_prev_anno_prec.elem_code=bil_ele_code
      AND imp_prev_anno_prec.elem_code2=bil_ele_code2
      AND imp_prev_anno_prec.elem_code3=classifBilRec.BIL_ELE_CODE3
      AND imp_prev_anno_prec.anno= annoPrec
      AND imp_prev_anno_prec.ente_proprietario_id=p_ente_prop_id
      AND imp_prev_anno_prec.data_cancellazione IS NULL;
  IF NOT FOUND THEN 
      previsioni_anno_prec_comp=0;
      previsioni_anno_prec_cassa=0;
      stanziamento_fpv_anno_prec=0;
  ELSE
 -- raise notice 'XXXX tipo_categ_capitolo = %', tipo_categ_capitolo;
      previsioni_anno_prec_comp=previsioni_anno_prec_comp_app;
      previsioni_anno_prec_cassa=previsioni_anno_prec_cassa_app;
      	-- se il capitolo e' di tipo FPV carico anche il campo stanziamento_fpv_anno_prec
     -- 06/09/2016: aggiunto FPVC
 	 IF tipo_categ_capitolo = 'FPV' OR tipo_categ_capitolo = 'FPVC' THEN
      	previsioni_anno_prec_comp=0;
      	stanziamento_fpv_anno_prec=previsioni_anno_prec_comp_app;  
      END IF;
  END IF;
ELSE
      previsioni_anno_prec_comp=0;
      previsioni_anno_prec_cassa=0;
      stanziamento_fpv_anno_prec=0;
END IF;
--06/05/2016: in prima battuta la tabella siac_t_cap_e_importi_anno_prec NON
-- conterra' i dati della competenza ma solo quelli della cassa, pertanto
-- il dato della competenza letto dalla tabella e' sostituito da quello che
-- era contenuto nel campo previsioni_anno_prec.
-- Quando sara' valorizzato le seguenti righe dovranno ESSERE ELIMINATE!!!
--previsioni_anno_prec_comp=stanziamento_anno_prec;
--stanziamento_fpv_anno_prec=stanziamento_fpv_anno_prec_app;

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
    previsioni_anno_prec_comp=0;
	previsioni_anno_prec_cassa=0;
	stanziamento_fpv_anno_prec=0;

end loop;


delete from siac_rep_mis_pro_tit_mac_riga_anni 		where utente=user_table;
delete from siac_rep_cap_up 						where utente=user_table;
delete from siac_rep_cap_up_imp 					where utente=user_table;
delete from siac_rep_cap_up_imp_riga				where utente=user_table;
delete from siac_rep_mptm_up_cap_importi 			where utente=user_table;
delete from siac_rep_impegni 						where utente=user_table;
delete from siac_rep_impegni_riga  					where utente=user_table;
delete from siac_rep_var_spese  					where utente=user_table;
delete from siac_rep_var_spese_riga  				where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'nessun dato trovato per struttura bilancio';
      return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
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

ALTER FUNCTION siac."BILR111_Allegato_9_bil_gest_spesa_mpt" (p_ente_prop_id integer, p_anno varchar, p_disavanzo boolean, p_ele_variazioni varchar, p_num_provv_var_peg integer, p_anno_provv_var_peg varchar, p_tipo_provv_var_peg varchar, p_num_provv_var_bil integer, p_anno_provv_var_bil varchar, p_tipo_provv_var_bil varchar, p_code_sac_direz_peg varchar, p_code_sac_sett_peg varchar, p_code_sac_direz_bil varchar, p_code_sac_sett_bil varchar)
  OWNER TO siac;
  
CREATE OR REPLACE FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_disavanzo boolean,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
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
  display_error varchar
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
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
BIL_ELE_CODE3	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
-- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- DAVIDE - SIAC-5202 - FINE
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

contaParVarPeg integer;
contaParVarBil integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP_UG';	--- Capitolo gestione

anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;
contaParVarPeg:=0;
contaParVarBil:=0;

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
display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- DAVIDE - SIAC-5202 - FINE

END IF;

--INC000004803136 10/03/2021.
--Controllo aggiunto per ovviare ad un errato passaggio di parametri dal report.
--Dovra' essere tolto quando il report sara' corretto.
if p_code_sac_direz_peg = '99' then
	p_code_sac_direz_peg:='999';
end if;
if p_code_sac_direz_bil = '99' then
	p_code_sac_direz_bil:='999';
end if;


/* 26/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;

select fnc_siac_random_user()
into	user_table;

/*
insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
-------siac_v_mis_pro_tit_macr_anni v 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;
*/


-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 06/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 
insert into siac_rep_cap_up
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
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
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
    anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	-----cat_del_capitolo.elem_cat_code	=	'STD'
    -- 06/09/2016: aggiunto FPVC
    cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')														
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
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
    and	r_cat_capitolo.data_cancellazione 			is null;	
   


insert into siac_rep_cap_up_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo           
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
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id	=capitolo_imp_tipo.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id	=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno							= p_anno 													
    	and	bilancio.periodo_id						=anno_eserc.periodo_id 								
        and	capitolo.bil_id							=bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 			= elemTipoCode
        and	capitolo_importi.elem_det_tipo_id		=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPV (che era in query successiva che 
        -- e' stata tolta) e FPVC        		
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')								
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
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
	siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	and	tb1.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	and	tb2.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	and	tb3.tipo_capitolo 	in ('STD','FSC')
                    AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpRes	and	tb4.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa and	tb6.tipo_capitolo 		in ('STD','FSC')
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
                
/* SIAC-8785 03/08/2022.
   Per gli importi dei capitoli FPV occorre inserire anche la cassa e
   i residui per prevenire eventuali errori di importi inseriti come FPV che poi
   eventualmente potrebbero essere tolti tramite variazione */                    
/*
  insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where		
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND  -- 06/09/2016: aggiunto FPVC
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	IN ('FPV','FPVC')
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		IN ('FPV','FPVC')
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		IN ('FPV','FPVC')
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;

*/
-- insert modificata per SIAC-8785: inseriti anche cassa e residui per PFV.
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	tb11.importo	as		stanziamento_prev_res_anno,
    	0,
    	tb12.importo 	as 		stanziamento_prev_cassa_anno,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente 
from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10, siac_rep_cap_up_imp tb11, siac_rep_cap_up_imp tb12
where tb7.elem_id	=	tb8.elem_id 
and tb8.elem_id	=	tb9.elem_id
and  tb9.elem_id	=	tb10.elem_id 
and  tb10.elem_id	=	tb11.elem_id 
and  tb11.elem_id	=	tb12.elem_id 
AND  -- 06/09/2016: aggiunto FPVC
	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	IN ('FPV','FPVC')
and tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
AND tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		IN ('FPV','FPVC')
and tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		IN ('FPV','FPVC')
and tb11.periodo_anno = annoCapImp	AND	tb11.tipo_imp =	TipoImpRes			and	tb11.tipo_capitolo 		IN ('FPV','FPVC')
and tb12.periodo_anno = annoCapImp	AND	tb12.tipo_imp =	TipoImpCassa		and	tb12.tipo_capitolo 		IN ('FPV','FPVC')
and tb7.utente 	= 	tb8.utente	
and	tb8.utente	=	tb9.utente
and	tb9.utente	=	tb10.utente	
and	tb10.utente	=	tb11.utente	
and	tb11.utente	=	tb12.utente	
and	tb12.utente	=	user_table;                 
                                       
                   


/*
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb6,siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where	
        tb6.elem_id	=	tb7.elem_id
        and 	
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND
        tb6.periodo_anno = annoCapImp	AND	tb6.tipo_imp = 	TipoImpCassa and	tb6.tipo_capitolo 		= 'FPV'
        AND
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	= 'FPV'
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		= 'FPV'
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		= 'FPV'
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		= 'FPV'
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;
        
*/

insert into siac_rep_mptm_up_cap_importi
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno, 
        v1.ente_proprietario_id,
        user_table utente,
        0,
        '',
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2 
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			FULL  join siac_rep_cap_up tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_up_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente) 	
            -----------left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id
    where v1.utente = user_table      
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;           

 -------------------------------------
--26/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
/*25/09/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro e' stato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
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
            siac_t_bil                  bilancio ';
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;                      
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id|| '
    and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
	IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query|| ' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
   
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;

    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;        

EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp2
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table    ; 
end if;

-------------------------------------

 	for classifBilRec in
select 	t1.missione_tipo_desc	missione_tipo_desc,
		t1.missione_code		missione_code,
		t1.missione_desc		missione_desc,
		t1.programma_tipo_desc	programma_tipo_desc,
		t1.programma_code		programma_code,
		t1.programma_desc		programma_desc,
		t1.titusc_tipo_desc		titusc_tipo_desc,
		t1.titusc_code			titusc_code,
		t1.titusc_desc			titusc_desc,
		t1.macroag_tipo_desc	macroag_tipo_desc,
		t1.macroag_code			macroag_code,
		t1.macroag_desc			macroag_desc,
    	t1.bil_anno   			BIL_ANNO,
        t1.elem_code     		BIL_ELE_CODE,
        t1.elem_code2     		BIL_ELE_CODE2,
        t1.elem_code3			BIL_ELE_CODE3,
		t1.elem_desc     		BIL_ELE_DESC,
        t1.elem_desc2     		BIL_ELE_DESC2,
        t1.elem_id      		BIL_ELE_ID,
       	t1.elem_id_padre    	BIL_ELE_ID_PADRE,
    	COALESCE (t1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
    	COALESCE (t1.stanziamento_prev_anno1,0)			stanziamento_prev_anno1,
    	COALESCE (t1.stanziamento_prev_anno2,0)			stanziamento_prev_anno2,
   	 	COALESCE (t1.stanziamento_prev_res_anno,0)		stanziamento_prev_res_anno,
    	COALESCE (t1.stanziamento_anno_prec,0)			stanziamento_anno_prec,
    	COALESCE (t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2 ,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2                    
from siac_rep_mptm_up_cap_importi t1
		left	join  siac_rep_var_spese_riga var_anno 
           			on (var_anno.elem_id	=	t1.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	t1.utente=user_table
                        and var_anno.utente	=	t1.utente)         
			left	join  siac_rep_var_spese_riga var_anno1
           			on (var_anno1.elem_id	=	t1.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	t1.utente=user_table
                        and var_anno1.utente	=	t1.utente)  
			left	join  siac_rep_var_spese_riga var_anno2
           			on (var_anno2.elem_id	=	t1.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	t1.utente=user_table
                        and var_anno2.utente	=	t1.utente)   
        order by missione_code,programma_code,titusc_code,macroag_code
          loop
          missione_tipo_desc:= classifBilRec.missione_tipo_desc;
          missione_code:= classifBilRec.missione_code;
          missione_desc:= classifBilRec.missione_desc;
          programma_tipo_desc:= classifBilRec.programma_tipo_desc;
          programma_code:= classifBilRec.programma_code;
          programma_desc:= classifBilRec.programma_desc;
          titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
          titusc_code:= classifBilRec.titusc_code;
          titusc_desc:= classifBilRec.titusc_desc;
          macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
          macroag_code:= classifBilRec.macroag_code;
          macroag_desc:= classifBilRec.macroag_desc;
          bil_anno:=classifBilRec.bil_anno;
          bil_ele_code:=classifBilRec.bil_ele_code;
          bil_ele_desc:=classifBilRec.bil_ele_desc;
          bil_ele_code2:=classifBilRec.bil_ele_code2;
          bil_ele_desc2:=classifBilRec.bil_ele_desc2;
          bil_ele_id:=classifBilRec.bil_ele_id;
          bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
          bil_anno:=p_anno;
          stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
          stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
          stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
          stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
          stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
          stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
          stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
          stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
          stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
          stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
          impegnato_anno:=0;
          impegnato_anno1:=0;
          impegnato_anno2=0;

--25/07/2016: sommo gli eventuali valori delle variazioni
--stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
---            					    classifBilRec.variazione_diminuzione_stanziato;
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
--stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
--            					    classifBilRec.variazione_diminuzione_stanziato1;
--stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
--            					    classifBilRec.variazione_diminuzione_stanziato2;
stanziamento_prev_res_anno=stanziamento_prev_res_anno+classifBilRec.variazione_aumento_residuo+
            					    classifBilRec.variazione_diminuzione_residuo;


select b.elem_cat_code into cat_capitolo from siac_r_bil_elem_categoria a, siac_d_bil_elem_categoria b
where a.elem_id=classifBilRec.bil_ele_id 
and a.data_cancellazione is null
and a.validita_fine is null
and a.elem_cat_id=b.elem_cat_id;

--raise notice 'XXXX tipo_categ_capitolo = %', cat_capitolo;
--raise notice 'XXXX elem id = %', classifBilRec.bil_ele_id ;


if cat_capitolo = 'FPV' or cat_capitolo = 'FPVC' then 
stanziamento_fpv_anno=stanziamento_fpv_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;

stanziamento_fpv_anno1=stanziamento_fpv_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_fpv_anno2=stanziamento_fpv_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;
else

stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
	
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;

end if;


/*          
if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Missione = %, Programma = %, Titolo %', bil_ele_code, bil_ele_id, missione_code, programma_code, titusc_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;            */

-- restituisco il record complessivo
/*raise notice 'record %', classifBilRec.bil_ele_id;
 h_count:=h_count+1;
 raise notice 'n. record %', h_count;*/
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

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_up where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;
delete from siac_rep_var_spese  					where utente=user_table;
delete from siac_rep_var_spese_riga  				where utente=user_table;


raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'nessun dato trovato per struttura bilancio';
      return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
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

ALTER FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_spese" (p_ente_prop_id integer, p_anno varchar, p_disavanzo boolean, p_ele_variazioni varchar, p_num_provv_var_peg integer, p_anno_provv_var_peg varchar, p_tipo_provv_var_peg varchar, p_num_provv_var_bil integer, p_anno_provv_var_bil varchar, p_tipo_provv_var_bil varchar, p_code_sac_direz_peg varchar, p_code_sac_sett_peg varchar, p_code_sac_direz_bil varchar, p_code_sac_sett_bil varchar)
  OWNER TO siac;  

--SIAC-8785 - Maurizio - FINE


--INC000006308065 - Maurizio - INIZIO 

CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_sposta_capitolo_su_accertamento (
  annobilancio integer,
  pdcfinv_accertamento boolean,
  pdcfin varchar,
  enteproprietarioid integer,
  loginoperazione varchar,
  genaggiorna boolean,
  genaccertamento boolean,
  gendocumento boolean,
  genordinativo boolean,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE




strMessaggio         VARCHAR(1500):='';
strMessaggioFinale   VARCHAR(1500):='';


BEGIN

 strMessaggioFinale:='Sposta capitolo su accertamento.';
 codiceRisultato:=0;

 -- spostamento capitolo su accertamento
 strMessaggio:='collegamento tra capitolo e accertamento : annullamento precedente relazione.';
 raise notice 'strMessaggio=%',strMessaggio;

 update siac_r_movgest_bil_elem rmov
 set    data_cancellazione=clock_timestamp(),
        validita_fine=clock_timestamp(),
        login_operazione=rmov.login_operazione||'-'||loginOperazione
 from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_d_movgest_tipo tipo , siac_t_movgest mov
 where  tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.movgest_tipo_code='A'
 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
 and    anno.bil_id=mov.bil_id
 and    anno.anno_bilancio=annoBilancio
 and    bko.ente_proprietario_id=anno.ente_proprietario_id
 and    bko.anno_bilancio=anno.anno_bilancio
 and    bko.anno_accertamento_da=mov.movgest_anno::integer
 and    bko.numero_accertamento_da=mov.movgest_numero::integer
 and    rmov.movgest_id=mov.movgest_id
 and    rmov.data_cancellazione is null
 and    rmov.validita_fine is null;

 strMessaggio:='collegamento tra capitolo e accertamento : inserimento nuova  relazione.';
 raise notice 'strMessaggio=%',strMessaggio;
 insert into siac_r_movgest_bil_elem
 (
 	elem_id,
    movgest_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
 )
 with
 accertamento as
 (
 select distinct mov.movgest_id,
                 tipo.ente_proprietario_id,
                 bko.numero_capitolo_a,
                 bko.numero_articolo_a
 from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_d_movgest_tipo tipo, siac_t_movgest mov
 where  tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.movgest_tipo_code='A'
 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
 and    anno.bil_id=mov.bil_id
 and    anno.anno_bilancio=annoBilancio
 and    bko.ente_proprietario_id=anno.ente_proprietario_id
 and    bko.anno_bilancio=anno.anno_bilancio
 and    bko.anno_accertamento_da=mov.movgest_anno::integer
 and    bko.numero_accertamento_da=mov.movgest_numero::integer
 ) ,
 capitolo as
 (
  select e.elem_id, e.elem_code::integer,e.elem_code2::integer
  from siac_d_bil_elem_tipo tipoe, siac_t_bil_elem e, siac_v_bko_anno_bilancio anno
  where tipoe.ente_proprietario_id=enteProprietarioId
  and   tipoe.elem_tipo_code='CAP-EG'
  and   e.elem_tipo_id=tipoe.elem_tipo_id
  and   anno.bil_id=e.bil_id
  and   anno.anno_bilancio=annoBilancio
 )
 select capitolo.elem_id,
        accertamento.movgest_id,
        now(),
        loginOperazione,
        accertamento.ente_proprietario_id
 from  accertamento, capitolo
 where capitolo.elem_code=accertamento.numero_capitolo_a
 --INC000006308065: errata controllo sull'articolo del capitolo.
--and       capitolo.elem_code=accertamento.numero_articolo_a;
and    capitolo.elem_code2=accertamento.numero_articolo_a;

 -- spostamento classificatori su accertamento
 strMessaggio:='collegamento tra classificatori e accertamento : annullamento precedente relazione.';
 raise notice 'strMessaggio=%',strMessaggio;
 update siac_r_movgest_class rc
 set    data_cancellazione=now(),
        validita_fine=now(),
        login_operazione=rc.login_operazione||'-'||loginOperazione
 from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_d_movgest_tipo tipo, siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
        siac_t_class c, siac_d_class_tipo tipoc
 where  tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.movgest_tipo_code='A'
 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
 and    anno.bil_id=mov.bil_id
 and    anno.anno_bilancio=annoBilancio
 and    bko.ente_proprietario_id=anno.ente_proprietario_id
 and    bko.anno_bilancio=anno.anno_bilancio
 and    bko.anno_accertamento_da=mov.movgest_anno::integer
 and    bko.numero_accertamento_da=mov.movgest_numero::integer
 and    ts.movgest_id=mov.movgest_id
 and    tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
 and    (case when tipots.movgest_ts_tipo_code='T' then bko.numero_subaccertamento_da=0
              else bko.numero_subaccertamento_da=ts.movgest_ts_code::integer
         end)
 and    rc.movgest_ts_id=ts.movgest_ts_id
 and    c.classif_id=rc.classif_id
 and    tipoc.classif_tipo_id=c.classif_tipo_id
 and    tipoc.classif_tipo_code in
 (
 'PDC_V',
 'PERIMETRO_SANITARIO_ENTRATA',
 'RICORRENTE_ENTRATA',
 'TRANSAZIONE_UE_ENTRATA'
 )
 and    rc.data_cancellazione is null
 and    rc.validita_fine is null;

 strMessaggio:='collegamento tra classificatori e accertamento : inserimento nuove relazioni.';
 raise notice 'strMessaggio=%',strMessaggio;
 insert into siac_r_movgest_class
 (
 	movgest_ts_id,
    classif_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
 )
 select distinct
        ts.movgest_ts_id,
        c.classif_id,
        now(),
        loginOperazione,
        tipo.ente_proprietario_id
 from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_d_movgest_tipo tipo, siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
        siac_r_movgest_bil_elem rmov,siac_r_bil_elem_class rc,
        siac_t_class c, siac_d_class_tipo tipoc
 where  tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.movgest_tipo_code='A'
 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
 and    anno.bil_id=mov.bil_id
 and    anno.anno_bilancio=annoBilancio
 and    bko.ente_proprietario_id=anno.ente_proprietario_id
 and    bko.anno_bilancio=anno.anno_bilancio
 and    bko.anno_accertamento_da=mov.movgest_anno::integer
 and    bko.numero_accertamento_da=mov.movgest_numero::integer
 and    ts.movgest_id=mov.movgest_id
 and    tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
 and    (case when tipots.movgest_ts_tipo_code='T' then bko.numero_subaccertamento_da=0
              else bko.numero_subaccertamento_da=ts.movgest_ts_code::integer
         end)
 and    rmov.movgest_id=mov.movgest_id
 and    rc.elem_id=rmov.elem_id
 and    c.classif_id=rc.classif_id
 and    tipoc.classif_tipo_id=c.classif_tipo_id
 and    tipoc.classif_tipo_code in
 (
 'PDC_V',
 'PERIMETRO_SANITARIO_ENTRATA',
 'RICORRENTE_ENTRATA',
 'TRANSAZIONE_UE_ENTRATA'
 )
 and rmov.data_cancellazione is null
 and rmov.validita_fine is null
 and rc.data_cancellazione is null
 and rc.validita_fine is null;

 if pdcfinv_accertamento = true then 
    strMessaggio:='collegamento tra classificatori e accertamento PDC_FIN_V : inserimento nuove relazioni.';
    raise notice 'strMessaggio=%',strMessaggio;
    insert into siac_r_movgest_class
    (
   	 movgest_ts_id,
     classif_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select distinct
           ts.movgest_ts_id,
           c.classif_id,
           now(),
           loginOperazione,
           tipo.ente_proprietario_id
 	from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
    	   siac_d_movgest_tipo tipo, siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
    	   siac_t_class c, siac_d_class_tipo tipoc
	 where  tipo.ente_proprietario_id=enteProprietarioId
	 and    tipo.movgest_tipo_code='A'
	 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
	 and    anno.bil_id=mov.bil_id
	 and    anno.anno_bilancio=annoBilancio
	 and    bko.ente_proprietario_id=anno.ente_proprietario_id
	 and    bko.anno_bilancio=anno.anno_bilancio
	 and    bko.anno_accertamento_da=mov.movgest_anno::integer
	 and    bko.numero_accertamento_da=mov.movgest_numero::integer
	 and    ts.movgest_id=mov.movgest_id
	 and    tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	 and    (case when tipots.movgest_ts_tipo_code='T' then bko.numero_subaccertamento_da=0
	              else bko.numero_subaccertamento_da=ts.movgest_ts_code::integer
	         end)
	 and    tipoc.ente_proprietario_id=mov.ente_proprietario_id
     and    tipoc.classif_tipo_code='PDC_V'
	 and    c.classif_tipo_id=tipoc.classif_tipo_id
     and    c.classif_id=bko.pdc_fin_acc_id
     and    c.data_cancellazione is null
     and    c.validita_fine is null;
 else 
  if pdcFin is not null then
    strMessaggio:='collegamento tra classificatori e accertamento PDC_FIN_V : inserimento nuove relazioni.';
    raise notice 'strMessaggio=%',strMessaggio;

 	insert into siac_r_movgest_class
    (
   	 movgest_ts_id,
     classif_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select distinct
           ts.movgest_ts_id,
           c.classif_id,
           now(),
           loginOperazione,
           tipo.ente_proprietario_id
 	from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
    	   siac_d_movgest_tipo tipo, siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
    	   siac_t_class c, siac_d_class_tipo tipoc
	 where  tipo.ente_proprietario_id=enteProprietarioId
	 and    tipo.movgest_tipo_code='A'
	 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
	 and    anno.bil_id=mov.bil_id
	 and    anno.anno_bilancio=annoBilancio
	 and    bko.ente_proprietario_id=anno.ente_proprietario_id
	 and    bko.anno_bilancio=anno.anno_bilancio
	 and    bko.anno_accertamento_da=mov.movgest_anno::integer
	 and    bko.numero_accertamento_da=mov.movgest_numero::integer
	 and    ts.movgest_id=mov.movgest_id
	 and    tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	 and    (case when tipots.movgest_ts_tipo_code='T' then bko.numero_subaccertamento_da=0
	              else bko.numero_subaccertamento_da=ts.movgest_ts_code::integer
	         end)
	 and    tipoc.ente_proprietario_id=mov.ente_proprietario_id
     and    tipoc.classif_tipo_code='PDC_V'
	 and    c.classif_tipo_id=tipoc.classif_tipo_id
     and    c.classif_code=pdcFin
     and    c.data_cancellazione is null
     and    c.validita_fine is null;
  end if;
end if; 

 -- spostamento capitolo su ordinativo

 strMessaggio:='collegamento tra ordinativo e capitolo : annullamento precedente relazione.';
 raise notice 'strMessaggio=%',strMessaggio;

 -- collegamento tra ordinativo e capitolo
 -- annullamento vecchia relazione
 update siac_r_ordinativo_bil_elem r
 set    data_cancellazione=clock_timestamp(),
        validita_fine=clock_timestamp(),
        login_operazione=r.login_operazione||'-'||loginOperazione
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
      siac_v_bko_anno_bilancio anno,
      siac_bko_sposta_ordinativo_inc bko
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='I'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   r.ord_id=ord.ord_id
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   r.data_cancellazione is null
 and   r.validita_fine is null;

 strMessaggio:= 'collegamento tra ordinativo e capitolo : inserimento nuova relazione.';
 raise notice 'strMessaggio=%',strMessaggio;

 -- inserimento nuova relazione
 insert into siac_r_ordinativo_bil_elem
 (
  ord_id,
  elem_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 (
 WITH
 cap as
 (
  select e.elem_code::integer,e.elem_id,e.elem_code2::integer
  from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,siac_v_bko_anno_bilancio anno
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.elem_tipo_code='CAP-EG'
  and   e.elem_tipo_id=tipo.elem_tipo_id
  and   anno.bil_id=e.bil_id
  and   anno.anno_bilancio=annoBilancio
  and   e.data_cancellazione is null
  and   e.validita_fine is null
 ),
 ordin as
 (
 	select distinct
           ord.ord_id,
           bko.numero_capitolo_a,
           bko.numero_articolo_a,
           ord.ente_proprietario_id
    from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
         siac_v_bko_anno_bilancio anno,
         siac_bko_sposta_ordinativo_inc bko
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.ord_tipo_code='I'
    and   ord.ord_tipo_id=tipo.ord_tipo_id
    and   anno.bil_id=ord.bil_id
    and   anno.anno_bilancio=annoBilancio
    and   bko.ente_proprietario_id=tipo.ente_proprietario_id
    and   bko.anno_bilancio=annoBilancio
    and   bko.ord_numero=ord.ord_numero::integer
    and   ord.data_cancellazione is null
    and   ord.validita_fine is null
  )
  select distinct ordin.ord_id,
                  cap.elem_id,
                  now(),
                  loginOperazione,
                  ordin.ente_proprietario_id
  from cap, ordin
  where ordin.numero_capitolo_a=cap.elem_code
  and      ordin.numero_articolo_a=cap.elem_code2
 );

 -- spostamento classificatori su ordinativo

 strMessaggio:= 'collegamento tra ordinativo e classificatori : annullamento precedenti relazioni.';
 raise notice 'strMessaggio=%',strMessaggio;

 -- collegamento tra ordinativo e classificatori
 -- annullamento tra classificatori ordinativo
 update siac_r_ordinativo_class rc
 set    data_cancellazione=clock_timestamp(),
        validita_fine=clock_timestamp(),
        login_operazione=rc.login_operazione||'-'||loginoperazione
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
      siac_v_bko_anno_bilancio anno,
      siac_bko_sposta_ordinativo_inc bko,
      siac_t_class c, siac_d_class_tipo tipoc
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='I'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   rc.ord_id=ord.ord_id
 and   c.classif_id=rc.classif_id
 and   tipoc.classif_tipo_id=c.classif_tipo_id
 and   tipoc.classif_tipo_code in
 (
 'PDC_V',
 'PERIMETRO_SANITARIO_ENTRATA',
 'RICORRENTE_ENTRATA',
 'TRANSAZIONE_UE_ENTRATA'
 )
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   rc.data_cancellazione is null
 and   rc.validita_fine is null;

 -- inserimento nuovi classificatori prendendo da nuova liquidazione
 strMessaggio:= 'collegamento tra ordinativo e classificatori : inserimento nuove relazioni.';
 raise notice 'strMessaggio=%',strMessaggio;

 insert into siac_r_ordinativo_class
 (
	ord_id,
    classif_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
 )
 select distinct ord.ord_id,
                 c.classif_id,
                 now(),
                 loginOperazione,
                 c.ente_proprietario_id
 from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_t_ordinativo_ts ordts,siac_r_ordinativo_ts_movgest_ts rmov,
        siac_r_movgest_class rc, siac_t_class c, siac_d_class_tipo tipoc
 where  tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.ord_tipo_code='I'
 and    ord.ord_tipo_id=tipo.ord_tipo_id
 and    anno.bil_id=ord.bil_id
 and    anno.anno_bilancio=annoBilancio
 and    bko.ente_proprietario_id=anno.ente_proprietario_id
 and    bko.anno_bilancio=anno.anno_bilancio
 and    bko.ord_numero=ord.ord_numero::integer
 and    ordts.ord_id=ord.ord_id
 and    ordts.ord_ts_code::integer=bko.ord_sub_numero
 and    rmov.ord_ts_id=ordts.ord_ts_id
 and    rc.movgest_ts_id=rmov.movgest_ts_id
 and    c.classif_id=rc.classif_id
 and    tipoc.classif_tipo_id=c.classif_tipo_id
 and    tipoc.classif_tipo_code in
 (
 'PDC_V',
 'PERIMETRO_SANITARIO_ENTRATA',
 'RICORRENTE_ENTRATA',
 'TRANSAZIONE_UE_ENTRATA'
 )
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   ordts.data_cancellazione is null
 and   ordts.validita_fine is null
 and   rmov.data_cancellazione is null
 and   rmov.validita_fine is null
 and   rc.data_cancellazione is null
 and   rc.validita_fine is null
 and   c.data_cancellazione is null;




 -- annullamento di tutte le prime note-registri
 if genAggiorna=true then




    -- ordinativo

    strMessaggio:= 'collegamento tra ordinativo e prima nota : inserimento stato annullato.';
    raise notice 'strMessaggio=%',strMessaggio;

  -- inserire stato prima nota annullato, se esiste non annullata
  insert into siac_r_prima_nota_stato
  (
 	pnota_id,
    pnota_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select distinct pnota.pnota_id,
                  statoA.pnota_stato_id,
                  now(),
                  loginOperazione||'-ORD',
                  tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_ordinativo_inc bko,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   revento.campo_pk_id=ord.ord_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OI'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
   and   statoA.pnota_stato_code='A'
   and   ord.data_cancellazione is null
   and   ord.validita_fine is null
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   ep.data_cancellazione is null
   and   ep.validita_fine is null
   and   pnota.data_cancellazione is null
   and   pnota.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null;

   -- annullare prima nota, se presente non annullata
  strMessaggio:= 'collegamento tra ordinativo e prima nota : annullamento stato non annullato prima nota.';
  raise notice 'strMessaggio=%',strMessaggio;

  update siac_r_prima_nota_stato r
  set    data_cancellazione=clock_timestamp(),
         validita_fine=clock_timestamp(),
         login_operazione=r.login_operazione||'-'||loginOperazione||'-ORD'
  from  siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_inc bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   revento.campo_pk_id=ord.ord_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OI'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   ord.data_cancellazione is null
   and   ord.validita_fine is null
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   ep.data_cancellazione is null
   and   ep.validita_fine is null
   and   pnota.data_cancellazione is null
   and   pnota.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null;

   -- inserire stato registro annullato, se esiste non annullato
   strMessaggio:= 'collegamento tra ordinativo e registro prima nota precedente : inserimento stato annullato.';
   raise notice 'strMessaggio=%',strMessaggio;

   insert into siac_r_reg_movfin_stato
   (
  	 regmovfin_id,
     regmovfin_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
   )
   select distinct reg.regmovfin_id,
                   statoA.regmovfin_stato_id,
                   now(),
                   loginOperazione||'-ORD',
                   tipo.ente_proprietario_id
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_inc bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_d_reg_movfin_stato statoA
   where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   revento.campo_pk_id=ord.ord_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OI'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
   and   statoA.regmovfin_stato_code='A'
   and   ord.data_cancellazione is null
   and   ord.validita_fine is null
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null;

   strMessaggio:= 'collegamento tra ordinativo e registro prima nota precedente : annullamento stato non annullato.';
   raise notice 'strMessaggio=%',strMessaggio;

   update siac_r_reg_movfin_stato rrstato
   set    data_cancellazione=clock_timestamp(),
          validita_fine=clock_timestamp(),
          login_operazione=rrstato.login_operazione||'-'||loginOperazione||'-ORD'
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_inc bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg,  siac_d_reg_movfin_stato rstato
   where  tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.ord_tipo_code='I'
    and   ord.ord_tipo_id=tipo.ord_tipo_id
    and   anno.bil_id=ord.bil_id
    and   anno.anno_bilancio=annoBilancio
    and   bko.ente_proprietario_id=tipo.ente_proprietario_id
    and   bko.anno_bilancio=annoBilancio
    and   bko.ord_numero=ord.ord_numero::integer
    and   revento.campo_pk_id=ord.ord_id
    and   evento.evento_id=revento.evento_id
    and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and   coll.collegamento_tipo_code='OI'
    and   reg.regmovfin_id=revento.regmovfin_id
    and   rrstato.regmovfin_id=reg.regmovfin_id
    and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
    and   rstato.regmovfin_stato_code!='A'
    and   ord.data_cancellazione is null
    and   ord.validita_fine is null
    and   revento.data_cancellazione is null
    and   revento.validita_fine is null
    and   reg.data_cancellazione is null
    and   reg.validita_fine is null
    and   rrstato.data_cancellazione is null
    and   rrstato.validita_fine is null;
/* SCRITTO MA MAI PROVATO
  -- documenti
  strMessaggio:= 'collegamento tra documenti e prima nota : inserimento stato annullato.';
  raise notice 'strMessaggio=%',strMessaggio;

  -- inserire stato prima nota annullato, se esiste non annullata
  insert into siac_r_prima_nota_stato
  (
 	pnota_id,
    pnota_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select distinct pnota.pnota_id,
                  statoA.pnota_stato_id,
                  now(),
                  loginOperazione||'-DOC',
                  tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
       siac_t_ordinativo_ts ordts,
       siac_r_subdoc_ordinativo_ts rsub,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   ordts.ord_id=ord.ord_id
   and   ordts.ord_ts_code::integer=bko.ord_sub_numero
   and   rsub.ord_ts_id=ordts.ord_ts_id
   and   revento.campo_pk_id=rsub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='SE'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
   and   statoA.pnota_stato_code='A'
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   ep.data_cancellazione is null
   and   ep.validita_fine is null
   and   pnota.data_cancellazione is null
   and   pnota.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null;

  -- annullare prima nota, se presente non annullata
  strMessaggio:= 'collegamento tra documenti e prima nota : annullamento stato non annullato prima nota.';
  raise notice 'strMessaggio=%',strMessaggio;

  update siac_r_prima_nota_stato r
  set    data_cancellazione=clock_timestamp(),
         validita_fine=clock_timestamp(),
         login_operazione=r.login_operazione||'-'||loginOperazione||'-DOC'
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
       siac_t_ordinativo_ts ordts,
       siac_r_subdoc_ordinativo_ts rsub,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato
  where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   ordts.ord_id=ord.ord_id
   and   ordts.ord_ts_code::integer=bko.ord_sub_numero
   and   rsub.ord_ts_id=ordts.ord_ts_id
   and   revento.campo_pk_id=rsub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='SE'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   ep.data_cancellazione is null
   and   ep.validita_fine is null
   and   pnota.data_cancellazione is null
   and   pnota.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null;

   -- inserire stato registro annullato, se esiste non annullato
   strMessaggio:= 'collegamento tra documenti e registro prima nota precedente : inserimento stato annullato.';
   raise notice 'strMessaggio=%',strMessaggio;


   insert into siac_r_reg_movfin_stato
   (
  	 regmovfin_id,
     regmovfin_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
   )
   select REG.regmovfin_id,
          statoA.regmovfin_stato_id,
          --REG.subdoc_id,
          now(),
          loginOperazione||'-DOC',
	      statoA.ente_proprietario_id
   from siac_d_reg_movfin_stato statoA,
   (
   with
   impegno as
   (
   select distinct rsub.subdoc_id
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_t_ordinativo_ts ordts,
        siac_r_subdoc_ordinativo_ts rsub
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   ordts.ord_id=ord.ord_id
   and   ordts.ord_ts_code::integer=bko.ord_sub_numero
   and   rsub.ord_ts_id=ordts.ord_ts_id
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   ),
   regmov as
   (
   select distinct reg.regmovfin_id,
                   revento.campo_pk_id
   from siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato
   where coll.ente_proprietario_id=enteProprietarioId
   and   coll.collegamento_tipo_code='SE'
   and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and   revento.evento_id=evento.evento_id
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   )
   select impegno.subdoc_id,
          regmov.regmovfin_id
   from impegno, regmov
   where regmov.campo_pk_id=impegno.subdoc_id
   ) REG
   where statoA.ente_proprietario_id=enteProprietarioId
   and   statoA.regmovfin_stato_code='A';


   strMessaggio:= 'collegamento tra documenti e registro prima nota precedente : annullamento stato non annullato.';
   raise notice 'strMessaggio=%',strMessaggio;

   update siac_r_reg_movfin_stato rrstatoUPD
   set    data_cancellazione=clock_timestamp(),
          validita_fine=clock_timestamp(),
          login_operazione=rrstatoUPD.login_operazione||'-'||loginOperazione||'-DOC'
   from
   (
   with
   impegno as
   (
   select distinct rsub.subdoc_id
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_t_ordinativo_ts ordts,
        siac_r_subdoc_ordinativo_ts rsub
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   ordts.ord_id=ord.ord_id
   and   ordts.ord_ts_code::integer=bko.ord_sub_numero
   and   rsub.ord_ts_id=ordts.ord_ts_id
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   ),
   regmov as
   (
   select distinct reg.regmovfin_id,
                   rrstato.regmovfin_stato_r_id,
                   revento.campo_pk_id
   from siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato
   where coll.ente_proprietario_id=enteProprietarioId
   and   coll.collegamento_tipo_code='SE'
   and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and   revento.evento_id=evento.evento_id
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   )
   select impegno.subdoc_id,
          regmov.regmovfin_id,
          regmov.regmovfin_stato_r_id
   from impegno, regmov
   where regmov.campo_pk_id=impegno.subdoc_id
   ) REG
   where rrstatoUPD.ente_proprietario_id=enteProprietarioId
   and   rrstatoUPD.regmovfin_stato_r_id=REG.regmovfin_stato_r_id;
   -- 267
*/
 end if;

 -- inserimento registri notificati per Ordinativi
 if genAggiorna= true and genOrdinativo=true then
  strMessaggio:= 'registro generale ordinativo : inserimento nuovo registro.';
  raise notice 'strMessaggio=%',strMessaggio;

  -- inserire registro in stato NOTIFICATO
  insert into siac_t_reg_movfin
  (
  	classif_id_iniziale,
    classif_id_aggiornato,
    bil_id,
    ambito_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  with
  pdcFin as
  (
  select rc.ord_id, c.classif_id
  from siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipoc
  where tipoc.ente_proprietario_id=enteProprietarioId
  and   tipoc.classif_tipo_code='PDC_V'
  and   c.classif_tipo_id=tipoc.classif_tipo_id
  and   rc.classif_id=c.classif_id
  and  rc.data_cancellazione is null
  and  rc.validita_fine is null
  and  c.data_cancellazione is null
  ),
  ordin as
  (select distinct
          ord.bil_id,
          ord.ord_id,
          a.ambito_id,
          tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_ordinativo_inc bko,
       siac_d_evento evento , siac_d_collegamento_tipo coll,siac_d_ambito a
  where  tipo.ente_proprietario_id=enteProprietarioId
   and  tipo.ord_tipo_code='I'
   and  ord.ord_tipo_id=tipo.ord_tipo_id
   and  anno.bil_id=ord.bil_id
   and  anno.anno_bilancio=annoBilancio
   and  bko.ente_proprietario_id=tipo.ente_proprietario_id
   and  bko.anno_bilancio=annoBilancio
   and  bko.ord_numero=ord.ord_numero::integer
   and  coll.ente_proprietario_id=tipo.ente_proprietario_id
   and  coll.collegamento_tipo_code='OI'
   and  evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and  evento.evento_code='OIN-INS'
   and  a.ente_proprietario_id=tipo.ente_proprietario_id
   and  a.ambito_code='AMBITO_FIN'
   and  ord.data_cancellazione is null
   and  ord.validita_fine is null
  )
  select pdcFin.classif_id,
		 pdcFin.classif_id,
         ordin.bil_id,
         ordin.ambito_id,
         now(),
         loginOperazione||'-ORD'||'@'||ordin.ord_id::varchar,
         ordin.ente_proprietario_id
  from pdcFin, ordin
  where ordin.ord_id=pdcFin.ord_id
  );


  strMessaggio:= 'registro prima nota  ordinativo  : inserimento stato NOTIFICATO.';
  raise notice 'strMessaggio=%',strMessaggio;

  insert into siac_r_reg_movfin_stato
  (
  	regmovfin_id,
    regmovfin_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select reg.regmovfin_id,
         stato.regmovfin_stato_id,
         clock_timestamp(),
         loginOperazione||'-ORD',
         reg.ente_proprietario_id
  from siac_t_reg_movfin reg ,siac_d_reg_movfin_stato stato
  where reg.ente_proprietario_id=enteProprietarioId
  and   reg.login_operazione like loginOperazione||'-ORD'||'@%'
  and   stato.ente_proprietario_id=reg.ente_proprietario_id
  and   stato.regmovfin_stato_code='N';


  strMessaggio:= 'collegamento tra registro prima nota e ordinativo : inserimento relazione.';
  raise notice 'strMessaggio=%',strMessaggio;

  insert into siac_r_evento_reg_movfin
  (
  	regmovfin_id,
    evento_id,
    campo_pk_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select distinct
         reg.regmovfin_id,
         evento.evento_id,
         ord.ord_id,
         now(),
         loginOperazione||'-ORD',
         tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_ordinativo_inc bko,
	   siac_d_evento evento , siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.ord_tipo_code='I'
  and   ord.ord_tipo_id=tipo.ord_tipo_id
  and   anno.bil_id=ord.bil_id
  and   anno.anno_bilancio=annoBilancio
  and   bko.ente_proprietario_id=tipo.ente_proprietario_id
  and   bko.anno_bilancio=annoBilancio
  and   bko.ord_numero=ord.ord_numero::integer
  and   coll.ente_proprietario_id=tipo.ente_proprietario_id
  and   coll.collegamento_tipo_code='OI'
  and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
  and   evento.evento_code='OIN-INS'
  and   reg.ente_proprietario_id=tipo.ente_proprietario_id
  and   reg.login_operazione like loginOperazione||'-ORD'||'@%'
  and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=ord.ord_id
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   reg.data_cancellazione is null
  and   Reg.validita_fine is null;

 end if;




  -- da implementare
  -- inserimento registri notificati per Documento
/* if genAggiorna= true and genDocumento=true then
  strMessaggio:= 'registro generale documento : inserimento nuovo registro.';
  raise notice 'strMessaggio=%',strMessaggio;

  -- inserire registro in stato NOTIFICATO
    insert into siac_t_reg_movfin
   (
    classif_id_iniziale,
    classif_id_aggiornato,
    bil_id ,
    ambito_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
   )
   (
   WITH
   documenti as
   (
   select distinct rsub.subdoc_id, ts.movgest_ts_id,mov.bil_id,ts.ente_proprietario_id
   from siac_d_movgest_tipo tipo,siac_t_movgest mov, siac_t_movgest_ts ts,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_pag_liquidazione bko,
        siac_r_subdoc_movgest_ts rsub,
        siac_d_movgest_ts_tipo tsTipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.movgest_tipo_code='I'
   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
   and   anno.bil_id=mov.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.anno_impegno_a=mov.movgest_anno::integer
   and   bko.numero_impegno_a=mov.movgest_numero::integer
   and   ts.movgest_id=mov.movgest_id
   and   rsub.movgest_ts_id=ts.movgest_ts_id
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   and   ts.movgest_ts_tipo_id = tsTipo.movgest_ts_tipo_id
   and   (ts.movgest_ts_code::integer = bko.numero_subimpegno_a
 	     or
         ( bko.numero_subimpegno_a = '0' and tsTipo.movgest_ts_tipo_code = 'T'))
  ),
  PdcFin as
  (
  select rc.movgest_ts_id, c.classif_id,a.ambito_id
  from siac_r_movgest_class rc, siac_t_class c, siac_d_class_tipo tipoc,siac_d_ambito a
  where tipoc.ente_proprietario_id=enteProprietarioId
  and   tipoc.classif_tipo_code='PDC_V'
  and   c.classif_tipo_id=tipoc.classif_tipo_id
  and   rc.classif_id=c.classif_id
  and   a.ente_proprietario_id=tipoc.ente_proprietario_id
  and   a.ambito_code='AMBITO_FIN'
  and   rc.data_cancellazione is null
  and   rc.validita_fine is null
  )
  select PdcFin.classif_id,
         PdcFin.classif_id,
         documenti.bil_id,
         PdcFin.ambito_id,
	     clock_timestamp(),
         loginOperazione||'-SS@'||documenti.subdoc_id::varchar,
         documenti.ente_proprietario_id
  from  documenti,PdcFin
  where documenti.movgest_ts_id=PdcFin.movgest_ts_id
 );

 strMessaggio:= 'registro prima nota  documento  : inserimento stato NOTIFICATO.';
 raise notice 'strMessaggio=%',strMessaggio;

 insert into siac_r_reg_movfin_stato
 (
 	regmovfin_id,
    regmovfin_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
 )
 select reg.regmovfin_id,
        stato.regmovfin_stato_id,
        clock_timestamp(),
        loginOperazione||'-SS',
        stato.ente_proprietario_id
 from siac_t_reg_movfin reg, siac_d_reg_movfin_stato stato
 where stato.ente_proprietario_id=enteProprietarioId
 and   stato.regmovfin_stato_code='N'
 and   reg.ente_proprietario_id=stato.ente_proprietario_id
 and   reg.login_operazione like loginOperazione||'-SS%';


 strMessaggio:= 'collegamento tra registro prima nota e documento : inserimento relazione.';
 raise notice 'strMessaggio=%',strMessaggio;

 insert into siac_r_evento_reg_movfin
 (
  regmovfin_id,
  evento_id,
  campo_pk_id ,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 (select  reg.regmovfin_id,
         evento.evento_id,
         subdoc.subdoc_id,
         clock_timestamp(),
         loginOperazione||'-SS',
         coll.ente_proprietario_id
 from siac_t_reg_movfin reg,siac_d_evento evento, siac_d_collegamento_tipo coll,siac_t_subdoc subdoc
 where coll.ente_proprietario_id=enteProprietarioId
 and   coll.collegamento_tipo_code='SS'
 and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
 and   evento.evento_code='DSN-INS'
 and   reg.ente_proprietario_id=coll.ente_proprietario_id
 and   reg.login_operazione like loginOperazione||'%SS%'
 and   subdoc.ente_proprietario_id=coll.ente_proprietario_id
 and   subdoc.subdoc_id=
       substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer
);

 end if;
*/







 messaggioRisultato:=strMessaggioFinale||' OK .';

 raise notice 'messaggioRisultato=%',messaggioRisultato;

 return;

exception
    when RAISE_EXCEPTION THEN
        raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
                substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

    when no_data_found THEN
        raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        return;
    when others  THEN
        raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
                substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;

ALTER FUNCTION siac.fnc_siac_bko_sposta_capitolo_su_accertamento (annobilancio integer, pdcfinv_accertamento boolean, pdcfin varchar, enteproprietarioid integer, loginoperazione varchar, genaggiorna boolean, genaccertamento boolean, gendocumento boolean, genordinativo boolean, out codicerisultato integer, out messaggiorisultato varchar)
  OWNER TO siac;

--INC000006308065 - Maurizio - FINE

  --SIAC-8771 INIZIO
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GESC004-ricVarLimitaAVariazioniDefDec','Ricerca variazioni  limitata a variazioni di bilancio definitive decentrate',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacbilapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'BIL_ALTRO'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-GESC004-ricVarLimitaAVariazioniDefDec'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);
--SIAC-8771 FINE

--SIAC-8793 inizio
CREATE OR REPLACE FUNCTION siac.fnc_dba_azione_richiesta_clean (
  p_clean_interval VARCHAR = NULL
)
RETURNS TABLE (
  esito VARCHAR,
  deleted_params BIGINT,
  deleted_rows BIGINT
) AS
$body$
DECLARE

BEGIN
	esito := 'ko';
	deleted_params := 0;
	deleted_rows := 0;

	IF p_clean_interval IS NULL THEN
		RETURN;
	END IF;

	DELETE FROM siac_t_parametro_azione_richiesta WHERE data_creazione < now() - p_clean_interval::INTERVAL;
	GET DIAGNOSTICS deleted_params = ROW_COUNT;
	
	DELETE FROM siac_t_azione_richiesta WHERE data_creazione < now() - p_clean_interval::INTERVAL;
	GET DIAGNOSTICS deleted_rows = ROW_COUNT;

	esito := 'ok';
	RETURN NEXT;
	
	EXCEPTION
	WHEN no_data_found THEN
		RAISE NOTICE 'nessun dato trovato';
	WHEN others THEN
		RAISE NOTICE 'errore : %  - stato: % ', SQLERRM, SQLSTATE;
	RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1;

--SIAC-8793 fine



--SIAC-8788 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR148_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_cons"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR148_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_cons" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  residui_attivi numeric,
  residui_attivi_prec numeric,
  totale_residui_attivi numeric,
  importo_minimo_fondo numeric,
  bil_ele_code3 varchar,
  flag_cassa integer,
  accertamenti_succ numeric,
  crediti_stralciati numeric,
  fondo_dubbia_esig numeric,
  afde_bil_crediti_stralciati numeric,
  afde_bil_crediti_stralciati_fcde numeric,
  afde_bil_accertamenti_anni_successivi numeric,
  afde_bil_accertamenti_anni_successivi_fcde numeric,
  colonna_e numeric,
  perc_media_app numeric
) AS
$body$
DECLARE

classifBilRec record;
bilancio_id integer;
annoCapImp_int integer;
tipomedia varchar;
RTN_MESSAGGIO text;
afde_bilancioId integer;
var_afde_bil_crediti_stralciati numeric;
var_afde_bil_crediti_stralciati_fcde numeric;
var_afde_bil_accertamenti_anni_successivi numeric;
var_afde_bil_accertamenti_anni_successivi_fcde numeric;
  
BEGIN
RTN_MESSAGGIO:='select 1';

annoCapImp_int:= p_anno::integer; 

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id 
	and b.periodo_id=a.periodo_id
and b.anno=p_anno;

raise notice 'bilancio_id = %', bilancio_id;

/*
	SIAC-8154 13/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    
select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

if tipomedia is null then
   tipomedia = 'SEMPLICE';
end if;

*/

--SIAC-8154 21/07/2021
--devo leggere afde_bil_id che serve per l'accesso alla tabella 
--siac.siac_t_acc_fondi_dubbia_esig 
select 	fondi_bil.afde_bil_id, 
	COALESCE(fondi_bil.afde_bil_crediti_stralciati,0),
	COALESCE(fondi_bil.afde_bil_crediti_stralciati_fcde,0),
    COALESCE(fondi_bil.afde_bil_accertamenti_anni_successivi,0),
    COALESCE(fondi_bil.afde_bil_accertamenti_anni_successivi_fcde,0)    
	into afde_bilancioId, var_afde_bil_crediti_stralciati,
    var_afde_bil_crediti_stralciati_fcde, var_afde_bil_accertamenti_anni_successivi,
    var_afde_bil_accertamenti_anni_successivi_fcde    
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='RENDICONTO' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;
    
--    var_afde_bil_crediti_stralciati:=100;
--    var_afde_bil_crediti_stralciati_fcde:=200;
--    var_afde_bil_accertamenti_anni_successivi:=300;
--    var_afde_bil_accertamenti_anni_successivi_fcde:=400;
    
raise notice 'afde_bilancioId = %', afde_bilancioId;

return query
select zz.* from (
with clas as (
	select classif_tipo_desc1 titent_tipo_desc, titolo_code titent_code,
    	 titolo_desc titent_desc, titolo_validita_inizio titent_validita_inizio,
         titolo_validita_fine titent_validita_fine, 
         classif_tipo_desc2 tipologia_tipo_desc,
         tipologia_id, strutt.tipologia_code tipologia_code, 
         strutt.tipologia_desc tipologia_desc,
         tipologia_validita_inizio, tipologia_validita_fine,
         classif_tipo_desc3 categoria_tipo_desc,
         categoria_id, strutt.categoria_code categoria_code, 
         strutt.categoria_desc categoria_desc,
         categoria_validita_inizio, categoria_validita_fine,
         ente_proprietario_id
    from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, 
    											   p_anno,'') strutt 
),
capall as (
with
cap as (
select bil_elem.elem_id,bil_elem.elem_code,bil_elem.elem_desc,
  bil_elem.elem_code2,bil_elem.elem_desc2,bil_elem.elem_id_padre,
  bil_elem.elem_code3,class.classif_id , 
  fcde.acc_fde_denominatore,fcde.acc_fde_denominatore_1,
  fcde.acc_fde_denominatore_2,
  fcde.acc_fde_denominatore_3,fcde.acc_fde_denominatore_4,
  fcde.acc_fde_numeratore,fcde.acc_fde_numeratore_1,
  fcde.acc_fde_numeratore_2,
  fcde.acc_fde_numeratore_3,fcde.acc_fde_numeratore_4,
  COALESCE(fcde.perc_media_applicata, 0) perc_media_applicata,
  fcde.elem_id elem_id_fcde,
  --23/08/2022 SIAC-8788.
  -- per il calcolo della colonna E leggo il dato salvato su DB.
  fcde.acc_fde_accantonamento_anno
  /*case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
        COALESCE(fcde.acc_fde_media_semplice_rapporti, 0)          
    else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
      COALESCE(fcde.acc_fde_media_semplice_totali, 0)        
    else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
        COALESCE(fcde.acc_fde_media_ponderata_rapporti, 0)
    else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
        COALESCE(fcde.acc_fde_media_ponderata_totali,0)     
    else case when tipo_media.afde_tipo_media_code ='UTENTE' then
        COALESCE(fcde.acc_fde_media_utente, 0)      
    end end end end end perc_media_applicata*/
from siac_t_bil_elem bil_elem
--SIAC-8154 07/10/2021.
--aggiunto legame con la tabella dell'fcde perche' si devono
--estrarre solo i capitoli coinvolti.
--SIAC-8575 27/01/2022.
--e' stato richiesto di prendere tutti i capitoli e non solo quelli FCDE,
--per cui il legame con la tabella siac_t_acc_fondi_dubbia_esig viene
--fatto il left join.
	left join (select tab_fcde.elem_id,
    				  tab_fcde.acc_fde_denominatore,
    				  tab_fcde.acc_fde_denominatore_1,
                      tab_fcde.acc_fde_denominatore_2,
                      tab_fcde.acc_fde_denominatore_3,
                      tab_fcde.acc_fde_denominatore_4,
                      tab_fcde.acc_fde_numeratore,
                      tab_fcde.acc_fde_numeratore_1,
                      tab_fcde.acc_fde_numeratore_2,
                      tab_fcde.acc_fde_numeratore_3,
                      tab_fcde.acc_fde_numeratore_4,
                      --23/08/2022 SIAC-8788.
  					  -- per il calcolo della colonna E leggo il dato salvato su DB.
                      tab_fcde.acc_fde_accantonamento_anno,
                      tipo_media.afde_tipo_media_code,
              case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
        		COALESCE(tab_fcde.acc_fde_media_semplice_rapporti, 0)          
              else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
                COALESCE(tab_fcde.acc_fde_media_semplice_totali, 0)        
              else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
                  COALESCE(tab_fcde.acc_fde_media_ponderata_rapporti, 0)
              else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
                  COALESCE(tab_fcde.acc_fde_media_ponderata_totali,0)     
              else case when tipo_media.afde_tipo_media_code ='UTENTE' then
                  COALESCE(tab_fcde.acc_fde_media_utente, 0)      
              end end end end end perc_media_applicata
         		from siac_t_acc_fondi_dubbia_esig tab_fcde
            		left join siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
                	on tipo_media.afde_tipo_media_id=tab_fcde.afde_tipo_media_id
                where tab_fcde.ente_proprietario_id = p_ente_prop_id
                	and tab_fcde.afde_bil_id =  afde_bilancioId
                    and tab_fcde.data_cancellazione is null) fcde
      on fcde.elem_id = bil_elem.elem_id,
     siac_d_bil_elem_tipo bil_elem_tipo,
     siac_r_bil_elem_class r_bil_elem_class,
 	 siac_t_class class,	
     siac_d_class_tipo d_class_tipo,
	 siac_r_bil_elem_categoria r_bil_elem_categ,	
     siac_d_bil_elem_categoria d_bil_elem_categ, 
     siac_r_bil_elem_stato r_bil_elem_stato, 
     siac_d_bil_elem_stato d_bil_elem_stato 
where bil_elem.elem_tipo_id		 = bil_elem_tipo.elem_tipo_id 
and   r_bil_elem_class.elem_id   = bil_elem.elem_id
and   class.classif_id           = r_bil_elem_class.classif_id
and   d_class_tipo.classif_tipo_id      = class.classif_tipo_id
and   d_bil_elem_categ.elem_cat_id          = r_bil_elem_categ.elem_cat_id
and   r_bil_elem_categ.elem_id              = bil_elem.elem_id
and   r_bil_elem_stato.elem_id              = bil_elem.elem_id
and   d_bil_elem_stato.elem_stato_id        = r_bil_elem_stato.elem_stato_id
and   bil_elem.ente_proprietario_id = p_ente_prop_id
and   bil_elem.bil_id               = bilancio_id
and   bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'
and   d_class_tipo.classif_tipo_code	 = 'CATEGORIA'
and	  d_bil_elem_categ.elem_cat_code	     = 'STD'
and	  d_bil_elem_stato.elem_stato_code	     = 'VA'
and   bil_elem.data_cancellazione   is null
and	  bil_elem_tipo.data_cancellazione   is null
and	  r_bil_elem_class.data_cancellazione	 is null
and	  class.data_cancellazione	 is null
and	  d_class_tipo.data_cancellazione 	 is null
and	  r_bil_elem_categ.data_cancellazione 	 is null
and	  d_bil_elem_categ.data_cancellazione	 is null
and	  r_bil_elem_stato.data_cancellazione   is null
and	  d_bil_elem_stato.data_cancellazione   is null
), 
resatt as ( -- Residui Attivi 
select capitolo.elem_id,
       sum (dt_movimento.movgest_ts_det_importo) residui_accertamenti,
       CASE 
         WHEN movimento.movgest_anno < annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'I' THEN
            'RESATT' 
         WHEN movimento.movgest_anno = annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'A' THEN  
            'ACCERT' 
         ELSE
            'ALTRO'
       END tipo_importo         
from siac_t_bil_elem                  capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id 
inner join siac_d_movgest_tipo        tipo_mov on movimento.movgest_tipo_id = tipo_mov.movgest_tipo_id 
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id 
inner join siac_r_movgest_ts_stato    r_movimento_stato on ts_movimento.movgest_ts_id = r_movimento_stato.movgest_ts_id 
inner join siac_d_movgest_stato       tipo_stato on r_movimento_stato.movgest_stato_id = tipo_stato.movgest_stato_id
inner join siac_t_movgest_ts_det      dt_movimento on ts_movimento.movgest_ts_id = dt_movimento.movgest_ts_id 
inner join siac_d_movgest_ts_tipo     ts_mov_tipo on ts_movimento.movgest_ts_tipo_id = ts_mov_tipo.movgest_ts_tipo_id
inner join siac_d_movgest_ts_det_tipo dt_mov_tipo on dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id 
where capitolo.ente_proprietario_id     =   p_ente_prop_id
and   capitolo.bil_id      				=	bilancio_id
and   t_capitolo.elem_tipo_code    		= 	'CAP-EG'
and   movimento.movgest_anno 	        <= 	annoCapImp_int
and   movimento.bil_id					=	bilancio_id
and   tipo_mov.movgest_tipo_code    	=   'A' 
and   tipo_stato.movgest_stato_code     in  ('D','N')
and   ts_mov_tipo.movgest_ts_tipo_code  =   'T'
and   dt_mov_tipo.movgest_ts_det_tipo_code in ('I','A')
and   capitolo.data_cancellazione     	is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione    	is null 
and   movimento.data_cancellazione     	is null 
and   tipo_mov.data_cancellazione     	is null 
and   r_movimento_stato.data_cancellazione is null 
and   ts_movimento.data_cancellazione   is null 
and   tipo_stato.data_cancellazione    	is null 
and   dt_movimento.data_cancellazione   is null 
and   ts_mov_tipo.data_cancellazione    is null 
and   dt_mov_tipo.data_cancellazione    is null
and   now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and   now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
group by tipo_importo, capitolo.elem_id
),
resrisc as ( -- Riscossione residui
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_residui,
            CASE 
             WHEN movimento.movgest_anno < annoCapImp_int THEN
                'RISRES'
             ELSE
                'RISCOMP'
             END tipo_importo                    
from  siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
      siac_t_ordinativo				    ordinativo,
      siac_d_ordinativo_tipo			tipo_ordinativo,
      siac_r_ordinativo_stato			r_stato_ordinativo,
      siac_d_ordinativo_stato			stato_ordinativo,
      siac_t_ordinativo_ts 			    ordinativo_det,
      siac_t_ordinativo_ts_det 		    ordinativo_imp,
      siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
      siac_t_movgest     				movimento,
      siac_t_movgest_ts    			    ts_movimento, 
      siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
where r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
    and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
    and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
    and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
    and	ordinativo.ord_id					=	ordinativo_det.ord_id
    and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
    and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
    and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
    and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
    and	ts_movimento.movgest_id				=	movimento.movgest_id
    and ordinativo_det.ente_proprietario_id	    =	p_ente_prop_id
    and	tipo_ordinativo.ord_tipo_code		= 	'I'	-- Incasso
    ------------------------------------------------------------------------------------------		
    ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
    and	stato_ordinativo.ord_stato_code			<> 'A' -- Annullato
    -----------------------------------------------------------------------------------------------
    and	ordinativo.bil_id					=	bilancio_id
    and movimento.bil_id					=	bilancio_id	
    and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	-- Importo attuale
    and	movimento.movgest_anno				<=	annoCapImp_int	
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
group by tipo_importo, r_capitolo_ordinativo.elem_id
),
resriacc as ( -- Riaccertamenti residui
select capitolo.elem_id,
       sum (t_movgest_ts_det_mod.movgest_ts_det_importo) riaccertamenti_residui
from siac_t_bil_elem     capitolo , 
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
       and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
       and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
       and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id 
       and r_mod_stato.mod_id=t_modifica.mod_id              
       and capitolo.ente_proprietario_id   = p_ente_prop_id           
       and capitolo.bil_id      				=	bilancio_id
       and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
       and movimento.movgest_anno 	< 	annoCapImp_int
       and movimento.bil_id					=	bilancio_id
       and tipo_mov.movgest_tipo_code    	= 'A' 
       and tipo_stato.movgest_stato_code   in ('D','N')
       and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
       and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
       and d_mod_stato.mod_stato_code='V'    
       and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
       and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
       and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
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
     group by capitolo.elem_id	
),
/*
	SIAC-8154 13/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' pi� un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/      
/*
minfondo as ( -- Importo minimo del fondo
SELECT
 rbilelem.elem_id, 
 CASE 
   WHEN tipomedia = 'SEMPLICE' THEN
        round((COALESCE(datifcd.perc_acc_fondi,0)+
        COALESCE(datifcd.perc_acc_fondi_1,0)+
        COALESCE(datifcd.perc_acc_fondi_2,0)+
        COALESCE(datifcd.perc_acc_fondi_3,0)+
        COALESCE(datifcd.perc_acc_fondi_4,0))/5,2)
   ELSE
        round((COALESCE(datifcd.perc_acc_fondi,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_1,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_2,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_3,0)*0.35+
        COALESCE(datifcd.perc_acc_fondi_4,0)*0.35),2)
 END perc_media
 -- ,1 flag_cassa -- SIAC-5854
 , 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
 WHERE rbilelem.acc_fde_id = datifcd.acc_fde_id 
 AND   datifcd.ente_proprietario_id = p_ente_prop_id 
 AND   rbilelem.data_cancellazione is null
), */
minfondo as ( -- Importo minimo del fondo
SELECT
 datifcd.elem_id,   
 case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
    	COALESCE(acc_fde_media_semplice_rapporti, 0)          
    else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
      COALESCE(acc_fde_media_semplice_totali, 0)        
    else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
    	COALESCE(acc_fde_media_ponderata_rapporti, 0)
    else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
    	COALESCE(acc_fde_media_ponderata_totali,0)     
    else case when tipo_media.afde_tipo_media_code ='UTENTE' then
    	COALESCE(acc_fde_media_utente, 0)      
    end end end end end perc_media,        
 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, 
    siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
 WHERE tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
   AND datifcd.ente_proprietario_id = p_ente_prop_id 
   and datifcd.afde_bil_id  = afde_bilancioId
   AND datifcd.data_cancellazione is null
   AND tipo_media.data_cancellazione is null
),
accertcassa as ( -- Accertato per cassa -- SIAC-5854
SELECT rbea.elem_id, 0 flag_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.data_cancellazione is null
AND    ta.data_cancellazione is null
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S'
),
acc_succ as ( -- Accertamenti imputati agli esercizi successivi a quello cui il rendiconto si riferisce
select capitolo.elem_id,
       --sum (t_movgest_ts_det_mod.movgest_ts_det_importo) accertamenti_succ
       sum (dt_movimento.movgest_ts_det_importo) accertamenti_succ
from siac_t_bil_elem     capitolo , 
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
     where capitolo.bil_id      				=	bilancio_id
     and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id     
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
     and movimento.bil_id					=	bilancio_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	> 	annoCapImp_int      
     and tipo_mov.movgest_tipo_code    	= 'A'       
     and tipo_stato.movgest_stato_code   in ('D','N')      
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
     group by capitolo.elem_id	
),
cred_stra as ( -- Crediti stralciati
 select    
   capitolo.elem_id,
   abs(sum (t_movgest_ts_det_mod.movgest_ts_det_importo)) crediti_stralciati
    from siac_t_bil_elem     capitolo , 
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
      siac_d_modifica_tipo d_modif_tipo,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
	  and movimento.ente_proprietario_id   = p_ente_prop_id 
      and movimento.bil_id					=	bilancio_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno 	        <= 	annoCapImp_int      
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'
      /*and ((d_modif_tipo.mod_tipo_code in ('CROR','ECON') and p_anno <= '2016')
            or
           (d_modif_tipo.mod_tipo_code like 'FCDE%' and p_anno >= '2017')
          ) */
      and d_modif_tipo.mod_tipo_code in ('CROR','ECON')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
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
group by capitolo.elem_id),
--SIAC-8154.
--Le query seguenti sono quelle utilizzate per il calcolo dei residui.
--SIAC-8707 06/05/2022.
--L'importo residuo anno del bilancio e' preso da accertamenti - riscossioni
--di competenza
/*stanz_residuo_capitolo as(
  select bil_elem.elem_id, 
      sum(bil_elem_det.elem_det_importo) importo_residui   
  from siac_t_bil_elem bil_elem,	
--SIAC-8575 27/01/2022.
--e' stato richiesto di prendere tutti i capitoli e non solo quelli FCDE
--viene tolto il legame con la tabella siac_t_acc_fondi_dubbia_esig   
     --  siac_t_acc_fondi_dubbia_esig fcde,
       siac_d_bil_elem_tipo bil_elem_tipo,
       siac_t_bil_elem_det bil_elem_det,
       siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
       siac_t_periodo per
  where --bil_elem.elem_id = fcde.elem_id
  bil_elem.elem_tipo_id = bil_elem_tipo.elem_tipo_id
  and bil_elem.elem_id=bil_elem_det.elem_id
  and bil_elem_det.elem_det_tipo_id=d_bil_elem_det_tipo.elem_det_tipo_id
  and per.periodo_id=bil_elem_det.periodo_id
  and bil_elem.ente_proprietario_id= p_ente_prop_id
  --and fcde.afde_bil_id				=  afde_bilancioId
  and bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'    
  and d_bil_elem_det_tipo.elem_det_tipo_code='STR'
  and per.anno			= p_anno
  and bil_elem.data_cancellazione IS NULL
 -- and fcde.data_cancellazione IS NULL
  and bil_elem_tipo.data_cancellazione IS NULL
  and bil_elem_det.data_cancellazione IS NULL
  and d_bil_elem_det_tipo.data_cancellazione IS NULL  
  and bil_elem_det.validita_inizio < CURRENT_TIMESTAMP
  and (bil_elem_det.validita_fine IS NULL OR
       bil_elem_det.validita_fine > CURRENT_TIMESTAMP)
  group by bil_elem.elem_id),
  */
stanz_residuo_capitolo as(  
  select capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) importo_residui_acc
    from siac_t_bil_elem     capitolo , 
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
      and movimento.bil_id					=	capitolo.bil_id
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
      and capitolo.bil_id = bilancio_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno ::text  	= 	p_anno
      and tipo_mov.movgest_tipo_code    	= 'A' --Accertamenti
      and tipo_stato.movgest_stato_code   in ('D','N')      
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
 between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
    and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
 between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
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
riscossioni_competenza as(
---riscossioni di competenza
  select 		r_capitolo_ordinativo.elem_id,
              sum(ordinativo_imp.ord_ts_det_importo) risc_competenza
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
          and movimento.bil_id					=	ordinativo.bil_id
          and	ordinativo.ente_proprietario_id	=	p_ente_prop_id
          and	ordinativo.bil_id					=	bilancio_id										        
          and	tipo_ordinativo.ord_tipo_code		= 	'I'
          and	stato_ordinativo.ord_stato_code			<> 'A'
          and	movimento.movgest_anno				=	annoCapImp_int	
          and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' -- importo attuale        
          and	r_capitolo_ordinativo.data_cancellazione	is null
          and	ordinativo.data_cancellazione				is null
          AND	tipo_ordinativo.data_cancellazione			is null
          and	r_stato_ordinativo.data_cancellazione		is null
          AND	stato_ordinativo.data_cancellazione			is null
          AND ordinativo_det.data_cancellazione				is null
          aND ordinativo_imp.data_cancellazione				is null
          and ordinativo_imp_tipo.data_cancellazione		is null
          and	movimento.data_cancellazione				is null
          and	ts_movimento.data_cancellazione				is null
          and	r_ordinativo_movgest.data_cancellazione		is null
        and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
  between r_capitolo_ordinativo.validita_inizio and COALESCE(r_capitolo_ordinativo.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
    and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
  between r_stato_ordinativo.validita_inizio and COALESCE(r_stato_ordinativo.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
    and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
  between r_ordinativo_movgest.validita_inizio and COALESCE(r_ordinativo_movgest.validita_fine,to_timestamp('31/12/'||'2021','dd/mm/yyyy'))
       group by r_capitolo_ordinativo.elem_id
),
stanz_residuo_capitolo_mod as (
  select bil_elem.elem_id, 
  sum(bil_elem_det_var.elem_det_importo) importo_residui_mod    
  from siac_t_bil_elem bil_elem,	
--SIAC-8575 27/01/2022.
--e' stato richiesto di prendere tutti i capitoli e non solo quelli FCDE
--viene tolto il legame con la tabella siac_t_acc_fondi_dubbia_esig    
       --siac_t_acc_fondi_dubbia_esig fcde,
       siac_d_bil_elem_tipo bil_elem_tipo,
       siac_t_bil_elem_det bil_elem_det,
       siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
       siac_t_periodo per,
       siac_t_bil_elem_det_var bil_elem_det_var,
       siac_r_variazione_stato r_var_stato,
       siac_d_variazione_stato d_var_stato
  where --bil_elem.elem_id = fcde.elem_id
  bil_elem.elem_tipo_id = bil_elem_tipo.elem_tipo_id
  and bil_elem.elem_id=bil_elem_det.elem_id
  and bil_elem_det.elem_det_tipo_id=d_bil_elem_det_tipo.elem_det_tipo_id
  and per.periodo_id=bil_elem_det.periodo_id
  and bil_elem_det_var.elem_det_id=bil_elem_det.elem_det_id
  and bil_elem_det_var.variazione_stato_id=r_var_stato.variazione_stato_id
  and r_var_stato.variazione_stato_tipo_id=d_var_stato.variazione_stato_tipo_id
  and bil_elem.ente_proprietario_id= p_ente_prop_id
  --and fcde.afde_bil_id				=  afde_bilancioId
  and bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'    
  and d_bil_elem_det_tipo.elem_det_tipo_code='STR'
  and per.anno 						= p_anno
  and d_var_stato.variazione_stato_tipo_code not in ('A','D')
  and bil_elem.data_cancellazione IS NULL
  --and fcde.data_cancellazione IS NULL
  and bil_elem_tipo.data_cancellazione IS NULL
  and bil_elem_det.data_cancellazione IS NULL
  and bil_elem_det_var.data_cancellazione IS NULL
  and r_var_stato.data_cancellazione IS NULL
  and d_var_stato.data_cancellazione IS NULL
  and d_bil_elem_det_tipo.data_cancellazione IS NULL  
  and bil_elem_det.validita_inizio < CURRENT_TIMESTAMP
  and (bil_elem_det.validita_fine IS NULL OR
       bil_elem_det.validita_fine > CURRENT_TIMESTAMP)
  group by bil_elem.elem_id),
--SIAC-8707 30/05/2022.  
--Calcolo le colonne A e B come sono calcolate nel report BILR048.
-- Colonna A = RESIDUI ATTIVI DA ESERCIZIO DI COMPETENZA (EC=A-RC)
--Colonna B = RESIDUI ATTIVI DA ESERCIZI PRECEDENTI (EP = RS -RR+R)
accertamenti_A as (      
        select capitolo.elem_id,
        sum (dt_movimento.movgest_ts_det_importo) imp_accertamenti_A
            from siac_t_bil_elem     capitolo , 
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
              and movimento.bil_id					=	capitolo.bil_id
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
              and capitolo.bil_id				  = bilancio_id       
              and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale       
              and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
              and movimento.movgest_anno ::text  	= 	p_anno
              and tipo_mov.movgest_tipo_code    	= 'A' 
              and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
              and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
              and now() 
                between r_mov_capitolo.validita_inizio 
                    and COALESCE(r_mov_capitolo.validita_fine,now())
              and now() 
                between r_movimento_stato.validita_inizio 
                    and COALESCE(r_movimento_stato.validita_fine,now())  
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
risc_conto_comp_RC as(
       select 		r_capitolo_ordinativo.elem_id,
             sum(ordinativo_imp.ord_ts_det_importo) imp_risc_conto_comp_RC
            from siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
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
            and	movimento.ente_proprietario_id		=	p_ente_prop_id
            and movimento.bil_id					=	bilancio_id	
            and	ordinativo.bil_id					=	bilancio_id							   		           
            and	tipo_ordinativo.ord_tipo_code		= 	'I'	--Ordnativo di incasso
            and	stato_ordinativo.ord_stato_code		<> 'A'
            and	ordinativo_imp_tipo.ord_ts_det_tipo_code	= 'A' -- importo attuala
            and	movimento.movgest_anno				=	p_anno::integer	        	
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
            and now() between r_capitolo_ordinativo.validita_inizio 
                and COALESCE(r_capitolo_ordinativo.validita_fine,now())
            and now() between r_stato_ordinativo.validita_inizio 
                and COALESCE(r_stato_ordinativo.validita_fine,now())
            and now() between r_ordinativo_movgest.validita_inizio
             and COALESCE(r_ordinativo_movgest.validita_fine,now())  
         group by r_capitolo_ordinativo.elem_id),
	residui_attivi_RS AS(    
      select capitolo.elem_id, 
                sum (dt_movimento.movgest_ts_det_importo) imp_residui_attivi_RS
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
              and bilancio.bil_id      				=	capitolo.bil_id
              and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
              and movimento.bil_id					=	bilancio.bil_id
              and r_mov_capitolo.elem_id    		=	capitolo.elem_id
              and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
              and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
              and movimento.movgest_id      		= 	ts_movimento.movgest_id 
              and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
              and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
              and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
              and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
              and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
              and anno_eserc.ente_proprietario_id   = p_ente_prop_id 
              and anno_eserc.anno       			=   p_anno
              and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
              and movimento.movgest_anno  	< 	p_anno::integer
              and tipo_mov.movgest_tipo_code    	= 'A'
              and tipo_stato.movgest_stato_code   in ('D','N')       
              and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
              and dt_mov_tipo.movgest_ts_det_tipo_code = 'I'-- 'A' 
              and now() between r_mov_capitolo.validita_inizio 
                and COALESCE(r_mov_capitolo.validita_fine,now())
              and now() between r_movimento_stato.validita_inizio 
                and COALESCE(r_movimento_stato.validita_fine,now())
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
			group by capitolo.elem_id),
  riscossioni_residui_RR as (  	
      select 		r_capitolo_ordinativo.elem_id,
                      sum(ordinativo_imp.ord_ts_det_importo) imp_riscossioni_residui_RR
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
          where r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
              and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
              and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
              and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id        												    	        
              and	ordinativo.ord_id					=	ordinativo_det.ord_id
              and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
              and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
              and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
              and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
              and	ts_movimento.movgest_id				=	movimento.movgest_id
              and movimento.bil_id					=	ordinativo.bil_id	
              and	ordinativo.ente_proprietario_id	=	p_ente_prop_id
              and	ordinativo.bil_id					=	bilancio_id
              and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
              and	stato_ordinativo.ord_stato_code			<> 'A' 
              and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' -- importo attuala
              and	movimento.movgest_anno				<	p_anno::integer	
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
              and now() between r_capitolo_ordinativo.validita_inizio 
                  and COALESCE(r_capitolo_ordinativo.validita_fine,now())
              and now()
                  between r_stato_ordinativo.validita_inizio 
                      and COALESCE(r_stato_ordinativo.validita_fine,now())
              and now()
                  between r_ordinativo_movgest.validita_inizio 
                      and COALESCE(r_ordinativo_movgest.validita_fine,now())
              group by r_capitolo_ordinativo.elem_id),
 riaccertamenti_residui_R as (       	
      select capitolo.elem_id,
         sum (t_movgest_ts_det_mod.movgest_ts_det_importo) imp_riaccertamenti_residui_R
          from siac_t_bil_elem     capitolo , 
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
            where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
            and movimento.bil_id					=	capitolo.bil_id
            and r_mov_capitolo.elem_id    		=	capitolo.elem_id
            and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
            and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
            and movimento.movgest_id      		= 	ts_movimento.movgest_id 
            and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
            and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
            and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
            and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
            and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
            and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
            and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
            and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id 
            and r_mod_stato.mod_id=t_modifica.mod_id  
            and capitolo.ente_proprietario_id   = p_ente_prop_id
            and capitolo.bil_id					= bilancio_id      
            and t_capitolo.elem_tipo_code    	= 	'CAP-EG'
            and movimento.movgest_anno  	< 	p_anno::integer
            and tipo_mov.movgest_tipo_code    	= 'A' --Accertamenti 
            and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
            and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
            and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- importo attuale 
            and d_mod_stato.mod_stato_code='V'           	
            and now() 
              between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
            and now() 
              between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
            and now()
              between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
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
      group by capitolo.elem_id )       
select 
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.classif_id categoria_id,
coalesce(resatt1.residui_accertamenti,0) residui_attivi,
--SIAC-8154 07/10/2021.
--i residui dell'anno precedente devono essere presi dalla tabella
--dell'fcde.
/*
(coalesce(resatt1.residui_accertamenti,0) -
	coalesce(resrisc1.importo_residui,0) +
	coalesce(resriacc.riaccertamenti_residui,0)) residui_attivi_prec,*/
(+COALESCE(cap.acc_fde_denominatore,0)+
COALESCE(cap.acc_fde_denominatore_1,0)+COALESCE(cap.acc_fde_denominatore_2,0)+
COALESCE(cap.acc_fde_denominatore_3,0)+COALESCE(cap.acc_fde_denominatore_4,0))residui_attivi_prec,           
coalesce(minfondo.perc_media,0) perc_media,
-- minfondo.flag_cassa, -- SIAC-5854
coalesce(minfondo.flag_fondo,0) flag_fondo, -- SIAC-5854
coalesce(accertcassa.flag_cassa,1) flag_cassa, -- SIAC-5854
coalesce(acc_succ.accertamenti_succ,0) accertamenti_succ,
coalesce(cred_stra.crediti_stralciati,0) crediti_stralciati,
coalesce(resrisc2.importo_residui,0) residui_competenza,
coalesce(resatt2.residui_accertamenti,0) accertamenti,
--(coalesce(resatt2.residui_accertamenti,0) -
-- coalesce(resrisc2.importo_residui,0)) importo_finale
coalesce(stanz_residuo_capitolo.importo_residui_acc,0) importo_residui_acc,
coalesce(riscossioni_competenza.risc_competenza,0) risc_competenza,
COALESCE(stanz_residuo_capitolo_mod.importo_residui_mod,0) importo_residui_mod,
cap.perc_media_applicata,
cap.elem_id_fcde,
  --23/08/2022 SIAC-8788.
  -- per il calcolo della colonna E leggo il dato salvato su DB.
cap.acc_fde_accantonamento_anno,
COALESCE(accertamenti_A.imp_accertamenti_A,0) imp_accertamenti_A,
COALESCE(risc_conto_comp_RC.imp_risc_conto_comp_RC,0) imp_risc_conto_comp_RC,
COALESCE(residui_attivi_RS.imp_residui_attivi_RS,0) imp_residui_attivi_RS,
COALESCE(riscossioni_residui_RR.imp_riscossioni_residui_RR,0) imp_riscossioni_residui_RR,
COALESCE(riaccertamenti_residui_R.imp_riaccertamenti_residui_R,0) imp_riaccertamenti_residui_R
from cap
left join resatt resatt1
	on cap.elem_id=resatt1.elem_id and resatt1.tipo_importo = 'RESATT'
left join resatt resatt2
	on cap.elem_id=resatt2.elem_id and resatt2.tipo_importo = 'ACCERT'
left join resrisc resrisc1
	on cap.elem_id=resrisc1.elem_id and resrisc1.tipo_importo = 'RISRES'
left join resrisc resrisc2
	on cap.elem_id=resrisc2.elem_id and resrisc2.tipo_importo = 'RISCOMP'
left join resriacc
	on cap.elem_id=resriacc.elem_id
left join minfondo
	on cap.elem_id=minfondo.elem_id
left join accertcassa
	on cap.elem_id=accertcassa.elem_id
left join acc_succ
	on cap.elem_id=acc_succ.elem_id
left join cred_stra
	on cap.elem_id=cred_stra.elem_id
left join stanz_residuo_capitolo
	on cap.elem_id=stanz_residuo_capitolo.elem_id
left join stanz_residuo_capitolo_mod
	on cap.elem_id=stanz_residuo_capitolo_mod.elem_id
left join riscossioni_competenza
	on cap.elem_id=riscossioni_competenza.elem_id  
--SIAC-8707 30/05/2022. 
--Aggiunti i join.      
left join accertamenti_A 
	on cap.elem_id=accertamenti_A.elem_id    
left join risc_conto_comp_RC 
	on cap.elem_id=risc_conto_comp_RC.elem_id  
left join residui_attivi_RS 
	on cap.elem_id=residui_attivi_RS.elem_id        
left join riscossioni_residui_RR 
	on cap.elem_id=riscossioni_residui_RR.elem_id   
left join riaccertamenti_residui_R 
	on cap.elem_id=riaccertamenti_residui_R.elem_id                            
),
fondo_dubbia_esig as (
select  importi.repimp_desc programma_code,
        coalesce(importi.repimp_importo,0) imp_fondo_dubbia_esig
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
		siac_t_bil 						bilancio,
	 	siac_t_periodo 					anno_eserc,
        siac_t_periodo 					anno_comp
where   bilancio.periodo_id				=	anno_eserc.periodo_id 		
and     importi.bil_id					=	bilancio.bil_id 			
and     r_report_importi.rep_id			=	report.rep_id				
and     r_report_importi.repimp_id		=	importi.repimp_id			
and     importi.periodo_id 				=	anno_comp.periodo_id
   				
and     report.ente_proprietario_id		=	p_ente_prop_id				
and		anno_eserc.anno					=	p_anno 						
and 	report.rep_codice				=	'BILR148'
  --24/05/2021 SIAC-8212.
  --Cambiato il codice che identifica le variabili per aggiungere una nota utile
  --all'utente per la compilazione degli importi.
  --and     importi.repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
and 	importi.repimp_codice like 'Colonna E Allegato c) FCDE Rendiconto%'
and     report.data_cancellazione is null
and     importi.data_cancellazione is null
and     r_report_importi.data_cancellazione is null
and     anno_eserc.data_cancellazione is null
and     anno_comp.data_cancellazione is null
and     importi.repimp_desc <> ''
)
select 
p_anno::varchar bil_anno,
''::varchar titent_tipo_code,
clas.titent_tipo_desc::varchar,
clas.titent_code::varchar,
clas.titent_desc::varchar,
''::varchar tipologia_tipo_code,
clas.tipologia_tipo_desc::varchar,
clas.tipologia_code::varchar,
clas.tipologia_desc::varchar,
''::varchar	categoria_tipo_code,
clas.categoria_tipo_desc::varchar,
clas.categoria_code::varchar,
clas.categoria_desc::varchar,
capall.bil_ele_code::varchar,
capall.bil_ele_desc::varchar,
capall.bil_ele_code2::varchar,
capall.bil_ele_desc2::varchar,
capall.bil_ele_id::integer,
capall.bil_ele_id_padre::integer,
--COALESCE(capall.importo_residui::numeric,0) + 
--	COALESCE(capall.importo_residui_mod::numeric,0) residui_attivi,
--COALESCE(capall.importo_residui::numeric,0) -     
--	COALESCE(capall.risc_competenza::numeric,0) residui_attivi,   
--SIAC-8707 30/05/2022. 
--Cambia il calcolo dei residui attivi
--COALESCE(capall.residui_attivi,0) residui_attivi,
(COALESCE(capall.imp_accertamenti_A, 0)  -
	COALESCE(capall.imp_risc_conto_comp_RC, 0))::numeric residui_attivi,
--SIAC-8707 30/05/2022. 
--Cambia il calcolo dei residui attivi anno precedente    
--COALESCE(capall.residui_attivi_prec::numeric,0) residui_attivi_prec,
(COALESCE(capall.imp_residui_attivi_RS, 0) -
 COALESCE(capall.imp_riscossioni_residui_RR, 0) +
 COALESCE(capall.imp_riaccertamenti_residui_R, 0)) residui_attivi_prec,
--SIAC-8707 30/05/2022. 
--Cambia il calcolo dei residui attivi totali
--COALESCE(capall.importo_residui_acc::numeric + capall.importo_residui_mod +
 --capall.residui_attivi_prec::numeric,0) totale_residui_attivi,
(COALESCE(capall.imp_accertamenti_A, 0)  -
	COALESCE(capall.imp_risc_conto_comp_RC, 0)) +
(COALESCE(capall.imp_residui_attivi_RS, 0) -
 COALESCE(capall.imp_riscossioni_residui_RR, 0) +
 COALESCE(capall.imp_riaccertamenti_residui_R, 0))totale_residui_attivi,     
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  COALESCE(round((capall.importo_residui_acc::numeric + 
  capall.importo_residui_mod::numeric +
  capall.residui_attivi_prec::numeric) * (1 - perc_media::numeric/100),2),0)
 ELSE
 0
END 
importo_minimo_fondo,
capall.bil_ele_code3::varchar,
--COALESCE(capall.flag_cassa::integer,0) flag_cassa, -- SAIC-5854
COALESCE(capall.flag_cassa::integer,1) flag_cassa, -- SAIC-5854       
COALESCE(capall.accertamenti_succ::numeric,0) accertamenti_succ,
COALESCE(capall.crediti_stralciati::numeric,0) crediti_stralciati,
imp_fondo_dubbia_esig,
var_afde_bil_crediti_stralciati,
var_afde_bil_crediti_stralciati_fcde,
var_afde_bil_accertamenti_anni_successivi,
var_afde_bil_accertamenti_anni_successivi_fcde,
--SIAC-8575 28/01/2022.
--la colonna E FCDE e' calcolata solo per i capitoli coinvolti nell'FCDE.
--23/08/2022 SIAC-8788.
-- per il calcolo della colonna E leggo il dato salvato su DB.
--Non serve piu' testare capall.elem_id_fcde is not null perche' il valore
--acc_fde_accantonamento_anno esiste solo per i capitoli FCDE. 
--Bisogna fare il round per non avere dei problemi con i decimali in Excel.
--case when capall.elem_id_fcde is not null then
/*  (COALESCE(capall.importo_residui_acc::numeric,0) + 
      COALESCE(capall.importo_residui_mod::numeric,0)) * 
      (100 - capall.perc_media_applicata) / 100 
else 0 end colonna_e,*/
	round(COALESCE(capall.acc_fde_accantonamento_anno,0), 2) colonna_e  ,        
--else 0 end colonna_e, 
capall.perc_media_applicata perc_media_app
from clas 
	left join capall on clas.categoria_id = capall.categoria_id  
	left join fondo_dubbia_esig on fondo_dubbia_esig.programma_code = clas.tipologia_code   
) as zz;

/*raise notice 'query: %',queryfin;
RETURN QUERY queryfin;*/

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

ALTER FUNCTION siac."BILR148_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_cons" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;
  
--SIAC-8788 - Maurizio - FINE


--SIAC-8792 - Maurizio - INIZIO  
  
DROP FUNCTION if exists siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil(p_afde_bil_id integer);
  
CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil (
  p_afde_bil_id integer
)
RETURNS TABLE (
  versione integer,
  fase_attributi_bilancio varchar,
  stato_attributi_bilancio varchar,
  data_ora_elaborazione timestamp,
  anni_esercizio varchar,
  riscossione_virtuosa boolean,
  quinquennio_riferimento varchar,
  capitolo varchar,
  articolo varchar,
  ueb varchar,
  titolo_entrata varchar,
  tipologia varchar,
  categoria varchar,
  sac varchar,
  incasso_conto_competenza numeric,
  accertato_conto_competenza numeric,
  percentuale_incasso_gestione numeric,
  percentuale_accantonamento numeric,
  tipo_precedente varchar,
  percentuale_precedente numeric,
  percentuale_minima numeric,
  percentuale_effettiva numeric,
  stanziamento_0 numeric,
  stanziamento_1 numeric,
  stanziamento_2 numeric,
  accantonamento_fcde_0 numeric,
  accantonamento_fcde_1 numeric,
  accantonamento_fcde_2 numeric,
  accantonamento_graduale numeric,
  stanz_senza_var_0 numeric,
  stanz_senza_var_1 numeric,
  stanz_senza_var_2 numeric,
  delta_var_0 numeric,
  delta_var_1 numeric,
  delta_var_2 numeric
) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
    v_media_utilizzo 		   NUMERIC;
    v_perc_accantonamento	   NUMERIC;
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		)
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				--SIAC-8513 la gestione ha subito delle modifiche, attualmente se non e' presente la media utente
				WHEN 'UTENTE'   THEN 
					v_componente_cento - COALESCE(
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente,
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali,
						--TODO ci sarebbe da mettere la percentuale sullo stanziamento
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto,
						0
					)
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			--SIAC-8768
			, COALESCE(comp_capitolo0.impSta, 0) AS stanz_senza_var_0
			, COALESCE(var_capitolo0.impSta, 0) AS delta_var_0
			, COALESCE(comp_capitolo1.impSta, 0) AS stanz_senza_var_1
			, COALESCE(var_capitolo1.impSta, 0) AS delta_var_1
			, COALESCE(comp_capitolo2.impSta, 0) AS stanz_senza_var_2
			, COALESCE(var_capitolo2.impSta, 0) AS delta_var_2
            --SIAC-8792 26/08/2022
            --Estraggo altri campi che servono per i calcoli successivi.
            , siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
            , siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
            , siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto
            , siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
            , siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			--, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS stanziamento_0
			--, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS stanziamento_1
			--, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS stanziamento_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
        --SIAC-8792 26/08/2022 la percentuale effettiva e' calcolata successivamente
		--percentuale_effettiva := v_loop_var.acc_fde_media;
		--stanziamento_0        := v_loop_var.stanziamento_0;
		--stanziamento_1        := v_loop_var.stanziamento_1;
		--stanziamento_2        := v_loop_var.stanziamento_2;
		stanz_senza_var_0     := v_loop_var.stanz_senza_var_0;
		stanz_senza_var_1     := v_loop_var.stanz_senza_var_1;
		stanz_senza_var_2     := v_loop_var.stanz_senza_var_2;
		delta_var_0           := v_loop_var.delta_var_0;
		delta_var_1           := v_loop_var.delta_var_1;
		delta_var_2           := v_loop_var.delta_var_2;
 
		--SIAC-8768
		
		stanziamento_0 := v_loop_var.stanz_senza_var_0 + v_loop_var.delta_var_0;
		stanziamento_1 := v_loop_var.stanz_senza_var_1 + v_loop_var.delta_var_1;
		stanziamento_2 := v_loop_var.stanz_senza_var_2 + v_loop_var.delta_var_2;
/*
se media utente != null -> 100 - media utente
altrimenti
100 - [max(media_confronto, min(%acc, %stanziamento))]
*/       		
		-- /10000 perche' ho due percentuali per cui moltiplico (v_loop_var.acc_fde_media e accantonamento_graduale)
		-- SIAC-8446: arrotondo gli importi a due cifre decimali
/*		SIAC-8792 26/08/2022
        --Il calcolo dell'accantonamento FCDE prvede il seguente algoritmo:
        
        se media utente != null -> 100 - media utente
		altrimenti
		100 - [max(media_confronto, min(%acc, %stanziamento))]
*/        
        --accantonamento_fcde_0 := ROUND(stanziamento_0 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		--accantonamento_fcde_1 := ROUND(stanziamento_1 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		--accantonamento_fcde_2 := ROUND(stanziamento_2 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		
        if v_loop_var.afde_tipo_media_code = 'UTENTE' THEN
        	v_media_utilizzo:= v_loop_var.acc_fde_media_utente;
        else
        	v_perc_accantonamento:=COALESCE((v_loop_var.acc_fde_numeratore * 100 / stanziamento_0), 0);
            v_media_utilizzo:= GREATEST (v_loop_var.acc_fde_media_confronto,
            	LEAST(v_perc_accantonamento, v_loop_var.acc_fde_media_semplice_totali));
        end if;
		--raise notice 'cap % - v_media_utilizzo = %', capitolo, v_media_utilizzo;
        
		accantonamento_fcde_0 := ROUND(stanziamento_0 * (100 - v_media_utilizzo) / 100, 2);
		accantonamento_fcde_1 := ROUND(stanziamento_1 * (100 - v_media_utilizzo) / 100, 2);
		accantonamento_fcde_2 := ROUND(stanziamento_2 * (100 - v_media_utilizzo) / 100, 2);
		--SIAC-8792 26/08/2022
        --La percentuale effettuva e' il complemento a 100 della media utilizzata.
        percentuale_effettiva := ROUND(100 - v_media_utilizzo, 2); 
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
            --SIAC-8792 26/08/2022
            --Il campo percentuale_accantonamento e' calcolato e non e' la
            --media utente.
			--, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
            , round(COALESCE((siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore * 100 / stanziamento_0), 0), 2)  
			, siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_desc			
            , siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
--				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
--				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
		INTO
			  incasso_conto_competenza
			, accertato_conto_competenza
			, percentuale_incasso_gestione
			, percentuale_accantonamento
			, tipo_precedente
			, percentuale_precedente
			, percentuale_minima
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media_confronto ON (siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_conf_id AND siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.data_cancellazione IS NULL)
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil (p_afde_bil_id integer)
  OWNER TO siac;

--SIAC-8792 - Maurizio - FINE


--SIAC-8787 - Maurizio - INIZIO 

DROP FUNCTION if exists siac.fnc_siac_acc_fondi_dubbia_esig_rendiconto_by_attr_bil(p_afde_bil_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_rendiconto_by_attr_bil (
  p_afde_bil_id integer
)
RETURNS TABLE (
  versione integer,
  fase_attributi_bilancio varchar,
  stato_attributi_bilancio varchar,
  data_ora_elaborazione timestamp,
  anni_esercizio varchar,
  riscossione_virtuosa boolean,
  quinquennio_riferimento varchar,
  capitolo varchar,
  articolo varchar,
  ueb varchar,
  titolo_entrata varchar,
  tipologia varchar,
  categoria varchar,
  sac varchar,
  residui_4 numeric,
  incassi_conto_residui_4 numeric,
  residui_3 numeric,
  incassi_conto_residui_3 numeric,
  residui_2 numeric,
  incassi_conto_residui_2 numeric,
  residui_1 numeric,
  incassi_conto_residui_1 numeric,
  residui_0 numeric,
  incassi_conto_residui_0 numeric,
  media_semplice_totali numeric,
  media_semplice_rapporti numeric,
  media_ponderata_totali numeric,
  media_ponderata_rapporti numeric,
  media_utente numeric,
  percentuale_minima numeric,
  percentuale_effettiva numeric,
  residui_finali numeric,
  accantonamento_fcde numeric,
  accantonamento_graduale numeric
) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
    v_anno_bil				   VARCHAR;
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
        --SIAC-8706 25/05/2022.
        --Aggiunto l'anno del bilancio che serve per le nuove query inserite per
        --il calcolo dei residui finali.
        , siac_t_periodo.anno        
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
        , v_anno_bil
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			-- TODO: aggiungere i dati delle variazioni non definitive e non annullate
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		),
--SIAC-8706 25/05/2022.
--Cambia il calcolo dei resudui finali che deve essere calcolato come nel 
--report BILR203 - campo "TOTALE RESIDUI ATTIVI DA RIPORTARE (TR=EP+EC)".
--Di seguito sono introdotte le query che concorrono al calcolo nel report BILR203
-- Applicando la formula : (A-RC) + (RS-RR+R)  .   
        residui_attivi_RS as (        	
        select capitolo.elem_id, 
                sum (dt_movimento.movgest_ts_det_importo) imp_residui_attivi_RS
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
              and bilancio.bil_id      				=	capitolo.bil_id
              and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
              and movimento.bil_id					=	bilancio.bil_id
              and r_mov_capitolo.elem_id    		=	capitolo.elem_id
              and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
              and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
              and movimento.movgest_id      		= 	ts_movimento.movgest_id 
              and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
              and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
              and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
              and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
              and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
               and anno_eserc.ente_proprietario_id   = v_ente_proprietario_id 
              and anno_eserc.anno       			=   v_anno_bil
              and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
                and movimento.movgest_anno  	< 	v_anno_bil::integer
              and tipo_mov.movgest_tipo_code    	= 'A'
               and tipo_stato.movgest_stato_code   in ('D','N')       
              and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
              and dt_mov_tipo.movgest_ts_det_tipo_code = 'I'--'A' 
              and now() between r_mov_capitolo.validita_inizio 
                and COALESCE(r_mov_capitolo.validita_fine,now())
              and now() between r_movimento_stato.validita_inizio 
                and COALESCE(r_movimento_stato.validita_fine,now())
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
			group by capitolo.elem_id),
	accertamenti_A as (        	
        select capitolo.elem_id, 
                sum (dt_movimento.movgest_ts_det_importo) imp_accertamenti_A
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
              and bilancio.bil_id      				=	capitolo.bil_id
              and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
              and movimento.bil_id					=	bilancio.bil_id
              and r_mov_capitolo.elem_id    		=	capitolo.elem_id
              and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
              and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
              and movimento.movgest_id      		= 	ts_movimento.movgest_id 
              and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
              and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
              and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
              and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
              and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
               and anno_eserc.ente_proprietario_id   = v_ente_proprietario_id 
              and anno_eserc.anno       			=   v_anno_bil 
              and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
                and movimento.movgest_anno  	= 	v_anno_bil::integer
              and tipo_mov.movgest_tipo_code    	= 'A'
               and tipo_stato.movgest_stato_code   in ('D','N')       
              and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
              and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' 
              and now() between r_mov_capitolo.validita_inizio 
                and COALESCE(r_mov_capitolo.validita_fine,now())
              and now() between r_movimento_stato.validita_inizio 
                and COALESCE(r_movimento_stato.validita_fine,now())
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
			group by capitolo.elem_id),
      risc_conto_comp_RC as(
       select 		r_capitolo_ordinativo.elem_id,
             sum(ordinativo_imp.ord_ts_det_importo) imp_risc_conto_comp_RC
            from siac_t_bil 						bilancio,
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
        where 	bilancio.periodo_id					=	anno_eserc.periodo_id
            and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
            and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
            and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
            and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
            and	ordinativo.bil_id					=	bilancio.bil_id
            and	ordinativo.ord_id					=	ordinativo_det.ord_id
            and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
            and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
            and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
            and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
            and	ts_movimento.movgest_id				=	movimento.movgest_id
            and movimento.bil_id					=	bilancio.bil_id								   		
            and	bilancio.ente_proprietario_id	=	v_ente_proprietario_id
            and	anno_eserc.anno						= 	v_anno_bil
            and	tipo_ordinativo.ord_tipo_code		= 	'I'	--Ordnativo di incasso
            and	stato_ordinativo.ord_stato_code		<> 'A'
            and	ordinativo_imp_tipo.ord_ts_det_tipo_code	= 'A' -- importo attuala
            and	movimento.movgest_anno				=	v_anno_bil::integer	        	
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
            and now() between r_capitolo_ordinativo.validita_inizio 
                and COALESCE(r_capitolo_ordinativo.validita_fine,now())
            and now() between r_stato_ordinativo.validita_inizio 
                and COALESCE(r_stato_ordinativo.validita_fine,now())
            and now() between r_ordinativo_movgest.validita_inizio
             and COALESCE(r_ordinativo_movgest.validita_fine,now())  
         group by r_capitolo_ordinativo.elem_id),
	risc_conto_residui_RR as(
       select 		r_capitolo_ordinativo.elem_id,
             sum(ordinativo_imp.ord_ts_det_importo) risc_conto_residui_RR
            from siac_t_bil 						bilancio,
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
        where 	bilancio.periodo_id					=	anno_eserc.periodo_id
            and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
            and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
            and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
            and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
            and	ordinativo.bil_id					=	bilancio.bil_id
            and	ordinativo.ord_id					=	ordinativo_det.ord_id
            and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
            and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
            and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
            and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
            and	ts_movimento.movgest_id				=	movimento.movgest_id
            and movimento.bil_id					=	bilancio.bil_id								   		
            and	bilancio.ente_proprietario_id	=	v_ente_proprietario_id
            and	anno_eserc.anno						= 	v_anno_bil
            and	tipo_ordinativo.ord_tipo_code		= 	'I'	--Ordnativo di incasso
            and	stato_ordinativo.ord_stato_code		<> 'A'
            and	ordinativo_imp_tipo.ord_ts_det_tipo_code	= 'A' -- importo attuala
            and	movimento.movgest_anno				<	v_anno_bil::integer	        	
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
            and now() between r_capitolo_ordinativo.validita_inizio 
                and COALESCE(r_capitolo_ordinativo.validita_fine,now())
            and now() between r_stato_ordinativo.validita_inizio 
                and COALESCE(r_stato_ordinativo.validita_fine,now())
            and now() between r_ordinativo_movgest.validita_inizio
             and COALESCE(r_ordinativo_movgest.validita_fine,now())  
         group by r_capitolo_ordinativo.elem_id),
	riaccertamenti_residui_R as (
        select capitolo.elem_id,
           sum (t_movgest_ts_det_mod.movgest_ts_det_importo) imp_riaccertamenti_residui_R
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
              and bilancio.bil_id      				=	capitolo.bil_id
              and movimento.bil_id					=	bilancio.bil_id
              and r_mov_capitolo.elem_id    		=	capitolo.elem_id
              and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
              and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
              and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
              and movimento.movgest_id      		= 	ts_movimento.movgest_id 
              and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
              and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
              and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id
              and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
              and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
              and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
              and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
              and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
              and r_mod_stato.mod_id=t_modifica.mod_id      
              and anno_eserc.ente_proprietario_id   = v_ente_proprietario_id        
              and anno_eserc.anno       			=   v_anno_bil 
              and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
              and movimento.movgest_anno   			< 	v_anno_bil::integer
              and tipo_mov.movgest_tipo_code    	= 'A' --Accertamento 
              and tipo_stato.movgest_stato_code   in ('D','N')       
              and ts_mov_tipo.movgest_ts_tipo_code  = 'T' --Testata
              and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' --importo attuale 
              and d_mod_stato.mod_stato_code='V'            
              and now() between r_mov_capitolo.validita_inizio 
                and COALESCE(r_mov_capitolo.validita_fine,now())
              and now() between r_movimento_stato.validita_inizio 
                and COALESCE(r_movimento_stato.validita_fine,now())
              and now()between r_mod_stato.validita_inizio 
                and COALESCE(r_mod_stato.validita_fine,now())
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
        group by capitolo.elem_id)                               
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				WHEN 'SEMP_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				WHEN 'POND_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				WHEN 'POND_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
				WHEN 'UTENTE'   THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			--SIAC-8706 25/05/2022.
            --Cambia la formula per i residui finali
            --, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS residui_finali
            , COALESCE(res_att_RS.imp_residui_attivi_RS, 0) AS imp_residui_attivi_RS
			, COALESCE(accert_A.imp_accertamenti_A, 0) AS imp_accertamenti_A
            , COALESCE(risc_cc_RC.imp_risc_conto_comp_RC, 0) as imp_risc_conto_comp_RC
            , COALESCE(risc_cres_RR.risc_conto_residui_RR, 0) as risc_conto_residui_RR
            , COALESCE(riacc_res_R.imp_riaccertamenti_residui_R, 0) as imp_riaccertamenti_residui_R           
            --, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS residui_finali_1
			--, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS residui_finali_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		--SIAC-8706 25/05/2022.
        --Aggiunte le tabelle per il calcolo dei residui finali.
        LEFT OUTER JOIN residui_attivi_RS AS res_att_RS ON (siac_t_bil_elem.elem_id = res_att_RS.elem_id)
        LEFT OUTER JOIN accertamenti_A AS accert_A ON (siac_t_bil_elem.elem_id = accert_A.elem_id)        
        LEFT OUTER JOIN risc_conto_comp_RC AS risc_cc_RC ON (siac_t_bil_elem.elem_id = risc_cc_RC.elem_id)        
        LEFT OUTER JOIN risc_conto_residui_RR AS risc_cres_RR ON (siac_t_bil_elem.elem_id = risc_cres_RR.elem_id)       
        LEFT OUTER JOIN riaccertamenti_residui_R AS riacc_res_R ON (siac_t_bil_elem.elem_id = riacc_res_R.elem_id)        
        WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
		percentuale_effettiva := v_loop_var.acc_fde_media;
			--SIAC-8706 25/05/2022.
            --Cambia la formula per i residui finali:
            --Residui finali = (A-RC) + (RS-RR+R)        
		--residui_finali        := v_loop_var.residui_finali;        
        residui_finali		  := (v_loop_var.imp_accertamenti_A-v_loop_var.imp_risc_conto_comp_RC)+ 
        	(v_loop_var.imp_residui_attivi_RS-v_loop_var.risc_conto_residui_RR +
             v_loop_var.imp_riaccertamenti_residui_R) ;
		--residui_finali_1      := v_loop_var.residui_finali_1;		
		--residui_finali_2      := v_loop_var.residui_finali_2;
		-- /100 perche' ho una percentuale per cui moltiplico (v_loop_var.acc_fde_media)
			--SIAC-8706 25/05/2022.
            --Cambia la formula per i residui finali
        --accantonamento_fcde   := v_loop_var.residui_finali * v_loop_var.acc_fde_media / 100;
		accantonamento_fcde   := residui_finali * v_loop_var.acc_fde_media / 100;
raise notice 'Capitolo: % - Percentuale: % - Residui finali: % - Accontonamento: %',
	        capitolo, v_loop_var.acc_fde_media, residui_finali, accantonamento_fcde;
            
        --accantonamento_fcde_1 := v_loop_var.residui_finali_1 * v_loop_var.acc_fde_media / 100;
		--accantonamento_fcde_2 := v_loop_var.residui_finali_2 * v_loop_var.acc_fde_media / 100;
		
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
			-- SIAC-8446 - lettura del dato da DB
			 
            --23/08/2022 SIAC-8787.
            --Nell'Excel occorre arrotondare il valore dell'accantonamento FCDE 
            --a 2 cifre decimali per evitare valori errati nei totali.
            --, siac_t_acc_fondi_dubbia_esig.acc_fde_accantonamento_anno
            , ROUND(siac_t_acc_fondi_dubbia_esig.acc_fde_accantonamento_anno,2)
		INTO
			incassi_conto_residui_4
			, residui_4
			, incassi_conto_residui_3
			, residui_3
			, incassi_conto_residui_2
			, residui_2
			, incassi_conto_residui_1
			, residui_1
			, incassi_conto_residui_0
			, residui_0
			, media_semplice_totali
			, media_semplice_rapporti
			, media_ponderata_totali
			, media_ponderata_rapporti
			, media_utente
			, percentuale_minima
			, accantonamento_fcde
		FROM siac_t_acc_fondi_dubbia_esig
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_rendiconto_by_attr_bil (p_afde_bil_id integer)
  OWNER TO siac;  
  
--SIAC-8787 - Maurizio - FINE
 
 