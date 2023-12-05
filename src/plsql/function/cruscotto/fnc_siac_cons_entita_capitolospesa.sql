/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_capitolospesa (
  _ente_proprietario_id integer,
  _anno_capitolo varchar,
  _numero_capitolo varchar,
  _numero_articolo varchar,
  _numero_ueb varchar,
  _uid_titolo integer,
  _uid_tipologia integer,
  _uid_categoria integer,
  _uid_macroaggregato integer,
  _uid_sac integer,
  _elem_tipo_code varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  capitolo_ueb varchar,
  capitolo_desc varchar,
  articolo_desc varchar,
  elem_tipo_code varchar,
  categoria_code varchar,
  categoria_desc varchar,
  classif_programma_code varchar,
  classif_programma_desc varchar,
  classif_macr_code varchar,
  classif_macr_desc varchar,
  classif_missione_code varchar,
  classif_missione_desc varchar,
  classif_titolo_code varchar,
  classif_titolo_desc varchar,
  classif_sac_code varchar,
  classif_sac_desc varchar,
  classif_pdc_code varchar,
  classif_pdc_desc varchar,
  stanziamento numeric,
  stanziamento_residuo numeric,
  stanziamento_cassa numeric,
  stanziamento_var numeric,
  stanziamento_res_var numeric,
  stanziamento_cassa_var numeric
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN
	RETURN QUERY
    with
    capitoli as
    (
	with capitolo as (
select
c.elem_id uid,
b.anno,
c.elem_code,
c.elem_code2,
c.elem_code3,
c.elem_desc,
c.elem_desc2,
d.elem_tipo_code,
f.elem_cat_code,
f.elem_cat_desc
from siac_t_bil a,
siac_t_periodo b, siac_t_bil_elem c,siac_d_bil_elem_tipo d,
siac_r_bil_elem_categoria e,
siac.siac_d_bil_elem_categoria f
where
a.periodo_id=b.periodo_id
AND c.bil_id=a.bil_id
and d.elem_tipo_id=c.elem_tipo_id
and d.elem_tipo_code = _elem_tipo_code
and e.elem_id = c.elem_id
and f.elem_cat_id=e.elem_cat_id
and c.ente_proprietario_id=_ente_proprietario_id
and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
AND f.data_cancellazione is null
),
sac as (
--SAC
select d.ente_proprietario_id, f.elem_id,
d.classif_id sac_uid,
d.classif_code classif_sac_code,d.classif_desc classif_sac_desc,
e.classif_tipo_code
 from siac_d_class_fam a, siac_t_class_fam_tree b,
siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e, siac_r_bil_elem_class f
where
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=b.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and a.classif_fam_code='00005'
--and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
--and now() BETWEEN c.validita_inizio and coalesce (c.validita_fine,now())
and now() BETWEEN f.validita_inizio and coalesce (f.validita_fine,now())
and f.classif_id=d.classif_id
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and c.ente_proprietario_id=_ente_proprietario_id
),
programma as (
--MISSIONE-PROGRAMMA 00001
select d.ente_proprietario_id, f.elem_id,
d.classif_id uid_programma,
d.classif_code classif_programma_code,d.classif_desc classif_programma_desc,
e.classif_tipo_code,
d2.classif_id uid_missione,
d2.classif_code classif_missione_code,d2.classif_desc classif_missione_desc
 from siac_d_class_fam a, siac_t_class_fam_tree b,
siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e, siac_r_bil_elem_class f,
siac_t_class d2
where
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=b.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and a.classif_fam_code='00001'
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and now() BETWEEN c.validita_inizio and coalesce (c.validita_fine,now())
and now() BETWEEN f.validita_inizio and coalesce (f.validita_fine,now())
and f.classif_id=d.classif_id
and d2.classif_id=c.classif_id_padre
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and d2.data_cancellazione is null
and c.ente_proprietario_id=_ente_proprietario_id
),
macroaggregato as (
--TITOLO-MACROAGGREGATO spesa 00002
select d.ente_proprietario_id, f.elem_id,
d.classif_id macroaggregato_uid,
d.classif_code classif_macr_code,d.classif_desc classif_macr_desc,
e.classif_tipo_code,
d2.classif_id titolo_uid,
d2.classif_code classif_titolo_code,d2.classif_desc classif_titolo_desc
 from siac_d_class_fam a, siac_t_class_fam_tree b,
siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e, siac_r_bil_elem_class f,
siac_t_class d2
where
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=b.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and a.classif_fam_code='00002'
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and now() BETWEEN c.validita_inizio and coalesce (c.validita_fine,now())
and now() BETWEEN f.validita_inizio and coalesce (f.validita_fine,now())
and f.classif_id=d.classif_id
and d2.classif_id=c.classif_id_padre
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and d2.data_cancellazione is null
and c.ente_proprietario_id=_ente_proprietario_id
)
,
pdc as (
--piano dei conti 00008
select d.ente_proprietario_id, f.elem_id,
d.classif_code classif_pdc_code,d.classif_desc classif_pdc_desc,
e.classif_tipo_code
--,d2.classif_code classif_titolo_code,d2.classif_desc classif_titolo_desc
 from siac_d_class_fam a, siac_t_class_fam_tree b,
siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e, siac_r_bil_elem_class f
--,siac_t_class d2
where
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=b.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and a.classif_fam_code='00008'
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and now() BETWEEN c.validita_inizio and coalesce (c.validita_fine,now())
and now() BETWEEN f.validita_inizio and coalesce (f.validita_fine,now())
and f.classif_id=d.classif_id
--and d2.classif_id=c.classif_id_padre
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and c.ente_proprietario_id=_ente_proprietario_id
),
/*stanzanno1 as (
select a2.elem_id, sum (a2.elem_det_importo) as stanziamento_anno1
 from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
 siac_t_bil d2,siac_t_periodo e2, siac_t_periodo a3
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STA'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a3.periodo_id=a2.periodo_id
--annoimporto=annobilancio
and e2.anno=a3.anno
group by a2.elem_id
)*/
-- 07.04.2017 Sofia JIRA-SIAC-4669
stanzanno1 as (
select a2.elem_id, sum (a2.elem_det_importo) as stanziamento_anno1
from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
     siac_t_bil d2,siac_t_periodo e2
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STA'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a2.periodo_id=e2.periodo_id
group by a2.elem_id
),
/*stanzanno2 as (
select a2.elem_id, sum (a2.elem_det_importo) as stanziamento_anno2
 from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
 siac_t_bil d2,siac_t_periodo e2, siac_t_periodo a3
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STA'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a3.periodo_id=a2.periodo_id
--annoimporto=annobilancio+1
and e2.anno::integer+1=a3.anno::integer
group by a2.elem_id
)
,
stanzanno3 as (
select a2.elem_id, sum (a2.elem_det_importo) as stanziamento_anno3
 from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
 siac_t_bil d2,siac_t_periodo e2, siac_t_periodo a3
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STA'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a3.periodo_id=a2.periodo_id
--annoimporto=annobilancio+2
and e2.anno::integer+2=a3.anno::integer
group by a2.elem_id
)
,
stanzresiduoanno1 as (
select a2.elem_id, sum (a2.elem_det_importo) as stanziamento_residuo_anno1
 from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
 siac_t_bil d2,siac_t_periodo e2, siac_t_periodo a3
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STR'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a3.periodo_id=a2.periodo_id
--annoimporto=annobilancio
and e2.anno=a3.anno
group by a2.elem_id
)*/ -- 07.04.2017 Sofia JIRA-SIAC-4669
stanzresiduoanno1 as (
select a2.elem_id, sum (a2.elem_det_importo) as stanziamento_residuo_anno1
from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
     siac_t_bil d2,siac_t_periodo e2
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STR'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a2.periodo_id=e2.periodo_id
group by a2.elem_id
)
,
/*
stanzcassaanno1 as (
select a2.elem_id, sum (a2.elem_det_importo) as stanziamento_cassa_anno1
 from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
 siac_t_bil d2,siac_t_periodo e2, siac_t_periodo a3
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STR'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a3.periodo_id=a2.periodo_id
--annoimporto=annobilancio
and e2.anno=a3.anno
group by a2.elem_id
)*/ -- 07.04.2017 Sofia JIRA-SIAC-4669
stanzcassaanno1 as (
select a2.elem_id, sum (a2.elem_det_importo) as stanziamento_cassa_anno1
from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
     siac_t_bil d2,siac_t_periodo e2
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='SCA'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a2.periodo_id=e2.periodo_id
group by a2.elem_id
)
select capitolo.uid,
capitolo.anno as capitolo_anno,
capitolo.elem_code as capitolo_numero,
capitolo.elem_code2 as capitolo_articolo,
capitolo.elem_code3 as capitolo_ueb,
capitolo.elem_desc as capitolo_desc,
capitolo.elem_desc2 as articolo_desc,
capitolo.elem_tipo_code,
capitolo.elem_cat_code as categoria_code,
capitolo.elem_cat_desc as categoria_desc,
programma.classif_programma_code,
programma.classif_programma_desc,
macroaggregato.classif_macr_code,
macroaggregato.classif_macr_desc,
programma.classif_missione_code,
programma.classif_missione_desc,
macroaggregato.classif_titolo_code,
macroaggregato.classif_titolo_desc,
sac.classif_sac_code,
sac.classif_sac_desc,
pdc.classif_pdc_code,
pdc.classif_pdc_desc,
stanzanno1.stanziamento_anno1 stanziamento,
--stanzanno2.stanziamento_anno2,
--stanzanno3.stanziamento_anno3,
stanzresiduoanno1.stanziamento_residuo_anno1 stanziamento_residuo, -- 07.04.2017 Sofia JIRA-SIAC-4669
stanzcassaanno1.stanziamento_cassa_anno1     stanziamento_cassa    -- 07.04.2017 Sofia JIRA-SIAC-4669
from capitolo, sac, programma, macroaggregato,pdc, stanzanno1,-- stanzanno2, stanzanno3,
     stanzresiduoanno1,
	 stanzcassaanno1
where capitolo.uid=sac.elem_id
and capitolo.uid=programma.elem_id
and capitolo.uid=macroaggregato.elem_id
and capitolo.uid=pdc.elem_id
and capitolo.uid=stanzanno1.elem_id
--and capitolo.uid=stanzanno2.elem_id
--and capitolo.uid=stanzanno3.elem_id
and capitolo.uid=stanzresiduoanno1.elem_id
and capitolo.uid=stanzcassaanno1.elem_id
and (_anno_capitolo IS NULL OR _anno_capitolo = capitolo.anno)
and (_numero_capitolo IS NULL OR _numero_capitolo = capitolo.elem_code)
and (_numero_articolo IS NULL OR _numero_articolo = capitolo.elem_code2)
and (_numero_ueb IS NULL OR _numero_ueb = capitolo.elem_code3)
and (_uid_titolo IS NULL OR _uid_titolo = macroaggregato.titolo_uid)
--and (_uid_tipologia IS NULL OR _uid_tipologia = tc_titolo.classif_id)
--and (_uid_categoria IS NULL OR _uid_categoria = tc_titolo.classif_id)
and (_uid_macroaggregato IS NULL OR _uid_macroaggregato = macroaggregato.macroaggregato_uid)
and (_uid_sac IS NULL OR _uid_sac = sac.sac_uid)
order by 2,3,4,5
),
variazioni
as
(with
 varBozza as
 (select var.variazione_id, r.variazione_stato_id
  from siac_t_variazione var, siac_r_variazione_stato r,siac_d_variazione_stato stato
  where   r.variazione_id=var.variazione_id
  and   stato.variazione_stato_tipo_id=r.variazione_stato_tipo_id
  and   stato.variazione_stato_tipo_code='B'
  and   now() BETWEEN var.validita_inizio and COALESCE(var.validita_fine,now())
  and   now() BETWEEN r.validita_inizio and COALESCE(r.validita_fine,now())
  and   var.data_cancellazione is null
  and   r.data_cancellazione is null
 ),
 varBozzaComp as
 (select e.elem_id,detvar.variazione_stato_id,
         sum(detvar.elem_det_importo) stanziamento_var
  from  siac_t_bil bil, siac_t_periodo per,siac_t_bil_elem e,
        siac_t_bil_elem_det_var detvar, siac_d_bil_elem_det_tipo tipodet
  where per.periodo_id=bil.periodo_id
  and   detvar.periodo_id=per.periodo_id
  and   tipodet.elem_det_tipo_id=detvar.elem_det_tipo_id
  and   tipodet.elem_det_tipo_code in ('STA')
  and   e.elem_id=detvar.elem_id
  and   now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
  and   now() BETWEEN detvar.validita_inizio and COALESCE(detvar.validita_fine,now())
  and   e.data_cancellazione is null
  and   detvar.data_cancellazione is null
  group by e.elem_id,detvar.variazione_stato_id
 ),
 varBozzaRes as
 (select e.elem_id,detvar.variazione_stato_id,
         sum(detvar.elem_det_importo) stanziamento_res_var
  from  siac_t_bil bil, siac_t_periodo per,siac_t_bil_elem e,
        siac_t_bil_elem_det_var detvar, siac_d_bil_elem_det_tipo tipodet
  where per.periodo_id=bil.periodo_id
  and   detvar.periodo_id=per.periodo_id
  and   tipodet.elem_det_tipo_id=detvar.elem_det_tipo_id
  and   tipodet.elem_det_tipo_code in ('STR')
  and   e.elem_id=detvar.elem_id
  and   now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
  and   now() BETWEEN detvar.validita_inizio and COALESCE(detvar.validita_fine,now())
  and   e.data_cancellazione is null
  and   detvar.data_cancellazione is null
  group by e.elem_id,detvar.variazione_stato_id
  ),
  varBozzaCassa as
  (select e.elem_id,detvar.variazione_stato_id,
  	      sum(detvar.elem_det_importo) stanziamento_cassa_var
   from  siac_t_bil bil, siac_t_periodo per,siac_t_bil_elem e,
         siac_t_bil_elem_det_var detvar, siac_d_bil_elem_det_tipo tipodet
   where per.periodo_id=bil.periodo_id
   and   detvar.periodo_id=per.periodo_id
   and   tipodet.elem_det_tipo_id=detvar.elem_det_tipo_id
   and   tipodet.elem_det_tipo_code in ('SCA')
   and   e.elem_id=detvar.elem_id
   and   now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
   and   now() BETWEEN detvar.validita_inizio and COALESCE(detvar.validita_fine,now())
   and   e.data_cancellazione is null
   and   detvar.data_cancellazione is null
   group by e.elem_id,detvar.variazione_stato_id
  )
  select varBozzaComp.elem_id,
         sum(varBozzaComp.stanziamento_var) stanziamento_var,
         sum(varBozzaRes.stanziamento_res_var) stanziamento_res_var,
         sum(varBozzaCassa.stanziamento_cassa_var) stanziamento_cassa_var
  from varBozzaComp, varBozzaRes, varBozzaCassa,varBozza
  where   varBozzaComp.variazione_stato_id=varBozza.variazione_stato_id
  and     varBozzaComp.elem_id=varBozzaRes.elem_id
  and     varBozzaComp.variazione_stato_id=varBozzaRes.variazione_stato_id
  and     varBozzaComp.elem_id=varBozzaCassa.elem_id
  and     varBozzaComp.variazione_stato_id=varBozzaCassa.variazione_stato_id
  group by varBozzaComp.elem_id
)
select capitoli.uid,
capitoli.capitolo_anno,
capitoli.capitolo_numero,
capitoli.capitolo_articolo,
capitoli.capitolo_ueb,
capitoli.capitolo_desc,
capitoli.articolo_desc,
capitoli.elem_tipo_code,
capitoli.categoria_code,
capitoli.categoria_desc,
capitoli.classif_programma_code,
capitoli.classif_programma_desc,
capitoli.classif_macr_code,
capitoli.classif_macr_desc,
capitoli.classif_missione_code,
capitoli.classif_missione_desc,
capitoli.classif_titolo_code,
capitoli.classif_titolo_desc,
capitoli.classif_sac_code,
capitoli.classif_sac_desc,
capitoli.classif_pdc_code,
capitoli.classif_pdc_desc,
capitoli.stanziamento,
capitoli.stanziamento_residuo, -- 07.04.2017 Sofia JIRA-SIAC-4669
capitoli.stanziamento_cassa ,
coalesce(variazioni.stanziamento_var,0),
coalesce(variazioni.stanziamento_res_var,0),
coalesce(variazioni.stanziamento_cassa_var,0)
from capitoli left outer join variazioni on ( capitoli.uid=variazioni.elem_id)
order by 2,3,4,5
LIMIT _limit
OFFSET _offset;

/*DECLARE
	_offset INTEGER := (_page) * _limit;
    capitolo record;

    sql_query text;
    stanziamento_anno1 numeric;
    stanziamento_anno2 numeric;
    stanziamento_anno3 numeric;
    stanziamento_residuo_anno1 numeric;
    stanziamento_cassa_anno1 numeric;
    el_id1 integer;
    el_id2 integer;
    el_id3 integer;
    el_res_id1 integer;
    el_cas_id1 integer;
BEGIN
sql_query:='select
c.elem_id uid,b.anno,c.elem_code,c.elem_code2,c.elem_code3,c.elem_desc,c.elem_desc2,
d.elem_tipo_code,f.elem_cat_code,f.elem_cat_desc
from siac_t_bil a,siac_t_periodo b, siac_t_bil_elem c,siac_d_bil_elem_tipo d,
siac_r_bil_elem_categoria e,siac.siac_d_bil_elem_categoria f
where
a.periodo_id=b.periodo_id
AND c.bil_id=a.bil_id
and d.elem_tipo_id=c.elem_tipo_id
and e.elem_id = c.elem_id
and f.elem_cat_id=e.elem_cat_id
and now() between e.validita_inizio and coalesce(e.validita_fine,now())
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
AND f.data_cancellazione is null
and c.ente_proprietario_id= '||_ente_proprietario_id||' and d.elem_tipo_code = '''
||_elem_tipo_code||'''';

if _anno_capitolo is not null THEN
sql_query:=sql_query||' and b.anno='''||_anno_capitolo||'''';
end if;

if _numero_capitolo is not null THEN
sql_query:=sql_query||' and c.elem_code='''||_numero_capitolo||'''';
end if;

if _numero_articolo is not null THEN
sql_query:=sql_query||' and c.elem_code2='''||_numero_articolo||'''';
end if;

if _numero_ueb is not null THEN
sql_query:=sql_query||' and c.elem_code3='''||_numero_ueb||'''';
end if;

if    _limit is not null THEN
sql_query:=sql_query||' LIMIT '||_limit;
end if;

if    _offset is not null THEN
sql_query:=sql_query||' OFFSET '||_offset;
end if;


raise notice '%',sql_query;
for capitolo IN
EXECUTE sql_query
loop

--elementi capitolo
uid:=capitolo.uid;
capitolo_anno:=capitolo.anno;
capitolo_numero:=capitolo.elem_code;
capitolo_articolo:=capitolo.elem_code2;
capitolo_ueb:=capitolo.elem_code3;
capitolo_desc:=capitolo.elem_desc;
articolo_desc:=capitolo.elem_desc2;
elem_tipo_code:=capitolo.elem_tipo_code;
categoria_code:=capitolo.elem_cat_code;
categoria_desc:=capitolo.elem_cat_desc;



--sac
select
d.classif_code ,d.classif_desc into classif_sac_code,classif_sac_desc
 from siac_d_class_fam a, siac_t_class_fam_tree b,
siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e, siac_r_bil_elem_class f
where
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=b.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and a.classif_fam_code='00005'
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and f.classif_id=d.classif_id
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and f.elem_id=capitolo.uid;



--MISSIONE-PROGRAMMA 00001

select
d.classif_code ,d.classif_desc ,
d2.classif_code ,d2.classif_desc
into
classif_programma_code,classif_programma_desc,classif_missione_code,classif_missione_desc
 from siac_d_class_fam a, siac_t_class_fam_tree b,
siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e, siac_r_bil_elem_class f,
siac_t_class d2
where
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=b.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and a.classif_fam_code='00001'
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and f.classif_id=d.classif_id
and d2.classif_id=c.classif_id_padre
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and d2.data_cancellazione is null
and  f.elem_id=capitolo.uid;

--TITOLO-MACROAGGREGATO spesa 00002

select
d.classif_code ,d.classif_desc ,
d2.classif_code ,d2.classif_desc
into
classif_macr_code,classif_macr_desc,classif_titolo_code,classif_titolo_desc
 from siac_d_class_fam a, siac_t_class_fam_tree b,
siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e, siac_r_bil_elem_class f,
siac_t_class d2
where
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=b.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and a.classif_fam_code='00002'
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and f.classif_id=d.classif_id
and d2.classif_id=c.classif_id_padre
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and d2.data_cancellazione is null
and  f.elem_id=capitolo.uid;

--piano dei conti 00008

select
d.classif_code,d.classif_desc into classif_pdc_code,classif_pdc_desc
 from siac_d_class_fam a, siac_t_class_fam_tree b,
siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e, siac_r_bil_elem_class f
where
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=b.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and a.classif_fam_code='00008'
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and f.classif_id=d.classif_id
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and  f.elem_id=capitolo.uid;


--stanzanno1 as (
select a2.elem_id, sum (a2.elem_det_importo) into el_id1, stanziamento_anno1
 from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
 siac_t_bil d2,siac_t_periodo e2, siac_t_periodo a3
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STA'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a3.periodo_id=a2.periodo_id
and e2.anno=a3.anno
and a2.elem_id=capitolo.uid
group by a2.elem_id;

--stanzanno2 as (
select a2.elem_id, sum (a2.elem_det_importo) into el_id2, stanziamento_anno2
 from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
 siac_t_bil d2,siac_t_periodo e2, siac_t_periodo a3
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STA'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a3.periodo_id=a2.periodo_id
--annoimporto=annobilancio+1
and e2.anno::integer+1=a3.anno::integer
and a2.elem_id=capitolo.uid
group by a2.elem_id;

--stanzanno3 as (
select a2.elem_id, sum (a2.elem_det_importo) into el_id3, stanziamento_anno3
 from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
 siac_t_bil d2,siac_t_periodo e2, siac_t_periodo a3
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STA'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a3.periodo_id=a2.periodo_id
--annoimporto=annobilancio+2
and e2.anno::integer+2=a3.anno::integer
and a2.elem_id=capitolo.uid
group by a2.elem_id;


--stanzresiduoanno1 as (
select a2.elem_id, sum (a2.elem_det_importo) into el_res_id1, stanziamento_residuo_anno1
 from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
 siac_t_bil d2,siac_t_periodo e2, siac_t_periodo a3
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STR'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a3.periodo_id=a2.periodo_id
--annoimporto=annobilancio
and e2.anno=a3.anno
and a2.elem_id=capitolo.uid
group by a2.elem_id;

--stanzcassaanno1 as (
select a2.elem_id, sum (a2.elem_det_importo) into  el_cas_id1, stanziamento_cassa_anno1
 from siac_t_bil_elem_det a2,siac_d_bil_elem_det_tipo b2, siac_t_bil_elem c2,
 siac_t_bil d2,siac_t_periodo e2, siac_t_periodo a3
where b2.elem_det_tipo_id=a2.elem_det_tipo_id
and b2.elem_det_tipo_code='STR'
and c2.elem_id=a2.elem_id
and c2.bil_id=d2.bil_id
and d2.periodo_id=e2.periodo_id
and a3.periodo_id=a2.periodo_id
--annoimporto=annobilancio
and e2.anno=a3.anno
and a2.elem_id=capitolo.uid
group by a2.elem_id;

return next;
end loop;

return;*/

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;