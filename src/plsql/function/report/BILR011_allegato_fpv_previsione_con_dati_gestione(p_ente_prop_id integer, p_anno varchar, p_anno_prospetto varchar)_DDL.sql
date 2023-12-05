/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR011_allegato_fpv_previsione_con_dati_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  importi_capitoli numeric,
  spese_impegnate numeric,
  spese_impegnate_anno1 numeric,
  spese_impegnate_anno2 numeric,
  spese_impegnate_anno_succ numeric,
  importo_avanzo numeric,
  importo_avanzo_anno1 numeric,
  importo_avanzo_anno2 numeric,
  importo_avanzo_anno_succ numeric,
  elem_id integer,
  anno_esercizio varchar,
  spese_impegnate_da_prev numeric
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id integer;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;
annoprospetto_int integer;
annoprospetto_prec_int integer;

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della BILR171_allegato_fpv_previsione_con_dati_gestione che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR011.
		Poiche' il report BILR171 viene eliminato la funzione 
        BILR171_allegato_fpv_previsione_con_dati_gestione e' superflua ma NON viene
        cancellata perche' serve per gli anni precedenti il 2018.
*/

/*Se la fase di bilancio e' Previsione allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno-1 per tutte le colonne. 

Se la fase di bilancio e' Esercizio Provvisorio allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno per tutte le colonne tranne quella relativa agli importi dei capitolo (colonna a).
In questo caso l''anno di esercizio e il bilancio id saranno quelli di p_anno-1.

L'anno relativo agli importi dei capitoli e' anno_esercizio_prec
L'anno relativo agli importi degli impegni e' annoImpImpegni_int*/


-- SIAC-6063
/*Aggiunto parametro p_anno_prospetto
Variabile annoImpImpegni_int sostituita da annoprospetto_int
Azzerati importi  spese_impegnate_anno1
                  spese_impegnate_anno2
                  spese_impegnate_anno_succ
                  importo_avanzo_anno1
                  importo_avanzo_anno2
                  importo_avanzo_anno_succ*/

RTN_MESSAGGIO := 'select 1'; 

bilancio_id := null;
bilancio_id_prec := null;

select bil.bil_id, fase_operativa.fase_operativa_code
into   bilancio_id, cod_fase_operativa
from  siac_d_fase_operativa fase_operativa, 
      siac_r_bil_fase_operativa bil_fase_operativa, 
      siac_t_bil bil, 
      siac_t_periodo periodo
where fase_operativa.fase_operativa_id = bil_fase_operativa.fase_operativa_id
and   bil_fase_operativa.bil_id = bil.bil_id
and   periodo.periodo_id = bil.periodo_id
and   fase_operativa.fase_operativa_code in ('P','E','G') -- SIAC-5778 Aggiunto G
and   bil.ente_proprietario_id = p_ente_prop_id
and   periodo.anno = p_anno
and   fase_operativa.data_cancellazione is null
and   bil_fase_operativa.data_cancellazione is null 
and   bil.data_cancellazione is null 
and   periodo.data_cancellazione is null;
 
/*if cod_fase_operativa = 'P' then
  
  anno_esercizio := ((p_anno::integer)-1)::varchar;   

  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer-1;
  
elsif cod_fase_operativa in ('E','G') then

  anno_esercizio := p_anno;
  annoprospetto_int := p_anno_prospetto::integer;
   
end if;*/
 
  anno_esercizio := ((p_anno::integer)-1)::varchar;   


  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer;
  
  annoprospetto_prec_int := ((p_anno_prospetto::integer)-1);

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

-- annoImpImpegni_int := anno_esercizio::integer; 
-- annoImpImpegni_int := p_anno::integer; -- SIAC-6063
raise notice 'anno_esercizio = % - anno_esercizio_prec = %', anno_esercizio, anno_esercizio_prec;
raise notice 'bilancio_id = % - bilancio_id_prec = %', bilancio_id, bilancio_id_prec;
raise notice 'annoprospetto_int = %', annoprospetto_int;
raise notice 'annoprospetto_prec_int = %', annoprospetto_prec_int;

