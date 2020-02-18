/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_subordinativo_pagamento (
  ente_proprietario_id INTEGER NOT NULL,
  ente_denominazione VARCHAR(500),
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
  num_subord_pag VARCHAR(200),
  desc_subord_pag VARCHAR(500),
  data_esecuzione_pagamento TIMESTAMP WITHOUT TIME ZONE,
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
  anno_liquidazione INTEGER,
  num_liquidazione NUMERIC,
  desc_liquidazione VARCHAR(500),
  data_emissione_liquidazione TIMESTAMP WITHOUT TIME ZONE,
  importo_liquidazione NUMERIC,
  liquidazione_automatica VARCHAR(1),
  liquidazione_convalida_manuale VARCHAR(1),
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  cup VARCHAR(500),
  cig VARCHAR(500),
  data_inizio_val_stato_ordpg TIMESTAMP WITHOUT TIME ZONE,
  data_inizio_val_subordpg TIMESTAMP WITHOUT TIME ZONE,
  data_creazione_subordpg TIMESTAMP WITHOUT TIME ZONE,
  data_modifica_subordpg TIMESTAMP WITHOUT TIME ZONE,
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
  doc_id INTEGER
) 
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.cod_fase_operativa
IS 'cod fase operativa bilancio (siac_d_fase_operativa.fase_operativa_code,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.desc_fase_operativa
IS 'desc fase operativa bilancio (siac_d_fase_operativa.fase_operativa_desc,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.anno_ord_pag
IS 'siac_t_ordinativo.ord_anno con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.num_ord_pag
IS 'siac_t_ordinativo.ord_num con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.desc_ord_pag
IS 'siac_t_ordinativo.ord_desc con siac_d_ordinativo_tipo.ord_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.cod_stato_ord_pag
IS 'siac_d_ordinativo_stato.ord_stato_code';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.desc_stato_ord_pag
IS 'siac_d_ordinativo_stato.ord_stato_desc';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.castelletto_cassa_ord_pag
IS 'siac_t_ordinativo.ord_cast_cassa';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.castelletto_competenza_ord_pag
IS 'siac_t_ordinativo.ord_cast_competenza';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.castelletto_emessi_ord_pag
IS 'siac_t_ordinativo.ord_cast_emessi';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.data_emissione
IS 'siac_t_ordinativo.ord_emissione_data';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.data_riduzione
IS 'siac_t_ordinativo.ord_riduzione_data';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.data_spostamento
IS 'siac_t_ordinativo.ord_spostamento_data';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.data_variazione
IS 'siac_t_ordinativo.ord_variazione_data';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.beneficiario_multiplo
IS 'siac_t_ordinativo_stato.ord_beneficiariomult';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.num_subord_pag
IS 'siac_t_ordinativo_ts.ord_ts_code';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.desc_subord_pag
IS 'siac_t_ordinativo_ts.ord_ts_desc';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.data_esecuzione_pagamento
IS 'siac_t_ordinativo_ts.ord_ts_data_scadenza';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.importo_iniziale
IS 'siac_t_ordinativo_ts_det. ord_ts_det_importo dove siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code =''I''';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.importo_attuale
IS 'siac_t_ordinativo_ts_det. ord_ts_det_importo dove siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code =''A''';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.cod_onere
IS 'siac_d_onere.onere_code tramite siac_r_doc_onere_ordinativo_ts siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.desc_onere
IS 'siac_d_onere.onere_desc tramite siac_r_doc_onere_ordinativo_ts siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.cod_tipo_onere
IS 'siac_d_onere_tipo.onere_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.desc_tipo_onere
IS 'siac_d_onere_tipo.onere_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.importo_carico_ente
IS 'siac_r_doc_onere.importo_carico_ente';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.importo_carico_soggetto
IS 'siac_r_doc_onere.importo_carico_soggetto';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.importo_imponibile
IS 'siac_r_doc_onere.importo_imponibile';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.inizio_attivita
IS 'siac_r_doc_onere.attivita_inizio';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.fine_attivita
IS 'siac_r_doc_onere.attivita_fine';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.cod_causale
IS 'siac_d_causale.caus_code tramite siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.desc_causale
IS 'siac_d_causale.caus_desc tramite siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.cod_attivita_onere
IS 'siac_d_onere_attivita.onere_att_code tramite siac_r_doc_onere';

COMMENT ON COLUMN siac.siac_dwh_subordinativo_pagamento.desc_attivita_onere
IS 'siac_d_onere_attivita.onere_att_desc tramite siac_r_doc_onere';