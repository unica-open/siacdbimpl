/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_provvedimento_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_provvedimento_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_provvedimento_total (
  _uid_provvedimento integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	select coalesce(count(*),0) into total
	from
		siac_t_atto_amm a,
		siac_d_atto_amm_tipo b,
		siac_r_atto_amm_stato c,
		siac_d_atto_amm_stato d,
		siac_r_movgest_ts_atto_amm e,
		siac_t_movgest_ts f,
		siac_t_movgest g,
		siac_d_movgest_tipo h,
		siac_d_movgest_ts_tipo i,
		siac_r_movgest_ts_stato l,
		siac_d_movgest_stato m,
		siac_t_movgest_ts_det n,
		siac_d_movgest_ts_det_tipo o,
		siac_r_movgest_class p,
		siac_t_class q,
		siac_d_class_tipo r,
		siac_t_bil s,
		siac_t_periodo t
	where b.attoamm_tipo_id=a.attoamm_tipo_id
	and c.attoamm_id=a.attoamm_id
	and d.attoamm_stato_id=c.attoamm_stato_id
	and e.attoamm_id=a.attoamm_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_id=f.movgest_id
	and h.movgest_tipo_id=g.movgest_tipo_id
	and i.movgest_ts_tipo_id=f.movgest_ts_tipo_id
	and l.movgest_ts_id=f.movgest_ts_id
	and l.movgest_stato_id=m.movgest_stato_id
	and n.movgest_ts_id=f.movgest_ts_id
	and o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id
	and p.movgest_ts_id = f.movgest_ts_id
	and q.classif_id = p.classif_id
	and r.classif_tipo_id = q.classif_tipo_id
	and s.bil_id = g.bil_id
	and t.periodo_id = s.periodo_id
	and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
	and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
	and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now())
	and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
	and a.data_cancellazione is null
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
	and t.data_cancellazione is null
	and h.movgest_tipo_code='I'
	and i.movgest_ts_tipo_code='T'
	and o.movgest_ts_det_tipo_code='A'
	and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.attoamm_id=_uid_provvedimento
	and t.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;