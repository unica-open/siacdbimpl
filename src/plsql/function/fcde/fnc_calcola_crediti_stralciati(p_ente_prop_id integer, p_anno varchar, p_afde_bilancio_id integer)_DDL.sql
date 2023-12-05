/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_calcola_crediti_stralciati (
  p_ente_prop_id integer,
  p_anno varchar,
  p_afde_bilancio_id integer
)
RETURNS TABLE (
  afde_bil_crediti_stralciati numeric,
  afde_bil_crediti_stralciati_fcde numeric,
  afde_bil_accertamenti_anni_successivi numeric,
  afde_bil_accertamenti_anni_successivi_fcde numeric
) AS
$body$
DECLARE

bilancio_id integer;
RTN_MESSAGGIO text;

BEGIN

/* SIAC-8384 15/10/2021.
	Funzione creata per resitutire i valori dei crediti stralciati secondo le
    nuove regole comunicate.
    E' richiamata direttamente da Contabilia per presentare i campi nella
    maschera di FCDE.
*/

afde_bil_crediti_stralciati:=0;
afde_bil_crediti_stralciati_fcde:=0;
afde_bil_accertamenti_anni_successivi:=0;
afde_bil_accertamenti_anni_successivi_fcde:=0;


select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id  
  and b.periodo_id=a.periodo_id
  and b.anno=p_anno;


--Somma delle modifiche di accertamento (INEROR - ROR - Cancellazione per Inesigibilita' - entrate) 
-- + (INESIG - Cancellazione per Inesigibilita') con anno <=n
--Quindi rendiconto 2021 : modifiche accertamenti <=2021 - senza perimetro capitoli di pertinenza, 
--Titolo 1, 2, 3, 4 e 5.      
with struttura as (select *
 from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
capitoli as (      
    select class.classif_id categoria_id,
       t_movgest_ts_det_mod.movgest_ts_det_importo
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
        siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
        siac_t_class class,	
        siac_d_class_tipo d_class_tipo,
        siac_r_bil_elem_class r_bil_elem_class
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
      and   class.classif_id           = r_bil_elem_class.classif_id
	  and   d_class_tipo.classif_tipo_id      = class.classif_tipo_id
      and   r_bil_elem_class.elem_id   = capitolo.elem_id
	  and movimento.ente_proprietario_id   = p_ente_prop_id 
      and movimento.bil_id					=	bilancio_id 
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      	--accertamenti con anno <=anno bilancio
      and movimento.movgest_anno 	        <= 	p_anno::integer 
      and tipo_mov.movgest_tipo_code    	= 'A' --accertamenti
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'
      --Prima era:
      --and d_modif_tipo.mod_tipo_code in ('CROR','ECON')
      and d_modif_tipo.mod_tipo_code in ('INEROR','INESIG')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and d_class_tipo.classif_tipo_code	 = 'CATEGORIA'      
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
      and class.data_cancellazione    is null  
      and d_class_tipo.data_cancellazione is null  
      and r_bil_elem_class.data_cancellazione is null)   
select  COALESCE(abs(sum(movgest_ts_det_importo)),0) afde_bil_crediti_stralciati,
    	COALESCE(abs(sum(movgest_ts_det_importo)),0) afde_bil_crediti_stralciati_fcde
into afde_bil_crediti_stralciati, afde_bil_crediti_stralciati_fcde
from struttura
	left join capitoli 
    	on struttura.categoria_id=capitoli.categoria_id 
where struttura.titolo_code::integer between 1 and 5   ;


--Sommatoria di accertamenti pluriennali >2021 SOLO del titolo 5 + accertamenti
-- pluriennali RATEIZZATI del Titolo 1 e del Titolo 3 - 
--Nel perimetro dei capitoli pertinenti ed utilizzati per il calcolo del fondo

--NB: ad oggi non e' possibile distinguere gli accertamenti pluriennali Rateizzati
-- dagli accertaementi pluriennali normali perche' non ci sono flag/menu' che li 
--identifichino. Proporremo agli enti di utilizzare un classificatore che verra' 
--settato con la dicitura "Rateizzazione del credito" per cui vi arrivera' 
--dettagliata richiesta a strettissimo giro.


with struttura as (select *
 from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
capitoli as (      
    select class.classif_id categoria_id,       
       dt_movimento.movgest_ts_det_importo
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
        siac_t_class class,	
        siac_d_class_tipo d_class_tipo,
        siac_r_bil_elem_class r_bil_elem_class,
        siac_t_acc_fondi_dubbia_esig fcde
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
      and class.classif_id           = r_bil_elem_class.classif_id
	  and d_class_tipo.classif_tipo_id      = class.classif_tipo_id
      and r_bil_elem_class.elem_id   = capitolo.elem_id
      and fcde.elem_id						= capitolo.elem_id
	  and movimento.ente_proprietario_id   = p_ente_prop_id 
      and movimento.bil_id					=	bilancio_id 
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      	--accertamenti con anno > anno bilancio     
      and movimento.movgest_anno 	        > 	p_anno::integer 
      and tipo_mov.movgest_tipo_code    	= 'A' --accertamenti
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale        
      and d_class_tipo.classif_tipo_code	 = 'CATEGORIA'  
      and fcde.afde_bil_id				=  p_afde_bilancio_id    
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
      and class.data_cancellazione    is null  
      and d_class_tipo.data_cancellazione is null  
      and r_bil_elem_class.data_cancellazione is null
      and fcde.data_cancellazione is null)   
select	COALESCE(sum(movgest_ts_det_importo),0) afde_bil_accertamenti_anni_successivi,
    	COALESCE(sum(movgest_ts_det_importo),0) afde_bil_accertamenti_anni_successivi_fcde
	into afde_bil_accertamenti_anni_successivi, afde_bil_accertamenti_anni_successivi_fcde
from struttura
	left join capitoli 
    	on struttura.categoria_id=capitoli.categoria_id 
	--devono essere presi solo i pluriennali del titolo 5 e i pluriennali
    --rateizzati dei titoli 1 e 3.
    --Al momento non si sa come distinguere quelli rateizzati.        
where struttura.titolo_code::integer in (1,3,5) ;      


return next;


exception
when no_data_found THEN
    raise notice 'nessun dato trovato.';
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