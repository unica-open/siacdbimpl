/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5134 INIZIO
DROP FUNCTION IF EXISTS siac.fnc_siac_capitoli_from_variazioni(INTEGER);
CREATE OR REPLACE FUNCTION fnc_siac_capitoli_from_variazioni(p_uid_variazione INTEGER)
	RETURNS TABLE(
		stato_variazione     VARCHAR,
		anno_capitolo        VARCHAR,
		numero_capitolo      VARCHAR,
		numero_articolo      VARCHAR,
		numero_ueb           VARCHAR,
		tipo_capitolo        VARCHAR,
		descrizione_capitolo VARCHAR,
		descrizione_articolo VARCHAR,
		-- Dati uscita
		missione       VARCHAR,
		programma      VARCHAR,
		titolo_uscita  VARCHAR,
		macroaggregato VARCHAR,
		-- Dati entrata
		titolo_entrata VARCHAR,
		tipologia      VARCHAR,
		categoria      VARCHAR,
		-- Importi
		var_competenza  NUMERIC,
		var_residuo     NUMERIC,
		var_cassa       NUMERIC,
		var_competenza1 NUMERIC,
		var_residuo1    NUMERIC,
		var_cassa1      NUMERIC,
		var_competenza2 NUMERIC,
		var_residuo2    NUMERIC,
		var_cassa2      NUMERIC,
		cap_competenza  NUMERIC,
		cap_residuo     NUMERIC,
		cap_cassa       NUMERIC,
		cap_competenza1 NUMERIC,
		cap_residuo1    NUMERIC,
		cap_cassa1      NUMERIC,
		cap_competenza2 NUMERIC,
		cap_residuo2    NUMERIC,
		cap_cassa2      NUMERIC
	) AS
$body$
DECLARE
	v_ente_proprietario_id INTEGER;
