/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE MATERIALIZED VIEW siac.v_simop_fatt_ricev
AS WITH sac AS (
        SELECT r.doc_id,
            cl.classif_code AS codice_sac
        FROM siac_r_doc_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo_1
        WHERE r.ente_proprietario_id = 2
        AND r.classif_id = cl.classif_id
        AND cl.classif_tipo_id = tipo_1.classif_tipo_id
        AND tipo_1.classif_tipo_code IN ('CDC', 'CDR')
        AND r.data_cancellazione IS NULL
        AND r.validita_fine IS NULL
    ), cup AS (
        SELECT sub_1.subdoc_id,
            rattr.testo AS codice_cup
        FROM siac_t_subdoc sub_1,
            siac_t_doc doc_1,
            siac_t_attr attr,
            siac_r_subdoc_attr rattr
        WHERE sub_1.ente_proprietario_id = 2
        AND sub_1.doc_id = doc_1.doc_id
        AND rattr.subdoc_id = sub_1.subdoc_id
        AND rattr.testo IS NOT NULL
        AND rattr.testo <> ''
        AND attr.attr_id = rattr.attr_id
        AND attr.attr_code = 'cup'
        AND rattr.data_cancellazione IS NULL
        AND rattr.validita_fine IS NULL
    ), cig AS (
        SELECT sub_1.subdoc_id,
            rattr.testo AS codice_cig
        FROM siac_t_subdoc sub_1,
            siac_t_doc doc_1,
            siac_t_attr attr,
            siac_r_subdoc_attr rattr
        WHERE sub_1.ente_proprietario_id = 2
        AND sub_1.doc_id = doc_1.doc_id
        AND rattr.subdoc_id = sub_1.subdoc_id
        AND rattr.testo IS NOT NULL
        AND rattr.testo <> ''
        AND attr.attr_id = rattr.attr_id
        AND attr.attr_code = 'cig'
        AND rattr.data_cancellazione IS NULL
        AND rattr.validita_fine IS NULL
    ), impegno AS (
        SELECT rimp.subdoc_id,
            imp.movgest_anno,
            imp.movgest_numero,
            imp.movgest_subnumero
        FROM siac_r_subdoc_movgest_ts rimp,
            siac_v_bko_impegno_valido imp
        WHERE rimp.ente_proprietario_id = 2
        AND rimp.movgest_ts_id = imp.movgest_ts_id
        AND rimp.data_cancellazione IS NULL
        AND rimp.validita_fine IS NULL
    ), liquidazione AS (
        SELECT rsubliq.subdoc_id,
            liq.liq_anno,
            liq.liq_numero,
            liq.liq_importo
        FROM siac_r_subdoc_liquidazione rsubliq,
            siac_t_liquidazione liq
        WHERE rsubliq.ente_proprietario_id = 2
        AND rsubliq.liq_id = liq.liq_id
        AND rsubliq.data_cancellazione IS NULL
        AND rsubliq.validita_fine IS NULL
    ), mandato AS (
        SELECT rso.subdoc_id,
            mand.ord_anno,
            mand.ord_numero,
            mand.ord_emissione_data,
            det.ord_ts_det_importo AS importomandato
        FROM siac_t_ordinativo_ts_det det,
            siac_d_ordinativo_tipo tipo_1,
            siac_t_ordinativo mand,
            siac_t_ordinativo_ts ts,
            siac_r_subdoc_ordinativo_ts rso,
            siac_d_ordinativo_ts_det_tipo tipoimporto
        WHERE mand.ente_proprietario_id = 2
        AND mand.ord_tipo_id = tipo_1.ord_tipo_id
        AND tipo_1.ord_tipo_code = 'P'
        AND mand.ord_id = ts.ord_id
        AND ts.ord_ts_id = det.ord_ts_id
        AND det.ord_ts_det_tipo_id = tipoimporto.ord_ts_det_tipo_id
        AND tipoimporto.ord_ts_det_tipo_code = 'A'
        AND ts.ord_ts_id = rso.ord_ts_id
        AND rso.data_cancellazione IS NULL
        AND rso.validita_fine IS NULL
    )
    SELECT DISTINCT
        sog.soggetto_code AS codice_anagrafico_fornitore,
        sog.soggetto_desc AS nome_partecipata,
        sog.codice_fiscale AS codice_fiscale_partecipata,
        sog.partita_iva AS p_iva_partecipata,
        'RE' AS stato_documento,
        ufficio.pccuff_code AS ipa_struttura_capitolina,
        sac.codice_sac AS responsabile_procedura,
        doc.doc_sdi_lotto_siope AS identificativo_sdi,
        '' AS progressivo_invio_sdi,
        to_char(doc.doc_data_emissione, 'YYYYMMDD') AS data_ricezione_sdi,
        to_char(doc.data_creazione, 'YYYYMMDD') AS data_registrazione,
        tipo.doc_tipo_code AS tipo_documento,
        to_char(doc.doc_data_emissione, 'YYYYMMDD') AS data_fattura,
        doc.doc_numero AS n_fattura,
        to_char(doc.doc_anno) AS anno_fattura,
        doc.doc_importo AS importo_totale_fattura,
        ronere.importo_imponibile,
        ivamov.ivamov_totale AS importo_iva,
        sosp.subdoc_sosp_causale AS codice_sospensione,
        to_char(sosp.subdoc_sosp_data, 'YYYYMMDD') AS data_sospensione,
        cig.codice_cig,
        cup.codice_cup,
        impegno.movgest_anno AS anno_impegno,
        impegno.movgest_numero AS numero_impegno,
        impegno.movgest_subnumero AS numero_sub_impegno,
        sub.subdoc_importo AS importo_rata_fattura,
        CASE
            WHEN sosp.subdoc_sosp_data IS NOT NULL THEN 'CN'
            ELSE ''
        END AS codice_di_non_pagabilita,
        liquidazione.liq_anno || '/' || liquidazione.liq_numero AS numero_liquidazione,
        liquidazione.liq_importo AS importo_liquidato,
        CASE
            WHEN to_char(mandato.ord_emissione_data, 'YYYY') = to_char(sub.data_creazione, 'YYYY') THEN mandato.importomandato
            ELSE 0
        END AS importo_pagato_entro,
        CASE
            WHEN to_char(mandato.ord_emissione_data, 'YYYY') <> to_char(sub.data_creazione, 'YYYY') THEN mandato.importomandato
            ELSE 0
        END AS importo_pagato_oltre,
        mandato.ord_numero AS numero_mandato,
        to_char(doc.doc_id) AS id,
        CASE
            WHEN stato.doc_stato_code = 'EM' THEN to_char(stato.data_creazione, 'YYYYMMDD')
            ELSE NULL
        END AS data_chiusura
    FROM siac_d_doc_tipo tipo,
        siac_d_doc_fam_tipo fam,
        siac_r_doc_sog rsog,
        siac_t_soggetto sog,
        siac_t_soc_partecipate part,
        siac_r_doc_stato rs,
        siac_d_doc_stato stato,
        siac_t_doc doc
    LEFT JOIN siac_d_pcc_ufficio ufficio ON doc.pccuff_id = ufficio.pccuff_id
    LEFT JOIN sac ON doc.doc_id = sac.doc_id
    LEFT JOIN siac_r_doc_onere ronere ON doc.doc_id = ronere.doc_id AND ronere.data_cancellazione IS NULL AND ronere.validita_fine IS NULL
    LEFT JOIN siac_r_doc_iva riva ON doc.doc_id = riva.doc_id AND riva.data_cancellazione IS NULL AND riva.validita_fine IS NULL
    LEFT JOIN siac_t_subdoc_iva subiva ON riva.dociva_r_id = subiva.dociva_r_id
    LEFT JOIN siac_r_ivamov rimavo ON subiva.subdociva_id = rimavo.subdociva_id AND rimavo.data_cancellazione IS NULL AND rimavo.validita_fine IS NULL
    LEFT JOIN siac_t_ivamov ivamov ON rimavo.ivamov_id = ivamov.ivamov_id
    LEFT JOIN siac_t_subdoc sub ON doc.doc_id = sub.doc_id
    LEFT JOIN cig ON sub.subdoc_id = cig.subdoc_id
    LEFT JOIN cup ON sub.subdoc_id = cup.subdoc_id
    LEFT JOIN siac_t_subdoc_sospensione sosp ON sub.subdoc_id = sosp.subdoc_id
    LEFT JOIN impegno ON sub.subdoc_id = impegno.subdoc_id
    LEFT JOIN liquidazione ON sub.subdoc_id = liquidazione.subdoc_id
    LEFT JOIN mandato ON sub.subdoc_id = mandato.subdoc_id
    WHERE doc.ente_proprietario_id = 2
    AND doc.doc_tipo_id = tipo.doc_tipo_id
    AND tipo.doc_tipo_code = 'FAT'
    AND tipo.doc_fam_tipo_id = fam.doc_fam_tipo_id
    AND fam.doc_fam_tipo_code = 'S'
    AND rsog.doc_id = doc.doc_id
    AND sog.soggetto_id = rsog.soggetto_id
    AND sog.soggetto_code = part.codice
    AND part.anno::INTEGER = doc.doc_anno
    AND rs.doc_id = doc.doc_id
    AND rs.doc_stato_id = stato.doc_stato_id
    AND stato.doc_stato_code <> 'A'
    AND rsog.data_cancellazione IS NULL
    AND rsog.validita_fine IS NULL
    AND rs.data_cancellazione IS NULL
    AND rs.validita_fine IS NULL
