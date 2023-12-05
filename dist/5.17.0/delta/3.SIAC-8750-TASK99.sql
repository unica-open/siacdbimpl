/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--SIAC-8750 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR153_struttura_dca_spese_fpv_anno_succ"(p_ente_prop_id integer, p_anno varchar);

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
  
--SIAC-8750 - Maurizio - FINE

--siac-task-issue #99 - Maurizio - INIZIO
  
DROP FUNCTION if exists siac."BILR125_rendiconto_gestione"(p_ente_prop_id integer, p_anno varchar, p_classificatori varchar);


CREATE OR REPLACE FUNCTION siac."BILR125_rendiconto_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  importo_codice_bilancio_prec numeric,
  rif_cc varchar,
  rif_dm varchar,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
  importo_dati_passivo numeric,
  importo_dati_passivo_prec numeric,
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer
) AS
$body$
DECLARE

classifGestione record;
pdce            record;
impprimanota    record;
dati_passivo    record;

anno_prec 			 VARCHAR;
v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_dare_prec      NUMERIC :=0;
v_imp_avere_prec     NUMERIC :=0;
v_importo 			 NUMERIC :=0;
v_importo_prec 		 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_pdce_fam_code_prec VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_prec VARCHAR;
v_anno_int integer; -- SIAC-5487
v_anno_prec_int integer; -- SIAC-5487

DEF_NULL	constant VARCHAR:=''; 
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;

v_importo_anno_prec NUMERIC;

BEGIN

/*
Valori parametro p_classificatori:

- 1 - Conto Economico; BILR125;
- 2 - Stato Patrimoniale - Attivo; BILR128;
- 3 - Stato Patrimoniale - Passivo; BILR129;

*/

anno_prec := (p_anno::INTEGER-1)::VARCHAR;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer; -- SIAC-5487
v_anno_prec_int := p_anno::integer-1; -- SIAC-5487

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
importo_codice_bilancio_prec := 0;
rif_CC := '';
rif_DM := '';
codice_raggruppamento := '';
descr_raggruppamento := '';
codice_codifica_albero := '';
valore_importo := 0;
codice_subraggruppamento := '';
classif_id_liv1 := 0;
classif_id_liv2 := 0;
classif_id_liv3 := 0;
classif_id_liv4 := 0;
classif_id_liv5 := 0;
classif_id_liv6 := 0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL';   
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00022'; -- 'SPP_CODBIL';
   v_classificatori1 := '00023'; -- 'CO_CODBIL';
END IF;  

raise notice '1 - %' , v_classificatori;  

v_anno_prec := p_anno::INTEGER-1;

IF p_classificatori = '2' THEN

--16/05/2023 siac-task-issue #99
--La seguente query estraeva i dati sia dell'anno corrente che di quello precedente.
--E' stata spezzata in 2 query, una per l'anno corrente l'altra per l'anno precedente per permettere la corretta gestione
--della validita' della relazione tra conto economico e la relativa classificazione (siac_r_pdce_conto_class).
WITH Importipn AS ( --Anno corrente
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    --16/05/2023 siac-task-issue #99: solo anno corrente.
    AND anno_eserc.anno IN (p_anno)--,v_anno_prec)
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    --SIAC-8578 19/01/2022 i conti PP di ottavo livello devono essere esclusi.
    --AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND (pdce_fam.pdce_fam_code IN ('PP','OP') and 
    	pdce_conto.livello <> 8)
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    --16/05/2023 siac-task-issue #99: verifico solo la validita' e non la cancellazione.
   -- AND   a.data_cancellazione is null
    AND   v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
    AND   v_anno_int BETWEEN date_part('year',a.validita_inizio) AND date_part('year',COALESCE(a.validita_fine,now())) -- SIAC-6156
    )
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine ;

