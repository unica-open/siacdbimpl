/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.bilarm_tracciato_temp (
  elab_id_temp INTEGER NOT NULL,
  elab_id_det_temp INTEGER NOT NULL,
  ente_proprietario_id INTEGER,
  anno VARCHAR,
  elem_id INTEGER,
  elem_code VARCHAR,
  elem_cat_code VARCHAR,
  cod_aggregazione VARCHAR,
  desc_aggregazione VARCHAR,
  elem_det_tipo_code VARCHAR,
  elem_tipo_code VARCHAR,
  importo_capitolo NUMERIC,
  importo_cassa NUMERIC,
  importo_impegnato NUMERIC,
  importo_fondo_vincolato NUMERIC,
  CONSTRAINT bilarm_tracciato_temp_pkey PRIMARY KEY(elab_id_temp, elab_id_det_temp)
) 
WITH (oids = false);