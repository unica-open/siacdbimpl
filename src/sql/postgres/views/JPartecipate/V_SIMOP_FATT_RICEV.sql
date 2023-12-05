<<<<<<< HEAD
-- siac.v_simop_fatt_ricev source
drop MATERIALIZED VIEW siac.v_simop_fatt_ricev;


CREATE MATERIALIZED VIEW siac.v_simop_fatt_ricev
TABLESPACE pg_default
AS WITH sac AS (
         SELECT r.doc_id,
            cl.classif_code AS codice_sac
           FROM siac_r_doc_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo_1
          WHERE r.ente_proprietario_id = 2 AND r.classif_id = cl.classif_id AND cl.classif_tipo_id = tipo_1.classif_tipo_id AND (tipo_1.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])) AND r.data_cancellazione IS NULL AND r.validita_fine IS NULL
        ), onere AS (
         SELECT ronere.doc_id,
            sum(ronere.importo_imponibile) AS importo_imponibile
           FROM siac_r_doc_onere ronere
          WHERE ronere.ente_proprietario_id = 2 AND ronere.data_cancellazione IS NULL AND ronere.validita_fine IS NULL
          GROUP BY ronere.doc_id
        ), docarrot AS (
         SELECT r.doc_id,
            r.numerico AS importo_arrotondato
           FROM siac_r_doc_attr r,
            siac_t_attr sta
          WHERE r.attr_id = sta.attr_id AND sta.attr_code::text = 'arrotondamento'::text AND r.data_cancellazione IS NULL AND r.validita_fine IS NULL
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
        ), impegno AS (
         SELECT rimp.subdoc_id,
            imp.movgest_anno,
            imp.movgest_numero,
            imp.movgest_subnumero
           FROM siac_r_subdoc_movgest_ts rimp,
            siac_v_bko_impegno_valido imp
          WHERE rimp.ente_proprietario_id = 2 AND rimp.movgest_ts_id = imp.movgest_ts_id AND rimp.data_cancellazione IS NULL AND rimp.validita_fine IS NULL
        ), liquidazione AS (
         SELECT rsubliq.subdoc_id,
            liq.liq_anno,
            liq.liq_numero,
            liq.liq_importo
           FROM siac_r_subdoc_liquidazione rsubliq,
            siac_t_liquidazione liq
          WHERE rsubliq.ente_proprietario_id = 2 AND rsubliq.liq_id = liq.liq_id AND rsubliq.data_cancellazione IS NULL AND rsubliq.validita_fine IS NULL
        ), mandato AS (
         SELECT rso.subdoc_id,
=======
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
>>>>>>> b6cd016698b41511d3809c9b78b6885975325fa1
            mand.ord_anno,
            mand.ord_numero,
            mand.ord_emissione_data,
            det.ord_ts_det_importo AS importomandato
<<<<<<< HEAD
           FROM siac_t_ordinativo_ts_det det,
            siac_d_ordinativo_tipo tipo_1,
            siac_t_ordinativo mand,
            siac_r_ordinativo_stato rsmand,
            siac_d_ordinativo_stato stmand,
            siac_t_ordinativo_ts ts,
            siac_r_subdoc_ordinativo_ts rso,
            siac_d_ordinativo_ts_det_tipo tipoimporto
          WHERE mand.ente_proprietario_id = 2 AND mand.ord_tipo_id = tipo_1.ord_tipo_id AND tipo_1.ord_tipo_code::text = 'P'::text AND mand.ord_id = ts.ord_id AND ts.ord_ts_id = det.ord_ts_id AND det.ord_ts_det_tipo_id = tipoimporto.ord_ts_det_tipo_id AND tipoimporto.ord_ts_det_tipo_code::text = 'A'::text AND mand.ord_id = rsmand.ord_id AND rsmand.ord_stato_id = stmand.ord_stato_id AND stmand.ord_stato_code::text <> 'A'::text AND ts.ord_ts_id = rso.ord_ts_id AND rso.data_cancellazione IS NULL AND rso.validita_fine IS NULL AND rsmand.data_cancellazione IS NULL AND rsmand.validita_fine IS NULL
        ), pagatototale AS (
         SELECT documento.doc_id,
            sum(det.ord_ts_det_importo) AS totalepagatodoc
           FROM siac_t_ordinativo_ts_det det,
            siac_d_ordinativo_tipo tipo_1,
            siac_t_ordinativo mand,
            siac_r_ordinativo_stato rsmand,
            siac_d_ordinativo_stato stmand,
            siac_t_ordinativo_ts ts,
            siac_r_subdoc_ordinativo_ts rso,
            siac_d_ordinativo_ts_det_tipo tipoimporto,
            siac_t_subdoc quota,
            siac_t_doc documento
          WHERE mand.ente_proprietario_id = 2 AND mand.ord_tipo_id = tipo_1.ord_tipo_id AND tipo_1.ord_tipo_code::text = 'P'::text AND mand.ord_id = ts.ord_id AND ts.ord_ts_id = det.ord_ts_id AND det.ord_ts_det_tipo_id = tipoimporto.ord_ts_det_tipo_id AND tipoimporto.ord_ts_det_tipo_code::text = 'A'::text AND mand.ord_id = rsmand.ord_id AND rsmand.ord_stato_id = stmand.ord_stato_id AND stmand.ord_stato_code::text <> 'A'::text AND ts.ord_ts_id = rso.ord_ts_id AND rso.subdoc_id = quota.subdoc_id AND quota.doc_id = documento.doc_id AND mand.ord_anno = documento.doc_anno AND rso.data_cancellazione IS NULL AND rso.validita_fine IS NULL AND rsmand.data_cancellazione IS NULL AND rsmand.validita_fine IS NULL AND quota.data_cancellazione IS NULL
          GROUP BY documento.doc_id
        ), docstorno AS (
         SELECT doc.doc_id,
            sum(rdoc.doc_importo_da_dedurre) AS importostornato
           FROM siac_r_doc rdoc,
            siac_t_doc doc
          WHERE doc.doc_id = rdoc.doc_id_da AND rdoc.data_cancellazione IS NULL AND rdoc.validita_fine IS NULL
          GROUP BY doc.doc_id
        ), docpagato AS (
         SELECT doc.doc_id,
            to_date(rattr.testo::text, 'DD/Mm/YYYY'::text) AS datapagdoc
           FROM siac_t_attr attr,
            siac_r_doc_attr rattr,
            siac_t_doc doc
          WHERE attr.ente_proprietario_id = 2 AND attr.attr_code::text = 'dataOperazionePagamentoIncasso'::text AND rattr.attr_id = attr.attr_id AND rattr.doc_id = doc.doc_id AND rattr.data_cancellazione IS NULL
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
    doc.doc_anno::character varying AS anno_fattura,
    doc.doc_importo AS importo_totale_fattura,
    onere.importo_imponibile,
    ivamov.ivamov_totale AS importo_iva,
    sosp.subdoc_sosp_causale AS codice_sospensione,
    to_char(sosp.subdoc_sosp_data, 'YYYYMMDD'::text) AS data_sospensione,
    cig.codice_cig,
    cup.codice_cup,
    impegno.movgest_anno AS anno_impegno,
    impegno.movgest_numero AS numero_impegno,
    impegno.movgest_subnumero AS numero_sub_impegno,
    sub.subdoc_importo AS importo_rata_fattura,
        CASE
            WHEN sosp.subdoc_sosp_data <> NULL::timestamp without time zone THEN 'CN'::text
            ELSE ''::text
        END AS codice_di_non_pagabilita,
    (liquidazione.liq_anno || '/'::text) || liquidazione.liq_numero AS numero_liquidazione,
    liquidazione.liq_importo AS importo_liquidato,
        CASE
            WHEN mandato.ord_anno = doc.doc_anno THEN mandato.importomandato
            ELSE 0::numeric
        END AS importo_pagato_entro,
        CASE
            WHEN mandato.ord_anno <> doc.doc_anno THEN mandato.importomandato
            ELSE 0::numeric
        END AS importo_pagato_oltre,
    (mandato.ord_anno || '/'::text) || mandato.ord_numero AS numero_mandato,
    to_char(doc.doc_id) AS id,
        CASE
            WHEN stato.doc_stato_code::text = ANY (ARRAY['EM'::character varying, 'ST'::character varying]::text[]) THEN to_char(rs.data_creazione, 'YYYYMMDD'::text)
            ELSE NULL::text
        END AS data_chiusura,
    COALESCE(pagatototale.totalepagatodoc, 0::numeric) AS totalepagatodoc,
    COALESCE(docstorno.importostornato, 0::numeric) AS importostornato,
    stato.doc_stato_code AS statodocpag,
    docpagato.datapagdoc,
    rs.data_creazione AS datastatoemesso,
    1 AS tipo_estr
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
     LEFT JOIN onere ON doc.doc_id = onere.doc_id
     LEFT JOIN docarrot ON doc.doc_id = docarrot.doc_id
     LEFT JOIN siac_r_doc_iva riva ON doc.doc_id = riva.doc_id AND riva.data_cancellazione IS NULL AND riva.validita_fine IS NULL
     LEFT JOIN siac_t_subdoc_iva subiva ON riva.dociva_r_id = subiva.dociva_r_id
     LEFT JOIN siac_r_ivamov rimavo ON subiva.subdociva_id = rimavo.subdociva_id AND rimavo.data_cancellazione IS NULL AND rimavo.validita_fine IS NULL
     LEFT JOIN siac_t_ivamov ivamov ON rimavo.ivamov_id = ivamov.ivamov_id
     LEFT JOIN siac_t_subdoc sub ON doc.doc_id = sub.doc_id AND sub.data_cancellazione IS NULL AND sub.validita_fine IS NULL
     LEFT JOIN cig ON sub.subdoc_id = cig.subdoc_id
     LEFT JOIN cup ON sub.subdoc_id = cup.subdoc_id
     LEFT JOIN siac_t_subdoc_sospensione sosp ON sub.subdoc_id = sosp.subdoc_id AND sosp.data_cancellazione IS NULL AND sosp.validita_fine IS NULL
     LEFT JOIN impegno ON sub.subdoc_id = impegno.subdoc_id
     LEFT JOIN liquidazione ON sub.subdoc_id = liquidazione.subdoc_id
     LEFT JOIN mandato ON sub.subdoc_id = mandato.subdoc_id
     LEFT JOIN pagatototale ON doc.doc_id = pagatototale.doc_id
     LEFT JOIN docstorno ON doc.doc_id = docstorno.doc_id
     LEFT JOIN docpagato ON doc.doc_id = docpagato.doc_id
  WHERE doc.ente_proprietario_id = 2 AND doc.doc_tipo_id = tipo.doc_tipo_id AND (tipo.doc_tipo_code::text = ANY (ARRAY['FAT'::character varying, 'NTE'::character varying]::text[])) AND tipo.doc_fam_tipo_id = fam.doc_fam_tipo_id AND fam.doc_fam_tipo_code::text = 'S'::text AND rsog.doc_id = doc.doc_id AND sog.soggetto_id = rsog.soggetto_id AND sog.soggetto_code::text = part.codice::text AND part.anno::integer = doc.doc_anno AND rs.doc_id = doc.doc_id AND rs.doc_stato_id = stato.doc_stato_id AND ((stato.doc_stato_code::text <> ALL (ARRAY['A'::character varying, 'EM'::character varying]::text[])) OR stato.doc_stato_code::text = 'EM'::text AND to_char(COALESCE(docpagato.datapagdoc, to_date(doc.doc_anno::character varying::text, 'DD/Mm/YYYY'::text))::timestamp with time zone, 'YYYY'::text) <> doc.doc_anno::character varying::text) AND (round(doc.doc_importo, 2) + round(docarrot.importo_arrotondato, 2)) <> round(COALESCE(pagatototale.totalepagatodoc, 0::numeric) + COALESCE(docstorno.importostornato, 0::numeric), 2) AND rsog.data_cancellazione IS NULL AND rsog.validita_fine IS NULL AND rs.data_cancellazione IS NULL AND rs.validita_fine IS NULL AND doc.data_cancellazione IS NULL AND doc.validita_fine IS NULL
UNION
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
    doc.doc_anno::character varying AS anno_fattura,
    doc.doc_importo AS importo_totale_fattura,
    onere.importo_imponibile,
    ivamov.ivamov_totale AS importo_iva,
    ''::text AS codice_sospensione,
    ''::text AS data_sospensione,
    ''::text AS codice_cig,
    ''::text AS codice_cup,
    0 AS anno_impegno,
    0 AS numero_impegno,
    0 AS numero_sub_impegno,
    rdoc.doc_importo_da_dedurre AS importo_rata_fattura,
    'NCD'::text AS codice_di_non_pagabilita,
    ''::text AS numero_liquidazione,
    0 AS importo_liquidato,
    0 AS importo_pagato_entro,
    0 AS importo_pagato_oltre,
    ''::text AS numero_mandato,
    to_char(doc.doc_id) AS id,
    NULL::text AS data_chiusura,
    0 AS totalepagatodoc,
    COALESCE(docstorno.importostornato, 0::numeric) AS importostornato,
    stato.doc_stato_code AS statodocpag,
    docpagato.datapagdoc,
    rs.data_creazione AS datastatoemesso,
    2 AS tipo_estr
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
     LEFT JOIN onere ON doc.doc_id = onere.doc_id
     LEFT JOIN docarrot ON doc.doc_id = docarrot.doc_id
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
     LEFT JOIN pagatototale ON doc.doc_id = pagatototale.doc_id
     LEFT JOIN docstorno ON doc.doc_id = docstorno.doc_id
     JOIN siac_r_doc rdoc ON doc.doc_id = rdoc.doc_id_da AND rdoc.data_cancellazione IS NULL AND rdoc.validita_fine IS NULL
     LEFT JOIN docpagato ON doc.doc_id = docpagato.doc_id
  WHERE doc.ente_proprietario_id = 2 AND doc.doc_tipo_id = tipo.doc_tipo_id AND (tipo.doc_tipo_code::text = ANY (ARRAY['FAT'::character varying, 'NTE'::character varying]::text[])) AND tipo.doc_fam_tipo_id = fam.doc_fam_tipo_id AND fam.doc_fam_tipo_code::text = 'S'::text AND rsog.doc_id = doc.doc_id AND sog.soggetto_id = rsog.soggetto_id AND sog.soggetto_code::text = part.codice::text AND part.anno::integer = doc.doc_anno AND rs.doc_id = doc.doc_id AND rs.doc_stato_id = stato.doc_stato_id AND stato.doc_stato_code::text <> 'A'::text AND ((stato.doc_stato_code::text <> ALL (ARRAY['A'::character varying, 'EM'::character varying]::text[])) OR stato.doc_stato_code::text = 'EM'::text AND to_char(docpagato.datapagdoc::timestamp with time zone, 'YYYY'::text) <> doc.doc_anno::character varying::text) AND (round(doc.doc_importo, 2) + round(docarrot.importo_arrotondato, 2)) <> round(COALESCE(pagatototale.totalepagatodoc, 0::numeric) + COALESCE(docstorno.importostornato, 0::numeric), 2) AND rsog.data_cancellazione IS NULL AND rsog.validita_fine IS NULL AND rs.data_cancellazione IS NULL AND rs.validita_fine IS NULL AND doc.data_cancellazione IS NULL AND doc.validita_fine IS NULL
WITH DATA;
=======
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
>>>>>>> b6cd016698b41511d3809c9b78b6885975325fa1