WITH Importipn AS ( --anno precedente.
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    --16/05/2023 siac-task-issue #99: solo anno precedente.
    AND anno_eserc.anno IN (v_anno_prec) 
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    --SIAC-8578 19/01/2022 i conti PP di ottavo livello devono essere esclusi.
    --AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND (pdce_fam.pdce_fam_code IN ('PP','OP') and 
    	pdce_conto.livello <> 8)
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    --16/05/2023 siac-task-issue #99: verifico solo la validita' e non la cancellazione.
    --AND   a.data_cancellazione is null
    AND   v_anno_prec_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
    AND   v_anno_prec_int BETWEEN date_part('year',a.validita_inizio) AND date_part('year',COALESCE(a.validita_fine,now())) -- SIAC-6156
    )
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine ;
END IF;


FOR classifGestione IN
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       --case when zz.classif_code='26' then 'E.26' else zz.classif_code end codice_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       --case when zz.ordine='26' then 'E.26' else zz.ordine end codice_codifica_albero,
       case when zz.ordine='E.26' then 3 else zz.level end livello_codifica,
       --zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf, siac_t_class c
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           and c.classif_id=rt1.classif_id
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
/*           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)*/
           AND v_anno_int BETWEEN date_part('year',tt1.validita_inizio) AND 
           date_part('year',COALESCE(tt1.validita_fine,now())) --SIAC-5487
           AND v_anno_int BETWEEN date_part('year',rt1.validita_inizio) AND 
           date_part('year',COALESCE(rt1.validita_fine,now())) 
           AND v_anno_int BETWEEN date_part('year',c.validita_inizio) AND 
           date_part('year',COALESCE(c.validita_fine,now())) 
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn,siac_t_class c2
        WHERE tp.classif_id = tn.classif_id_padre 
        and c2.classif_id=tn.classif_id
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND v_anno_int BETWEEN date_part('year',tn.validita_inizio) AND 
           date_part('year',COALESCE(tn.validita_fine,now())) 
AND v_anno_int BETWEEN date_part('year',c2.validita_inizio) AND 
           date_part('year',COALESCE(c2.validita_fine,now()))            
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, 
--case when zz.ordine='26' then 'E.26' else zz.ordine end asc
zz.ordine
/*
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, zz.ordine asc     */

LOOP
    
        
    valore_importo := 0;

    SELECT COUNT(*)
    INTO   valore_importo
    FROM   siac_r_class_fam_tree a
    WHERE  a.classif_id_padre = classifGestione.classif_id
    AND    a.data_cancellazione IS NULL;

    IF classifGestione.livello_codifica = 3 THEN    
       v_codice_subraggruppamento := classifGestione.codice_codifica;  
       codice_subraggruppamento := v_codice_subraggruppamento;       
    ELSIF classifGestione.livello_codifica < 3 THEN
       codice_subraggruppamento := '';        
    ELSIF classifGestione.livello_codifica > 3 THEN
       codice_subraggruppamento := v_codice_subraggruppamento;          
    END IF;
       
    IF classifGestione.livello_codifica = 2 THEN
       codice_raggruppamento := SUBSTRING(classifGestione.descrizione_codifica FROM 1 FOR 1);
       descr_raggruppamento := classifGestione.descrizione_codifica;
    ELSIF classifGestione.livello_codifica = 1 THEN  
       codice_raggruppamento := '';
       descr_raggruppamento := '';  
    END IF;   
    
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF;
    
    rif_CC := ''; 
    rif_DM := '';

    SELECT a.rif_art_2424_cc, a.rif_dm_26_4_95
    INTO rif_CC, rif_DM
    FROM siac_rep_rendiconto_gestione_rif a
    WHERE a.codice_bilancio = classifGestione.codice_codifica_albero
    AND   (a.codice_report = v_classificatori OR a.codice_report = v_classificatori1);    

    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0; 
    
    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

      SELECT importo_passivo
      INTO   importo_dati_passivo_prec
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = v_anno_prec
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;
          
      	raise notice 'Codifica: % - importo_passivo 2022 = % - importo passivo 2021 = % - albero = %', 
        	classifGestione.descrizione_codifica, importo_dati_passivo, importo_dati_passivo_prec, classifGestione.codice_codifica_albero;

    END IF;
    

    
    v_imp_dare := 0;
    v_imp_avere := 0;
    v_imp_dare_prec := 0;
    v_imp_avere_prec := 0;
    v_importo := 0;
    v_importo_prec := 0;
    v_pdce_fam_code := '';
    v_pdce_fam_code_prec := '';

