/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE TABLE siac.siac_dwh_contabilita_generale (
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  bil_anno VARCHAR(4),
  desc_prima_nota VARCHAR(500),
  num_provvisorio_prima_nota INTEGER,
  num_definitivo_prima_nota INTEGER,
  data_registrazione_prima_nota TIMESTAMP WITHOUT TIME ZONE,
  cod_stato_prima_nota VARCHAR(200),
  desc_stato_prima_nota VARCHAR(500),
  cod_mov_ep VARCHAR(200),
  desc_mov_ep VARCHAR(500),
  cod_mov_ep_dettaglio VARCHAR(200),
  desc_mov_ep_dettaglio VARCHAR(500),
  importo_mov_ep NUMERIC,
  segno_mov_ep VARCHAR(40),
  cod_piano_dei_conti VARCHAR(200),
  desc_piano_dei_conti VARCHAR(500),
  livello_piano_dei_conti INTEGER,
  ordine_piano_dei_conti VARCHAR,
  cod_pdce_fam VARCHAR(200),
  desc_pdce_fam VARCHAR(500),
  cod_ambito VARCHAR(200),
  desc_ambito VARCHAR(500),
  cod_causale VARCHAR(200),
  desc_causale VARCHAR(500),
  cod_tipo_causale VARCHAR(200),
  desc_tipo_causale VARCHAR(500),
  cod_stato_causale VARCHAR(200),
  desc_stato_causale VARCHAR(500),
  cod_evento VARCHAR(200),
  desc_evento VARCHAR(500),
  cod_tipo_mov_finanziario VARCHAR(200),
  desc_tipo_mov_finanziario VARCHAR(500),
  cod_piano_finanziario VARCHAR(200),
  desc_piano_finanziario VARCHAR(500),
  anno_movimento INTEGER,
  numero_movimento NUMERIC,
  cod_submovimento VARCHAR(200),
  anno_ordinativo INTEGER,
  num_ordinativo NUMERIC,
  num_subordinativo VARCHAR(200),
  anno_liquidazione INTEGER,
  num_liquidazione NUMERIC,
  anno_doc INTEGER,
  num_doc VARCHAR(200),
  cod_tipo_doc VARCHAR(200),
  data_emissione_doc TIMESTAMP WITHOUT TIME ZONE,
  cod_sogg_doc VARCHAR(200),
  num_subdoc INTEGER,
  modifica_impegno VARCHAR(1),
  entrate_uscite VARCHAR(1),
  cod_bilancio VARCHAR(200),
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  numero_ricecon INTEGER,
  tipo_evento VARCHAR(200),
  doc_id INTEGER
)
WITH (oids = false);