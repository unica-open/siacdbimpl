/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."BILR013_Allegato_A_Risultato_Amministrazione_Presunto" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  accertamento numeric,
  impegnato numeric,
  variazioni_su_spese numeric,
  variazioni_su_entrate numeric,
  fase_bilancio varchar
) AS
$body$
DECLARE

annoCapImp varchar;
anno_bil_accertamento	varchar;
anno_delibera varchar;
elemTipoCode_EP varchar;
elemTipoCode_UP varchar;
fase_bilancio varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;


BEGIN

annoCapImp:= p_anno; 
elemTipoCode_EP:='CAP-EP'; -- tipo capitolo previsione
elemTipoCode_UP:='CAP-UP';	--- Capitolo gestione 

anno_bil_accertamento:= ((p_anno::INTEGER)-1)::VARCHAR;
anno_delibera:= ((p_anno::INTEGER)-1)::VARCHAR;


raise notice '%', annoCapImp;

bil_anno='';
accertamento=0;
fase_bilancio='';
bil_anno:= p_anno;

RTN_MESSAGGIO:='lettura anno di bilancio''.';  
select fase.fase_operativa_code
into  fase_bilancio
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
		now() between fase.validita_inizio and coalesce (fase.validita_fine, now());

 if fase_bilancio = 'P'  then
      anno_bil_accertamento:= ((p_anno::INTEGER)-1)::VARCHAR;
  else
      anno_bil_accertamento:=p_anno;
  end if;
  
  


RTN_MESSAGGIO:='lettura accertamento''.';  

select sum (COALESCE(dt_movimento.movgest_ts_det_importo,0))
INTO accertamento 
from siac_t_bil bilancio, 
siac_t_periodo anno_eserc, 
siac_t_bil_elem capitolo , 
siac_r_movgest_bil_elem r_mov_capitolo, 
siac_d_bil_elem_tipo t_capitolo, 
siac_t_movgest movimento, 
siac_d_movgest_tipo tipo_mov, 
siac_t_movgest_ts ts_movimento, 
siac_r_movgest_ts_stato r_movimento_stato, 
siac_d_movgest_stato tipo_stato, 
siac_t_movgest_ts_det dt_movimento, 
siac_d_movgest_ts_tipo ts_mov_tipo, 
siac_d_movgest_ts_det_tipo dt_mov_tipo 
where 
bilancio.periodo_id = anno_eserc.periodo_id 
and anno_eserc.anno =  anno_bil_accertamento 
and bilancio.bil_id=capitolo.bil_id
and movimento.bil_id = bilancio.bil_id 
and capitolo.elem_tipo_id = t_capitolo.elem_tipo_id 
and t_capitolo.elem_tipo_code =  elemTipoCode_EP 
and movimento.movgest_anno::text = annoCapImp
---and r_mov_capitolo.elem_id = capitoloRec.bil_ele_id 
and r_mov_capitolo.elem_id=capitolo.elem_id
and r_mov_capitolo.movgest_id = movimento.movgest_id 
and movimento.movgest_tipo_id = tipo_mov.movgest_tipo_id 
and tipo_mov.movgest_tipo_code = 'A' 
and movimento.movgest_id = ts_movimento.movgest_id 
and ts_movimento.movgest_ts_id = r_movimento_stato.movgest_ts_id 
and r_movimento_stato.movgest_stato_id = tipo_stato.movgest_stato_id 
and tipo_stato.movgest_stato_code = 'D' ------ P,A,N 
and ts_movimento.movgest_ts_tipo_id = ts_mov_tipo.movgest_ts_tipo_id 
and ts_mov_tipo.movgest_ts_tipo_code = 'T' 
and ts_movimento.movgest_ts_id = dt_movimento.movgest_ts_id 
and dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id 
and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
and anno_eserc.data_cancellazione is null 
and bilancio.data_cancellazione is null 
and capitolo.data_cancellazione is null 
and r_mov_capitolo.data_cancellazione is null 
and t_capitolo.data_cancellazione is null 
and movimento.data_cancellazione is null 
and tipo_mov.data_cancellazione is null 
and r_movimento_stato.data_cancellazione is null 
and ts_movimento.data_cancellazione is null 
and tipo_stato.data_cancellazione is null 
and dt_movimento.data_cancellazione is null 
and ts_mov_tipo.data_cancellazione is null 
and dt_mov_tipo.data_cancellazione is null 
and anno_eserc.ente_proprietario_id = p_ente_prop_id 
and bilancio.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and capitolo.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and r_mov_capitolo.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and t_capitolo.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and movimento.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and tipo_mov.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and ts_movimento.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and r_movimento_stato.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and tipo_stato.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and dt_movimento.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and ts_mov_tipo.ente_proprietario_id = anno_eserc.ente_proprietario_id 
and dt_mov_tipo.ente_proprietario_id = anno_eserc.ente_proprietario_id; 


