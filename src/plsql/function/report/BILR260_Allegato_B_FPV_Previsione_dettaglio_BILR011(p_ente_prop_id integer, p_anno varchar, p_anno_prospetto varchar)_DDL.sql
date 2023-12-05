/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  anno_prospetto varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  elem_id integer,
  numero_capitolo varchar,
  anno_impegno integer,
  numero_impegno numeric,
  spese_impegnate numeric,
  importo_avanzo numeric,
  importo_colonna_d_anno_prec numeric,
  spese_impegnate_da_prev numeric,
  progetto varchar,
  cronoprogramma varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;
annoprospetto_int integer;
annoprospetto_prec_int integer;

BEGIN

/*
	26/04/2022: SIAC-8634.
    	Funzione che estrae i dati di dettaglio relativi al report BILR011
        per la sola colonna B utilizzata dal report BILR260.
*/
/* Aggiornamenti per SIAC-8866 30/06/2023.

*/

--I dati letti in questa procedura riguardano la gestione dell'anno precedente di quello del bilancio in input.
bilancio_id_prec := null;
 
anno_esercizio := ((p_anno::integer)-1)::varchar;   

annoprospetto_int := p_anno_prospetto::integer;
  
annoprospetto_prec_int := ((p_anno_prospetto::integer)-1);

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

--leggo l'id del bilancio precedente.
select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

raise notice 'bilancio_id_prec = %', bilancio_id_prec;
raise notice 'anno_esercizio = % - anno_esercizio_prec = % - annoprospetto_int = %- annoprospetto_prec_int = %', 
anno_esercizio, anno_esercizio_prec, annoprospetto_int, annoprospetto_prec_int;


return query
with tutto as (
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
and capitolo.bil_id = bilancio_id_prec													
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
and    movimento.bil_id = bilancio_id_prec
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
and    movimento.bil_id = bilancio_id_prec
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
and    movimento.bil_id = bilancio_id_prec
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
dettaglio_impegni as(
select impegno.movgest_anno anno_impegno,
	impegno.movgest_numero numero_impegno, impegno_ts.movgest_ts_id
from siac_t_movgest impegno,
	siac_t_movgest_ts impegno_ts,
    siac_d_movgest_tipo movgest_tipo
where impegno.movgest_id=impegno_ts.movgest_id
	and impegno.movgest_tipo_id=movgest_tipo.movgest_tipo_id
	and impegno.ente_proprietario_id= p_ente_prop_id
    and impegno.bil_id=bilancio_id_prec
    and movgest_tipo.movgest_tipo_code='I'
    and impegno.data_cancellazione IS NULL
    and impegno_ts.data_cancellazione IS NULL)    
select impegni.movgest_ts_b_id,
	   dettaglio_impegni.anno_impegno,
       dettaglio_impegni.numero_impegno,
       case 
        when impegni.anno_impegno = annoprospetto_int and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,         
       case 
        when impegni.anno_impegno = annoprospetto_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo                           
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
left   join dettaglio_impegni on dettaglio_impegni.movgest_ts_id = impegni.movgest_ts_b_id
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento,
	dettaglio_impegni.anno_impegno, dettaglio_impegni.numero_impegno
), --importo_impegni
    capitoli_impegni as (
    select capitolo.elem_id, ts_movimento.movgest_ts_id,
    	capitolo.elem_code numero_capitolo
    from  siac_t_bil_elem                 capitolo
    inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
    inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
    inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
    inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
    inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
    inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
    where capitolo.ente_proprietario_id = p_ente_prop_id
    and   capitolo.bil_id =	bilancio_id_prec
    and   movimento.bil_id = bilancio_id_prec
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
    ),
    /* SIAC-8866 26/06/2023.
    	Estraggo i dati degli impegni per verificare se un certo impegno era gia' stato utilizzato.
        Nel report il dato spese_impegnate_da_prev viene sottratto all'importo importo_colonna_d_anno_prec.
    */
    impegni_verif_previsione as(
    select distinct accert.*, imp.*,     ts_impegni_legati.movgest_ts_b_id
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
                        and mov_imp.bil_id = bilancio_id_prec  --anno precedente di gestione
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
                      and anno_bil.anno=p_anno--annoprospetto_prec_int::varchar -- anno bilancio precedente
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
    	and imp.anno_imp = annoprospetto_int --+1  
        and ts_impegni_legati.avav_id is null
        and ts_impegni_legati.data_cancellazione is null  
        	--progetti.programma_id IS NULL cioe' non sono compresi negli impegni legati ai progetti estratti
            --nelle query precedenti. In pratica non devo contarli 2 volte.
      and progetti.programma_id IS NULL  ),
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
select 
capitoli_impegni.elem_id,
capitoli_impegni.numero_capitolo,
COALESCE(importo_impegni.anno_impegno,0) anno_impegno, 
COALESCE(importo_impegni.numero_impegno,0) numero_impegno,
COALESCE(elenco_progetti_imp.programma_code,'') progetto,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.importo_avanzo) importo_avanzo,
sum(impegni_verif_previsione.importo_imp) spese_impegnate_da_prev
--0::numeric spese_impegnate_da_prev
from capitoli_impegni
	left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
	left join impegni_verif_previsione on capitoli_impegni.movgest_ts_id = impegni_verif_previsione.movgest_ts_b_id and
		annoprospetto_int > p_anno::integer 
    left join elenco_progetti_imp on elenco_progetti_imp.movgest_ts_id = capitoli_impegni.movgest_ts_id-- importo_impegni.movgest_ts_b_id
