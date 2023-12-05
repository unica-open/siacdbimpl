/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop VIEW siac.siac_v_dwh_fattura_sirfel

CREATE OR REPLACE VIEW siac_v_dwh_fattura_sirfel (CREATE OR REPLACE VIEW siac.siac_v_dwh_fattura_sirfel (
    ente_proprietario_id,
    fornitore_cod,
    fornitore_desc,
    data_emissione,
    data_ricezione,
    numero_documento,
    documento_fel_tipo_cod,
    documento_fel_tipo_desc,
    data_acquisizione,
    stato_acquisizione,
    importo_lordo,
    arrotondamento_fel,
    importo_netto,
    codice_destinatario,
    tipo_ritenuta,
    aliquota_ritenuta,
    importo_ritenuta,
    anno_protocollo,
    numero_protocollo,
    registro_protocollo,
    data_reg_protocollo,
    modpag_cod,
    modpag_desc,
    aliquota_iva,
    imponibile,
    imposta,
    arrotondamento_onere,
    spese_accessorie,
    doc_id,
    anno_doc,
    num_doc,
    data_emissione_doc,
    cod_tipo_doc,
    cod_sogg_doc,
    esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
    data_scadenza_pagamento_pcc, -- siac-6125 Sofia 23.05.2018
    stato_sdi , -- SIAC-6565
    lotto_sdi -- 02.10.2023 Sofia SIAC-TASK-172
    ) 
AS
SELECT tab.ente_proprietario_id, tab.fornitore_cod, tab.fornitore_desc,
    tab.data_emissione, tab.data_ricezione, tab.numero_documento,
    tab.documento_fel_tipo_cod, tab.documento_fel_tipo_desc,
    tab.data_acquisizione, tab.stato_acquisizione, tab.importo_lordo,
    tab.arrotondamento_fel, tab.importo_netto, tab.codice_destinatario,
    tab.tipo_ritenuta, tab.aliquota_ritenuta, tab.importo_ritenuta,
    tab.anno_protocollo, tab.numero_protocollo, tab.registro_protocollo,
    tab.data_reg_protocollo, tab.modpag_cod, tab.modpag_desc, tab.aliquota_iva,
    tab.imponibile, tab.imposta, tab.arrotondamento_onere, tab.spese_accessorie,
    tab.doc_id, tab.anno_doc, tab.num_doc, tab.data_emissione_doc,
    tab.cod_tipo_doc, tab.cod_sogg_doc,
    tab.esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
    tab.data_scadenza_pagamento_pcc, -- siac-6125 Sofia 23.05.2018
    tab.stato_sdi, -- SIAC-6565
    tab.lotto_sdi -- 02.10.2023 Sofia SIAC-TASK-172
FROM ( WITH dati_sirfel AS (
    SELECT tf.ente_proprietario_id,
                    tp.codice_prestatore AS fornitore_cod,
                        CASE
                            WHEN tp.denominazione_prestatore IS NULL THEN
                                ((tp.nome_prestatore::text || ' '::text) || tp.cognome_prestatore::text)::character varying
                            ELSE tp.denominazione_prestatore
                        END AS fornitore_desc,
                    tf.data AS data_emissione, tpf.data_ricezione,
                    tf.numero AS numero_documento,
                    dtd.codice AS documento_fel_tipo_cod,
                    dtd.descrizione AS documento_fel_tipo_desc,
                    tf.data_caricamento AS data_acquisizione,
                        CASE
                            WHEN tf.stato_fattura = 'S'::bpchar THEN 'IMPORTATA'::text
                            ELSE
                            CASE
                                WHEN tf.stato_fattura = 'N'::bpchar THEN
                                    'DA ACQUISIRE'::text
                                ELSE 'SOSPESA'::text
                            END
                        END AS stato_acquisizione,
                    tf.importo_totale_documento AS importo_lordo,
                    tf.arrotondamento AS arrotondamento_fel,
                    tf.importo_totale_netto AS importo_netto,
                    tf.codice_destinatario, tf.tipo_ritenuta,
                    tf.aliquota_ritenuta, tf.importo_ritenuta,
                    tpro.anno_protocollo, tpro.numero_protocollo,
                    tpro.registro_protocollo, tpro.data_reg_protocollo,
                    tpagdett.modalita_pagamento AS modpag_cod,
                    dmodpag.descrizione AS modpag_desc, trb.aliquota_iva,
                    trb.imponibile_importo AS imponibile, trb.imposta,
                    trb.arrotondamento AS arrotondamento_onere,
                    trb.spese_accessorie, tf.id_fattura,
                    tpf.esito_stato_fattura esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
                    tpagdett.data_scadenza_pagamento data_scadenza_pagamento_pcc -- siac-6125 Sofia 23.05.2018
    FROM sirfel_t_fattura tf
              JOIN sirfel_t_prestatore tp ON tf.id_prestatore =
                  tp.id_prestatore AND tf.ente_proprietario_id = tp.ente_proprietario_id
         LEFT JOIN sirfel_t_portale_fatture tpf ON tf.id_fattura =
             tpf.id_fattura AND tf.ente_proprietario_id = tpf.ente_proprietario_id
    LEFT JOIN sirfel_d_tipo_documento dtd ON tf.tipo_documento::text =
        dtd.codice::text AND tf.ente_proprietario_id = dtd.ente_proprietario_id
   LEFT JOIN sirfel_t_riepilogo_beni trb ON tf.id_fattura = trb.id_fattura AND
       tf.ente_proprietario_id = trb.ente_proprietario_id
   LEFT JOIN sirfel_t_protocollo tpro ON tf.id_fattura = tpro.id_fattura AND
       tf.ente_proprietario_id = tpro.ente_proprietario_id
   LEFT JOIN sirfel_t_pagamento tpag ON tf.id_fattura = tpag.id_fattura AND
       tf.ente_proprietario_id = tpag.ente_proprietario_id
   LEFT JOIN sirfel_t_dettaglio_pagamento tpagdett ON tpag.id_fattura =
       tpagdett.id_fattura AND tpag.progressivo = tpagdett.progressivo_pagamento AND tpag.ente_proprietario_id = tpagdett.ente_proprietario_id
   LEFT JOIN sirfel_d_modalita_pagamento dmodpag ON
       tpagdett.modalita_pagamento::text = dmodpag.codice::text AND tpagdett.ente_proprietario_id = dmodpag.ente_proprietario_id
    ), dati_fattura AS (
    SELECT rdoc.ente_proprietario_id, rdoc.id_fattura, tdoc.doc_id,
                    tdoc.doc_anno AS anno_doc, tdoc.doc_numero AS num_doc,
                    tdoc.doc_data_emissione AS data_emissione_doc,
                    ddoctipo.doc_tipo_code AS cod_tipo_doc,
                    tdoc.stato_sdi as stato_sdi, -- SIAC-6565
                    tdoc.doc_sdi_lotto_siope lotto_sdi, -- 02.10.2023 Sofia SIAC-TASK-172
                    tsogg.soggetto_code AS cod_sogg_doc
    FROM siac_r_doc_sirfel rdoc
              JOIN siac_t_doc tdoc ON tdoc.doc_id = rdoc.doc_id
         JOIN siac_d_doc_tipo ddoctipo ON tdoc.doc_tipo_id = ddoctipo.doc_tipo_id
    LEFT JOIN siac_r_doc_sog rdocsog ON tdoc.doc_id = rdocsog.doc_id AND
        rdocsog.data_cancellazione IS NULL AND now() >= rdocsog.validita_inizio AND now() <= COALESCE(rdocsog.validita_fine::timestamp with time zone, now())
   LEFT JOIN siac_t_soggetto tsogg ON rdocsog.soggetto_id = tsogg.soggetto_id
       AND tsogg.data_cancellazione IS NULL
    WHERE rdoc.data_cancellazione IS NULL AND tdoc.data_cancellazione IS NULL
        AND now() >= rdoc.validita_inizio AND now() <= COALESCE(rdoc.validita_fine::timestamp with time zone, now())
    )
    SELECT dati_sirfel.ente_proprietario_id, dati_sirfel.fornitore_cod,
            dati_sirfel.fornitore_desc, dati_sirfel.data_emissione,
            dati_sirfel.data_ricezione, dati_sirfel.numero_documento,
            dati_sirfel.documento_fel_tipo_cod,
            dati_sirfel.documento_fel_tipo_desc, dati_sirfel.data_acquisizione,
            dati_sirfel.stato_acquisizione, dati_sirfel.importo_lordo,
            dati_sirfel.arrotondamento_fel, dati_sirfel.importo_netto,
            dati_sirfel.codice_destinatario, dati_sirfel.tipo_ritenuta,
            dati_sirfel.aliquota_ritenuta, dati_sirfel.importo_ritenuta,
            dati_sirfel.anno_protocollo, dati_sirfel.numero_protocollo,
            dati_sirfel.registro_protocollo, dati_sirfel.data_reg_protocollo,
            dati_sirfel.modpag_cod, dati_sirfel.modpag_desc,
            dati_sirfel.aliquota_iva, dati_sirfel.imponibile,
            dati_sirfel.imposta, dati_sirfel.arrotondamento_onere,
            dati_sirfel.spese_accessorie, dati_sirfel.id_fattura,
            dati_fattura.doc_id, dati_fattura.anno_doc, dati_fattura.num_doc,
            dati_fattura.data_emissione_doc, dati_fattura.cod_tipo_doc,
            dati_fattura.cod_sogg_doc,
            dati_sirfel.esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
            dati_sirfel.data_scadenza_pagamento_pcc, -- siac-6125 Sofia 23.05.2018
            dati_fattura.stato_sdi, -- SIAC-6565
            dati_fattura.lotto_sdi -- 10.02.2023 Sofia SIAC-TASK-172
    FROM dati_sirfel
      LEFT JOIN dati_fattura ON dati_sirfel.id_fattura =
          dati_fattura.id_fattura AND dati_sirfel.ente_proprietario_id = dati_fattura.ente_proprietario_id
    ) tab;
    
   
   
   alter view siac.siac_v_dwh_fattura_sirfel owner to siac;