/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_iva (
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  cod_doc_fam_tipo VARCHAR(200),
  desc_doc_fam_tipo VARCHAR(500),
  anno_doc INTEGER,
  num_doc VARCHAR(200),
  cod_tipo_doc VARCHAR(200),
  data_emissione_doc TIMESTAMP WITHOUT TIME ZONE,
  cod_sogg_doc VARCHAR(200),
  num_subdoc INTEGER,
  anno_subbdoc_iva VARCHAR(4),
  num_subdoc_iva INTEGER,
  data_registrazione_subdoc_iva TIMESTAMP WITHOUT TIME ZONE,
  cod_tipo_registrazione VARCHAR(200),
  desc_tipo_registrazione VARCHAR(500),
  cod_tipo_registro_iva VARCHAR(200),
  desc_tipo_registro_iva VARCHAR(500),
  cod_registro_iva VARCHAR(200),
  desc_registro_iva VARCHAR(500),
  cod_attivita VARCHAR(200),
  desc_attivita VARCHAR(500),
  prot_prov_subdoc_iva VARCHAR(200),
  data_prot_prov_subdoc_iva TIMESTAMP WITHOUT TIME ZONE,
  prot_def_subdoc_iva VARCHAR(200),
  data_prot_def_subdoc_iva TIMESTAMP WITHOUT TIME ZONE,
  cod_aliquota_iva VARCHAR(200),
  desc_aliquota_iva VARCHAR(500),
  perc_aliquota_iva NUMERIC,
  perc_indetr_aliquota_iva NUMERIC,
  imponibile NUMERIC,
  imposta NUMERIC,
  importo_detraibile NUMERIC,
  importo_indetraibile NUMERIC,
  cod_tipo_oprazione VARCHAR(200),
  desc_tipo_oprazione VARCHAR(200),
  cod_tipo_aliquota VARCHAR(200),
  desc_tipo_aliquota VARCHAR(500),
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  doc_id INTEGER
) 
WITH (oids = false);