/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE VIEW siac.siac_v_dwh_inventario_cespiti (
    ente_proprietario_id,
    ces_id,
    code_scheda_cespite,
    desc_scheda_cespite,
    code_tipo_bene,
    desc_tipo_bene,
    code_cespite_categ,
    desc_cespite_categ,
    perc_ammortamento,
    code_tipo_calcolo,
    desc_tipo_calcolo,
    code_conto_patrimoniale,
    desc_conto_patrimoniale,
    code_conto_ammortamento,
    desc_conto_ammortamento,
    code_evento_ammortamento,
    desc_evento_ammortamento,
    code_conto_fondo_ammortamento,
    desc_conto_fondo_ammortamento,
    code_conto_plusvalenza_alien,
    desc_conto_plusvalenza_alien,
    code_conto_minusvalenza_alien,
    desc_conto_minusvalenza_alien,
    code_conto_incremento_valore,
    desc_conto_incremento_valore,
    code_evento_incremento_valore,
    desc_evento_incremento_valore,
    code_conto_decremento_valore,
    desc_conto_decremento_valore,
    code_evento_decremento_valore,
    desc_evento_decremento_valore,
    code_conto_credito_alien,
    desc_conto_credito_alien,
    code_conto_donazione_rinven,
    desc_conto_donazione_rinven,
    code_classificazione_giurid,
    desc_classificazione_giurid,
    soggetto_beni_culturali,
    donazione_rinvenimento,
    numero_inventario,
    data_ingresso_inventario,
    valore_iniziale,
    id_fattura,
    anno_fattura,
    numero_fattura,
    soggetto_id_fattura,
    code_soggetto_fattura,
    desc_soggetto_fattura,
    code_tipo_fattura,
    code_tipo_fam_fattura,
    data_fattura,
    numero_quota,
    importo_quota,
    anno_impegno,
    numero_impegno,
    importo_impegno,
    numero_subimpegno,
    importo_subimpegno,
    soggetto_id_impegno,
    code_soggetto_impegno,
    desc_soggetto_impegno,
    code_pdce_finanziario,
    desc_pdce_finanziario,
    anno_liquidazione,
    numero_liquidazione,
    importo_liquidazione,
    soggetto_id_liquidazione,
    code_soggetto_liquidazione,
    desc_soggetto_liquidazione,
    attivo,
    descrizione_stato,
    ubicazione,
    anno_ammortamento_massivo,
    data_ammortamento_massivo,
    importo_ammortamento_massivo,
    anno_ammortamento_annuo,
    importo_ammortamento_annuo,
    data_cessazione_dismis,
    anno_provvedimento_dismis,
    numero_provvedimento_dismis,
    tipo_provvedimento_dismis,
    importo_dismis,
    importo_rivalutazione,
    importo_svalutazione,
    importo_donazione)