RTN_MESSAGGIO:='lettura impegnato''.';  

select sum (COALESCE(dt_movimento.movgest_ts_det_importo,0))
INTO impegnato 
from siac_t_bil bilancio, 
siac_t_periodo anno_eserc, 
siac_t_bil_elem capitolo , 
siac_r_movgest_bil_elem r_mov_capitolo, 
siac_d_bil_elem_tipo t_capitolo, 
siac_t_movgest movimento, 
siac_d_movgest_tipo tipo_mov, 
siac_t_movgest_ts ts_movimento, 
siac_r_movgest_ts_stato r_movimento_stato, 
siac_d_movgest_stato tipo_stato, 
siac_t_movgest_ts_det dt_movimento, 
siac_d_movgest_ts_tipo ts_mov_tipo, 
siac_d_movgest_ts_det_tipo dt_mov_tipo 
where 
bilancio.periodo_id = anno_eserc.periodo_id 
and anno_eserc.anno =  anno_bil_accertamento 
and bilancio.bil_id=capitolo.bil_id
and movimento.bil_id = bilancio.bil_id 
and capitolo.elem_tipo_id = t_capitolo.elem_tipo_id 
and t_capitolo.elem_tipo_code =  elemTipoCode_UP 
and movimento.movgest_anno::text = annoCapImp
---and r_mov_capitolo.elem_id = capitoloRec.bil_ele_id 
and r_mov_capitolo.elem_id=capitolo.elem_id
and r_mov_capitolo.movgest_id = movimento.movgest_id 
and movimento.movgest_tipo_id = tipo_mov.movgest_tipo_id 
and tipo_mov.movgest_tipo_code = 'I' 
and movimento.movgest_id = ts_movimento.movgest_id 
and ts_movimento.movgest_ts_id = r_movimento_stato.movgest_ts_id 
and r_movimento_stato.movgest_stato_id = tipo_stato.movgest_stato_id 
and tipo_stato.movgest_stato_code = 'D' ------ P,A,N 
and ts_movimento.movgest_ts_tipo_id = ts_mov_tipo.movgest_ts_tipo_id 
and ts_mov_tipo.movgest_ts_tipo_code = 'T' 
and ts_movimento.movgest_ts_id = dt_movimento.movgest_ts_id 
and dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id 
and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
and anno_eserc.data_cancellazione is null 
and bilancio.data_cancellazione is null 
and capitolo.data_cancellazione is null 
and r_mov_capitolo.data_cancellazione is null 
and t_capitolo.data_cancellazione is null 
and movimento.data_cancellazione is null 
and tipo_mov.data_cancellazione is null 
and r_movimento_stato.data_cancellazione is null 
and ts_movimento.data_cancellazione is null 
and tipo_stato.data_cancellazione is null 
and dt_movimento.data_cancellazione is null 
and ts_mov_tipo.data_cancellazione is null 
and dt_mov_tipo.data_cancellazione is null 
and anno_eserc.ente_proprietario_id = p_ente_prop_id; 

