/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- siac_t_acc_fondi_dubbia_esig_bil
INSERT INTO siac.siac_t_acc_fondi_dubbia_esig_bil(bil_id, afde_tipo_id, afde_stato_id, afde_bil_versione, afde_bil_accantonamento_graduale, afde_bil_quinquennio_riferimento, afde_bil_riscossione_virtuosa, validita_inizio, ente_proprietario_id, login_operazione)
WITH accantonamento_graduale AS (
	SELECT tb.bil_id,
		CASE rba."boolean"
			WHEN 'S' THEN 100
			ELSE 0
		END AS valore
	FROM siac_r_bil_attr rba
	JOIN siac_t_bil tb ON tb.bil_id = rba.bil_id
	JOIN siac_t_attr ta ON ta.attr_id = rba.attr_id
	WHERE rba.data_cancellazione IS NULL
	AND ta.attr_code = 'accantonamentoGraduale'
), quinquennio_riferimento AS (
	SELECT tb.bil_id, rba.numerico AS valore
	FROM siac_r_bil_attr rba
	JOIN siac_t_bil tb ON tb.bil_id = rba.bil_id
	JOIN siac_t_attr ta ON ta.attr_id = rba.attr_id
	WHERE rba.data_cancellazione IS NULL
	AND ta.attr_code = 'ultimoAnnoApprovato'
), riscossione_virtuosa AS (
	SELECT tb.bil_id,
		CASE rba."boolean"
			WHEN 'S' THEN true
			ELSE false
		END AS valore
	FROM siac_r_bil_attr rba
	JOIN siac_t_bil tb ON tb.bil_id = rba.bil_id
	JOIN siac_t_attr ta ON ta.attr_id = rba.attr_id
	WHERE rba.data_cancellazione IS NULL
	AND ta.attr_code = 'riscossioneVirtuosa'
)
SELECT tb.bil_id, dafdet.afde_tipo_id, dafdes.afde_stato_id, 1, ag.valore, qr.valore, rv.valore, now(), tb.ente_proprietario_id, 'SIAC-7858'
FROM siac_t_bil tb
JOIN siac_d_acc_fondi_dubbia_esig_tipo dafdet ON dafdet.ente_proprietario_id = tb.ente_proprietario_id
JOIN siac_d_acc_fondi_dubbia_esig_stato dafdes ON dafdes.ente_proprietario_id = tb.ente_proprietario_id
FULL OUTER JOIN accantonamento_graduale ag ON ag.bil_id = tb.bil_id
FULL OUTER JOIN quinquennio_riferimento qr ON qr.bil_id = tb.bil_id
FULL OUTER JOIN riscossione_virtuosa rv ON rv.bil_id = tb.bil_id
WHERE (ag.valore IS NOT NULL OR qr.valore IS NOT NULL OR rv.valore IS NOT NULL)
AND dafdet.afde_tipo_code IN ('PREVISIONE', 'RENDICONTO')
AND dafdes.afde_stato_code = 'DEFINITIVA';

-- siac_t_acc_fondi_dubbia_esig
DO $$
DECLARE
	fcde RECORD;
	v_acc_fde_id INTEGER;
	v_elem_id INTEGER;
	v_afde_tipo_media_id INTEGER;
	v_afde_tipo_id INTEGER;
	v_afde_tipo_code VARCHAR;

	v_perc_acc_fondi NUMERIC;
	v_perc_acc_fondi_1 NUMERIC;
	v_perc_acc_fondi_2 NUMERIC;
	v_perc_acc_fondi_3 NUMERIC;
	v_perc_acc_fondi_4 NUMERIC;

	v_acc_fde_numeratore NUMERIC;
	v_acc_fde_numeratore_1 NUMERIC;
	v_acc_fde_numeratore_2 NUMERIC;
	v_acc_fde_numeratore_3 NUMERIC;
	v_acc_fde_numeratore_4 NUMERIC;

	v_acc_fde_denominatore NUMERIC;
	v_acc_fde_denominatore_1 NUMERIC;
	v_acc_fde_denominatore_2 NUMERIC;
	v_acc_fde_denominatore_3 NUMERIC;
	v_acc_fde_denominatore_4 NUMERIC;

	v_acc_fde_media_utente NUMERIC;
	v_acc_fde_media_semplice_totali NUMERIC;
	v_acc_fde_media_semplice_rapporti NUMERIC;
	v_acc_fde_media_ponderata_totali NUMERIC;
	v_acc_fde_media_ponderata_rapporti NUMERIC;

	v_acc_fde_note TEXT;

	v_afde_bil_id INTEGER;
	v_anno INTEGER;
	v_riscossione_virtuosa BOOLEAN;
	v_idx INTEGER;
	v_importo NUMERIC;
	v_num NUMERIC;
	v_den NUMERIC;
	v_tmp NUMERIC;
	v_counter INTEGER;

