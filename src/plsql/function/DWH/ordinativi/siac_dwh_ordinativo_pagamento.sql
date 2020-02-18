/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_ordinativo_pagamento (
  ente_proprietario_id INTEGER NOT NULL,
  ente_denominazione VARCHAR,
  bil_anno VARCHAR(4),
  cod_fase_operativa VARCHAR(200),
  desc_fase_operativa VARCHAR(500),
  anno_ord_pag INTEGER,
  num_ord_pag NUMERIC,
  desc_ord_pag VARCHAR(500),
  cod_stato_ord_pag VARCHAR(200),
  desc_stato_ord_pag VARCHAR(500),
  castelletto_cassa_ord_pag NUMERIC,
  castelletto_competenza_ord_pag NUMERIC,
  castelletto_emessi_ord_pag NUMERIC,
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
  cod_spesa_ricorrente VARCHAR(200),
  desc_spesa_ricorrente VARCHAR(500),
  cod_transazione_spesa_ue VARCHAR(200),
  desc_transazione_spesa_ue VARCHAR(500),
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
  data_inizio_val_stato_ordpg TIMESTAMP WITHOUT TIME ZONE,
  data_inizio_val_ordpg TIMESTAMP WITHOUT TIME ZONE,
  data_creazione_ordpg TIMESTAMP WITHOUT TIME ZONE,
  data_modifica_ordpg TIMESTAMP WITHOUT TIME ZONE,
  data_trasmissione TIMESTAMP WITHOUT TIME ZONE,
  cod_siope VARCHAR(50),
  desc_siope VARCHAR(500),
  tipo_cessione varchar(50), -- 04.07.2017 Sofia SIAC-5036
  cod_cessione varchar(100), -- 04.07.2017 Sofia SIAC-5036
  desc_cessione varchar(200), -- 04.07.2017 Sofia SIAC-5036
  soggetto_csc_id INTEGER,
  cod_siope_tipo_debito VARCHAR(200),
  desc_siope_tipo_debito VARCHAR(500),
  desc_siope_tipo_debito_bnkit VARCHAR(500),
  cod_siope_assenza_motivazione VARCHAR(200),
  desc_siope_assenza_motivazione VARCHAR(500),
  desc_siope_assenza_motiv_bnkit VARCHAR(500),
  ord_da_trasmettere boolean not null default true
)
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_fase_operativa
IS 'cod fase operativa bilancio (siac_d_fase_operativa.fase_operativa_code,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_fase_operativa
IS 'desc fase operativa bilancio (siac_d_fase_operativa.fase_operativa_desc,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.anno_ord_pag
IS 'siac_t_ordinativo.ord_anno con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.num_ord_pag
IS 'siac_t_ordinativo.ord_num con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_ord_pag
IS 'siac_t_ordinativo.ord_desc con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_stato_ord_pag
IS 'siac_d_ordinativo_stato.ord_stato_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_stato_ord_pag
IS 'siac_d_ordinativo_stato.ord_stato_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.castelletto_cassa_ord_pag
IS 'siac_t_ordinativo.ord_cast_cassa';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.castelletto_competenza_ord_pag
IS 'siac_t_ordinativo.ord_cast_competenza';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.castelletto_emessi_ord_pag
IS 'siac_t_ordinativo.ord_cast_emessi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.data_emissione
IS 'siac_t_ordinativo.ord_emissione_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.data_riduzione
IS 'siac_t_ordinativo.ord_riduzione_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.data_spostamento
IS 'siac_t_ordinativo.ord_spostamento_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.data_variazione
IS 'siac_t_ordinativo.ord_variazione_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.beneficiario_multiplo
IS 'siac_t_ordinativo_stato.ord_beneficiariomult';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_bollo
IS 'siac_d_codbollo.codbollo_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_cod_bollo
IS 'siac_d_codbollo.codbollo_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_tipo_commissione
IS 'siac_d_commissione_tipo.comm_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_tipo_commissione
IS 'siac_d_commissione_tipo.comm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_conto_tesoreria
IS 'siac_d_contotesoreria.contotes_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.decrizione_conto_tesoreria
IS 'siac_d_contotesoreria.contotes_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_distinta
IS 'siac_d_distinta.dist_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_distinta
IS 'siac_d_distinta.dist_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_soggetto
IS 'cod soggetto intestatario. se il soggetto è sede secondaria, bisogna recuperare il soggetto padre';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_soggetto
IS 'desc soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cf_soggetto
IS 'cod fiscale soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cf_estero_soggetto
IS 'cod fiscale estero soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.p_iva_soggetto
IS 'partita iva soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_soggetto_mod_pag
IS 'cod soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_soggetto_mod_pag
IS 'desc soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cf_soggetto_mod_pag
IS 'cod fiscale soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cf_estero_soggetto_mod_pag
IS 'cod fiscale estero soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.p_iva_soggetto_mod_pag
IS 'partita iva soggetto intestatario';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_tipo_accredito
IS 'siac_d_accredito_tipo.accredito_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_tipo_accredito
IS 'siac_d_accredito_tipo.accredito_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.quietanziante
IS 'siac_t_modpag.quietanziante';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.data_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.luogo_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_luogo';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.stato_nascita_quietanziante
IS 'siac_t_modpag.quietanziante_nascita_stato';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.bic
IS 'siac_t_modpag.bic';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.contocorrente
IS 'siac_t_modpag.contotcorrente';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.intestazione_contocorrente
IS 'siac_t_modpag.contotcorrente_intestazione';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.iban
IS 'siac_t_modpag.iban';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.note_mod_pag
IS 'siac_t_modpag.note';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.data_scadenza_mod_pag
IS 'siac_t_modpag.data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.anno_atto_amministrativo
IS 'siac_t_atto_amm_tipo.attoamm_anno, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.num_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_num, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.oggetto_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_oggetto, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.note_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_note, siac_r_liquidazione_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_tipo_avviso
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_tipo_avviso
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_spesa_ricorrente
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_spesa_ricorrente
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_transazione_spesa_ue
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_transazione_spesa_ue
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_pdc_finanziario_i
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_pdc_finanziario_i
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_pdc_finanziario_ii
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_pdc_finanziario_ii
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_pdc_finanziario_iii
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_pdc_finanziario_iii
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_pdc_finanziario_iv
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_pdc_finanziario_iv
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_pdc_finanziario_v
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_pdc_finanziario_v
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_pdc_economico_i
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_pdc_economico_i
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_pdc_economico_ii
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_pdc_economico_ii
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_pdc_economico_iii
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_pdc_economico_iii
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_pdc_economico_iv
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_pdc_economico_iv
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_pdc_economico_v
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_pdc_economico_v
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_cofog_divisione
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_cofog_divisione
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_cofog_gruppo
IS 'classificatore (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_cofog_gruppo
IS 'classificatore (siac_t_class.classif_desc,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.classificatore_1
IS 'classificatore cod (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.classificatore_2
IS 'classificatore cod (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.classificatore_3
IS 'classificatore cod (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.classificatore_4
IS 'classificatore cod (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.classificatore_5
IS 'classificatore cod (siac_t_class.classif_code,siac_r_ordinativo_class) i classificatori generici di ordinativo di incasso e di pagamento sono diversi';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.allegato_cartaceo
IS 'attributo boolean siac_t_attr, siac_r_ordinativo_attr flagAllegatoCartaceo';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.note
IS 'attributo testo siac_t_attr, siac_r_ordinativo_attr';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.importo_iniziale
IS 'siac_t_ordinativo_ts_det. ord_ts_det_importo dove siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code =''I''';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.importo_attuale
IS 'siac_t_ordinativo_ts_det. ord_ts_det_importo dove siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code =''A''';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.data_firma
IS 'siac_r_ordinativo_firma.ord_firma_data';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.firma
IS 'siac_r_ordinativo_firma.ord_firma';


-- 04.07.2017 Sofia SIAC-5036
COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.tipo_cessione
IS 'tipo_cessione incasso CSI/CSC';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_cessione
IS 'codice cessione di tipo tipo_cessione';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_cessione
IS 'descrizione cessione di tipo tipo_cessione';
-- 04.07.2017 Sofia SIAC-5036