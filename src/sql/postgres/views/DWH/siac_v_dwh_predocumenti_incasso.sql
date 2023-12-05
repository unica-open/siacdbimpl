/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_predocumenti_incasso (
    ente_proprietario_id,
    predoc_id,
    predoc_numero,
    predoc_periodo_competenza,
    predoc_data_competenza,
    data_esecuzione,
    predoc_data_trasmissione,
    predoc_importo,
    descrizione,
    predoc_codice_iuv,
    predoc_note,
    predoc_stato_code,
    predoc_stato_desc,
    struttura_code,
    struttura_desc,
    struttura_tipo_code,
    conto_corrente_code,
    conto_corrente_desc,
    famiglia_causale_code,
    famiglia_causale_desc,
    tipo_causale_code,
    tipo_causale_desc,
    causale_code,
    causale_desc,
    predocan_ragione_sociale,
    predocan_cognome,
    predocan_nome,
    predocan_codice_fiscale,
    predocan_partita_iva,
    soggetto_id,
    soggetto_codice,
    soggetto_desc,
    movgest_anno,
    movgest_numero,
    sub,
    doc_id,
    doc_numero,
    doc_anno,
    doc_data_emissione,
    doc_tipo_code,
    doc_tipo_desc,
    doc_fam_tipo_code,
    doc_fam_tipo_desc)
