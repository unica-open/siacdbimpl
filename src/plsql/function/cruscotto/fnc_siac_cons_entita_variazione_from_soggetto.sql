/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_variazione_from_soggetto (
  _uid_soggetto integer,
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
BEGIN

	RETURN QUERY
	SELECT tv.variazione_id,
		tv.variazione_num,
		tv.variazione_desc,
		CASE
			WHEN dbet.elem_tipo_code LIKE '%G' THEN 'GESTIONE'::VARCHAR
			WHEN dbet.elem_tipo_code LIKE '%P' THEN 'PREVISIONE'::VARCHAR
			ELSE '?'::VARCHAR
		END AS variazione_applicazione,
		dvt.variazione_tipo_code, 
		dvt.variazione_tipo_desc,
		dvs.variazione_stato_tipo_code,
		dvs.variazione_stato_tipo_desc,
		taa.attoamm_numero,
		taa.attoamm_anno,
		daat.attoamm_tipo_code,
		daat.attoamm_tipo_desc,
		daas.attoamm_stato_desc,
		tc.classif_code,
		tc.classif_desc
	FROM siac_t_variazione tv
	JOIN siac_d_variazione_tipo dvt ON dvt.variazione_tipo_id = tv.variazione_tipo_id
	JOIN siac_r_variazione_stato rvs ON rvs.variazione_id = tv.variazione_id
	JOIN siac_d_variazione_stato dvs ON dvs.variazione_stato_tipo_id = rvs.variazione_stato_tipo_id
	--Capitoli nella variazione Codifiche
	LEFT OUTER JOIN siac_t_bil_elem_var tbev ON tbev.variazione_stato_id = rvs.variazione_stato_id
	LEFT OUTER JOIN siac_t_bil_elem tbe1 ON tbe1.elem_id = tbev.elem_id
	--Capitoli nella variazione Importi
	LEFT OUTER JOIN siac_t_bil_elem_det_var tbedv ON tbedv.variazione_stato_id = rvs.variazione_stato_id
	LEFT OUTER JOIN siac_t_bil_elem tbe2 ON tbe2.elem_id = tbedv.elem_id
	--Tipologia capitoli nella variazione
	LEFT OUTER JOIN siac_d_bil_elem_tipo dbet ON (tbe1.elem_tipo_id = dbet.elem_tipo_id -- Variazioni Codifiche
	                                              OR tbe2.elem_tipo_id = dbet.elem_tipo_id --Variazioni Importi
	                                              )
	LEFT OUTER JOIN siac_t_atto_amm taa ON taa.attoamm_id = rvs.attoamm_id
	LEFT OUTER JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id = taa.attoamm_tipo_id
	LEFT OUTER JOIN siac_r_atto_amm_stato raas ON raas.attoamm_id = taa.attoamm_id
	LEFT OUTER JOIN siac_d_atto_amm_stato daas ON daas.attoamm_stato_id = raas.attoamm_stato_id
	LEFT OUTER JOIN siac_r_atto_amm_class raac ON raac.attoamm_id = taa.attoamm_id
	LEFT OUTER JOIN siac_t_class tc ON tc.classif_id = raac.classif_id
	LEFT OUTER JOIN siac_d_class_tipo dct ON dct.classif_tipo_id = tc.classif_tipo_id
	WHERE tv.data_cancellazione IS NULL
	AND rvs.data_cancellazione IS NULL
	AND raas.data_cancellazione IS NULL
	AND raac.data_cancellazione IS NULL
	AND tbev.data_cancellazione IS NULL
	AND tbedv.data_cancellazione IS NULL
	AND (dct IS NULL OR dct.classif_tipo_code IN ('CDC', 'CDR'))
	GROUP BY tv.variazione_id,
		tv.variazione_num,
		tv.variazione_desc,
		variazione_applicazione,
		dvt.variazione_tipo_code,
		dvt.variazione_tipo_desc,
		dvs.variazione_stato_tipo_code,
		dvs.variazione_stato_tipo_desc,
		taa.attoamm_numero,
		taa.attoamm_anno,
		daat.attoamm_tipo_code,
		daat.attoamm_tipo_desc,
		daas.attoamm_stato_desc,
		tc.classif_code,
		tc.classif_desc
	ORDER BY tv.variazione_num
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;