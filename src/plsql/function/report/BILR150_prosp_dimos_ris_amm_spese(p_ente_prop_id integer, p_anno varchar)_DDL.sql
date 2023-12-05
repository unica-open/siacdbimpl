/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR150_prosp_dimos_ris_amm_spese" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  pr_totale_pagam_residui numeric,
  pc_totale_pagam_competenza numeric,
  rs_totale_residui_passivi numeric,
  r_totale_riaccertamenti_residui numeric,
  i_totale_importo_impegni numeric,
  totale_importo_fpv_parte_corr numeric,
  totale_importo_fpv_cc numeric,
  disav_debito_autor_non_contr numeric
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp_int integer;
TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_movgest_tipo varchar:='A';
v_movgest_ts_tipo varchar :='T';

v_det_tipo_importo_attuale varchar:='A';
v_det_tipo_importo_iniziale varchar:='I';
v_ord_stato_code_annullato varchar:='A';
v_ord_tipo_code_incasso varchar:='I';
v_fam_titolotipologiacategoria varchar:='00003';

bilancio_id integer;

BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;  

TipoImpstanzresidui='SRI'; -- stanziamento residuo post (RS)
TipoImpstanz='STA'; -- stanziamento  (CP)
TipoImpCassa ='SCA'; ----- cassa	(CS)
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

pr_totale_pagam_residui:=0;
pc_totale_pagam_competenza:=0;
rs_totale_residui_passivi:=0;
r_totale_riaccertamenti_residui:=0;
i_totale_importo_impegni:=0;
totale_importo_fpv_parte_corr:=0;
totale_importo_fpv_cc:=0;

--SIAC-7192 20/02/2020.
--  Introdotto il calcolo dell'importo dei capitoli  
--  DDANC - DISAVANZO DERIVANTE DA DEBITO AUTORIZZATO E NON CONTRATTO 
disav_debito_autor_non_contr:=0;

RTN_MESSAGGIO:='Estrazione dei dati delle riscossioni e dei pagamenti.';
raise notice '%',RTN_MESSAGGIO;

raise notice '5 - %' , clock_timestamp()::text;

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

raise notice 'bilancio_id = %', bilancio_id;
 
