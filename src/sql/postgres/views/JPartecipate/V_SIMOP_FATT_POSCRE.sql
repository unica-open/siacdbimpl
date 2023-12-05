<<<<<<< HEAD
-- siac.v_simop_fatt_poscre source
drop MATERIALIZED VIEW siac.v_simop_fatt_poscre;


CREATE MATERIALIZED VIEW siac.v_simop_fatt_poscre
TABLESPACE pg_default
AS WITH sac AS (
         SELECT r.doc_id,
            cl.classif_code AS codice_sac
           FROM siac_r_doc_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo_1
          WHERE r.ente_proprietario_id = 2 AND r.classif_id = cl.classif_id AND cl.classif_tipo_id = tipo_1.classif_tipo_id AND (tipo_1.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])) AND r.data_cancellazione IS NULL AND r.validita_fine IS NULL
        ), cup AS (
         SELECT sub_1.subdoc_id,
            rattr.testo AS codice_cup
           FROM siac_t_subdoc sub_1,
            siac_t_doc doc_1,
            siac_t_attr attr,
            siac_r_subdoc_attr rattr
          WHERE sub_1.ente_proprietario_id = 2 AND sub_1.doc_id = doc_1.doc_id AND rattr.subdoc_id = sub_1.subdoc_id AND rattr.testo IS NOT NULL AND rattr.testo::text <> ''::text AND attr.attr_id = rattr.attr_id AND attr.attr_code::text = 'cup'::text AND rattr.data_cancellazione IS NULL AND rattr.validita_fine IS NULL
        ), cig AS (
         SELECT sub_1.subdoc_id,
            rattr.testo AS codice_cig
           FROM siac_t_subdoc sub_1,
            siac_t_doc doc_1,
            siac_t_attr attr,
            siac_r_subdoc_attr rattr
          WHERE sub_1.ente_proprietario_id = 2 AND sub_1.doc_id = doc_1.doc_id AND rattr.subdoc_id = sub_1.subdoc_id AND rattr.testo IS NOT NULL AND rattr.testo::text <> ''::text AND attr.attr_id = rattr.attr_id AND attr.attr_code::text = 'cig'::text AND rattr.data_cancellazione IS NULL AND rattr.validita_fine IS NULL
        ), accertamento AS (
         SELECT rimp.subdoc_id,
            imp.movgest_anno,
            imp.movgest_numero,
            imp.movgest_subnumero
           FROM siac_r_subdoc_movgest_ts rimp,
            siac_v_bko_accertamento_valido imp
          WHERE rimp.ente_proprietario_id = 2 AND rimp.movgest_ts_id = imp.movgest_ts_id AND rimp.data_cancellazione IS NULL AND rimp.validita_fine IS NULL
        ), reversale AS (
         SELECT rso.subdoc_id,
=======
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
>>>>>>> b6cd016698b41511d3809c9b78b6885975325fa1
            rev.ord_anno,
            rev.ord_numero,
            rev.ord_emissione_data,
            det.ord_ts_det_importo AS importoreversale
<<<<<<< HEAD
           FROM siac_t_ordinativo_ts_det det,
=======
        FROM siac_t_ordinativo_ts_det det,
>>>>>>> b6cd016698b41511d3809c9b78b6885975325fa1
            siac_d_ordinativo_tipo tipo_1,
            siac_t_ordinativo rev,
            siac_t_ordinativo_ts ts,
            siac_r_subdoc_ordinativo_ts rso,
            siac_d_ordinativo_ts_det_tipo tipoimporto
<<<<<<< HEAD
          WHERE rev.ente_proprietario_id = 2 AND rev.ord_tipo_id = tipo_1.ord_tipo_id AND tipo_1.ord_tipo_code::text = 'I'::text AND rev.ord_id = ts.ord_id AND ts.ord_ts_id = det.ord_ts_id AND det.ord_ts_det_tipo_id = tipoimporto.ord_ts_det_tipo_id AND tipoimporto.ord_ts_det_tipo_code::text = 'A'::text AND ts.ord_ts_id = rso.ord_ts_id AND rso.data_cancellazione IS NULL AND rso.validita_fine IS NULL
        )
 SELECT DISTINCT sog.soggetto_code AS codice_anagrafico_fornitore,
    sog.soggetto_desc AS nome_partecipata,
    sog.codice_fiscale::character varying(16) AS codice_fiscale_partecipata,
    sog.partita_iva AS p_iva_partecipata,
    'RE'::text AS stato_documento,
    ufficio.pccuff_code AS ipa_struttura_capitolina,
    sac.codice_sac AS responsabile_procedura,
    doc.doc_sdi_lotto_siope AS identificativo_sdi,
    ''::text AS progressivo_invio_sdi,
    to_char(doc.doc_data_emissione, 'YYYYMMDD'::text) AS data_ricezione_sdi,
    to_char(doc.data_creazione, 'YYYYMMDD'::text) AS data_registrazione,
    tipo.doc_tipo_code AS tipo_documento,
    to_char(doc.doc_data_emissione, 'YYYYMMDD'::text) AS data_fattura,
    doc.doc_numero AS n_fattura,
    to_char(doc.doc_anno) AS anno_fattura,
    doc.doc_importo AS importo_totale_fattura,
    ivamov.ivamov_imponibile AS importo_imponibile,
    ivamov.ivamov_imposta AS importo_iva,
    cig.codice_cig,
    cup.codice_cup,
    accertamento.movgest_anno AS anno_accertamento,
    accertamento.movgest_numero AS numero_accertamento,
    accertamento.movgest_subnumero AS numero_sub_accertamento,
    sub.subdoc_importo AS importo_rata_fattura,
    reversale.ord_numero AS numero_reversale,
        CASE
            WHEN reversale.ord_anno = doc.doc_anno THEN reversale.importoreversale
            ELSE 0::numeric
        END AS importo_reversale_entro,
        CASE
            WHEN reversale.ord_anno <> doc.doc_anno THEN reversale.importoreversale
            ELSE 0::numeric
        END AS importo_reversale_oltre,
    to_char(doc.doc_id) AS id,
        CASE
            WHEN reversale.ord_emissione_data IS NOT NULL THEN to_char(reversale.ord_emissione_data, 'YYYYMMDD'::text)
            ELSE NULL::text
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
  WHERE doc.ente_proprietario_id = 2 AND doc.doc_tipo_id = tipo.doc_tipo_id AND tipo.doc_fam_tipo_id = fam.doc_fam_tipo_id AND fam.doc_fam_tipo_code::text = 'E'::text AND rsog.doc_id = doc.doc_id AND sog.soggetto_id = rsog.soggetto_id AND sog.soggetto_code::text = part.codice::text AND part.anno::integer = doc.doc_anno AND rs.doc_id = doc.doc_id AND rs.doc_stato_id = stato.doc_stato_id AND stato.doc_stato_code::text <> 'A'::text AND rsog.data_cancellazione IS NULL AND rsog.validita_fine IS NULL AND rs.data_cancellazione IS NULL AND rs.validita_fine IS NULL
WITH DATA;
=======
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
>>>>>>> b6cd016698b41511d3809c9b78b6885975325fa1