AS
 WITH pred AS (
SELECT a.ente_proprietario_id, a.predoc_id, a.predoc_numero,
            a.predoc_periodo_competenza, a.predoc_data_competenza,
            a.predoc_data, a.predoc_data_trasmissione, a.predoc_importo,
            replace(a.predoc_desc::text, '\r\n'::text, ' '::text) AS predoc_desc,
            a.predoc_codice_iuv, a.predoc_note, c.predoc_stato_code,
            c.predoc_stato_desc, i.caus_fam_tipo_code, i.caus_fam_tipo_desc,
            g.caus_tipo_code, g.caus_tipo_desc, e.caus_code,
            replace(e.caus_desc::text, '\r\n'::text, ' '::text) AS caus_desc,
            h.predocan_ragione_sociale, h.predocan_cognome, h.predocan_nome,
            h.predocan_codice_fiscale, h.predocan_partita_iva,
            l.doc_fam_tipo_code, l.doc_fam_tipo_desc
FROM siac_t_predoc a, siac_r_predoc_stato b, siac_d_predoc_stato c,
            siac_r_predoc_causale d, siac_d_causale e, siac_r_causale_tipo f,
            siac_d_causale_tipo g, siac_t_predoc_anagr h,
            siac_d_causale_fam_tipo i, siac_d_doc_fam_tipo l
WHERE b.predoc_id = a.predoc_id AND c.predoc_stato_id = b.predoc_stato_id AND
    d.predoc_id = a.predoc_id AND e.caus_id = d.caus_id AND f.caus_id = e.caus_id AND g.caus_tipo_id = f.caus_tipo_id AND h.predoc_id = a.predoc_id AND i.caus_fam_tipo_id = g.caus_fam_tipo_id AND a.doc_fam_tipo_id = l.doc_fam_tipo_id AND l.doc_fam_tipo_code::text = 'E'::text AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND f.data_cancellazione IS NULL AND g.data_cancellazione IS NULL AND h.data_cancellazione IS NULL AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL
        ), sog AS (
    SELECT a.predoc_id, b.soggetto_id, b.soggetto_code, b.soggetto_desc
    FROM siac_r_predoc_sog a, siac_t_soggetto b
    WHERE b.soggetto_id = a.soggetto_id AND a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL
    ), movgest AS (
    SELECT a.predoc_id, c.movgest_anno, c.movgest_numero,
                CASE
                    WHEN d.movgest_ts_tipo_code::text = 'T'::text THEN
                        '0'::character varying(200)
                    ELSE b.movgest_ts_code
                END AS movgest_ts_code
    FROM siac_r_predoc_movgest_ts a, siac_t_movgest_ts b,
            siac_t_movgest c, siac_d_movgest_ts_tipo d
    WHERE a.movgest_ts_id = b.movgest_ts_id AND c.movgest_id = b.movgest_id AND
        d.movgest_ts_tipo_id = b.movgest_ts_tipo_id AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL
    ), sac AS (
    SELECT a.predoc_id, b.classif_code, b.classif_desc,
            c.classif_tipo_code
    FROM siac_r_predoc_class a, siac_t_class b, siac_d_class_tipo c
    WHERE a.classif_id = b.classif_id AND c.classif_tipo_id = b.classif_tipo_id
        AND (c.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])) AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL
    ), cc AS (
    SELECT a.predoc_id, b.classif_code, b.classif_desc,
            c.classif_tipo_code
    FROM siac_r_predoc_class a, siac_t_class b, siac_d_class_tipo c
    WHERE a.classif_id = b.classif_id AND c.classif_tipo_id = b.classif_tipo_id
        AND c.classif_tipo_code::text = 'CBPI'::text AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL
    ), doc AS (
    SELECT e.predoc_id, a.doc_id, a.doc_numero, a.doc_anno,
            a.doc_data_emissione, c.doc_tipo_code, c.doc_tipo_desc
    FROM siac_t_doc a, siac_t_subdoc b, siac_d_doc_tipo c,
            siac_r_predoc_subdoc e
    WHERE a.doc_id = b.doc_id AND c.doc_tipo_id = a.doc_tipo_id AND e.subdoc_id
        = b.subdoc_id AND a.data_cancellazione IS NULL AND e.validita_fine IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND e.data_cancellazione IS NULL
    )
    SELECT pred.ente_proprietario_id, pred.predoc_id, pred.predoc_numero,
    pred.predoc_periodo_competenza, pred.predoc_data_competenza,
    pred.predoc_data AS data_esecuzione, pred.predoc_data_trasmissione,
    pred.predoc_importo, pred.predoc_desc AS descrizione,
    pred.predoc_codice_iuv, pred.predoc_note, pred.predoc_stato_code,
    pred.predoc_stato_desc, sac.classif_code AS struttura_code,
    sac.classif_desc AS struttura_desc,
    sac.classif_tipo_code AS struttura_tipo_code,
    cc.classif_code AS conto_corrente_code,
    cc.classif_desc AS conto_corrente_desc,
    pred.caus_fam_tipo_code AS famiglia_causale_code,
    pred.caus_fam_tipo_desc AS famiglia_causale_desc,
    pred.caus_tipo_code AS tipo_causale_code,
    pred.caus_tipo_desc AS tipo_causale_desc, pred.caus_code AS causale_code,
    pred.caus_desc AS causale_desc, pred.predocan_ragione_sociale,
    pred.predocan_cognome, pred.predocan_nome, pred.predocan_codice_fiscale,
    pred.predocan_partita_iva, sog.soggetto_id,
    sog.soggetto_code AS soggetto_codice, sog.soggetto_desc,
    movgest.movgest_anno, movgest.movgest_numero,
    movgest.movgest_ts_code AS sub, doc.doc_id, doc.doc_numero, doc.doc_anno,
    doc.doc_data_emissione, doc.doc_tipo_code, doc.doc_tipo_desc,
    pred.doc_fam_tipo_code, pred.doc_fam_tipo_desc
    FROM pred
   LEFT JOIN sog ON pred.predoc_id = sog.predoc_id
   LEFT JOIN movgest ON pred.predoc_id = movgest.predoc_id
   LEFT JOIN sac ON pred.predoc_id = sac.predoc_id
   LEFT JOIN cc ON pred.predoc_id = cc.predoc_id
   LEFT JOIN doc ON pred.predoc_id = doc.predoc_id
    ORDER BY pred.ente_proprietario_id, pred.predoc_numero, pred.predoc_data_competenza;