BEGIN
	FOR fcde IN
	SELECT tafde.*
	FROM siac_t_acc_fondi_dubbia_esig tafde
	WHERE tafde.data_cancellazione IS NULL
	ORDER BY tafde.acc_fde_id
	LOOP
		-- Clean data
		v_afde_bil_id := NULL;
		v_anno := NULL;
		v_riscossione_virtuosa := NULL;
		v_elem_id := NULL;
		v_afde_tipo_media_id := NULL;
		v_afde_tipo_id := NULL;
		v_afde_tipo_code := NULL;
		v_perc_acc_fondi := NULL;
		v_perc_acc_fondi_1 := NULL;
		v_perc_acc_fondi_2 := NULL;
		v_perc_acc_fondi_3 := NULL;
		v_perc_acc_fondi_4 := NULL;
		v_acc_fde_numeratore := NULL;
		v_acc_fde_numeratore_1 := NULL;
		v_acc_fde_numeratore_2 := NULL;
		v_acc_fde_numeratore_3 := NULL;
		v_acc_fde_numeratore_4 := NULL;
		v_acc_fde_denominatore := NULL;
		v_acc_fde_denominatore_1 := NULL;
		v_acc_fde_denominatore_2 := NULL;
		v_acc_fde_denominatore_3 := NULL;
		v_acc_fde_denominatore_4 := NULL;

		v_acc_fde_media_utente := NULL;
		v_acc_fde_media_semplice_totali := NULL;
		v_acc_fde_media_semplice_rapporti := NULL;
		v_acc_fde_media_ponderata_totali := NULL;
		v_acc_fde_media_ponderata_rapporti := NULL;

		v_acc_fde_note := NULL;

		RAISE NOTICE 'Elaborazione per FCDE con id %', fcde.acc_fde_id;

		-- elem_id
		SELECT rbeafde.elem_id
		INTO v_elem_id
		FROM siac_r_bil_elem_acc_fondi_dubbia_esig rbeafde
		WHERE rbeafde.acc_fde_id = fcde.acc_fde_id
		AND rbeafde.data_cancellazione IS NULL;

		IF v_elem_id IS NULL THEN
			CONTINUE;
		END IF;
		RAISE NOTICE 'Elaborazione per FCDE con id %. Elem id: %', fcde.acc_fde_id, v_elem_id;

		-- afde_tipo_media_id
		-- DEFAULT: media utente
		SELECT dafdetm.afde_tipo_media_id
		INTO v_afde_tipo_media_id
		FROM siac_d_acc_fondi_dubbia_esig_tipo_media dafdetm
		WHERE dafdetm.ente_proprietario_id = fcde.ente_proprietario_id
		AND dafdetm.afde_tipo_media_code = 'UTENTE';
		RAISE NOTICE 'Elaborazione per FCDE con id %. Tipo media id: %', fcde.acc_fde_id, v_afde_tipo_media_id;

		-- afde_tipo_id
		-- Dati pregressi: solo previsione e rendiconto
		SELECT dafdet.afde_tipo_id, dafdet.afde_tipo_code
		INTO v_afde_tipo_id, v_afde_tipo_code
		FROM siac_r_bil_elem_acc_fondi_dubbia_esig rbeafde
		JOIN siac_t_bil_elem tbe ON tbe.elem_id = rbeafde.elem_id
		JOIN siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
		JOIN siac_d_acc_fondi_dubbia_esig_tipo dafdet ON dafdet.ente_proprietario_id = fcde.ente_proprietario_id
		WHERE rbeafde.acc_fde_id = fcde.acc_fde_id
		AND rbeafde.data_cancellazione IS NULL
		AND (
			(dbet.elem_tipo_code = 'CAP-EG' AND dafdet.afde_tipo_code = 'RENDICONTO')
			OR ((dbet.elem_tipo_code = 'CAP-EP' AND dafdet.afde_tipo_code = 'PREVISIONE'))
		);
		RAISE NOTICE 'Elaborazione per FCDE con id %. Tipo id: %. Tipo codice: %', fcde.acc_fde_id, v_afde_tipo_id, v_afde_tipo_code;

		SELECT tafdeb.afde_bil_quinquennio_riferimento, tafdeb.afde_bil_riscossione_virtuosa, tafdeb.afde_bil_id
		INTO v_anno, v_riscossione_virtuosa, v_afde_bil_id
		FROM siac_t_acc_fondi_dubbia_esig_bil tafdeb
		JOIN siac_t_bil_elem tbe ON (tbe.elem_id = v_elem_id AND tbe.bil_id = tafdeb.bil_id)
		WHERE tafdeb.data_cancellazione IS NULL
		AND tafdeb.afde_tipo_id = v_afde_tipo_id;
		RAISE NOTICE 'Elaborazione per FCDE con id %. Id attributi: %. Anno: %. Riscossone virtuosa: %', fcde.acc_fde_id, v_afde_bil_id, v_anno, v_riscossione_virtuosa;

		CASE
			WHEN v_afde_tipo_code = 'PREVISIONE' THEN
				v_idx := NULL;
				FOR v_idx IN 0..4 LOOP
					SELECT SUM(totd.ord_ts_det_importo)
					INTO v_importo
					FROM siac_t_bil_elem tbe_current
					JOIN siac_t_bil_elem tbe ON (tbe_current.elem_code = tbe.elem_code AND tbe_current.elem_code2 = tbe.elem_code2 AND tbe_current.elem_code3 = tbe.elem_code3 AND tbe_current.ente_proprietario_id = tbe.ente_proprietario_id AND tbe.data_cancellazione IS NULL)
					JOIN siac_t_bil tb ON (tb.bil_id = tbe.bil_id AND tb.data_cancellazione IS NULL)
					JOIN siac_t_periodo tp ON (tp.periodo_id = tb.periodo_id AND tp.data_cancellazione IS NULL)
					JOIN siac_d_bil_elem_tipo dbet ON (dbet.elem_tipo_id = tbe.elem_tipo_id AND dbet.data_cancellazione IS NULL)
					JOIN siac_r_bil_elem_stato rbes ON (rbes.elem_id = tbe.elem_id AND rbes.data_cancellazione IS NULL)
					JOIN siac_d_bil_elem_stato dbes ON (dbes.elem_stato_id = rbes.elem_stato_id AND rbes.data_cancellazione IS NULL)
					JOIN siac_r_movgest_bil_elem rmbe ON (rmbe.elem_id = tbe.elem_id AND rmbe.data_cancellazione IS NULL)
					JOIN siac_t_movgest tm ON (tm.movgest_id = rmbe.movgest_id AND tm.data_cancellazione IS NULL)
					JOIN siac_t_movgest_ts tmt ON (tmt.movgest_id = tm.movgest_id AND tmt.data_cancellazione IS NULL)
					JOIN siac_r_movgest_ts_stato rmts ON (rmts.movgest_ts_id = tmt.movgest_ts_id AND rmts.data_cancellazione IS NULL)
					JOIN siac_d_movgest_stato dms ON (dms.movgest_stato_id = rmts.movgest_stato_id AND dms.data_cancellazione IS NULL)
					JOIN siac_r_ordinativo_ts_movgest_ts rotmt ON (rotmt.movgest_ts_id = tmt.movgest_ts_id AND rotmt.data_cancellazione IS NULL)
					JOIN siac_t_ordinativo_ts tot ON (tot.ord_ts_id = rotmt.ord_ts_id AND tot.data_cancellazione IS NULL)
					JOIN siac_t_ordinativo tor ON (tor.ord_id = tot.ord_id AND tor.data_cancellazione IS NULL)
					JOIN siac_r_ordinativo_stato ros ON (ros.ord_id = tor.ord_id AND ros.data_cancellazione IS NULL AND ros.validita_fine IS NULL)
					JOIN siac_d_ordinativo_stato dos ON (dos.ord_stato_id = ros.ord_stato_id AND dos.data_cancellazione IS NULL)
					JOIN siac_t_ordinativo_ts_det totd ON (totd.ord_ts_id = tot.ord_ts_id AND totd.data_cancellazione IS NULL)
					JOIN siac_d_ordinativo_ts_det_tipo dotdt ON (dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id AND dotdt.data_cancellazione IS NULL)
					WHERE tbe_current.elem_id = v_elem_id
					AND dbet.elem_tipo_code = 'CAP-EG'
					AND CAST(tp.anno AS INTEGER) = (v_anno - v_idx)
					AND dbes.elem_stato_code = 'VA'
					AND dms.movgest_stato_code <> 'A'
					AND dos.ord_stato_code <> 'A'
					AND dotdt.ord_ts_det_tipo_code = 'A';

					CASE
						WHEN v_idx = 0 THEN v_acc_fde_numeratore := v_importo;
						WHEN v_idx = 1 THEN v_acc_fde_numeratore_1 := v_importo;
						WHEN v_idx = 2 THEN v_acc_fde_numeratore_2 := v_importo;
						WHEN v_idx = 3 THEN v_acc_fde_numeratore_3 := v_importo;
						WHEN v_idx = 4 THEN v_acc_fde_numeratore_4 := v_importo;
					END CASE;
				END LOOP;
				RAISE NOTICE 'Elaborazione per FCDE %. Previsione. Numeratori: % - % - % - % - %', fcde.acc_fde_id, v_acc_fde_numeratore, v_acc_fde_numeratore_1, v_acc_fde_numeratore_2, v_acc_fde_numeratore_3, v_acc_fde_numeratore_4;

				v_idx := NULL;
				FOR v_idx IN 0..4 LOOP
					SELECT SUM(tmtd.movgest_ts_det_importo)
					INTO v_importo
					FROM siac_t_bil_elem tbe_current
					JOIN siac_t_bil_elem tbe ON (tbe_current.elem_code = tbe.elem_code AND tbe_current.elem_code2 = tbe.elem_code2 AND tbe_current.elem_code3 = tbe.elem_code3 AND tbe_current.ente_proprietario_id = tbe.ente_proprietario_id AND tbe.data_cancellazione IS NULL)
					JOIN siac_t_bil tb ON (tb.bil_id = tbe.bil_id AND tb.data_cancellazione IS NULL)
					JOIN siac_t_periodo tp ON (tp.periodo_id = tb.periodo_id AND tp.data_cancellazione IS NULL)
					JOIN siac_d_bil_elem_tipo dbet ON (dbet.elem_tipo_id = tbe.elem_tipo_id AND dbet.data_cancellazione IS NULL)
					JOIN siac_r_bil_elem_stato rbes ON (rbes.elem_id = tbe.elem_id AND rbes.data_cancellazione IS NULL)
					JOIN siac_d_bil_elem_stato dbes ON (dbes.elem_stato_id = rbes.elem_stato_id AND rbes.data_cancellazione IS NULL)
					JOIN siac_r_movgest_bil_elem rmbe ON (rmbe.elem_id = tbe.elem_id AND rmbe.data_cancellazione IS NULL)
					JOIN siac_t_movgest tm ON (tm.movgest_id = rmbe.movgest_id AND tm.data_cancellazione IS NULL)
					JOIN siac_t_movgest_ts tmt ON (tmt.movgest_id = tm.movgest_id AND tmt.data_cancellazione IS NULL)
					JOIN siac_r_movgest_ts_stato rmts ON (rmts.movgest_ts_id = tmt.movgest_ts_id AND rmts.data_cancellazione IS NULL)
					JOIN siac_d_movgest_stato dms ON (dms.movgest_stato_id = rmts.movgest_stato_id AND dms.data_cancellazione IS NULL)
					JOIN siac_t_movgest_ts_det tmtd ON (tmtd.movgest_ts_id = tmt.movgest_ts_id AND tmtd.data_cancellazione IS NULL)
					JOIN siac_d_movgest_ts_det_tipo dmtdt ON (dmtdt.movgest_ts_det_tipo_id = tmtd.movgest_ts_det_tipo_id AND dmtdt.data_cancellazione IS NULL)
					WHERE tbe_current.elem_id = v_elem_id
					AND dbet.elem_tipo_code = 'CAP-EG'
					AND CAST(tp.anno AS INTEGER) = (v_anno - v_idx)
					AND dbes.elem_stato_code = 'VA'
					AND dms.movgest_stato_code <> 'A'
					AND dmtdt.movgest_ts_det_tipo_code = 'A';

					CASE
						WHEN v_idx = 0 THEN v_acc_fde_denominatore := v_importo;
						WHEN v_idx = 1 THEN v_acc_fde_denominatore_1 := v_importo;
						WHEN v_idx = 2 THEN v_acc_fde_denominatore_2 := v_importo;
						WHEN v_idx = 3 THEN v_acc_fde_denominatore_3 := v_importo;
						WHEN v_idx = 4 THEN v_acc_fde_denominatore_4 := v_importo;
					END CASE;
				END LOOP;
				RAISE NOTICE 'Elaborazione per FCDE %. Previsione. Denominatori: % - % - % - % - %', fcde.acc_fde_id, v_acc_fde_denominatore, v_acc_fde_denominatore_1, v_acc_fde_denominatore_2, v_acc_fde_denominatore_3, v_acc_fde_denominatore_4;
			WHEN v_afde_tipo_code = 'RENDICONTO' THEN
				v_idx := NULL;
				FOR v_idx IN 0..4 LOOP
					SELECT SUM(totd.ord_ts_det_importo)
					INTO v_importo
					FROM siac_t_bil_elem tbe_current
					JOIN siac_t_bil_elem tbe ON (tbe_current.elem_code = tbe.elem_code AND tbe_current.elem_code2 = tbe.elem_code2 AND tbe_current.elem_code3 = tbe.elem_code3 AND tbe_current.ente_proprietario_id = tbe.ente_proprietario_id AND tbe.data_cancellazione IS NULL)
					JOIN siac_t_bil tb ON (tb.bil_id = tbe.bil_id AND tb.data_cancellazione IS NULL)
					JOIN siac_t_periodo tp ON (tp.periodo_id = tb.periodo_id AND tp.data_cancellazione IS NULL)
					JOIN siac_d_bil_elem_tipo dbet ON (dbet.elem_tipo_id = tbe.elem_tipo_id AND dbet.data_cancellazione IS NULL)
					JOIN siac_r_bil_elem_stato rbes ON (rbes.elem_id = tbe.elem_id AND rbes.data_cancellazione IS NULL)
					JOIN siac_d_bil_elem_stato dbes ON (dbes.elem_stato_id = rbes.elem_stato_id AND rbes.data_cancellazione IS NULL)
					JOIN siac_r_movgest_bil_elem rmbe ON (rmbe.elem_id = tbe.elem_id AND rmbe.data_cancellazione IS NULL)
					JOIN siac_t_movgest tm ON (tm.movgest_id = rmbe.movgest_id AND tm.data_cancellazione IS NULL)
					JOIN siac_t_movgest_ts tmt ON (tmt.movgest_id = tm.movgest_id AND tmt.data_cancellazione IS NULL)
					JOIN siac_r_movgest_ts_stato rmts ON (rmts.movgest_ts_id = tmt.movgest_ts_id AND rmts.data_cancellazione IS NULL)
					JOIN siac_d_movgest_stato dms ON (dms.movgest_stato_id = rmts.movgest_stato_id AND dms.data_cancellazione IS NULL)
					JOIN siac_r_ordinativo_ts_movgest_ts rotmt ON (rotmt.movgest_ts_id = tmt.movgest_ts_id AND rotmt.data_cancellazione IS NULL)
					JOIN siac_t_ordinativo_ts tot ON (tot.ord_ts_id = rotmt.ord_ts_id AND tot.data_cancellazione IS NULL)
					JOIN siac_t_ordinativo tor ON (tor.ord_id = tot.ord_id AND tor.data_cancellazione IS NULL)
					JOIN siac_r_ordinativo_stato ros ON (ros.ord_id = tor.ord_id AND ros.data_cancellazione IS NULL AND ros.validita_fine IS NULL)
					JOIN siac_d_ordinativo_stato dos ON (dos.ord_stato_id = ros.ord_stato_id AND dos.data_cancellazione IS NULL)
					JOIN siac_t_ordinativo_ts_det totd ON (totd.ord_ts_id = tot.ord_ts_id AND totd.data_cancellazione IS NULL)
					JOIN siac_d_ordinativo_ts_det_tipo dotdt ON (dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id AND dotdt.data_cancellazione IS NULL)
					WHERE tbe_current.elem_id = v_elem_id
					AND dbet.elem_tipo_code = 'CAP-EG'
					AND CAST(tp.anno AS INTEGER) = (v_anno - v_idx)
					AND dbes.elem_stato_code = 'VA'
					AND dms.movgest_stato_code <> 'A'
					AND tm.movgest_anno < CAST(tp.anno AS INTEGER)
					AND dos.ord_stato_code <> 'A'
					AND tor.ord_anno = CAST(tp.anno AS INTEGER)
					AND dotdt.ord_ts_det_tipo_code = 'A';

					CASE
						WHEN v_idx = 0 THEN v_acc_fde_numeratore := v_importo;
						WHEN v_idx = 1 THEN v_acc_fde_numeratore_1 := v_importo;
						WHEN v_idx = 2 THEN v_acc_fde_numeratore_2 := v_importo;
						WHEN v_idx = 3 THEN v_acc_fde_numeratore_3 := v_importo;
						WHEN v_idx = 4 THEN v_acc_fde_numeratore_4 := v_importo;
					END CASE;
				END LOOP;
				RAISE NOTICE 'Elaborazione per FCDE %. Gestione. Numeratori: % - % - % - % - %', fcde.acc_fde_id, v_acc_fde_numeratore, v_acc_fde_numeratore_1, v_acc_fde_numeratore_2, v_acc_fde_numeratore_3, v_acc_fde_numeratore_4;

				v_idx := NULL;
				FOR v_idx IN 0..4 LOOP
					SELECT SUM(tbed.elem_det_importo)
					INTO v_importo
					FROM siac_t_bil_elem tbe_current
					JOIN siac_t_bil_elem tbe ON (tbe_current.elem_code = tbe.elem_code AND tbe_current.elem_code2 = tbe.elem_code2 AND tbe_current.elem_code3 = tbe.elem_code3 AND tbe_current.ente_proprietario_id = tbe.ente_proprietario_id AND tbe.data_cancellazione IS NULL)
					JOIN siac_t_bil tb ON (tb.bil_id = tbe.bil_id AND tb.data_cancellazione IS NULL)
					JOIN siac_t_periodo tp ON (tp.periodo_id = tb.periodo_id AND tp.data_cancellazione IS NULL)
					JOIN siac_d_bil_elem_tipo dbet ON (dbet.elem_tipo_id = tbe.elem_tipo_id AND dbet.data_cancellazione IS NULL)
					JOIN siac_r_bil_elem_stato rbes ON (rbes.elem_id = tbe.elem_id AND rbes.data_cancellazione IS NULL)
					JOIN siac_d_bil_elem_stato dbes ON (dbes.elem_stato_id = rbes.elem_stato_id AND rbes.data_cancellazione IS NULL)
					JOIN siac_t_bil_elem_det tbed ON (tbed.elem_id = tbe.elem_id AND tbe.data_cancellazione IS NULL)
					JOIN siac_d_bil_elem_det_tipo dbedt ON (dbedt.elem_det_tipo_id = tbed.elem_det_tipo_id AND dbedt.data_cancellazione IS NULL)
					WHERE tbe_current.elem_id = v_elem_id
					AND dbet.elem_tipo_code = 'CAP-EG'
					AND CAST(tp.anno AS INTEGER) = (v_anno - v_idx)
					AND tbed.periodo_id = tp.periodo_id
					AND dbes.elem_stato_code = 'VA'
					AND dbedt.elem_det_tipo_code = 'SRI';

					CASE
						WHEN v_idx = 0 THEN v_acc_fde_denominatore := v_importo;
						WHEN v_idx = 1 THEN v_acc_fde_denominatore_1 := v_importo;
						WHEN v_idx = 2 THEN v_acc_fde_denominatore_2 := v_importo;
						WHEN v_idx = 3 THEN v_acc_fde_denominatore_3 := v_importo;
						WHEN v_idx = 4 THEN v_acc_fde_denominatore_4 := v_importo;
					END CASE;
				END LOOP;
				RAISE NOTICE 'Elaborazione per FCDE %. Gestione. Denominatori: % - % - % - % - %', fcde.acc_fde_id, v_acc_fde_denominatore, v_acc_fde_denominatore_1, v_acc_fde_denominatore_2, v_acc_fde_denominatore_3, v_acc_fde_denominatore_4;
		END CASE;

		-- Media semplice totali
		v_num := 0;
		v_den := 0;
		IF v_acc_fde_denominatore_4 IS NOT NULL AND v_acc_fde_numeratore_4 IS NOT NULL AND v_acc_fde_denominatore_4 <> 0 THEN
			v_num := v_num + v_acc_fde_numeratore_4;
			v_den := v_den + v_acc_fde_denominatore_4;
		END IF;
		IF v_acc_fde_denominatore_3 IS NOT NULL AND v_acc_fde_numeratore_3 IS NOT NULL AND v_acc_fde_denominatore_3 <> 0 THEN
			v_num := v_num + v_acc_fde_numeratore_3;
			v_den := v_den + v_acc_fde_denominatore_3;
		END IF;
		IF v_acc_fde_denominatore_2 IS NOT NULL AND v_acc_fde_numeratore_2 IS NOT NULL AND v_acc_fde_denominatore_2 <> 0 THEN
			v_num := v_num + v_acc_fde_numeratore_2;
			v_den := v_den + v_acc_fde_denominatore_2;
		END IF;
		IF v_acc_fde_denominatore_1 IS NOT NULL AND v_acc_fde_numeratore_1 IS NOT NULL AND v_acc_fde_denominatore_1 <> 0 THEN
			v_num := v_num + v_acc_fde_numeratore_1;
			v_den := v_den + v_acc_fde_denominatore_1;
		END IF;
		IF v_acc_fde_denominatore IS NOT NULL AND v_acc_fde_numeratore IS NOT NULL AND v_acc_fde_denominatore <> 0 THEN
			v_num := v_num + v_acc_fde_numeratore;
			v_den := v_den + v_acc_fde_denominatore;
		END IF;
		IF v_den > 0 THEN
			v_acc_fde_media_semplice_totali := ROUND(LEAST(v_num / v_den, 1) * 100, 5);
		END IF;
		RAISE NOTICE 'Elaborazione per FCDE %. Media semplice totali %', fcde.acc_fde_id, v_acc_fde_media_semplice_totali;

		-- Media semplice rapporti
		v_tmp := 0;
		v_counter := 0;
		IF v_acc_fde_denominatore_4 IS NOT NULL AND v_acc_fde_numeratore_4 IS NOT NULL AND v_acc_fde_denominatore_4 <> 0 THEN
			v_counter := v_counter + 1;
			v_tmp := v_tmp + LEAST(v_acc_fde_numeratore_4 / v_acc_fde_denominatore_4, 1);
		END IF;
		IF v_acc_fde_denominatore_3 IS NOT NULL AND v_acc_fde_numeratore_3 IS NOT NULL AND v_acc_fde_denominatore_3 <> 0 THEN
			v_counter := v_counter + 1;
			v_tmp := v_tmp + LEAST(v_acc_fde_numeratore_3 / v_acc_fde_denominatore_3, 1);
		END IF;
		IF v_acc_fde_denominatore_2 IS NOT NULL AND v_acc_fde_numeratore_2 IS NOT NULL AND v_acc_fde_denominatore_2 <> 0 THEN
			v_counter := v_counter + 1;
			v_tmp := v_tmp + LEAST(v_acc_fde_numeratore_2 / v_acc_fde_denominatore_2, 1);
		END IF;
		IF v_acc_fde_denominatore_1 IS NOT NULL AND v_acc_fde_numeratore_1 IS NOT NULL AND v_acc_fde_denominatore_1 <> 0 THEN
			v_counter := v_counter + 1;
			v_tmp := v_tmp + LEAST(v_acc_fde_numeratore_1 / v_acc_fde_denominatore_1, 1);
		END IF;
		IF v_acc_fde_denominatore IS NOT NULL AND v_acc_fde_numeratore IS NOT NULL AND v_acc_fde_denominatore <> 0 THEN
			v_counter := v_counter + 1;
			v_tmp := v_tmp + LEAST(v_acc_fde_numeratore / v_acc_fde_denominatore, 1);
		END IF;
		IF v_counter > 0 THEN
			v_acc_fde_media_semplice_rapporti := ROUND(LEAST(v_tmp / v_counter, 1) * 100, 5);
		END IF;
		RAISE NOTICE 'Elaborazione per FCDE %. Media semplice rapporti %', fcde.acc_fde_id, v_acc_fde_media_semplice_rapporti;

		-- Media ponderata
		IF
				v_riscossione_virtuosa <> true
				AND v_acc_fde_numeratore IS NOT NULL
				AND v_acc_fde_numeratore_1 IS NOT NULL
				AND v_acc_fde_numeratore_2 IS NOT NULL
				AND v_acc_fde_numeratore_3 IS NOT NULL
				AND v_acc_fde_numeratore_4 IS NOT NULL
				AND v_acc_fde_denominatore IS NOT NULL
				AND v_acc_fde_denominatore_1 IS NOT NULL
				AND v_acc_fde_denominatore_2 IS NOT NULL
				AND v_acc_fde_denominatore_3 IS NOT NULL
				AND v_acc_fde_denominatore_4 IS NOT NULL
		THEN
			-- Media ponderata totali
			v_den = v_acc_fde_denominatore_4 * 0.1 + v_acc_fde_denominatore_3 * 0.1 + v_acc_fde_denominatore_2 * 0.1 + v_acc_fde_denominatore_1 * 0.35 + v_acc_fde_denominatore * 0.35;
			IF v_den <> 0 THEN
				v_num := v_acc_fde_numeratore_4 * 0.1 + v_acc_fde_numeratore_3 *0.1 + v_acc_fde_numeratore_2 * 0.1 + v_acc_fde_numeratore_1 * 0.35 + v_acc_fde_numeratore * 0.35;
				v_acc_fde_media_ponderata_totali := ROUND(LEAST(v_num / v_den, 1) * 100, 5);
			END IF;
			RAISE NOTICE 'Elaborazione per FCDE %. Media ponderata totali %', fcde.acc_fde_id, v_acc_fde_media_ponderata_totali;
			-- Media ponderata rapporti
			v_tmp := 0;
			v_counter := 0;
			IF v_acc_fde_denominatore_4 <> 0 THEN
				v_counter := v_counter + 1;
				v_tmp := v_tmp + LEAST(v_acc_fde_numeratore_4 / v_acc_fde_denominatore_4, 1) * 0.1;
			END IF;
			IF v_acc_fde_denominatore_3 <> 0 THEN
				v_counter := v_counter + 1;
				v_tmp := v_tmp + LEAST(v_acc_fde_numeratore_3 / v_acc_fde_denominatore_3, 1) * 0.1;
			END IF;
			IF v_acc_fde_denominatore_2 <> 0 THEN
				v_counter := v_counter + 1;
				v_tmp := v_tmp + LEAST(v_acc_fde_numeratore_2 / v_acc_fde_denominatore_2, 1) * 0.1;
			END IF;
			IF v_acc_fde_denominatore_1 <> 0 THEN
				v_counter := v_counter + 1;
				v_tmp := v_tmp + LEAST(v_acc_fde_numeratore_1 / v_acc_fde_denominatore_1, 1) * 0.35;
			END IF;
			IF v_acc_fde_denominatore <> 0 THEN
				v_counter := v_counter + 1;
				v_tmp := v_tmp + LEAST(v_acc_fde_numeratore / v_acc_fde_denominatore, 1) * 0.35;
			END IF;
			IF v_counter = 5 THEN
				v_acc_fde_media_ponderata_rapporti := ROUND(LEAST(v_tmp / v_counter, 1) * 100, 5);
			END IF;
			RAISE NOTICE 'Elaborazione per FCDE %. Media ponderata rapporti %', fcde.acc_fde_id, v_acc_fde_media_ponderata_rapporti;
		END IF;
		v_acc_fde_media_utente := v_acc_fde_media_semplice_totali;
	
		UPDATE siac_t_acc_fondi_dubbia_esig tafde
		SET elem_id = v_elem_id,
			afde_tipo_media_id = v_afde_tipo_media_id,
			afde_tipo_id = v_afde_tipo_id,
			acc_fde_numeratore = v_acc_fde_numeratore,
			acc_fde_numeratore_1 = v_acc_fde_numeratore_1,
			acc_fde_numeratore_2 = v_acc_fde_numeratore_2,
			acc_fde_numeratore_3 = v_acc_fde_numeratore_3,
			acc_fde_numeratore_4 = v_acc_fde_numeratore_4,
			acc_fde_denominatore = v_acc_fde_denominatore,
			acc_fde_denominatore_1 = v_acc_fde_denominatore_1,
			acc_fde_denominatore_2 = v_acc_fde_denominatore_2,
			acc_fde_denominatore_3 = v_acc_fde_denominatore_3,
			acc_fde_denominatore_4 = v_acc_fde_denominatore_4,
			acc_fde_media_semplice_rapporti = v_acc_fde_media_semplice_rapporti,
			acc_fde_media_semplice_totali = v_acc_fde_media_semplice_totali,
			acc_fde_media_ponderata_rapporti = v_acc_fde_media_ponderata_rapporti,
			acc_fde_media_ponderata_totali = v_acc_fde_media_ponderata_totali,
			acc_fde_media_utente = v_acc_fde_media_utente,
			acc_fde_meta_numeratore_originale = v_acc_fde_numeratore,
			acc_fde_meta_numeratore_1_originale = v_acc_fde_numeratore_1,
			acc_fde_meta_numeratore_2_originale = v_acc_fde_numeratore_2,
			acc_fde_meta_numeratore_3_originale = v_acc_fde_numeratore_3,
			acc_fde_meta_numeratore_4_originale = v_acc_fde_numeratore_4,
			acc_fde_meta_denominatore_originale = v_acc_fde_denominatore,
			acc_fde_meta_denominatore_1_originale = v_acc_fde_denominatore_1,
			acc_fde_meta_denominatore_2_originale = v_acc_fde_denominatore_2,
			acc_fde_meta_denominatore_3_originale = v_acc_fde_denominatore_3,
			acc_fde_meta_denominatore_4_originale = v_acc_fde_denominatore_4,
			acc_fde_meta_media_utente_originale = v_acc_fde_media_utente,
			acc_fde_meta_accantonamento_anno_originale = null,
			acc_fde_meta_accantonamento_anno1_originale = null,
			acc_fde_meta_accantonamento_anno2_originale = null,
			afde_bil_id = v_afde_bil_id,
			data_modifica = now(),
			login_operazione = tafde.login_operazione || '-SIAC-7858'
		WHERE acc_fde_id = fcde.acc_fde_id;
		RAISE NOTICE 'Elaborazione per FCDE % completata', fcde.acc_fde_id;

	END LOOP;
END $$;

-- Progressivi
INSERT INTO siac.siac_t_acc_fondi_dubbia_esig_bil_num (bil_id, afde_tipo_id, afde_bil_versione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tafdeb.bil_id, tafdeb.afde_tipo_id, MAX(tafdeb.afde_bil_versione), now(), tafdeb.ente_proprietario_id, 'admin'
FROM siac_t_acc_fondi_dubbia_esig_bil tafdeb
WHERE tafdeb.data_cancellazione IS NULL
GROUP BY tafdeb.bil_id, tafdeb.afde_tipo_id, tafdeb.ente_proprietario_id;