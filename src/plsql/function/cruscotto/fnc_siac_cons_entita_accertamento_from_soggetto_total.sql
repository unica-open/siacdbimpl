/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (
  _uid_soggetto integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	select coalesce(count(*), 0)
	into total
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
		siac_r_movgest_ts_sog m,
		siac_t_soggetto n,
		siac_r_movgest_class o,
		siac_t_class p,
		siac_d_class_tipo q,
		siac_t_bil r,
		siac_t_periodo s
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
	and m.movgest_ts_id=e.movgest_ts_id
	and n.soggetto_id=m.soggetto_id
	and o.movgest_ts_id=e.movgest_ts_id
	and p.classif_id=o.classif_id
	and q.classif_tipo_id=p.classif_tipo_id
	and r.bil_id = c.bil_id
	and s.periodo_id = r.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
	and now() BETWEEN o.validita_inizio and COALESCE(o.validita_fine,now())
	and m.data_cancellazione is null
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
	and r.data_cancellazione is null
	and s.data_cancellazione is null	
	and q.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')	
	and d.movgest_tipo_code='A'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and n.soggetto_id=_uid_soggetto
	and s.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;