/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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