/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE VIEW siac.siac_v_dwh_pcc (
    ente_proprietario_id,
    importo_quietanza,
    numero_ordinativo,
    data_emissione_ordinativo,
    data_scadenza,
    data_registrazione,
    cod_esito,
    desc_esito,
    data_esito,
    cod_tipo_operazione,
    desc_tipo_operazione,
    cod_ufficio,
    desc_ufficio,
    cod_debito,
    desc_debito,
    cod_causale_pcc,
    desc_causale_pcc,
    validita_inizio,
    validita_fine,
    anno_doc,
    num_doc,
    data_emissione_doc,
    cod_tipo_doc,
    cod_sogg_doc,
    num_subdoc,
    doc_id)
AS
SELECT t_registro_pcc.ente_proprietario_id,
    t_registro_pcc.rpcc_quietanza_importo AS importo_quietanza,
    t_registro_pcc.ordinativo_numero AS numero_ordinativo,
    t_registro_pcc.ordinativo_data_emissione AS data_emissione_ordinativo,
    t_registro_pcc.data_scadenza,
    t_registro_pcc.rpcc_registrazione_data AS data_registrazione,
    t_registro_pcc.rpcc_esito_code AS cod_esito,
    t_registro_pcc.rpcc_esito_desc AS desc_esito,
    t_registro_pcc.rpcc_esito_data AS data_esito,
    d_pcc_oper_tipo.pccop_tipo_code AS cod_tipo_operazione,
    d_pcc_oper_tipo.pccop_tipo_desc AS desc_tipo_operazione,
    d_pcc_codice.pcccod_code AS cod_ufficio,
    d_pcc_codice.pcccod_desc AS desc_ufficio,
    d_pcc_debito_stato.pccdeb_stato_code AS cod_debito,
    d_pcc_debito_stato.pccdeb_stato_desc AS desc_debito,
    d_pcc_causale.pcccau_code AS cod_causale_pcc,
    d_pcc_causale.pcccau_desc AS desc_causale_pcc,
    t_registro_pcc.validita_inizio, t_registro_pcc.validita_fine,
    t_doc.doc_anno AS anno_doc, t_doc.doc_numero AS num_doc,
    t_doc.doc_data_emissione AS data_emissione_doc,
    d_doc_tipo.doc_tipo_code AS cod_tipo_doc,
    t_soggetto.soggetto_code AS cod_sogg_doc,
    t_subdoc.subdoc_numero AS num_subdoc,
    t_doc.doc_id
FROM siac_t_registro_pcc t_registro_pcc
INNER JOIN siac_d_pcc_operazione_tipo d_pcc_oper_tipo ON d_pcc_oper_tipo.pccop_tipo_id = t_registro_pcc.pccop_tipo_id
INNER JOIN siac_t_doc t_doc ON t_doc.doc_id = t_registro_pcc.doc_id
INNER JOIN siac_d_pcc_codice d_pcc_codice ON d_pcc_codice.pcccod_id = t_doc.pcccod_id
INNER JOIN siac_t_subdoc t_subdoc ON t_subdoc.subdoc_id = t_registro_pcc.subdoc_id
INNER JOIN siac_d_doc_tipo d_doc_tipo ON d_doc_tipo.doc_tipo_id = t_doc.doc_tipo_id
LEFT JOIN siac_d_pcc_debito_stato d_pcc_debito_stato ON d_pcc_debito_stato.pccdeb_stato_id = t_registro_pcc.pccdeb_stato_id AND d_pcc_debito_stato.data_cancellazione IS NULL
LEFT JOIN siac_d_pcc_causale d_pcc_causale ON d_pcc_causale.pcccau_id = t_registro_pcc.pcccau_id AND d_pcc_causale.data_cancellazione IS NULL
LEFT JOIN siac_r_doc_sog r_doc_sog ON r_doc_sog.doc_id = t_doc.doc_id AND r_doc_sog.data_cancellazione IS NULL
LEFT JOIN siac_t_soggetto t_soggetto ON t_soggetto.soggetto_id = r_doc_sog.soggetto_id AND t_soggetto.data_cancellazione IS NULL
WHERE
--SIAC-6100
--d_pcc_oper_tipo.pccop_tipo_code::text = 'CP'::text AND
t_registro_pcc.data_cancellazione IS NULL
AND d_pcc_codice.data_cancellazione IS NULL
AND d_pcc_oper_tipo.data_cancellazione IS NULL
AND t_doc.data_cancellazione IS NULL
AND t_subdoc.data_cancellazione IS NULL
AND d_doc_tipo.data_cancellazione IS NULL;