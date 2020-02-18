/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_programma (
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  cod_programma VARCHAR(200),
  desc_programma VARCHAR(500),
  data_aggiudicazione_gara_progr TIMESTAMP WITHOUT TIME ZONE,
  data_indizione_gara_progr TIMESTAMP WITHOUT TIME ZONE,
  investimento_in_def_progr BOOLEAN DEFAULT false,
  cod_stato_programma VARCHAR(200),
  desc_stato_programma VARCHAR(500),
  cod_tipo_ambito VARCHAR(200),
  desc_tipo_ambito VARCHAR(500),
  flagrilevante_fpv VARCHAR(1),
  valorecomplessivoprogramma NUMERIC,
  note VARCHAR,
  anno_atto_amministrativo VARCHAR(4),
  num_atto_amministrativo VARCHAR(500),
  oggetto_atto_amministrativo VARCHAR(500),
  note_atto_amministrativo VARCHAR,
  cod_tipo_atto_amministrativo VARCHAR(200),
  desc_tipo_atto_amministrativo VARCHAR(500),
  desc_stato_atto_amministrativo VARCHAR(500),
  cod_cdr_atto_amministrativo VARCHAR(200),
  desc_cdr_atto_amministrativo VARCHAR(500),
  cod_cdc_atto_amministrativo VARCHAR(200),
  desc_cdc_atto_amministrativo VARCHAR(500),
  -- siac-6255 Sofia 29.04.2019
  programma_anno_bilancio      VARCHAR(4),
  programma_responsabile_unico VARCHAR(500),
  programma_spazi_finanziari   boolean,
  programma_affidamento_code   VARCHAR(200),
  programma_affidamento_desc   VARCHAR(500),
  programma_tipo_code          VARCHAR(200),
  programma_tipo_desc          VARCHAR(500),
  programma_sac_tipo           VARCHAR(200),
  programma_sac_code           VARCHAR(500),
  programma_sac_desc           VARCHAR(500),
  programma_cup                 VARCHAR(200)
)
WITH (oids = false);