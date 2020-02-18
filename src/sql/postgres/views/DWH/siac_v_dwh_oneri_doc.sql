/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE VIEW siac.siac_v_dwh_oneri_doc (
    ente_proprietario_id,
    doc_tipo_code,
    doc_anno,
    doc_numero,
    data_emissione,
    soggetto_id,
    soggetto_code,
    onere_tipo_code,
    onere_tipo_desc,
    onere_code,
    onere_desc,
    importo_imponibile,
    importo_carico_ente,
    importo_carico_soggetto,
    somma_non_soggetta,
    perc_carico_ente,
    perc_carico_sogg,
    doc_stato_code,
    doc_stato_desc,
    doc_id,
    attivita_code,
    attivita_desc,
    attivita_inizio,
    attivita_fine,
    quadro_770,
    causale_code,
    causale_desc,
    somma_non_soggetta_tipo_code,
    somma_non_soggetta_tipo_desc)
AS
SELECT --DISTINCT  11.06.2018 Sofia SIAC-6233
    tb.ente_proprietario_id, tb.doc_tipo_code, tb.doc_anno,
    tb.doc_numero, tb.doc_data_emissione AS data_emissione, tb.soggetto_id,
    tb.soggetto_code, tb.onere_code AS onere_tipo_code,
    tb.onere_desc AS onere_tipo_desc, tb.onere_tipo_code AS onere_code,
    tb.onere_tipo_desc AS onere_desc, tb.importo_imponibile,
    tb.importo_carico_ente, tb.importo_carico_soggetto, tb.somma_non_soggetta,
    tb.perc_carico_ente, tb.perc_carico_sogg, tb.doc_stato_code,
    tb.doc_stato_desc, tb.doc_id, tb.onere_att_code AS attivita_code,
    tb.onere_att_desc AS attivita_desc, tb.attivita_inizio, tb.attivita_fine,
    tb.quadro_770, tb.caus_code AS causale_code, tb.caus_desc AS causale_desc,
    tb.somma_non_soggetta_tipo_code, tb.somma_non_soggetta_tipo_desc
