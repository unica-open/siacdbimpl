/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR166_rend_gest_costi_missione_all_h" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  pdce_finanz_code varchar,
  pdce_finanz_descr varchar,
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  importo_impegno numeric,
  code_missione varchar,
  desc_missione varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_competenza_int integer;
 
sqlQuery varchar;
idBilancio integer;

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
pdce_finanz_code:='';
pdce_finanz_descr:='';
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
importo_impegno:=0;
code_missione:='';
desc_missione:='';
anno_competenza_int=p_anno ::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
-- leggo l'ID del bilancio x velocizzare.
 select a.bil_id
 into idBilancio
 from siac_t_bil a, siac_t_periodo b
 where a.periodo_id=b.periodo_id
 and a.ente_proprietario_id =p_ente_prop_id
 and b.anno = p_anno
 and a.data_cancellazione IS NULL
 and b.data_cancellazione IS NULL;
 
-- 15/05/2018: nella query seguente tolti i riferimenti alle tabelle siac_t_bil e
--  siac_t_periodo sostituite direttamente dall'Id del bilancio letto in
--  precedenza x velocizzare l'esecuzione.
return query 
select query_totale.* from  (
with impegni as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                 CASE WHEN d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'                 
                    THEN 'IMP'
                    ELSE 'SUB' end tipo_impegno,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,                            
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id      
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	                          
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_movgest.bil_id = idBilancio
                AND t_movgest.movgest_anno =anno_competenza_int
                AND d_movgest_tipo.movgest_tipo_code='I'    --impegno  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                	-- Impegni DEFINITIVI o DEFINITIVI NON LIQUIDABILI
                AND d_movgest_stato.movgest_stato_code  in ('D','N') 
                AND d_movgest_ts_tipo.movgest_ts_tipo_code = 'T' --solo impegni non sub-impegni
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND  d_movgest_tipo.data_cancellazione IS NULL                            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL),
capitoli as(
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        p_anno anno_bilancio,
        r_movgest_bil_elem.movgest_id,
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
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_r_movgest_bil_elem r_movgest_bil_elem 
where 	
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 		
    and	programma.classif_id=r_capitolo_programma.classif_id			    
    and	macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 		
    and	macroaggr.classif_id=r_capitolo_macroaggr.classif_id			    
   	and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					
    and	capitolo.elem_id=r_capitolo_programma.elem_id					
    and	capitolo.elem_id=r_capitolo_macroaggr.elem_id						
    and	capitolo.elem_id				=	r_capitolo_stato.elem_id	
	and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
    and	capitolo.elem_id				=	r_cat_capitolo.elem_id		
	and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	    	
    and	r_movgest_bil_elem.elem_id = capitolo.elem_id	
    and	capitolo.ente_proprietario_id=p_ente_prop_id 					
    and	capitolo.bil_id = idBilancio										 
    and	programma_tipo.classif_tipo_code='PROGRAMMA'							
    and	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
    and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     	
    and	stato_capitolo.elem_stato_code	=	'VA'						     							
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
    and	r_cat_capitolo.data_cancellazione 			is null
    and r_movgest_bil_elem.data_cancellazione		is null),
elenco_pdce_finanz as (        
	SELECT  r_movgest_class.movgest_ts_id,
           COALESCE( t_class.classif_code,'') pdce_code, 
            COALESCE(t_class.classif_desc,'') pdce_desc 
        from siac_r_movgest_class r_movgest_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where t_class.classif_id 					= 	r_movgest_class.classif_id
                 and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and d_class_tipo.classif_tipo_code like 'PDC_%'			
                   and r_movgest_class.ente_proprietario_id=p_ente_prop_id
                   AND r_movgest_class.validita_fine is NULL
                   AND r_movgest_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL    )  ,    
     strut_bilancio as(
     		select *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,''))                                  
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
	COALESCE(elenco_pdce_finanz.pdce_code,'')::varchar pdce_finanz_code,
    COALESCE(elenco_pdce_finanz.pdce_desc,'')::varchar pdce_finanz_descr,
    impegni.movgest_numero::numeric num_impegno,
    impegni.movgest_anno::integer anno_impegno,
    impegni.movgest_ts_code::varchar num_subimpegno,
	COALESCE(impegni.movgest_ts_det_importo,0)::numeric importo_impegno,
    COALESCE(strut_bilancio.missione_code,'') code_missione,
    COALESCE(strut_bilancio.missione_desc,'') desc_missione
/*FROM strut_bilancio 
	LEFT JOIN capitoli on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
    LEFT JOIN impegni on impegni.movgest_id = capitoli.movgest_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.movgest_ts_id = impegni.movgest_ts_id 
   */
   FROM impegni 
	LEFT JOIN capitoli on capitoli.movgest_id = impegni.movgest_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.movgest_ts_id = impegni.movgest_ts_id 
    FULL JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
ORDER BY code_missione,anno_impegno, num_impegno, num_subimpegno) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun accertamento trovato' ;
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