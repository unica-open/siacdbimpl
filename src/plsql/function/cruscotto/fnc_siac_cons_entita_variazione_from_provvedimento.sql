/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_variazione_from_provvedimento (
  _uid_provvedimento integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  variazione_num integer,
  variazione_desc varchar,
  variazione_applicazione varchar,
  variazione_tipo_code varchar,
  variazione_tipo_desc varchar,
  variazione_stato_tipo_code varchar,
  variazione_stato_tipo_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar
) AS
$body$
DECLARE
_offset INTEGER := (_page) * _limit;
rec record;    
v_attoamm_id integer;    
BEGIN

for rec in   
--variazione codifica
select e.variazione_id
, e.variazione_num,e.variazione_desc,
	CASE
			WHEN g.elem_tipo_code LIKE '%G' THEN 'GESTIONE'::VARCHAR
			WHEN g.elem_tipo_code LIKE '%P' THEN 'PREVISIONE'::VARCHAR
			ELSE '?'::VARCHAR
		END AS variazione_applicazione,
f.variazione_tipo_code,f.variazione_tipo_desc,
i.variazione_stato_tipo_code,
i.variazione_stato_tipo_desc,  
d.attoamm_id
 from siac_T_bil_elem a,siac_t_bil b2,siac_t_periodo c2,
 siac_t_bil_elem_var a2,siac_r_variazione_stato d,
 siac_t_variazione e,siac_d_variazione_tipo f, siac_d_bil_elem_tipo g,
 siac_r_variazione_stato h,siac_d_variazione_stato i
  where 
 a.bil_id=b2.bil_id
 and c2.periodo_id=b2.periodo_id
 --a.elem_id=_uid_capitolospesa--25330
 and d.attoamm_id=_uid_provvedimento
and a.elem_id=a2.elem_id
and d.variazione_stato_id=a2.variazione_stato_id
and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
and e.variazione_id=d.variazione_id
and f.variazione_tipo_id=e.variazione_tipo_id
and g.elem_tipo_id=a.elem_tipo_id
and h.variazione_id=e.variazione_id
and i.variazione_stato_tipo_id=h.variazione_stato_tipo_id
and now() BETWEEN h.validita_inizio and COALESCE(h.validita_fine,now())
and a.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and a2.data_cancellazione is null
and b2.data_cancellazione is null
and c2.data_cancellazione is null
union
select 
e.variazione_id,
e.variazione_num,e.variazione_desc,
	CASE
			WHEN g.elem_tipo_code LIKE '%G' THEN 'GESTIONE'::VARCHAR
			WHEN g.elem_tipo_code LIKE '%P' THEN 'PREVISIONE'::VARCHAR
			ELSE '?'::VARCHAR
		END AS variazione_applicazione,
f.variazione_tipo_code,f.variazione_tipo_desc,
i.variazione_stato_tipo_code,
i.variazione_stato_tipo_desc,  
d.attoamm_id
 from siac_T_bil_elem a,siac_t_bil b2,siac_t_periodo c2,
 siac_t_bil_elem_det_var a2,siac_r_variazione_stato d,
 siac_t_variazione e,siac_d_variazione_tipo f, siac_d_bil_elem_tipo g,
 siac_r_variazione_stato h,siac_d_variazione_stato i
  where 
 a.bil_id=b2.bil_id
 and c2.periodo_id=b2.periodo_id and
-- a.elem_id=_uid_capitolospesa
  d.attoamm_id=_uid_provvedimento
and a.elem_id=a2.elem_id
and d.variazione_stato_id=a2.variazione_stato_id
and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
and e.variazione_id=d.variazione_id
and f.variazione_tipo_id=e.variazione_tipo_id
and g.elem_tipo_id=a.elem_tipo_id
and h.variazione_id=e.variazione_id
and i.variazione_stato_tipo_id=h.variazione_stato_tipo_id
and now() BETWEEN h.validita_inizio and COALESCE(h.validita_fine,now())
and a.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and a2.data_cancellazione is null
and b2.data_cancellazione is null
and c2.data_cancellazione is null
order by 2
LIMIT _limit
OFFSET _offset
loop
 

uid:=rec.variazione_id;
variazione_num:=rec.variazione_num;
variazione_desc:=rec.variazione_desc;
variazione_applicazione:=rec.variazione_applicazione;
variazione_tipo_code:=rec.variazione_tipo_code;
variazione_tipo_desc:=rec.variazione_tipo_desc;
variazione_stato_tipo_code:=rec.variazione_stato_tipo_code;
variazione_stato_tipo_desc:=rec.variazione_stato_tipo_desc;
v_attoamm_id:=rec.attoamm_id;

select 
q.attoamm_numero,q.attoamm_anno,
t.attoamm_stato_desc,
r.attoamm_tipo_code,r.attoamm_tipo_desc
into 
attoamm_numero,attoamm_anno,
attoamm_stato_desc,
attoamm_tipo_code,attoamm_tipo_desc
 from 
siac_t_atto_amm q,siac_d_atto_amm_tipo r,
siac_r_atto_amm_stato s, siac_d_atto_amm_stato t
where q.attoamm_id=v_attoamm_id
and r.attoamm_tipo_id=q.attoamm_tipo_id
and s.attoamm_id=q.attoamm_id
and t.attoamm_stato_id=s.attoamm_stato_id
and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
and q.data_cancellazione is null
and r.data_cancellazione is null
and s.data_cancellazione is null
and t.data_cancellazione is null;

--sac
select 
y.classif_code,y.classif_desc
into 
attoamm_sac_code,
  attoamm_sac_desc
from  siac_r_atto_amm_class z,
siac_t_class y, siac_d_class_tipo x
where z.classif_id=y.classif_id
and x.classif_tipo_id=y.classif_tipo_id
and x.classif_tipo_code  IN ('CDC', 'CDR')
and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
and z.data_cancellazione is NULL
and x.data_cancellazione is NULL
and y.data_cancellazione is NULL
and z.attoamm_id=v_attoamm_id
;


return next;

end loop;

return;    

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;