WITH DATA;

CREATE OR REPLACE MATERIALIZED VIEW siac.v_simop_fatt_daricev
AS SELECT DISTINCT
        sog.soggetto_code AS codice_anagrafico_fornitore,
        sog.soggetto_desc AS nome_partecipata,
        sog.codice_fiscale::CHARACTER VARYING(16) AS codice_fiscale_partecipata,
        sog.partita_iva AS p_iva_partecipata,
        'PR' AS stato_documento,
        fat.codice_destinatario AS ipa_struttura_capitolina,
        ' ' AS responsabile_procedura,
        portale.identificativo_sdi,
        '' AS progressivo_invio_sdi,
        '' AS data_ricezione_sdi,
        '' AS data_registrazione,
        '' AS tipo_documento,
        '' AS data_fattura,
        fat.numero AS n_fattura,
        to_char(fat.data, 'YYYY') AS anno_fattura,
        fat.importo_totale_documento AS importo_totale_fattura,
        fat.importo_totale_netto AS importo_imponibile,
        fat.importo_totale_documento - fat.importo_totale_netto AS importo_iva,
        '' AS codice_sospensione,
        '' AS data_sospensione,
        '' AS codice_cig,
        '' AS codice_cup,
        '' AS anno_impegno,
        '' AS numero_impegno,
        '' AS numero_sub_impegno,
        '' AS importo_rata_fattura,
        '' AS codice_di_non_pagabilita,
        '' AS numero_liquidazione,
        '' AS importo_liquidato,
        '' AS importo_pagato_entro,
        '' AS importo_pagato_oltre,
        '' AS numero_mandato,
        '' AS id,
        '' AS data_chiusura
    FROM sirfel_t_fattura fat,
        siac_t_soc_partecipate part,
        siac_t_soggetto sog,
        sirfel_t_prestatore stp,
        sirfel_t_portale_fatture portale
    WHERE fat.stato_fattura = 'N'
    AND stp.id_prestatore = fat.id_prestatore
    AND portale.id_fattura = fat.id_fattura
    AND portale.esito_utente_codice = part.codice_fiscale
    AND part.anno = to_char(fat.data, 'YYYY')
    AND portale.esito_utente_codice = sog.codice_fiscale
