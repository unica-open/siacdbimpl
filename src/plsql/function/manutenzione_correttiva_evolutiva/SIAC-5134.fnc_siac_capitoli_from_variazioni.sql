/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
