/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_variazione_from_capitoloentrata_total (
  _uid_capitoloentrata integer
)
RETURNS bigint AS
$body$
DECLARE total bigint;
BEGIN
	SELECT 
	coalesce(count(tb.variazione_num),0) into total
  from (
  select 
e.variazione_num
 from siac_T_bil_elem a,siac_t_bil b2,siac_t_periodo c2,
 siac_t_bil_elem_var a2,siac_r_variazione_stato d,
 siac_t_variazione e,siac_d_variazione_tipo f, siac_d_bil_elem_tipo g,
 siac_r_variazione_stato h,siac_d_variazione_stato i
  where 
 a.bil_id=b2.bil_id
 and c2.periodo_id=b2.periodo_id and
 a.elem_id=_uid_capitoloentrata--25330
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
e.variazione_num
from siac_T_bil_elem a,siac_t_bil b2,siac_t_periodo c2,
 siac_t_bil_elem_det_var a2,siac_r_variazione_stato d,
 siac_t_variazione e,siac_d_variazione_tipo f, siac_d_bil_elem_tipo g,
 siac_r_variazione_stato h,siac_d_variazione_stato i
  where 
 a.bil_id=b2.bil_id
 and c2.periodo_id=b2.periodo_id and
 a.elem_id=_uid_capitoloentrata--25330
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
) tb;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;