WITH DATA;

CREATE OR REPLACE MATERIALIZED VIEW siac.v_simop_fatt_poscre
AS WITH sac AS (
        SELECT r.doc_id,
            cl.classif_code AS codice_sac
        FROM siac_r_doc_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo_1
        WHERE r.ente_proprietario_id = 2
        AND r.classif_id = cl.classif_id
        AND cl.classif_tipo_id = tipo_1.classif_tipo_id
        AND tipo_1.classif_tipo_code in ('CDC', 'CDR')
        AND r.data_cancellazione IS NULL
        AND r.validita_fine IS NULL
    ), cup AS (
        SELECT sub_1.subdoc_id,
            rattr.testo AS codice_cup
        FROM siac_t_subdoc sub_1,
            siac_t_doc doc_1,
            siac_t_attr attr,
            siac_r_subdoc_attr rattr
        WHERE sub_1.ente_proprietario_id = 2
        AND sub_1.doc_id = doc_1.doc_id
        AND rattr.subdoc_id = sub_1.subdoc_id
        AND rattr.testo IS NOT NULL
        AND rattr.testo <> ''
        AND attr.attr_id = rattr.attr_id
        AND attr.attr_code = 'cup'
        AND rattr.data_cancellazione IS NULL
        AND rattr.validita_fine IS NULL
    ), cig AS (
        SELECT sub_1.subdoc_id,
            rattr.testo AS codice_cig
        FROM siac_t_subdoc sub_1,
            siac_t_doc doc_1,
            siac_t_attr attr,
            siac_r_subdoc_attr rattr
        WHERE sub_1.ente_proprietario_id = 2
        AND sub_1.doc_id = doc_1.doc_id
        AND rattr.subdoc_id = sub_1.subdoc_id
        AND rattr.testo IS NOT NULL
        AND rattr.testo <> ''
        AND attr.attr_id = rattr.attr_id
        AND attr.attr_code = 'cig'
        AND rattr.data_cancellazione IS NULL
        AND rattr.validita_fine IS NULL
    ), accertamento AS (
        SELECT rimp.subdoc_id,
            imp.movgest_anno,
            imp.movgest_numero,
            imp.movgest_subnumero
        FROM siac_r_subdoc_movgest_ts rimp,
            siac_v_bko_accertamento_valido imp
        WHERE rimp.ente_proprietario_id = 2
        AND rimp.movgest_ts_id = imp.movgest_ts_id
        AND rimp.data_cancellazione IS NULL
        AND rimp.validita_fine IS NULL
    ), reversale AS (
        SELECT rso.subdoc_id,
            rev.ord_anno,
            rev.ord_numero,
            rev.ord_emissione_data,
            det.ord_ts_det_importo AS importoreversale
        FROM siac_t_ordinativo_ts_det det,
            siac_d_ordinativo_tipo tipo_1,
            siac_t_ordinativo rev,
            siac_t_ordinativo_ts ts,
            siac_r_subdoc_ordinativo_ts rso,
            siac_d_ordinativo_ts_det_tipo tipoimporto
        WHERE rev.ente_proprietario_id = 2
        AND rev.ord_tipo_id = tipo_1.ord_tipo_id
        AND tipo_1.ord_tipo_code = 'P'
        AND rev.ord_id = ts.ord_id
        AND ts.ord_ts_id = det.ord_ts_id
        AND det.ord_ts_det_tipo_id = tipoimporto.ord_ts_det_tipo_id
        AND tipoimporto.ord_ts_det_tipo_code = 'A'
        AND ts.ord_ts_id = rso.ord_ts_id
        AND rso.data_cancellazione IS NULL AND rso.validita_fine IS NULL
    )
    SELECT DISTINCT
        sog.soggetto_code AS codice_anagrafico_fornitore,
        sog.soggetto_desc AS nome_partecipata,
        sog.codice_fiscale AS codice_fiscale_partecipata,
        sog.partita_iva AS p_iva_partecipata,
        'RE' AS stato_documento,
        ufficio.pccuff_code AS ipa_struttura_capitolina,
        sac.codice_sac AS responsabile_procedura,
        doc.doc_sdi_lotto_siope AS identificativo_sdi,
        '' AS progressivo_invio_sdi,
        to_char(doc.doc_data_emissione, 'YYYYMMDD') AS data_ricezione_sdi,
        to_char(doc.data_creazione, 'YYYYMMDD') AS data_registrazione,
        tipo.doc_tipo_code AS tipo_documento,
        to_char(doc.doc_data_emissione, 'YYYYMMDD') AS data_fattura,
        doc.doc_numero AS n_fattura,
        to_char(doc.doc_anno) AS anno_fattura,
        doc.doc_importo AS importo_totale_fattura,
        ronere.importo_imponibile,
        ivamov.ivamov_totale AS importo_iva,
        cig.codice_cig,
        cup.codice_cup,
        accertamento.movgest_anno AS anno_accertamento,
        accertamento.movgest_numero AS numero_accertamento,
        accertamento.movgest_subnumero AS numero_sub_accertamento,
        sub.subdoc_importo AS importo_rata_fattura,
        reversale.ord_numero AS numero_reversale,
        CASE
            WHEN to_char(reversale.ord_emissione_data, 'YYYY') = to_char(sub.data_creazione, 'YYYY') THEN reversale.importoreversale
            ELSE 0
        END AS importo_reversale_entro,
        CASE
            WHEN to_char(reversale.ord_emissione_data, 'YYYY') <> to_char(sub.data_creazione, 'YYYY') THEN reversale.importoreversale
            ELSE 0
        END AS importo_reversale_oltre,
        to_char(doc.doc_id) AS id,
        CASE
            WHEN stato.doc_stato_code = 'EM' THEN to_char(stato.data_creazione, 'YYYYMMDD')
            ELSE NULL
        END AS data_chiusura
    FROM siac_d_doc_tipo tipo,
        siac_d_doc_fam_tipo fam,
        siac_r_doc_sog rsog,
        siac_t_soggetto sog,
        siac_t_soc_partecipate part,
        siac_r_doc_stato rs,
        siac_d_doc_stato stato,
        siac_t_doc doc
    LEFT JOIN siac_d_pcc_ufficio ufficio ON doc.pccuff_id = ufficio.pccuff_id
    LEFT JOIN sac ON doc.doc_id = sac.doc_id
    LEFT JOIN siac_r_doc_onere ronere ON doc.doc_id = ronere.doc_id AND ronere.data_cancellazione IS NULL AND ronere.validita_fine IS NULL
    LEFT JOIN siac_r_doc_iva riva ON doc.doc_id = riva.doc_id AND riva.data_cancellazione IS NULL AND riva.validita_fine IS NULL
    LEFT JOIN siac_t_subdoc_iva subiva ON riva.dociva_r_id = subiva.dociva_r_id
    LEFT JOIN siac_r_ivamov rimavo ON subiva.subdociva_id = rimavo.subdociva_id AND rimavo.data_cancellazione IS NULL AND rimavo.validita_fine IS NULL
    LEFT JOIN siac_t_ivamov ivamov ON rimavo.ivamov_id = ivamov.ivamov_id
    LEFT JOIN siac_t_subdoc sub ON doc.doc_id = sub.doc_id AND sub.data_cancellazione IS NULL AND sub.validita_fine IS NULL
    LEFT JOIN cig ON sub.subdoc_id = cig.subdoc_id
    LEFT JOIN cup ON sub.subdoc_id = cup.subdoc_id
    LEFT JOIN accertamento ON sub.subdoc_id = accertamento.subdoc_id
    LEFT JOIN reversale ON sub.subdoc_id = reversale.subdoc_id
    WHERE doc.ente_proprietario_id = 2
    AND doc.doc_tipo_id = tipo.doc_tipo_id
    AND tipo.doc_fam_tipo_id = fam.doc_fam_tipo_id
    AND fam.doc_fam_tipo_code = 'E'
    AND rsog.doc_id = doc.doc_id
    AND sog.soggetto_id = rsog.soggetto_id
    AND sog.soggetto_code = part.codice
    AND part.anno::INTEGER = doc.doc_anno
    AND rs.doc_id = doc.doc_id
    AND rs.doc_stato_id = stato.doc_stato_id
    AND stato.doc_stato_code <> 'A'
    AND rsog.data_cancellazione IS NULL
    AND rsog.validita_fine IS NULL
    AND rs.data_cancellazione IS NULL
    AND rs.validita_fine IS NULL