RTN_MESSAGGIO:='variazione_su_spese''.';  

 select sum (COALESCE(dettaglio_variazione.elem_det_importo,0))
 INTO variazioni_su_spese 
     	from 		siac_t_atto_amm 			atto,
					siac_d_atto_amm_stato 		stato_atto,
                    siac_r_atto_amm_stato 		r_atto_stato,
                    siac_r_atto_amm_class		r_classif_atto,
                    siac_t_class				classificatore,
                    siac_r_variazione_stato		r_variazione_stato,
                    siac_t_variazione 			testata_variazione,
                    siac_d_variazione_stato 	tipologia_stato_var,
                    siac_t_bil_elem_det_var 	dettaglio_variazione,
                    siac_d_variazione_tipo		tipologia_variazione,
                    siac_t_bil_elem				capitolo,
                    siac_d_bil_elem_tipo 		tipo_capitolo,
                    siac_t_bil 					bilancio,
                    siac_d_bil_elem_stato 		stato_capitolo, 
     				siac_r_bil_elem_stato 		r_capitolo_stato, 
                    siac_t_bil_elem_det 		capitolo_importi,
         			siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                    siac_t_periodo 				capitolo_imp_periodo,
                    siac_d_bil_elem_categoria 	cat_del_capitolo,
     				siac_r_bil_elem_categoria 	r_cat_capitolo
		where 	atto.attoamm_anno 										= 	anno_delibera
		and		atto.attoamm_id											=	r_atto_stato.attoamm_id
		and 	stato_atto.attoamm_stato_code							=	'DEFINITIVO'
		and 	r_atto_stato.attoamm_stato_id							=	stato_atto.attoamm_stato_id
		and		r_classif_atto.attoamm_id								=	atto.attoamm_id
		and 	r_classif_atto.classif_id								=	classificatore.classif_id
		and 	r_variazione_stato.attoamm_id							=	atto.attoamm_id
		and		r_variazione_stato.variazione_id						=	testata_variazione.variazione_id	
		and		testata_variazione.variazione_tipo_id					=	tipologia_variazione.variazione_tipo_id
        -- 15/06/2016: cambiati i tipi di variazione.        
		--and		tipologia_variazione.variazione_tipo_code				in ('ST','VA')
        and		tipologia_variazione.variazione_tipo_code				in ('ST','VA', 'VR', 'PF', 'AS')
		and		tipologia_stato_var.variazione_stato_tipo_id			=	r_variazione_stato.variazione_stato_tipo_id
		and		r_variazione_stato.variazione_stato_id					=	dettaglio_variazione.variazione_stato_id
		and 	tipologia_stato_var.variazione_stato_tipo_code			=	'D'
		and 	dettaglio_variazione.elem_id							= 	capitolo.elem_id
        and		capitolo.elem_id										=	r_capitolo_stato.elem_id			
		and		r_capitolo_stato.elem_stato_id							=	stato_capitolo.elem_stato_id		
		and		stato_capitolo.elem_stato_code							=	'VA'						
       	and		capitolo.elem_id										=	capitolo_importi.elem_id 
        and		capitolo.elem_tipo_id									=	tipo_capitolo.elem_tipo_id						
        and		tipo_capitolo.elem_tipo_code 							= 	elemTipoCode_UP
        and		capitolo_importi.elem_det_tipo_id						=	capitolo_imp_tipo.elem_det_tipo_id
        and		capitolo_imp_tipo.elem_det_tipo_code					=	'STA'
      	and		dettaglio_variazione.elem_det_tipo_id					= 	capitolo_importi.elem_det_tipo_id
        and		capitolo_importi.periodo_id								=	capitolo_imp_periodo.periodo_id		  
        and		capitolo_imp_periodo.anno 								<=	anno_delibera	
        ----and		capitolo.elem_id										=	r_cat_capitolo.elem_id				
		----and		r_cat_capitolo.elem_cat_id								=	cat_del_capitolo.elem_cat_id
		----and		cat_del_capitolo.elem_cat_code							=	'STD'
        and 	atto.ente_proprietario_id								=	p_ente_prop_id
        and		atto.data_cancellazione													is null
 		and 	stato_atto.data_cancellazione												is null
        and 	r_atto_stato.data_cancellazione											is null
        and		r_classif_atto.data_cancellazione											is null	
        and		classificatore.data_cancellazione											is null
        and		r_variazione_stato.data_cancellazione										is null
        and 	testata_variazione.data_cancellazione										is null
        and 	tipologia_stato_var.data_cancellazione										is null
        and 	dettaglio_variazione.data_cancellazione									is null
        and		tipologia_variazione.data_cancellazione									is null
        and		capitolo.data_cancellazione												is null
        and 	tipo_capitolo.data_cancellazione											is null
        and 	bilancio.data_cancellazione												is null
        and 	stato_capitolo.data_cancellazione											is null 
     	and 	r_capitolo_stato.data_cancellazione										is null 
        and 	capitolo_importi.data_cancellazione										is null
        and 	capitolo_imp_tipo.data_cancellazione										is null
        and 	capitolo_imp_periodo.data_cancellazione									is null
        and 	cat_del_capitolo.data_cancellazione										is null
     	and 	r_cat_capitolo.data_cancellazione											is null;

