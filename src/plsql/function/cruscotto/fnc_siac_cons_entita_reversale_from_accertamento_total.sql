/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_accertamento_total (
  _uid_accertamento integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0)
	into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_ordinativo_bil_elem b,
		siac_t_ordinativo d,
		siac_d_ordinativo_tipo e,
		siac_r_ordinativo_ts_movgest_ts f,
		siac_t_ordinativo_ts g,
		siac_t_movgest_ts h,
		siac_r_ordinativo_stato i,
		siac_d_ordinativo_stato l
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and b.elem_id=a.elem_id
	and d.ord_id=b.ord_id
	and e.ord_tipo_id=d.ord_tipo_id
	and e.ord_tipo_code='I'
	and f.ord_ts_id=g.ord_ts_id
	and g.ord_id=d.ord_id
	and h.movgest_ts_id=f.movgest_ts_id
	and h.movgest_id=_uid_accertamento
	and i.ord_id=d.ord_id
	and l.ord_stato_id=i.ord_stato_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and b.data_cancellazione is null
	and d.data_cancellazione is null
	and b2.data_cancellazione is null
	and c2.data_cancellazione is null
	and e.data_cancellazione is null
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and i.data_cancellazione is null
	and l.data_cancellazione is null;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;