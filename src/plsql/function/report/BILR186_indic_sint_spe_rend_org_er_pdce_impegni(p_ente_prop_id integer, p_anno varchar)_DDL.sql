/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR186_indic_sint_spe_rend_org_er_pdce_impegni" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  id_impegno integer,
  num_impegno numeric,
  anno_impegno integer,
  imp_impegnato_i numeric,
  pdce_code varchar,
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
	Funzione che estrae i dati di impegno del rendiconto di spesa 
    dell'anno di bilancio in input, con il relativo PDCE.
        
    I dati restituiti sono:  		
    	- id impegno ;
        - numero impegno;
        - anno impegno;  		
        - importo IMPEGNI (I);
        - pdce.
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
with i_impegni as (
    select t_movgest.movgest_id, t_movgest.movgest_numero,
    	t_movgest.movgest_anno, t_movgest_ts.movgest_ts_id,
        t_movgest_ts_det.movgest_ts_det_importo importo_impegno        
     from siac_t_movgest t_movgest,
          siac_d_movgest_tipo d_movgest_tipo,
          siac_t_movgest_ts t_movgest_ts,
          siac_d_movgest_ts_tipo d_movgest_ts_tipo,
          siac_r_movgest_ts_stato r_movgest_ts_stato,
          siac_d_movgest_stato d_movgest_stato,
          siac_t_movgest_ts_det t_movgest_ts_det,
          siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
    where d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
    and t_movgest_ts.movgest_id=t_movgest.movgest_id
    and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
    and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and d_movgest_stato.movgest_stato_id=r_movgest_ts_stato.movgest_stato_id
    and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
    and t_movgest_ts_det.movgest_ts_det_tipo_id=d_movgest_ts_det_tipo.movgest_ts_det_tipo_id    
    and t_movgest.ente_proprietario_id =p_ente_prop_id
    and d_movgest_tipo.movgest_tipo_code='I'
    and d_movgest_ts_tipo.movgest_ts_tipo_code='T'
    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'    
    -- D = DEFINITIVO
    -- N = DEFINITIVO NON LIQUIDABILE
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
    and t_movgest_ts_det.data_cancellazione is null
    and d_movgest_ts_det_tipo.data_cancellazione is null),
conto_pdce_imp as(
        select t_class_upb.classif_code, r_movgest_class.movgest_ts_id
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_movgest_class r_movgest_class
        	where 		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 
                and t_class_upb.classif_id=r_movgest_class.classif_id
                and t_class_upb.ente_proprietario_id=p_ente_prop_id
                and class_upb.classif_tipo_code like 'PDC_%'
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_movgest_class.data_cancellazione 			is null)                   
SELECT  i_impegni.movgest_id::integer id_impegno,
		i_impegni.movgest_numero::numeric num_impegno,
        i_impegni.movgest_anno::integer anno_impegno,		
        COALESCE(i_impegni.importo_impegno,0)::numeric imp_impegnato_i,
        conto_pdce_imp.classif_code::varchar pdce_code,
        ''::varchar display_error
FROM i_impegni	
    LEFT JOIN conto_pdce_imp on conto_pdce_imp.movgest_ts_id = i_impegni.movgest_ts_id            
ORDER BY anno_impegno, num_impegno;
                    
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