return query
select 
zz.*
from (
select 
tab1.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null) -- Potrebbe essere anche anno_esercizio_prec
),
capitoli_anno_prec as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 			
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id_prec													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
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
and	r_cat_capitolo.data_cancellazione           is null
),
capitoli_importo as ( -- Fondo pluriennale vincolato al 31 dicembre dell''esercizio N-1
select 		capitolo_importi.elem_id,
           	sum(capitolo_importi.elem_det_importo) importi_capitoli
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
where capitolo_importi.ente_proprietario_id = p_ente_prop_id  								 
and	capitolo.elem_id = capitolo_importi.elem_id 
and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
and	capitolo.elem_id = r_capitolo_stato.elem_id			
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
and	capitolo.bil_id = bilancio_id_prec							
and	tipo_elemento.elem_tipo_code = 'CAP-UG'
and	capitolo_imp_periodo.anno = annoprospetto_prec_int::varchar		  
--and	capitolo_imp_periodo.anno = anno_esercizio_prec	
and	stato_capitolo.elem_stato_code = 'VA'								
and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
and capitolo_imp_tipo.elem_det_tipo_code = 'STA'				
and	capitolo_importi.data_cancellazione 		is null
and	capitolo_imp_tipo.data_cancellazione 		is null
and	capitolo_imp_periodo.data_cancellazione 	is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
COALESCE(capitoli_importo.importi_capitoli,0)::numeric,
0::numeric spese_impegnate,
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
0::numeric importo_avanzo,
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli_anno_prec.elem_id::integer,
anno_esercizio::varchar,
0::numeric spese_impegnate_da_prev
from struttura
left join capitoli_anno_prec on struttura.programma_id = capitoli_anno_prec.programma_id
                   and struttura.macroag_id = capitoli_anno_prec.macroaggregato_id
left join capitoli_importo on capitoli_anno_prec.elem_id = capitoli_importo.elem_id
) tab1
union all
select 
tab2.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null)
),
capitoli as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
-- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
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
and	r_cat_capitolo.data_cancellazione           is null
),
dati_impegni as (
with importo_impegni as (
with   impegni as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_impegno
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.movgest_anno  >= annoprospetto_int
-- and    movimento.movgest_anno  >= annoImpImpegni_int
and    movimento.bil_id = bilancio_id
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno
),
imp_impegni_accertamenti as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_accertamento,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo       
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_a_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    ts_impegni_legati.avav_id is null
and    movimento.bil_id = bilancio_id
and    movimento.movgest_anno <= annoprospetto_int+2
-- and    movimento.movgest_anno <= annoImpImpegni_int+2
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
imp_impegni_avanzo as (
select ts_impegni_legati.movgest_ts_b_id,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo,
       movimento.movgest_anno        
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_avanzovincolo avanzovincolo on ts_impegni_legati.avav_id = avanzovincolo.avav_id
inner  join siac_d_avanzovincolo_tipo tipo_avanzovincolo on avanzovincolo.avav_tipo_id = tipo_avanzovincolo.avav_tipo_id
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.bil_id = bilancio_id
and    ts_impegni_legati.movgest_ts_a_id is null
and    tipo_avanzovincolo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
and    movimento.movgest_anno >= annoprospetto_int
-- and    movimento.movgest_anno >= annoImpImpegni_int
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    avanzovincolo.data_cancellazione is null 
and    tipo_avanzovincolo.data_cancellazione is null
and    ts_movimento.data_cancellazione is null 
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
impegni_verif_previsione as(
    select distinct accert.*, imp.*, ts_impegni_legati.movgest_ts_b_id
    from siac_r_movgest_ts ts_impegni_legati    	
         join (	--accertamenti
         		select ts_mov_acc.movgest_ts_id,
                        mov_acc.movgest_anno anno_acc, 
                        mov_acc.movgest_numero numero_acc,
                        ts_mov_det_acc.movgest_ts_det_importo importo_acc
                    from siac_t_movgest mov_acc,
                         siac_t_movgest_ts ts_mov_acc,					
                         siac_t_movgest_ts_det ts_mov_det_acc,
                         siac_r_movgest_ts_stato r_stato_acc,
                         siac_d_movgest_stato stato_acc
                    where mov_acc.movgest_id=ts_mov_acc.movgest_id
                        and ts_mov_acc.movgest_ts_id=ts_mov_det_acc.movgest_ts_id
                        and ts_mov_acc.movgest_ts_id=r_stato_acc.movgest_ts_id
                        and r_stato_acc.movgest_stato_id=stato_acc.movgest_stato_id
                        and mov_acc.ente_proprietario_id= p_ente_prop_id
                        and mov_acc.movgest_anno = annoprospetto_prec_int--annoprospetto_int --accertamenti sempre dell'anno prospetto
                        --and mov_acc.movgest_anno = annoprospetto_int --accertamenti sempre dell'anno prospetto
                        and stato_acc.movgest_stato_code in ('D','N')
                        and r_stato_acc.data_cancellazione IS NULL
                        and mov_acc.data_cancellazione IS NULL
                        and ts_mov_acc.data_cancellazione IS NULL) accert
            on accert.movgest_ts_id =  ts_impegni_legati.movgest_ts_a_id
          join (--impegni
          		select ts_mov_imp.movgest_ts_id,
                        mov_imp.movgest_anno anno_imp, 
                        mov_imp.movgest_numero numero_imp,
                        r_imp_bil_elem.elem_id,
                        ts_mov_det_imp.movgest_ts_det_importo importo_imp
                    from siac_t_movgest mov_imp,
                         siac_t_movgest_ts ts_mov_imp,					
                         siac_t_movgest_ts_det ts_mov_det_imp,
                         siac_r_movgest_ts_stato r_stato_imp,
                         siac_d_movgest_stato stato_imp,
                         siac_r_movgest_bil_elem r_imp_bil_elem
                    where mov_imp.movgest_id=ts_mov_imp.movgest_id
                        and ts_mov_imp.movgest_ts_id=ts_mov_det_imp.movgest_ts_id
                        and ts_mov_imp.movgest_ts_id=r_stato_imp.movgest_ts_id
                        and r_stato_imp.movgest_stato_id=stato_imp.movgest_stato_id
                        and r_imp_bil_elem.movgest_id=mov_imp.movgest_id
                        and mov_imp.ente_proprietario_id= p_ente_prop_id
                        and mov_imp.bil_id = bilancio_id  --anno precedente di gestione
                        and mov_imp.movgest_anno >= annoprospetto_prec_int+1-- annoprospetto_int + 1 --impegni a partire dell'anno prospetto + 1
                        --and mov_imp.movgest_anno >=  annoprospetto_int + 1 --impegni a partire dell'anno prospetto + 1
                        and stato_imp.movgest_stato_code in ('D','N')
                        and r_stato_imp.data_cancellazione IS NULL
                        and mov_imp.data_cancellazione IS NULL
                        and ts_mov_imp.data_cancellazione IS NULL
                        and r_imp_bil_elem.data_cancellazione IS NULL) imp              
            on imp.movgest_ts_id =  ts_impegni_legati.movgest_ts_b_id
          left join (--legame con i progetti 
          		select r_mov_progr.movgest_ts_id, progetto.programma_id
                  from siac_t_programma progetto, siac_t_cronop crono, 
                      siac_t_bil bil, siac_t_periodo anno_bil,
                      siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
                      siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato,
                     siac_r_movgest_ts_programma r_mov_progr             
                  where progetto.programma_id=crono.programma_id
                      and crono.bil_id = bil.bil_id
                      and bil.periodo_id=anno_bil.periodo_id
                      and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
                      and r_cronop_stato.cronop_id=crono.cronop_id
                      and r_progetto_stato.programma_id=progetto.programma_id
                      and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id     
                      and r_mov_progr.programma_id=progetto.programma_id                      
                      and progetto.ente_proprietario_id= p_ente_prop_id
                      and anno_bil.anno=p_anno -- anno bilancio
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null) progetti
             on ts_impegni_legati.movgest_ts_b_id = progetti.movgest_ts_id
    where ts_impegni_legati.ente_proprietario_id=p_ente_prop_id     
        and ts_impegni_legati.avav_id is null
        and ts_impegni_legati.data_cancellazione is null  
        	--progetti.programma_id IS NULL cioe' non sono compresi negli impegni legati ai progetti estratti
            --nelle query precedenti. In pratica non devo contarli 2 volte.
        and progetti.programma_id IS NULL ),
/* SIAC-8866 04/07/2023.
    	Devo verificare che l'impegno non sia legato ad un progetto per non contarlo 2 volte.
*/     
elenco_progetti_imp as (select r_mov_progr.movgest_ts_id, progetto.programma_id, progetto.programma_code
                  from siac_t_programma progetto, siac_t_cronop crono, 
                      siac_t_bil bil, siac_t_periodo anno_bil,
                      siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
                      siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato,
                     siac_r_movgest_ts_programma r_mov_progr             
                  where progetto.programma_id=crono.programma_id
                      and crono.bil_id = bil.bil_id
                      and bil.periodo_id=anno_bil.periodo_id
                      and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
                      and r_cronop_stato.cronop_id=crono.cronop_id
                      and r_progetto_stato.programma_id=progetto.programma_id
                      and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id     
                      and r_mov_progr.programma_id=progetto.programma_id                      
                      and progetto.ente_proprietario_id= p_ente_prop_id
                      and anno_bil.anno=anno_esercizio_prec -- anno bilancio precedente
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null)         
select impegni.movgest_ts_b_id, COALESCE(elenco_progetti_imp.programma_code,'') progetto,
       case 
        when impegni.anno_impegno = annoprospetto_int and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,  
       case 
        when impegni.anno_impegno = annoprospetto_int+1 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno1,   
       case 
        when impegni.anno_impegno = annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno2,    
       case 
        when impegni.anno_impegno > annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+2 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno_succ,
       case 
        when impegni.anno_impegno = annoprospetto_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo,    
       case 
        when impegni.anno_impegno = annoprospetto_int+1 then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo_anno1,      
       case 
        when impegni.anno_impegno = annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno2,
       case 
        when impegni.anno_impegno > annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno_succ,
       case 
       	when impegni.anno_impegno = annoprospetto_int then --and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
       		sum(impegni_verif_previsione.importo_imp) 
        end spese_impegnate_da_prev                            
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
left   join impegni_verif_previsione on impegni.movgest_ts_b_id = impegni_verif_previsione.movgest_ts_b_id and
		annoprospetto_int > p_anno::integer 
left join elenco_progetti_imp on elenco_progetti_imp.movgest_ts_id = impegni.movgest_ts_b_id        
--left   join impegni_verif_previsione on 1000 = impegni_verif_previsione.movgest_ts_b_id
-- SIAC-8866 04/07/2023: solo se l'impegno non è collegato al progetto.
where  ((COALESCE(elenco_progetti_imp.programma_code,'') = '' ) OR
		(COALESCE(elenco_progetti_imp.programma_code,'') <> '' AND impegni_verif_previsione.movgest_ts_b_id IS NULL))
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento ,
	COALESCE(elenco_progetti_imp.programma_code,'')
),
capitoli_impegni as (
select capitolo.elem_id, ts_movimento.movgest_ts_id
from  siac_t_bil_elem                 capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where capitolo.ente_proprietario_id = p_ente_prop_id
and   capitolo.bil_id =	bilancio_id
and   movimento.bil_id = bilancio_id
and   t_capitolo.elem_tipo_code = 'CAP-UG'
and   movimento.movgest_anno >= annoprospetto_int
-- and   movimento.movgest_anno >= annoImpImpegni_int
and   stato.movgest_stato_code in ('D','N')-- SIAC-5778
and   capitolo.data_cancellazione is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione is null
and   movimento.data_cancellazione is null 
and   ts_movimento.data_cancellazione is null
and   ts_stato.data_cancellazione is null-- SIAC-5778
and   stato.data_cancellazione is null-- SIAC-5778 
)
select 
capitoli_impegni.elem_id,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.spese_impegnate_anno1) spese_impegnate_anno1,
sum(importo_impegni.spese_impegnate_anno2) spese_impegnate_anno2,
sum(importo_impegni.spese_impegnate_anno_succ) spese_impegnate_anno_succ,
sum(importo_impegni.importo_avanzo) importo_avanzo,
sum(importo_impegni.importo_avanzo_anno1) importo_avanzo_anno1,
sum(importo_impegni.importo_avanzo_anno2) importo_avanzo_anno2,
sum(importo_impegni.importo_avanzo_anno_succ) importo_avanzo_anno_succ,
sum(importo_impegni.spese_impegnate_da_prev) spese_impegnate_da_prev
from capitoli_impegni
	left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
