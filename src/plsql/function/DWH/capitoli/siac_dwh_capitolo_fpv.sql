/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table siac_dwh_capitolo_fpv
CREATE TABLE siac_dwh_capitolo_fpv
(
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  data_elaborazione       TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  bil_anno VARCHAR(4),
  cod_capitolo VARCHAR(200),
  cod_articolo VARCHAR(200),
  cod_ueb VARCHAR(200),
  desc_capitolo VARCHAR,
  desc_articolo VARCHAR,
  cod_tipo_capitolo VARCHAR(200),
  desc_tipo_capitolo VARCHAR(500),
  cod_capitolo_fpv VARCHAR(200),
  cod_articolo_fpv VARCHAR(200),
  cod_ueb_fpv VARCHAR(200),
  desc_capitolo_fpv VARCHAR,
  desc_articolo_fpv VARCHAR,
  cod_tipo_capitolo_fpv VARCHAR(200),
  desc_tipo_capitolo_fpv VARCHAR(500),
  cod_tipo_fpv varchar(200),
  desc_tipo_fpv varchar(200),
  importo_fpv numeric
)
WITH (oids = false);