BEGIN

	-- Utilizzo l'ente per migliorare la performance delle CTE nella query successiva
	SELECT ente_proprietario_id
	INTO v_ente_proprietario_id
	FROM siac_t_variazione
	WHERE siac_t_variazione.variazione_id = p_uid_variazione;

	RETURN QUERY
		-- CTE per uscita
		WITH missione AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc missione_tipo_desc,
				siac_t_class.classif_id missione_id,
				siac_t_class.classif_code missione_code,
				siac_t_class.classif_desc missione_desc,
				siac_t_class.validita_inizio missione_validita_inizio,
				siac_t_class.validita_fine missione_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR missione_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id_padre                      AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00001'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		programma AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc programma_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre missione_id,
				siac_t_class.classif_id programma_id,
				siac_t_class.classif_code programma_code,
				siac_t_class.classif_desc programma_desc,
				siac_t_class.validita_inizio programma_validita_inizio,
				siac_t_class.validita_fine programma_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR programma_code_desc,
				siac_r_bil_elem_class.elem_id programma_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione is null)
			WHERE siac_d_class_fam.classif_fam_code = '00001'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre is not null
			AND siac_t_class.data_cancellazione is null
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		titusc AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titusc_tipo_desc,
				siac_t_class.classif_id titusc_id,
				siac_t_class.classif_code titusc_code,
				siac_t_class.classif_desc titusc_desc,
				siac_t_class.validita_inizio titusc_validita_inizio,
				siac_t_class.validita_fine titusc_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titusc_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00002'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine,to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		macroag AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc macroag_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titusc_id,
				siac_t_class.classif_id macroag_id,
				siac_t_class.classif_code macroag_code,
				siac_t_class.classif_desc macroag_desc,
				siac_t_class.validita_inizio macroag_validita_inizio,
				siac_t_class.validita_fine macroag_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR macroag_code_desc,
				siac_r_bil_elem_class.elem_id macroag_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00002'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE per entrata
		titent AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titent_tipo_desc,
				siac_t_class.classif_id titent_id,
				siac_t_class.classif_code titent_code,
				siac_t_class.classif_desc titent_desc,
				siac_t_class.validita_inizio titent_validita_inizio,
				siac_t_class.validita_fine titent_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titent_id,
				siac_t_class.classif_id tipologia_id,
				siac_t_class.classif_code tipologia_code,
				siac_t_class.classif_desc tipologia_desc,
				siac_t_class.validita_inizio tipologia_validita_inizio,
				siac_t_class.validita_fine tipologia_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre tipologia_id,
				siac_t_class.classif_id categoria_id,
				siac_t_class.classif_code categoria_code,
				siac_t_class.classif_desc categoria_desc,
				siac_t_class.validita_inizio categoria_validita_inizio,
				siac_t_class.validita_fine categoria_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc,
				siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE importi variazione
		comp_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                         AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		residuo_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impRes,
				siac_t_periodo.anno::integer
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione  IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                         AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		cassa_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                         AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		-- CTE importi capitolo
		comp_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		residuo_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impRes,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		cassa_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		)
		SELECT
			siac_d_variazione_stato.variazione_stato_tipo_desc stato_variazione
			,siac_t_periodo.anno                               anno_capitolo
			,siac_t_bil_elem.elem_code                         numero_capitolo
			,siac_t_bil_elem.elem_code2                        numero_articolo
			,siac_t_bil_elem.elem_code3                        numero_ueb
			,siac_d_bil_elem_tipo.elem_tipo_code               tipo_capitolo
			,siac_t_bil_elem.elem_desc                         descrizione_capitolo
			,siac_t_bil_elem.elem_desc2                        descrizione_articolo
			-- Dati uscita
			,missione.missione_code_desc   missione
			,programma.programma_code_desc programma
			,titusc.titusc_code_desc       titolo_uscita
			,macroag.macroag_code_desc     macroaggregato
			-- Dati entrata
			,titent.titent_code_desc       titolo_entrata
			,tipologia.tipologia_code_desc tipologia
			,categoria.categoria_code_desc categoria
			-- Importi variazione
			,comp_variaz.impSta     var_competenza
			,residuo_variaz.impRes  var_residuo
			,cassa_variaz.impSca    var_cassa
			,comp_variaz1.impSta    var_competenza1
			,residuo_variaz1.impRes var_residuo1
			,cassa_variaz1.impSca   var_cassa1
			,comp_variaz2.impSta    var_competenza2
			,residuo_variaz2.impRes var_residuo2
			,cassa_variaz2.impSca   var_cassa2
			-- Importi capitolo
			,comp_capitolo.impSta     cap_competenza
			,residuo_capitolo.impRes  cap_residuo
			,cassa_capitolo.impSca    cap_cassa
			,comp_capitolo1.impSta    cap_competenza1
			,residuo_capitolo1.impRes cap_residuo1
			,cassa_capitolo1.impSca   cap_cassa1
			,comp_capitolo2.impSta    cap_competenza2
			,residuo_capitolo2.impRes cap_residuo2 
			,cassa_capitolo2.impSca   cap_cassa2
		FROM siac_t_variazione
		JOIN siac_r_variazione_stato           ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                             AND siac_r_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_d_variazione_stato           ON (siac_r_variazione_stato.variazione_stato_tipo_id = siac_d_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem_det_var           ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem                   ON (siac_t_bil_elem_det_var.elem_id = siac_t_bil_elem.elem_id                                           AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                        ON (siac_t_bil_elem.bil_id = siac_t_bil.bil_id                                                          AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                    ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                                   AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_tipo              ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id                                    AND siac_d_bil_elem_tipo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_det_tipo          ON (siac_d_bil_elem_det_tipo.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
		JOIN siac_t_bil     bil_variazione     ON (bil_variazione.bil_id = siac_t_variazione.bil_id                                                    AND bil_variazione.data_cancellazione IS NULL)
		JOIN siac_t_periodo periodo_variazione ON (bil_variazione.periodo_id = periodo_variazione.periodo_id                                           AND periodo_variazione.data_cancellazione IS NULL)
		-- Importi variazione, anno 0
		LEFT OUTER JOIN comp_variaz    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz.elem_id    AND comp_variaz.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN residuo_variaz ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz.elem_id AND residuo_variaz.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN cassa_variaz   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz.elem_id   AND cassa_variaz.anno = periodo_variazione.anno::INTEGER)
		-- Importi variazione, anno +1
		LEFT OUTER JOIN comp_variaz    comp_variaz1    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz1.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz1.elem_id    AND comp_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_variaz residuo_variaz1 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz1.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz1.elem_id AND residuo_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz1   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz1.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz1.elem_id   AND cassa_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		-- Importi variazione, anno +2
		LEFT OUTER JOIN comp_variaz    comp_variaz2    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz2.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz2.elem_id    AND comp_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_variaz residuo_variaz2 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz2.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz2.elem_id AND residuo_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz2   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz2.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz2.elem_id   AND cassa_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		-- Importi capitolo, anno 0
		LEFT OUTER JOIN comp_capitolo    ON (siac_t_bil_elem.elem_id = comp_capitolo.elem_id    AND comp_capitolo.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN residuo_capitolo ON (siac_t_bil_elem.elem_id = residuo_capitolo.elem_id AND residuo_capitolo.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN cassa_capitolo   ON (siac_t_bil_elem.elem_id = cassa_capitolo.elem_id   AND cassa_capitolo.anno = periodo_variazione.anno::INTEGER)
		-- Importi capitolo, anno +1
		LEFT OUTER JOIN comp_capitolo    comp_capitolo1    ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id    AND comp_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo1 ON (siac_t_bil_elem.elem_id = residuo_capitolo1.elem_id AND residuo_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo1   ON (siac_t_bil_elem.elem_id = cassa_capitolo1.elem_id   AND cassa_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		-- Importi capitolo, anno +2
		LEFT OUTER JOIN comp_capitolo    comp_capitolo2    ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id    AND comp_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo2 ON (siac_t_bil_elem.elem_id = residuo_capitolo2.elem_id AND residuo_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo2   ON (siac_t_bil_elem.elem_id = cassa_capitolo2.elem_id   AND cassa_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		-- Classificatori
		LEFT OUTER JOIN macroag   ON (macroag.macroag_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN programma ON (programma.programma_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN missione  ON (missione.missione_id = programma.missione_id)
		LEFT OUTER JOIN titusc    ON (titusc.titusc_id = macroag.titusc_id)
		LEFT OUTER JOIN categoria ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN tipologia ON (tipologia.tipologia_id = categoria.tipologia_id)
		LEFT OUTER JOIN titent    ON (tipologia.titent_id = titent.titent_id)
		-- WHERE clause
		WHERE siac_t_variazione.variazione_id = p_uid_variazione
		AND siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		ORDER BY tipo_capitolo DESC, anno_capitolo, siac_t_bil_elem.elem_code::integer, siac_t_bil_elem.elem_code2::integer, siac_t_bil_elem.elem_code3::integer;
		
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5134 FINE


-- SIAC-5136 Maurizio INIZIO

CREATE OR REPLACE FUNCTION siac."BILR152_elenco_doc_spesa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  doc_anno integer,
  doc_numero varchar,
  subdoc_numero integer,
  tipo_doc varchar,
  conto_dare varchar,
  conto_avere varchar,
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  tipo_impegno varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  num_liquidazione varchar,
  anno_liquidazione integer,
  importo_quota numeric,
  penale_anno integer,
  penale_numero varchar,
  ncd_anno integer,
  ncd_numero varchar,
  tipo_iva_split_reverse varchar,
  importo_split_reverse numeric,
  codice_onere varchar,
  aliquota_carico_sogg numeric
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;

-- CR944 inizio
tipo_cessione varchar:=''; 
-- CR944 fine
 

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
doc_anno:=0;
doc_numero:='';
subdoc_numero:=0;
tipo_doc:='';
conto_dare:='';
conto_avere:='';
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
tipo_impegno:='';
code_soggetto:='';
desc_soggetto:=0;
num_liquidazione:='';
anno_liquidazione:=0;
importo_quota:=0;
penale_anno:=0;
penale_numero:='';
ncd_anno:=0;
ncd_numero:='';
tipo_iva_split_reverse:='';
importo_split_reverse:=0;
codice_onere:='';
aliquota_carico_sogg:=0;

anno_eser_int=p_anno ::INTEGER;


RTN_MESSAGGIO:='Estrazione dei dati dei documenti di spesa ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
with doc as (      
      select r_subdoc_atto_amm.subdoc_id,
              t_doc.doc_id,
                COALESCE(t_doc.doc_numero,'''') doc_numero, 
                COALESCE(t_doc.doc_anno,0) doc_anno, 
                COALESCE(t_doc.doc_importo,0) doc_importo,
                COALESCE(t_subdoc.subdoc_numero,0) subdoc_numero, 
                COALESCE(t_subdoc.subdoc_importo,0) subdoc_importo, 
                COALESCE(t_subdoc.subdoc_importo_da_dedurre,0) subdoc_importo_da_dedurre, 
                COALESCE(d_doc_tipo.doc_tipo_code,'''') tipo_doc,
                 t_atto_amm.attoamm_numero,
                  t_atto_amm.attoamm_anno,
                  tipo_atto.attoamm_tipo_code,
                  r_subdoc_movgest_ts.movgest_ts_id
          from siac_r_subdoc_atto_amm r_subdoc_atto_amm,
                  siac_t_subdoc t_subdoc
                  LEFT JOIN siac_r_subdoc_movgest_ts r_subdoc_movgest_ts
                      ON (r_subdoc_movgest_ts.subdoc_id=t_subdoc.subdoc_id
                          AND r_subdoc_movgest_ts.data_cancellazione IS NULL),
                  siac_t_doc 	t_doc
                  LEFT JOIN siac_d_doc_tipo d_doc_tipo
                      ON (d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                          AND d_doc_tipo.data_cancellazione IS NULL)
                  LEFT JOIN siac_d_doc_fam_tipo d_doc_fam_tipo
                      ON (d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id
                          AND d_doc_fam_tipo.data_cancellazione IS NULL),
                  siac_t_atto_amm t_atto_amm  ,
                  siac_d_atto_amm_tipo	tipo_atto
          where t_subdoc.subdoc_id= r_subdoc_atto_amm.subdoc_id
              AND t_doc.doc_id=  t_subdoc.doc_id
              AND t_atto_amm.attoamm_id=r_subdoc_atto_amm.attoamm_id
              AND tipo_atto.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
              and r_subdoc_atto_amm.ente_proprietario_id=p_ente_prop_id
              AND t_atto_amm.attoamm_numero=p_numero_provv
              AND t_atto_amm.attoamm_anno=p_anno_provv
              AND tipo_atto.attoamm_tipo_code=p_tipo_provv
             AND d_doc_fam_tipo.doc_fam_tipo_code='S' --doc di Spesa
              AND r_subdoc_atto_amm.data_cancellazione IS NULL
              AND t_atto_amm.data_cancellazione IS NULL
              AND tipo_atto.data_cancellazione IS NULL
              AND t_subdoc.data_cancellazione IS NULL
              AND t_doc.data_cancellazione IS NULL   ),
 impegni as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,            
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno
                AND d_movgest_tipo.movgest_tipo_code='I'    --Impegno  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL),                     
	soggetto as (
    		SELECT r_doc_sog.doc_id,
                t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc
            FROM siac_r_doc_sog r_doc_sog,
                siac_t_soggetto t_soggetto
            WHERE r_doc_sog.soggetto_id=   t_soggetto.soggetto_id
                and t_soggetto.ente_proprietario_id=p_ente_prop_id
                AND t_soggetto.data_cancellazione IS NULL  
                AND r_doc_sog.data_cancellazione IS NULL) ,   
    	capitoli as(
        	select r_movgest_bil_elem.movgest_id,
            	t_bil_elem.elem_id,
            	t_bil_elem.elem_code,
                t_bil_elem.elem_code2,
                t_bil_elem.elem_code3,
                t_bil_elem.elem_desc,
                t_bil_elem.elem_desc2
            from 	siac_r_movgest_bil_elem r_movgest_bil_elem,
            	siac_t_bil_elem t_bil_elem
            where r_movgest_bil_elem.elem_id=t_bil_elem.elem_id            
            	AND r_movgest_bil_elem.ente_proprietario_id=p_ente_prop_id
            	AND t_bil_elem.data_cancellazione IS NULL
                AND r_movgest_bil_elem.data_cancellazione IS NULL) ,
	conto_integrato as (    	
      select distinct t_subdoc.subdoc_id, 
          t_mov_ep_det.movep_det_segno,
          t_pdce_conto.pdce_conto_code
      from siac_r_evento_reg_movfin r_ev_reg_movfin,
          siac_t_subdoc t_subdoc,
          siac_d_evento d_evento,
          siac_d_collegamento_tipo d_coll_tipo,
          siac_t_reg_movfin t_reg_movfin,
          siac_t_mov_ep t_mov_ep,
          siac_t_mov_ep_det t_mov_ep_det,
          siac_t_pdce_conto t_pdce_conto
      where t_subdoc.subdoc_id=r_ev_reg_movfin.campo_pk_id
          and d_evento.evento_id=r_ev_reg_movfin.evento_id
          and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
          and t_reg_movfin.regmovfin_id=r_ev_reg_movfin.regmovfin_id
          and t_mov_ep.regmovfin_id=t_reg_movfin.regmovfin_id
          and t_mov_ep_det.movep_id=t_mov_ep.movep_id
          and t_pdce_conto.pdce_conto_id=t_mov_ep_det.pdce_conto_id
          and t_subdoc.ente_proprietario_id=p_ente_prop_id
          and d_coll_tipo.collegamento_tipo_code='SS' --Subdocumento Spesa   
          and r_ev_reg_movfin.data_cancellazione is null
          and t_subdoc.data_cancellazione is null
          and d_evento.data_cancellazione is null
          and d_coll_tipo.data_cancellazione is null
          and t_reg_movfin.data_cancellazione is null
          and t_mov_ep.data_cancellazione is null
          and t_mov_ep_det.data_cancellazione is null
          and t_pdce_conto.data_cancellazione is null )   ,
      liquidazioni as (    
          select t_liquidazione.liq_anno,
              -- CR944 inizio
              --t_liquidazione.liq_numero,
              t_liquidazione.liq_numero || ' ' || COALESCE( d_relaz.relaz_tipo_code, '') as liq_numero,
              -- CR944 fine
              r_subdoc_liq.subdoc_id         
           from  siac_t_liquidazione t_liquidazione
             -- CR944 inizio
             left join  siac_r_soggetto_relaz r_relaz on (
                  t_liquidazione.soggetto_relaz_id=  r_relaz.soggetto_relaz_id
                  and r_relaz.data_cancellazione is null
                  and r_relaz.validita_fine is null 
             )
             left join siac_d_relaz_tipo d_relaz on (
                  d_relaz.relaz_tipo_id=r_relaz.relaz_tipo_id
             )
             left join siac_r_soggrel_modpag r_modpag on (
                  r_modpag.soggetto_relaz_id = r_relaz.soggetto_relaz_id
                  and r_modpag.data_cancellazione is null
                  and r_modpag.validita_fine is null
             )
             -- CR944 fine
           ,         
                siac_r_subdoc_liquidazione r_subdoc_liq                
          where t_liquidazione.liq_id=   r_subdoc_liq.liq_id
               AND t_liquidazione.ente_proprietario_id =p_ente_prop_id
               AND t_liquidazione.data_cancellazione IS NULL
               AND r_subdoc_liq.data_cancellazione IS NULL)  ,
      ncd as  (
      		SELECT  r_doc.doc_id_da doc_id,
            	t_doc.doc_anno,
                t_doc.doc_numero, 
                d_doc_tipo.doc_tipo_code
            FROM siac_r_doc r_doc, 
            		siac_d_relaz_tipo d_relaz_tipo,
                    siac_t_doc t_doc,
                    siac_d_doc_tipo d_doc_tipo
            WHERE r_doc.relaz_tipo_id=d_relaz_tipo.relaz_tipo_id
            	AND t_doc.doc_id=r_doc.doc_id_a
                AND d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                AND d_relaz_tipo.relaz_tipo_code='NCD' -- note di credito
                and r_doc.ente_proprietario_id=p_ente_prop_id
                AND r_doc.data_cancellazione IS NULL
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_doc.data_cancellazione IS NULL
                AND d_doc_tipo.data_cancellazione IS NULL)  ,
			ritenute as (
        		SELECT r_doc_onere.doc_id, r_doc_onere.importo_carico_ente, 
                    r_doc_onere.importo_imponibile,
                    d_onere_tipo.onere_tipo_code, d_onere.onere_code
                FROM siac_r_doc_onere r_doc_onere, siac_d_onere d_onere,
                	siac_d_onere_tipo  d_onere_tipo
                WHERE r_doc_onere.onere_id=d_onere.onere_id
                	AND d_onere.onere_tipo_id=d_onere_tipo.onere_tipo_id
                    AND r_doc_onere.ente_proprietario_id =p_ente_prop_id
                    -- estraggo solo gli oneri con importo carico ente
                    -- e che non sono Split/reverse
                    AND r_doc_onere.importo_carico_ente > 0   
                    AND d_onere_tipo.onere_tipo_code <> 'SP'
                    AND r_doc_onere.data_cancellazione IS NULL
                    AND d_onere.data_cancellazione IS NULL
                    AND d_onere_tipo.data_cancellazione IS NULL)  ,
            split_reverse as (
            	SELECT r_subdoc_split_iva_tipo.subdoc_id,
						d_split_iva_tipo.sriva_tipo_code, 
                        t_subdoc.subdoc_splitreverse_importo
                FROM siac_r_subdoc_splitreverse_iva_tipo r_subdoc_split_iva_tipo,
                  siac_d_splitreverse_iva_tipo d_split_iva_tipo ,
                  siac_t_subdoc t_subdoc    
                WHERE  r_subdoc_split_iva_tipo.sriva_tipo_id= d_split_iva_tipo.sriva_tipo_id
                	AND t_subdoc.subdoc_id=r_subdoc_split_iva_tipo.subdoc_id
                    AND r_subdoc_split_iva_tipo.ente_proprietario_id=p_ente_prop_id
                    AND r_subdoc_split_iva_tipo.data_cancellazione IS NULL
                    AND d_split_iva_tipo.data_cancellazione IS NULL
                    AND t_subdoc.data_cancellazione IS NULL) ,
            penali as (
            	SELECT  r_doc.doc_id_da doc_id,
            	t_doc.doc_anno,
                t_doc.doc_numero, 
                d_doc_tipo.doc_tipo_code
            FROM siac_r_doc r_doc, 
            		siac_d_relaz_tipo d_relaz_tipo,
                    siac_t_doc t_doc,
                    siac_d_doc_tipo d_doc_tipo
            WHERE r_doc.relaz_tipo_id=d_relaz_tipo.relaz_tipo_id
            	AND t_doc.doc_id=r_doc.doc_id_a
                AND d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                AND d_relaz_tipo.relaz_tipo_code='SUB' -- subortinati
                AND d_doc_tipo.doc_tipo_code='PNL' -- Penale
                and r_doc.ente_proprietario_id=p_ente_prop_id
                AND r_doc.data_cancellazione IS NULL
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_doc.data_cancellazione IS NULL
                AND d_doc_tipo.data_cancellazione IS NULL)
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
    doc.doc_anno::integer,
    doc.doc_numero::varchar,
    doc.subdoc_numero::integer,
    doc.tipo_doc::varchar,
    CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='DARE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_dare,
     CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='AVERE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_avere,
    impegni.movgest_numero::numeric num_impegno,
    impegni.movgest_anno::integer anno_impegno,
    impegni.movgest_ts_code::varchar num_subimpegno,
    CASE WHEN impegni.movgest_ts_tipo_code = 'T'
    	THEN 'IMP'::varchar 
        ELSE 'SUB'::varchar end tipo_impegno,
    COALESCE(soggetto.soggetto_code,'')::varchar code_soggetto,
    COALESCE(soggetto.soggetto_desc,'')::varchar desc_soggetto,
    COALESCE(liquidazioni.liq_numero,'0')::varchar num_liquidazione,
    COALESCE(liquidazioni.liq_anno,0)::integer anno_liquidazione,
	COALESCE(doc.subdoc_importo,0)-
    	COALESCE(doc.subdoc_importo_da_dedurre,0) ::numeric importo_quota,
    COALESCE(penali.doc_anno,0)::integer   penale_anno, 
    COALESCE(penali.doc_numero,'')::varchar   penale_numero, 
	COALESCE(ncd.doc_anno,0)::integer ncd_anno,
    COALESCE(ncd.doc_numero,'')::varchar ncd_numero,
   --'1'::varchar ncd_numero,
    COALESCE(split_reverse.sriva_tipo_code,'')::varchar tipo_iva_split_reverse,
	COALESCE(split_reverse.subdoc_splitreverse_importo,0)::numeric importo_split_reverse,
    COALESCE(ritenute.onere_code,'')::varchar codice_onere,
    COALESCE(ritenute.importo_carico_ente,0)::numeric aliquota_carico_sogg
FROM doc
	LEFT JOIN impegni on impegni.movgest_ts_id=doc.movgest_ts_id
	LEFT JOIN soggetto on soggetto.doc_id=doc.doc_id    
	LEFT JOIN capitoli on capitoli.movgest_id = impegni.movgest_id
    LEFT JOIN conto_integrato on conto_integrato.subdoc_id = doc.subdoc_id 
    LEFT JOIN liquidazioni on liquidazioni.subdoc_id = doc.subdoc_id 
    LEFT JOIN ncd on ncd.doc_id =doc.doc_id         
    LEFT JOIN ritenute on ritenute.doc_id =doc.doc_id  
    LEFT JOIN split_reverse on split_reverse.subdoc_id =doc.subdoc_id  
    LEFT JOIN penali on ncd.doc_id =penali.doc_id           
ORDER BY doc_anno, doc_numero, subdoc_numero) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati dei documenti di spesa ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun documento trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-5136 Maurizio FINE
-- SIAC-5141 Alessandro INIZIO
CREATE OR REPLACE FUNCTION siac."BILR150_prosp_dimos_ris_amm_entrate" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  rr_totale_risc_residui numeric,
  rc_totale_risc_competenza numeric,
  r_totale_riacc_residui numeric,
  rs_totale_residui_attivi numeric,
  a_totale_accertamenti numeric
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp_int integer;
TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_movgest_tipo varchar:='A';
v_movgest_ts_tipo varchar :='T';

v_det_tipo_importo_attuale varchar:='A';
v_det_tipo_importo_iniziale varchar:='I';
v_ord_stato_code_annullato varchar:='A';
v_ord_tipo_code_incasso varchar:='I';
v_fam_titolotipologiacategoria varchar:='00003';


BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;  

TipoImpstanzresidui='SRI'; -- stanziamento residuo post (RS)
TipoImpstanz='STA'; -- stanziamento  (CP)
TipoImpCassa ='SCA'; ----- cassa	(CS)
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

rr_totale_risc_residui:=0;
rc_totale_risc_competenza:=0;
r_totale_riacc_residui:=0;
rs_totale_residui_attivi:=0;
a_totale_accertamenti:=0;

RTN_MESSAGGIO:='Estrazione dei dati delle riscossioni.';
raise notice '%',RTN_MESSAGGIO;

raise notice '5 - %' , clock_timestamp()::text;

 
return query
with capent as (
select e.elem_id
from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	'CAP-EG'
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
-- 14/04/2017: corretto il controllo sulle date.
/*and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between rc.validita_inizio and COALESCE(rc.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
*/
and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
),
 riscossioni_res as (
select 	 r_capitolo_ordinativo.elem_id,
	 sum(ordinativo_imp.ord_ts_det_importo) riscossioni
from 		siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc, 
            siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
            siac_t_ordinativo				ordinativo,
            siac_d_ordinativo_tipo			tipo_ordinativo,
            siac_r_ordinativo_stato			r_stato_ordinativo,
            siac_d_ordinativo_stato			stato_ordinativo,
            siac_t_ordinativo_ts 			ordinativo_det,
			siac_t_ordinativo_ts_det 		ordinativo_imp,
        	siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
            siac_t_movgest     				movimento,
            siac_t_movgest_ts    			ts_movimento, 
            siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
    where 	anno_eserc.anno						= 	p_anno											
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	bilancio.ente_proprietario_id	=	p_ente_prop_id
        and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
		and	tipo_ordinativo.ord_tipo_code		= 	v_ord_tipo_code_incasso		------ incasso
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
        and	stato_ordinativo.ord_stato_code			<> v_ord_stato_code_annullato --- 
        -----------------------------------------------------------------------------------------------
        and	ordinativo.bil_id					=	bilancio.bil_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	v_det_tipo_importo_attuale 	---- importo attuala
        ---------------------------------------------------------------------------------------------------------------------
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id
        and	movimento.movgest_anno				<	annoCapImp_int	
        and movimento.bil_id					=	bilancio.bil_id	
        --------------------------------------------------------------------------------------------------------------------		
        and	bilancio.data_cancellazione 				is null
        and	anno_eserc.data_cancellazione 				is null
        and	r_capitolo_ordinativo.data_cancellazione	is null
        and	ordinativo.data_cancellazione				is null
        AND	tipo_ordinativo.data_cancellazione			is null
        and	r_stato_ordinativo.data_cancellazione		is null
        AND	stato_ordinativo.data_cancellazione			is null
        AND ordinativo_det.data_cancellazione			is null
 	  	aND ordinativo_imp.data_cancellazione			is null
        and ordinativo_imp_tipo.data_cancellazione		is null
        and	movimento.data_cancellazione				is null
        and	ts_movimento.data_cancellazione				is null
        and	r_ordinativo_movgest.data_cancellazione		is null
    and now()
      between r_capitolo_ordinativo.validita_inizio 
          and COALESCE(r_capitolo_ordinativo.validita_fine,now())
          and now()
      between r_stato_ordinativo.validita_inizio 
          and COALESCE(r_stato_ordinativo.validita_fine,now())
          and now()
      between r_ordinativo_movgest.validita_inizio 
          and COALESCE(r_ordinativo_movgest.validita_fine,now()) 
      group by r_capitolo_ordinativo.elem_id),
riscossioni_comp as (
select 	 r_capitolo_ordinativo.elem_id,
	 sum(ordinativo_imp.ord_ts_det_importo) riscossioni
from 		siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc, 
            siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
            siac_t_ordinativo				ordinativo,
            siac_d_ordinativo_tipo			tipo_ordinativo,
            siac_r_ordinativo_stato			r_stato_ordinativo,
            siac_d_ordinativo_stato			stato_ordinativo,
            siac_t_ordinativo_ts 			ordinativo_det,
			siac_t_ordinativo_ts_det 		ordinativo_imp,
        	siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
            siac_t_movgest     				movimento,
            siac_t_movgest_ts    			ts_movimento, 
            siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
    where 	anno_eserc.anno						= 	p_anno											
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	bilancio.ente_proprietario_id	=	p_ente_prop_id
        and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
		and	tipo_ordinativo.ord_tipo_code		= 	v_ord_tipo_code_incasso		------ incasso
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
        and	stato_ordinativo.ord_stato_code			<> v_ord_stato_code_annullato --- 
        -----------------------------------------------------------------------------------------------
        and	ordinativo.bil_id					=	bilancio.bil_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	v_det_tipo_importo_attuale 	---- importo attuala
        ---------------------------------------------------------------------------------------------------------------------
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id
        and	movimento.movgest_anno				=	annoCapImp_int	
        and movimento.bil_id					=	bilancio.bil_id	
        --------------------------------------------------------------------------------------------------------------------		
        and	bilancio.data_cancellazione 				is null
        and	anno_eserc.data_cancellazione 				is null
        and	r_capitolo_ordinativo.data_cancellazione	is null
        and	ordinativo.data_cancellazione				is null
        AND	tipo_ordinativo.data_cancellazione			is null
        and	r_stato_ordinativo.data_cancellazione		is null
        AND	stato_ordinativo.data_cancellazione			is null
        AND ordinativo_det.data_cancellazione			is null
 	  	aND ordinativo_imp.data_cancellazione			is null
        and ordinativo_imp_tipo.data_cancellazione		is null
        and	movimento.data_cancellazione				is null
        and	ts_movimento.data_cancellazione				is null
        and	r_ordinativo_movgest.data_cancellazione		is null
    and now()
      between r_capitolo_ordinativo.validita_inizio 
          and COALESCE(r_capitolo_ordinativo.validita_fine,now())
          and now()
      between r_stato_ordinativo.validita_inizio 
          and COALESCE(r_stato_ordinativo.validita_fine,now())
          and now()
      between r_ordinativo_movgest.validita_inizio 
          and COALESCE(r_ordinativo_movgest.validita_fine,now()) 
      group by r_capitolo_ordinativo.elem_id),
riacc_residui as(
 select    
   capitolo.elem_id,
   sum (t_movgest_ts_det_mod.movgest_ts_det_importo) riacc_residui
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
      siac_t_modifica t_modifica,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      and movimento.movgest_anno ::text  	< 	p_anno
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= v_movgest_tipo 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = v_movgest_ts_tipo
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = v_det_tipo_importo_attuale ----- importo attuale 
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and d_mod_stato.mod_stato_code='V'
      and r_mod_stato.mod_id=t_modifica.mod_id      	
      and now() 
		between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() 
 		between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now()
 		between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
      group by capitolo.elem_id )  ,
residui_attivi as (
select    
capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) residui
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno  			< 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= v_movgest_tipo
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = v_movgest_ts_tipo
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = v_det_tipo_importo_iniziale ----- importo attuale 
      -- INC000001913168 Inizio
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())        
      and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())         
      --and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
      --and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
      -- INC000001913168 Fine
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id)  ,
accertamenti as (
select    
capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) imp_accertamenti
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno 		  	= 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= v_movgest_tipo 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = v_movgest_ts_tipo 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = v_det_tipo_importo_attuale ----- importo attuale 	  
      and now() 
 		between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
      and now() 
 		between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now()) 
   	  and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id)  
select sum(riscossioni_res.riscossioni) rr_totale_risc_residui,
		sum(riscossioni_comp.riscossioni) rc_totale_risc_competenza,
        sum(riacc_residui.riacc_residui) r_totale_riacc_residui,
        sum(residui_attivi.residui) rs_totale_residui_attivi,
        sum(accertamenti.imp_accertamenti) a_totale_accertamenti             
	from capent
    	left join riscossioni_res
        	on capent.elem_id=riscossioni_res.elem_id
    	left join riscossioni_comp
        	on capent.elem_id=riscossioni_comp.elem_id
        left join riacc_residui
        	on capent.elem_id=riacc_residui.elem_id 
        left join residui_attivi
        	on capent.elem_id=residui_attivi.elem_id  
        left join accertamenti 
        	on capent.elem_id=accertamenti.elem_id ;   


exception
	when no_data_found THEN
		raise notice 'nessun dato trovato per le entrate.' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5141 Alessandro FINE

-- MODIFICHE da CSI - Maurizio - INIZIO

DROP FUNCTION siac."BILR146_peg_entrate_gestione_strut_capitolo"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(IN p_ente_prop_id integer, IN p_anno character varying)
  RETURNS TABLE(bil_anno character varying, titoloe_tipo_code character varying, titoloe_tipo_desc character varying, titoloe_code character varying, titoloe_desc character varying, tipologia_tipo_code character varying, tipologia_tipo_desc character varying, tipologia_code character varying, tipologia_desc character varying, categoria_tipo_code character varying, categoria_tipo_desc character varying, categoria_code character varying, categoria_desc character varying, bil_ele_code character varying, bil_ele_desc character varying, bil_ele_code2 character varying, bil_ele_desc2 character varying, bil_ele_id integer, bil_ele_id_padre integer, stanziamento_prev_cassa_anno numeric, stanziamento_prev_anno numeric, stanziamento_prev_anno1 numeric, stanziamento_prev_anno2 numeric, direz_code character varying, direz_descr character varying, sett_code character varying, sett_descr character varying, codice_conto_finanz character varying, stanziamento_prev_res_anno numeric) AS
$BODY$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
classif_id_padre integer;
v_fam_titolotipologiacategoria varchar:='00003';

BEGIN


annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa

elemTipoCode:='CAP-EG'; -- tipo capitolo Gestione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
stanziamento_prev_cassa_anno:=0;

direz_code='';
direz_descr='';
sett_code='';
sett_descr='';
classif_id_padre=0;

select fnc_siac_random_user()
into	user_table;




--05/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;
 

insert into siac_rep_cap_eg
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente,
   (select t_class_upb.classif_code
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 
            	class_upb.classif_tipo_code in('PDC_V' , 'PDC_IV')	and
                --class_upb.classif_tipo_code='CLASSIFICATORE_36' 							and		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 				and
                t_class_upb.classif_id=r_capitolo_upb.classif_id					AND
                e.elem_id=r_capitolo_upb.elem_id
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null	)
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
--and	stato_capitolo.elem_stato_code	=	'VA'
and	stato_capitolo.elem_stato_code in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());

/* inserisco i capitoli che non hanno una struttura */
insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente,
  (select t_class_upb.classif_code
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 
            	class_upb.classif_tipo_code in('PDC_V' , 'PDC_IV')	and
                --class_upb.classif_tipo_code='CLASSIFICATORE_36' 							and		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 				and
                t_class_upb.classif_id=r_capitolo_upb.classif_id					AND
                e.elem_id=r_capitolo_upb.elem_id
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null	)
 from 	
 		siac_t_bil_elem e,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and not EXISTS
(
   select 1 from siac_rep_cap_eg x
   where x.elem_id = e.elem_id
   and x.utente=user_table
);


insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	------coalesce (sum(capitolo_importi.elem_det_importo),0)    
            sum(capitolo_importi.elem_det_importo)     
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		--and	stato_capitolo.elem_stato_code		=	'VA'
        and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and	cat_del_capitolo.elem_cat_code		=	'STD'
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;



insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento_prev_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_prev_anno1,
        coalesce (tb3.importo,0)   as 		stanziamento_prev_anno2,
        coalesce (tb4.importo,0)   as 		stanziamento_prev_res_anno,
        0,
       -- coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb3,
	siac_rep_cap_eg_imp tb4,
    --, siac_rep_cap_eg_imp tb5, 
    siac_rep_cap_eg_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			--tb4.elem_id	=	tb5.elem_id								and
        			--tb5.elem_id	=	tb6.elem_id								and
                    tb3.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			--tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa;
--------raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    

for classifBilRec in

select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)		stanziamento_prev_res_anno,
    	--COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(tb.pdc,' ') codice_conto_finanz
from  	siac_rep_tit_tip_cat_riga_anni v1
		 join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id 	
                    	and tb1.utente=user_table)
         where 
         	   	COALESCE (tb1.stanziamento_prev_anno,0)			> 0 or
				COALESCE (tb1.stanziamento_prev_anno1,0)		> 0 or
    			COALESCE (tb1.stanziamento_prev_anno2,0)		> 0 or
   	 			COALESCE (tb1.residui_presunti,0)				> 0 or
     			COALESCE (tb1.stanziamento_prev_cassa_anno,0)	> 0       
 union
    select 	
		'Titolo'    			titoloe_TIPO_DESC,
       	NULL              		titoloe_ID,
       	'0'            			titoloe_CODE,
       	' '             	titoloe_DESC,
       	'Tipologia'	  			tipologia_TIPO_DESC,
       	null	              	tipologia_ID,
       	'0000000'            	tipologia_CODE,
       	' '           tipologia_DESC,
       	'Categoria'     		categoria_TIPO_DESC,
      	null	              	categoria_ID,
       	'0000000'            	categoria_CODE,
       	' '           categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
        COALESCE (tb1.residui_presunti,0)			stanziamento_prev_res_anno,        
        COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(tb.pdc,' ') codice_conto_finanz
from  	siac_rep_cap_eg tb
            left	join    siac_rep_cap_ep_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)            
    where  tb.utente = user_table    	
    and tb.ente_proprietario_id=p_ente_prop_id
   and tb.classif_id is null 
   and (
	COALESCE (tb1.stanziamento_prev_anno,0)			> 0 or
	COALESCE (tb1.stanziamento_prev_anno1,0)		> 0 or
    COALESCE (tb1.stanziamento_prev_anno2,0)		> 0 or
   	COALESCE (tb1.residui_presunti,0)				> 0 or
    COALESCE (tb1.stanziamento_prev_cassa_anno,0)	> 0   )    

   		--order by titoloe_CODE,tipologia_CODE,categoria_CODE                    
		--	order by v1.titolo_code,v1.tipologia_code,v1.categoria_code,tb.elem_code::INTEGER,tb.elem_code2::INTEGER            

loop

/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
--previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;
codice_conto_finanz=classifBilRec.codice_conto_finanz;


IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN
		/* Cerco il settore e prendo anche l'ID dell'elemento padre per cercare poi
        	la direzione */
	BEGIN    
		SELECT   t_class.classif_code, t_class.classif_desc, r_class_fam_tree.classif_id_padre 
		INTO sett_code, sett_descr, classif_id_padre      
            from siac_r_bil_elem_class r_bil_elem_class,
            	siac_r_class_fam_tree r_class_fam_tree,
                siac_t_class			t_class,
                siac_d_class_tipo		d_class_tipo ,
                siac_t_bil_elem    		capitolo               
        where 
            r_bil_elem_class.elem_id 			= 	capitolo.elem_id
            and t_class.classif_id 					= 	r_bil_elem_class.classif_id
            and t_class.classif_id 					= 	r_class_fam_tree.classif_id
            and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
           AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
            and capitolo.elem_id=classifBilRec.BIL_ELE_ID
             AND r_bil_elem_class.data_cancellazione is NULL
             AND t_class.data_cancellazione is NULL
             AND d_class_tipo.data_cancellazione is NULL
             AND capitolo.data_cancellazione is NULL
             and r_class_fam_tree.data_cancellazione is NULL;    
                          
       		IF NOT FOUND THEN
       			/* se il settore non esiste restituisco un codice fittizio
                	e cerco se esiste la direzione */
     			sett_code='999';
				sett_descr='SETTORE NON CONFIGURATO';
        
              BEGIN
              SELECT  t_class.classif_code, t_class.classif_desc
                  INTO direz_code, direz_descr
                  from siac_r_bil_elem_class r_bil_elem_class,
                      siac_t_class			t_class,
                      siac_d_class_tipo		d_class_tipo ,
                      siac_t_bil_elem    		capitolo               
              where 
                  r_bil_elem_class.elem_id 			= 	capitolo.elem_id
                  and t_class.classif_id 					= 	r_bil_elem_class.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 -- AND d_class_tipo.classif_tipo_desc='Centro di Respondabilita''(Direzione)'
                 and d_class_tipo.classif_tipo_code='CDR'
                  and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL
                   AND capitolo.data_cancellazione is NULL;	
             IF NOT FOUND THEN
             	/* se non esiste la direzione restituisco un codice fittizio */
              direz_code='999';
              direz_descr='DIREZIONE NON CONFIGURATA';         
              END IF;
          END;
        
       ELSE
       		/* cerco la direzione con l'ID padre del settore */
         BEGIN
          SELECT  t_class.classif_code, t_class.classif_desc
              INTO direz_code, direz_descr
          from siac_t_class t_class
          where t_class.classif_id= classif_id_padre;
          IF NOT FOUND THEN
          	direz_code='999';
			direz_descr='DIREZIONE NON CONFIGURATA';  
          END IF;
          END;
        
        END IF;
    END;    

ELSE
		/* se non c'e' l'ID capitolo restituisco i campi vuoti */
	direz_code='';
	direz_descr='';
	sett_code='';
	sett_descr='';
END IF;
--direz_code='PPPP';
--sett_code='999';

return next;
bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
stanziamento_prev_cassa_anno:=0;
stanziamento_prev_res_anno:=0;
direz_code='';
direz_descr='';
sett_code='';
sett_descr='';
classif_id_padre=0;


end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_tit_tip_cat_riga where utente=user_table;

delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(integer, character varying)
  OWNER TO siac;
GRANT EXECUTE ON FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(integer, character varying) TO public;
GRANT EXECUTE ON FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(integer, character varying) TO siac;
GRANT EXECUTE ON FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(integer, character varying) TO siac_rw;


DROP FUNCTION siac."BILR146_peg_spese_gestione_strut_capitolo"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION "BILR146_peg_spese_gestione_strut_capitolo"(IN p_ente_prop_id integer, IN p_anno character varying)
  RETURNS TABLE(bil_anno character varying, missione_tipo_code character varying, missione_tipo_desc character varying, missione_code character varying, missione_desc character varying, programma_tipo_code character varying, programma_tipo_desc character varying, programma_code character varying, programma_desc character varying, titusc_tipo_code character varying, titusc_tipo_desc character varying, titusc_code character varying, titusc_desc character varying, macroag_tipo_code character varying, macroag_tipo_desc character varying, macroag_code character varying, macroag_desc character varying, bil_ele_code character varying, bil_ele_desc character varying, bil_ele_code2 character varying, bil_ele_desc2 character varying, bil_ele_id integer, bil_ele_id_padre integer, stanziamento_prev_res_anno numeric, stanziamento_anno_prec numeric, stanziamento_prev_cassa_anno numeric, stanziamento_prev_anno numeric, stanziamento_prev_anno1 numeric, stanziamento_prev_anno2 numeric, stanziamento_fpv_anno_prec numeric, stanziamento_fpv_anno numeric, stanziamento_fpv_anno1 numeric, stanziamento_fpv_anno2 numeric, fase_bilancio character varying, capitolo_prec integer, bil_ele_code3 character varying, direz_code character varying, direz_descr character varying, sett_code character varying, sett_descr character varying, codice_conto_finanz character varying) AS
$BODY$
DECLARE

classifBilRec record;


annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
classif_id_padre integer;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN
/*
	Questa Procedura nasce come copia della procedura BILR046_peg_spese_previsione.
    Le modifiche effettuate sono quelle per estrarre i dati  dei capitoli di
    GESTIONE invece che di PREVISIONE.
    Per comodita' sono state lasciate le stesse tabelle di appoggio (es. siac_rep_cap_ep_imp_riga)
    usate dalla procedura di previsione.
    Anche i nomi dei campi di output sono gli stessi in modo da non dover effettuare
    troppi cambiamenti al report BILR077_peg_senza_fpv_gestione che e' copiato dal
    BILR046_peg_senza_fpv.
*/
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;


select fnc_siac_random_user()
into	user_table;

anno_bil_impegni:=p_anno;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
tipologia_capitolo='';

direz_code='';
direz_descr='';
sett_code='';
sett_descr='';
classif_id_padre=0;
codice_conto_finanz='';

     RTN_MESSAGGIO:='lettura struttura del bilancio''.';  

with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 05/09/2016: start filtro per mis-prog-macro*/
   , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 05/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;


     RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
     
     
insert into siac_rep_cap_ug
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        (select t_class_upb.classif_code
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 
                class_upb.classif_tipo_code in('PDC_V' , 'PDC_IV')	and
                --class_upb.classif_tipo_code in('CLASSIFICATORE_1')					and		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 				and
                t_class_upb.classif_id=r_capitolo_upb.classif_id					AND
                capitolo.elem_id=r_capitolo_upb.elem_id
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null	),
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	--stato_capitolo.elem_stato_code	=	'VA'								and
    stato_capitolo.elem_stato_code		in ('VA', 'PR')						and 
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    ---------and	cat_del_capitolo.elem_cat_code	=	'STD'	    
	--cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC') -- ANNA 2206 FPV e FSC
    and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
	and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
    and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
    and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
    and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
    and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
    and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
    and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
    and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
    and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
    and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
    and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
    and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	


  /* inserisco i capitoli che non hanno una struttura */
 insert into siac_rep_cap_ug
      select null, null,
        anno_eserc.anno anno_bilancio,
        e.*, 
        (select t_class_upb.classif_code
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 
                class_upb.classif_tipo_code in('PDC_V' , 'PDC_IV')	and
                --class_upb.classif_tipo_code in('CLASSIFICATORE_1')					and		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 				and
                t_class_upb.classif_id=r_capitolo_upb.classif_id					AND
                e.elem_id=r_capitolo_upb.elem_id
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null	),
            user_table utente
       from 	
              siac_t_bil_elem e,
              siac_t_bil bilancio,
              siac_t_periodo anno_eserc,
              siac_d_bil_elem_tipo tipo_elemento, 
              siac_d_bil_elem_stato stato_capitolo,
              siac_r_bil_elem_stato r_capitolo_stato
      where e.ente_proprietario_id=p_ente_prop_id
      and anno_eserc.anno					= 	p_anno
      and bilancio.periodo_id				=	anno_eserc.periodo_id 
      and e.bil_id						=	bilancio.bil_id 
      and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
      and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
      and	e.elem_id						=	r_capitolo_stato.elem_id
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id	 							
      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
      and e.data_cancellazione 				is null
      and	r_capitolo_stato.data_cancellazione	is null
      and	bilancio.data_cancellazione 		is null
      and	anno_eserc.data_cancellazione 		is null
      and	tipo_elemento.data_cancellazione	is null
      and	stato_capitolo.data_cancellazione 	is null
      and not EXISTS
      (
         select 1 from siac_rep_cap_ug x
         where x.elem_id = e.elem_id
         and x.utente=user_table
    );

     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp standard''.';  

insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo       
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	in ('VA', 'PR')								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        -- 05/09/2016: aggiunto FPVC
		--and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV E FSC						
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

-----------------   importo capitoli di tipo fondo pluriennale vincolato ------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp fpv''.';  


-----------------------------------------------------------------------------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga STD''.';  


insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
         where			
    	tb1.elem_id	=	tb2.elem_id
        and 
        tb2.elem_id	=	tb3.elem_id
        and 
        tb3.elem_id	=	tb4.elem_id
        and 
        tb4.elem_id	=	tb5.elem_id
        and 
        tb5.elem_id	=	tb6.elem_id
        and -- 05/09/2016: aggiunto FPVC
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp			--and	tb1.tipo_capitolo 		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV	
        AND
        tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp 		--and	tb2.tipo_capitolo		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV	
        and
        tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp		--and	tb3.tipo_capitolo		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV				 
        and 
    	tb4.periodo_anno = tb1.periodo_anno AND	tb4.tipo_imp = 	TipoImpRes		--and	tb4.tipo_capitolo		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV	
        and 
    	tb5.periodo_anno = tb1.periodo_anno AND	tb5.tipo_imp = 	TipoImpstanzresidui	--and	tb5.tipo_capitolo	in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV	
        and 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa;	--and	tb6.tipo_capitolo		in ('STD','FSC','FPV','FPVC');  -- ANNA 2206 FPV	

     RTN_MESSAGGIO:='insert tabella siac_rep_mptm_up_cap_importi''.';  

insert into siac_rep_mptm_up_cap_importi
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno,
        v1.ente_proprietario_id,
        user_table utente,
        tbprec.elem_id_old,
        tb.codice_pdc	upb,
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2        
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			   join siac_rep_cap_ug tb
           		on  (v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and tb.elem_id is not null
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_up_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
            left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id     
            and tbprec.data_cancellazione is null          
union
    select	
        'Missione'							missione_tipo_desc,
        '00'								missione_code,
        ' '									missione_desc,
        'Programma'							programma_tipo_desc,
        '0000'								programma_code,
        ' '									programma_desc,
        'Titolo Spesa'						titusc_tipo_desc,
        '0'									titusc_code,
        ' '									titusc_desc,  
        'Macroaggregato'					macroag_tipo_desc,
    	'0000000'							macroag_code,
      	' '									macroag_desc,           
    	tb.bil_anno   						BIL_ANNO,        
       	tb.elem_code     					BIL_ELE_CODE,
        tb.elem_code2     					BIL_ELE_CODE2,
        tb.elem_code3						BIL_ELE_CODE3,
       	tb.elem_desc     					BIL_ELE_DESC,    
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno,
        tb.ente_proprietario_id,
        user_table utente,
        NULL,
        tb.codice_pdc,
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2 
from  	siac_t_ente_proprietario t_ente,
		 siac_rep_cap_ug tb
            left	join    siac_rep_cap_up_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)           
    where t_ente.ente_proprietario_id=tb.ente_proprietario_id
    and tb.utente = user_table    	
   and (tb.programma_id is null or tb.macroaggregato_id is NULL)             
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;

   

      
 RTN_MESSAGGIO:='preparazione file output ''.'; 
 
 for classifBilRec in
	select 	t1.missione_tipo_desc	missione_tipo_desc,
            t1.missione_code		missione_code,
            t1.missione_desc		missione_desc,
            t1.programma_tipo_desc	programma_tipo_desc,
            t1.programma_code		programma_code,
            t1.programma_desc		programma_desc,
            t1.titusc_tipo_desc		titusc_tipo_desc,
            t1.titusc_code			titusc_code,
            t1.titusc_desc			titusc_desc,
            t1.macroag_tipo_desc	macroag_tipo_desc,
            t1.macroag_code			macroag_code,
            t1.macroag_desc			macroag_desc,
            t1.bil_anno   			BIL_ANNO,
            t1.elem_code     		BIL_ELE_CODE,
            t1.elem_code2     		BIL_ELE_CODE2,
            t1.elem_code3			BIL_ELE_CODE3,
            t1.elem_desc     		BIL_ELE_DESC,
            t1.elem_desc2     		BIL_ELE_DESC2,
            t1.elem_id      		BIL_ELE_ID,
            t1.elem_id_padre    	BIL_ELE_ID_PADRE,           
            COALESCE(t1.stanziamento_prev_anno,0)	stanziamento_prev_anno,
            COALESCE(t1.stanziamento_prev_anno1,0)	stanziamento_prev_anno1,
            COALESCE(t1.stanziamento_prev_anno2,0)	stanziamento_prev_anno2,
            COALESCE(t1.stanziamento_prev_res_anno,0)	stanziamento_prev_res_anno,
            COALESCE(t1.stanziamento_anno_prec,0)	stanziamento_anno_prec,
            COALESCE(t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
            COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        	COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        	COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        	COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2,   
            COALESCE(t1.codice_pdc,' ') codice_conto_finanz 
    from siac_rep_mptm_up_cap_importi t1 
            	/* aggiunto questo join x estrarre l'eventuale riferimento all'ex capitolo */
        /*   left 	join 	siac_r_bil_elem_rel_tempo rel_tempo on rel_tempo.elem_id 	=  t1.elem_id and rel_tempo.data_cancellazione is null
            left	join 	siac_t_bil_elem		bil_elem	on bil_elem.elem_id = rel_tempo.elem_id_old and bil_elem.data_cancellazione is null                          */
            where 
            COALESCE(t1.stanziamento_prev_anno,0)	> 0 OR
            COALESCE(t1.stanziamento_prev_anno1,0)	> 0 OR
            COALESCE(t1.stanziamento_prev_anno2,0)	> 0 OR
            COALESCE(t1.stanziamento_prev_res_anno,0)	> 0 OR
            COALESCE(t1.stanziamento_prev_cassa_anno,0)	> 0 OR
        	COALESCE(t1.stanziamento_fpv_anno,0)	> 0 OR
        	COALESCE(t1.stanziamento_fpv_anno1,0)	> 0 OR
        	COALESCE(t1.stanziamento_fpv_anno2,0)	> 0    
            order by missione_code,programma_code,titusc_code,macroag_code   	
loop
      missione_tipo_desc:= classifBilRec.missione_tipo_desc;
      missione_code:= classifBilRec.missione_code;
      missione_desc:= classifBilRec.missione_desc;
      programma_tipo_desc:= classifBilRec.programma_tipo_desc;
      programma_code:= classifBilRec.programma_code;
      programma_desc:= classifBilRec.programma_desc;
      titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
      titusc_code:= classifBilRec.titusc_code;
      titusc_desc:= classifBilRec.titusc_desc;
      macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
      macroag_code:= classifBilRec.macroag_code;
      macroag_desc:= classifBilRec.macroag_desc;
      bil_anno:=classifBilRec.bil_anno;
      bil_ele_code:=classifBilRec.bil_ele_code;
      bil_ele_desc:=classifBilRec.bil_ele_desc;
      bil_ele_code2:=classifBilRec.bil_ele_code2;
      bil_ele_desc2:=classifBilRec.bil_ele_desc2;
      bil_ele_id:=classifBilRec.bil_ele_id;
      bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
      bil_anno:=p_anno;
      stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
      stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
      stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
      stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
      stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
      stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
      stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
      stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
      stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
      stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;      
      codice_conto_finanz=classifBilRec.codice_conto_finanz;

      IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN
              /* Cerco il settore e prendo anche l'ID dell'elemento padre per cercare poi
                  la direzione */    
              SELECT   t_class.classif_code, t_class.classif_desc, r_class_fam_tree.classif_id_padre 
              INTO sett_code, sett_descr, classif_id_padre      
                  from siac_r_bil_elem_class r_bil_elem_class,
                      siac_r_class_fam_tree r_class_fam_tree,
                      siac_t_class			t_class,
                      siac_d_class_tipo		d_class_tipo ,
                      siac_t_bil_elem    		capitolo               
              where 
                  r_bil_elem_class.elem_id 			= 	capitolo.elem_id
                  and t_class.classif_id 					= 	r_bil_elem_class.classif_id
                  and t_class.classif_id 					= 	r_class_fam_tree.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
                  and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                  and capitolo.ente_proprietario_id=p_ente_prop_id
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL
                   AND capitolo.data_cancellazione is NULL
                   and r_class_fam_tree.data_cancellazione is NULL;    
                                
                  IF NOT FOUND THEN
                      /* se il settore non esiste restituisco un codice fittizio
                          e cerco se esiste la direzione */
                      sett_code='999';
                      sett_descr='SETTORE NON CONFIGURATO';
                                  
                    SELECT  t_class.classif_code, t_class.classif_desc
                        INTO direz_code, direz_descr
                        from siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class			t_class,
                            siac_d_class_tipo		d_class_tipo ,
                            siac_t_bil_elem    		capitolo               
                    where 
                        r_bil_elem_class.elem_id 			= 	capitolo.elem_id
                        and t_class.classif_id 					= 	r_bil_elem_class.classif_id
                        and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                       -- AND d_class_tipo.classif_tipo_desc='Centro di Respondabilita''(Direzione)'
                       and d_class_tipo.classif_tipo_code='CDR'
                        and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                        and capitolo.ente_proprietario_id=p_ente_prop_id
                         AND r_bil_elem_class.data_cancellazione is NULL
                         AND t_class.data_cancellazione is NULL
                         AND d_class_tipo.data_cancellazione is NULL
                         AND capitolo.data_cancellazione is NULL;	
                   IF NOT FOUND THEN
                      /* se non esiste la direzione restituisco un codice fittizio */
                    direz_code='999';
                    direz_descr='DIREZIONE NON CONFIGURATA';         
                    END IF;                              
             ELSE
                  /* cerco la direzione con l'ID padre del settore */
                SELECT  t_class.classif_code, t_class.classif_desc
                    INTO direz_code, direz_descr
                from siac_t_class t_class
                where t_class.classif_id= classif_id_padre;
                IF NOT FOUND THEN
                  direz_code='999';
                  direz_descr='DIREZIONE NON CONFIGURATA';  
                END IF;              
              END IF;
      ELSE
              /* se non c'e' l'ID capitolo restituisco i campi vuoti */
          direz_code='';
          direz_descr='';
          sett_code='';
          sett_descr='';
      END IF;

	return next;
    bil_anno='';
    missione_tipo_code='';
    missione_tipo_desc='';
    missione_code='';
    missione_desc='';
    programma_tipo_code='';
    programma_tipo_desc='';
    programma_code='';
    programma_desc='';
    titusc_tipo_code='';
    titusc_tipo_desc='';
    titusc_code='';
    titusc_desc='';
    macroag_tipo_code='';
    macroag_tipo_desc='';
    macroag_code='';
    macroag_desc='';
    bil_ele_code='';
    bil_ele_desc='';
    bil_ele_code2='';
    bil_ele_desc2='';
    bil_ele_id=0;
    bil_ele_id_padre=0;
    stanziamento_prev_res_anno=0;
    stanziamento_anno_prec=0;
    stanziamento_prev_cassa_anno=0;
    stanziamento_prev_anno=0;
    stanziamento_prev_anno1=0;
    stanziamento_prev_anno2=0;    
    stanziamento_fpv_anno_prec=0;
    stanziamento_fpv_anno=0;
    stanziamento_fpv_anno1=0;
    stanziamento_fpv_anno2=0;
    direz_code='';
    direz_descr='';
    sett_code='';
    sett_descr='';
	classif_id_padre=0;
    codice_conto_finanz='';
    
end loop;
--end if;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga	where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;


raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION "BILR146_peg_spese_gestione_strut_capitolo"(integer, character varying)
  OWNER TO siac;
GRANT EXECUTE ON FUNCTION "BILR146_peg_spese_gestione_strut_capitolo"(integer, character varying) TO public;
GRANT EXECUTE ON FUNCTION "BILR146_peg_spese_gestione_strut_capitolo"(integer, character varying) TO siac;
GRANT EXECUTE ON FUNCTION "BILR146_peg_spese_gestione_strut_capitolo"(integer, character varying) TO siac_rw;

-- MODIFICHE da CSI - Maurizio - FINE

-- SIAC-5132 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR166_rend_gest_costi_missione_all_h" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  pdce_finanz_code varchar,
  pdce_finanz_descr varchar,
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  importo_impegno numeric,
  code_missione varchar,
  desc_missione varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_competenza_int integer;
 
sqlQuery varchar;

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
pdce_finanz_code:='';
pdce_finanz_descr:='';
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
importo_impegno:=0;
code_missione:='';
desc_missione:='';
anno_competenza_int=p_anno ::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
with impegni as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                 CASE WHEN d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'                 
                    THEN 'IMP'
                    ELSE 'SUB' end tipo_impegno,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,            
                siac_r_movgest_ts_atto_amm r_movgest_ts_atto,
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	
               AND r_movgest_ts_atto.movgest_ts_id=t_movgest_ts.movgest_ts_id            
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno
                AND t_movgest.movgest_anno =anno_competenza_int
                AND d_movgest_tipo.movgest_tipo_code='I'    --impegno  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                	-- Impegni DEFINITIVI o DEFINITIVI NON LIQUIDABILI
                AND d_movgest_stato.movgest_stato_code  in ('D','N') 
                AND d_movgest_ts_tipo.movgest_ts_tipo_code = 'T' --solo impegni non sub-impegni
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND r_movgest_ts_atto.data_cancellazione IS NULL
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL),
capitoli as(
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        anno_eserc.anno anno_bilancio,
        r_movgest_bil_elem.movgest_id,
       	capitolo.*
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_r_movgest_bil_elem r_movgest_bil_elem 
where 	
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and    
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and    
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and	
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and    	
    r_movgest_bil_elem.elem_id = capitolo.elem_id							and
    programma_tipo.classif_tipo_code='PROGRAMMA'							and	
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and	
    tipo_elemento.elem_tipo_code = 'CAP-UG'						     		and
    stato_capitolo.elem_stato_code	=	'VA'								and 
    capitolo.ente_proprietario_id=p_ente_prop_id 							and
   	anno_eserc.anno=p_anno													     								
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null
    and r_movgest_bil_elem.data_cancellazione		is null),
elenco_pdce_finanz as (        
	SELECT  r_movgest_class.movgest_ts_id,
           COALESCE( t_class.classif_code,'') pdce_code, 
            COALESCE(t_class.classif_desc,'') pdce_desc 
        from siac_r_movgest_class r_movgest_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where t_class.classif_id 					= 	r_movgest_class.classif_id
                 and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and d_class_tipo.classif_tipo_code like 'PDC_%'			
                   and r_movgest_class.ente_proprietario_id=p_ente_prop_id
                   AND r_movgest_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL    )  ,    
     strut_bilancio as(
     		select *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,''))                                  
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
	COALESCE(elenco_pdce_finanz.pdce_code,'')::varchar pdce_finanz_code,
    COALESCE(elenco_pdce_finanz.pdce_desc,'')::varchar pdce_finanz_descr,
    impegni.movgest_numero::numeric num_impegno,
    impegni.movgest_anno::integer anno_impegno,
    impegni.movgest_ts_code::varchar num_subimpegno,
	COALESCE(impegni.movgest_ts_det_importo,0)::numeric importo_impegno,
    COALESCE(strut_bilancio.missione_code,'') code_missione,
    COALESCE(strut_bilancio.missione_desc,'') desc_missione
