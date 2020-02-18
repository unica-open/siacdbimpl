/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_provvedimento_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_provvedimento_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_provvedimento_total (
  _uid_provvedimento integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total BIGINT;
BEGIN
			
	SELECT COALESCE(COUNT(*),0) INTO total
	FROM siac_t_atto_amm a,
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
	WHERE b.attoamm_tipo_id=a.attoamm_tipo_id
	AND c.attoamm_id=a.attoamm_id
	AND d.attoamm_stato_id=c.attoamm_stato_id
	AND e.attoamm_id=a.attoamm_id
	AND f.movgest_ts_id=e.movgest_ts_id
	AND g.movgest_id=f.movgest_id
	AND h.movgest_tipo_id=g.movgest_tipo_id
	AND i.movgest_ts_tipo_id=f.movgest_ts_tipo_id
	AND l.movgest_ts_id=f.movgest_ts_id
	AND l.movgest_stato_id=m.movgest_stato_id
	AND n.movgest_ts_id=f.movgest_ts_id
	AND o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id
	AND p.movgest_ts_id = f.movgest_ts_id
	AND q.classif_id = p.classif_id
	AND r.classif_tipo_id = q.classif_tipo_id
	AND s.bil_id = g.bil_id
	AND t.periodo_id = s.periodo_id
	AND now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine,now())
	AND now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine,now())
	AND now() BETWEEN l.validita_inizio AND COALESCE(l.validita_fine,now())
	AND now() BETWEEN p.validita_inizio AND COALESCE(p.validita_fine,now())
	AND s.data_cancellazione IS NULL
	AND t.data_cancellazione IS NULL
	AND a.data_cancellazione IS NULL
	AND b.data_cancellazione IS NULL
	AND c.data_cancellazione IS NULL
	AND d.data_cancellazione IS NULL
	AND e.data_cancellazione IS NULL
	AND f.data_cancellazione IS NULL
	AND g.data_cancellazione IS NULL
	AND h.data_cancellazione IS NULL
	AND i.data_cancellazione IS NULL
	AND l.data_cancellazione IS NULL
	AND m.data_cancellazione IS NULL
	AND n.data_cancellazione IS NULL
	AND o.data_cancellazione IS NULL
	AND p.data_cancellazione is null
	AND q.data_cancellazione is null
	AND r.data_cancellazione is null
	AND s.data_cancellazione is null
	AND r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	AND h.movgest_tipo_code='A'
	AND i.movgest_ts_tipo_code='T'
	AND o.movgest_ts_det_tipo_code='A'
	AND a.attoamm_id=_uid_provvedimento
	AND t.anno = _anno;
	
	RETURN total;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;