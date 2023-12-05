/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_carta_contabile (
    ente_proprietario_id,
    anno_bilancio,
    cartac_stato_code,
    cartac_stato_desc,
    crt_det_sogg_id,
    soggetto_code,
    soggetto_desc,
    attoamm_anno,
    attoamm_numero,
    attoamm_tipo_code,
    attoamm_tipo_desc,
    cod_sac,
    desc_sac,
    cartac_numero,
    cartac_importo,
    cartac_oggetto,
    causale_carta,
    cartac_data_scadenza,
    cartac_data_pagamento,
    note_carta,
    urgenza,
    flagisestera,
    est_causale,
    est_valuta,
    est_data_valuta,
    est_titolare_diverso,
    est_istruzioni,
    crt_det_numero,
    crt_det_desc,
    crt_det_importo,
    crt_det_valuta,
    crt_det_contotesoriere,
    crt_det_mdp_id,
    movgest_anno,
    movgest_numero,
    subimpegno,
    doc_anno,
    doc_numero,
    doc_tipo_code,
    doc_fam_tipo_code,
    doc_data_emissione,
    soggetto_doc,
    subdoc_numero,
    anno_elenco_doc,
    num_elenco_doc,
    doc_id)
AS
SELECT tbb.ente_proprietario_id,
    tbb.anno_bilancio,
    tbb.cartac_stato_code,
    tbb.cartac_stato_desc,
    tbb.crt_det_sogg_id,
    tbb.soggetto_code,
    tbb.soggetto_desc,
    tbb.attoamm_anno,
    tbb.attoamm_numero,
    tbb.attoamm_tipo_code,
    tbb.attoamm_tipo_desc,
    tbb.cod_sac,
    tbb.desc_sac,
    tbb.cartac_numero,
    tbb.cartac_importo,
    tbb.cartac_oggetto,
    tbb.causale_carta,
    tbb.cartac_data_scadenza,
    tbb.cartac_data_pagamento,
    tbb.note_carta,
    tbb.urgenza,
    tbb.flagisestera,
    tbb.est_causale,
    tbb.est_valuta,
    tbb.est_data_valuta,
    tbb.est_titolare_diverso,
    tbb.est_istruzioni,
    tbb.crt_det_numero,
    tbb.crt_det_desc,
    tbb.crt_det_importo,
    tbb.crt_det_valuta,
    tbb.crt_det_contotesoriere,
    tbb.crt_det_mdp_id,
    tbb.movgest_anno,
    tbb.movgest_numero,
    tbb.subimpegno,
    tbb.doc_anno,
    tbb.doc_numero,
    tbb.doc_tipo_code,
    tbb.doc_fam_tipo_code,
    tbb.doc_data_emissione,
    tbb.soggetto_doc,
    tbb.subdoc_numero,
    tbb.anno_elenco_doc,
    tbb.num_elenco_doc,
    tbb.doc_id