-- SIAC-8866 04/07/2023: solo se l'impegno non è collegato al progetto.
where  ((COALESCE(elenco_progetti_imp.programma_code,'') = '' ) OR
		(COALESCE(elenco_progetti_imp.programma_code,'') <> '' AND impegni_verif_previsione.movgest_ts_b_id IS NULL))    
group by capitoli_impegni.elem_id,capitoli_impegni.numero_capitolo,
importo_impegni.anno_impegno, importo_impegni.numero_impegno, COALESCE(elenco_progetti_imp.programma_code,'')
) --dati_impegni
select 
p_anno_prospetto::varchar anno_prosp,
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
dati_impegni.elem_id::integer,
dati_impegni.numero_capitolo,
COALESCE(dati_impegni.anno_impegno,0) anno_impegno, 
COALESCE(dati_impegni.numero_impegno,0) numero_impegno,
COALESCE(dati_impegni.spese_impegnate,0)::numeric spese_impegnate,
COALESCE(dati_impegni.importo_avanzo,0)::numeric importo_avanzo,
0::numeric importo_colonna_d_Anno_prec,
COALESCE(dati_impegni.spese_impegnate_da_prev,0) spese_impegnate_da_prev,
''::varchar programma,
''::varchar cronoprogramma 
from struttura
	left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
	left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
where dati_impegni.elem_id is not null
--estraggo i dati della colonna D dello stesso anno bilancio ma con
--anno prospetto precedente.
--Vale solo quando il prospetto e' > dell'anno bilancio.
union 
--SIAC-8866 21/06/2023
--il calcolo degll'importo dei progetti deve prendere solo quelli di Previsione
select p_anno_prospetto::varchar anno_prosp,
''::varchar missione_code,
''::varchar missione_desc, 
cl2.classif_code programma_code,
''::varchar programma_desc, 
0::integer elem_id,
crono_elem.cronop_elem_code numero_capitolo,
0::integer anno_impegno,
0::integer numero_impegno,
0::numeric spese_impegnate,
0::numeric importo_avanzo,
case when p_anno = p_anno_prospetto 
    	then 0
		else COALESCE(sum(crono_elem_det.cronop_elem_det_importo),0) end importo_colonna_d_Anno_prec,
0::numeric spese_impegnate_da_prev,
pr.programma_code progetto,
crono.cronop_code cronoprogramma
from siac_t_programma pr, siac_t_cronop crono, 
     siac_t_bil bil, siac_t_periodo anno_bil, siac_d_programma_tipo tipo_prog,
     siac_t_cronop_elem crono_elem, siac_d_bil_elem_tipo crono_elem_tipo,
     siac_t_cronop_elem_det crono_elem_det, siac_t_periodo anno_crono_elem_det,
     siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
     siac_r_cronop_stato stc , siac_d_cronop_stato stct,
     siac_r_programma_stato stpr, siac_d_programma_stato stprt
where pr.programma_id=crono.programma_id
      and crono.bil_id = bil.bil_id
      and bil.periodo_id=anno_bil.periodo_id
      and tipo_prog.programma_tipo_id = pr.programma_tipo_id
      and crono_elem.cronop_id=crono.cronop_id
      and crono_elem.cronop_elem_id=crono_elem_det.cronop_elem_id
      and crono_elem_tipo.elem_tipo_id=crono_elem.elem_tipo_id
      and rcl2.cronop_elem_id = crono_elem.cronop_elem_id
      and rcl2.classif_id=cl2.classif_id
      and cl2.classif_tipo_id=clt2.classif_tipo_id
      and crono_elem_det.periodo_id = anno_crono_elem_det.periodo_id
      and stc.cronop_id=crono.cronop_id
      and stc.cronop_stato_id=stct.cronop_stato_id
      and stpr.programma_id=pr.programma_id
      and stpr.programma_stato_id=stprt.programma_stato_id                          
      and pr.ente_proprietario_id= p_ente_prop_id
      and anno_bil.anno=p_anno -- anno bilancio
      and crono.usato_per_fpv::boolean = true
      and crono_elem_det.anno_entrata = annoprospetto_prec_int::varchar -- anno prospetto           
      and anno_crono_elem_det.anno::integer=annoprospetto_prec_int +1 -- anno prospetto
      and clt2.classif_tipo_code='PROGRAMMA'
      and stct.cronop_stato_code='VA'