--18/01/2022 SIAC-8196, SIAC-8557 e SIAC-8578.
--Se il conto e' passivo e se il livello e' 8 nel report BILR128 (SP Attivo)
--devo considerare il conto PP come fosse attivo (AP).
    FOR pdce IN
    SELECT case when p_classificatori ='2' and d.pdce_fam_code ='PP' and
    		b.livello = 8
    	then 'AP'
        else d.pdce_fam_code end codice_pdce_fam_code,
    e.movep_det_segno, i.anno, SUM(COALESCE(e.movep_det_importo,0)) AS importo
    FROM  siac_r_pdce_conto_class a
    INNER JOIN siac_t_pdce_conto b ON a.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
    INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
    INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
    INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
    INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
    INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id
    WHERE a.classif_id = classifGestione.classif_id
    AND   m.pnota_stato_code = 'D'
    AND   (i.anno = p_anno OR i.anno = anno_prec)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL
/*    AND   (v_anno_int BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487    
           OR
           v_anno_prec_int BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487 
          )*/
       AND   (i.anno::integer BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487    
           OR
           i.anno::integer BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487 
          )  
    AND  v_anno_int BETWEEN date_part('year',a.validita_inizio)::integer
    AND coalesce (date_part('year',a.validita_fine)::integer ,v_anno_int) 
    GROUP BY codice_pdce_fam_code, e.movep_det_segno, i.anno
        
    LOOP
        
    IF p_classificatori IN ('1','3') THEN
           
      IF pdce.movep_det_segno = 'Dare' THEN
         IF pdce.anno = p_anno THEN
            v_imp_dare := pdce.importo;
         ELSE
            v_imp_dare_prec := pdce.importo;
         END IF;   
      ELSIF pdce.movep_det_segno = 'Avere' THEN
         IF pdce.anno = p_anno THEN
            v_imp_avere := pdce.importo;
         ELSE
            v_imp_avere_prec := pdce.importo;
         END IF;                   
      END IF;               
    
      IF pdce.anno = p_anno THEN
         v_pdce_fam_code := pdce.codice_pdce_fam_code;
      ELSE
         v_pdce_fam_code_prec := pdce.codice_pdce_fam_code;
      END IF;    
        
    ELSIF p_classificatori = '2' THEN  
      IF pdce.codice_pdce_fam_code = 'AP' THEN 
      
        IF pdce.movep_det_segno = 'Dare' THEN
           IF pdce.anno = p_anno THEN
              v_imp_dare := pdce.importo;
           ELSE
              v_imp_dare_prec := pdce.importo;
           END IF;   
        ELSIF pdce.movep_det_segno = 'Avere' THEN
           IF pdce.anno = p_anno THEN
              v_imp_avere := pdce.importo;
           ELSE
              v_imp_avere_prec :=pdce.importo;
           END IF;                   
        END IF;       
      
        IF pdce.anno = p_anno THEN
           v_pdce_fam_code := pdce.codice_pdce_fam_code;
        ELSE
           v_pdce_fam_code_prec := pdce.codice_pdce_fam_code;
        END IF;      
      
      END IF;        
    END IF;  
                                                                        
    END LOOP;


        
    IF p_classificatori IN ('1','3') THEN
      IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
         v_importo := v_imp_avere - v_imp_dare;
      ELSIF v_pdce_fam_code IN ('AP','CE') THEN   
         v_importo := v_imp_dare - v_imp_avere;   
      END IF; 
    
      IF v_pdce_fam_code_prec IN ('PP','OP','OA','RE') THEN
         v_importo_prec := v_imp_avere_prec - v_imp_dare_prec;
      ELSIF v_pdce_fam_code_prec IN ('AP','CE') THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;     
    
    ELSIF p_classificatori = '2' THEN
      
      IF v_pdce_fam_code = 'AP' THEN   
         v_importo := v_imp_dare - v_imp_avere;
      END IF; 
      
      IF v_pdce_fam_code_prec = 'AP' THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;       
            
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code,classifGestione.classif_id,COALESCE(v_importo,0),COALESCE(v_imp_dare,0),COALESCE(v_imp_avere,0);
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code_prec,classifGestione.classif_id,COALESCE(v_importo_prec,0),COALESCE(v_imp_dare_prec,0),COALESCE(v_imp_avere_prec,0);
        
    END IF;
    