/*FROM strut_bilancio 
	LEFT JOIN capitoli on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
    LEFT JOIN impegni on impegni.movgest_id = capitoli.movgest_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.movgest_ts_id = impegni.movgest_ts_id 
   */
   FROM impegni 
	LEFT JOIN capitoli on capitoli.movgest_id = impegni.movgest_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.movgest_ts_id = impegni.movgest_ts_id 
    FULL JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
ORDER BY code_missione,anno_impegno, num_impegno, num_subimpegno) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun accertamento trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;


-- 31.08.2017 Sofia - aggiunta condizione not exists in seguenti insert su 
-- siac_t_report
-- siac_t_report_importi

INSERT INTO SIAC_T_REPORT (rep_codice,
                           rep_desc,
                           rep_birt_codice,
                           validita_inizio,
                           validita_fine,
                           ente_proprietario_id,
                           data_creazione,
                           data_modifica,
                           data_cancellazione,
                           login_operazione)
select 'BILR166',
       'Allegato h - Prospetto dei costi per missione(BILR166)',
       'BILR166_Prospetto_costi_per_missione',
       to_date('01/01/2017','dd/mm/yyyy'),
       null,
       a.ente_proprietario_id,
       now(),
       now(),
       null,
       'admin'
from siac_t_ente_proprietario a
where a.data_cancellazione is  null
and not exists 
(select 1 from SIAC_T_REPORT r1 where r1.rep_codice='BILR166' and r1.ente_proprietario_id=a.ente_proprietario_id);

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss01_variaz_rimanenz_materie',
        'Missione 01 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists 
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss01_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id);  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss01_ammort_immob_immateriali',
        'Missione 01 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss01_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id);  


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss01_ammort_immob_materiali',
        'Missione 01 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss01_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss01_altre_svalut_immobiliz',
        'Missione 01 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss01_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss01_svalut_crediti',
        'Missione 01 - Svalutazione dei crediti',
        0,
        'N',
        5,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss01_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss01_accanton_rischi',
        'Missione 01 - Accantonamento per rischi',
        0,
        'N',
        6,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss01_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss01_altri_accanton',
        'Missione 01 - Altri accantonamenti',
        0,
        'N',
        7,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss01_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss01_svalutazioni',
        'Missione 01 - Svalutazioni',
        0,
        'N',
        8,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss01_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss01_soprav_passivo_e_insussist_attivo',
        'Missione 01 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss01_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss01_minusvalenze_patrimoniali',
        'Missione 01 - Minusvalenze patrimoniali',
        0,
        'N',
        10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss01_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss02_variaz_rimanenz_materie',
        'Missione 02 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss02_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss02_ammort_immob_immateriali',
        'Missione 02 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss02_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss02_ammort_immob_materiali',
        'Missione 02 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss02_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss02_altre_svalut_immobiliz',
        'Missione 02 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss02_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss02_svalut_crediti',
        'Missione 02 - Svalutazione dei crediti',
        0,
        'N',
        5+10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss02_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss02_accanton_rischi',
        'Missione 02 - Accantonamento per rischi',
        0,
        'N',
        6+10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss02_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss02_altri_accanton',
        'Missione 02 - Altri accantonamenti',
        0,
        'N',
        7+10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss02_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss02_svalutazioni',
        'Missione 02 - Svalutazioni',
        0,
        'N',
        8+10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss02_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss02_soprav_passivo_e_insussist_attivo',
        'Missione 02 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss02_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss02_minusvalenze_patrimoniali',
        'Missione 02 - Minusvalenze patrimoniali',
        0,
        'N',
        10+10,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss02_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss03_variaz_rimanenz_materie',
        'Missione 03 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+20,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss03_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss03_ammort_immob_immateriali',
        'Missione 03 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+20,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss03_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss03_ammort_immob_materiali',
        'Missione 03 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+20,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss03_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss03_altre_svalut_immobiliz',
        'Missione 03 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+20,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss03_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss03_svalut_crediti',
        'Missione 03 - Svalutazione dei crediti',
        0,
        'N',
        5+20,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss03_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss03_accanton_rischi',
        'Missione 03 - Accantonamento per rischi',
        0,
        'N',
        6+20,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss03_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss03_altri_accanton',
        'Missione 03 - Altri accantonamenti',
        0,
        'N',
        7+20,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss03_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss03_svalutazioni',
        'Missione 03 - Svalutazioni',
        0,
        'N',
        8+20,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss03_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss03_soprav_passivo_e_insussist_attivo',
        'Missione 03 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+20,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss03_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss03_minusvalenze_patrimoniali',
        'Missione 03 - Minusvalenze patrimoniali',
        0,
        'N',
        10+20,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss03_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss04_variaz_rimanenz_materie',
        'Missione 04 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+30,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss04_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss04_ammort_immob_immateriali',
        'Missione 04 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+30,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss04_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss04_ammort_immob_materiali',
        'Missione 04 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+30,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss04_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss04_altre_svalut_immobiliz',
        'Missione 04 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+30,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss04_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss04_svalut_crediti',
        'Missione 04 - Svalutazione dei crediti',
        0,
        'N',
        5+30,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss04_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss04_accanton_rischi',
        'Missione 04 - Accantonamento per rischi',
        0,
        'N',
        6+30,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss04_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss04_altri_accanton',
        'Missione 04 - Altri accantonamenti',
        0,
        'N',
        7+30,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss04_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss04_svalutazioni',
        'Missione 04 - Svalutazioni',
        0,
        'N',
        8+30,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss04_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss04_soprav_passivo_e_insussist_attivo',
        'Missione 04 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+30,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss04_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss04_minusvalenze_patrimoniali',
        'Missione 04 - Minusvalenze patrimoniali',
        0,
        'N',
        10+30,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss04_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss05_variaz_rimanenz_materie',
        'Missione 05 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+40,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss05_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss05_ammort_immob_immateriali',
        'Missione 05 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+40,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss05_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss05_ammort_immob_materiali',
        'Missione 05 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+40,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss05_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss05_altre_svalut_immobiliz',
        'Missione 05 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+40,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss05_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss05_svalut_crediti',
        'Missione 05 - Svalutazione dei crediti',
        0,
        'N',
        5+40,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss05_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss05_accanton_rischi',
        'Missione 05 - Accantonamento per rischi',
        0,
        'N',
        6+40,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss05_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss05_altri_accanton',
        'Missione 05 - Altri accantonamenti',
        0,
        'N',
        7+40,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss05_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss05_svalutazioni',
        'Missione 05 - Svalutazioni',
        0,
        'N',
        8+40,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss05_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss05_soprav_passivo_e_insussist_attivo',
        'Missione 05 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+40,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss05_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss05_minusvalenze_patrimoniali',
        'Missione 05 - Minusvalenze patrimoniali',
        0,
        'N',
        10+40,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss05_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 

