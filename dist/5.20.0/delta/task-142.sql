/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--siac-tasks-Issues #142 - MAURIZIO - INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil (
  p_afde_bil_id integer
)
RETURNS TABLE (
  versione integer,
  fase_attributi_bilancio varchar,
  stato_attributi_bilancio varchar,
  data_ora_elaborazione timestamp,
  anni_esercizio varchar,
  riscossione_virtuosa boolean,
  quinquennio_riferimento varchar,
  capitolo varchar,
  articolo varchar,
  ueb varchar,
  titolo_entrata varchar,
  tipologia varchar,
  categoria varchar,
  sac varchar,
  incasso_conto_competenza numeric,
  accertato_conto_competenza numeric,
  percentuale_incasso_gestione numeric,
  percentuale_accantonamento numeric,
  tipo_precedente varchar,
  percentuale_precedente numeric,
  percentuale_minima numeric,
  percentuale_effettiva numeric,
  stanziamento_0 numeric,
  stanziamento_1 numeric,
  stanziamento_2 numeric,
  accantonamento_fcde_0 numeric,
  accantonamento_fcde_1 numeric,
  accantonamento_fcde_2 numeric,
  accantonamento_graduale numeric,
  stanz_senza_var_0 numeric,
  stanz_senza_var_1 numeric,
  stanz_senza_var_2 numeric,
  delta_var_0 numeric,
  delta_var_1 numeric,
  delta_var_2 numeric
) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
    v_media_utilizzo 		   NUMERIC;
    v_perc_accantonamento	   NUMERIC;
    v_accertamenti_0		   NUMERIC;
    v_accertamenti_1		   NUMERIC;
    v_accertamenti_2		   NUMERIC;
    
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
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
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
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
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
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
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		)
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				--SIAC-8513 la gestione ha subito delle modifiche, attualmente se non e' presente la media utente
				WHEN 'UTENTE'   THEN 
					v_componente_cento - COALESCE(
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente,
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali,
						--TODO ci sarebbe da mettere la percentuale sullo stanziamento
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto,
						0
					)
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			--SIAC-8768
			, COALESCE(comp_capitolo0.impSta, 0) AS stanz_senza_var_0
			, COALESCE(var_capitolo0.impSta, 0) AS delta_var_0
			, COALESCE(comp_capitolo1.impSta, 0) AS stanz_senza_var_1
			, COALESCE(var_capitolo1.impSta, 0) AS delta_var_1
			, COALESCE(comp_capitolo2.impSta, 0) AS stanz_senza_var_2
			, COALESCE(var_capitolo2.impSta, 0) AS delta_var_2
            --SIAC-8792 26/08/2022
            --Estraggo altri campi che servono per i calcoli successivi.
            , COALESCE(siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code, '') afde_tipo_media_code
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente, 0) acc_fde_media_utente
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto, 0) acc_fde_media_confronto
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali, 0) acc_fde_media_semplice_totali
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore, 0) acc_fde_numeratore
            --21/07/2023 siac-tasks-Issues #142 
            --Leggo anche i campi denominatore dove sono contenuti i valori degli accertamenti per anno che
            --servono per il calcolo dell'accantonamento FCDE.
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore, 0) acc_fde_denominatore
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_1, 0) acc_fde_denominatore_1
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_2, 0) acc_fde_denominatore_2
			--, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS stanziamento_0
			--, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS stanziamento_1
			--, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS stanziamento_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
        --SIAC-8792 26/08/2022 la percentuale effettiva e' calcolata successivamente
		--percentuale_effettiva := v_loop_var.acc_fde_media;
		--stanziamento_0        := v_loop_var.stanziamento_0;
		--stanziamento_1        := v_loop_var.stanziamento_1;
		--stanziamento_2        := v_loop_var.stanziamento_2;
		stanz_senza_var_0     := v_loop_var.stanz_senza_var_0;
		stanz_senza_var_1     := v_loop_var.stanz_senza_var_1;
		stanz_senza_var_2     := v_loop_var.stanz_senza_var_2;
		delta_var_0           := v_loop_var.delta_var_0;
		delta_var_1           := v_loop_var.delta_var_1;
		delta_var_2           := v_loop_var.delta_var_2;
 
		--SIAC-8768
		
		stanziamento_0 := v_loop_var.stanz_senza_var_0 + v_loop_var.delta_var_0;
		stanziamento_1 := v_loop_var.stanz_senza_var_1 + v_loop_var.delta_var_1;
		stanziamento_2 := v_loop_var.stanz_senza_var_2 + v_loop_var.delta_var_2;
        
         --21/07/2023 siac-tasks-Issues #142 
         --Valori degli accertamenti per anno.
        v_accertamenti_0 := COALESCE(v_loop_var.acc_fde_denominatore, 0);
        v_accertamenti_1 := COALESCE(v_loop_var.acc_fde_denominatore_1, 0);
        v_accertamenti_2 := COALESCE(v_loop_var.acc_fde_denominatore_2, 0);
