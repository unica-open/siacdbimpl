/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_importo (integer,varchar,varchar);

-- _filtro_crp da rinominare: e' il filtro che discrimina COMPETENZA, RESIDUO, PLURIENNALE
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa_importo (
  _uid_capitolospesa integer,
  _anno varchar,
  _filtro_crp varchar
)
RETURNS numeric AS
$body$
DECLARE
	total numeric;
BEGIN

	SELECT coalesce(sum(f.movgest_ts_det_importo),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_class m,
		siac_t_class n,
		siac_d_class_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and l.movgest_stato_id=i.movgest_stato_id
	and m.movgest_ts_id = e.movgest_ts_id
	and n.classif_id = m.classif_id
	and o.classif_tipo_id = n.classif_tipo_id
	and p.bil_id = c.bil_id
	and q.periodo_id = p.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
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
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and d.movgest_tipo_code='I'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and l.movgest_stato_code<>'A'
	and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.elem_id=_uid_capitolospesa
	and q.anno = _anno
    and (case when coalesce(_filtro_crp,'X')='R' then c.movgest_anno<_anno::integer
                     	when coalesce(_filtro_crp,'X')='C' then c.movgest_anno=_anno::integer
                        when coalesce(_filtro_crp,'X')='P' then c.movgest_anno>_anno::integer
		                else true end); -- 02.07.2018 Sofia jira siac-6193

	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;