WITH DATA;

CREATE OR REPLACE MATERIALIZED VIEW siac.v_simop_fatt_posdeb
AS WITH sac AS (
        SELECT r.doc_id,
            cl.classif_code AS codice_sac
        FROM siac_r_doc_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo_1
        WHERE r.ente_proprietario_id = 2
        AND r.classif_id = cl.classif_id
        AND cl.classif_tipo_id = tipo_1.classif_tipo_id
        AND tipo_1.classif_tipo_code IN ('CDC', 'CDR')
        AND r.data_cancellazione IS NULL
        AND r.validita_fine IS NULL
    ), cup AS (
        SELECT sub_1.subdoc_id,
            rattr.testo AS codice_cup
        FROM siac_t_subdoc sub_1,
            siac_t_doc doc_1,
            siac_t_attr attr,
            siac_r_subdoc_attr rattr
        WHERE sub_1.ente_proprietario_id = 2
        AND sub_1.doc_id = doc_1.doc_id
        AND rattr.subdoc_id = sub_1.subdoc_id
        AND rattr.testo IS NOT NULL
        AND rattr.testo <> ''
        AND attr.attr_id = rattr.attr_id
        AND attr.attr_code = 'cup'
        AND rattr.data_cancellazione IS NULL
        AND rattr.validita_fine IS NULL
    ), cig AS (
        SELECT sub_1.subdoc_id,
            rattr.testo AS codice_cig
        FROM siac_t_subdoc sub_1,
            siac_t_doc doc_1,
            siac_t_attr attr,
            siac_r_subdoc_attr rattr
        WHERE sub_1.ente_proprietario_id = 2
        AND sub_1.doc_id = doc_1.doc_id
        AND rattr.subdoc_id = sub_1.subdoc_id
        AND rattr.testo IS NOT NULL
        AND rattr.testo <> ''
        AND attr.attr_id = rattr.attr_id
        AND attr.attr_code = 'cig'
        AND rattr.data_cancellazione IS NULL
        AND rattr.validita_fine IS NULL
    ), impegno AS (
        SELECT rimp.subdoc_id,
            imp.movgest_anno,
            imp.movgest_numero,
            imp.movgest_subnumero
        FROM siac_r_subdoc_movgest_ts rimp,
            siac_v_bko_impegno_valido imp
        WHERE rimp.ente_proprietario_id = 2
        AND rimp.movgest_ts_id = imp.movgest_ts_id
        AND rimp.data_cancellazione IS NULL
        AND rimp.validita_fine IS NULL
    ), liquidazione AS (
        SELECT rsubliq.subdoc_id,
            liq.liq_anno,
            liq.liq_numero,
            liq.liq_importo
        FROM siac_r_subdoc_liquidazione rsubliq,
            siac_t_liquidazione liq
        WHERE rsubliq.ente_proprietario_id = 2
        AND rsubliq.liq_id = liq.liq_id
        AND rsubliq.data_cancellazione IS NULL
        AND rsubliq.validita_fine IS NULL
    ), mandato AS (
        SELECT rso.subdoc_id,
            mand.ord_anno,
            mand.ord_numero,
            mand.ord_emissione_data,
            det.ord_ts_det_importo AS importomandato
        FROM siac_t_ordinativo_ts_det det,
            siac_d_ordinativo_tipo tipo_1,
            siac_t_ordinativo mand,
            siac_t_ordinativo_ts ts,
            siac_r_subdoc_ordinativo_ts rso,
            siac_d_ordinativo_ts_det_tipo tipoimporto
        WHERE mand.ente_proprietario_id = 2
        AND mand.ord_tipo_id = tipo_1.ord_tipo_id
        AND tipo_1.ord_tipo_code = 'P'
        AND mand.ord_id = ts.ord_id
        AND ts.ord_ts_id = det.ord_ts_id
        AND det.ord_ts_det_tipo_id = tipoimporto.ord_ts_det_tipo_id
        AND tipoimporto.ord_ts_det_tipo_code = 'A'
        AND ts.ord_ts_id = rso.ord_ts_id
        AND rso.data_cancellazione IS NULL
        AND rso.validita_fine IS NULL
    )
    SELECT DISTINCT
        sog.soggetto_code AS codice_anagrafico_fornitore,
        sog.soggetto_desc AS nome_partecipata,
        sog.codice_fiscale AS codice_fiscale_partecipata,
        sog.partita_iva AS p_iva_partecipata,
        'RE' AS stato_documento,
        ufficio.pccuff_code AS ipa_struttura_capitolina,
        sac.codice_sac AS responsabile_procedura,
        doc.doc_sdi_lotto_siope AS identificativo_sdi,
        '' AS progressivo_invio_sdi,
        to_char(doc.doc_data_emissione, 'YYYYMMDD') AS data_ricezione_sdi,
        to_char(doc.data_creazione, 'YYYYMMDD') AS data_registrazione,
        tipo.doc_tipo_code AS tipo_documento,
        to_char(doc.doc_data_emissione, 'YYYYMMDD') AS data_fattura,
        doc.doc_numero AS n_fattura,
        to_char(doc.doc_anno) AS anno_fattura,
        doc.doc_importo AS importo_totale_fattura,
        ronere.importo_imponibile,
        ivamov.ivamov_totale AS importo_iva,
        sosp.subdoc_sosp_causale AS codice_sospensione,
        to_char(sosp.subdoc_sosp_data, 'YYYYMMDD') AS data_sospensione,
        cig.codice_cig,
        cup.codice_cup,
        impegno.movgest_anno AS anno_impegno,
        impegno.movgest_numero AS numero_impegno,
        impegno.movgest_subnumero AS numero_sub_impegno,
        sub.subdoc_importo AS importo_rata_fattura,
        CASE
            WHEN sosp.subdoc_sosp_data IS NOT NULL THEN 'CN'
            ELSE ''
        END AS codice_di_non_pagabilita,
        liquidazione.liq_anno || '/' || liquidazione.liq_numero AS numero_liquidazione,
        liquidazione.liq_importo AS importo_liquidato,
        CASE
            WHEN to_char(mandato.ord_emissione_data, 'YYYY') = to_char(sub.data_creazione, 'YYYY') THEN mandato.importomandato
            ELSE 0
        END AS importo_pagato_entro,
        CASE
            WHEN to_char(mandato.ord_emissione_data, 'YYYY') <> to_char(sub.data_creazione, 'YYYY') THEN mandato.importomandato
            ELSE 0
        END AS importo_pagato_oltre,
        mandato.ord_numero AS numero_mandato,
        to_char(doc.doc_id) AS id,
        CASE
            WHEN stato.doc_stato_code = 'EM' THEN to_char(stato.data_creazione, 'YYYYMMDD')
            ELSE NULL
        END AS data_chiusura
    FROM siac_d_doc_tipo tipo,
        siac_d_doc_fam_tipo fam,
        siac_r_doc_sog rsog,
        siac_t_soggetto sog,
        siac_t_soc_partecipate part,
        siac_r_doc_stato rs,
        siac_d_doc_stato stato,
        siac_t_doc doc
    LEFT JOIN siac_d_pcc_ufficio ufficio ON doc.pccuff_id = ufficio.pccuff_id
    LEFT JOIN sac ON doc.doc_id = sac.doc_id
    LEFT JOIN siac_r_doc_onere ronere ON doc.doc_id = ronere.doc_id AND ronere.data_cancellazione IS NULL AND ronere.validita_fine IS NULL
    LEFT JOIN siac_r_doc_iva riva ON doc.doc_id = riva.doc_id AND riva.data_cancellazione IS NULL AND riva.validita_fine IS NULL
    LEFT JOIN siac_t_subdoc_iva subiva ON riva.dociva_r_id = subiva.dociva_r_id
    LEFT JOIN siac_r_ivamov rimavo ON subiva.subdociva_id = rimavo.subdociva_id AND rimavo.data_cancellazione IS NULL AND rimavo.validita_fine IS NULL
    LEFT JOIN siac_t_ivamov ivamov ON rimavo.ivamov_id = ivamov.ivamov_id
    LEFT JOIN siac_t_subdoc sub ON doc.doc_id = sub.doc_id
    LEFT JOIN cig ON sub.subdoc_id = cig.subdoc_id
    LEFT JOIN cup ON sub.subdoc_id = cup.subdoc_id
    LEFT JOIN siac_t_subdoc_sospensione sosp ON sub.subdoc_id = sosp.subdoc_id
    LEFT JOIN impegno ON sub.subdoc_id = impegno.subdoc_id
    LEFT JOIN liquidazione ON sub.subdoc_id = liquidazione.subdoc_id
    LEFT JOIN mandato ON sub.subdoc_id = mandato.subdoc_id
    WHERE doc.ente_proprietario_id = 2
    AND doc.doc_tipo_id = tipo.doc_tipo_id
    AND tipo.doc_tipo_code <> 'FAT'
    AND tipo.doc_fam_tipo_id = fam.doc_fam_tipo_id
    AND fam.doc_fam_tipo_code = 'S'
    AND rsog.doc_id = doc.doc_id
    AND sog.soggetto_id = rsog.soggetto_id
    AND sog.soggetto_code = part.codice
    AND part.anno::integer = doc.doc_anno
    AND rs.doc_id = doc.doc_id
    AND rs.doc_stato_id = stato.doc_stato_id
    AND stato.doc_stato_code <> 'A'
    AND rsog.data_cancellazione IS NULL
    AND rsog.validita_fine IS NULL
    AND rs.data_cancellazione IS NULL
    AND rs.validita_fine IS NULL
