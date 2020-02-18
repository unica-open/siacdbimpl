/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_clearo_impegnato_quietanzato (
  ente_proprietario_id INTEGER,
  anno_bilancio VARCHAR(4),
  anno_atto_amministrativo VARCHAR(4),
  num_atto_amministrativo VARCHAR(200),
  oggetto_atto_amministrativo VARCHAR(500),
  note_atto_amministrativo VARCHAR(500),
  cod_tipo_atto_amministrativo VARCHAR(200),
  desc_tipo_atto_amministrativo VARCHAR(500),
  desc_stato_atto_amministrativo VARCHAR(500),
  anno_impegno INTEGER,
  num_impegno NUMERIC,
  impegnato NUMERIC,
  quietanzato NUMERIC,
  cod_soggetto VARCHAR(200),
  desc_soggetto VARCHAR(500),
  cf_soggetto CHAR(16),
  cf_estero_soggetto VARCHAR(500),
  p_iva_soggetto VARCHAR(500),
  cod_classe_soggetto VARCHAR(200),
  desc_classe_soggetto VARCHAR(500),
  tipo_impegno VARCHAR(200),
  tipo_importo CHAR(1),
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
) 
WITH (oids = false);