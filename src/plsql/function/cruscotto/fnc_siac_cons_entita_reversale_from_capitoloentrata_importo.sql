/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop function if exists fnc_siac_cons_entita_reversale_from_capitoloentrata_importo ( integer );
drop function if exists fnc_siac_cons_entita_reversale_from_capitoloentrata_importo ( integer ,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_capitoloentrata_importo (
  _uid_capitoloentrata integer,
  _filtro_crp varchar -- 12.07.2018 Sofia jira siac-6193 C,R,altro per tutto

)
RETURNS numeric AS
$body$
DECLARE
	total numeric;
BEGIN

	SELECT coalesce(sum(i.ord_ts_det_importo),0)
	into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_ordinativo_bil_elem b,
		siac_t_ordinativo d,
		siac_d_ordinativo_tipo e,
		siac_r_ordinativo_stato f,
		siac_d_ordinativo_stato g,
		siac_t_ordinativo_ts h,
		siac_t_ordinativo_ts_det i,
		siac_d_ordinativo_ts_det_tipo j,
        siac_r_ordinativo_ts_movgest_ts rmov,
        siac_t_movgest_ts ts,
        siac_t_movgest mov
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and a.elem_id=_uid_capitoloentrata
	and b.elem_id=a.elem_id
	and d.ord_id=b.ord_id
	and e.ord_tipo_id=d.ord_tipo_id
	and e.ord_tipo_code='I'
	and f.ord_id=d.ord_id
	and g.ord_stato_id=f.ord_stato_id
	and h.ord_id = d.ord_id
	and i.ord_ts_id=h.ord_ts_id
	and j.ord_ts_det_tipo_id=i.ord_ts_det_tipo_id
	and j.ord_ts_det_tipo_code='A'
    and rmov.ord_ts_id=h.ord_ts_id
    and ts.movgest_ts_id=rmov.movgest_ts_id
    and mov.movgest_id=ts.movgest_id
    and ( case when coalesce(_filtro_crp,'')='C' then c2.anno::integer=mov.movgest_anno
      	       when coalesce(_filtro_crp,'')='R' then mov.movgest_anno<c2.anno::integer
                    else true end )
	and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and b.data_cancellazione is null
	and d.data_cancellazione is null
	and b2.data_cancellazione is null
	and c2.data_cancellazione is null
	and e.data_cancellazione is null
	and h.data_cancellazione is null
    and rmov.data_cancellazione is null
    and now() BETWEEN rmov.validita_inizio and COALESCE(rmov.validita_fine,now())
    and ts.data_cancellazione is null
    and now() BETWEEN ts.validita_inizio and COALESCE(ts.validita_fine,now())
    and mov.data_cancellazione is null
    and now() BETWEEN mov.validita_inizio and COALESCE(mov.validita_fine,now());

	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;