--SIAC-8866 21/06/2023
--il calcolo degll'importo dei progetti deve prendere solo quelli di Previsione      
      and tipo_prog.programma_tipo_code ='P'  --Solo progetti della previsione.
      and stprt.programma_stato_code='VA'
      and stpr.data_cancellazione is null
      and stc.data_cancellazione is null
      and crono.data_cancellazione is null
      and pr.data_cancellazione is null
      and bil.data_cancellazione is null
      and anno_bil.data_cancellazione is null
      and crono_elem.data_cancellazione is null
      and crono_elem_det.data_cancellazione is null
      and rcl2.data_cancellazione is null
group by cl2.classif_code ,crono_elem.cronop_elem_code, pr.programma_code, crono.cronop_code
/* SIAC-8866 26/06/2023.
    Nel report BILR011 l'importo della colonna D anno precedente e' dato non solo dai progetti ma anche dagli impegni.
    Aggiungo la query.
*/
union
select *
from(
with struttura as (
    select *
    from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,(p_anno::integer - 1)::varchar, null)
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
    and capitolo.bil_id = bilancio_id_prec --anno precedente													
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
    impegni as(
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
                        and mov_acc.ente_proprietario_id=p_ente_prop_id
                        and mov_acc.movgest_anno = annoprospetto_prec_int --accertamenti sempre dell'anno prospetto
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
                        and mov_imp.ente_proprietario_id=p_ente_prop_id
                        and mov_imp.bil_id = bilancio_id_prec --anno precedente di gestione
                        and mov_imp.movgest_anno >= annoprospetto_prec_int + 1 --impegni a partire dell'anno prospetto + 1
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
                      and anno_bil.anno::integer=p_anno::integer-1--annoprospetto_prec_int - 1 -- anno precedente quello del bilancio?
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
        and progetti.programma_id IS NULL )
    select --struttura.programma_code::varchar programma,    
    p_anno_prospetto::varchar anno_prosp,
	struttura.missione_code::varchar missione_code,
	struttura.missione_desc::varchar missione_desc, 
	struttura.programma_code programma_code,
	struttura.programma_desc::varchar programma_desc, 
	capitoli.elem_id::integer elem_id,
	capitoli.elem_code::varchar numero_capitolo,
	impegni.anno_imp::integer anno_impegno,
	impegni.numero_imp::integer numero_impegno,
	0::numeric spese_impegnate,
	0::numeric importo_avanzo,
	case when p_anno = p_anno_prospetto 
    	then 0
        else COALESCE(sum(impegni.importo_imp),0) end importo_colonna_d_Anno_prec,
	0::numeric spese_impegnate_da_prev,
    ''::varchar programma,
    ''::varchar cronoprogramma 
    from impegni
        left join capitoli 
            on impegni.elem_id=capitoli.elem_id 
        left join struttura 
            on struttura.programma_id = capitoli.programma_id
                and struttura.macroag_id = capitoli.macroaggregato_id        
    where impegni.anno_imp = annoprospetto_int
    group by anno_prosp, struttura.missione_code,struttura. missione_desc, struttura.programma_code, struttura.programma_desc, 
    	capitoli.elem_id, capitoli.elem_code, impegni.anno_imp, impegni.numero_imp) aaa     ) 
select * from tutto 
union 
--aggiungo la riga dei totali
select tutto.anno_prosp anno_prospetto,
 '' missione_code,
 '' missione_desc,
 'Totale' programma_code ,
 '' programma_desc,  
 0 elem_id,
 '' numero_capitolo,
 0 anno_impegno,
 0 numero_impegno,
 sum(tutto.spese_impegnate) spese_impegnate,
 sum(tutto.importo_avanzo) importo_avanzo,
 sum(tutto.importo_colonna_d_Anno_prec) importo_colonna_d_Anno_prec,
 sum(tutto.spese_impegnate_da_prev) spese_impegnate_da_prev,
 ''::varchar programma,
 ''::varchar cronoprogramma 
from tutto
group by anno_prospetto;

exception
when no_data_found THEN
raise notice 'Nessun dato trovato';
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

ALTER FUNCTION siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;