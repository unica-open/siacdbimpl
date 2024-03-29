/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR153_struttura_dca_spese_fpv_anno_succ" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  missione_code varchar,
  programma_code varchar,
  cofog varchar,
  transaz_ue varchar,
  pdc varchar,
  per_sanitario varchar,
  ricorr_spesa varchar,
  code_cup varchar,
  tupla_group varchar,
  fondo_plur_vinc numeric
) AS
$body$
DECLARE

/* 10/09/2020 - SIAC-7702.
	Nuova funzione che estrae i dati delle quote di impegni vincolati a FPVSC o FPVCC 
    dell'anno di bilancio successivo a quello per cui e' lanciato il report BILR153.
    I dati sono raggruppati per la tupla che compone la chiave logica del report:
    Missione, Programma, Codice Cofog, Codice Transazione UE, PDC, Perimetro Sanitario Spesa,
    Ricorrente Spesa, Cup.
*/

classifBilRec record;
bilancio_id integer;
RTN_MESSAGGIO text;
anno_int integer;

BEGIN
RTN_MESSAGGIO:='select 1';

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

anno_int :=p_anno::INTEGER;


return query
select distinct
	zz.missione_code, zz.programma_code, zz.code_cofog, zz.code_transaz_ue,
    zz.pdc_iv, zz.perim_sanitario_spesa, zz.ricorrente_spesa,zz.cup,
	zz.tupla_group::varchar,
	sum(zz.fondo_plur_vinc)  
