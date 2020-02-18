/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_vincolo (
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  bil_anno VARCHAR(4),
  cod_vincolo VARCHAR(200),
  desc_vincolo VARCHAR(500),
  cod_stato_vincolo VARCHAR(200),
  desc_stato_vincolo VARCHAR(500),
  cod_genere_vincolo VARCHAR(200),
  desc_genere_vincolo VARCHAR(500),
  cod_capitolo VARCHAR(200),
  cod_articolo VARCHAR(200),
  cod_ueb VARCHAR(200),
  desc_capitolo VARCHAR,
  desc_articolo VARCHAR,
  cod_tipo_capitolo VARCHAR(200),
  desc_tipo_capitolo VARCHAR(500),
  cod_stato_capitolo VARCHAR(200),
  desc_stato_capitolo VARCHAR(500),
  cod_classificazione_capitolo VARCHAR(200),
  desc_classificazione_capitolo VARCHAR(500),
  flagtrasferimentivincolati VARCHAR(1),
  note VARCHAR
) 
WITH (oids = false);