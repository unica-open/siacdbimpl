/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- Configurazione dei record per la gestione del parametro GESTIONE_NUM_ANNI_BIL_PREV_INDIC.
INSERT INTO siac_d_gestione_tipo (
   gestione_tipo_code,
  gestione_tipo_desc,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
 SELECT 'GESTIONE_NUM_ANNI_BIL_PREV_INDIC', 'Gestione del numero di anni relativi al bilancio di gestione per i report degli indicatori',
	now(), NULL, a.ente_proprietario_id, now(), now(), NULL, 'admin'
 FROM siac_t_ente_proprietario a
	where a.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_d_gestione_tipo z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.gestione_tipo_code='GESTIONE_NUM_ANNI_BIL_PREV_INDIC');
              
-- valore 3 per tutti gli enti tranne regione.          
INSERT INTO siac_d_gestione_livello (
  gestione_livello_code,
  gestione_livello_desc,
  gestione_tipo_id,
  validita_inizio ,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
SELECT 
 'CONF_NUM_ANNI_BIL_PREV_INDIC_2018', '3', a.gestione_tipo_id, now(), NULL, a.ente_proprietario_id, now(), now(), NULL, 'admin'
 FROM siac_d_gestione_tipo a
 WHERE a.gestione_tipo_code ='GESTIONE_NUM_ANNI_BIL_PREV_INDIC' 
    and a.ente_proprietario_id <> 2
	and a.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_d_gestione_livello z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.gestione_livello_code='CONF_NUM_ANNI_BIL_PREV_INDIC_2018');
      
-- valore 2 per regione. 
INSERT INTO siac_d_gestione_livello (
  gestione_livello_code,
  gestione_livello_desc,
  gestione_tipo_id,
  validita_inizio ,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
SELECT 
 'CONF_NUM_ANNI_BIL_PREV_INDIC_2018', '2', a.gestione_tipo_id, now(), NULL, a.ente_proprietario_id, now(), now(), NULL, 'admin'
 FROM siac_d_gestione_tipo a
 WHERE a.gestione_tipo_code ='GESTIONE_NUM_ANNI_BIL_PREV_INDIC' 
    and a.ente_proprietario_id = 2
	and a.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_d_gestione_livello z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.gestione_livello_code='CONF_NUM_ANNI_BIL_PREV_INDIC_2018');  
	  
      
INSERT INTO siac_r_gestione_ente (
 gestione_livello_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
 SELECT 
	gestione_livello_id, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin'
from siac_d_gestione_livello a
	where a.gestione_livello_code ='CONF_NUM_ANNI_BIL_PREV_INDIC_2018'
		and a.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_r_gestione_ente z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.gestione_livello_id=a.gestione_livello_id);
	  
	  
CREATE OR REPLACE FUNCTION siac."BILR174_indic_sint_spe_bp_FPV" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  campo_report varchar,
  anno varchar,
  missione_code varchar,
  importo_fpv numeric
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

anno1 integer;
anno2 integer;
anno3 integer;

BEGIN

/*
	Funzione che estrae i valori FPV dal cronoprogramma come estratto nel report 
    BILR011.
    Gli importi sono restituiti per anno, missione e per codice del campo del report 
    BILR011, cioe':
    	- CAMPO_B = Spese impegnate negli esercizi precedenti con copertura costituita        
		  dal fondo pluriennale vincolato e imputate all'esercizio 'anno bilancio'.          
        - CAMPO_D = Spese che si prevede di impegnare nell'esercizio 'anno bilancio', 
        	con copertura costituita dal fondo pluriennale vincolato con imputazione 
            all'esercizio esercizi 'anno bilancio'+1.
        - CAMPO_E = Spese che si prevede di impegnare nell'esercizio 'anno bilancio', 
        	con copertura costituita dal fondo pluriennale vincolato con imputazione 
            all'esercizio esercizi 'anno bilancio'+2.
        - CAMPO_F = Spese che si prevede di impegnare nell'esercizio 'anno bilancio', 
        	con copertura costituita dal fondo pluriennale vincolato con imputazione 
            all'esercizio esercizi > 'anno bilancio'+1.
    
    La funzione e' utilizzata dai report:
    	- BILR174 - Indicatori sintetici per Organismi ed enti strumentali delle Regioni e delle Province aut.
        - BILR177 - Indicatori sintetici per Regioni
    	- BILR180 - Indicatori sintetici per Enti Locali.

*/

