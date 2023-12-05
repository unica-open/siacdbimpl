/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE TABLE siac.siac_dwh_ordinativo_incasso (
  ente_proprietario_id INTEGER NOT NULL,
  ente_denominazione VARCHAR(500),
  bil_anno VARCHAR(4),
  cod_fase_operativa VARCHAR(200),
  desc_fase_operativa VARCHAR(500),
  anno_ord_inc INTEGER,
  num_ord_inc NUMERIC,
  desc_ord_inc VARCHAR(500),
  cod_stato_ord_inc VARCHAR(200),
  desc_stato_ord_inc VARCHAR(500),
  castelletto_cassa_ord_inc NUMERIC,
  castelletto_competenza_ord_inc NUMERIC,
  castelletto_emessi_ord_inc NUMERIC,
  data_emissione TIMESTAMP WITHOUT TIME ZONE,
  data_riduzione TIMESTAMP WITHOUT TIME ZONE,
  data_spostamento TIMESTAMP WITHOUT TIME ZONE,
  data_variazione TIMESTAMP WITHOUT TIME ZONE,
  beneficiario_multiplo VARCHAR(1),
  cod_bollo VARCHAR(200),
  desc_cod_bollo VARCHAR(500),
  cod_tipo_commissione VARCHAR(200),
  desc_tipo_commissione VARCHAR(500),
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
  cod_tipo_atto_amministrativo VARCHAR(200),
  desc_tipo_atto_amministrativo VARCHAR(500),
  desc_stato_atto_amministrativo VARCHAR(500),
  anno_atto_amministrativo VARCHAR(4),
  num_atto_amministrativo VARCHAR(500),
  oggetto_atto_amministrativo VARCHAR(500),
  note_atto_amministrativo VARCHAR,
  cod_tipo_avviso VARCHAR(200),
  desc_tipo_avviso VARCHAR(500),
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
  classificatore_1 VARCHAR(500),
  classificatore_1_valore VARCHAR(200),
  classificatore_1_desc_valore VARCHAR(500),
  classificatore_2 VARCHAR(500),
  classificatore_2_valore VARCHAR(200),
  classificatore_2_desc_valore VARCHAR(500),
  classificatore_3 VARCHAR(500),
  classificatore_3_valore VARCHAR(200),
  classificatore_3_desc_valore VARCHAR(500),
  classificatore_4 VARCHAR(500),
  classificatore_4_valore VARCHAR(200),
  classificatore_4_desc_valore VARCHAR(500),
  classificatore_5 VARCHAR(500),
  classificatore_5_valore VARCHAR(200),
  classificatore_5_desc_valore VARCHAR(500),
  allegato_cartaceo VARCHAR(1),
  cup VARCHAR(500),
  note VARCHAR,
  cod_capitolo VARCHAR(200),
  cod_articolo VARCHAR(200),
  cod_ueb VARCHAR(200),
  desc_capitolo VARCHAR,
  desc_articolo VARCHAR,
  desc_ueb VARCHAR,
  importo_iniziale NUMERIC,
  importo_attuale NUMERIC,
  cod_cdr_atto_amministrativo VARCHAR(200),
  desc_cdr_atto_amministrativo VARCHAR(500),
  cod_cdc_atto_amministrativo VARCHAR(200),
  desc_cdc_atto_amministrativo VARCHAR(500),
  data_firma TIMESTAMP WITHOUT TIME ZONE,
  firma VARCHAR(200),
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  data_inizio_val_stato_ordin TIMESTAMP WITHOUT TIME ZONE,
  data_inizio_val_ordin TIMESTAMP WITHOUT TIME ZONE,
  data_creazione_ordin TIMESTAMP WITHOUT TIME ZONE,
  data_modifica_ordin TIMESTAMP WITHOUT TIME ZONE,
  data_trasmissione TIMESTAMP WITHOUT TIME ZONE,
  cod_siope VARCHAR(50),
  desc_siope VARCHAR(500),
  caus_id INTEGER,
  cod_causale VARCHAR(200),
  desc_causale VARCHAR(200),
  cod_tipo_causale VARCHAR(200),
  desc_tipo_causale VARCHAR(200),
  ord_da_trasmettere boolean not null default true,
  --  23.01.2023 Sofia Jira 	SIAC-8762
  cod_conto_tes_vincolato VARCHAR(200),
  descri_conto_tes_vincolato VARCHAR(500)
)
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_fase_operativa
IS 'cod fase operativa bilancio (siac_d_fase_operativa.fase_operativa_code,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_fase_operativa
IS 'desc fase operativa bilancio (siac_d_fase_operativa.fase_operativa_desc,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.anno_ord_inc
IS 'siac_t_ordinativo.ord_anno con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.num_ord_inc
IS 'siac_t_ordinativo.ord_num con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_ord_inc
IS 'siac_t_ordinativo.ord_desc con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_stato_ord_inc
IS 'siac_d_ordinativo_stato.ord_stato_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_stato_ord_inc
IS 'siac_d_ordinativo_stato.ord_stato_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.castelletto_cassa_ord_inc
IS 'siac_t_ordinativo.ord_cast_cassa';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.castelletto_competenza_ord_inc
IS 'siac_t_ordinativo.ord_cast_competenza';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.castelletto_emessi_ord_inc
IS 'siac_t_ordinativo.ord_cast_emessi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.data_emissione
IS 'siac_t_ordinativo.ord_emissione_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.data_riduzione
IS 'siac_t_ordinativo.ord_riduzione_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.data_spostamento
IS 'siac_t_ordinativo.ord_spostamento_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.data_variazione
IS 'siac_t_ordinativo.ord_variazione_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.beneficiario_multiplo
IS 'siac_t_ordinativo_stato.ord_beneficiariomult';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_bollo
IS 'siac_d_codbollo.codbollo_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_cod_bollo
IS 'siac_d_codbollo.codbollo_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_tipo_commissione
IS 'siac_d_commissione_tipo.comm_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_tipo_commissione
IS 'siac_d_commissione_tipo.comm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_conto_tesoreria
IS 'siac_d_contotesoreria.contotes_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.decrizione_conto_tesoreria
IS 'siac_d_contotesoreria.contotes_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_distinta
IS 'siac_d_distinta.dist_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_distinta
IS 'siac_d_distinta.dist_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_soggetto
IS 'cod soggetto intestatario. se il soggetto è sede secondaria, bisogna recuperare il soggetto padre';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_soggetto
IS 'desc soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cf_soggetto
IS 'cod fiscale soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cf_estero_soggetto
IS 'cod fiscale estero soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.p_iva_soggetto
IS 'partita iva soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_soggetto_mod_pag
IS 'cod soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_soggetto_mod_pag
IS 'desc soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cf_soggetto_mod_pag
IS 'cod fiscale soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cf_estero_soggetto_mod_pag
IS 'cod fiscale estero soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.p_iva_soggetto_mod_pag
IS 'partita iva soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_tipo_accredito
IS 'siac_d_accredito_tipo.accredito_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_tipo_accredito
IS 'siac_d_accredito_tipo.accredito_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.quietanziante
IS 'siac_t_modpag.quietanziante';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.data_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.luogo_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_luogo';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.stato_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_stato';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.bic
IS 'siac_t_modpag.bic';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.contocorrente
IS 'siac_t_modpag.contotcorrente';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.intestazione_contocorrente
IS 'siac_t_modpag.contotcorrente_intestazione';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.iban
IS 'siac_t_modpag.iban';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.note_mod_pag
IS 'siac_t_modpag.note';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.data_scadenza_mod_pag
IS 'siac_t_modpag.data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.anno_atto_amministrativo
IS 'siac_t_atto_amm_tipo.attoamm_anno, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.num_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_num, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.oggetto_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_oggetto, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.note_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_note, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_tipo_avviso
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_tipo_avviso
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_pdc_finanziario_i
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_pdc_finanziario_i
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_pdc_finanziario_ii
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_pdc_finanziario_ii
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_pdc_finanziario_iii
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_pdc_finanziario_iii
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_pdc_finanziario_iv
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_pdc_finanziario_iv
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_pdc_finanziario_v
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_pdc_finanziario_v
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_pdc_economico_i
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_pdc_economico_i
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_pdc_economico_ii
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_pdc_economico_ii
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_pdc_economico_iii
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_pdc_economico_iii
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_pdc_economico_iv
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_pdc_economico_iv
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_pdc_economico_v
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_pdc_economico_v
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_cofog_divisione
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_cofog_divisione
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cod_cofog_gruppo
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.desc_cofog_gruppo
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.classificatore_1
IS 'classificatore cod (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.classificatore_2
IS 'classificatore cod (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.classificatore_3
IS 'classificatore cod (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.classificatore_4
IS 'classificatore cod (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.classificatore_5
IS 'classificatore cod (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.allegato_cartaceo
IS 'attributo boolean siac_t_attr, siac_r_ordinativo_attr';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.cup
IS 'attributo test siac_t_attr, siac_r_ordinativo_attr';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.note
IS 'attributo testo siac_t_attr, siac_r_ordinativo_attr';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.importo_iniziale
IS 'siac_t_ordinativo_ts_det. ord_ts_det_importo dove siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code =''I''';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.importo_attuale
IS 'siac_t_ordinativo_ts_det. ord_ts_det_importo dove siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code =''A''';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.data_firma
IS 'siac_r_ordinativo_firma.ord_firma_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_incasso.firma
IS 'siac_r_ordinativo_firma.ord_firma';