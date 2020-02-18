/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_provvisori_cassa_doc (
    ente_proprietario_id,
    provc_tipo_code,
    provc_tipo_desc,
    provc_anno,
    provc_numero,
    fam_doc,
    tipo_doc,
    anno_doc,
    numero_doc,
    sogg_doc,
    subdoc_numero,
    importo_reg,
    data_emissione_doc,
    doc_id)
AS
SELECT a.ente_proprietario_id, b.provc_tipo_code, b.provc_tipo_desc,
    a.provc_anno, a.provc_numero, i.doc_fam_tipo_code AS fam_doc,
    h.doc_tipo_code AS tipo_doc, e.doc_anno AS anno_doc,
    e.doc_numero AS numero_doc, g.soggetto_code AS sogg_doc, d.subdoc_numero,
    d.subdoc_importo AS importo_reg, e.doc_data_emissione AS data_emissione_doc,
    e.doc_id
FROM siac_t_prov_cassa a, siac_d_prov_cassa_tipo b,
    siac_r_subdoc_prov_cassa c, siac_t_subdoc d, siac_t_doc e, siac_r_doc_sog f,
    siac_t_soggetto g, siac_d_doc_tipo h, siac_d_doc_fam_tipo i
WHERE a.provc_tipo_id = b.provc_tipo_id AND c.provc_id = a.provc_id AND
    d.subdoc_id = c.subdoc_id AND d.doc_id = e.doc_id AND e.doc_id = f.doc_id AND f.soggetto_id = g.soggetto_id AND e.doc_tipo_id = h.doc_tipo_id AND i.doc_fam_tipo_id = h.doc_fam_tipo_id AND a.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND f.data_cancellazione IS NULL
ORDER BY a.ente_proprietario_id;