/*
se media utente != null -> 100 - media utente
altrimenti
100 - [max(media_confronto, min(%acc, %stanziamento))]
*/       		
		-- /10000 perche' ho due percentuali per cui moltiplico (v_loop_var.acc_fde_media e accantonamento_graduale)
		-- SIAC-8446: arrotondo gli importi a due cifre decimali
/*		SIAC-8792 26/08/2022
        --Il calcolo dell'accantonamento FCDE prvede il seguente algoritmo:
        
        se media utente != null -> 100 - media utente
		altrimenti
		100 - [max(media_confronto, min(%acc, %stanziamento))]
*/        
        --accantonamento_fcde_0 := ROUND(stanziamento_0 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		--accantonamento_fcde_1 := ROUND(stanziamento_1 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		--accantonamento_fcde_2 := ROUND(stanziamento_2 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		
        if v_loop_var.afde_tipo_media_code = 'UTENTE' THEN
        	v_media_utilizzo:= v_loop_var.acc_fde_media_utente;
        else
              --12/10/2023 siac-tasks-issue #142.
              --Se lo stanziamento e' 0 occorre impostare la percentuale di accantonamento per non far fallire il rapporto
              --(v_loop_var.acc_fde_numeratore * 100 / stanziamento_0. Prima era:     
              --v_perc_accantonamento:=COALESCE((v_loop_var.acc_fde_numeratore * 100 / stanziamento_0), 0);   
        	if stanziamento_0 = 0 then
            	v_perc_accantonamento:= 0;
            else
        		v_perc_accantonamento:=COALESCE((v_loop_var.acc_fde_numeratore * 100 / stanziamento_0), 0);
            end if;
            
            v_media_utilizzo:= GREATEST (v_loop_var.acc_fde_media_confronto,
            	LEAST(v_perc_accantonamento, v_loop_var.acc_fde_media_semplice_totali));
        end if;
        
        raise notice 'capitolo = % - numeratore = % - stanziamento = %', 
        	capitolo, v_loop_var.acc_fde_numeratore, stanziamento_0;
		raise notice 'capitolo % - tipo media = % - media_confronto = % - perc_accantonamento = % - acc_fde_media_semplice_totali = % v_media_utilizzo = %', 
        	capitolo, v_loop_var.afde_tipo_media_code, v_loop_var.acc_fde_media_confronto,
            v_perc_accantonamento, v_loop_var.acc_fde_media_semplice_totali, v_media_utilizzo;
        raise notice 'capitolo % - v_accertamenti_0 = % - v_accertamenti_1 = % - v_accertamenti_2 = %',
        	capitolo, v_accertamenti_0, v_accertamenti_1, v_accertamenti_2;
            
             --21/07/2023 siac-tasks-Issues #142 
             --Per calcolare l'accantonamento FCDE devo usare il valore maggiore tra stanziamento e accertamento.
        --accantonamento_fcde_0 := ROUND(stanziamento_0 * (100 - v_media_utilizzo) / 100, 2);
		--accantonamento_fcde_1 := ROUND(stanziamento_1 * (100 - v_media_utilizzo) / 100, 2);
		--accantonamento_fcde_2 := ROUND(stanziamento_2 * (100 - v_media_utilizzo) / 100, 2);
		accantonamento_fcde_0 := ROUND(GREATEST(stanziamento_0, v_accertamenti_0)  * (100 - v_media_utilizzo) / 100, 2);
		accantonamento_fcde_1 := ROUND(GREATEST(stanziamento_1, v_accertamenti_1) * (100 - v_media_utilizzo) / 100, 2);
		accantonamento_fcde_2 := ROUND(GREATEST(stanziamento_2, v_accertamenti_2) * (100 - v_media_utilizzo) / 100, 2);
        
        raise notice 'accantonamento_fcde_0 = % - accantonamento_fcde_1 = % - accantonamento_fcde_2 = %',
        	accantonamento_fcde_0, accantonamento_fcde_1, accantonamento_fcde_2;
            
		--SIAC-8792 26/08/2022
        --La percentuale effettiva e' il complemento a 100 della media utilizzata.
        percentuale_effettiva := ROUND(100 - v_media_utilizzo, 2); 
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
            --SIAC-8792 26/08/2022
            --Il campo percentuale_accantonamento e' calcolato e non e' la
            --media utente.
			--, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
            , --17/11/2023 siac-tasks-Issues #290
              --se lo stanziamento e' 0, come percentuale_accantonamento si restituisce 0.
              --aggiunto anche COALESCE se manca la media di confronto
            case when stanziamento_0 = 0 then 0
            else round(COALESCE((siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore * 100 / stanziamento_0), 0), 2) end
			, COALESCE(siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_desc, '')			
            , siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
--				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
--				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
		INTO
			  incasso_conto_competenza
			, accertato_conto_competenza
			, percentuale_incasso_gestione
			, percentuale_accantonamento
			, tipo_precedente
			, percentuale_precedente
			, percentuale_minima
		FROM siac_t_acc_fondi_dubbia_esig
         --17/11/2023 siac-tasks-Issues #290
         --per alcuni capitoli non c'e' la percentuale di confronto e quindi manca il join con la tabella siac_d_acc_fondi_dubbia_esig_tipo_media_confronto
         --Si deve accedere con LEFT JOIN
		LEFT JOIN siac_d_acc_fondi_dubbia_esig_tipo_media_confronto ON (siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_conf_id AND siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.data_cancellazione IS NULL)
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil (p_afde_bil_id integer)
  OWNER TO siac;
  
  
CREATE OR REPLACE FUNCTION siac."BILR262_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_assest" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar,
  p_afde_bil_id integer
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  importo_collb numeric,
  importo_collc numeric,
  flag_acc_cassa boolean
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImpVar varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
flagAccantGrad varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strpercAccantonamento varchar;
percAccantonamento numeric;
tipomedia varchar;
perc1 numeric;
perc2 numeric;
perc3 numeric;
perc4 numeric;
perc5 numeric;
fde_media_utente  numeric;
fde_media_semplice_totali numeric;
fde_media_semplice_rapporti  numeric;
fde_media_ponderata_totali  numeric;
fde_media_ponderata_rapporti  numeric;

perc_delta numeric;
perc_media numeric;
afde_bilancioId integer;
perc_massima numeric;

h_count integer :=0;

accertamento_cap numeric;
incassi_conto_competenza numeric;
accertamento_cap1 numeric;
incassi_conto_competenza1 numeric;
accertamento_cap2 numeric;
incassi_conto_competenza2 numeric;
accertamento_cap_utilizzato numeric;

perc_accantonamento numeric;
media_confronto numeric;

BEGIN

annoCapImp:= p_anno; 
annoCapImpVar:= p_anno_competenza;

flag_acc_cassa:= true;

/*
Funzione creata per la SIAC-8664 - 06/10/2022.
Parte come copia della "BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita"
ma e' modificata per gestire i dati dell'assestamento invece che della 
previsione.


*/

percAccantonamento:=0;
select COALESCE(fondi_bil.afde_bil_accantonamento_graduale,0),
	fondi_bil.afde_bil_id
	into percAccantonamento, afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
    and fondi_bil.ente_proprietario_id = p_ente_prop_id
    and fondi_bil.afde_bil_id = p_afde_bil_id
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione.

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
codice_pdc='';
accertamento_cap_utilizzato:=0;

select fnc_siac_random_user()
into	user_table;


insert into siac_rep_tit_tip_cat_riga_anni
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, user_table);
 

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.elem_id						=	rc.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and ct.classif_tipo_code			=	'CATEGORIA' 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and pdc_tipo.classif_tipo_code like 'PDC_%'
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null;

insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
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
            siac_r_bil_elem_categoria r_cat_capitolo--,
         --22/12/2021 SIAC-8254
         --I capitoli devono essere presi tutti e non solo quelli
         --coinvolti in FCDE per avere l'importo effettivo dello stanziato
         --nella colonna (a).
            --siac_t_acc_fondi_dubbia_esig fcde
    where 	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and   fcde.elem_id						= capitolo.elem_id
        and capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	and	anno_eserc.anno							= 	p_anno				
        --and   fcde.afde_bil_id				=  afde_bilancioId
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        --leggo solo gli importi dell'anno di competenza.
        and	capitolo_imp_periodo.anno 				in (p_anno_competenza)
        and	stato_capitolo.elem_stato_code		=	'VA'
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
       -- and fcde.data_cancellazione IS NULL     
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;
               
--21/07/2023 siac-tasks-issu #142.
--Nel calcolo dello stanziamento occorre considerare le eventuali variazioni in BOZZA sul capitolo.     
 insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),        
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            testata_variazione.ente_proprietario_id	      	
    from 	siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_r_variazione_stato		r_variazione_stato,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_bil					t_bil,
            siac_t_periodo 				anno_importi
    where 	testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
    and 	t_bil.bil_id 										= 	testata_variazione.bil_id
    and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
    and 	testata_variazione.variazione_id					=  	r_variazione_stato.variazione_id
    and 	testata_variazione.ente_proprietario_id 			= 	p_ente_prop_id 
    and		anno_eserc.anno										= 	p_anno	   
    and		anno_importi.anno									= 	annoCapImpVar    									 	
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
    and		tipo_elemento.elem_det_tipo_code					= 'STA'
    and		tipologia_stato_var.variazione_stato_tipo_code		NOT IN ('A', 'D')
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    and		t_bil.data_cancellazione					is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
               utente,
                testata_variazione.ente_proprietario_id;
                    
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
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
        COALESCE (var_ent.importo,0)		imp_var
from  	siac_rep_tit_tip_cat_riga_anni v1
		FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
         left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
        left join siac_rep_var_entrate var_ent
                  on (var_ent.elem_id	=	tb.elem_id
                          and	tb.utente=user_table
                          and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop


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
--21/07/2023 siac-tasks-issu #142.
--Nel calcolo dello stanziamento occorre considerare le eventuali variazioni in BOZZA sul capitolo.  
--Poiche' il report viene eseguito su uno specifico anno di competenza, il campo valorizzato su stanziamento_prev_anno
--e' gia' quello dell'anno di competenza.
--stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno + classifBilRec.imp_var;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
codice_pdc:=classifBilRec.codice_pdc;


-- SIAC-5854 INIZIO
SELECT true
INTO   flag_acc_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
  AND    ta.ente_proprietario_id = p_ente_prop_id
  AND    rbea.elem_id = classifBilRec.bil_ele_id
  AND    ta.attr_code = 'FlagAccertatoPerCassa'

  AND    rbea."boolean" = 'S'
  AND    rbea.data_cancellazione IS NULL
  AND    ta.data_cancellazione IS NULL;

IF flag_acc_cassa IS NULL THEN
   flag_acc_cassa := false;
END IF;
-- SIAC-5854 FINE


raise notice 'bil_ele_id = %', classifBilRec.bil_ele_id;

fde_media_utente:=0;
fde_media_semplice_totali:=0; 
fde_media_semplice_rapporti:=0;
fde_media_ponderata_totali:=0; 
fde_media_ponderata_rapporti:=0;
perc_delta:=0;
perc_media:=0;
tipomedia:='';
accertamento_cap:=0;

if classifBilRec.bil_ele_id IS NOT NULL then
  select  datifcd.perc_delta, 1, tipo_media.afde_tipo_media_code,
    COALESCE(datifcd.acc_fde_media_utente,0), 
    COALESCE(datifcd.acc_fde_media_semplice_totali,0),
    COALESCE(datifcd.acc_fde_media_semplice_rapporti,0), 
    COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
    COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0),
    greatest (COALESCE(datifcd.acc_fde_media_semplice_totali,0),
       		  COALESCE(datifcd.acc_fde_media_semplice_rapporti,0),
    COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
    COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0)),
    COALESCE(datifcd.acc_fde_denominatore, 0) accert,
    COALESCE(datifcd.acc_fde_numeratore, 0) incassi_conto_comp,
    COALESCE(datifcd.acc_fde_denominatore_1, 0) accert1,
    COALESCE(datifcd.acc_fde_numeratore_1, 0) incassi_conto_comp1,
    COALESCE(datifcd.acc_fde_denominatore_2, 0) accert2,
    COALESCE(datifcd.acc_fde_numeratore_2, 0) incassi_conto_comp2,
    COALESCE(datifcd.acc_fde_media_confronto, 0) media_confr
  into perc_delta, h_count, tipomedia,
      fde_media_utente, fde_media_semplice_totali, fde_media_semplice_rapporti,
      fde_media_ponderata_totali, fde_media_ponderata_rapporti, perc_massima, accertamento_cap, incassi_conto_competenza,
      accertamento_cap1, incassi_conto_competenza1, accertamento_cap2, incassi_conto_competenza2, media_confronto
   FROM siac_t_acc_fondi_dubbia_esig datifcd, 
      siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
  where tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
    and datifcd.elem_id=classifBilRec.bil_ele_id 
    and datifcd.afde_bil_id  = afde_bilancioId
    and datifcd.data_cancellazione is null
    and tipo_media.data_cancellazione is null;

--28/07/2023: il valore dell'accertamento usato per i calcoli dipende dall'anno di competenza.
if p_anno_competenza =  p_anno then
	accertamento_cap_utilizzato:= accertamento_cap;
elsif p_anno_competenza::integer = p_anno::integer +1 then
	accertamento_cap_utilizzato:= accertamento_cap1;
elsif p_anno_competenza::integer = p_anno::integer +2 then
	accertamento_cap_utilizzato:= accertamento_cap2;
else 
	accertamento_cap_utilizzato:=0;
end if;
    
/*
if tipomedia = 'SEMP_RAP' then
    perc_media = fde_media_semplice_rapporti;         
elsif tipomedia = 'SEMP_TOT' then
    perc_media = fde_media_semplice_totali;        
elsif tipomedia = 'POND_RAP' then
      perc_media = fde_media_ponderata_rapporti;  
elsif tipomedia = 'POND_TOT' then
      perc_media = fde_media_ponderata_totali;    
elsif tipomedia = 'UTENTE' then  --Media utente
      perc_media = fde_media_utente;   
end if;
*/


if tipomedia = 'UTENTE' THEN
    perc_media:= fde_media_utente;
else
		--12/10/2023 siac-tasks-issue #142.
        --Se lo stanziamento e' 0 occorre impostare la percentuale di accantonamento per non far fallire il rapporto
        --(incassi_conto_competenza * 100 / stanziamento_prev_anno). Prima era:
        --perc_accantonamento:=COALESCE((incassi_conto_competenza * 100 / stanziamento_prev_anno), 0);
	if stanziamento_prev_anno = 0 then
    	raise notice 'formula per perc_accantonamento:perc_accantonamento:= 0';
    	perc_accantonamento:= 0;
    else 
    	raise notice 'formula per perc_accantonamento:
        	COALESCE((% * 100 / %), 0)', incassi_conto_competenza, stanziamento_prev_anno;
    	perc_accantonamento:=COALESCE((incassi_conto_competenza * 100 / stanziamento_prev_anno), 0);
    end if;
    
    raise notice 'formula per perc_media: 
    	GREATEST (%, LEAST(%, %))', media_confronto, perc_accantonamento, fde_media_semplice_totali;
        
        --10/11/2023: nell'ambito dei test della siac-tasks-issue #142 ci si e' accorti che non e' corretto usare la
        --media fde_media_ponderata_totali ma occorre usare la fde_media_semplice_totali come nell'export Excel ed a video.
    perc_media:= GREATEST (media_confronto, LEAST(perc_accantonamento, fde_media_semplice_totali));--fde_media_ponderata_totali));
