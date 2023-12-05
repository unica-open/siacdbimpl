/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE TABLE siac.siac_dwh_subordinativo_incasso (
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
  num_subord_inc VARCHAR(200),
  desc_subord_inc VARCHAR(500),
  data_scadenza TIMESTAMP WITHOUT TIME ZONE,
  importo_iniziale NUMERIC,
  importo_attuale NUMERIC,
  cod_onere VARCHAR(200),
  desc_onere VARCHAR(500),
  cod_tipo_onere VARCHAR(200),
  desc_tipo_onere VARCHAR(500),
  importo_carico_ente NUMERIC,
  importo_carico_soggetto NUMERIC,
  importo_imponibile NUMERIC,
  inizio_attivita TIMESTAMP WITHOUT TIME ZONE,
  fine_attivita TIMESTAMP WITHOUT TIME ZONE,
  cod_causale VARCHAR(200),
  desc_causale VARCHAR(500),
  cod_attivita_onere VARCHAR(200),
  desc_attivita_onere VARCHAR(500),
  anno_accertamento INTEGER,
  num_accertamento NUMERIC,
  desc_accertamento VARCHAR(500),
  cod_subaccertamento VARCHAR(200),
  importo_quietanziato NUMERIC,
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  data_inizio_val_stato_ordin TIMESTAMP WITHOUT TIME ZONE,
  data_inizio_val_subordin TIMESTAMP WITHOUT TIME ZONE,
  data_creazione_subordin TIMESTAMP WITHOUT TIME ZONE,
  data_modifica_subordin TIMESTAMP WITHOUT TIME ZONE,
  cod_gruppo_doc VARCHAR(200),
  desc_gruppo_doc VARCHAR(500),
  cod_famiglia_doc VARCHAR(200),
  desc_famiglia_doc VARCHAR(500),
  cod_tipo_doc VARCHAR(200),
  desc_tipo_doc VARCHAR(500),
  anno_doc INTEGER,
  num_doc VARCHAR(200),
  num_subdoc INTEGER,
  cod_sogg_doc VARCHAR(200),
  caus_id INTEGER,
  doc_id INTEGER,
  cod_causale_ord VARCHAR(200),
  desc_causale_ord VARCHAR(200),
  cod_tipo_causale_ord VARCHAR(200),
  desc_tipo_causale_ord VARCHAR(200)
)
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.cod_fase_operativa
IS 'cod fase operativa bilancio (siac_d_fase_operativa.fase_operativa_code,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.desc_fase_operativa
IS 'desc fase operativa bilancio (siac_d_fase_operativa.fase_operativa_desc,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.anno_ord_inc
IS 'siac_t_ordinativo.ord_anno con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.num_ord_inc
IS 'siac_t_ordinativo.ord_num con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.desc_ord_inc
IS 'siac_t_ordinativo.ord_desc con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.cod_stato_ord_inc
IS 'siac_d_ordinativo_stato.ord_stato_code';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.desc_stato_ord_inc
IS 'siac_d_ordinativo_stato.ord_stato_desc';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.castelletto_cassa_ord_inc
IS 'siac_t_ordinativo.ord_cast_cassa';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.castelletto_competenza_ord_inc
IS 'siac_t_ordinativo.ord_cast_competenza';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.castelletto_emessi_ord_inc
IS 'siac_t_ordinativo.ord_cast_emessi';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.data_emissione
IS 'siac_t_ordinativo.ord_emissione_data';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.data_riduzione
IS 'siac_t_ordinativo.ord_riduzione_data';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.data_spostamento
IS 'siac_t_ordinativo.ord_spostamento_data';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.data_variazione
IS 'siac_t_ordinativo.ord_variazione_data';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.beneficiario_multiplo
IS 'siac_t_ordinativo_stato.ord_beneficiariomult';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.num_subord_inc
IS 'siac_t_ordinativo_ts.ord_ts_code';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.desc_subord_inc
IS 'siac_t_ordinativo_ts.ord_ts_desc';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.data_scadenza
IS 'siac_t_ordinativo_ts.ord_ts_data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.importo_iniziale
IS 'siac_t_ordinativo_ts_det. ord_ts_det_importo dove siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code =''I''';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.importo_attuale
IS 'siac_t_ordinativo_ts_det. ord_ts_det_importo dove siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code =''A''';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.cod_onere
IS 'siac_d_onere.onere_code tramite siac_r_doc_onere_ordinativo_ts siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.desc_onere
IS 'siac_d_onere.onere_desc tramite siac_r_doc_onere_ordinativo_ts siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.cod_tipo_onere
IS 'siac_d_onere_tipo.onere_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.desc_tipo_onere
IS 'siac_d_onere_tipo.onere_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.importo_carico_ente
IS 'siac_r_doc_onere.importo_carico_ente';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.importo_carico_soggetto
IS 'siac_r_doc_onere.importo_carico_soggetto';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.importo_imponibile
IS 'siac_r_doc_onere.importo_imponibile';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.inizio_attivita
IS 'siac_r_doc_onere.attivita_inizio';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.fine_attivita
IS 'siac_r_doc_onere.attivita_fine';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.cod_causale
IS 'siac_d_causale.caus_code tramite siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.desc_causale
IS 'siac_d_causale.caus_desc tramite siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.cod_attivita_onere
IS 'siac_d_onere_attivita.onere_att_code tramite siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.desc_attivita_onere
IS 'siac_d_onere_attivita.onere_att_desc tramite siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.anno_accertamento
IS 'siac_t_movgest.movgest_anno tramite siac_r_ordinativo_ts_movgest_ts';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.num_accertamento
IS 'siac_t_movgest.movgest_num tramite siac_r_ordinativo_ts_movgest_ts';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.desc_accertamento
IS 'siac_t_movgest.movgest_desc tramite siac_r_ordinativo_ts_movgest_ts';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_incasso.cod_subaccertamento
IS 'siac_t_movgest_ts.movgest_ts_code tramite siac_r_ordinativo_ts_movgest_ts';