WITH DATA;

CREATE OR REPLACE MATERIALIZED VIEW siac.v_simop_residui_attivi
AS WITH sac AS (
        SELECT r.movgest_ts_id,
            cl.classif_code AS codice_sac
        FROM siac_r_movgest_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo
        WHERE r.ente_proprietario_id = 2
        AND r.classif_id = cl.classif_id
        AND cl.classif_tipo_id = tipo.classif_tipo_id
        AND tipo.classif_tipo_code IN ('CDC', 'CDR')
        AND r.data_cancellazione IS NULL
        AND r.validita_fine IS NULL
    ), incassato AS (
        SELECT acc_1.movgest_anno,
            acc_1.movgest_numero,
            rev.ord_anno AS anno_emis,
            sum(importopag.ord_ts_det_importo) AS tot_pag
        FROM siac_r_ordinativo_ts_movgest_ts raccrev,
            siac_t_ordinativo rev,
            siac_r_ordinativo_stato rs,
            siac_d_ordinativo_stato stato,
            siac_d_ordinativo_tipo tipo,
            siac_t_ordinativo_ts ts,
            siac_t_ordinativo_ts_det importopag,
            siac_d_ordinativo_ts_det_tipo tipopag,
            siac_v_bko_accertamento_valido acc_1
        WHERE raccrev.movgest_ts_id = acc_1.movgest_ts_id
        AND raccrev.ord_ts_id = ts.ord_ts_id
        AND ts.ord_id = rev.ord_id
        AND rev.ord_tipo_id = tipo.ord_tipo_id
        AND rs.ord_id = rev.ord_id
        AND rs.ord_stato_id = stato.ord_stato_id
        AND stato.ord_stato_code <> 'A'
        AND tipo.ord_tipo_code = 'I'
        AND importopag.ord_ts_id = ts.ord_ts_id
        AND tipopag.ord_ts_det_tipo_id = importopag.ord_ts_det_tipo_id
        AND tipopag.ord_ts_det_tipo_code = 'A'
        AND raccrev.data_cancellazione IS NULL
        AND raccrev.validita_fine IS NULL
        AND rs.data_cancellazione IS NULL
        AND rs.validita_fine IS NULL
        GROUP BY acc_1.movgest_anno, acc_1.movgest_numero, rev.ord_anno
    )
    SELECT DISTINCT
        sog.soggetto_code AS codice_anagrafico_fornitore,
        sog.soggetto_desc AS nome_partecipata,
        sog.codice_fiscale AS codice_fiscale_partecipata,
        sog.partita_iva AS p_iva_partecipata,
        sac.codice_sac AS responsabile_procedura,
        acc.movgest_anno AS anno_accertamento,
        acc.movgest_numero AS numero_accertamento,
        acc.movgest_subnumero AS numero_subaccertamento,
        acc.movgest_desc AS descrizione_accertamento,
        importiimpiniz.movgest_ts_det_importo AS importo_origine_accertamento,
        importiimpatt.movgest_ts_det_importo AS importo_assestato_accert_3112,
        COALESCE(reversali_3112.tot_pag, 0::numeric) AS reversali_3112,
        importiimpatt.movgest_ts_det_importo - COALESCE(reversali_3112.tot_pag, 0::numeric) AS disponibilita_3112,
        importiimpatt.movgest_ts_det_importo AS assestato_accertamento_oggi,
        COALESCE(reversali_oltre_3112.tot_pag, 0::numeric) AS reversali_oltre_3112,
        to_char(acc.anno_bilancio) AS esercizio,
        ' ' AS mantenimento
    FROM siac_r_movgest_ts_sog rsog,
        siac_t_movgest_ts_det importiimpiniz,
        siac_d_movgest_ts_det_tipo tipoimportiiniz,
        siac_t_movgest_ts_det importiimpatt,
        siac_d_movgest_ts_det_tipo tipoimportiatt,
        siac_t_soggetto sog,
        siac_t_soc_partecipate part,
        siac_v_bko_accertamento_valido acc
    LEFT JOIN sac ON acc.movgest_ts_id = sac.movgest_ts_id
    LEFT JOIN incassato reversali_3112 ON acc.movgest_anno = reversali_3112.movgest_anno AND acc.movgest_numero = reversali_3112.movgest_numero AND acc.movgest_anno = reversali_3112.anno_emis
    LEFT JOIN incassato reversali_oltre_3112 ON acc.movgest_anno = reversali_oltre_3112.movgest_anno AND acc.movgest_numero = reversali_oltre_3112.movgest_numero AND acc.movgest_anno < reversali_oltre_3112.anno_emis
    WHERE rsog.movgest_ts_id = acc.movgest_ts_id
    AND rsog.soggetto_id = sog.soggetto_id
    AND sog.soggetto_code = part.codice
    AND part.anno::integer = acc.anno_bilancio
    AND importiimpiniz.movgest_ts_id = acc.movgest_ts_id
    AND importiimpiniz.movgest_ts_det_tipo_id = tipoimportiiniz.movgest_ts_det_tipo_id
    AND tipoimportiiniz.movgest_ts_det_tipo_code = 'I'
    AND importiimpatt.movgest_ts_id = acc.movgest_ts_id
    AND importiimpatt.movgest_ts_det_tipo_id = tipoimportiatt.movgest_ts_det_tipo_id
    AND tipoimportiatt.movgest_ts_det_tipo_code = 'A'
    AND rsog.data_cancellazione IS NULL
    AND rsog.validita_fine IS NULL
    AND acc.anno_bilancio = acc.movgest_anno