FROM ( WITH aa AS (
    SELECT DISTINCT a.ente_proprietario_id,
                    d.anno,
                    f.cartac_stato_id,
                    f.cartac_stato_code,
                    f.cartac_stato_desc,
                    a.cartac_numero,
                    a.cartac_importo,
                    a.cartac_oggetto,
                    a.cartac_causale,
                    a.cartac_data_scadenza,
                    a.cartac_data_pagamento,
                    a.cartac_importo_valuta,
                    a.cartac_id,
                    b.cartac_det_numero,
                    b.cartac_det_desc,
                    b.cartac_det_importo,
                    b.cartac_det_importo_valuta,
                    b.contotes_id,
                    b.cartac_det_id,
                    a.attoamm_id
    FROM siac_t_cartacont a,
                    siac_t_cartacont_det b,
                    siac_t_bil c,
                    siac_t_periodo d,
                    siac_r_cartacont_stato e,
                    siac_d_cartacont_stato f
    WHERE a.cartac_id = b.cartac_id AND a.bil_id = c.bil_id AND d.periodo_id =
        c.periodo_id AND e.cartac_id = a.cartac_id AND e.cartac_stato_id = f.cartac_stato_id AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND now() >= e.validita_inizio AND now() <= COALESCE(e.validita_fine::timestamp with time zone, now())
    ), bb AS (
    SELECT notes.contotes_code,
                    notes.contotes_id
    FROM siac_d_contotesoreria notes
    WHERE notes.data_cancellazione IS NULL
    ), cc AS (
    SELECT i.cartacest_id,
                    i.cartacest_causalepagamento,
                    i.cartacest_data_valuta,
                    i.cartacest_diversotitolare,
                    i.cartacest_istruzioni,
                    i.cartac_id
    FROM siac_t_cartacont_estera i
    WHERE i.data_cancellazione IS NULL
    ), dd AS (
    SELECT rmdp.modpag_id,
                    rmdp.cartac_det_id
    FROM siac_r_cartacont_det_modpag rmdp
    WHERE rmdp.data_cancellazione IS NULL AND now() >= rmdp.validita_inizio AND
        now() <= COALESCE(rmdp.validita_fine::timestamp with time zone, now())
    ), ee AS (
    SELECT rmvgest.cartac_det_id,
                    mvgts.movgest_ts_id_padre,
                    movgest.movgest_anno,
                    movgest.movgest_numero,
                    mvgts.movgest_ts_code
    FROM siac_r_cartacont_det_movgest_ts rmvgest,
                    siac_t_movgest_ts mvgts,
                    siac_t_movgest movgest
    WHERE rmvgest.movgest_ts_id = mvgts.movgest_ts_id AND mvgts.movgest_id =
        movgest.movgest_id AND rmvgest.data_cancellazione IS NULL AND mvgts.data_cancellazione IS NULL AND movgest.data_cancellazione IS NULL AND now() >= rmvgest.validita_inizio AND now() <= COALESCE(rmvgest.validita_fine::timestamp with time zone, now())
    ), ff AS (
    SELECT rsog.soggetto_id,
                    rsog.cartac_det_id,
                    b.soggetto_code,
                    b.soggetto_desc
    FROM siac_r_cartacont_det_soggetto rsog,
                    siac_t_soggetto b
    WHERE rsog.data_cancellazione IS NULL AND b.soggetto_id = rsog.soggetto_id
        AND rsog.validita_fine IS NULL
    ), gg AS (
    SELECT tb.doc_id,
                    tb.cartac_det_id,
                    tb.doc_anno,
                    tb.doc_numero,
                    tb.doc_tipo_code,
                    tb.doc_fam_tipo_code,
                    tb.doc_data_emissione,
                    tb.soggetto_id,
                    tb.subdoc_numero,
                    tb.anno_elenco_doc,
                    tb.num_elenco_doc
    FROM ( WITH gg1 AS (
        SELECT doc.doc_id,
                                    rsubdoc.cartac_det_id,
                                    doc.doc_anno,
                                    doc.doc_numero,
                                    e.doc_tipo_code,
                                    d.doc_fam_tipo_code,
                                    doc.doc_data_emissione,
                                    subdoc.subdoc_numero,
                                    subdoc.subdoc_id
        FROM siac_r_cartacont_det_subdoc rsubdoc,
                                    siac_t_subdoc subdoc,
                                    siac_t_doc doc,
                                    siac_d_doc_fam_tipo d,
                                    siac_d_doc_tipo e
        WHERE subdoc.subdoc_id = rsubdoc.subdoc_id AND doc.doc_id =
            subdoc.doc_id AND rsubdoc.data_cancellazione IS NULL AND subdoc.data_cancellazione IS NULL AND doc.data_cancellazione IS NULL AND e.doc_tipo_id = doc.doc_tipo_id AND d.doc_fam_tipo_id = e.doc_fam_tipo_id AND e.data_cancellazione IS NULL AND d.data_cancellazione IS NULL
        ), gg2 AS (
        SELECT rsogd.soggetto_id,
                                    rsogd.doc_id
        FROM siac_r_doc_sog rsogd
        WHERE rsogd.data_cancellazione IS NULL
        ), gg3 AS (
        SELECT a.subdoc_id,
                                    b.eldoc_anno AS anno_elenco_doc,
                                    b.eldoc_numero AS num_elenco_doc
        FROM siac_r_elenco_doc_subdoc a,
                                    siac_t_elenco_doc b
        WHERE b.eldoc_id = a.eldoc_id AND a.data_cancellazione IS NULL AND
            b.data_cancellazione IS NULL AND a.validita_fine IS NULL
        )
        SELECT gg1.doc_id,
                            gg1.cartac_det_id,
                            gg1.doc_anno,
                            gg1.doc_numero,
                            gg1.doc_tipo_code,
                            gg1.doc_fam_tipo_code,
                            gg1.doc_data_emissione,
                            gg2.soggetto_id,
                            gg1.subdoc_numero,
                            gg3.anno_elenco_doc,
                            gg3.num_elenco_doc
        FROM gg1
                             LEFT JOIN gg2 ON gg1.doc_id = gg2.doc_id
                             LEFT JOIN gg3 ON gg1.subdoc_id = gg3.subdoc_id
        ) tb
    ), hh AS (
    SELECT rurg.testo,
                    rurg.cartac_id
    FROM siac_r_cartacont_attr rurg,
                    siac_t_attr atturg
    WHERE atturg.attr_id = rurg.attr_id AND atturg.attr_code::text =
        'motivo_urgenza'::text AND rurg.data_cancellazione IS NULL AND atturg.data_cancellazione IS NULL
    ), ii AS (
    SELECT rnote.testo,
                    rnote.cartac_id
    FROM siac_r_cartacont_attr rnote,
                    siac_t_attr attrnote
    WHERE attrnote.attr_id = rnote.attr_id AND attrnote.attr_code::text =
        'note'::text AND rnote.data_cancellazione IS NULL AND attrnote.data_cancellazione IS NULL
    ), ll AS (
    SELECT h.attoamm_id,
                    h.attoamm_anno,
                    h.attoamm_numero,
                    daat.attoamm_tipo_code,
                    daat.attoamm_tipo_desc
    FROM siac_t_atto_amm h,
                    siac_d_atto_amm_tipo daat
    WHERE daat.attoamm_tipo_id = h.attoamm_tipo_id AND h.data_cancellazione IS
        NULL AND daat.data_cancellazione IS NULL
    ), mm AS (
    SELECT i.attoamm_id,
                    l.classif_id,
                    l.classif_code,
                    l.classif_desc,
                    m.classif_tipo_code
    FROM siac_r_atto_amm_class i,
                    siac_t_class l,
                    siac_d_class_tipo m,
                    siac_r_class_fam_tree n,
                    siac_t_class_fam_tree o,
                    siac_d_class_fam p
    WHERE i.classif_id = l.classif_id AND m.classif_tipo_id = l.classif_tipo_id
        AND n.classif_id = l.classif_id AND n.classif_fam_tree_id = o.classif_fam_tree_id AND o.classif_fam_id = p.classif_fam_id AND p.classif_fam_code::text = '00005'::text AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL AND m.data_cancellazione IS NULL AND n.data_cancellazione IS NULL AND o.data_cancellazione IS NULL AND p.data_cancellazione IS NULL
    )
    SELECT aa.ente_proprietario_id,
            aa.anno AS anno_bilancio,
            aa.cartac_stato_code,
            aa.cartac_stato_desc,
            ff.soggetto_id AS crt_det_sogg_id,
            ff.soggetto_code,
            ff.soggetto_desc,
            ll.attoamm_anno,
            ll.attoamm_numero,
            ll.attoamm_tipo_code,
            ll.attoamm_tipo_desc,
            mm.classif_code AS cod_sac,
            mm.classif_desc AS desc_sac,
            aa.cartac_numero,
            aa.cartac_importo,
            aa.cartac_oggetto,
            aa.cartac_causale AS causale_carta,
            aa.cartac_data_scadenza,
            aa.cartac_data_pagamento,
            ii.testo AS note_carta,
            hh.testo AS urgenza,
                CASE
                    WHEN cc.cartacest_id IS NOT NULL THEN true
                    ELSE false
                END AS flagisestera,
            cc.cartacest_causalepagamento AS est_causale,
            aa.cartac_importo_valuta AS est_valuta,
            cc.cartacest_data_valuta AS est_data_valuta,
            cc.cartacest_diversotitolare AS est_titolare_diverso,
            cc.cartacest_istruzioni AS est_istruzioni,
            aa.cartac_det_numero AS crt_det_numero,
            aa.cartac_det_desc AS crt_det_desc,
            aa.cartac_det_importo AS crt_det_importo,
            aa.cartac_det_importo_valuta AS crt_det_valuta,
            bb.contotes_code AS crt_det_contotesoriere,
            dd.modpag_id AS crt_det_mdp_id,
            ee.movgest_anno,
            ee.movgest_numero,
                CASE
                    WHEN ee.movgest_ts_id_padre::character varying IS NOT NULL
                        THEN ee.movgest_ts_code
                    ELSE ee.movgest_ts_id_padre::character varying
                END AS subimpegno,
            gg.doc_anno,
            gg.doc_numero,
            gg.doc_tipo_code,
            gg.doc_fam_tipo_code,
            gg.doc_data_emissione,
            gg.soggetto_id AS soggetto_doc,
            gg.subdoc_numero,
            gg.anno_elenco_doc,
            gg.num_elenco_doc,
            gg.doc_id
    FROM aa
             LEFT JOIN bb ON aa.contotes_id = bb.contotes_id
             LEFT JOIN cc ON aa.cartac_id = cc.cartac_id
             LEFT JOIN dd ON aa.cartac_det_id = dd.cartac_det_id
             LEFT JOIN ee ON aa.cartac_det_id = ee.cartac_det_id
             LEFT JOIN ff ON aa.cartac_det_id = ff.cartac_det_id
             LEFT JOIN gg ON aa.cartac_det_id = gg.cartac_det_id
             LEFT JOIN hh ON aa.cartac_id = hh.cartac_id
             LEFT JOIN ii ON aa.cartac_id = ii.cartac_id
             LEFT JOIN ll ON aa.attoamm_id = ll.attoamm_id
             LEFT JOIN mm ON aa.attoamm_id = mm.attoamm_id
    ) tbb
ORDER BY tbb.ente_proprietario_id, tbb.anno_bilancio, tbb.cartac_numero;