/* SIAC-6296. 11/07/2018: per risolvere il problema relativo all'estrazione
	dei dati dell'anno precedente che in alcuni casi non sono estratti 
    correttamente a causa delle date di fine validita'.
    E' chiamata una copia della procedura passando in input l'anno 
    precedente.
    In questo modo si e' sicuri che i dati dell'anno precedente sono
    uguali a quelli ottenuti nel report con input anno precente. */ 
    
/* siac-task-issue #89 04/05/2023.
  La ricerca deve essere effettuata per ID del classificare e non per codice/descrizione perche' ci sono classificatori
  che hanno codice e descrizione identici ma padri differenti.       
    select a.importo_codice_bilancio
    into v_importo_anno_prec
    from "BILR125_rendiconto_gestione_anno_prec"(p_ente_prop_id, anno_prec, 
    	p_classificatori, classifGestione.codice_codifica,
        classifGestione.descrizione_codifica) a; */
select a.importo_codice_bilancio
    into v_importo_anno_prec
    from "BILR125_rendiconto_gestione_anno_prec"(p_ente_prop_id, anno_prec, 
    	p_classificatori, classifGestione.codice_codifica,
        classifGestione.descrizione_codifica, classifGestione.classif_id) a;        
  --  where a.codice_codifica = classifGestione.codice_codifica
   -- and a.descrizione_codifica = classifGestione.descrizione_codifica
   -- and a.tipo_codifica = classifGestione.tipo_codifica
   -- and a.livello_codifica = classifGestione.livello_codifica;
    
           
	v_importo_prec:=v_importo_anno_prec;
        
    raise notice 'codice_codifica = %, classif_id = % - descr_codifica = %, importo_prec = %', 
    	classifGestione.codice_codifica, classifGestione.classif_id, classifGestione.descrizione_codifica,
        v_importo_anno_prec; 
        
    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;
  
    IF p_classificatori != '1' THEN
    
      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;         
         importo_codice_bilancio_prec := v_importo_prec;
      ELSE
         importo_codice_bilancio := 0;       
         importo_codice_bilancio_prec := 0;
      END IF;          
  
    ELSE
      importo_codice_bilancio := v_importo;
      importo_codice_bilancio_prec := v_importo_prec;     
    END IF;

raise notice 'classif_id = %, descrizione_codifica = %, codice_raggruppamento = %, codice_subraggruppamento = %, v_importo = %, v_importo_prec = %',
    	classifGestione.classif_id,
        classifGestione.descrizione_codifica, codice_raggruppamento,
        codice_subraggruppamento, 
        v_importo, v_importo_prec;
        
    codice_codifica_albero := classifGestione.codice_codifica_albero;
    
    classif_id_liv1 := classifGestione.classif_id_liv1;
    classif_id_liv2 := classifGestione.classif_id_liv2;
    classif_id_liv3 := classifGestione.classif_id_liv3;
    classif_id_liv4 := classifGestione.classif_id_liv4;
    classif_id_liv5 := classifGestione.classif_id_liv5;
    classif_id_liv6 := classifGestione.classif_id_liv6;
      
    return next;

    tipo_codifica := '';
    codice_codifica := '';
    descrizione_codifica := '';
    livello_codifica := 0;
    importo_codice_bilancio := 0;
    importo_codice_bilancio_prec := 0;
    rif_CC := '';
    rif_DM := '';
    codice_codifica_albero := '';
    valore_importo := 0;
    codice_subraggruppamento := '';
    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0;
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;

END LOOP;

delete from rep_bilr125_dati_stato_passivo where utente=user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione';
  return;
  WHEN others  THEN
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

ALTER FUNCTION siac."BILR125_rendiconto_gestione" (p_ente_prop_id integer, p_anno varchar, p_classificatori varchar)
  OWNER TO siac;  
  
--siac-task-issue #99 - Maurizio - FINE  