end if;
               
raise notice 'Capitolo = % - tipomedia % - perc_accantonamento= % - perc_media: % - delta: % - massima %', 
	bil_ele_code, tipomedia , perc_accantonamento, perc_media, perc_delta, perc_massima ;
raise notice '      stanziamento = % - accertamento = %', classifBilRec.stanziamento_prev_anno, accertamento_cap;

--- colonna b del report = stanziamento capitolo * percentualeAccantonamentoAnno(1,2) * perc_media
--- colonna c del report = stanziamento capitolo * perc_delta della tabella 

--SIAC-8154 14/10/2021
--la colonna C diventa quello che prima era la colonna B
--la colonna B invece della percentuale media deve usa la percentuale 
--che ha il valore massimo (esclusa quella utente).
--importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
--importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_delta/100) * percAccantonamento/100,2);   

--SIAC-8579 17/01/2022 l'accantonamento obbligatorio (Colonna B) diventa uguale
--all'accantonamento effettivo (Colonna C).
--importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_massima/100) * percAccantonamento/100,2);
--importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);

raise notice 'Applicata formula: ROUND(GREATEST(%, %)  * (100 - %) / 100, 2)',
	stanziamento_prev_anno, accertamento_cap_utilizzato, perc_media;
    
--21/07/2023 siac-tasks-issu #142.
--La formaula usata per il calcoo dell'accantonamento FCDE viene adeguata a quella usata dalla procedura
--fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil per l'export in Excel.    
importo_collc := ROUND(GREATEST(stanziamento_prev_anno, accertamento_cap_utilizzato)  * (100 - perc_media) / 100, 2);
importo_collb:=importo_collc;
else
	importo_collc:=0;
    importo_collb:=0;
end if;

raise notice '      importo_collb %',  importo_collb;

if h_count is null or flag_acc_cassa = true then
  importo_collb:=0;
  importo_collc:=0;
  -- flag_acc_cassa:=true; -- SIAC-5854
END if;

-- importi capitolo

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
codice_pdc:=0;
importo_collb:=0;
importo_collc:=0;
flag_acc_cassa:=true;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR262_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_assest" (p_ente_prop_id integer, p_anno varchar, p_anno_competenza varchar, p_afde_bil_id integer)
  OWNER TO siac;
  
--siac-tasks-Issues #142 - MAURIZIO - FINE

  