FROM ( WITH aa AS (
    SELECT a.ente_proprietario_id, dt.doc_tipo_code, d.doc_anno,
                    d.doc_numero, d.doc_data_emissione, e.soggetto_id,
                    e.soggetto_code, a.onere_code, a.onere_desc,
                    b.onere_tipo_code, b.onere_tipo_desc, c.importo_imponibile,
                    c.importo_carico_ente, c.importo_carico_soggetto,
                    COALESCE(c.somma_non_soggetta, 0::numeric) AS somma_non_soggetta,
                    a.onere_id, g.doc_stato_code, g.doc_stato_desc, d.doc_id,
                    c.onere_att_id, c.caus_id, c.somma_non_soggetta_tipo_id,
                    c.attivita_inizio, c.attivita_fine
    FROM siac_d_onere a, siac_d_onere_tipo b, siac_r_doc_onere c,
                    siac_t_doc d, siac_d_doc_tipo dt, siac_r_doc_sog er,
                    siac_t_soggetto e, siac_r_doc_stato f, siac_d_doc_stato g
    WHERE a.onere_tipo_id = b.onere_tipo_id AND a.onere_id = c.onere_id AND
        c.doc_id = d.doc_id AND dt.doc_tipo_id = d.doc_tipo_id AND er.doc_id = d.doc_id AND er.soggetto_id = e.soggetto_id AND f.doc_id = d.doc_id AND f.doc_stato_id = g.doc_stato_id AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND dt.data_cancellazione IS NULL AND er.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND f.data_cancellazione IS NULL AND g.data_cancellazione IS NULL AND now() >= c.validita_inizio AND now() <= COALESCE(c.validita_fine::timestamp with time zone, now()) AND now() >= er.validita_inizio AND now() <= COALESCE(er.validita_fine::timestamp with time zone, now()) AND now() >= f.validita_inizio AND now() <= COALESCE(f.validita_fine::timestamp with time zone, now())
    ), bb AS (
    SELECT rattr1.onere_id,
                    COALESCE(rattr1.percentuale, 0::numeric) AS perc_carico_ente
    FROM siac_r_onere_attr rattr1, siac_t_attr attr1
    WHERE rattr1.attr_id = attr1.attr_id AND attr1.attr_code::text =
        'ALIQUOTA_ENTE'::text AND rattr1.data_cancellazione IS NULL AND attr1.data_cancellazione IS NULL AND now() >= rattr1.validita_inizio AND now() <= COALESCE(rattr1.validita_fine::timestamp with time zone, now())
    ), cc AS (
    SELECT rattr2.onere_id,
                    COALESCE(rattr2.percentuale, 0::numeric) AS perc_carico_sogg
    FROM siac_r_onere_attr rattr2, siac_t_attr attr2
    WHERE rattr2.attr_id = attr2.attr_id AND attr2.attr_code::text =
        'ALIQUOTA_SOGG'::text AND rattr2.data_cancellazione IS NULL AND attr2.data_cancellazione IS NULL AND now() >= rattr2.validita_inizio AND now() <= COALESCE(rattr2.validita_fine::timestamp with time zone, now())
    ), dd AS (
    SELECT roa.onere_id, doa.onere_att_code, doa.onere_att_desc,
                    roa.onere_att_id
    FROM siac_r_onere_attivita roa, siac_d_onere_attivita doa
    WHERE roa.onere_att_id = doa.onere_att_id AND roa.data_cancellazione IS
        NULL AND doa.data_cancellazione IS NULL AND now() >= roa.validita_inizio AND now() <= COALESCE(roa.validita_fine::timestamp with time zone, now())
    ), ee AS (
    SELECT rattr3.onere_id, rattr3.testo AS quadro_770
    FROM siac_r_onere_attr rattr3, siac_t_attr attr3
    WHERE rattr3.attr_id = attr3.attr_id AND attr3.attr_code::text =
        'QUADRO_770'::text AND rattr3.data_cancellazione IS NULL AND attr3.data_cancellazione IS NULL AND now() >= rattr3.validita_inizio AND now() <= COALESCE(rattr3.validita_fine::timestamp with time zone, now())
    ), ff AS (
    SELECT dc.caus_id, dc.caus_code, dc.caus_desc
    FROM siac_d_causale dc
    WHERE dc.data_cancellazione IS NULL
    ), gg AS (
    SELECT dsnst.somma_non_soggetta_tipo_id,
                    dsnst.somma_non_soggetta_tipo_code,
                    dsnst.somma_non_soggetta_tipo_desc
    FROM siac_d_somma_non_soggetta_tipo dsnst
    WHERE dsnst.data_cancellazione IS NULL
    )
    SELECT aa.ente_proprietario_id, aa.doc_tipo_code, aa.doc_anno,
            aa.doc_numero, aa.doc_data_emissione, aa.soggetto_id,
            aa.soggetto_code, aa.onere_code, aa.onere_desc, aa.onere_tipo_code,
            aa.onere_tipo_desc, aa.importo_imponibile, aa.importo_carico_ente,
            aa.importo_carico_soggetto, aa.somma_non_soggetta,
            bb.perc_carico_ente, cc.perc_carico_sogg, aa.doc_stato_code,
            aa.doc_stato_desc, aa.doc_id, dd.onere_att_code, dd.onere_att_desc,
            aa.attivita_inizio, aa.attivita_fine, ee.quadro_770, ff.caus_code,
            ff.caus_desc, gg.somma_non_soggetta_tipo_code,
            gg.somma_non_soggetta_tipo_desc
    FROM aa
      LEFT JOIN bb ON aa.onere_id = bb.onere_id
   LEFT JOIN cc ON aa.onere_id = cc.onere_id
   LEFT JOIN dd ON aa.onere_id = dd.onere_id AND aa.onere_att_id = dd.onere_att_id
   LEFT JOIN ee ON aa.onere_id = ee.onere_id
   LEFT JOIN ff ON aa.caus_id = ff.caus_id
   LEFT JOIN gg ON aa.somma_non_soggetta_tipo_id = gg.somma_non_soggetta_tipo_id
    ) tb; 