WITH DATA;

CREATE OR REPLACE MATERIALIZED VIEW siac.v_simop_residui_passivi
AS WITH sac AS (
        SELECT r.movgest_ts_id,
            cl.classif_code AS codice_sac
        FROM siac_r_movgest_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo
        WHERE r.ente_proprietario_id = 2
        AND r.classif_id = cl.classif_id
        AND cl.classif_tipo_id = tipo.classif_tipo_id
        AND tipo.classif_tipo_code IN ('CDC', 'CDR')
        AND r.data_cancellazione IS NULL
        AND r.validita_fine IS NULL
    ), liquidato AS (
        SELECT imp_1.movgest_anno,
            imp_1.movgest_numero,
            periodo.anno,
            liq.liq_anno AS anno_emis,
            sum(liq.liq_importo) AS tot_liq
        FROM siac_r_liquidazione_movgest rliqmov,
            siac_t_liquidazione liq,
            siac_r_liquidazione_stato rs,
            siac_d_liquidazione_stato stato,
            siac_t_bil bil,
            siac_t_periodo periodo,
            siac_v_bko_impegno_valido imp_1
        WHERE rliqmov.liq_id = liq.liq_id
        AND rliqmov.movgest_ts_id = imp_1.movgest_ts_id
        AND liq.bil_id = bil.bil_id
        AND bil.periodo_id = periodo.periodo_id
        AND periodo.anno::integer = liq.liq_anno
        AND rs.liq_id = liq.liq_id
        AND rs.liq_stato_id = stato.liq_stato_id
        AND stato.liq_stato_code <> 'A'
        AND rliqmov.data_cancellazione IS NULL
        AND rliqmov.validita_fine IS NULL
        AND rs.data_cancellazione IS NULL
        AND rs.validita_fine IS NULL
        GROUP BY imp_1.movgest_anno, imp_1.movgest_numero, periodo.anno, liq.liq_anno
    ), pagato AS (
        SELECT imp_1.movgest_anno,
            imp_1.movgest_numero,
            mand.ord_anno AS anno_emis,
            sum(importopag.ord_ts_det_importo) AS tot_pag
        FROM siac_r_liquidazione_movgest rliqmov,
            siac_t_liquidazione liq,
            siac_r_liquidazione_ord rliqord,
            siac_t_ordinativo mand,
            siac_d_ordinativo_tipo tipo,
            siac_t_ordinativo_ts ts,
            siac_t_ordinativo_ts_det importopag,
            siac_d_ordinativo_ts_det_tipo tipopag,
            siac_v_bko_impegno_valido imp_1
        WHERE rliqmov.liq_id = liq.liq_id
        AND rliqmov.movgest_ts_id = imp_1.movgest_ts_id
        AND rliqord.liq_id = liq.liq_id
        AND rliqord.sord_id = ts.ord_ts_id
        AND ts.ord_id = mand.ord_id
        AND mand.ord_tipo_id = tipo.ord_tipo_id
        AND tipo.ord_tipo_code = 'P'
        AND mand.ord_id = ts.ord_id
        AND importopag.ord_ts_id = ts.ord_ts_id
        AND tipopag.ord_ts_det_tipo_id = importopag.ord_ts_det_tipo_id
        AND tipopag.ord_ts_det_tipo_code = 'A'
        AND rliqmov.data_cancellazione IS NULL
        AND rliqmov.validita_fine IS NULL
        GROUP BY imp_1.movgest_anno, imp_1.movgest_numero, mand.ord_anno
    ), documenti AS (
        SELECT imp_1.anno_bilancio,
            imp_1.movgest_anno,
            imp_1.movgest_numero,
            sum(sub.subdoc_importo) AS tot_quote
        FROM siac_r_subdoc_movgest_ts r,
            siac_v_bko_impegno_valido imp_1,
            siac_t_subdoc sub,
            siac_t_doc doc
        WHERE imp_1.ente_proprietario_id = 2
        AND r.movgest_ts_id = imp_1.movgest_ts_id
        AND r.subdoc_id = sub.subdoc_id
        AND sub.doc_id = doc.doc_id
        AND sub.data_cancellazione IS NULL
        AND sub.validita_fine IS NULL
        AND r.data_cancellazione IS NULL
        AND r.validita_fine IS NULL
        GROUP BY imp_1.anno_bilancio, imp_1.movgest_anno, imp_1.movgest_numero
    )
    SELECT DISTINCT
        sog.soggetto_code AS codice_anagrafico_fornitore,
        sog.soggetto_desc AS nome_partecipata,
        sog.codice_fiscale AS codice_fiscale_partecipata,
        sog.partita_iva AS p_iva_partecipata,
        sac.codice_sac AS responsabile_procedura,
        imp.movgest_anno AS anno_impegno,
        imp.movgest_numero AS numero_impegno,
        imp.movgest_subnumero AS numero_sub_impegno,
        imp.movgest_desc AS descrizione_impegno,
        importiimpiniz.movgest_ts_det_importo AS importo_origine_impegno,
        importiimpatt.movgest_ts_det_importo AS importo_assestato_impegno_3112,
        COALESCE(liq_3112.tot_liq, 0::numeric) AS liquidato_3112,
        COALESCE(pagato_3112.tot_pag, 0::numeric) AS pagamenti_3112,
        importiimpatt.movgest_ts_det_importo - COALESCE(pagato_3112.tot_pag, 0::numeric) AS disponibilita_3112,
        COALESCE(rate_3112.tot_quote, 0::numeric) AS rate_3112,
        importiimpatt.movgest_ts_det_importo AS assestato_impegno_oggi,
        COALESCE(liq_oltre_3112.tot_liq, 0::numeric) AS liquidato_oltre_3112,
        COALESCE(pagato_oltre_3112.tot_pag, 0::numeric) AS pagamenti_oltre_3112,
        COALESCE(rate_oltre_3112.tot_quote, 0::numeric) AS rate_oltre_3112,
        to_char(imp.anno_bilancio) AS esercizio,
        ' ' AS mantenimento
    FROM siac_r_movgest_ts_sog rsog,
        siac_t_movgest_ts_det importiimpiniz,
        siac_d_movgest_ts_det_tipo tipoimportiiniz,
        siac_t_movgest_ts_det importiimpatt,
        siac_d_movgest_ts_det_tipo tipoimportiatt,
        siac_t_soggetto sog,
        siac_t_soc_partecipate part,
        siac_v_bko_impegno_valido imp
    LEFT JOIN sac ON imp.movgest_ts_id = sac.movgest_ts_id
    LEFT JOIN liquidato liq_3112 ON imp.movgest_anno = liq_3112.movgest_anno AND imp.movgest_numero = liq_3112.movgest_numero AND imp.movgest_anno = liq_3112.anno_emis AND imp.anno_bilancio = liq_3112.anno::integer
    LEFT JOIN liquidato liq_oltre_3112 ON imp.movgest_anno = liq_oltre_3112.movgest_anno AND imp.movgest_numero = liq_oltre_3112.movgest_numero AND imp.movgest_anno < liq_oltre_3112.anno_emis
    LEFT JOIN pagato pagato_3112 ON imp.movgest_anno = pagato_3112.movgest_anno AND imp.movgest_numero = pagato_3112.movgest_numero AND imp.movgest_anno = pagato_3112.anno_emis
    LEFT JOIN pagato pagato_oltre_3112 ON imp.movgest_anno = pagato_oltre_3112.movgest_anno AND imp.movgest_numero = pagato_oltre_3112.movgest_numero AND imp.movgest_anno < pagato_oltre_3112.anno_emis
    LEFT JOIN documenti rate_3112 ON imp.movgest_anno = rate_3112.movgest_anno AND imp.movgest_numero = rate_3112.movgest_numero AND imp.anno_bilancio = rate_3112.anno_bilancio
    LEFT JOIN documenti rate_oltre_3112 ON imp.movgest_anno = rate_oltre_3112.movgest_anno AND imp.movgest_numero = rate_oltre_3112.movgest_numero AND imp.anno_bilancio < rate_oltre_3112.anno_bilancio
    WHERE rsog.movgest_ts_id = imp.movgest_ts_id
    AND rsog.soggetto_id = sog.soggetto_id
    AND sog.soggetto_code = part.codice
    AND part.anno::integer = imp.anno_bilancio
    AND importiimpiniz.movgest_ts_id = imp.movgest_ts_id
    AND importiimpiniz.movgest_ts_det_tipo_id = tipoimportiiniz.movgest_ts_det_tipo_id
    AND tipoimportiiniz.movgest_ts_det_tipo_code = 'I'
    AND importiimpatt.movgest_ts_id = imp.movgest_ts_id
    AND importiimpatt.movgest_ts_det_tipo_id = tipoimportiatt.movgest_ts_det_tipo_id
    AND tipoimportiatt.movgest_ts_det_tipo_code = 'A'
    AND rsog.data_cancellazione IS NULL
    AND rsog.validita_fine IS NULL
    AND imp.anno_bilancio = imp.movgest_anno
WITH DATA;
