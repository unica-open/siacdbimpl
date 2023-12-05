/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR141_calcola_spese_correnti_non_ricorrenti" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  importo_spese numeric
) AS
$body$
DECLARE

DEF_NULL	  constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

bilancio_id    integer;

BEGIN

/* 
	04/03/2022 Funzione nata per la SIAC-8412.

Nei report BILR141 (regione) e BILR142 (Enti Locali).
deve essere aggiunta una riga che e' un di cui delle Spese Correnti:
- "di cui spese correnti non ricorrenti finanziate con utilizzo del risultato di amministrazione". 

Il valore di questa riga e' un parametro nell'elenco dei parametri dei report,
ma se tale parametro non e' valorizzato (NULL) deve essere calcolato come:

-sommatoria del valore attuale degli impegni di competenza anno n
	del Titolo 1 (spese correnti)
	Non Ricorrenti
	con Tipo Vincolo: AAM.
    
Questa funzione restituisce solo il valore dell'importo calcolato. 
E' il report che controlla il valore del parametro e, se questo e' NULL,
valorizza il campo con il valore restituita da questa funzione.   

*/


select bil.bil_id
	into bilancio_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno=p_anno
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;  
    
raise notice 'bilancio_id = %', bilancio_id;

importo_spese := 0;
  


  return query 
  with struttura as (select * 
  		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
  capitoli as (
	select classific.programma_id,
    	classific.macroaggregato_id,
    	cap.elem_id
   	from   siac_t_bil_elem cap
   			LEFT JOIN (select r_capitolo_programma.elem_id, 
            		r_capitolo_programma.classif_id programma_id,
                	r_capitolo_macroaggr.classif_id macroaggregato_id
				from	siac_r_bil_elem_class r_capitolo_programma,
     					siac_r_bil_elem_class r_capitolo_macroaggr, 
                    	siac_d_class_tipo programma_tipo,
     					siac_t_class programma,
     					siac_d_class_tipo macroaggr_tipo,
     					siac_t_class macroaggr
				where   programma.classif_id=r_capitolo_programma.classif_id
    				AND programma.classif_tipo_id=programma_tipo.classif_tipo_id 
                    AND macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 
    				AND macroaggr.classif_id=r_capitolo_macroaggr.classif_id
                    AND r_capitolo_programma.elem_id=r_capitolo_macroaggr.elem_id
    				AND programma.ente_proprietario_id = p_ente_prop_id
                    AND programma_tipo.classif_tipo_code='PROGRAMMA'	
    				AND macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'	
					AND r_capitolo_programma.data_cancellazione IS NULL
    				AND r_capitolo_macroaggr.data_cancellazione IS NULL
    				AND programma_tipo.data_cancellazione IS NULL
                    AND programma.data_cancellazione IS NULL
                    AND macroaggr_tipo.data_cancellazione IS NULL
                    AND macroaggr.data_cancellazione IS NULL
    				AND now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now()) 
    				AND now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now()) 
    				AND	now() between programma.validita_inizio and coalesce (programma.validita_fine, now())
                    AND	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())) classific
            	ON classific.elem_id= cap.elem_id,                    
          siac_d_bil_elem_tipo tipo_elemento, 
          siac_d_bil_elem_stato stato_capitolo,
          siac_r_bil_elem_stato r_capitolo_stato,
          siac_d_bil_elem_categoria cat_del_capitolo,
          siac_r_bil_elem_categoria r_cat_capitolo
     where cap.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
      and	cap.elem_id						=	r_capitolo_stato.elem_id
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
      and	cap.elem_id						=	r_cat_capitolo.elem_id
      and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
      and cap.ente_proprietario_id 			=	p_ente_prop_id
      and cap.bil_id						= bilancio_id
      and tipo_elemento.elem_tipo_code 	= 	'CAP-UG'
      and	stato_capitolo.elem_stato_code	=	'VA'
      and cap.data_cancellazione 				is null
      and	r_capitolo_stato.data_cancellazione	is null
      and	tipo_elemento.data_cancellazione	is null
      and	stato_capitolo.data_cancellazione 	is null
      and	cat_del_capitolo.data_cancellazione	is null
      and	now() between cap.validita_inizio and coalesce (cap.validita_fine, now())
      and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
      and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
      and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
      and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
      and	now() between r_cat_capitolo.validita_inizio 
      and coalesce (r_cat_capitolo.validita_fine, now())),
  impegni as (
      select r_imp_bil_elem.elem_id, imp_ts.movgest_ts_id,
      	imp_ts_det.movgest_ts_det_importo
      from siac_t_movgest imp,
          siac_t_movgest_ts imp_ts,
          siac_t_movgest_ts_det imp_ts_det,
          siac_d_movgest_ts_det_tipo imp_ts_det_tipo,
          siac_d_movgest_tipo mov_tipo,
          siac_r_movgest_bil_elem r_imp_bil_elem
      where imp.movgest_tipo_id=mov_tipo.movgest_tipo_id
      and imp.movgest_id=imp_ts.movgest_id            
      and r_imp_bil_elem.movgest_id=imp.movgest_id
      and imp_ts_det.movgest_ts_id=imp_ts.movgest_ts_id
      and imp_ts_det.movgest_ts_det_tipo_id=imp_ts_det_tipo.movgest_ts_det_tipo_id
      and imp.ente_proprietario_id=p_ente_prop_id
      and imp.bil_id=bilancio_id
      and mov_tipo.movgest_tipo_code ='I' --Impegni
      and imp_ts_det_tipo.movgest_ts_det_tipo_code='A' --Importo Attuale.
      and imp.data_cancellazione IS NULL
      and imp_ts.data_cancellazione IS NULL
      and r_imp_bil_elem.data_cancellazione IS NULL),
	class_ricorrente as (
    	select r_mov_class.movgest_ts_id, class.classif_code
        from siac_t_class class,
            siac_d_class_tipo class_tipo,
            siac_r_movgest_class r_mov_class   
        where class.classif_tipo_id=class_tipo.classif_tipo_id
            and class.classif_id=r_mov_class.classif_id           
            and class.ente_proprietario_id= p_ente_prop_id
            and class_tipo.classif_tipo_code='RICORRENTE_SPESA'
            and class.data_cancellazione IS NULL
            and r_mov_class.data_cancellazione IS NULL ),
	imp_vincoli as (
    	select r_mov_ts.movgest_ts_b_id, av.avav_id
		from siac_t_avanzovincolo av,
            siac_d_avanzovincolo_tipo tipo,
            siac_r_movgest_ts r_mov_ts
        where av.avav_tipo_id=tipo.avav_tipo_id
        	and r_mov_ts.avav_id=av.avav_id
            and   tipo.ente_proprietario_id=p_ente_prop_id
            and   tipo.avav_tipo_code='AAM'
            and av.data_cancellazione is null
            --SIAC-8694 13/04/2022.
            --Non si deve testare che la data di fine validita' 
            --del vincolo sia NULL ma che sia compresa nell'anno
            --di bilancio in input.
            --and av.validita_fine IS NULL
			 and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
             	between av.validita_inizio 	
            		and COALESCE(av.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))             
            and r_mov_ts.data_cancellazione is null)                        
  select COALESCE(sum(impegni.movgest_ts_det_importo),0) importo_spese
  from struttura
  	join capitoli 
    	ON(struttura.programma_id = capitoli.programma_id
        	and struttura.macroag_id = capitoli.macroaggregato_id)  
    join impegni
    	on impegni.elem_id=capitoli.elem_id
    left join class_ricorrente
    	on class_ricorrente.movgest_ts_id=impegni.movgest_ts_id
	left join imp_vincoli
    	on imp_vincoli.movgest_ts_b_id=impegni.movgest_ts_id        
   where struttura.titusc_code='1'  --solo Titolo 1 - spese correnti
   		and COALESCE(class_ricorrente.classif_code,'')='4' --Impegno Non ricorrente 
        and imp_vincoli.avav_id IS NOT NULL; --Esiste un vincolo AAM 
       
  raise notice 'fine OK';
  raise notice 'ora: % ',clock_timestamp()::varchar;  
  
  EXCEPTION
  when no_data_found THEN
  raise notice 'Nessun dato trovato per le spese corrente non ricorrenti ';
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

ALTER FUNCTION siac."BILR141_calcola_spese_correnti_non_ricorrenti" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;