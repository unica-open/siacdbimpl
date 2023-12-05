/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_capitoloentrata_total (
  _ente_proprietario_id integer,
  _anno_capitolo varchar,
  _numero_capitolo varchar,
  _numero_articolo varchar,
  _numero_ueb varchar,
  _uid_titolo integer,
  _uid_tipologia integer,
  _uid_categoria integer,
  _uid_sac integer,
  _elem_tipo_code varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN
	
with capitolo as (
select c.elem_id uid,
b.anno,
c.elem_code,
c.elem_code2,
c.elem_code3,
c.elem_desc,
c.elem_desc2,
d.elem_tipo_code,
f.elem_cat_code as categoria_code,
f.elem_cat_desc as categoria_desc
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
--and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
and f.classif_id=d.classif_id
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and c.ente_proprietario_id=_ente_proprietario_id
),
tittipmac
as (
-- TITOLO TIPOLOGIA CATEGORIA 00003
select d.ente_proprietario_id, 
f.elem_id,
d.classif_id uid_categoria,
d.classif_code classif_categoria_code,d.classif_desc classif_categoria_desc,
e.classif_tipo_code,
d2.classif_id uid_tipologia,
d2.classif_code classif_tipologia_code,d2.classif_desc classif_tipologia_desc,
d3.classif_id uid_titolo,
d3.classif_code classif_titolo_code,d3.classif_desc classif_titolo_desc
 from siac_d_class_fam a, siac_t_class_fam_tree b,
siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e, 
siac_r_bil_elem_class f,
siac_t_class d2, siac_r_class_fam_tree c2,
siac_t_class d3
where 
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=b.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and a.classif_fam_code='00003'
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
and now() BETWEEN c2.validita_inizio and COALESCE(c2.validita_fine,now())
and f.classif_id=d.classif_id
and d2.classif_id=c.classif_id_padre
and d2.classif_id=c2.classif_id
and d3.classif_id=c2.classif_id_padre
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and d2.data_cancellazione is null
and d3.data_cancellazione is null
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
and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
and f.classif_id=d.classif_id
--and d2.classif_id=c.classif_id_padre
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and c.ente_proprietario_id=_ente_proprietario_id
)
select count(capitolo.*) into total
 from capitolo, sac, tittipmac, pdc
where 
capitolo.uid=sac.elem_id
and capitolo.uid=tittipmac.elem_id
and capitolo.uid=pdc.elem_id
and (_anno_capitolo IS NULL OR _anno_capitolo = capitolo.anno)
and (_numero_capitolo IS NULL OR _numero_capitolo = capitolo.elem_code)
and (_numero_articolo IS NULL OR _numero_articolo = capitolo.elem_code2)
and (_numero_ueb IS NULL OR _numero_ueb = capitolo.elem_code3)
and (_uid_titolo IS NULL OR _uid_titolo = tittipmac.uid_titolo)
and (_uid_tipologia IS NULL OR _uid_tipologia = tittipmac.uid_tipologia)
and (_uid_categoria IS NULL OR _uid_categoria = tittipmac.uid_categoria)
and (_uid_sac IS NULL OR _uid_sac = sac.sac_uid)
;
raise notice 'num %', total;
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;