return query
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
and e.classif_tipo_id=a.classif_tipo_id )
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
and e.classif_tipo_id=a.classif_tipo_id )
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
and e.classif_tipo_id=a.classif_tipo_id )
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
and e.classif_tipo_id=a.classif_tipo_id )
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
 capusc as (
select a.elem_id,  g.elem_cat_code/*,
a.elem_code ,
a.elem_desc ,
a.elem_code2 ,
a.elem_desc2 ,
a.elem_id_padre ,
a.elem_code3,
d.classif_id programma_id,d2.classif_id macroag_id */
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
and i.elem_stato_code<>'AN'
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
pagamenti_residui as (
select 
l.elem_id,sum(coalesce(m.ord_ts_det_importo,0)) pagamenti
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
and a.movgest_anno < annoCapImp_int
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
group by l.elem_id          ),
pagamenti_comp as (
select 
l.elem_id,sum(coalesce(m.ord_ts_det_importo,0)) pagamenti
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
and a.movgest_anno =annoCapImp_int
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
group by l.elem_id          ),
residui_pass as (
select d.elem_id,
sum(coalesce(c.movgest_ts_det_importo,0)) residui_passivi 
from siac_t_movgest a,siac_t_movgest_ts b,siac_t_movgest_ts_det c,
siac_r_movgest_bil_elem d,siac_d_movgest_tipo e,siac_r_movgest_ts_stato f,siac_d_movgest_stato g,
siac_d_movgest_ts_tipo h,siac_d_movgest_ts_det_tipo i
 where a.bil_id=bilancio_id
 and b.movgest_id=a.movgest_id
 and c.movgest_ts_id=b.movgest_ts_id
 and a.movgest_anno < annoCapImp_int
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
group by d.elem_id),
riacc_residui as (
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
and c.movgest_anno < annoCapImp_int
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
group by b.elem_id),
impegni as (
select d.elem_id,
sum(coalesce(c.movgest_ts_det_importo,0)) importo_impegni 
from siac_t_movgest a,siac_t_movgest_ts b,siac_t_movgest_ts_det c,
siac_r_movgest_bil_elem d,siac_d_movgest_tipo e,siac_r_movgest_ts_stato f,siac_d_movgest_stato g,
siac_d_movgest_ts_tipo h,siac_d_movgest_ts_det_tipo i
 where a.bil_id=bilancio_id
 and b.movgest_id=a.movgest_id
 and c.movgest_ts_id=b.movgest_ts_id
 and a.movgest_anno = annoCapImp_int
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
group by d.elem_id),
fpv_tit1 as (
select  
a.elem_id,
sum(d.elem_det_importo) importo_fpv_tit1
 from 
siac_t_bil_elem a, siac_d_bil_elem_tipo b,
siac_t_bil c, siac_t_periodo c2,  siac_t_bil_elem_det d, siac_d_bil_elem_det_tipo e,
siac_r_bil_elem_categoria f,siac_d_bil_elem_categoria g,siac_d_bil_elem_stato h,
siac_r_bil_elem_stato i,siac_r_bil_elem_class j,siac_r_bil_elem_class k,
siac_t_class m,siac_t_class n,
siac_d_class_tipo m2,siac_d_class_tipo n2,siac_t_periodo o
where 
a.ente_proprietario_id=p_ente_prop_id 
and 
a.elem_tipo_id=b.elem_tipo_id
and b.elem_tipo_code='CAP-UG'
and c.bil_id=a.bil_id
and c2.periodo_id=c.periodo_id
and c2.anno=p_anno
and d.elem_id=a.elem_id
and e.elem_det_tipo_id=d.elem_det_tipo_id
and e.elem_det_tipo_code='STA'
and f.elem_id=A.elem_id
and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
and g.elem_cat_id=f.elem_cat_id
and g.elem_cat_code in	('FPV','FPVC')	
and i.elem_id=A.elem_id
and h.elem_stato_id=i.elem_stato_id
and h.elem_stato_code='VA'
and j.elem_id=a.elem_id
and now() between i.validita_inizio and COALESCE(i.validita_fine,now())
and now() between j.validita_inizio and COALESCE(j.validita_fine,now())    
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and c2.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and j.data_cancellazione is null
and k.elem_id=A.elem_id
and now() between k.validita_inizio and COALESCE(k.validita_fine,now())
and m.classif_id=j.classif_id
and n.classif_id=k.classif_id
and m2.classif_tipo_id=m.classif_tipo_id
and m2.classif_tipo_code='MACROAGGREGATO'
and n2.classif_tipo_id=n.classif_tipo_id
and n2.classif_tipo_code='PROGRAMMA'
and substring(m.classif_code from 1 for 1)='1'
and o.periodo_id=d.periodo_id
and o.anno=p_anno
group by a.elem_id
 ),
 -- 03/06/2020 SIAC-7657
 -- il campo totale_importo_fpv_cc deve contenere gli importi FPV dei titoli 2 e 3
 -- e non solo il titolo 2.
 -- Per pulizia e' stato cambiato anche il nome da fpv_tit2 a fpv_tit2_3.
--fpv_tit2 as (
fpv_tit2_3 as (
select  
a.elem_id,
sum(d.elem_det_importo) importo_fpv_tit2_3
 from 
siac_t_bil_elem a, siac_d_bil_elem_tipo b,
siac_t_bil c, siac_t_periodo c2,  siac_t_bil_elem_det d, siac_d_bil_elem_det_tipo e,
siac_r_bil_elem_categoria f,siac_d_bil_elem_categoria g,siac_d_bil_elem_stato h,
siac_r_bil_elem_stato i,siac_r_bil_elem_class j,siac_r_bil_elem_class k,
siac_t_class m,siac_t_class n,
siac_d_class_tipo m2,siac_d_class_tipo n2,siac_t_periodo o
where 
a.ente_proprietario_id=p_ente_prop_id 
and 
a.elem_tipo_id=b.elem_tipo_id
and b.elem_tipo_code='CAP-UG'
and c.bil_id=a.bil_id
and c2.periodo_id=c.periodo_id
and c2.anno=p_anno
and d.elem_id=a.elem_id
and e.elem_det_tipo_id=d.elem_det_tipo_id
and e.elem_det_tipo_code='STA'
and f.elem_id=A.elem_id
and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
and g.elem_cat_id=f.elem_cat_id
and g.elem_cat_code in	('FPV','FPVC')	
and i.elem_id=A.elem_id
and h.elem_stato_id=i.elem_stato_id
and h.elem_stato_code='VA'
and j.elem_id=a.elem_id
and now() between i.validita_inizio and COALESCE(i.validita_fine,now())
and now() between j.validita_inizio and COALESCE(j.validita_fine,now())    
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and c2.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and j.data_cancellazione is null
and k.elem_id=A.elem_id
and now() between k.validita_inizio and COALESCE(k.validita_fine,now())
and m.classif_id=j.classif_id
and n.classif_id=k.classif_id
and m2.classif_tipo_id=m.classif_tipo_id
and m2.classif_tipo_code='MACROAGGREGATO'
and n2.classif_tipo_id=n.classif_tipo_id
and n2.classif_tipo_code='PROGRAMMA'
 -- 03/06/2020 SIAC-7657
 -- il campo totale_importo_fpv_cc deve contenere gli importi FPV dei titoli 2 e 3
 -- e non solo il titolo 2.
--and substring(m.classif_code from 1 for 1) = '2'
and substring(m.classif_code from 1 for 1) in('2','3')
and o.periodo_id=d.periodo_id
and o.anno=p_anno
group by a.elem_id
) ,
disav_debito_non_contr as (
select  
a.elem_id,
sum(d.elem_det_importo) importo_disavanzo
 from 
siac_t_bil_elem a, siac_d_bil_elem_tipo b,
siac_t_bil c, siac_t_periodo c2,  siac_t_bil_elem_det d, siac_d_bil_elem_det_tipo e,
siac_r_bil_elem_categoria f,siac_d_bil_elem_categoria g,siac_d_bil_elem_stato h,
siac_r_bil_elem_stato i,siac_r_bil_elem_class j,siac_r_bil_elem_class k,
siac_t_class m,siac_t_class n,
siac_d_class_tipo m2,siac_d_class_tipo n2,siac_t_periodo o
where 
a.ente_proprietario_id=p_ente_prop_id 
and 
a.elem_tipo_id=b.elem_tipo_id
and b.elem_tipo_code='CAP-UG'
and c.bil_id=a.bil_id
and c2.periodo_id=c.periodo_id
and c2.anno=p_anno
and d.elem_id=a.elem_id
and e.elem_det_tipo_id=d.elem_det_tipo_id
and e.elem_det_tipo_code='STA'
and f.elem_id=A.elem_id
and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
and g.elem_cat_id=f.elem_cat_id
and g.elem_cat_code in	('DDANC')	
and i.elem_id=A.elem_id
and h.elem_stato_id=i.elem_stato_id
and h.elem_stato_code='VA'
and j.elem_id=a.elem_id
and now() between i.validita_inizio and COALESCE(i.validita_fine,now())
and now() between j.validita_inizio and COALESCE(j.validita_fine,now())    
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and c2.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and j.data_cancellazione is null
and k.elem_id=A.elem_id
and now() between k.validita_inizio and COALESCE(k.validita_fine,now())
and m.classif_id=j.classif_id
and n.classif_id=k.classif_id
and m2.classif_tipo_id=m.classif_tipo_id
and m2.classif_tipo_code='MACROAGGREGATO'
and n2.classif_tipo_id=n.classif_tipo_id
and n2.classif_tipo_code='PROGRAMMA'
and o.periodo_id=d.periodo_id
and o.anno=p_anno
group by a.elem_id
 )   
select sum(pagamenti_residui.pagamenti) pr_totale_pagam_residui,
	sum(pagamenti_comp.pagamenti) pc_totale_pagam_competenza,
    sum(residui_pass.residui_passivi) rs_totale_residui_passivi,
    sum(riacc_residui.riaccertamenti_residui) r_totale_riaccertamenti_residui,
    sum(impegni.importo_impegni) i_totale_importo_impegni,
    sum(fpv_tit1.importo_fpv_tit1) totale_importo_fpv_parte_corr,
    sum(fpv_tit2_3.importo_fpv_tit2_3) totale_importo_fpv_cc,
    COALESCE(sum(disav_debito_non_contr.importo_disavanzo),0) disav_debito_autor_non_contr
   from capusc   	
          left join pagamenti_residui 
              on capusc.elem_id=pagamenti_residui.elem_id
          left join pagamenti_comp
              on capusc.elem_id=pagamenti_comp.elem_id
          left join residui_pass
              on capusc.elem_id=residui_pass.elem_id
          left join riacc_residui
          	  on capusc.elem_id=riacc_residui.elem_id
          left join impegni
          	  on capusc.elem_id=impegni.elem_id
          left join fpv_tit1
          	  on capusc.elem_id=fpv_tit1.elem_id 
          left join fpv_tit2_3
          	  on capusc.elem_id=fpv_tit2_3.elem_id 
          left join disav_debito_non_contr
          	  on capusc.elem_id=disav_debito_non_contr.elem_id;
  

exception
	when no_data_found THEN
		raise notice 'nessun dato trovato per le sspese.' ;
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