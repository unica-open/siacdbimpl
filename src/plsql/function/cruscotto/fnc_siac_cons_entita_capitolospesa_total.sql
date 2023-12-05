/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_capitolospesa_total (
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
  _elem_tipo_code varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
    query text;
BEGIN
	
query := 'with capitolo as (
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
and d.elem_tipo_code = '''||_elem_tipo_code||''' 
and e.elem_id = c.elem_id
and f.elem_cat_id=e.elem_cat_id
and c.ente_proprietario_id='||_ente_proprietario_id||' 
and now() BETWEEN e.validita_inizio and coalesce (e.validita_fine,now())
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
AND f.data_cancellazione is null';

if _anno_capitolo IS not NULL then 
query:=query||' and b.anno='''||_anno_capitolo||'''';
end if;


if _numero_capitolo IS not NULL then 
query:=query||' and c.elem_code='''||_numero_capitolo||'''';
end if;


if _numero_articolo IS not NULL then 
query:=query||' and c.elem_code2='''||_numero_articolo||'''';
end if;


if _numero_ueb IS not NULL then 
query:=query||' and c.elem_code3='''||_numero_ueb||'''';
end if;

query:=query||'),
sac as (
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
and a.classif_fam_code=''00005''
and now() BETWEEN f.validita_inizio and coalesce (f.validita_fine,now())
and f.classif_id=d.classif_id
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and c.ente_proprietario_id='||_ente_proprietario_id;

if _uid_sac IS not NULL then 
query:=query||' and d.classif_id='||_uid_sac;
end if;

query:=query||'
),
programma as (
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
and a.classif_fam_code=''00001''
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
and c.ente_proprietario_id='||_ente_proprietario_id||'
),
macroaggregato as (
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
and a.classif_fam_code=''00002''
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
and c.ente_proprietario_id='||_ente_proprietario_id;

if _uid_titolo IS not NULL then 
query:=query||' and d2.classif_id='||_uid_titolo;
end if;

if _uid_macroaggregato IS not NULL then 
query:=query||' and  d.classif_id='||_uid_macroaggregato;
end if;


query:=query||'
)
,
pdc as (
select d.ente_proprietario_id, f.elem_id,
d.classif_code classif_pdc_code,d.classif_desc classif_pdc_desc,
e.classif_tipo_code
 from siac_d_class_fam a, siac_t_class_fam_tree b,
siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e, siac_r_bil_elem_class f
where 
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=b.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and a.classif_fam_code=''00008''
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and now() BETWEEN c.validita_inizio and coalesce (c.validita_fine,now())
and now() BETWEEN f.validita_inizio and coalesce (f.validita_fine,now())
and f.classif_id=d.classif_id
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
and f.data_cancellazione is null
and c.ente_proprietario_id='||_ente_proprietario_id||'
)
select count(capitolo.*) 
 from capitolo, sac, programma, macroaggregato,pdc
where capitolo.uid=sac.elem_id
and capitolo.uid=programma.elem_id
and capitolo.uid=macroaggregato.elem_id
and capitolo.uid=pdc.elem_id';

/*with capitolo as (
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
and now() BETWEEN e.validita_inizio and coalesce (e.validita_fine,now())
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
AND f.data_cancellazione is null
),
sac as (
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
)
select count(capitolo.*) into total
 from capitolo, sac, programma, macroaggregato,pdc
where capitolo.uid=sac.elem_id
and capitolo.uid=programma.elem_id
and capitolo.uid=macroaggregato.elem_id
and capitolo.uid=pdc.elem_id
and (_anno_capitolo IS NULL OR _anno_capitolo = capitolo.anno)
and (_numero_capitolo IS NULL OR _numero_capitolo = capitolo.elem_code)
and (_numero_articolo IS NULL OR _numero_articolo = capitolo.elem_code2)
and (_numero_ueb IS NULL OR _numero_ueb = capitolo.elem_code3)
and (_uid_titolo IS NULL OR _uid_titolo = macroaggregato.titolo_uid)
and (_uid_macroaggregato IS NULL OR _uid_macroaggregato = macroaggregato.macroaggregato_uid)
and (_uid_sac IS NULL OR _uid_sac = sac.sac_uid)
;*/
execute query into total;

	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;