AS
 WITH cespiti AS (
SELECT t_cespiti.ente_proprietario_id,
            t_cespiti.ces_id,
            t_cespiti.ces_code AS code_scheda_cespite,
            t_cespiti.ces_desc AS desc_scheda_cespite,
            d_cespiti_bene_tipo.ces_bene_tipo_code AS code_tipo_bene,
            d_cespiti_bene_tipo.ces_bene_tipo_desc AS desc_tipo_bene,
            d_cespiti_categ.cescat_code AS code_cespite_categ,
            d_cespiti_categ.cescat_desc AS desc_cespite_categ,
            r_cespiti_categ_calcolo.aliquota_annua AS perc_ammortamento,
            d_cespiti_categ_calcolo.cescat_calcolo_tipo_code AS code_tipo_calcolo,
            d_cespiti_categ_calcolo.cescat_calcolo_tipo_desc AS desc_tipo_calcolo,
            COALESCE(r_cespiti_bene_tipo.pdce_conto_patrimoniale_code,
                ''::character varying) AS code_conto_patrimoniale,
            COALESCE(r_cespiti_bene_tipo.pdce_conto_patrimoniale_desc,
                ''::character varying) AS desc_conto_patrimoniale,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_ammortamento_code,
                ''::character varying) AS code_conto_ammortamento,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_ammortamento_desc,
                ''::character varying) AS desc_conto_ammortamento,
            COALESCE(d_cespiti_bene_tipo.evento_ammortamento_code,
                ''::character varying) AS code_evento_ammortamento,
            COALESCE(d_cespiti_bene_tipo.evento_ammortamento_desc,
                ''::character varying) AS desc_evento_ammortamento,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_fondo_ammortamento_code,
                ''::character varying) AS code_conto_fondo_ammortamento,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_fondo_ammortamento_desc,
                ''::character varying) AS desc_conto_fondo_ammortamento,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_plusvalenza_code,
                ''::character varying) AS code_conto_plusvalenza_alienazione,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_plusvalenza_desc,
                ''::character varying) AS desc_conto_plusvalenza_alienazione,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_minusvalenza_code,
                ''::character varying) AS code_conto_minusvalenza_alienazione,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_minusvalenza_desc,
                ''::character varying) AS desc_conto_minusvalenza_alienazione,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_incremento_code,
                ''::character varying) AS code_conto_incremento_valore,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_incremento_desc,
                ''::character varying) AS desc_conto_incremento_valore,
            COALESCE(d_cespiti_bene_tipo.evento_incremento_code, ''::character
                varying) AS code_evento_incremento_valore,
            COALESCE(d_cespiti_bene_tipo.evento_incremento_desc, ''::character
                varying) AS desc_evento_incremento_valore,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_decremento_code,
                ''::character varying) AS code_conto_decremento_valore,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_decremento_desc,
                ''::character varying) AS desc_conto_decremento_valore,
            COALESCE(d_cespiti_bene_tipo.evento_decremento_code, ''::character
                varying) AS code_evento_decremento_valore,
            COALESCE(d_cespiti_bene_tipo.evento_decremento_desc, ''::character
                varying) AS desc_evento_decremento_valore,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_alienazione_code,
                ''::character varying) AS code_conto_credito_alienazione,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_alienazione_desc,
                ''::character varying) AS desc_conto_credito_alienazione,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_donazione_code,
                ''::character varying) AS code_conto_donazione_rinvenimento,
            COALESCE(d_cespiti_bene_tipo.pdce_conto_donazione_desc,
                ''::character varying) AS desc_conto_donazione_rinvenimento,
            d_cespiti_class_giuri.ces_class_giu_code AS code_classificazione_giuridica,
            d_cespiti_class_giuri.ces_class_giu_desc AS desc_classificazione_giuridica,
                CASE
                    WHEN t_cespiti.soggetto_beni_culturali = true THEN 'SI'::text
                    ELSE 'NO'::text
                END AS soggetto_beni_culturali,
                CASE
                    WHEN t_cespiti.flg_donazione_rinvenimento = true THEN 'SI'::text
                    ELSE 'NO'::text
                END AS donazione_rinvenimento,
            t_cespiti.num_inventario AS numero_inventario,
            t_cespiti.data_ingresso_inventario,
            t_cespiti.valore_iniziale,
            t_cespiti.descrizione_stato,
            t_cespiti.ubicazione,
                CASE
                    WHEN t_cespiti.flg_stato_bene = true THEN 'SI'::text
                    ELSE 'NO'::text
                END AS attivo,
            t_cespiti.ces_dismissioni_id,
                CASE
                    WHEN t_cespiti.flg_donazione_rinvenimento = true THEN
                        t_cespiti.valore_attuale
                    ELSE 0::numeric
                END AS importo_donazione
FROM siac_t_cespiti t_cespiti,
            siac_d_cespiti_bene_tipo d_cespiti_bene_tipo,
            siac_r_cespiti_bene_tipo_conto_patr_cat r_cespiti_bene_tipo,
            siac_d_cespiti_categoria d_cespiti_categ,
            siac_r_cespiti_categoria_aliquota_calcolo_tipo r_cespiti_categ_calcolo,
            siac_d_cespiti_categoria_calcolo_tipo d_cespiti_categ_calcolo,
            siac_d_cespiti_classificazione_giuridica d_cespiti_class_giuri