-- QUI
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss06_variaz_rimanenz_materie',
        'Missione 06 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+50,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss06_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss06_ammort_immob_immateriali',
        'Missione 06 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+50,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss06_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss06_ammort_immob_materiali',
        'Missione 06 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+50,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss06_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss06_altre_svalut_immobiliz',
        'Missione 06 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+50,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss06_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss06_svalut_crediti',
        'Missione 06 - Svalutazione dei crediti',
        0,
        'N',
        5+50,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss06_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss06_accanton_rischi',
        'Missione 06 - Accantonamento per rischi',
        0,
        'N',
        6+50,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss06_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss06_altri_accanton',
        'Missione 06 - Altri accantonamenti',
        0,
        'N',
        7+50,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss06_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss06_svalutazioni',
        'Missione 06 - Svalutazioni',
        0,
        'N',
        8+50,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss06_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss06_soprav_passivo_e_insussist_attivo',
        'Missione 06 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+50,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss06_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss06_minusvalenze_patrimoniali',
        'Missione 06 - Minusvalenze patrimoniali',
        0,
        'N',
        10+50,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss06_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss07_variaz_rimanenz_materie',
        'Missione 07 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+60,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss07_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss07_ammort_immob_immateriali',
        'Missione 07 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+60,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss07_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss07_ammort_immob_materiali',
        'Missione 07 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+60,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss07_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss07_altre_svalut_immobiliz',
        'Missione 07 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+60,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss07_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss07_svalut_crediti',
        'Missione 07 - Svalutazione dei crediti',
        0,
        'N',
        5+60,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss07_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss07_accanton_rischi',
        'Missione 07 - Accantonamento per rischi',
        0,
        'N',
        6+60,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss07_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss07_altri_accanton',
        'Missione 07 - Altri accantonamenti',
        0,
        'N',
        7+60,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss07_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss07_svalutazioni',
        'Missione 07 - Svalutazioni',
        0,
        'N',
        8+60,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss07_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss07_soprav_passivo_e_insussist_attivo',
        'Missione 07 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+60,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss07_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss07_minusvalenze_patrimoniali',
        'Missione 07 - Minusvalenze patrimoniali',
        0,
        'N',
        10+60,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss07_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss08_variaz_rimanenz_materie',
        'Missione 08 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+70,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss08_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss08_ammort_immob_immateriali',
        'Missione 08 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+70,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss08_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss08_ammort_immob_materiali',
        'Missione 08 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+70,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss08_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss08_altre_svalut_immobiliz',
        'Missione 08 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+70,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss08_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss08_svalut_crediti',
        'Missione 08 - Svalutazione dei crediti',
        0,
        'N',
        5+70,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss08_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss08_accanton_rischi',
        'Missione 08 - Accantonamento per rischi',
        0,
        'N',
        6+70,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss08_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss08_altri_accanton',
        'Missione 08 - Altri accantonamenti',
        0,
        'N',
        7+70,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss08_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss08_svalutazioni',
        'Missione 08 - Svalutazioni',
        0,
        'N',
        8+70,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss08_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss08_soprav_passivo_e_insussist_attivo',
        'Missione 08 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+70,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss08_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss08_minusvalenze_patrimoniali',
        'Missione 08 - Minusvalenze patrimoniali',
        0,
        'N',
        10+70,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss08_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss09_variaz_rimanenz_materie',
        'Missione 09 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+80,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss09_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss09_ammort_immob_immateriali',
        'Missione 09 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+80,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss09_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss09_ammort_immob_materiali',
        'Missione 09 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+80,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss09_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss09_altre_svalut_immobiliz',
        'Missione 09 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+80,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss09_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss09_svalut_crediti',
        'Missione 09 - Svalutazione dei crediti',
        0,
        'N',
        5+80,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss09_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss09_accanton_rischi',
        'Missione 09 - Accantonamento per rischi',
        0,
        'N',
        6+80,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss09_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 

 

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss09_altri_accanton',
        'Missione 09 - Altri accantonamenti',
        0,
        'N',
        7+80,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss09_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss09_svalutazioni',
        'Missione 09 - Svalutazioni',
        0,
        'N',
        8+80,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss09_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss09_soprav_passivo_e_insussist_attivo',
        'Missione 09 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+80,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss09_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss09_minusvalenze_patrimoniali',
        'Missione 09 - Minusvalenze patrimoniali',
        0,
        'N',
        10+80,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss09_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss10_variaz_rimanenz_materie',
        'Missione 10 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+90,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss10_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss10_ammort_immob_immateriali',
        'Missione 10 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+90,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss10_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss10_ammort_immob_materiali',
        'Missione 10 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+90,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss10_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss10_altre_svalut_immobiliz',
        'Missione 10 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+90,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss10_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss10_svalut_crediti',
        'Missione 10 - Svalutazione dei crediti',
        0,
        'N',
        5+90,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss10_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss10_accanton_rischi',
        'Missione 10 - Accantonamento per rischi',
        0,
        'N',
        6+90,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss10_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss10_altri_accanton',
        'Missione 10 - Altri accantonamenti',
        0,
        'N',
        7+90,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss10_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss10_svalutazioni',
        'Missione 10 - Svalutazioni',
        0,
        'N',
        8+90,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss10_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss10_soprav_passivo_e_insussist_attivo',
        'Missione 10 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+90,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss10_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss10_minusvalenze_patrimoniali',
        'Missione 10 - Minusvalenze patrimoniali',
        0,
        'N',
        10+90,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss10_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss11_variaz_rimanenz_materie',
        'Missione 11 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+100,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss11_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss11_ammort_immob_immateriali',
        'Missione 11 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+100,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss11_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss11_ammort_immob_materiali',
        'Missione 11 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+100,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss11_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss11_altre_svalut_immobiliz',
        'Missione 11 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+100,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss11_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss11_svalut_crediti',
        'Missione 11 - Svalutazione dei crediti',
        0,
        'N',
        5+100,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss11_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss11_accanton_rischi',
        'Missione 11 - Accantonamento per rischi',
        0,
        'N',
        6+100,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss11_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss11_altri_accanton',
        'Missione 11 - Altri accantonamenti',
        0,
        'N',
        7+100,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss11_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss11_svalutazioni',
        'Missione 11 - Svalutazioni',
        0,
        'N',
        8+100,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss11_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss11_soprav_passivo_e_insussist_attivo',
        'Missione 11 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+100,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss11_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss11_minusvalenze_patrimoniali',
        'Missione 11 - Minusvalenze patrimoniali',
        0,
        'N',
        10+100,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss11_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss12_variaz_rimanenz_materie',
        'Missione 12 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+110,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss12_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss12_ammort_immob_immateriali',
        'Missione 12 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+110,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss12_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss12_ammort_immob_materiali',
        'Missione 12 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+110,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss12_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss12_altre_svalut_immobiliz',
        'Missione 12 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+110,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss12_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss12_svalut_crediti',
        'Missione 12 - Svalutazione dei crediti',
        0,
        'N',
        5+110,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss12_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss12_accanton_rischi',
        'Missione 12 - Accantonamento per rischi',
        0,
        'N',
        6+110,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss12_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss12_altri_accanton',
        'Missione 12 - Altri accantonamenti',
        0,
        'N',
        7+110,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss12_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss12_svalutazioni',
        'Missione 12 - Svalutazioni',
        0,
        'N',
        8+110,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss12_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss12_soprav_passivo_e_insussist_attivo',
        'Missione 12 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+110,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss12_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss12_minusvalenze_patrimoniali',
        'Missione 12 - Minusvalenze patrimoniali',
        0,
        'N',
        10+110,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss12_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss13_variaz_rimanenz_materie',
        'Missione 13 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+120,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss13_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss13_ammort_immob_immateriali',
        'Missione 13 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+120,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss13_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss13_ammort_immob_materiali',
        'Missione 13 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+120,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss13_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss13_altre_svalut_immobiliz',
        'Missione 13 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+120,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss13_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss13_svalut_crediti',
        'Missione 13 - Svalutazione dei crediti',
        0,
        'N',
        5+120,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss13_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss13_accanton_rischi',
        'Missione 13 - Accantonamento per rischi',
        0,
        'N',
        6+120,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss13_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss13_altri_accanton',
        'Missione 13 - Altri accantonamenti',
        0,
        'N',
        7+120,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss13_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss13_svalutazioni',
        'Missione 13 - Svalutazioni',
        0,
        'N',
        8+120,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss13_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss13_soprav_passivo_e_insussist_attivo',
        'Missione 13 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+120,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss13_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss13_minusvalenze_patrimoniali',
        'Missione 13 - Minusvalenze patrimoniali',
        0,
        'N',
        10+120,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss13_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss14_variaz_rimanenz_materie',
        'Missione 14 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+130,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss14_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss14_ammort_immob_immateriali',
        'Missione 14 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+130,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss14_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss14_ammort_immob_materiali',
        'Missione 14 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+130,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss14_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss14_altre_svalut_immobiliz',
        'Missione 14 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+130,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss14_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss14_svalut_crediti',
        'Missione 14 - Svalutazione dei crediti',
        0,
        'N',
        5+130,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss14_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss14_accanton_rischi',
        'Missione 14 - Accantonamento per rischi',
        0,
        'N',
        6+130,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss14_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss14_altri_accanton',
        'Missione 14 - Altri accantonamenti',
        0,
        'N',
        7+130,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss14_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss14_svalutazioni',
        'Missione 14 - Svalutazioni',
        0,
        'N',
        8+130,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss14_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss14_soprav_passivo_e_insussist_attivo',
        'Missione 14 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+130,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss14_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss14_minusvalenze_patrimoniali',
        'Missione 14 - Minusvalenze patrimoniali',
        0,
        'N',
        10+130,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss14_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss15_variaz_rimanenz_materie',
        'Missione 15 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+140,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss15_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss15_ammort_immob_immateriali',
        'Missione 15 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+140,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss15_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss15_ammort_immob_materiali',
        'Missione 15 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+140,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss15_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss15_altre_svalut_immobiliz',
        'Missione 15 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+140,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss15_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss15_svalut_crediti',
        'Missione 15 - Svalutazione dei crediti',
        0,
        'N',
        5+140,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss15_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss15_accanton_rischi',
        'Missione 15 - Accantonamento per rischi',
        0,
        'N',
        6+140,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss15_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss15_altri_accanton',
        'Missione 15 - Altri accantonamenti',
        0,
        'N',
        7+140,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss15_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss15_svalutazioni',
        'Missione 15 - Svalutazioni',
        0,
        'N',
        8+140,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss15_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss15_soprav_passivo_e_insussist_attivo',
        'Missione 15 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+140,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss15_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss15_minusvalenze_patrimoniali',
        'Missione 15 - Minusvalenze patrimoniali',
        0,
        'N',
        10+140,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss15_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss16_variaz_rimanenz_materie',
        'Missione 16 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+150,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss16_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss16_ammort_immob_immateriali',
        'Missione 16 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+150,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss16_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss16_ammort_immob_materiali',
        'Missione 16 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+150,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss16_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss16_altre_svalut_immobiliz',
        'Missione 16 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+150,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss16_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss16_svalut_crediti',
        'Missione 16 - Svalutazione dei crediti',
        0,
        'N',
        5+150,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss16_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss16_accanton_rischi',
        'Missione 16 - Accantonamento per rischi',
        0,
        'N',
        6+150,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss16_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss16_altri_accanton',
        'Missione 16 - Altri accantonamenti',
        0,
        'N',
        7+150,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss16_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss16_svalutazioni',
        'Missione 16 - Svalutazioni',
        0,
        'N',
        8+150,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss16_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss16_soprav_passivo_e_insussist_attivo',
        'Missione 16 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+150,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss16_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss16_minusvalenze_patrimoniali',
        'Missione 16 - Minusvalenze patrimoniali',
        0,
        'N',
        10+150,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss16_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss17_variaz_rimanenz_materie',
        'Missione 17 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+160,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss17_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss17_ammort_immob_immateriali',
        'Missione 17 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+160,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss17_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss17_ammort_immob_materiali',
        'Missione 17 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+160,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss17_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss17_altre_svalut_immobiliz',
        'Missione 17 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+160,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss17_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss17_svalut_crediti',
        'Missione 17 - Svalutazione dei crediti',
        0,
        'N',
        5+160,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss17_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss17_accanton_rischi',
        'Missione 17 - Accantonamento per rischi',
        0,
        'N',
        6+160,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss17_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss17_altri_accanton',
        'Missione 17 - Altri accantonamenti',
        0,
        'N',
        7+160,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss17_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss17_svalutazioni',
        'Missione 17 - Svalutazioni',
        0,
        'N',
        8+160,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss17_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss17_soprav_passivo_e_insussist_attivo',
        'Missione 17 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+160,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss17_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss17_minusvalenze_patrimoniali',
        'Missione 17 - Minusvalenze patrimoniali',
        0,
        'N',
        10+160,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss17_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss18_variaz_rimanenz_materie',
        'Missione 18 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+170,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss18_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 



INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss18_ammort_immob_immateriali',
        'Missione 18 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+170,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss18_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss18_ammort_immob_materiali',
        'Missione 18 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+170,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss18_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss18_altre_svalut_immobiliz',
        'Missione 18 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+170,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss18_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss18_svalut_crediti',
        'Missione 18 - Svalutazione dei crediti',
        0,
        'N',
        5+170,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss18_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss18_accanton_rischi',
        'Missione 18 - Accantonamento per rischi',
        0,
        'N',
        6+170,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss18_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss18_altri_accanton',
        'Missione 18 - Altri accantonamenti',
        0,
        'N',
        7+170,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss18_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss18_svalutazioni',
        'Missione 18 - Svalutazioni',
        0,
        'N',
        8+170,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss18_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss18_soprav_passivo_e_insussist_attivo',
        'Missione 18 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+170,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss18_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss18_minusvalenze_patrimoniali',
        'Missione 18 - Minusvalenze patrimoniali',
        0,
        'N',
        10+170,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss18_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss19_variaz_rimanenz_materie',
        'Missione 19 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+180,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss19_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 



INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss19_ammort_immob_immateriali',
        'Missione 19 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+180,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss19_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss19_ammort_immob_materiali',
        'Missione 19 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+180,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss19_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss19_altre_svalut_immobiliz',
        'Missione 19 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+180,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss19_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss19_svalut_crediti',
        'Missione 19 - Svalutazione dei crediti',
        0,
        'N',
        5+180,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss19_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss19_accanton_rischi',
        'Missione 19 - Accantonamento per rischi',
        0,
        'N',
        6+180,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss19_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 



INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss19_altri_accanton',
        'Missione 19 - Altri accantonamenti',
        0,
        'N',
        7+180,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss19_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss19_svalutazioni',
        'Missione 19 - Svalutazioni',
        0,
        'N',
        8+180,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss19_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss19_soprav_passivo_e_insussist_attivo',
        'Missione 19 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+180,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss19_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss19_minusvalenze_patrimoniali',
        'Missione 19 - Minusvalenze patrimoniali',
        0,
        'N',
        10+180,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss19_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 



INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss20_variaz_rimanenz_materie',
        'Missione 20 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+190,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss20_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss20_ammort_immob_immateriali',
        'Missione 20 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+190,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss20_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss20_ammort_immob_materiali',
        'Missione 20 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+190,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss20_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss20_altre_svalut_immobiliz',
        'Missione 20 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+190,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss20_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss20_svalut_crediti',
        'Missione 20 - Svalutazione dei crediti',
        0,
        'N',
        5+190,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss20_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss20_accanton_rischi',
        'Missione 20 - Accantonamento per rischi',
        0,
        'N',
        6+190,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss20_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss20_altri_accanton',
        'Missione 20 - Altri accantonamenti',
        0,
        'N',
        7+190,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss20_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss20_svalutazioni',
        'Missione 20 - Svalutazioni',
        0,
        'N',
        8+190,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss20_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss20_soprav_passivo_e_insussist_attivo',
        'Missione 20 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+190,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss20_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss20_minusvalenze_patrimoniali',
        'Missione 20 - Minusvalenze patrimoniali',
        0,
        'N',
        10+190,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss20_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss50_variaz_rimanenz_materie',
        'Missione 50 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+200,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss50_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss50_ammort_immob_immateriali',
        'Missione 50 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+200,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss50_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss50_ammort_immob_materiali',
        'Missione 50 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+200,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss50_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss50_altre_svalut_immobiliz',
        'Missione 50 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+200,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss50_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss50_svalut_crediti',
        'Missione 50 - Svalutazione dei crediti',
        0,
        'N',
        5+200,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss50_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss50_accanton_rischi',
        'Missione 50 - Accantonamento per rischi',
        0,
        'N',
        6+200,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss50_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss50_altri_accanton',
        'Missione 50 - Altri accantonamenti',
        0,
        'N',
        7+200,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss50_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss50_svalutazioni',
        'Missione 50 - Svalutazioni',
        0,
        'N',
        8+200,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss50_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss50_soprav_passivo_e_insussist_attivo',
        'Missione 50 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+200,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss50_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss50_minusvalenze_patrimoniali',
        'Missione 50 - Minusvalenze patrimoniali',
        0,
        'N',
        10+200,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss50_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss60_variaz_rimanenz_materie',
        'Missione 60 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+210,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss60_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss60_ammort_immob_immateriali',
        'Missione 60 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+210,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss60_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss60_ammort_immob_materiali',
        'Missione 60 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+210,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss60_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss60_altre_svalut_immobiliz',
        'Missione 60 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+210,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss60_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss60_svalut_crediti',
        'Missione 60 - Svalutazione dei crediti',
        0,
        'N',
        5+210,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss60_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss60_accanton_rischi',
        'Missione 60 - Accantonamento per rischi',
        0,
        'N',
        6+210,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss60_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss60_altri_accanton',
        'Missione 60 - Altri accantonamenti',
        0,
        'N',
        7+210,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss60_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss60_svalutazioni',
        'Missione 60 - Svalutazioni',
        0,
        'N',
        8+210,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss60_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss60_soprav_passivo_e_insussist_attivo',
        'Missione 60 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+210,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss60_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss60_minusvalenze_patrimoniali',
        'Missione 60 - Minusvalenze patrimoniali',
        0,
        'N',
        10+210,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss60_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 



INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss99_variaz_rimanenz_materie',
        'Missione 99 - Variazioni nelle rimanenze di materie prime e/o beni di consumo (+/-)',
        0,
        'N',
        1+220,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss99_variaz_rimanenz_materie' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss99_ammort_immob_immateriali',
        'Missione 99 - Ammortamenti immobilizzazioni Immateriali',
        0,
        'N',
        2+220,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss99_ammort_immob_immateriali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss99_ammort_immob_materiali',
        'Missione 99 - Ammortamenti immobilizzazioni materiali',
        0,
        'N',
        3+220,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss99_ammort_immob_materiali' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss99_altre_svalut_immobiliz',
        'Missione 99 - Altre svalutazioni delle immobilizzazioni',
        0,
        'N',
        4+220,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss99_altre_svalut_immobiliz' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss99_svalut_crediti',
        'Missione 99 - Svalutazione dei crediti',
        0,
        'N',
        5+220,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss99_svalut_crediti' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss99_accanton_rischi',
        'Missione 99 - Accantonamento per rischi',
        0,
        'N',
        6+220,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss99_accanton_rischi' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss99_altri_accanton',
        'Missione 99 - Altri accantonamenti',
        0,
        'N',
        7+220,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss99_altri_accanton' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss99_svalutazioni',
        'Missione 99 - Svalutazioni',
        0,
        'N',
        8+220,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss99_svalutazioni' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss99_soprav_passivo_e_insussist_attivo',
        'Missione 99 - Sopravvenienze passive e insussistenze dell''attivo',
        0,
        'N',
        9+220,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss99_soprav_passivo_e_insussist_attivo' and r1.ente_proprietario_id=a.ente_proprietario_id); 


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'miss99_minusvalenze_patrimoniali',
        'Missione 99 - Minusvalenze patrimoniali',
        0,
        'N',
        10+220,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2017','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists
(select 1 from SIAC_T_REPORT_IMPORTI r1 where r1.repimp_codice='miss99_minusvalenze_patrimoniali' and r1.ente_proprietario_id=a.ente_proprietario_id); 





INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR166'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
to_date('01/01/2017','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice IN ('miss01_variaz_rimanenz_materie',
'miss01_ammort_immob_immateriali',
'miss01_ammort_immob_materiali',
'miss01_altre_svalut_immobiliz',
'miss01_svalut_crediti',
'miss01_accanton_rischi',
'miss01_altri_accanton',
'miss01_svalutazioni',
'miss01_soprav_passivo_e_insussist_attivo',
'miss01_minusvalenze_patrimoniali',

'miss02_variaz_rimanenz_materie',
'miss02_ammort_immob_immateriali',
'miss02_ammort_immob_materiali',
'miss02_altre_svalut_immobiliz',
'miss02_svalut_crediti',
'miss02_accanton_rischi',
'miss02_altri_accanton',
'miss02_svalutazioni',
'miss02_soprav_passivo_e_insussist_attivo',
'miss02_minusvalenze_patrimoniali',

'miss03_variaz_rimanenz_materie',
'miss03_ammort_immob_immateriali',
'miss03_ammort_immob_materiali',
'miss03_altre_svalut_immobiliz',
'miss03_svalut_crediti',
'miss03_accanton_rischi',
'miss03_altri_accanton',
'miss03_svalutazioni',
'miss03_soprav_passivo_e_insussist_attivo',
'miss03_minusvalenze_patrimoniali',

'miss04_variaz_rimanenz_materie',
'miss04_ammort_immob_immateriali',
'miss04_ammort_immob_materiali',
'miss04_altre_svalut_immobiliz',
'miss04_svalut_crediti',
'miss04_accanton_rischi',
'miss04_altri_accanton',
'miss04_svalutazioni',
'miss04_soprav_passivo_e_insussist_attivo',
'miss04_minusvalenze_patrimoniali',

'miss05_variaz_rimanenz_materie',
'miss05_ammort_immob_immateriali',
'miss05_ammort_immob_materiali',
'miss05_altre_svalut_immobiliz',
'miss05_svalut_crediti',
'miss05_accanton_rischi',
'miss05_altri_accanton',
'miss05_svalutazioni',
'miss05_soprav_passivo_e_insussist_attivo',
'miss05_minusvalenze_patrimoniali',

'miss06_variaz_rimanenz_materie',
'miss06_ammort_immob_immateriali',
'miss06_ammort_immob_materiali',
'miss06_altre_svalut_immobiliz',
'miss06_svalut_crediti',
'miss06_accanton_rischi',
'miss06_altri_accanton',
'miss06_svalutazioni',
'miss06_soprav_passivo_e_insussist_attivo',
'miss06_minusvalenze_patrimoniali',

'miss07_variaz_rimanenz_materie',
'miss07_ammort_immob_immateriali',
'miss07_ammort_immob_materiali',
'miss07_altre_svalut_immobiliz',
'miss07_svalut_crediti',
'miss07_accanton_rischi',
'miss07_altri_accanton',
'miss07_svalutazioni',
'miss07_soprav_passivo_e_insussist_attivo',
'miss07_minusvalenze_patrimoniali',

'miss08_variaz_rimanenz_materie',
'miss08_ammort_immob_immateriali',
'miss08_ammort_immob_materiali',
'miss08_altre_svalut_immobiliz',
'miss08_svalut_crediti',
'miss08_accanton_rischi',
'miss08_altri_accanton',
'miss08_svalutazioni',
'miss08_soprav_passivo_e_insussist_attivo',
'miss08_minusvalenze_patrimoniali',

'miss09_variaz_rimanenz_materie',
'miss09_ammort_immob_immateriali',
'miss09_ammort_immob_materiali',
'miss09_altre_svalut_immobiliz',
'miss09_svalut_crediti',
'miss09_accanton_rischi',
'miss09_altri_accanton',
'miss09_svalutazioni',
'miss09_soprav_passivo_e_insussist_attivo',
'miss09_minusvalenze_patrimoniali',

'miss10_variaz_rimanenz_materie',
'miss10_ammort_immob_immateriali',
'miss10_ammort_immob_materiali',
'miss10_altre_svalut_immobiliz',
'miss10_svalut_crediti',
'miss10_accanton_rischi',
'miss10_altri_accanton',
'miss10_svalutazioni',
'miss10_soprav_passivo_e_insussist_attivo',
'miss10_minusvalenze_patrimoniali',

'miss11_variaz_rimanenz_materie',
'miss11_ammort_immob_immateriali',
'miss11_ammort_immob_materiali',
'miss11_altre_svalut_immobiliz',
'miss11_svalut_crediti',
'miss11_accanton_rischi',
'miss11_altri_accanton',
'miss11_svalutazioni',
'miss11_soprav_passivo_e_insussist_attivo',
'miss11_minusvalenze_patrimoniali',

'miss12_variaz_rimanenz_materie',
'miss12_ammort_immob_immateriali',
'miss12_ammort_immob_materiali',
'miss12_altre_svalut_immobiliz',
'miss12_svalut_crediti',
'miss12_accanton_rischi',
'miss12_altri_accanton',
'miss12_svalutazioni',
'miss12_soprav_passivo_e_insussist_attivo',
'miss12_minusvalenze_patrimoniali',

'miss13_variaz_rimanenz_materie',
'miss13_ammort_immob_immateriali',
'miss13_ammort_immob_materiali',
'miss13_altre_svalut_immobiliz',
'miss13_svalut_crediti',
'miss13_accanton_rischi',
'miss13_altri_accanton',
'miss13_svalutazioni',
'miss13_soprav_passivo_e_insussist_attivo',
'miss13_minusvalenze_patrimoniali',

'miss14_variaz_rimanenz_materie',
'miss14_ammort_immob_immateriali',
'miss14_ammort_immob_materiali',
'miss14_altre_svalut_immobiliz',
'miss14_svalut_crediti',
'miss14_accanton_rischi',
'miss14_altri_accanton',
'miss14_svalutazioni',
'miss14_soprav_passivo_e_insussist_attivo',
'miss14_minusvalenze_patrimoniali',

'miss15_variaz_rimanenz_materie',
'miss15_ammort_immob_immateriali',
'miss15_ammort_immob_materiali',
'miss15_altre_svalut_immobiliz',
'miss15_svalut_crediti',
'miss15_accanton_rischi',
'miss15_altri_accanton',
'miss15_svalutazioni',
'miss15_soprav_passivo_e_insussist_attivo',
'miss15_minusvalenze_patrimoniali',

'miss16_variaz_rimanenz_materie',
'miss16_ammort_immob_immateriali',
'miss16_ammort_immob_materiali',
'miss16_altre_svalut_immobiliz',
'miss16_svalut_crediti',
'miss16_accanton_rischi',
'miss16_altri_accanton',
'miss16_svalutazioni',
'miss16_soprav_passivo_e_insussist_attivo',
'miss16_minusvalenze_patrimoniali',

'miss17_variaz_rimanenz_materie',
'miss17_ammort_immob_immateriali',
'miss17_ammort_immob_materiali',
'miss17_altre_svalut_immobiliz',
'miss17_svalut_crediti',
'miss17_accanton_rischi',
'miss17_altri_accanton',
'miss17_svalutazioni',
'miss17_soprav_passivo_e_insussist_attivo',
'miss17_minusvalenze_patrimoniali',

'miss18_variaz_rimanenz_materie',
'miss18_ammort_immob_immateriali',
'miss18_ammort_immob_materiali',
'miss18_altre_svalut_immobiliz',
'miss18_svalut_crediti',
'miss18_accanton_rischi',
'miss18_altri_accanton',
'miss18_svalutazioni',
'miss18_soprav_passivo_e_insussist_attivo',
'miss18_minusvalenze_patrimoniali',

'miss19_variaz_rimanenz_materie',
'miss19_ammort_immob_immateriali',
'miss19_ammort_immob_materiali',
'miss19_altre_svalut_immobiliz',
'miss19_svalut_crediti',
'miss19_accanton_rischi',
'miss19_altri_accanton',
'miss19_svalutazioni',
'miss19_soprav_passivo_e_insussist_attivo',
'miss19_minusvalenze_patrimoniali',

'miss20_variaz_rimanenz_materie',
'miss20_ammort_immob_immateriali',
'miss20_ammort_immob_materiali',
'miss20_altre_svalut_immobiliz',
'miss20_svalut_crediti',
'miss20_accanton_rischi',
'miss20_altri_accanton',
'miss20_svalutazioni',
'miss20_soprav_passivo_e_insussist_attivo',
'miss20_minusvalenze_patrimoniali',

'miss50_variaz_rimanenz_materie',
'miss50_ammort_immob_immateriali',
'miss50_ammort_immob_materiali',
'miss50_altre_svalut_immobiliz',
'miss50_svalut_crediti',
'miss50_accanton_rischi',
'miss50_altri_accanton',
'miss50_svalutazioni',
'miss50_soprav_passivo_e_insussist_attivo',
'miss50_minusvalenze_patrimoniali',

'miss60_variaz_rimanenz_materie',
'miss60_ammort_immob_immateriali',
'miss60_ammort_immob_materiali',
'miss60_altre_svalut_immobiliz',
'miss60_svalut_crediti',
'miss60_accanton_rischi',
'miss60_altri_accanton',
'miss60_svalutazioni',
'miss60_soprav_passivo_e_insussist_attivo',
'miss60_minusvalenze_patrimoniali',

'miss99_variaz_rimanenz_materie',
'miss99_ammort_immob_immateriali',
'miss99_ammort_immob_materiali',
'miss99_altre_svalut_immobiliz',
'miss99_svalut_crediti',
'miss99_accanton_rischi',
'miss99_altri_accanton',
'miss99_svalutazioni',
'miss99_soprav_passivo_e_insussist_attivo',
'miss99_minusvalenze_patrimoniali');

INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,
 rep_competenza_anni)
VALUES 
('BILR166', 1);

 INSERT INTO bko_t_report_importi
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
 select distinct a.rep_codice, 
 	a.rep_desc,
    c.repimp_codice, 
    c.repimp_desc,
    0,
 	c.repimp_modificabile,
    c.repimp_progr_riga
 from siac_t_report a,
 	siac_r_report_importi b,
    siac_t_report_importi c
 where a.rep_id=b.rep_id
 	and b.repimp_id=c.repimp_id
    and a.rep_codice='BILR166'
    order by c.repimp_progr_riga;


-- SIAC-5132 - Maurizio - FINE

-- SIAC-5056 INIZIO
-- 31.08.2017 - Sofia - in collaudo il campo esiste ma negli altri ambienti di prod no 
ALTER TABLE siac.siac_d_causale ADD COLUMN dist_id INTEGER;

ALTER TABLE siac_d_causale 	ADD CONSTRAINT siac_d_causale_siac_d_distinta FOREIGN KEY (dist_id) REFERENCES siac.siac_d_distinta (dist_id) 
	ON UPDATE NO ACTION ON DELETE NO ACTION;
-- 31.08.2017 - Sofia - in collaudo il campo esiste ma negli altri ambienti di prod no 
--SIAC-5056 FINE

-- SIAC-5150 INIZIO
CREATE OR REPLACE FUNCTION siac."BILR125_rendiconto_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  importo_codice_bilancio_prec numeric,
  rif_cc varchar,
  rif_dm varchar,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
  importo_dati_passivo numeric,
  importo_dati_passivo_prec numeric,
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer
) AS
$body$
DECLARE

classifGestione record;
pdce            record;
impprimanota    record;
dati_passivo    record;

anno_prec 			 VARCHAR;
v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_dare_prec      NUMERIC :=0;
v_imp_avere_prec     NUMERIC :=0;
v_importo 			 NUMERIC :=0;
v_importo_prec 		 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_pdce_fam_code_prec VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_prec VARCHAR;

DEF_NULL	constant VARCHAR:=''; 
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;

BEGIN

anno_prec := (p_anno::INTEGER-1)::VARCHAR;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
importo_codice_bilancio_prec := 0;
rif_CC := '';
rif_DM := '';
codice_raggruppamento := '';
descr_raggruppamento := '';
codice_codifica_albero := '';
valore_importo := 0;
codice_subraggruppamento := '';
classif_id_liv1 := 0;
classif_id_liv2 := 0;
classif_id_liv3 := 0;
classif_id_liv4 := 0;
classif_id_liv5 := 0;
classif_id_liv6 := 0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL';   
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00022'; -- 'SPP_CODBIL';
   v_classificatori1 := '00023'; -- 'CO_CODBIL';
END IF;  

raise notice '1 - %' , v_classificatori;  

v_anno_prec := p_anno::INTEGER-1;

IF p_classificatori = '2' THEN

WITH Importipn AS (
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    AND anno_eserc.anno IN (p_anno,v_anno_prec)
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    AND   a.data_cancellazione is null)
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine;

END IF;


FOR classifGestione IN
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id 
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, zz.ordine asc

LOOP
    
    valore_importo := 0;

    SELECT COUNT(*)
    INTO   valore_importo
    FROM   siac_r_class_fam_tree a
    WHERE  a.classif_id_padre = classifGestione.classif_id
    AND    a.data_cancellazione IS NULL;

    IF classifGestione.livello_codifica = 3 THEN    
       v_codice_subraggruppamento := classifGestione.codice_codifica;  
       codice_subraggruppamento := v_codice_subraggruppamento;       
    ELSIF classifGestione.livello_codifica < 3 THEN
       codice_subraggruppamento := '';        
    ELSIF classifGestione.livello_codifica > 3 THEN
       codice_subraggruppamento := v_codice_subraggruppamento;          
    END IF;
       
    IF classifGestione.livello_codifica = 2 THEN
       codice_raggruppamento := SUBSTRING(classifGestione.descrizione_codifica FROM 1 FOR 1);
       descr_raggruppamento := classifGestione.descrizione_codifica;
    ELSIF classifGestione.livello_codifica = 1 THEN  
       codice_raggruppamento := '';
       descr_raggruppamento := '';  
    END IF;   
    
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF;
    
    rif_CC := ''; 
    rif_DM := '';

    SELECT a.rif_art_2424_cc, a.rif_dm_26_4_95
    INTO rif_CC, rif_DM
    FROM siac_rep_rendiconto_gestione_rif a
    WHERE a.codice_bilancio = classifGestione.codice_codifica_albero
    AND   (a.codice_report = v_classificatori OR a.codice_report = v_classificatori1);    

    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0; 
    
    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

      SELECT importo_passivo
      INTO   importo_dati_passivo_prec
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = v_anno_prec
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;
          
    END IF;
    
    v_imp_dare := 0;
    v_imp_avere := 0;
    v_imp_dare_prec := 0;
    v_imp_avere_prec := 0;
    v_importo := 0;
    v_importo_prec := 0;
    v_pdce_fam_code := '';
    v_pdce_fam_code_prec := '';

    FOR pdce IN
	SELECT d.pdce_fam_code, e.movep_det_segno, i.anno, SUM(COALESCE(e.movep_det_importo,0)) AS importo
    FROM  siac_r_pdce_conto_class a
    INNER JOIN siac_t_pdce_conto b ON a.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
    INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
    INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
    INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
    INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
    INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id
    WHERE a.classif_id = classifGestione.classif_id
    AND   m.pnota_stato_code = 'D'
    AND   (i.anno = p_anno OR i.anno = anno_prec)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL    
    GROUP BY d.pdce_fam_code, e.movep_det_segno, i.anno
        
    LOOP
    
    IF pdce.movep_det_segno = 'Dare' THEN
       IF pdce.anno = p_anno THEN
          v_imp_dare := pdce.importo;
       ELSE
          v_imp_dare_prec := pdce.importo;
       END IF;   
    ELSIF pdce.movep_det_segno = 'Avere' THEN
       IF pdce.anno = p_anno THEN
          v_imp_avere := pdce.importo;
       ELSE
          v_imp_avere_prec := pdce.importo;
       END IF;                   
    END IF;               
    
    IF pdce.anno = p_anno THEN
       v_pdce_fam_code := pdce.pdce_fam_code;
    ELSE
       v_pdce_fam_code_prec := pdce.pdce_fam_code;
    END IF;
                                                                    
    END LOOP;

    IF p_classificatori IN ('1','3') THEN

      IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
         v_importo := v_imp_avere - v_imp_dare;
      ELSIF v_pdce_fam_code IN ('AP','CE') THEN   
         v_importo := v_imp_dare - v_imp_avere;   
      END IF; 
    
      IF v_pdce_fam_code_prec IN ('PP','OP','OA','RE') THEN
         v_importo_prec := v_imp_avere_prec - v_imp_dare_prec;
      ELSIF v_pdce_fam_code_prec IN ('AP','CE') THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;     
    
    ELSIF p_classificatori = '2' THEN
      
      IF v_pdce_fam_code = 'AP' THEN   
         v_importo := v_imp_dare - v_imp_avere;
      END IF; 
      
      IF v_pdce_fam_code_prec = 'AP' THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;       
            
    --raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code,classifGestione.classif_id,COALESCE(v_importo,0),COALESCE(v_imp_dare,0),COALESCE(v_imp_avere,0);
    --raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code_prec,classifGestione.classif_id,COALESCE(v_importo_prec,0),COALESCE(v_imp_dare_prec,0),COALESCE(v_imp_avere_prec,0);
    
    END IF;
    
    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;
  
    IF p_classificatori != '1' THEN
    
      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;         
         importo_codice_bilancio_prec := v_importo_prec;
      ELSE
         importo_codice_bilancio := 0;       
         importo_codice_bilancio_prec := 0;
      END IF;          
  
    ELSE
      importo_codice_bilancio := v_importo;
      importo_codice_bilancio_prec := v_importo_prec;     
    END IF;

    codice_codifica_albero := classifGestione.codice_codifica_albero;
    
    classif_id_liv1 := classifGestione.classif_id_liv1;
    classif_id_liv2 := classifGestione.classif_id_liv2;
    classif_id_liv3 := classifGestione.classif_id_liv3;
    classif_id_liv4 := classifGestione.classif_id_liv4;
    classif_id_liv5 := classifGestione.classif_id_liv5;
    classif_id_liv6 := classifGestione.classif_id_liv6;
      
    return next;

    tipo_codifica := '';
    codice_codifica := '';
    descrizione_codifica := '';
    livello_codifica := 0;
    importo_codice_bilancio := 0;
    importo_codice_bilancio_prec := 0;
    rif_CC := '';
    rif_DM := '';
    codice_codifica_albero := '';
    valore_importo := 0;
    codice_subraggruppamento := '';
    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0;
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;

END LOOP;

delete from rep_bilr125_dati_stato_passivo where utente=user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5150 FINE