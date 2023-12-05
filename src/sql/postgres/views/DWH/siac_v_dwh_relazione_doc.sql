/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_relazione_doc (
    ente_proprietario_id,
    cod_tipo_relazione,
    desc_tipo_relazione,
    anno_doc_a,
    doc_numero_a,
    desc_doc_a,
    importo_doc_a,
    beneficiario_multiplo_doc_a,
    data_emissione_doc_a,
    data_scadenza_doc_a,
    cod_tipo_doc_a,
    desc_tipo_doc_a,
    cod_famiglia_doc_a,
    desc_famiglia_doc_a,
    cod_stato_doc_a,
    desc_stato_cod_a,
    cod_soggetto_a,
    desc_soggetto_a,
    anno_doc_b,
    doc_numero_b,
    desc_doc_b,
    importo_doc_b,
    beneficiario_multiplo_doc_b,
    data_emissione_doc_b,
    data_scadenza_doc_b,
    cod_tipo_doc_b,
    desc_tipo_doc_b,
    cod_famiglia_doc_b,
    desc_famiglia_doc_b,
    cod_stato_doc_b,
    desc_stato_cod_b,
    cod_soggetto_b,
    desc_soggett_b,
    importo_relazione_doc,
    doc_id_a,
    doc_id_b)
AS
SELECT rd.ente_proprietario_id, drt.relaz_tipo_code AS cod_tipo_relazione,
    drt.relaz_tipo_desc AS desc_tipo_relazione, td1.doc_anno AS anno_doc_a,
    td1.doc_numero AS doc_numero_a, td1.doc_desc AS desc_doc_a,
    td1.doc_importo AS importo_doc_a,
    td1.doc_beneficiariomult AS beneficiario_multiplo_doc_a,
    td1.doc_data_emissione AS data_emissione_doc_a,
    td1.doc_data_scadenza AS data_scadenza_doc_a,
    ddt1.doc_tipo_code AS cod_tipo_doc_a, ddt1.doc_tipo_desc AS desc_tipo_doc_a,
    dft1.doc_fam_tipo_code AS cod_famiglia_doc_a,
    dft1.doc_fam_tipo_desc AS desc_famiglia_doc_a,
    dds1.doc_stato_code AS cod_stato_doc_a,
    dds1.doc_stato_desc AS desc_stato_cod_a,
    ts1.soggetto_code AS cod_soggetto_a, ts1.soggetto_desc AS desc_soggetto_a,
    td2.doc_anno AS anno_doc_b, td2.doc_numero AS doc_numero_b,
    td2.doc_desc AS desc_doc_b, td2.doc_importo AS importo_doc_b,
    td2.doc_beneficiariomult AS beneficiario_multiplo_doc_b,
    td2.doc_data_emissione AS data_emissione_doc_b,
    td2.doc_data_scadenza AS data_scadenza_doc_b,
    ddt2.doc_tipo_code AS cod_tipo_doc_b, ddt2.doc_tipo_desc AS desc_tipo_doc_b,
    dft2.doc_fam_tipo_code AS cod_famiglia_doc_b,
    dft2.doc_fam_tipo_desc AS desc_famiglia_doc_b,
    dds2.doc_stato_code AS cod_stato_doc_b,
    dds2.doc_stato_desc AS desc_stato_cod_b,
    ts2.soggetto_code AS cod_soggetto_b, ts2.soggetto_desc AS desc_soggett_b,
    rd.doc_importo_da_dedurre AS importo_relazione_doc,
    td1.doc_id AS doc_id_a, td2.doc_id AS doc_id_b
FROM siac_r_doc rd
   JOIN siac_t_doc td1 ON td1.doc_id = rd.doc_id_da
   JOIN siac_t_doc td2 ON td2.doc_id = rd.doc_id_a
   JOIN siac_d_relaz_tipo drt ON drt.relaz_tipo_id = rd.relaz_tipo_id
   LEFT JOIN siac_d_doc_tipo ddt1 ON ddt1.doc_tipo_id = td1.doc_tipo_id AND
       ddt1.data_cancellazione IS NULL
   LEFT JOIN siac_d_doc_tipo ddt2 ON ddt2.doc_tipo_id = td2.doc_tipo_id AND
       ddt2.data_cancellazione IS NULL
   LEFT JOIN siac_d_doc_fam_tipo dft1 ON dft1.doc_fam_tipo_id =
       ddt1.doc_fam_tipo_id AND dft1.data_cancellazione IS NULL
   LEFT JOIN siac_d_doc_fam_tipo dft2 ON dft2.doc_fam_tipo_id =
       ddt2.doc_fam_tipo_id AND dft2.data_cancellazione IS NULL
   JOIN siac_r_doc_stato rds1 ON rds1.doc_id = rd.doc_id_da
   JOIN siac_r_doc_stato rds2 ON rds2.doc_id = rd.doc_id_a
   JOIN siac_d_doc_stato dds1 ON dds1.doc_stato_id = rds1.doc_stato_id
   JOIN siac_d_doc_stato dds2 ON dds2.doc_stato_id = rds2.doc_stato_id
   JOIN siac_r_doc_sog srds1 ON srds1.doc_id = rd.doc_id_da
   JOIN siac_r_doc_sog srds2 ON srds2.doc_id = rd.doc_id_a
   JOIN siac_t_soggetto ts1 ON ts1.soggetto_id = srds1.soggetto_id
   JOIN siac_t_soggetto ts2 ON ts2.soggetto_id = srds2.soggetto_id
WHERE rd.data_cancellazione IS NULL AND td1.data_cancellazione IS NULL AND
    td2.data_cancellazione IS NULL AND drt.data_cancellazione IS NULL AND rds1.data_cancellazione IS NULL AND rds2.data_cancellazione IS NULL AND dds1.data_cancellazione IS NULL AND dds2.data_cancellazione IS NULL AND srds1.data_cancellazione IS NULL AND srds2.data_cancellazione IS NULL AND ts1.data_cancellazione IS NULL AND ts2.data_cancellazione IS NULL;
