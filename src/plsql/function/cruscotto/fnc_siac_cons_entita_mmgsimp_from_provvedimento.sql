/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_mmgsimp_from_provvedimento (integer,integer,integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_mmgsimp_from_provvedimento (integer,varchar,integer,integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mmgsimp_from_provvedimento (
  _uid_provvedimento integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  impegno_anno integer,
  impegno_numero numeric,
  subimpegno_numero varchar,
  impegno_subimpegno varchar,
  impegno_desc varchar,
  modifica_desc varchar,
  modifica_tipo_code varchar,
  modifica_tipo_desc varchar,
  modifica_stato_code varchar,
  modifica_stato_desc varchar,
  importo numeric,
  modifica_numero integer
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
		SELECT
			tmtdm.movgest_ts_det_mod_id AS uid,
			tm.movgest_anno AS impegno_anno,
			tm.movgest_numero AS impegno_numero,
			tmt.movgest_ts_code AS subimpegno_numero,
			dmtt.movgest_ts_tipo_code AS impegno_subimpegno,
			tm.movgest_desc AS impegno_desc,
			tmo.mod_desc AS modifica_desc,
			dmot.mod_tipo_code AS modifica_tipo_code,
			dmot.mod_tipo_desc AS modifica_tipo_desc,
			dms.mod_stato_code AS modifica_stato_code,
			dms.mod_stato_desc AS modifica_stato_desc,
			tmtdm.movgest_ts_det_importo AS importo,
			tmo.mod_num AS modifica_numero
		FROM siac_t_movgest_ts_det_mod tmtdm
		JOIN siac_t_movgest_ts tmt ON (tmt.movgest_ts_id = tmtdm.movgest_ts_id AND tmtdm.data_cancellazione IS NULL AND tmt.data_cancellazione IS NULL)
		JOIN siac_d_movgest_ts_tipo dmtt ON (dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id AND dmtt.data_cancellazione IS NULL)
		JOIN siac_t_movgest tm ON (tm.movgest_id = tmt.movgest_id AND tm.data_cancellazione IS NULL)
		JOIN siac_d_movgest_tipo dmt ON (dmt.movgest_tipo_id = tm.movgest_tipo_id AND dmt.data_cancellazione IS NULL)
		JOIN siac_r_modifica_stato rms ON (rms.mod_stato_r_id = tmtdm.mod_stato_r_id AND rms.data_cancellazione IS NULL AND now() BETWEEN rms.validita_inizio AND COALESCE(rms.validita_fine, now()))
		JOIN siac_d_modifica_stato dms ON (dms.mod_stato_id = rms.mod_stato_id AND dms.data_cancellazione IS NULL)
		JOIN siac_t_modifica tmo ON (tmo.mod_id = rms.mod_id AND tmo.data_cancellazione IS NULL)
		JOIN siac_d_modifica_tipo dmot ON (dmot.mod_tipo_id = tmo.mod_tipo_id AND dmot.data_cancellazione IS NULL)
		JOIN siac_t_atto_amm taa ON taa.attoamm_id = tmo.attoamm_id
		JOIN siac_t_bil tb ON (tb.bil_id = tm.bil_id AND tb.data_cancellazione IS NULL)
		JOIN siac_t_periodo tp ON (tp.periodo_id = tb.periodo_id AND tp.data_cancellazione IS NULL)
		WHERE taa.attoamm_id = _uid_provvedimento
		AND dmt.movgest_tipo_code = 'I'
		AND tp.anno = _anno
		ORDER BY impegno_anno, impegno_numero, impegno_subimpegno DESC, subimpegno_numero, modifica_numero
		LIMIT _limit
		OFFSET _offset;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;