WHERE t_cespiti.ces_bene_tipo_id = d_cespiti_bene_tipo.ces_bene_tipo_id AND
    r_cespiti_bene_tipo.ces_bene_tipo_id = d_cespiti_bene_tipo.ces_bene_tipo_id AND d_cespiti_categ.cescat_id = r_cespiti_bene_tipo.cescat_id AND r_cespiti_categ_calcolo.cescat_id = d_cespiti_categ.cescat_id AND d_cespiti_categ_calcolo.cescat_calcolo_tipo_id = r_cespiti_categ_calcolo.cescat_calcolo_tipo_id AND d_cespiti_class_giuri.ces_class_giu_id = t_cespiti.ces_class_giu_id AND t_cespiti.data_cancellazione IS NULL AND t_cespiti.validita_fine IS NULL AND d_cespiti_bene_tipo.data_cancellazione IS NULL AND d_cespiti_bene_tipo.validita_fine IS NULL AND r_cespiti_bene_tipo.data_cancellazione IS NULL AND r_cespiti_bene_tipo.validita_fine IS NULL AND d_cespiti_categ.data_cancellazione IS NULL AND d_cespiti_categ.validita_fine IS NULL AND d_cespiti_bene_tipo.validita_fine IS NULL AND r_cespiti_categ_calcolo.data_cancellazione IS NULL AND r_cespiti_categ_calcolo.validita_fine IS NULL AND d_cespiti_categ_calcolo.data_cancellazione IS NULL AND d_cespiti_categ_calcolo.validita_fine IS NULL AND d_cespiti_class_giuri.data_cancellazione IS NULL AND d_cespiti_class_giuri.validita_fine IS NULL
        ), documenti AS (
    SELECT r_cesp_mov_ep_det.ente_proprietario_id,
            r_cesp_mov_ep_det.ces_id,
            t_doc.doc_id,
            t_doc.doc_anno,
            t_doc.doc_numero,
            t_subdoc.subdoc_id,
            t_subdoc.subdoc_numero,
            t_subdoc.subdoc_importo,
            t_class.classif_code AS pdce_conto_code,
            t_class.classif_desc AS pdce_conto_desc,
            t_reg_movfin.classif_id_aggiornato,
            t_reg_movfin.pdce_conto_id,
            t_soggetto.soggetto_id,
            t_soggetto.soggetto_code,
            t_soggetto.soggetto_desc,
            t_doc.doc_data_emissione,
            d_doc_tipo.doc_tipo_code,
            d_doc_tipo.doc_tipo_desc,
            d_doc_fam_tipo.doc_fam_tipo_code,
            d_doc_fam_tipo.doc_fam_tipo_desc
    FROM siac_r_cespiti_mov_ep_det r_cesp_mov_ep_det,
            siac_t_mov_ep_det t_mov_ep_det,
            siac_t_mov_ep t_mov_ep,
            siac_t_reg_movfin t_reg_movfin
             LEFT JOIN siac_t_class t_class ON t_class.classif_id =
                 t_reg_movfin.classif_id_aggiornato AND t_class.ente_proprietario_id = t_reg_movfin.ente_proprietario_id AND t_class.data_cancellazione IS NULL AND t_class.validita_fine IS NULL,
            siac_r_evento_reg_movfin r_evento_reg_movfin,
            siac_t_subdoc t_subdoc,
            siac_t_doc t_doc,
            siac_t_soggetto t_soggetto,
            siac_r_doc_sog r_doc_sog,
            siac_d_doc_tipo d_doc_tipo,
            siac_d_doc_fam_tipo d_doc_fam_tipo
    WHERE r_cesp_mov_ep_det.movep_det_id = t_mov_ep_det.movep_det_id AND
        t_mov_ep_det.movep_id = t_mov_ep.movep_id AND t_mov_ep.regmovfin_id = t_reg_movfin.regmovfin_id AND t_reg_movfin.regmovfin_id = r_evento_reg_movfin.regmovfin_id AND (r_evento_reg_movfin.campo_pk_id = t_subdoc.subdoc_id OR r_evento_reg_movfin.campo_pk_id = t_doc.doc_id) AND t_doc.doc_id = t_subdoc.doc_id AND t_mov_ep.ambito_id = t_reg_movfin.ambito_id AND r_doc_sog.doc_id = t_doc.doc_id AND r_doc_sog.soggetto_id = t_soggetto.soggetto_id AND t_doc.doc_tipo_id = d_doc_tipo.doc_tipo_id AND d_doc_tipo.doc_fam_tipo_id = d_doc_fam_tipo.doc_fam_tipo_id AND r_cesp_mov_ep_det.data_cancellazione IS NULL AND r_cesp_mov_ep_det.validita_fine IS NULL AND t_mov_ep_det.data_cancellazione IS NULL AND t_mov_ep_det.validita_fine IS NULL AND t_mov_ep.data_cancellazione IS NULL AND t_mov_ep.validita_fine IS NULL AND t_reg_movfin.data_cancellazione IS NULL AND t_reg_movfin.validita_fine IS NULL AND r_evento_reg_movfin.data_cancellazione IS NULL AND r_evento_reg_movfin.validita_fine IS NULL AND t_subdoc.data_cancellazione IS NULL AND t_subdoc.validita_fine IS NULL AND t_doc.data_cancellazione IS NULL AND t_doc.validita_fine IS NULL AND t_soggetto.data_cancellazione IS NULL AND t_soggetto.validita_fine IS NULL AND r_doc_sog.data_cancellazione IS NULL AND r_doc_sog.validita_fine IS NULL AND d_doc_tipo.data_cancellazione IS NULL AND d_doc_tipo.validita_fine IS NULL AND d_doc_fam_tipo.data_cancellazione IS NULL AND d_doc_fam_tipo.validita_fine IS NULL
    ), impegni AS (
    SELECT t_movgest_ts.movgest_ts_id,
            t_movgest.movgest_anno,
            t_movgest.movgest_numero,
            t_movgest_ts.movgest_ts_code,
            t_movgest_ts_det.movgest_ts_det_importo,
            r_subdoc_movgest_ts.subdoc_id,
            t_movgest.ente_proprietario_id,
            t_soggetto.soggetto_code,
            t_soggetto.soggetto_desc,
            t_soggetto.soggetto_id,
            d_movgest_ts_tipo.movgest_ts_tipo_code,
            importi_imp.importo_impegno
    FROM siac_t_movgest t_movgest
             LEFT JOIN (
        SELECT a.movgest_id,
                    a.ente_proprietario_id,
                    e.movgest_ts_det_importo AS importo_impegno
        FROM siac_t_movgest a,
                    siac_t_movgest_ts b,
                    siac_d_movgest_tipo c,
                    siac_d_movgest_ts_tipo d,
                    siac_t_movgest_ts_det e,
                    siac_d_movgest_ts_det_tipo f
        WHERE a.movgest_id = b.movgest_id AND a.movgest_tipo_id =
            c.movgest_tipo_id AND b.movgest_ts_tipo_id = d.movgest_ts_tipo_id AND b.movgest_ts_id = e.movgest_ts_id AND e.movgest_ts_det_tipo_id = f.movgest_ts_det_tipo_id AND c.movgest_tipo_code::text = 'I'::text AND d.movgest_ts_tipo_code::text = 'T'::text AND f.movgest_ts_det_tipo_code::text = 'A'::text AND a.data_cancellazione IS NULL AND a.validita_fine IS NULL AND b.data_cancellazione IS NULL AND b.validita_fine IS NULL AND c.data_cancellazione IS NULL AND c.validita_fine IS NULL AND d.data_cancellazione IS NULL AND d.validita_fine IS NULL AND e.data_cancellazione IS NULL AND e.validita_fine IS NULL AND f.data_cancellazione IS NULL AND f.validita_fine IS NULL
        ) importi_imp ON importi_imp.movgest_id = t_movgest.movgest_id AND
            importi_imp.ente_proprietario_id = t_movgest.ente_proprietario_id,
            siac_t_movgest_ts t_movgest_ts,
            siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_t_movgest_ts_det t_movgest_ts_det,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
            siac_r_subdoc_movgest_ts r_subdoc_movgest_ts,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_sog r_movgest_ts_sogg,
            siac_t_soggetto t_soggetto
    WHERE t_movgest.movgest_id = t_movgest_ts.movgest_id AND
        d_movgest_ts_tipo.movgest_ts_tipo_id = t_movgest_ts.movgest_ts_tipo_id AND t_movgest_ts_det.movgest_ts_id = t_movgest_ts.movgest_ts_id AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id = t_movgest_ts_det.movgest_ts_det_tipo_id AND t_movgest_ts.movgest_ts_id = r_subdoc_movgest_ts.movgest_ts_id AND d_movgest_tipo.movgest_tipo_id = t_movgest.movgest_tipo_id AND r_movgest_ts_sogg.movgest_ts_id = t_movgest_ts.movgest_ts_id AND r_movgest_ts_sogg.soggetto_id = t_soggetto.soggetto_id AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code::text = 'A'::text AND d_movgest_tipo.movgest_tipo_code::text = 'I'::text AND t_movgest.data_cancellazione IS NULL AND t_movgest.validita_fine IS NULL AND t_movgest_ts.data_cancellazione IS NULL AND t_movgest_ts.validita_fine IS NULL AND d_movgest_ts_tipo.data_cancellazione IS NULL AND d_movgest_ts_tipo.validita_fine IS NULL AND t_movgest_ts_det.data_cancellazione IS NULL AND t_movgest_ts.validita_fine IS NULL AND d_movgest_ts_det_tipo.data_cancellazione IS NULL AND d_movgest_ts_det_tipo.validita_fine IS NULL AND r_subdoc_movgest_ts.data_cancellazione IS NULL AND r_subdoc_movgest_ts.validita_fine IS NULL AND r_movgest_ts_sogg.data_cancellazione IS NULL AND r_movgest_ts_sogg.validita_fine IS NULL AND t_soggetto.data_cancellazione IS NULL AND t_soggetto.validita_fine IS NULL
    ), liquidazioni AS (
    SELECT t_liq.liq_id,
            t_liq.ente_proprietario_id,
            t_liq.liq_anno,
            t_liq.liq_numero,
            t_liq.liq_importo,
            r_subdoc_liq.subdoc_id,
            t_soggetto.soggetto_code,
            t_soggetto.soggetto_desc,
            t_soggetto.soggetto_id
    FROM siac_r_subdoc_liquidazione r_subdoc_liq,
            siac_t_liquidazione t_liq,
            siac_r_liquidazione_soggetto r_liq_sogg,
            siac_t_soggetto t_soggetto
    WHERE r_subdoc_liq.liq_id = t_liq.liq_id AND t_liq.liq_id =
        r_liq_sogg.liq_id AND r_liq_sogg.soggetto_id = t_soggetto.soggetto_id AND r_subdoc_liq.data_cancellazione IS NULL AND r_subdoc_liq.validita_fine IS NULL AND t_liq.data_cancellazione IS NULL AND t_liq.validita_fine IS NULL AND r_liq_sogg.data_cancellazione IS NULL AND r_liq_sogg.validita_fine IS NULL AND t_soggetto.data_cancellazione IS NULL AND t_soggetto.validita_fine IS NULL
    ), dismissioni AS (
    SELECT t_cespiti_dism.ces_dismissioni_id,
            t_cespiti_dism.ente_proprietario_id,
            t_cespiti_dism.data_cessazione,
            t_atto_amm.attoamm_anno,
            t_atto_amm.attoamm_numero,
            d_atto_amm_tipo.attoamm_tipo_code,
            d_atto_amm_tipo.attoamm_tipo_desc
    FROM siac_t_cespiti_dismissioni t_cespiti_dism,
            siac_t_atto_amm t_atto_amm,
            siac_d_atto_amm_tipo d_atto_amm_tipo
    WHERE t_cespiti_dism.attoamm_id = t_atto_amm.attoamm_id AND
        d_atto_amm_tipo.attoamm_tipo_id = t_atto_amm.attoamm_tipo_id AND t_cespiti_dism.data_cancellazione IS NULL AND t_cespiti_dism.validita_fine IS NULL AND t_atto_amm.data_cancellazione IS NULL AND t_atto_amm.validita_fine IS NULL AND d_atto_amm_tipo.data_cancellazione IS NULL AND d_atto_amm_tipo.validita_fine IS NULL
    ), cespiti_rivalutazioni AS (
    SELECT t_cespiti_var.ces_id,
            t_cespiti_var.ente_proprietario_id,
            sum(t_cespiti_var.ces_var_importo) AS importo_rivalutazione
    FROM siac_t_cespiti_variazione t_cespiti_var,
            siac_d_cespiti_variazione_stato d_cespiti_var_stato
    WHERE t_cespiti_var.ces_var_stato_id = d_cespiti_var_stato.ces_var_stato_id
        AND d_cespiti_var_stato.ces_var_stato_code::text <> 'A'::text AND t_cespiti_var.flg_tipo_variazione_incr = true AND t_cespiti_var.data_cancellazione IS NULL AND t_cespiti_var.validita_fine IS NULL AND d_cespiti_var_stato.data_cancellazione IS NULL AND d_cespiti_var_stato.validita_fine IS NULL
    GROUP BY t_cespiti_var.ces_id, t_cespiti_var.ente_proprietario_id
    ), cespiti_svalutazioni AS (
    SELECT t_cespiti_var.ces_id,
            t_cespiti_var.ente_proprietario_id,
            sum(t_cespiti_var.ces_var_importo) AS importo_svalutazione
    FROM siac_t_cespiti_variazione t_cespiti_var,
            siac_d_cespiti_variazione_stato d_cespiti_var_stato
    WHERE t_cespiti_var.ces_var_stato_id = d_cespiti_var_stato.ces_var_stato_id
        AND d_cespiti_var_stato.ces_var_stato_code::text <> 'A'::text AND t_cespiti_var.flg_tipo_variazione_incr = false AND t_cespiti_var.data_cancellazione IS NULL AND t_cespiti_var.validita_fine IS NULL AND d_cespiti_var_stato.data_cancellazione IS NULL AND d_cespiti_var_stato.validita_fine IS NULL
    GROUP BY t_cespiti_var.ces_id, t_cespiti_var.ente_proprietario_id
    ), dati_ammortamento AS (
    SELECT t_cespiti_ammort.ces_id,
            t_cespiti_ammort.ente_proprietario_id,
            t_cespiti_ammort_dett.ces_amm_dett_id,
            t_cespiti_ammort.ces_amm_ultimo_anno_reg,
            t_cespiti_ammort.ces_amm_importo_tot_reg,
            t_cespiti_ammort_dett.ces_amm_dett_anno,
            t_cespiti_ammort_dett.ces_amm_dett_importo,
            t_cespiti_ammort_dett.ces_amm_dett_data,
            t_cespiti_ammort_dett.pnota_id,
            t_cespiti_ammort_dett.num_reg_def_ammortamento
    FROM siac_t_cespiti_ammortamento t_cespiti_ammort,
            siac_t_cespiti_ammortamento_dett t_cespiti_ammort_dett
    WHERE t_cespiti_ammort.ces_amm_id = t_cespiti_ammort_dett.ces_amm_id AND
        t_cespiti_ammort.data_cancellazione IS NULL AND t_cespiti_ammort.validita_fine IS NULL AND t_cespiti_ammort_dett.data_cancellazione IS NULL AND t_cespiti_ammort_dett.validita_fine IS NULL
    ), dismissioni_importo AS (
    SELECT t_cespiti_dismis.ces_dismissioni_id,
            t_mov_ep_det.movep_det_importo,
            t_cespiti_dismis.ente_proprietario_id
    FROM siac_t_cespiti t_cesp,
            siac_t_cespiti_dismissioni t_cespiti_dismis,
            siac_r_cespiti_dismissioni_prima_nota r_cesp_dismi_prima_nota,
            siac_t_prima_nota t_prima_nota,
            siac_t_mov_ep t_mov_ep,
            siac_t_mov_ep_det t_mov_ep_det,
            siac_r_evento_causale r_ev_causale,
            siac_d_evento d_evento,
            siac_t_cespiti_ammortamento_dett t_cesp_ammort_dett
    WHERE t_cesp.ces_dismissioni_id = t_cespiti_dismis.ces_dismissioni_id AND
        t_cespiti_dismis.ces_dismissioni_id = r_cesp_dismi_prima_nota.ces_dismissioni_id AND r_cesp_dismi_prima_nota.pnota_id = t_prima_nota.pnota_id AND t_prima_nota.pnota_id = t_mov_ep.regep_id AND t_mov_ep_det.movep_id = t_mov_ep.movep_id AND r_ev_causale.causale_ep_id = t_mov_ep.causale_ep_id AND d_evento.evento_id = r_ev_causale.evento_id AND t_cesp_ammort_dett.ces_amm_dett_id = r_cesp_dismi_prima_nota.ces_amm_dett_id AND d_evento.evento_code::text = 'DIS'::text AND t_mov_ep_det.movep_det_segno = 'Dare'::bpchar AND (t_mov_ep_det.movep_det_id IN (
        SELECT max(a.movep_det_id) AS max
        FROM siac_t_mov_ep_det a
        WHERE a.movep_id = t_mov_ep_det.movep_id AND a.data_cancellazione IS
            NULL AND a.validita_fine IS NULL
        )) AND t_cesp.data_cancellazione IS NULL AND t_cesp.validita_fine IS
            NULL AND t_cespiti_dismis.data_cancellazione IS NULL AND t_cespiti_dismis.validita_fine IS NULL AND r_cesp_dismi_prima_nota.data_cancellazione IS NULL AND r_cesp_dismi_prima_nota.validita_fine IS NULL AND t_prima_nota.data_cancellazione IS NULL AND t_prima_nota.validita_fine IS NULL AND t_mov_ep.data_cancellazione IS NULL AND t_mov_ep.validita_fine IS NULL AND t_mov_ep_det.data_cancellazione IS NULL AND t_mov_ep_det.validita_fine IS NULL AND r_ev_causale.data_cancellazione IS NULL AND r_ev_causale.validita_fine IS NULL AND d_evento.data_cancellazione IS NULL AND d_evento.validita_fine IS NULL AND t_cesp_ammort_dett.data_cancellazione IS NULL AND t_cesp_ammort_dett.validita_fine IS NULL
    )
    SELECT cespiti.ente_proprietario_id,
    cespiti.ces_id,
    cespiti.code_scheda_cespite,
    cespiti.desc_scheda_cespite,
    cespiti.code_tipo_bene,
    cespiti.desc_tipo_bene,
    cespiti.code_cespite_categ,
    cespiti.desc_cespite_categ,
    cespiti.perc_ammortamento,
    cespiti.code_tipo_calcolo,
    cespiti.desc_tipo_calcolo,
    cespiti.code_conto_patrimoniale::character varying(200) AS code_conto_patrimoniale,
    cespiti.desc_conto_patrimoniale::character varying(500) AS desc_conto_patrimoniale,
    cespiti.code_conto_ammortamento::character varying(200) AS code_conto_ammortamento,
    cespiti.desc_conto_ammortamento::character varying(500) AS desc_conto_ammortamento,
    cespiti.code_evento_ammortamento::character varying(200) AS
        code_evento_ammortamento,
    cespiti.desc_evento_ammortamento::character varying(500) AS
        desc_evento_ammortamento,
    cespiti.code_conto_fondo_ammortamento::character varying(200) AS
        code_conto_fondo_ammortamento,
    cespiti.desc_conto_fondo_ammortamento::character varying(500) AS
        desc_conto_fondo_ammortamento,
    cespiti.code_conto_plusvalenza_alienazione::character varying(200) AS
        code_conto_plusvalenza_alien,
    cespiti.desc_conto_plusvalenza_alienazione::character varying(500) AS
        desc_conto_plusvalenza_alien,
    cespiti.code_conto_minusvalenza_alienazione::character varying(200) AS
        code_conto_minusvalenza_alien,
    cespiti.desc_conto_minusvalenza_alienazione::character varying(500) AS
        desc_conto_minusvalenza_alien,
    cespiti.code_conto_incremento_valore::character varying(200) AS
        code_conto_incremento_valore,
    cespiti.desc_conto_incremento_valore::character varying(500) AS
        desc_conto_incremento_valore,
    cespiti.code_evento_incremento_valore::character varying(200) AS
        code_evento_incremento_valore,
    cespiti.desc_evento_incremento_valore::character varying(500) AS
        desc_evento_incremento_valore,
    cespiti.code_conto_decremento_valore::character varying(200) AS
        code_conto_decremento_valore,
    cespiti.desc_conto_decremento_valore::character varying(500) AS
        desc_conto_decremento_valore,
    cespiti.code_evento_decremento_valore::character varying(200) AS
        code_evento_decremento_valore,
    cespiti.desc_evento_decremento_valore::character varying(500) AS
        desc_evento_decremento_valore,
    cespiti.code_conto_credito_alienazione::character varying(200) AS
        code_conto_credito_alien,
    cespiti.desc_conto_credito_alienazione::character varying(500) AS
        desc_conto_credito_alien,
    cespiti.code_conto_donazione_rinvenimento::character varying(200) AS
        code_conto_donazione_rinven,
    cespiti.desc_conto_donazione_rinvenimento::character varying(500) AS
        desc_conto_donazione_rinven,
    cespiti.code_classificazione_giuridica AS code_classificazione_giurid,
    cespiti.desc_classificazione_giuridica AS desc_classificazione_giurid,
    cespiti.soggetto_beni_culturali::character varying(2) AS soggetto_beni_culturali,
    cespiti.donazione_rinvenimento::character varying(2) AS donazione_rinvenimento,
    cespiti.numero_inventario,
    cespiti.data_ingresso_inventario,
    cespiti.valore_iniziale,
    documenti.doc_id AS id_fattura,
    documenti.doc_anno AS anno_fattura,
    COALESCE(documenti.doc_numero, ''::character varying)::character
        varying(200) AS numero_fattura,
    documenti.soggetto_id AS soggetto_id_fattura,
    COALESCE(documenti.soggetto_code, ''::character varying)::character
        varying(200) AS code_soggetto_fattura,
    COALESCE(documenti.soggetto_desc, ''::character varying)::character
        varying(500) AS desc_soggetto_fattura,
    COALESCE(documenti.doc_tipo_code, ''::character varying)::character
        varying(200) AS code_tipo_fattura,
    COALESCE(documenti.doc_fam_tipo_code, ''::character varying)::character
        varying(200) AS code_tipo_fam_fattura,
    documenti.doc_data_emissione AS data_fattura,
    documenti.subdoc_numero AS numero_quota,
    documenti.subdoc_importo AS importo_quota,
    impegni.movgest_anno AS anno_impegno,
    impegni.movgest_numero AS numero_impegno,
    impegni.importo_impegno,
    COALESCE(impegni.movgest_ts_code, ''::character varying)::character
        varying(200) AS numero_subimpegno,
    impegni.movgest_ts_det_importo AS importo_subimpegno,
    impegni.soggetto_id AS soggetto_id_impegno,
    COALESCE(impegni.soggetto_code, ''::character varying)::character
        varying(200) AS code_soggetto_impegno,
    COALESCE(impegni.soggetto_desc, ''::character varying)::character
        varying(500) AS desc_soggetto_impegno,
    COALESCE(documenti.pdce_conto_code, ''::character varying)::character
        varying(200) AS code_pdce_finanziario,
    COALESCE(documenti.pdce_conto_desc, ''::character varying)::character
        varying(500) AS desc_pdce_finanziario,
    liquidazioni.liq_anno AS anno_liquidazione,
    liquidazioni.liq_numero AS numero_liquidazione,
    liquidazioni.liq_importo AS importo_liquidazione,
    liquidazioni.soggetto_id AS soggetto_id_liquidazione,
    COALESCE(liquidazioni.soggetto_code, ''::character varying)::character
        varying(200) AS code_soggetto_liquidazione,
    COALESCE(liquidazioni.soggetto_desc, ''::character varying)::character
        varying(500) AS desc_soggetto_liquidazione,
    cespiti.attivo::character varying(2) AS attivo,
    cespiti.descrizione_stato,
    cespiti.ubicazione,
    dati_ammortamento.ces_amm_dett_anno AS anno_ammortamento_massivo,
    dati_ammortamento.ces_amm_dett_data AS data_ammortamento_massivo,
    dati_ammortamento.ces_amm_dett_importo AS importo_ammortamento_massivo,
        CASE
            WHEN dati_ammortamento.pnota_id IS NOT NULL OR
                dati_ammortamento.num_reg_def_ammortamento IS NOT NULL THEN dati_ammortamento.ces_amm_dett_anno
            ELSE NULL::integer
        END AS anno_ammortamento_annuo,
        CASE
            WHEN dati_ammortamento.pnota_id IS NOT NULL OR
                dati_ammortamento.num_reg_def_ammortamento IS NOT NULL THEN dati_ammortamento.ces_amm_dett_importo
            ELSE NULL::numeric
        END AS importo_ammortamento_annuo,
    dismissioni.data_cessazione AS data_cessazione_dismis,
    dismissioni.attoamm_anno AS anno_provvedimento_dismis,
    dismissioni.attoamm_numero AS numero_provvedimento_dismis,
    dismissioni.attoamm_tipo_desc AS tipo_provvedimento_dismis,
    COALESCE(dismissioni_importo.movep_det_importo, 0::numeric) AS importo_dismis,
    cespiti_rivalutazioni.importo_rivalutazione,
    cespiti_svalutazioni.importo_svalutazione,
    cespiti.importo_donazione
    FROM cespiti
     LEFT JOIN documenti ON documenti.ces_id = cespiti.ces_id AND
         documenti.ente_proprietario_id = cespiti.ente_proprietario_id
     LEFT JOIN impegni ON impegni.subdoc_id = documenti.subdoc_id AND
         impegni.ente_proprietario_id = documenti.ente_proprietario_id
     LEFT JOIN liquidazioni ON liquidazioni.subdoc_id = documenti.subdoc_id AND
         liquidazioni.ente_proprietario_id = documenti.ente_proprietario_id
     LEFT JOIN dismissioni ON dismissioni.ces_dismissioni_id =
         cespiti.ces_dismissioni_id AND dismissioni.ente_proprietario_id = cespiti.ente_proprietario_id
     LEFT JOIN cespiti_rivalutazioni ON cespiti_rivalutazioni.ces_id =
         cespiti.ces_id AND cespiti_rivalutazioni.ente_proprietario_id = cespiti.ente_proprietario_id
     LEFT JOIN cespiti_svalutazioni ON cespiti_svalutazioni.ces_id =
         cespiti.ces_id AND cespiti_svalutazioni.ente_proprietario_id = cespiti.ente_proprietario_id
     LEFT JOIN dati_ammortamento ON dati_ammortamento.ces_id = cespiti.ces_id
         AND dati_ammortamento.ente_proprietario_id = cespiti.ente_proprietario_id
     LEFT JOIN dismissioni_importo ON dismissioni_importo.ces_dismissioni_id =
         dismissioni.ces_dismissioni_id AND dismissioni_importo.ente_proprietario_id = dismissioni.ente_proprietario_id
    ORDER BY cespiti.ente_proprietario_id, cespiti.code_scheda_cespite;
	