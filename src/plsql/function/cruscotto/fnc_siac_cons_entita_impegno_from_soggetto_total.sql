/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_soggetto_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_soggetto_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_soggetto_total (
  _uid_soggetto integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	select coalesce(count(*),0) into total
	from
		siac_r_movgest_ts_sog z,
		siac_t_soggetto y,
		siac_t_movgest_ts f,
		siac_t_movgest g,
		siac_d_movgest_tipo h,
		siac_d_movgest_ts_tipo i,
		siac_r_movgest_ts_stato l,
		siac_d_movgest_stato m,
		siac_t_movgest_ts_det n,
		siac_d_movgest_ts_det_tipo o,
		siac_r_movgest_class a,
		siac_t_class b,
		siac_d_class_tipo c,
		siac_t_bil d,
		siac_t_periodo e
	where z.soggetto_id=y.soggetto_id
	and z.movgest_ts_id=f.movgest_ts_id
	and g.movgest_id=f.movgest_id
	and h.movgest_tipo_id=g.movgest_tipo_id
	and i.movgest_ts_tipo_id=f.movgest_ts_tipo_id
	and l.movgest_ts_id=f.movgest_ts_id
	and l.movgest_stato_id=m.movgest_stato_id
	and a.movgest_ts_id = f.movgest_ts_id
	and b.classif_id = a.classif_id
	and c.classif_tipo_id = b.classif_tipo_id
	and n.movgest_ts_id=f.movgest_ts_id
	and o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id
	and d.bil_id = g.bil_id
	and e.periodo_id = d.periodo_id
	and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now())
	and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
	and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and i.data_cancellazione is null
	and l.data_cancellazione is null
	and m.data_cancellazione is null
	and n.data_cancellazione is null
	and o.data_cancellazione is null
	and z.data_cancellazione is null
	and y.data_cancellazione is null
	and a.data_cancellazione is null
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and h.movgest_tipo_code='I'
	and i.movgest_ts_tipo_code='T'
	and o.movgest_ts_det_tipo_code='A'
	and c.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and y.soggetto_id=_uid_soggetto
	and e.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;