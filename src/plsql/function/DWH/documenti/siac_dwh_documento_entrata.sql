/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_documento_entrata (
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  anno_atto_amministrativo VARCHAR(4),
  num_atto_amministrativo VARCHAR(200),
  oggetto_atto_amministrativo VARCHAR(500),
  cod_tipo_atto_amministrativo VARCHAR(200),
  desc_tipo_atto_amministrativo VARCHAR(200),
  cod_cdr_atto_amministrativo VARCHAR(200),
  desc_cdr_atto_amministrativo VARCHAR(500),
  cod_cdc_atto_amministrativo VARCHAR(200),
  desc_cdc_atto_amministrativo VARCHAR(500),
  note_atto_amministrativo VARCHAR(500),
  cod_stato_atto_amministrativo VARCHAR(200),
  desc_stato_atto_amministrativo VARCHAR(200),
  causale_atto_allegato VARCHAR(500),
  altri_allegati_atto_allegato VARCHAR(500),
  dati_sensibili_atto_allegato VARCHAR(1),
  data_scadenza_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  note_atto_allegato VARCHAR(500),
  annotazioni_atto_allegato VARCHAR(500),
  pratica_atto_allegato VARCHAR(500),
  resp_amm_atto_allegato VARCHAR(500),
  resp_contabile_atto_allegato VARCHAR(500),
  anno_titolario_atto_allegato INTEGER,
  num_titolario_atto_allegato VARCHAR(500),
  vers_invio_firma_atto_allegato INTEGER,
  cod_stato_atto_allegato VARCHAR(200),
  desc_stato_atto_allegato VARCHAR(200),
  sogg_id_atto_allegato INTEGER,
  cod_sogg_atto_allegato VARCHAR(200),
  tipo_sogg_atto_allegato VARCHAR(500),
  stato_sogg_atto_allegato VARCHAR(500),
  rag_sociale_sogg_atto_allegato VARCHAR(500),
  p_iva_sogg_atto_allegato VARCHAR(500),
  cf_sogg_atto_allegato VARCHAR(16),
  cf_estero_sogg_atto_allegato VARCHAR(500),
  nome_sogg_atto_allegato VARCHAR(500),
  cognome_sogg_atto_allegato VARCHAR(500),
  anno_doc INTEGER,
  num_doc VARCHAR(200),
  desc_doc VARCHAR(500),
  importo_doc NUMERIC,
  beneficiario_multiplo_doc VARCHAR(1),
  data_emissione_doc TIMESTAMP WITHOUT TIME ZONE,
  data_scadenza_doc TIMESTAMP WITHOUT TIME ZONE,
  codice_bollo_doc VARCHAR(200),
  desc_codice_bollo_doc VARCHAR(500),
  collegato_cec_doc VARCHAR(200),
  cod_pcc_doc VARCHAR(200),
  desc_pcc_doc VARCHAR(500),
  cod_ufficio_doc VARCHAR(200),
  desc_ufficio_doc VARCHAR(500),
  cod_stato_doc VARCHAR(200),
  desc_stato_doc VARCHAR(500),
  anno_elenco_doc INTEGER,
  num_elenco_doc INTEGER,
  data_trasmissione_elenco_doc TIMESTAMP WITHOUT TIME ZONE,
  tot_quote_entrate_elenco_doc NUMERIC,
  tot_quote_spese_elenco_doc NUMERIC,
  tot_da_pagare_elenco_doc NUMERIC,
  tot_da_incassare_elenco_doc NUMERIC,
  cod_stato_elenco_doc VARCHAR(200),
  desc_stato_elenco_doc VARCHAR(500),
  cod_gruppo_doc VARCHAR(200),
  desc_gruppo_doc VARCHAR(500),
  cod_famiglia_doc VARCHAR(200),
  desc_famiglia_doc VARCHAR(500),
  cod_tipo_doc VARCHAR(200),
  desc_tipo_doc VARCHAR(500),
  sogg_id_doc INTEGER,
  cod_sogg_doc VARCHAR(200),
  tipo_sogg_doc VARCHAR(500),
  stato_sogg_doc VARCHAR(500),
  rag_sociale_sogg_doc VARCHAR(500),
  p_iva_sogg_doc VARCHAR(500),
  cf_sogg_doc VARCHAR(16),
  cf_estero_sogg_doc VARCHAR(500),
  nome_sogg_doc VARCHAR(500),
  cognome_sogg_doc VARCHAR(500),
  num_subdoc INTEGER,
  desc_subdoc VARCHAR(500),
  importo_subdoc NUMERIC,
  num_reg_iva_subdoc VARCHAR(500),
  data_scadenza_subdoc TIMESTAMP WITHOUT TIME ZONE,
  convalida_manuale_subdoc VARCHAR(1),
  importo_da_dedurre_subdoc NUMERIC,
  splitreverse_importo_subdoc NUMERIC,
  pagato_cec_subdoc VARCHAR(1),
  data_pagamento_cec_subdoc TIMESTAMP WITHOUT TIME ZONE,
  note_tesoriere_subdoc VARCHAR(500),
  cod_distinta_subdoc VARCHAR(200),
  desc_distinta_subdoc VARCHAR(500),
  tipo_commissione_subdoc VARCHAR(500),
  conto_tesoreria_subdoc VARCHAR(500),
  rilevante_iva VARCHAR(1),
  ordinativo_singolo VARCHAR(1),
  ordinativo_manuale VARCHAR(1),
  esproprio VARCHAR(1),
  note VARCHAR(500),
  avviso VARCHAR(1),
  cod_tipo_avviso VARCHAR(200),
  desc_tipo_avviso VARCHAR(500),
  sogg_id_subdoc INTEGER,
  cod_sogg_subdoc VARCHAR(200),
  tipo_sogg_subdoc VARCHAR(500),
  stato_sogg_subdoc VARCHAR(500),
  rag_sociale_sogg_subdoc VARCHAR(500),
  p_iva_sogg_subdoc VARCHAR(500),
  cf_sogg_subdoc VARCHAR(16),
  cf_estero_sogg_subdoc VARCHAR(500),
  nome_sogg_subdoc VARCHAR(500),
  cognome_sogg_subdoc VARCHAR(500),
  sede_secondaria_subdoc CHAR(40),
  bil_anno VARCHAR(4),
  anno_accertamento INTEGER,
  num_accertamento NUMERIC,
  cod_accertamento VARCHAR(200),
  desc_accertamento VARCHAR(500),
  cod_subaccertamento VARCHAR(200),
  desc_subaccertamento VARCHAR(500),
  cod_tipo_accredito VARCHAR(200),
  desc_tipo_accredito VARCHAR(200),
  mod_pag_id INTEGER,
  quietanziante VARCHAR(500),
  data_nascita_quietanziante TIMESTAMP WITHOUT TIME ZONE,
  luogo_nascita_quietanziante VARCHAR(500),
  stato_nascita_quietanziante VARCHAR(500),
  bic VARCHAR(500),
  contocorrente VARCHAR(500),
  intestazione_contocorrente VARCHAR(500),
  iban VARCHAR(500),
  note_mod_pag VARCHAR(500),
  data_scadenza_mod_pag TIMESTAMP WITHOUT TIME ZONE,
  sogg_id_mod_pag INTEGER,
  cod_sogg_mod_pag VARCHAR(200),
  tipo_sogg_mod_pag VARCHAR(500),
  stato_sogg_mod_pag VARCHAR(500),
  rag_sociale_sogg_mod_pag VARCHAR(500),
  p_iva_sogg_mod_pag VARCHAR(500),
  cf_sogg_mod_pag VARCHAR(16),
  cf_estero_sogg_mod_pag VARCHAR(500),
  nome_sogg_mod_pag VARCHAR(500),
  cognome_sogg_mod_pag VARCHAR(500),
  bil_anno_ord VARCHAR(4),
  anno_ord INTEGER,
  num_ord NUMERIC,
  num_subord VARCHAR(200),
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  registro_repertorio VARCHAR(200),
  anno_repertorio VARCHAR(4),
  num_repertorio VARCHAR(200),
  data_repertorio VARCHAR(200),
  data_ricezione_portale VARCHAR(200),
  doc_contabilizza_genpcc VARCHAR(200),
  arrotondamento NUMERIC,
  doc_id INTEGER
) 
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.ente_proprietario_id
IS 'ente (siac_t_ente_proprietario)';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.ente_denominazione
IS 'denominazione ente (siac_t_ente_proprietario.ente_denominazione)';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.anno_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_anno';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.num_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_numero';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.oggetto_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_oggetto';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_cdr_atto_amministrativo
IS 'classificatore codice (siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_cdr_atto_amministrativo
IS 'classificatore descrizione (siac_t_class.classif_desc, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_cdc_atto_amministrativo
IS 'classificatore codice (siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_cdc_atto_amministrativo
IS 'classificatore descrizione (siac_t_class.classif_desc, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.note_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_note';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_stato_atto_amministrativo
IS 'siac_d_atto_amm_stato.attoamm_stato_code tramite siac_r_atto_amm_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_stato_atto_amministrativo
IS 'siac_d_atto_amm_stato.attoamm_stato_desc tramite siac_r_atto_amm_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.causale_atto_allegato
IS 'siac_t_atto_allegato.attoal_causale';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.altri_allegati_atto_allegato
IS 'siac_t_atto_allegato.attoal_altriallegati';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.dati_sensibili_atto_allegato
IS 'siac_t_atto_allegato.attoal_dati_sensibili';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.data_scadenza_atto_allegato
IS 'siac_t_atto_allegato.attoal_data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.note_atto_allegato
IS 'siac_t_atto_allegato.attoal_note';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.annotazioni_atto_allegato
IS 'siac_t_atto_allegato.attoal_annotazioni';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.pratica_atto_allegato
IS 'siac_t_atto_allegato.attoal_pratica';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.resp_amm_atto_allegato
IS 'siac_t_atto_allegato.attoal_responsabile_amm';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.resp_contabile_atto_allegato
IS 'siac_t_atto_allegato.attoal_responsabile_con';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.anno_titolario_atto_allegato
IS 'siac_t_atto_allegato.attoal_titolario_anno';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.num_titolario_atto_allegato
IS 'siac_t_atto_allegato.attoal_titolario_numero';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.vers_invio_firma_atto_allegato
IS 'siac_t_atto_allegato.attoal_versione_invio_firma';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_stato_atto_allegato
IS 'siac_d_atto_allegato_stato.attoal_stato_code tramite siac_r_atto_allegato_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_stato_atto_allegato
IS 'siac_d_atto_allegato_stato.attoal_stato_desc tramite siac_r_atto_allegato_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_sogg_atto_allegato
IS 'siac_t_soggetto.siac_t_soggetto.soggetto_code tramite siac_r_atto_allegato_sog';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.tipo_sogg_atto_allegato
IS 'siac_d_soggetto_tipo.soggetto_tipo_desc tramite siac_r_soggetto_tipo';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.stato_sogg_atto_allegato
IS 'siac_t_soggetto_stato.soggetto_stato_desc tramite siac_r_soggetto_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.rag_sociale_sogg_atto_allegato
IS 'siac_t_persona_giuridica.ragione_sociale';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.p_iva_sogg_atto_allegato
IS 'siac_t_soggetto.partita_iva';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cf_sogg_atto_allegato
IS 'siac_t_soggetto.codice_fiscale';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cf_estero_sogg_atto_allegato
IS 'siac_t_soggetto.codice_fiscale_estero';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.nome_sogg_atto_allegato
IS 'siac_t_persona_fisica.nome';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cognome_sogg_atto_allegato
IS 'siac_t_persona_fisica.cognome';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.anno_doc
IS 'siac_t_doc.doc_anno';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.num_doc
IS 'siac_t_doc.doc_numero';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_doc
IS 'siac_t_doc.doc_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.importo_doc
IS 'siac_t_doc.doc_importo';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.beneficiario_multiplo_doc
IS 'siac_t_doc.doc_beneficiariomult';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.data_emissione_doc
IS 'siac_t_doc.doc_data_emissione';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.data_scadenza_doc
IS 'siac_t_doc.doc_data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.codice_bollo_doc
IS 'siac_d_codicebollo.codbollo.code';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_codice_bollo_doc
IS 'siac_d_codicebollo.codbollo.desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.collegato_cec_doc
IS 'siac_t_doc.doc_collegato_cec';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_pcc_doc
IS 'siac_d_pcc_codice.pcccod_code';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_pcc_doc
IS 'siac_d_pcc_codice.pcccod_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_ufficio_doc
IS 'siac_d_pcc_ufficio.pccuff_code';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_ufficio_doc
IS 'siac_d_pcc_ufficio.pccuff_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_stato_doc
IS 'siac_d_doc_stato.doc_stato_code';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_stato_doc
IS 'siac_d_doc_stato.doc_stato_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.anno_elenco_doc
IS 'siac_t_elenco_doc.eldoc_anno';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.num_elenco_doc
IS 'siac_t_elenco_doc.eldoc_numero';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.data_trasmissione_elenco_doc
IS 'siac_t_elenco_doc.eldoc_data_trasmissione';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.tot_quote_entrate_elenco_doc
IS 'siac_t_elenco_doc.eldoc_tot_quoteentrate';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.tot_quote_spese_elenco_doc
IS 'siac_t_elenco_doc.eldoc_tot_quotespese';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.tot_da_pagare_elenco_doc
IS 'siac_t_elenco_doc.eldoc_tot_dapagare';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.tot_da_incassare_elenco_doc
IS 'siac_t_elenco_doc.eldoc_tot_daincassare';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_stato_elenco_doc
IS 'siac_d_elenco_doc_stato.eldoc_stato_code tramite siac_r_elenco_doc_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_stato_elenco_doc
IS 'siac_d_elenco_doc_statoeldoc_stato_desc tramite siac_r_elenco_doc_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_gruppo_doc
IS 'siac_d_doc_gruppo.doc_gruppo_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_gruppo_doc
IS 'siac_d_doc_gruppo.doc_gruppo_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_famiglia_doc
IS 'siac_d_doc_fam_tipo.doc_fam_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_famiglia_doc
IS 'siac_d_doc_fam_tipo.doc_fam_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_tipo_doc
IS 'siac_d_doc_tipo.doc_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_tipo_doc
IS 'siac_d_doc_tipo.doc_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_sogg_doc
IS 'siac_t_soggetto.siac_t_soggetto.soggetto_code tramite siac_r_doc_sog';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.tipo_sogg_doc
IS 'siac_d_soggetto_tipo.soggetto_tipo_desc tramite siac_r_soggetto_tipo';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.stato_sogg_doc
IS 'siac_t_soggetto_stato.soggetto_stato_desc tramite siac_r_soggetto_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.rag_sociale_sogg_doc
IS 'siac_t_persona_giuridica.ragione_sociale';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.p_iva_sogg_doc
IS 'siac_t_soggetto.partita_iva';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cf_sogg_doc
IS 'siac_t_soggetto.codice_fiscale';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cf_estero_sogg_doc
IS 'siac_t_soggetto.codice_fiscale_estero';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.nome_sogg_doc
IS 'siac_t_persona_fisica.nome';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cognome_sogg_doc
IS 'siac_t_persona_fisica.cognome';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.num_subdoc
IS 'siac_t_subdoc.subdoc_numero';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_subdoc
IS 'siac_t_subdoc.subdoc_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.importo_subdoc
IS 'siac_t_subdoc.subdoc_importo';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.num_reg_iva_subdoc
IS 'siac_t_subdoc.subdoc_nreg_iva';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.data_scadenza_subdoc
IS 'siac_t_subdoc.subdoc_data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.convalida_manuale_subdoc
IS 'siac_t_subdoc.subdoc_convalida_manuale';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.importo_da_dedurre_subdoc
IS 'siac_t_subdoc.subdoc_importo_da_dedurre';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.splitreverse_importo_subdoc
IS 'siac_t_subdoc.subdoc_splitreverse_importo';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.pagato_cec_subdoc
IS 'siac_t_subdoc.subdoc_pagato_cec';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.data_pagamento_cec_subdoc
IS 'siac_t_subdoc.subdoc_data_pagamento_cec';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.note_tesoriere_subdoc
IS 'siac_d_note_tesoriere.notetes_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_distinta_subdoc
IS 'siac_d_distinta.dist_code';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_distinta_subdoc
IS 'siac_d_distinta.dist_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.tipo_commissione_subdoc
IS 'siac_d_commissione_tipo.comm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.conto_tesoreria_subdoc
IS 'siac_d_contotesoreria.contotes_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.rilevante_iva
IS 'flagRilevanteIVA attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.ordinativo_singolo
IS 'flagOrdinativoSingolo attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.ordinativo_manuale
IS 'flagOrdinativoManuale attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.esproprio
IS 'flagEsproprio attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.note
IS 'Note attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.avviso
IS 'flagAvviso attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_tipo_avviso
IS 'siac_t_class.classif_code tramite siac_r_subdoc_class';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_tipo_avviso
IS 'siac_t_class.classif_code tramite siac_r_subdoc_class';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_sogg_subdoc
IS 'siac_t_soggetto.siac_t_soggetto.soggetto_code tramite siac_r_subdoc_sog';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.tipo_sogg_subdoc
IS 'siac_d_soggetto_tipo.soggetto_tipo_desc tramite siac_r_soggetto_tipo';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.stato_sogg_subdoc
IS 'siac_t_soggetto_stato.soggetto_stato_desc tramite siac_r_soggetto_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.rag_sociale_sogg_subdoc
IS 'siac_t_persona_giuridica.ragione_sociale';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.p_iva_sogg_subdoc
IS 'siac_t_soggetto.partita_iva';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cf_sogg_subdoc
IS 'siac_t_soggetto.codice_fiscale';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cf_estero_sogg_subdoc
IS 'siac_t_soggetto.codice_fiscale_estero';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.nome_sogg_subdoc
IS 'siac_t_persona_fisica.nome';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cognome_sogg_subdoc
IS 'siac_t_persona_fisica.cognome';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.sede_secondaria_subdoc
IS '''S'' se soggetto_id = siac_r_soggetto_relaz.soggetto_id_a con siac_d_relaz_tipo=''SEDE_SECONDARIA''  il soggetto su siac_r_subdoc_sog dovrebbe sempre essere sede secondaria';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.bil_anno
IS 'anno bilancio (siac_t_periodo.anno) tramite siac_r_subdoc_movgest_ts siac_t_movgest_ts siac_t_movgest';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.anno_accertamento
IS 'siac_t_movgest.movgest_anno con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''A''  tramite siac_r_subdoc_movgest_ts, siac_t_movgest_ts, siac_t_movgest';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.num_accertamento
IS 'siac_t_movgest.movgest_num con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''A'' tramite siac_r_subdoc_movgest_ts, siac_t_movgest_ts, siac_t_movgest';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_accertamento
IS 'siac_t_movgest_ts.movgest_ts_code con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_accertamento
IS 'siac_t_movgest.movgest_desc con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''A'' tramite siac_r_subdoc_movgest_ts, siac_t_movgest_ts, siac_t_movgest';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_subaccertamento
IS 'siac_t_movgest_ts.movgest_ts_code con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo S testata''  tramite siac_r_subdoc_movgest_ts';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_subaccertamento
IS 'siac_t_movgest_ts.movgest_ts_desc con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo S testata''  tramite siac_r_subdoc_movgest_ts';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_tipo_accredito
IS 'siac_d_accredito_tipo.accredito_tipo_code tramite siac_t_modpag, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.desc_tipo_accredito
IS 'siac_d_accredito_tipo.accredito_tipo_desc tramite siac_t_modpag, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.quietanziante
IS 'siac_t_modpag.quietanziante, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.data_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_data, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.luogo_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_luogo, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.stato_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_stato, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.bic
IS 'siac_t_modpag.bic, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.contocorrente
IS 'siac_t_modpag.contocorrente, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.intestazione_contocorrente
IS 'siac_t_modpag.contocorrente_intestazione, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.iban
IS 'siac_t_modpag.iban, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.note_mod_pag
IS 'siac_t_modpag.note, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.data_scadenza_mod_pag
IS 'siac_t_modpag.data_scadenza, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cod_sogg_mod_pag
IS 'siac_t_soggetto.soggetto_code dove soggetto_id=siac_t_modpag.soggetto_id tramite siac_r_subdoc_modpag se siac_r_subdoc_modpag .soggrelmpag_id is null  se  siac_r_subdoc_modpag .soggrelmpag_id is not null si tratta di cessione quindi siac_t_soggetto.soggetto_code dove soggetto_id=siac_r_soggetto_relaz.soggetto_id_a dove  siac_r_soggrel_modpag.soggrelmpag_id=siac_r_subdoc_modpag .soggrelmpag_id e  siac_r_soggrel_modpag.soggetto_relaz_id=soggetto_relaz_id ';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.tipo_sogg_mod_pag
IS 'siac_d_soggetto_tipo.soggetto_tipo_desc tramite siac_r_soggetto_tipo';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.stato_sogg_mod_pag
IS 'siac_t_soggetto_stato.soggetto_stato_desc tramite siac_r_soggetto_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.rag_sociale_sogg_mod_pag
IS 'siac_t_persona_giuridica.ragione_sociale';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.p_iva_sogg_mod_pag
IS 'siac_t_soggetto.partita_iva';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cf_sogg_mod_pag
IS 'siac_t_soggetto.codice_fiscale';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cf_estero_sogg_mod_pag
IS 'siac_t_soggetto.codice_fiscale_estero';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.nome_sogg_mod_pag
IS 'siac_t_persona_fisica.nome';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.cognome_sogg_mod_pag
IS 'siac_t_persona_fisica.cognome';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.registro_repertorio
IS 'registro_repertorio siac_t_attr.attr_code=''registro_repertorio''(x coge)';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.anno_repertorio
IS 'registro_repertorio siac_t_attr.attr_code=''anno_repertorio''(x coge)';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.num_repertorio
IS 'registro_repertorio siac_t_attr.attr_code=''num_repertorio''(x coge)';

COMMENT ON COLUMN siac.siac_dwh_documento_entrata.data_repertorio
IS 'registro_repertorio siac_t_attr.attr_code=''data_repertorio''(x coge)';


alter table siac_dwh_documento_entrata add column arrotondamento numeric;

