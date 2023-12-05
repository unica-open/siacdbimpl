/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR050_Riepilogo_generale_spese_missioni" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  residui_passivi numeric,
  previsioni_definitive_comp numeric,
  previsioni_definitive_cassa numeric,
  pagamenti_residui numeric,
  pagamenti_competenza numeric,
  riaccertamenti_residui numeric,
  impegni numeric,
  fondo_pluriennale_vincolato numeric,
  bil_ele_code3 varchar
) AS
$body$
DECLARE


classifBilRec record;
bilancio_id integer;
RTN_MESSAGGIO text;
BEGIN
RTN_MESSAGGIO:='select 1';
select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;


return query
select zz.* from (
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
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.elem_tipo_id=a.elem_tipo_id
and b.elem_tipo_code='CAP-UG' 
and c.elem_id=a.elem_id
and c2.elem_id=a.elem_id
and d.classif_id=c.classif_id
and d2.classif_id=c2.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and e2.classif_tipo_id=d2.classif_tipo_id
and e.classif_tipo_code='PROGRAMMA'
and e2.classif_tipo_code='MACROAGGREGATO'
and g.elem_cat_id=f.elem_cat_id
and f.elem_id=a.elem_id
and g.elem_cat_code in	('STD','FPV','FSC','FPVCC','FPVSC')
and h.elem_id=a.elem_id
and i.elem_stato_id=h.elem_stato_id
and i.elem_stato_code='VA'
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
capststa as (--capitoli ('STD','FSC') TipoImpstanz='STA'
select k.elem_id,sum(k.previsioni_definitive_comp) previsioni_definitive_comp from(
select a.elem_id, coalesce (f.elem_det_importo,0)   as previsioni_definitive_comp
from siac_t_bil_elem a,siac_r_bil_elem_stato b, siac_d_bil_elem_stato c,
siac_r_bil_elem_categoria d,siac_d_bil_elem_categoria e,siac_t_bil_elem_det f,siac_d_bil_elem_det_tipo g,
siac_t_periodo h
where  b.elem_id=a.elem_id
and c.elem_stato_id=b.elem_stato_id
and c.elem_stato_code='VA'
and a.ente_proprietario_id=p_ente_prop_id
and b.validita_fine is NULL
and d.elem_id=a.elem_id and e.elem_cat_id=d.elem_cat_id
and e.elem_cat_code	in	('STD','FSC')
and d.validita_fine is NULL
and f.elem_id=a.elem_id and g.elem_det_tipo_id=f.elem_det_tipo_id
and g.elem_det_tipo_code='STA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and h.periodo_id=f.periodo_id
and h.anno=p_anno
and a.bil_id=bilancio_id
union
--capitoli ('FPV','FPVCC','FPVSC') TipoImpstanz='STA'; 	
select a.elem_id, coalesce (f.elem_det_importo,0)   as previsioni_definitive_comp
from siac_t_bil_elem a,siac_r_bil_elem_stato b, siac_d_bil_elem_stato c,
siac_r_bil_elem_categoria d,siac_d_bil_elem_categoria e,siac_t_bil_elem_det f,siac_d_bil_elem_det_tipo g
,siac_t_periodo h
where  b.elem_id=a.elem_id
and c.elem_stato_id=b.elem_stato_id
and c.elem_stato_code='VA'
and a.ente_proprietario_id=p_ente_prop_id
and b.validita_fine is NULL
and d.elem_id=a.elem_id and e.elem_cat_id=d.elem_cat_id
and e.elem_cat_code	in	('FPV',  'FPVCC','FPVSC')
and d.validita_fine is NULL
and f.elem_id=a.elem_id and g.elem_det_tipo_id=f.elem_det_tipo_id
and g.elem_det_tipo_code='STA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and h.periodo_id=f.periodo_id
and h.anno=p_anno
and a.bil_id=bilancio_id) as k group by k.elem_id
),
capstsca AS(
--capitoli ('STD','FSC') TipoImpstanz='SCA'; 	
select a.elem_id, sum(coalesce (f.elem_det_importo,0))   as previsioni_definitive_cassa
from siac_t_bil_elem a,siac_r_bil_elem_stato b, siac_d_bil_elem_stato c,
siac_r_bil_elem_categoria d,siac_d_bil_elem_categoria e,siac_t_bil_elem_det f,siac_d_bil_elem_det_tipo g,
siac_t_periodo h
where  b.elem_id=a.elem_id
and c.elem_stato_id=b.elem_stato_id
and c.elem_stato_code='VA'
and a.ente_proprietario_id=p_ente_prop_id
and b.validita_fine is NULL
and d.elem_id=a.elem_id and e.elem_cat_id=d.elem_cat_id
and e.elem_cat_code	in	('STD','FSC')
and d.validita_fine is NULL
and f.elem_id=a.elem_id and g.elem_det_tipo_id=f.elem_det_tipo_id
and g.elem_det_tipo_code='SCA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and h.periodo_id=f.periodo_id
and h.anno=p_anno
and a.bil_id=bilancio_id
group by a.elem_id
)
,
res as (
--pagamenti residui
select 
l.elem_id,sum(coalesce(m.ord_ts_det_importo,0)) pagamenti_residui
 from  siac_T_movgest a, siac_t_movgest_ts b,siac_r_liquidazione_movgest c,siac_r_liquidazione_ord d,
siac_t_ordinativo_ts e,siac_t_ordinativo f,siac_d_ordinativo_tipo g,siac_r_ordinativo_stato h,
siac_d_ordinativo_stato i,siac_r_ordinativo_bil_elem l,siac_t_ordinativo_ts_det m,
siac_d_ordinativo_ts_det_tipo n
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.movgest_id=a.movgest_id
and c.movgest_ts_id=b.movgest_ts_id
and d.liq_id=c.liq_id
and f.ord_id=e.ord_id
and a.movgest_anno<p_anno::INTEGER
and c.validita_fine is NULL
and d.validita_fine is NULL
and d.sord_id=e.ord_ts_id
and f.ord_id=e.ord_id
and g.ord_tipo_id=f.ord_tipo_id
and g.ord_tipo_code='P'
and h.ord_id=f.ord_id
and i.ord_stato_id=h.ord_stato_id
and i.ord_stato_code<>'A'
and l.ord_id=f.ord_id
and m.ord_ts_id=e.ord_ts_id
and n.ord_ts_det_tipo_id=m.ord_ts_det_tipo_id
and n.ord_ts_det_tipo_code='A'
and l.validita_fine is NULL
and h.validita_fine is NULL
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
group by l.elem_id
),
comp as  (
--pagamenti competenza
select 
l.elem_id,sum(coalesce(m.ord_ts_det_importo,0)) pagamenti_competenza
 from  siac_T_movgest a, siac_t_movgest_ts b,siac_r_liquidazione_movgest c,siac_r_liquidazione_ord d,
siac_t_ordinativo_ts e,siac_t_ordinativo f,siac_d_ordinativo_tipo g,siac_r_ordinativo_stato h,
siac_d_ordinativo_stato i,siac_r_ordinativo_bil_elem l,siac_t_ordinativo_ts_det m,
siac_d_ordinativo_ts_det_tipo n
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.movgest_id=a.movgest_id
and c.movgest_ts_id=b.movgest_ts_id
and d.liq_id=c.liq_id
and f.ord_id=e.ord_id
and a.movgest_anno=p_anno::INTEGER
and c.validita_fine is NULL
and d.validita_fine is NULL
and d.sord_id=e.ord_ts_id
and f.ord_id=e.ord_id
and g.ord_tipo_id=f.ord_tipo_id
and g.ord_tipo_code='P'
and h.ord_id=f.ord_id
and i.ord_stato_id=h.ord_stato_id
and i.ord_stato_code<>'A'
and l.ord_id=f.ord_id
and m.ord_ts_id=e.ord_ts_id
and n.ord_ts_det_tipo_id=m.ord_ts_det_tipo_id
and n.ord_ts_det_tipo_code='A'
and l.validita_fine is NULL
and h.validita_fine is NULL
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
group by l.elem_id
) ,
rires as (
select  
b.elem_id,sum(coalesce(q.movgest_ts_det_importo,0)) riaccertamenti_residui
from 
siac_r_movgest_bil_elem b,siac_t_movgest c,
      siac_d_movgest_tipo  d,
      siac_t_movgest_ts  e,
      siac_r_movgest_ts_stato f,
      siac_d_movgest_stato   g,
      siac_t_movgest_ts_det h,
      siac_d_movgest_ts_tipo i,
      siac_d_movgest_ts_det_tipo l,
      siac_t_modifica m,
      siac_r_modifica_stato o,
      siac_d_modifica_stato p,
      siac_t_movgest_ts_det_mod q
where c.ente_proprietario_id=p_ente_prop_id
and c.bil_id=bilancio_id
and b.movgest_id = c.movgest_id 
and c.movgest_anno < p_anno::integer
and c.movgest_tipo_id = d.movgest_tipo_id 
and d.movgest_tipo_code = 'I'
and c.movgest_id = e.movgest_id 
and e.movgest_ts_id  = f.movgest_ts_id 
and f.movgest_stato_id  = g.movgest_stato_id 
and f.validita_fine is NULL
and g.movgest_stato_code   in ('D','N') 
and h.movgest_ts_id = e.movgest_ts_id
and i.movgest_ts_tipo_id  = e.movgest_ts_tipo_id 
and i.movgest_ts_tipo_code  = 'T' 
and l.movgest_ts_det_tipo_id  = h.movgest_ts_det_tipo_id 
and l.movgest_ts_det_tipo_code = 'A' 
and q.movgest_ts_id=e.movgest_ts_id      
and q.mod_stato_r_id=o.mod_stato_r_id
and o.validita_fine is NULL
and p.mod_stato_id=o.mod_stato_id  
and p.mod_stato_code='V'
and o.mod_id=m.mod_id
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and f.data_cancellazione is null 
and e.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null
and m.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
group by b.elem_id
 ),
 imp as (
select d.elem_id,sum(coalesce(c.movgest_ts_det_importo,0)) impegni from siac_t_movgest a,siac_t_movgest_ts b,siac_t_movgest_ts_det c,
siac_r_movgest_bil_elem d,siac_d_movgest_tipo e,siac_r_movgest_ts_stato f,siac_d_movgest_stato g,
siac_d_movgest_ts_tipo h,siac_d_movgest_ts_det_tipo i
 where a.bil_id=bilancio_id
 and b.movgest_id=a.movgest_id
 and c.movgest_ts_id=b.movgest_ts_id
 and a.movgest_anno = p_anno::integer
and d.movgest_id=a.movgest_id
and e.movgest_tipo_id=a.movgest_tipo_id
and e.movgest_tipo_code='I'
and f.movgest_ts_id=b.movgest_ts_id
and f.movgest_stato_id=g.movgest_stato_id
and g.movgest_stato_code in ('D','N') 
and f.validita_fine is NULL
and h.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and h.movgest_ts_tipo_code='T' 
and  i.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id
and i.movgest_ts_det_tipo_code='A'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
group by d.elem_id
),
impres as (
select d.elem_id,sum(coalesce(c.movgest_ts_det_importo,0)) residui_passivi from siac_t_movgest a,siac_t_movgest_ts b,siac_t_movgest_ts_det c,
siac_r_movgest_bil_elem d,siac_d_movgest_tipo e,siac_r_movgest_ts_stato f,siac_d_movgest_stato g,
siac_d_movgest_ts_tipo h,siac_d_movgest_ts_det_tipo i
 where a.bil_id=bilancio_id
 and b.movgest_id=a.movgest_id
 and c.movgest_ts_id=b.movgest_ts_id
 and a.movgest_anno < p_anno::integer
and d.movgest_id=a.movgest_id
and e.movgest_tipo_id=a.movgest_tipo_id
and e.movgest_tipo_code='I'
and f.movgest_ts_id=b.movgest_ts_id
and f.movgest_stato_id=g.movgest_stato_id
and g.movgest_stato_code in ('D','N') 
and f.validita_fine is NULL
and h.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and h.movgest_ts_tipo_code='T' 
and  i.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id
and i.movgest_ts_det_tipo_code='I'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
group by d.elem_id
),
fon as (select a.elem_id, sum (coalesce(f.elem_det_importo,0))   as fondo
from siac_t_bil_elem a,siac_r_bil_elem_stato b, siac_d_bil_elem_stato c,
siac_r_bil_elem_categoria d,siac_d_bil_elem_categoria e,
siac_t_bil_elem_det f,siac_d_bil_elem_det_tipo g,siac_t_periodo h
where  b.elem_id=a.elem_id
and c.elem_stato_id=b.elem_stato_id
and c.elem_stato_code='VA'
and a.ente_proprietario_id=p_ente_prop_id
and b.validita_fine is NULL
and d.elem_id=a.elem_id and e.elem_cat_id=d.elem_cat_id
and e.elem_cat_code	in	('FPV','FPVCC','FPVSC')
and d.validita_fine is NULL
and f.elem_id=a.elem_id and g.elem_det_tipo_id=f.elem_det_tipo_id
and g.elem_det_tipo_code='STA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and a.bil_id=bilancio_id
and h.data_cancellazione is null
and h.periodo_id=f.periodo_id
and h.anno=p_anno
group by a.elem_id
)
select 
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.programma_id,cap.macroag_id,
coalesce(impres.residui_passivi,0) residui_passivi,
coalesce(capststa.previsioni_definitive_comp,0) previsioni_definitive_comp,
coalesce(capstsca.previsioni_definitive_cassa,0) previsioni_definitive_cassa,
coalesce(res.pagamenti_residui,0) pagamenti_residui,
coalesce(comp.pagamenti_competenza,0) pagamenti_competenza,
coalesce(rires.riaccertamenti_residui,0) riaccertamenti_residui,
coalesce(imp.impegni,0) impegni,
coalesce(fon.fondo,0) fondo
from cap
left join capststa
on cap.elem_id=capststa.elem_id
left join capstsca
on cap.elem_id=capstsca.elem_id
left join res
on cap.elem_id=res.elem_id
left join comp
on cap.elem_id=comp.elem_id
left join rires
on cap.elem_id=rires.elem_id
left join imp
on cap.elem_id=imp.elem_id
left join impres
on cap.elem_id=impres.elem_id
left join fon
on cap.elem_id=fon.elem_id
)
select 
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
coalesce(capall.residui_passivi,0)::numeric,
coalesce(capall.previsioni_definitive_comp,0)::numeric,
coalesce(capall.previsioni_definitive_cassa,0)::numeric,
coalesce(capall.pagamenti_residui,0)::numeric,
coalesce(capall.pagamenti_competenza,0)::numeric,
coalesce(capall.riaccertamenti_residui,0)::numeric,
coalesce(capall.impegni,0)::numeric,
coalesce(capall.fondo,0)::numeric,
capall.bil_ele_code3::varchar
 from clas left join capall on 
clas.programma_id = capall.programma_id and    
clas.macroag_id=capall.macroag_id) as zz
    order by zz.missione_code,zz.programma_code,zz.titusc_code,zz.macroag_code,	zz.BIL_ELE_ID
;


/*raise notice 'query: %',queryfin;
RETURN QUERY queryfin;*/



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
COST 100 ROWS 1000;