/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_liquidazione (
  ente_proprietario_id INTEGER NOT NULL,
  ente_denominazione VARCHAR(500),
  bil_anno VARCHAR(4),
  cod_fase_operativa VARCHAR(200),
  desc_fase_operativa VARCHAR(500),
  anno_liquidazione INTEGER,
  num_liquidazione NUMERIC,
  desc_liquidazione VARCHAR(500),
  data_emissione_liquidazione TIMESTAMP WITHOUT TIME ZONE,
  importo_liquidazione NUMERIC,
  liquidazione_automatica VARCHAR(1),
  liquidazione_convalida_manuale VARCHAR(1),
  cod_stato_liquidazione VARCHAR(200),
  desc_stato_liquidazione VARCHAR(500),
  cod_conto_tesoreria VARCHAR(200),
  decrizione_conto_tesoreria VARCHAR(500),
  cod_distinta VARCHAR(200),
  desc_distinta VARCHAR(500),
  soggetto_id INTEGER,
  cod_soggetto VARCHAR(200),
  desc_soggetto VARCHAR(500),
  cf_soggetto CHAR(16),
  cf_estero_soggetto VARCHAR(500),
  p_iva_soggetto VARCHAR(500),
  soggetto_id_mod_pag INTEGER,
  cod_soggetto_mod_pag VARCHAR(200),
  desc_soggetto_mod_pag VARCHAR(500),
  cf_soggetto_mod_pag CHAR(16),
  cf_estero_soggetto_mod_pag VARCHAR(500),
  p_iva_soggetto_mod_pag VARCHAR(500),
  cod_tipo_accredito VARCHAR(200),
  desc_tipo_accredito VARCHAR(500),
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
  anno_impegno INTEGER,
  num_impegno NUMERIC,
  cod_impegno VARCHAR(200),
  desc_impegno VARCHAR(500),
  cod_subimpegno VARCHAR(200),
  desc_subimpegno VARCHAR(500),
  cod_tipo_atto_amministrativo VARCHAR(200),
  desc_tipo_atto_amministrativo VARCHAR(500),
  desc_stato_atto_amministrativo VARCHAR(500),
  anno_atto_amministrativo VARCHAR(4),
  num_atto_amministrativo VARCHAR(500),
  oggetto_atto_amministrativo VARCHAR(500),
  note_atto_amministrativo VARCHAR,
  cod_spesa_ricorrente VARCHAR(200),
  desc_spesa_ricorrente VARCHAR(500),
  cod_perimetro_sanita_spesa VARCHAR(200),
  desc_perimetro_sanita_spesa VARCHAR(500),
  cod_politiche_regionali_unit VARCHAR(200),
  desc_politiche_regionali_unit VARCHAR(500),
  cod_transazione_ue_spesa VARCHAR(200),
  desc_transazione_ue_spesa VARCHAR(500),
  cod_pdc_finanziario_i VARCHAR(200),
  desc_pdc_finanziario_i VARCHAR(500),
  cod_pdc_finanziario_ii VARCHAR(200),
  desc_pdc_finanziario_ii VARCHAR(500),
  cod_pdc_finanziario_iii VARCHAR(200),
  desc_pdc_finanziario_iii VARCHAR(500),
  cod_pdc_finanziario_iv VARCHAR(200),
  desc_pdc_finanziario_iv VARCHAR(500),
  cod_pdc_finanziario_v VARCHAR(200),
  desc_pdc_finanziario_v VARCHAR(500),
  cod_pdc_economico_i VARCHAR(200),
  desc_pdc_economico_i VARCHAR(500),
  cod_pdc_economico_ii VARCHAR(200),
  desc_pdc_economico_ii VARCHAR(500),
  cod_pdc_economico_iii VARCHAR(200),
  desc_pdc_economico_iii VARCHAR(500),
  cod_pdc_economico_iv VARCHAR(200),
  desc_pdc_economico_iv VARCHAR(500),
  cod_pdc_economico_v VARCHAR(200),
  desc_pdc_economico_v VARCHAR(500),
  cod_cofog_divisione VARCHAR(200),
  desc_cofog_divisione VARCHAR(500),
  cod_cofog_gruppo VARCHAR(200),
  desc_cofog_gruppo VARCHAR(500),
  cup VARCHAR(500),
  cig VARCHAR(500),
  cod_cdr_atto_amministrativo VARCHAR(200),
  desc_cdr_atto_amministrativo VARCHAR(500),
  cod_cdc_atto_amministrativo VARCHAR(200),
  desc_cdc_atto_amministrativo VARCHAR(500),
  tipo_cessione varchar(50), -- Sofia 04.07.2017 JIRA-SIAC-5040
  cod_cessione varchar(100), -- Sofia 04.07.2017 JIRA-SIAC-5040
  desc_cessione varchar(200), -- Sofia 04.07.2017 JIRA-SIAC-5040
  soggetto_csc_id INTEGER,
  cod_siope_tipo_debito VARCHAR(200),
  desc_siope_tipo_debito VARCHAR(500),
  desc_siope_tipo_debito_bnkit VARCHAR(500),
  cod_siope_assenza_motivazione VARCHAR(200),
  desc_siope_assenza_motivazione VARCHAR(500),
  desc_siope_assenza_motiv_bnkit VARCHAR(500)  
)
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_fase_operativa
IS 'cod fase operativa bilancio (siac_d_fase_operativa.fase_operativa_code,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_fase_operativa
IS 'desc fase operativa bilancio (siac_d_fase_operativa.fase_operativa_desc,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.anno_liquidazione
IS 'siac_t_liquidazione.liq_anno';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.num_liquidazione
IS 'siac_t_liquidazione.liq_num';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_liquidazione
IS 'siac_t_liquidazione.liq_desc';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.data_emissione_liquidazione
IS 'siac_t_liquidazione.liq_emissione_data';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.importo_liquidazione
IS 'siac_t_liquidazione.liq_importo';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.liquidazione_automatica
IS 'siac_t_liquidazione.liq_automatica';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.liquidazione_convalida_manuale
IS 'siac_t_liquidazione.liq_convalida_manuale';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_stato_liquidazione
IS 'siac_d_liquidazione_stato.liq_stato_code';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_stato_liquidazione
IS 'siac_d_liquidazione_stato.liq_stato_desc';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_conto_tesoreria
IS 'siac_d_contotesoreria.contotes_code';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.decrizione_conto_tesoreria
IS 'siac_d_contotesoreria.contotes_desc';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_distinta
IS 'siac_d_distinta.dist_code';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_distinta
IS 'siac_d_distinta.dist_desc';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_soggetto
IS 'cod soggetto intestatario. se il soggetto Ã¨ sede secondaria, bisogna recuperare il soggetto padre';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_soggetto
IS 'desc soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cf_soggetto
IS 'cod fiscale soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cf_estero_soggetto
IS 'cod fiscale estero soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.p_iva_soggetto
IS 'partita iva soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_soggetto_mod_pag
IS 'cod soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_soggetto_mod_pag
IS 'desc soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cf_soggetto_mod_pag
IS 'cod fiscale soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cf_estero_soggetto_mod_pag
IS 'cod fiscale estero soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.p_iva_soggetto_mod_pag
IS 'partita iva soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_tipo_accredito
IS 'siac_d_accredito_tipo.accredito_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_tipo_accredito
IS 'siac_d_accredito_tipo.accredito_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.quietanziante
IS 'siac_t_modpag.quietanziante';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.data_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_data';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.luogo_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_luogo';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.stato_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_stato';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.bic
IS 'siac_t_modpag.bic';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.contocorrente
IS 'siac_t_modpag.contotcorrente';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.intestazione_contocorrente
IS 'siac_t_modpag.contotcorrente_intestazione';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.iban
IS 'siac_t_modpag.iban';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.note_mod_pag
IS 'siac_t_modpag.note';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.data_scadenza_mod_pag
IS 'siac_t_modpag.data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.anno_impegno
IS 'siac_t_movgest';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.num_impegno
IS 'siac_t_movgest';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_impegno
IS 'siac_t_movgest_ts con movgest_ts_tipo=''T''';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_impegno
IS 'siac_t_movgest_ts con movgest_ts_tipo=''T''';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_subimpegno
IS 'siac_t_movgest_ts con movgest_ts_tipo=''S''';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_subimpegno
IS 'siac_t_movgest_ts con movgest_ts_tipo=''S''';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_stato_atto_amministrativo
IS 'siac_d_atto_amm_stato.attoamm_stato_desc';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.anno_atto_amministrativo
IS 'siac_t_atto_amm_tipo.attoamm_anno, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.num_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_num, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.oggetto_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_oggetto, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.note_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_note, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_spesa_ricorrente
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_spesa_ricorrente
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_perimetro_sanita_spesa
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_perimetro_sanita_spesa
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_politiche_regionali_unit
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_politiche_regionali_unit
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_transazione_ue_spesa
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_transazione_ue_spesa
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_pdc_finanziario_i
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_pdc_finanziario_i
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_pdc_finanziario_ii
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_pdc_finanziario_ii
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_pdc_finanziario_iii
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_pdc_finanziario_iii
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_pdc_finanziario_iv
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_pdc_finanziario_iv
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_pdc_finanziario_v
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_pdc_finanziario_v
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_pdc_economico_i
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_pdc_economico_i
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_pdc_economico_ii
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_pdc_economico_ii
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_pdc_economico_iii
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_pdc_economico_iii
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_pdc_economico_iv
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_pdc_economico_iv
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_pdc_economico_v
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_pdc_economico_v
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_cofog_divisione
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_cofog_divisione
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_cofog_gruppo
IS 'classificatore siac_t_class.classif_code siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_cofog_gruppo
IS 'classificatore siac_t_class.classif_desc siac_r_liquidazione_class';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cup
IS 'attributo';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cig
IS 'attributo';

-- Sofia 04.07.2017 JIRA-SIAC-5040
COMMENT ON COLUMN siac.siac_dwh_liquidazione.tipo_cessione
IS 'tipo cessione CSI/CSC';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_cessione
IS 'codice della cessione del tipo tipo_cessione';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_cessione
IS 'descrizione della cessione del tipo tipo_cessione';
-- Sofia 04.07.2017 JIRA-SIAC-5040


