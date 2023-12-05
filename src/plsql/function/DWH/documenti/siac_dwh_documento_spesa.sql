/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_documento_spesa_gnew (
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
  desc_famiglia_doc VARCHAR(500),
  cod_famiglia_doc VARCHAR(200),
  desc_gruppo_doc VARCHAR(500),
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
  cig VARCHAR(500),
  cup VARCHAR(500),
  causale_sospensione VARCHAR(500),
  data_sospensione VARCHAR(500),
  data_riattivazione VARCHAR(500),
  causale_ordinativo VARCHAR(500),
  num_mutuo INTEGER,
  annotazione VARCHAR(500),
  certificazione VARCHAR(1),
  data_certificazione VARCHAR(500),
  note_certificazione VARCHAR(500),
  num_certificazione VARCHAR(500),
  data_scadenza_dopo_sospensione VARCHAR(500),
  data_esecuzione_pagamento VARCHAR(500),
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
  sede_secondaria_subdoc VARCHAR(1),
  bil_anno VARCHAR(4),
  anno_impegno INTEGER,
  num_impegno NUMERIC,
  cod_impegno VARCHAR(200),
  desc_impegno VARCHAR(500),
  cod_subimpegno VARCHAR(200),
  desc_subimpegno VARCHAR(500),
  num_liquidazione NUMERIC,
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
  anno_liquidazione INTEGER,
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
  rudoc_registrazione_anno INTEGER,
  rudoc_registrazione_numero INTEGER,
  rudoc_registrazione_data TIMESTAMP WITHOUT TIME ZONE,
  cod_cdc_doc VARCHAR(200),
  desc_cdc_doc VARCHAR(500),
  cod_cdr_doc VARCHAR(200),
  desc_cdr_doc VARCHAR(500),
  data_operazione_pagamentoincasso VARCHAR(500),
  pagataincassata VARCHAR(500),
  note_pagamentoincasso VARCHAR(500),
  cod_tipo_splitrev VARCHAR(200),
  desc_tipo_splitrev VARCHAR(200),
  stato_liquidazione VARCHAR(200),
  arrotondamento NUMERIC,
  cod_siope_tipo_debito_subdoc VARCHAR(200),
  desc_siope_tipo_debito_subdoc VARCHAR(500),
  desc_siope_tipo_deb_bnkit_sub VARCHAR(500),
  cod_siope_ass_motiv_subdoc VARCHAR(200),
  desc_siope_ass_motiv_subdoc VARCHAR(500),
  desc_siope_ass_motiv_bnkit_sub VARCHAR(500),
  cod_siope_scad_motiv_subdoc VARCHAR(200),
  desc_siope_scad_motiv_subdoc VARCHAR(500),
  desc_siope_scad_moti_bnkit_sub VARCHAR(500),
  sdi_lotto_siope_doc VARCHAR(200),
  cod_siope_tipo_doc VARCHAR(200),
  desc_siope_tipo_doc VARCHAR(500),
  desc_siope_tipo_bnkit_doc VARCHAR(500),
  cod_siope_tipo_analogico_doc VARCHAR(200),
  desc_siope_tipo_analogico_doc VARCHAR(500),
  desc_siope_tipo_ana_bnkit_doc VARCHAR(500),
  doc_id INTEGER  ,
  -- SIAC-8153 Sofia 22.06.2021
  cod_cdc_sub VARCHAR(200),
  desc_cdc_sub VARCHAR(500),
  cod_cdr_sub VARCHAR(200),
  desc_cdr_sub VARCHAR(500)
  -- SIAC-8153 Sofia 22.06.2021
) 
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.ente_proprietario_id
IS 'ente (siac_t_ente_proprietario)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.ente_denominazione
IS 'denominazione ente (siac_t_ente_proprietario.ente_denominazione)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.anno_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_anno';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_numero';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.oggetto_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_oggetto';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_cdr_atto_amministrativo
IS 'classificatore codice (siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_cdr_atto_amministrativo
IS 'classificatore descrizione (siac_t_class.classif_desc, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_cdc_atto_amministrativo
IS 'classificatore codice (siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_cdc_atto_amministrativo
IS 'classificatore descrizione (siac_t_class.classif_desc, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.note_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_note';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_stato_atto_amministrativo
IS 'siac_d_atto_amm_stato.attoamm_stato_code tramite siac_r_atto_amm_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_stato_atto_amministrativo
IS 'siac_d_atto_amm_stato.attoamm_stato_desc tramite siac_r_atto_amm_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.causale_atto_allegato
IS 'siac_t_atto_allegato.attoal_causale';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.altri_allegati_atto_allegato
IS 'siac_t_atto_allegato.attoal_altriallegati';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.dati_sensibili_atto_allegato
IS 'siac_t_atto_allegato.attoal_dati_sensibili';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_scadenza_atto_allegato
IS 'siac_t_atto_allegato.attoal_data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.note_atto_allegato
IS 'siac_t_atto_allegato.attoal_note';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.annotazioni_atto_allegato
IS 'siac_t_atto_allegato.attoal_annotazioni';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.pratica_atto_allegato
IS 'siac_t_atto_allegato.attoal_pratica';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.resp_amm_atto_allegato
IS 'siac_t_atto_allegato.attoal_responsabile_amm';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.resp_contabile_atto_allegato
IS 'siac_t_atto_allegato.attoal_responsabile_con';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.anno_titolario_atto_allegato
IS 'siac_t_atto_allegato.attoal_titolario_anno';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_titolario_atto_allegato
IS 'siac_t_atto_allegato.attoal_titolario_numero';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.vers_invio_firma_atto_allegato
IS 'siac_t_atto_allegato.attoal_versione_invio_firma';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_stato_atto_allegato
IS 'siac_d_atto_allegato_stato.attoal_stato_code tramite siac_r_atto_allegato_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_stato_atto_allegato
IS 'siac_d_atto_allegato_stato.attoal_stato_desc tramite siac_r_atto_allegato_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_sogg_atto_allegato
IS 'siac_t_soggetto.siac_t_soggetto.soggetto_code tramite siac_r_atto_allegato_sog';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.tipo_sogg_atto_allegato
IS 'siac_d_soggetto_tipo.soggetto_tipo_desc tramite siac_r_soggetto_tipo';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.stato_sogg_atto_allegato
IS 'siac_t_soggetto_stato.soggetto_stato_desc tramite siac_r_soggetto_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.rag_sociale_sogg_atto_allegato
IS 'siac_t_persona_giuridica.ragione_sociale';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.p_iva_sogg_atto_allegato
IS 'siac_t_soggetto.partita_iva';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cf_sogg_atto_allegato
IS 'siac_t_soggetto.codice_fiscale';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cf_estero_sogg_atto_allegato
IS 'siac_t_soggetto.codice_fiscale_estero';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.nome_sogg_atto_allegato
IS 'siac_t_persona_fisica.nome';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cognome_sogg_atto_allegato
IS 'siac_t_persona_fisica.cognome';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.anno_doc
IS 'siac_t_doc.doc_anno';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_doc
IS 'siac_t_doc.doc_numero';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_doc
IS 'siac_t_doc.doc_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.importo_doc
IS 'siac_t_doc.doc_importo';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.beneficiario_multiplo_doc
IS 'siac_t_doc.doc_beneficiariomult';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_emissione_doc
IS 'siac_t_doc.doc_data_emissione';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_scadenza_doc
IS 'siac_t_doc.doc_data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.codice_bollo_doc
IS 'siac_d_codicebollo.codbollo.code';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_codice_bollo_doc
IS 'siac_d_codicebollo.codbollo.desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.collegato_cec_doc
IS 'siac_t_doc.doc_collegato_cec';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_pcc_doc
IS 'siac_d_pcc_codice.pcccod_code';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_pcc_doc
IS 'siac_d_pcc_codice.pcccod_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_ufficio_doc
IS 'siac_d_pcc_ufficio.pccuff_code';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_ufficio_doc
IS 'siac_d_pcc_ufficio.pccuff_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_stato_doc
IS 'siac_d_doc_stato.doc_stato_code';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_stato_doc
IS 'siac_d_doc_stato.doc_stato_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.anno_elenco_doc
IS 'siac_t_elenco_doc.eldoc_anno';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_elenco_doc
IS 'siac_t_elenco_doc.eldoc_numero';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_trasmissione_elenco_doc
IS 'siac_t_elenco_doc.eldoc_data_trasmissione';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.tot_quote_entrate_elenco_doc
IS 'siac_t_elenco_doc.eldoc_tot_quoteentrate';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.tot_quote_spese_elenco_doc
IS 'siac_t_elenco_doc.eldoc_tot_quotespese';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.tot_da_pagare_elenco_doc
IS 'siac_t_elenco_doc.eldoc_tot_dapagare';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.tot_da_incassare_elenco_doc
IS 'siac_t_elenco_doc.eldoc_tot_daincassare';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_stato_elenco_doc
IS 'siac_d_elenco_doc_stato.eldoc_stato_code tramite siac_r_elenco_doc_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_stato_elenco_doc
IS 'siac_d_elenco_doc_statoeldoc_stato_desc tramite siac_r_elenco_doc_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_gruppo_doc
IS 'siac_d_doc_gruppo.doc_gruppo_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_famiglia_doc
IS 'siac_d_doc_fam_tipo.doc_fam_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_famiglia_doc
IS 'siac_d_doc_fam_tipo.doc_fam_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_gruppo_doc
IS 'siac_d_doc_gruppo.doc_gruppo_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_tipo_doc
IS 'siac_d_doc_tipo.doc_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_tipo_doc
IS 'siac_d_doc_tipo.doc_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_sogg_doc
IS 'siac_t_soggetto.siac_t_soggetto.soggetto_code tramite siac_r_doc_sog';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.tipo_sogg_doc
IS 'siac_d_soggetto_tipo.soggetto_tipo_desc tramite siac_r_soggetto_tipo';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.stato_sogg_doc
IS 'siac_t_soggetto_stato.soggetto_stato_desc tramite siac_r_soggetto_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.rag_sociale_sogg_doc
IS 'siac_t_persona_giuridica.ragione_sociale';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.p_iva_sogg_doc
IS 'siac_t_soggetto.partita_iva';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cf_sogg_doc
IS 'siac_t_soggetto.codice_fiscale';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cf_estero_sogg_doc
IS 'siac_t_soggetto.codice_fiscale_estero';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.nome_sogg_doc
IS 'siac_t_persona_fisica.nome';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cognome_sogg_doc
IS 'siac_t_persona_fisica.cognome';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_subdoc
IS 'siac_t_subdoc.subdoc_numero';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_subdoc
IS 'siac_t_subdoc.subdoc_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.importo_subdoc
IS 'siac_t_subdoc.subdoc_importo';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_reg_iva_subdoc
IS 'siac_t_subdoc.subdoc_nreg_iva';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_scadenza_subdoc
IS 'siac_t_subdoc.subdoc_data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.convalida_manuale_subdoc
IS 'siac_t_subdoc.subdoc_convalida_manuale';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.importo_da_dedurre_subdoc
IS 'siac_t_subdoc.subdoc_importo_da_dedurre';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.splitreverse_importo_subdoc
IS 'siac_t_subdoc.subdoc_splitreverse_importo';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.pagato_cec_subdoc
IS 'siac_t_subdoc.subdoc_pagato_cec';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_pagamento_cec_subdoc
IS 'siac_t_subdoc.subdoc_data_pagamento_cec';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.note_tesoriere_subdoc
IS 'siac_d_note_tesoriere.notetes_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_distinta_subdoc
IS 'siac_d_distinta.dist_code';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_distinta_subdoc
IS 'siac_d_distinta.dist_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.tipo_commissione_subdoc
IS 'siac_d_commissione_tipo.comm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.conto_tesoreria_subdoc
IS 'siac_d_contotesoreria.contotes_desc';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.rilevante_iva
IS 'flagRilevanteIVA attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.ordinativo_singolo
IS 'flagOrdinativoSingolo attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.ordinativo_manuale
IS 'flagOrdinativoManuale attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.esproprio
IS 'flagEsproprio attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.note
IS 'Note attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cig
IS 'cig attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cup
IS 'cup attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.causale_sospensione
IS 'causale_sospensione attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_sospensione
IS 'data_sospensione attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_riattivazione
IS 'data_riattivazione attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.causale_ordinativo
IS 'causaleOrdinativo attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_mutuo
IS 'numeroMutuo attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.annotazione
IS 'annotazione attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.certificazione
IS 'flagCertificazione attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_certificazione
IS 'dataCertificazione attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.note_certificazione
IS 'noteCertificazione attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_certificazione
IS 'numeroCertificazione attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_scadenza_dopo_sospensione
IS 'dataScadenzaDopoSospensione attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_esecuzione_pagamento
IS 'dataEsecuzionePagamento attributo - siac_r_subdoc_attr, siac_t_attr (solo spesa)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.avviso
IS 'flagAvviso attributo - siac_r_subdoc_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_tipo_avviso
IS 'siac_t_class.classif_code tramite siac_r_subdoc_class';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_tipo_avviso
IS 'siac_t_class.classif_desc tramite siac_r_subdoc_class';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_sogg_subdoc
IS 'siac_t_soggetto.siac_t_soggetto.soggetto_code tramite siac_r_subdoc_sog';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.tipo_sogg_subdoc
IS 'siac_d_soggetto_tipo.soggetto_tipo_desc tramite siac_r_soggetto_tipo';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.stato_sogg_subdoc
IS 'siac_t_soggetto_stato.soggetto_stato_desc tramite siac_r_soggetto_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.rag_sociale_sogg_subdoc
IS 'siac_t_persona_giuridica.ragione_sociale';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.p_iva_sogg_subdoc
IS 'siac_t_soggetto.partita_iva';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cf_sogg_subdoc
IS 'siac_t_soggetto.codice_fiscale';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cf_estero_sogg_subdoc
IS 'siac_t_soggetto.codice_fiscale_estero';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.nome_sogg_subdoc
IS 'siac_t_persona_fisica.nome';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cognome_sogg_subdoc
IS 'siac_t_persona_fisica.cognome';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.sede_secondaria_subdoc
IS '''S'' se soggetto_id = siac_r_soggetto_relaz.soggetto_id_a con  siac_d_relaz_tipo=''SEDE_SECONDARIA''  tramite siac_r_subdoc_sog, siac_t_soggetto . il soggetto su siac_r_subdoc_sog dovrebbe sempre essere sede secondaria';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.bil_anno
IS 'anno bilancio (siac_t_periodo.anno) tramite siac_r_subdoc_movgest_ts siac_t_movgest_ts siac_t_movgest';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.anno_impegno
IS 'siac_t_movgest.movgest_anno con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''I'' ';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_impegno
IS 'siac_t_movgest.movgest_num con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_impegno
IS 'siac_t_movgest.movgest_code con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_impegno
IS 'siac_t_movgest.movgest_desc con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_subimpegno
IS 'siac_t_movgest_ts.movgest_ts_code con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo S testata'' ';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_subimpegno
IS 'siac_t_movgest_ts.movgest_ts_desc con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo S testata'' ';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_liquidazione
IS 'siac_t_liquidazione tramite siac_r_subdoc_liquidazione';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_tipo_accredito
IS 'siac_d_accredito_tipo.accredito_tipo_code tramite siac_t_modpad, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.desc_tipo_accredito
IS 'siac_d_accredito_tipo.accredito_tipo_desc, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.quietanziante
IS 'siac_t_modpag.quietanziante, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_data, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.luogo_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_luogo, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.stato_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_stato, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.bic
IS 'siac_t_modpag.bic, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.contocorrente
IS 'siac_t_modpag.contocorrente, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.intestazione_contocorrente
IS 'siac_t_modpag.contocorrente_intestazione, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.iban
IS 'siac_t_modpag.iban, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.note_mod_pag
IS 'siac_t_modpag.note, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_scadenza_mod_pag
IS 'siac_t_modpag.data_scadenza, siac_r_subdoc_modpag';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cod_sogg_mod_pag
IS 'siac_t_soggetto.soggetto_code dove soggetto_id=siac_t_modpag.soggetto_id tramite siac_r_subdoc_modpag se siac_r_subdoc_modpag .soggrelmpag_id is null  se  siac_r_subdoc_modpag .soggrelmpag_id is not null si tratta di cessione quindi siac_t_soggetto.soggetto_code dove soggetto_id=siac_r_soggetto_relaz.soggetto_id_a dove  siac_r_soggrel_modpag.soggrelmpag_id=siac_r_subdoc_modpag .soggrelmpag_id e  siac_r_soggrel_modpag.soggetto_relaz_id=soggetto_relaz_id ';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.tipo_sogg_mod_pag
IS 'siac_d_soggetto_tipo.soggetto_tipo_desc tramite siac_r_soggetto_tipo';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.stato_sogg_mod_pag
IS 'siac_t_soggetto_stato.soggetto_stato_desc tramite siac_r_soggetto_stato';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.rag_sociale_sogg_mod_pag
IS 'siac_t_persona_giuridica.ragione_sociale';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.p_iva_sogg_mod_pag
IS 'siac_t_soggetto.partita_iva';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cf_sogg_mod_pag
IS 'siac_t_soggetto.codice_fiscale';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cf_estero_sogg_mod_pag
IS 'siac_t_soggetto.codice_fiscale_estero';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.nome_sogg_mod_pag
IS 'siac_t_persona_fisica.nome';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.cognome_sogg_mod_pag
IS 'siac_t_persona_fisica.cognome';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.registro_repertorio
IS 'registro_repertorio siac_t_attr.attr_code=''registro_repertorio''(x coge)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.anno_repertorio
IS 'registro_repertorio siac_t_attr.attr_code=''anno_repertorio''(x coge)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.num_repertorio
IS 'registro_repertorio siac_t_attr.attr_code=''num_repertorio''(x coge)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_repertorio
IS 'registro_repertorio siac_t_attr.attr_code=''data_repertorio''(x coge)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.data_ricezione_portale
IS 'registro_repertorio siac_t_attr.attr_code=''dataRicezionePortale''(x coge)';

COMMENT ON COLUMN siac.siac_dwh_documento_spesa.doc_contabilizza_genpcc
IS 'siac_t_doc.doc_contabilizza_genpcc (x coge)';