anno1 :=p_anno::integer;
anno2 :=(p_anno::integer)+1;
anno3 :=(p_anno::integer)+2;


return query
select 'CAMPO_B'::varchar campo_report, f.anno::varchar anno, 
	left(cl2.classif_code,2)::varchar missione_code,
    COALESCE(sum(e.cronop_elem_det_importo),0)::numeric importo			
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d,          	
          siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where  pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.periodo_id = f.periodo_id
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and pr.ente_proprietario_id=p_ente_prop_id 
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = true          
          and ((e.anno_entrata::integer < anno1 -- anno prospetto            
          		and f.anno= anno1::varchar) OR -- anno prospetto
          	    (e.anno_entrata::integer < anno2 -- anno prospetto            
          		and f.anno= anno2::varchar) OR
                (e.anno_entrata::integer < anno3 -- anno prospetto            
          		and f.anno= anno3::varchar  ))
          and clt2.classif_tipo_code='PROGRAMMA'        
          and stct.cronop_stato_code='VA'          
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null
          group by f.anno, left(cl2.classif_code,2)
UNION
select 'CAMPO_D'::varchar  campo_report,e.anno_entrata::varchar anno,  
	left(cl2.classif_code,2)::varchar missione_code,
COALESCE(sum(e.cronop_elem_det_importo),0)::numeric importo 	
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and stc.cronop_id=a.cronop_id
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id    
          and e.periodo_id = f.periodo_id      
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and  pr.ente_proprietario_id= p_ente_prop_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = true
          and ((e.anno_entrata = anno1::varchar -- anno prospetto           
          		and f.anno::integer=anno1+1) OR -- anno prospetto + 1 
              (e.anno_entrata = anno2::varchar -- anno prospetto           
          		and f.anno::integer=anno2+1) OR -- anno prospetto + 1 
              (e.anno_entrata = anno3::varchar -- anno prospetto           
          		and f.anno::integer=anno3+1)) -- anno prospetto + 1                                       
          and clt2.classif_tipo_code='PROGRAMMA'
          and stct.cronop_stato_code='VA'          
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null
          group by e.anno_entrata,  left(cl2.classif_code,2)          
UNION 
 select 'CAMPO_E'::varchar campo_report, e.anno_entrata::varchar anno,  
 	left(cl2.classif_code,2)::varchar missione_code,
 	COALESCE(sum(e.cronop_elem_det_importo),0)::numeric importo 	
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and stc.cronop_id=a.cronop_id
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id    
          and e.periodo_id = f.periodo_id      
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and  pr.ente_proprietario_id= p_ente_prop_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = true
          and ((e.anno_entrata = anno1::varchar -- anno prospetto           
          		and f.anno::integer=anno1+2) OR -- anno prospetto + 2 
              (e.anno_entrata = anno2::varchar -- anno prospetto           
          		and f.anno::integer=anno2+2) OR -- anno prospetto + 2 
              (e.anno_entrata = anno3::varchar -- anno prospetto           
          		and f.anno::integer=anno3+2)) -- anno prospetto + 2                                       
          and clt2.classif_tipo_code='PROGRAMMA'
          and stct.cronop_stato_code='VA'          
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null
          group by e.anno_entrata,  left(cl2.classif_code,2)
UNION   
 select 'CAMPO_F'::varchar campo_report,e.anno_entrata::varchar anno,  
 	left(cl2.classif_code,2)::varchar missione_code,
 	COALESCE(sum(e.cronop_elem_det_importo),0)::numeric importo
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and stc.cronop_id=a.cronop_id
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id    
          and e.periodo_id = f.periodo_id      
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and  pr.ente_proprietario_id= p_ente_prop_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = true
          and ((e.anno_entrata = anno1::varchar -- anno prospetto           
          		and f.anno::integer=anno1+3) OR -- anno prospetto + 3 
              (e.anno_entrata = anno2::varchar -- anno prospetto           
          		and f.anno::integer=anno2+3) OR -- anno prospetto + 3 
              (e.anno_entrata = anno3::varchar -- anno prospetto           
          		and f.anno::integer=anno3+3)) -- anno prospetto + 3                                       
          and clt2.classif_tipo_code='PROGRAMMA'
          and stct.cronop_stato_code='VA'          
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null
          group by e.anno_entrata,  left(cl2.classif_code,2)    ;      


raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
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
COST 100 ROWS 1000;