group by capitoli_impegni.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
0::numeric importi_capitoli,
COALESCE(dati_impegni.spese_impegnate,0)::numeric spese_impegnate,
/*COALESCE(dati_impegni.spese_impegnate_anno1,0)::numeric spese_impegnate_anno1,
COALESCE(dati_impegni.spese_impegnate_anno2,0)::numeric spese_impegnate_anno2,
COALESCE(dati_impegni.spese_impegnate_anno_succ,0)::numeric spese_impegnate_anno_succ,*/
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
COALESCE(dati_impegni.importo_avanzo,0)::numeric importo_avanzo,
/*COALESCE(dati_impegni.importo_avanzo_anno1,0)::numeric importo_avanzo_anno1,
COALESCE(dati_impegni.importo_avanzo_anno2,0)::numeric importo_avanzo_anno2,
COALESCE(dati_impegni.importo_avanzo_anno_succ,0)::numeric importo_avanzo_anno_succ,*/
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli.elem_id::integer,
anno_esercizio::varchar,
coalesce(dati_impegni.spese_impegnate_da_prev,0) spese_impegnate_da_prev
from struttura
left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
) tab2
) as zz;

-- raise notice 'Dati % - %',anno_esercizio::varchar,anno_esercizio_prec::varchar;
-- raise notice 'Dati % - %',bilancio_id::varchar,bilancio_id_prec::varchar;

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

ALTER FUNCTION siac."BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;