RTN_MESSAGGIO:='variazione_su_spese''.';  

 select sum (COALESCE(dettaglio_variazione.elem_det_importo,0))
 INTO variazioni_su_entrate 
     	from 		siac_t_atto_amm 			atto,
					siac_d_atto_amm_stato 		stato_atto,
                    siac_r_atto_amm_stato 		r_atto_stato,
                    siac_r_atto_amm_class		r_classif_atto,
                    siac_t_class				classificatore,
                    siac_r_variazione_stato		r_variazione_stato,
                    siac_t_variazione 			testata_variazione,
                    siac_d_variazione_stato 	tipologia_stato_var,
                    siac_t_bil_elem_det_var 	dettaglio_variazione,
                    siac_d_variazione_tipo		tipologia_variazione,
                    siac_t_bil_elem				capitolo,
                    siac_d_bil_elem_tipo 		tipo_capitolo,
                    siac_t_bil 					bilancio,
                    siac_d_bil_elem_stato 		stato_capitolo, 
     				siac_r_bil_elem_stato 		r_capitolo_stato, 
                    siac_t_bil_elem_det 		capitolo_importi,
         			siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                    siac_t_periodo 				capitolo_imp_periodo,
                    siac_d_bil_elem_categoria 	cat_del_capitolo,
     				siac_r_bil_elem_categoria 	r_cat_capitolo
		where 	atto.attoamm_anno 										= 	anno_delibera
		and		atto.attoamm_id											=	r_atto_stato.attoamm_id
		and 	stato_atto.attoamm_stato_code							=	'DEFINITIVO'
		and 	r_atto_stato.attoamm_stato_id							=	stato_atto.attoamm_stato_id
		and		r_classif_atto.attoamm_id								=	atto.attoamm_id
		and 	r_classif_atto.classif_id								=	classificatore.classif_id
		and 	r_variazione_stato.attoamm_id							=	atto.attoamm_id
		and		r_variazione_stato.variazione_id						=	testata_variazione.variazione_id	
		and		testata_variazione.variazione_tipo_id					=	tipologia_variazione.variazione_tipo_id
		and		tipologia_variazione.variazione_tipo_code				in ('ST','VA')
		and		tipologia_stato_var.variazione_stato_tipo_id			=	r_variazione_stato.variazione_stato_tipo_id
		and		r_variazione_stato.variazione_stato_id					=	dettaglio_variazione.variazione_stato_id
		and 	tipologia_stato_var.variazione_stato_tipo_code			=	'D'
		and 	dettaglio_variazione.elem_id							= 	capitolo.elem_id
        and		capitolo.elem_id										=	r_capitolo_stato.elem_id			
		and		r_capitolo_stato.elem_stato_id							=	stato_capitolo.elem_stato_id		
		and		stato_capitolo.elem_stato_code							=	'VA'						
       	and		capitolo.elem_id										=	capitolo_importi.elem_id 
        and		capitolo.elem_tipo_id									=	tipo_capitolo.elem_tipo_id						
        and		tipo_capitolo.elem_tipo_code 							= 	elemTipoCode_EP
        and		capitolo_importi.elem_det_tipo_id						=	capitolo_imp_tipo.elem_det_tipo_id
        and		capitolo_imp_tipo.elem_det_tipo_code					=	'STA'
      	and		dettaglio_variazione.elem_det_tipo_id					= 	capitolo_importi.elem_det_tipo_id
        and		capitolo_importi.periodo_id								=	capitolo_imp_periodo.periodo_id		  
        and		capitolo_imp_periodo.anno 								<=	anno_delibera	
        ----and		capitolo.elem_id										=	r_cat_capitolo.elem_id				
		----and		r_cat_capitolo.elem_cat_id								=	cat_del_capitolo.elem_cat_id
		----and		cat_del_capitolo.elem_cat_code							=	'STD'
        and 	atto.ente_proprietario_id								=	p_ente_prop_id
        and		atto.data_cancellazione													is null
 		and 	stato_atto.data_cancellazione												is null
        and 	r_atto_stato.data_cancellazione											is null
        and		r_classif_atto.data_cancellazione											is null	
        and		classificatore.data_cancellazione											is null
        and		r_variazione_stato.data_cancellazione										is null
        and 	testata_variazione.data_cancellazione										is null
        and 	tipologia_stato_var.data_cancellazione										is null
        and 	dettaglio_variazione.data_cancellazione									is null
        and		tipologia_variazione.data_cancellazione									is null
        and		capitolo.data_cancellazione												is null
        and 	tipo_capitolo.data_cancellazione											is null
        and 	bilancio.data_cancellazione												is null
        and 	stato_capitolo.data_cancellazione											is null 
     	and 	r_capitolo_stato.data_cancellazione										is null 
        and 	capitolo_importi.data_cancellazione										is null
        and 	capitolo_imp_tipo.data_cancellazione										is null
        and 	capitolo_imp_periodo.data_cancellazione									is null
        and 	cat_del_capitolo.data_cancellazione										is null
     	and 	r_cat_capitolo.data_cancellazione											is null;

return next;

exception
 	when others  THEN
		RAISE EXCEPTION '% Errore  : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;