from (
with clas as (
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
and d.classif_fam_code = '00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
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
and d.classif_fam_code = '00001'
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
and d.classif_fam_code = '00002'
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
and d.classif_fam_code = '00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
--insert into siac_rep_mis_pro_tit_mac_riga_anni
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
from missione , programma
,titusc, macroag
, siac_r_class progmacro
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 and titusc.ente_proprietario_id=missione.ente_proprietario_id
 ),
capall as (
with
cap as (
select a.elem_id,
a.elem_code ,
a.elem_desc ,
a.elem_code2 ,
a.elem_desc2 ,
a.elem_id_padre ,
a.elem_code3,
d.classif_id programma_id,d2.classif_id macroag_id
from siac_t_bil_elem a,siac_d_bil_elem_tipo b, siac_r_bil_elem_class c,
siac_r_bil_elem_class c2,
siac_t_class d,siac_t_class d2,
siac_d_class_tipo e,siac_d_class_tipo e2, siac_r_bil_elem_categoria f, 
siac_d_bil_elem_categoria g,siac_r_bil_elem_stato h,siac_d_bil_elem_stato i
where b.elem_tipo_id=a.elem_tipo_id
and c.elem_id=a.elem_id
and c2.elem_id=a.elem_id
and d.classif_id=c.classif_id
and d2.classif_id=c2.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and e2.classif_tipo_id=d2.classif_tipo_id
and g.elem_cat_id=f.elem_cat_id
and f.elem_id=a.elem_id
and h.elem_id=a.elem_id
and i.elem_stato_id=h.elem_stato_id
and a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.elem_tipo_code = 'CAP-UG'
and e.classif_tipo_code='PROGRAMMA'
and e2.classif_tipo_code='MACROAGGREGATO'
and g.elem_cat_code in	('STD','FPV','FSC','FPVC')
and i.elem_stato_code = 'VA'
and h.validita_fine is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and c2.data_cancellazione is null
and d.data_cancellazione is null
and d2.data_cancellazione is null
and e.data_cancellazione is null
and e2.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
), 
elenco_movgest as (
select distinct
r.elem_id, a.movgest_id,b.movgest_ts_id,
a.movgest_anno,
coalesce(o.movgest_ts_det_importo,0) movgest_importo
 from  siac_t_movgest a, 
 	siac_t_movgest_ts b,  
 	siac_t_movgest_ts_det o,
	siac_d_movgest_ts_det_tipo p,
    siac_d_movgest_tipo q,
    siac_r_movgest_bil_elem r ,
    siac_r_movgest_ts_stato s,
    siac_d_movgest_stato t,
    siac_d_movgest_ts_tipo u
where b.movgest_id=a.movgest_id
and o.movgest_ts_id=b.movgest_ts_id
and p.movgest_ts_det_tipo_id=o.movgest_ts_det_tipo_id
and q.movgest_tipo_id=a.movgest_tipo_id
and r.movgest_id=a.movgest_id
and s.movgest_ts_id=b.movgest_ts_id
and t.movgest_stato_id=s.movgest_stato_id
and u.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
-- VERIFICARE SE e' GIUSTO PRENDERE ANCHE I MOVGEST > 2017
-- PER estrarre Impegnato reimputato ad esercizi successivi
--and a.movgest_anno<=p_anno::INTEGER
and q.movgest_tipo_code='I'
and p.movgest_ts_det_tipo_code='A' -- importo attuale
and t.movgest_stato_code in ('D','N') 
and u.movgest_ts_tipo_code='T' 
and a.data_cancellazione is null
and b.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null
and s.data_cancellazione is null
and t.data_cancellazione is null
and u.data_cancellazione is null
and s.validita_fine is NULL
),
elenco_ord as(
select 
l.elem_id, f.ord_id, a.movgest_id, a.movgest_anno,
sum(coalesce(m.ord_ts_det_importo,0)) ord_importo
 from  siac_T_movgest a, siac_t_movgest_ts b,
 siac_r_liquidazione_movgest c,siac_r_liquidazione_ord d,
siac_t_ordinativo_ts e, 
siac_t_ordinativo f,
siac_d_ordinativo_tipo g,siac_r_ordinativo_stato h,
siac_d_ordinativo_stato i,siac_r_ordinativo_bil_elem l,siac_t_ordinativo_ts_det m,
siac_d_ordinativo_ts_det_tipo n
where b.movgest_id=a.movgest_id
and c.movgest_ts_id=b.movgest_ts_id
and d.liq_id=c.liq_id
and f.ord_id=e.ord_id
and d.sord_id=e.ord_ts_id
and f.ord_id=e.ord_id
and g.ord_tipo_id=f.ord_tipo_id
and i.ord_stato_id=h.ord_stato_id
and l.ord_id=f.ord_id
and m.ord_ts_id=e.ord_ts_id
and n.ord_ts_det_tipo_id=m.ord_ts_det_tipo_id
and h.ord_id=f.ord_id
and a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
--and a.movgest_anno<= p_anno::INTEGER
and g.ord_tipo_code='P'
and i.ord_stato_code<>'A'
and n.ord_ts_det_tipo_code='A'
and l.validita_fine is NULL
and h.validita_fine is NULL
and c.validita_fine is NULL
and d.validita_fine is NULL
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
group by l.elem_id, f.ord_id, a.movgest_id, a.movgest_anno
),
elenco_pdci_IV as (
  select d_class_tipo.classif_tipo_code classif_tipo_code_cap,
          r_bil_elem_class.elem_id ,
          t_class.classif_code pdc_iv
              from siac_t_class t_class,
                          siac_d_class_tipo d_class_tipo,
                          siac_r_bil_elem_class r_bil_elem_class
              where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                    and r_bil_elem_class.classif_id= t_class.classif_id
                  and d_class_tipo.classif_tipo_code = 'PDC_IV'
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null),
elenco_pdci_V as (
  select d_class_tipo.classif_tipo_code classif_tipo_code_cap,
          r_bil_elem_class.elem_id ,
          t_class.classif_code classif_code_cap,
  substring(t_class.classif_code from 1 for length(t_class.classif_code)-3) ||
          '000' pdc_v
              from siac_t_class t_class,
                          siac_d_class_tipo d_class_tipo,
                          siac_r_bil_elem_class r_bil_elem_class
              where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                    and r_bil_elem_class.classif_id= t_class.classif_id
                  and d_class_tipo.classif_tipo_code = 'PDC_V'
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null) ,                    
elenco_class_capitoli as (
	select * from "fnc_bilr153_tab_class_capitoli"  (p_ente_prop_id,bilancio_id)),                    
elenco_class_movgest as (
	select * from "fnc_bilr153_tab_class_movgest"  (p_ente_prop_id,bilancio_id)),
elenco_class_ord as (
	select * from "fnc_bilr153_tab_class_ord"  (p_ente_prop_id,bilancio_id)) ,
cupord as (
		select DISTINCT t_attr.attr_code attr_code_cup_ord, 
        		trim(r_ordinativo_attr.testo) testo_cup_ord,
				r_ordinativo_attr.ord_id                
        from 
               siac_t_attr t_attr,
               siac_r_ordinativo_attr  r_ordinativo_attr
              where  r_ordinativo_attr.attr_id=t_attr.attr_id   
              and  t_attr.ente_proprietario_id=p_ente_prop_id         
              AND upper(t_attr.attr_code) = 'CUP'           
                  and r_ordinativo_attr.data_cancellazione IS NULL
                  and t_attr.data_cancellazione IS NULL) ,
cup_movgest as(
	select DISTINCT t_attr.attr_code attr_code_cup_movgest, 
          trim(r_movgest_ts_attr.testo) testo_cup_movgest,
          r_movgest_ts_attr.movgest_ts_id,
          t_movgest_ts.movgest_id
        from 
               siac_t_attr t_attr,
               siac_r_movgest_ts_attr  r_movgest_ts_attr,
               siac_t_movgest_ts t_movgest_ts
              where  r_movgest_ts_attr.attr_id=t_attr.attr_id                 	
                and t_movgest_ts.movgest_ts_id = r_movgest_ts_attr.movgest_ts_id      
                  and t_attr.ente_proprietario_id=p_ente_prop_id         
              AND upper(t_attr.attr_code) = 'CUP'           
                  and r_movgest_ts_attr.data_cancellazione IS NULL
                  and t_attr.data_cancellazione IS NULL
                  and t_movgest_ts.data_cancellazione IS NULL),
fondo_plur as (
-- da SIAC-7702: Tale importo deve essere calcolato andando a considerare le 
-- quote di impegni vincolati a FPVSC o FPVCC dell'anno di bilancio 
-- successivo a -- quello di elaborazione ed aventi 
-- anno impegno >= anno bilancio successivo.
-- Questa funzione viene lanciata con il parametro di anni bilancio
-- successivo a quello impostato nel report.
/*    select --cap.elem_id,
    		imp.movgest_id,
            sum(r_imp_ts.movgest_ts_importo) importo_quota_vincolo
     from siac_t_movgest imp,
          siac_t_movgest_ts imp_ts,
          siac_d_movgest_ts_tipo d_imp_ts_tipo,
          siac_r_movgest_ts r_imp_ts,   
          siac_d_movgest_tipo d_imp_tipo,    
          siac_t_avanzovincolo av,
          siac_d_avanzovincolo_tipo avt,
          siac_r_movgest_bil_elem r_imp_cap,
          siac_t_bil_elem cap      
    where  imp.movgest_id=imp_ts.movgest_id
    and imp_ts.movgest_ts_id = r_imp_ts.movgest_ts_b_id
    and d_imp_ts_tipo.movgest_ts_tipo_id=imp_ts.movgest_ts_tipo_id
    and d_imp_tipo.movgest_tipo_id=imp.movgest_tipo_id   
    and r_imp_ts.avav_id = av.avav_id
    and av.avav_tipo_id=avt.avav_tipo_id
    and r_imp_cap.movgest_id=imp.movgest_id
    and cap.elem_id=r_imp_cap.elem_id
    and imp.ente_proprietario_id= p_ente_prop_id
    and imp.bil_id=bilancio_id
    and imp.movgest_anno>=anno_int
    and d_imp_tipo.movgest_tipo_code='I'
    and d_imp_ts_tipo.movgest_ts_tipo_code = 'T'
    and DATE_PART('year', av.validita_inizio) = anno_int
    and avt.avav_tipo_code in('FPVCC','FPVSC')
    and r_imp_ts.validita_fine is null
    and av.data_cancellazione IS NULL
    and imp.data_cancellazione IS NULL
    and imp_ts.data_cancellazione IS NULL
    and d_imp_ts_tipo.data_cancellazione IS NULL
    and d_imp_tipo.data_cancellazione IS NULL
    and r_imp_cap.data_cancellazione IS NULL
    and cap.data_cancellazione IS NULL
    group by imp.movgest_id */
  
--SIAC-8750 09/05/2023.
--Implementato nuovo algoritmo: si devono prendere gli importi INIZIALI degli impegni del bilancio successivo a quello del report,
--cioe' del rendiconto con anno impegno > dell'anno del rendiconto, collegati a vincoli FPV con atto <= all'anno del
--rendiconto. 
    select --cap.elem_id,
    		imp.movgest_id,
           -- sum(r_imp_ts.movgest_ts_importo) importo_quota_vincolo,
            sum(imp_ts_det.movgest_ts_det_importo) importo_iniziale_impegno 
     from siac_t_movgest imp,
          siac_t_movgest_ts imp_ts,
          siac_d_movgest_ts_tipo d_imp_ts_tipo,
          siac_r_movgest_ts r_imp_ts,   
          siac_d_movgest_tipo d_imp_tipo,    
          siac_t_avanzovincolo av,
          siac_d_avanzovincolo_tipo avt,
          siac_r_movgest_bil_elem r_imp_cap,
          siac_t_bil_elem cap ,
          siac_t_movgest_ts_det   imp_ts_det,
          siac_d_movgest_ts_det_tipo d_imp_ts_det_tipo,
          siac_r_movgest_ts_atto_amm r_imp_atto,
          siac_t_atto_amm atto
    where  imp.movgest_id=imp_ts.movgest_id
    and imp_ts.movgest_ts_id = r_imp_ts.movgest_ts_b_id
    and d_imp_ts_tipo.movgest_ts_tipo_id=imp_ts.movgest_ts_tipo_id
    and d_imp_tipo.movgest_tipo_id=imp.movgest_tipo_id   
    and r_imp_ts.avav_id = av.avav_id
    and av.avav_tipo_id=avt.avav_tipo_id
    and r_imp_cap.movgest_id=imp.movgest_id
    and cap.elem_id=r_imp_cap.elem_id
    and imp_ts_det.movgest_ts_id=imp_ts.movgest_ts_id
    and d_imp_ts_det_tipo.movgest_ts_det_tipo_id=imp_ts_det.movgest_ts_det_tipo_id
    and r_imp_atto.movgest_ts_id=imp_ts.movgest_ts_id
    and r_imp_atto.attoamm_id=atto.attoamm_id
    and imp.ente_proprietario_id= p_ente_prop_id
    and imp.bil_id= bilancio_id
    and imp.movgest_anno > anno_int-1 --anno per il quale sto facendo il rendiconto
    and d_imp_tipo.movgest_tipo_code='I'  --Impegno
    and d_imp_ts_tipo.movgest_ts_tipo_code = 'T'
    and DATE_PART('year', av.validita_inizio) = anno_int
    and avt.avav_tipo_code in('FPVCC','FPVSC')
    and d_imp_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo Iniziale 
    and atto.attoamm_anno::integer <= anno_int-1 --anno per il quale sto facendo il rendiconto
    and r_imp_ts.validita_fine is null
    and av.data_cancellazione IS NULL
    and imp.data_cancellazione IS NULL
    and imp_ts.data_cancellazione IS NULL
    and d_imp_ts_tipo.data_cancellazione IS NULL
    and d_imp_tipo.data_cancellazione IS NULL
    and r_imp_cap.data_cancellazione IS NULL
    and cap.data_cancellazione IS NULL
    and imp_ts_det.data_cancellazione IS NULL 
    and r_imp_atto.data_cancellazione IS NULL
    group by imp.movgest_id
    
    )                                  
select distinct
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.programma_id,cap.macroag_id,
COALESCE(elenco_class_capitoli.code_cofog,'') code_cofog_cap,
COALESCE(elenco_class_capitoli.code_transaz_ue,'') code_transaz_ue_cap,
COALESCE(elenco_class_capitoli.perim_sanitario_spesa,'') perim_sanitario_spesa_cap,
COALESCE(elenco_class_capitoli.ricorrente_spesa,'') ricorrente_spesa_cap,
COALESCE(elenco_class_movgest.code_cofog,'') code_cofog_movgest,
COALESCE(elenco_class_movgest.code_transaz_ue,'') code_transaz_ue_movgest,
COALESCE(elenco_class_movgest.perim_sanitario_spesa,'') perim_sanitario_spesa_movgest,
COALESCE(elenco_class_movgest.ricorrente_spesa,'') ricorrente_spesa_movgest,
COALESCE(elenco_class_ord.code_cofog,'') code_cofog_ord,
COALESCE(elenco_class_ord.code_transaz_ue,'') code_transaz_ue_ord,
COALESCE(elenco_class_ord.perim_sanitario_spesa,'') perim_sanitario_spesa_ord,
COALESCE(elenco_class_ord.ricorrente_spesa,'') ricorrente_spesa_ord,
-- ANNA INIZIO 
--CASE WHEN  trim(COALESCE(elenco_pdci_IV.pdc_iv,'')) = ''
--        THEN elenco_pdci_V.pdc_v ::varchar 
--        ELSE elenco_pdci_IV.pdc_iv ::varchar end pdc_iv,
CASE WHEN  trim(COALESCE(elenco_class_movgest.pdc_v,'')) = ''
        THEN elenco_pdci_IV.pdc_iv ::varchar 
        ELSE elenco_class_movgest.pdc_v ::varchar end pdc_iv,
-- ANNA FINE 
COALESCE(cupord.testo_cup_ord,'') testo_cup_ord,
COALESCE(cup_movgest.testo_cup_movgest,'') testo_cup_movgest,
elenco_ord.ord_id,
COALESCE(elenco_ord.ord_importo,0) ord_importo,
elenco_movgest.elem_id,
COALESCE(elenco_movgest.movgest_anno,0) anno_movgest,
elenco_movgest.movgest_id,
COALESCE(elenco_movgest.movgest_importo,0) movgest_importo,
--SIAC-8750 09/05/2023: importo degli impegni inziali e non del vincolo.
--COALESCE(fondo_plur.importo_quota_vincolo,0) fondo_plur_vinc,
COALESCE(fondo_plur.importo_iniziale_impegno,0) fondo_plur_vinc,
CASE WHEN COALESCE(elenco_class_capitoli.code_cofog,'') = ''
    	THEN CASE WHEN COALESCE(elenco_class_movgest.code_cofog,'') = ''
              THEN COALESCE(elenco_class_ord.code_cofog,'')
              ELSE COALESCE(elenco_class_movgest.code_cofog,'')
              END
        ELSE  COALESCE(elenco_class_capitoli.code_cofog,'') end code_cofog,
CASE WHEN COALESCE(elenco_class_capitoli.code_transaz_ue,'') = ''
    	THEN CASE WHEN COALESCE(elenco_class_movgest.code_transaz_ue,'') = ''
        		THEN COALESCE(elenco_class_ord.code_transaz_ue,'')
                ELSE COALESCE(elenco_class_movgest.code_transaz_ue,'')
                END
        ELSE COALESCE(elenco_class_capitoli.code_transaz_ue,'') end code_transaz_ue,                            
CASE WHEN COALESCE(elenco_class_capitoli.perim_sanitario_spesa,'') = '' 
	or COALESCE(elenco_class_capitoli.perim_sanitario_spesa,'')='XX' -- 25.08.2017 Sofia
    	 THEN CASE WHEN COALESCE(elenco_class_movgest.perim_sanitario_spesa,'') = '' 
         	or COALESCE(elenco_class_movgest.perim_sanitario_spesa,'')='XX'  -- 25.08.2017 Sofia
                   THEN case when COALESCE(elenco_class_ord.perim_sanitario_spesa,'')='XX' then '' 
                   	else COALESCE(elenco_class_ord.perim_sanitario_spesa,'') end -- 25.08.2017 Sofia
                   ELSE COALESCE(elenco_class_movgest.perim_sanitario_spesa,'') 
                   END
        ELSE COALESCE(elenco_class_capitoli.perim_sanitario_spesa,'') end perim_sanitario_spesa,
 CASE WHEN COALESCE(elenco_class_capitoli.ricorrente_spesa,'') = ''
    	THEN CASE WHEN COALESCE(elenco_class_movgest.ricorrente_spesa,'') = ''
              THEN COALESCE(elenco_class_ord.ricorrente_spesa,'')::varchar
              ELSE COALESCE(elenco_class_movgest.ricorrente_spesa,'') 
              END
        ELSE COALESCE(elenco_class_capitoli.ricorrente_spesa,'') end ricorrente_spesa,
 CASE WHEN COALESCE(cup_movgest.testo_cup_movgest,'') =''
    	THEN COALESCE(cupord.testo_cup_ord,'')
        ELSE COALESCE(cup_movgest.testo_cup_movgest,'') end cup
from cap
  left join elenco_movgest on cap.elem_id=elenco_movgest.elem_id
  left join elenco_ord on elenco_ord.movgest_id=elenco_movgest.movgest_id
  left join elenco_pdci_IV on elenco_pdci_IV.elem_id=cap.elem_id 
  left join elenco_pdci_V on elenco_pdci_V.elem_id=cap.elem_id 
  left join elenco_class_capitoli on elenco_class_capitoli.elem_id=cap.elem_id
  left join elenco_class_movgest on elenco_class_movgest.movgest_id=elenco_movgest.movgest_id
  left join elenco_class_ord on elenco_class_ord.ord_id=elenco_ord.ord_id 
  left join cup_movgest on (cup_movgest.movgest_id=elenco_movgest.movgest_id
  					and cup_movgest.movgest_ts_id=elenco_movgest.movgest_ts_id)
  left join cupord on cupord.ord_id=elenco_ord.ord_id  
  --left join fondo_plur on cap.elem_id=fondo_plur.elem_id 
  left join fondo_plur on fondo_plur.movgest_id=elenco_movgest.movgest_id 
)
select --SIAC-8750 10/05/2023: occorre aggiungere un distinct per evitare di estrarre piu' volte un impegno
		--se e' collegato a piu' di un ordinativo.
	distinct
    p_anno::varchar bil_anno,
    ''::varchar missione_tipo_code,
    clas.missione_tipo_desc::varchar,
    clas.missione_code::varchar,
    clas.missione_desc::varchar,
    ''::varchar programma_tipo_code,
    clas.programma_tipo_desc::varchar,
    clas.programma_code::varchar,
    clas.programma_desc::varchar,
    ''::varchar	titusc_tipo_code,
    clas.titusc_tipo_desc::varchar,
    clas.titusc_code::varchar,
    clas.titusc_desc::varchar,
    ''::varchar macroag_tipo_code,
    clas.macroag_tipo_desc::varchar,
    clas.macroag_code::varchar,
    clas.macroag_desc::varchar,
    capall.bil_ele_code::varchar,
    capall.bil_ele_desc::varchar,
    capall.bil_ele_code2::varchar,
    capall.bil_ele_desc2::varchar,
    capall.bil_ele_id::integer,
    capall.bil_ele_id_padre::integer,
    capall.bil_ele_code3::varchar,
    capall.code_cofog::varchar,
    capall.code_transaz_ue::varchar,        
    capall.pdc_iv::varchar,
    capall.perim_sanitario_spesa::varchar,
    capall.ricorrente_spesa::varchar,  
    capall.cup::varchar,      
    	--SIAC-8750 10/05/2023: escludo i dati dell'ordinativo perche' se ne esiste  piu' di 1 collegato all'impegno 
    	--estraggo l'impegno piu' volte.
    --coalesce(capall.ord_id,0)::integer ord_id ,
    --coalesce(capall.ord_importo,0)::numeric ord_importo,
    coalesce(capall.movgest_id,0)::integer movgest_id,
    coalesce(capall.anno_movgest,0)::integer anno_movgest , 
    coalesce(capall.movgest_importo,0)::numeric movgest_importo,
--SIAC-8734 24/05/2022.
--Devo prendere tutti gli importi.    
   -- case when lag(clas.missione_code||clas.programma_code||code_cofog||code_transaz_ue||pdc_iv||
   -- perim_sanitario_spesa||ricorrente_spesa||cup::varchar)
	--	OVER (order by clas.missione_code||clas.programma_code||code_cofog||code_transaz_ue||pdc_iv||
   -- perim_sanitario_spesa||ricorrente_spesa||cup::varchar) = 
   -- clas.missione_code||clas.programma_code||code_cofog||code_transaz_ue||pdc_iv||
  --  perim_sanitario_spesa||ricorrente_spesa||cup::varchar then 0
  --  	else capall.fondo_plur_vinc end fondo_plur_vinc,            
    coalesce(capall.fondo_plur_vinc,0)::numeric fondo_plur_vinc,
    clas.missione_code||clas.programma_code||code_cofog||code_transaz_ue||pdc_iv||
    perim_sanitario_spesa||ricorrente_spesa||cup::varchar tupla_group
FROM capall left join clas on 
    clas.programma_id = capall.programma_id and    
    clas.macroag_id=capall.macroag_id
 where 
   capall.bil_ele_id is not null
   and coalesce(capall.fondo_plur_vinc,0) >0)
  as zz 
  group by zz.missione_code, zz.programma_code, zz.code_cofog, 
  zz.code_transaz_ue,  zz.pdc_iv, zz.perim_sanitario_spesa, 
  zz.ricorrente_spesa,zz.cup,  zz.tupla_group   ;


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

ALTER FUNCTION siac."BILR153_struttura_dca_spese_fpv_anno_succ" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;