/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop TABLE fase_bil_t_reimputazione;

CREATE TABLE fase_bil_t_reimputazione (
  reimputazione_id SERIAL,
  faseBilElabId integer not null,
  bil_id INTEGER NOT NULL,
  elemId_old integer,
  elem_code VARCHAR(200) NOT NULL,
  elem_code2 VARCHAR(200) NOT NULL,
  elem_code3 VARCHAR(200),
  elem_tipo_code VARCHAR(20),
  movgest_id INTEGER,
  movgest_anno INTEGER NOT NULL,
  movgest_numero NUMERIC NOT NULL,
  movgest_desc VARCHAR(500),
  movgest_tipo_id INTEGER NOT NULL,
  parere_finanziario BOOLEAN DEFAULT false NOT NULL,
  parere_finanziario_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  parere_finanziario_login_operazione VARCHAR(200),
  movgest_ts_id INTEGER,
  movgest_ts_code VARCHAR(200) NOT NULL,
  movgest_ts_desc VARCHAR(500),
  movgest_ts_tipo_id INTEGER NOT NULL,
  movgest_ts_id_padre INTEGER,
  ordine VARCHAR(200),
  livello INTEGER NOT NULL,
  movgest_ts_scadenza_data TIMESTAMP(0) WITHOUT TIME ZONE,
  movgest_ts_det_tipo_id INTEGER NOT NULL,
  impoinizimpegno NUMERIC,
  impoattimpegno NUMERIC,
  importomodifica NUMERIC,
  tipo VARCHAR,
  movgest_ts_det_tipo_code VARCHAR,
  movgest_ts_det_importo NUMERIC,
  mtdm_reimputazione_anno INTEGER,
  mtdm_reimputazione_flag BOOLEAN,
  mod_tipo_code VARCHAR,
  login_operazione VARCHAR,
  ente_proprietario_id INTEGER,
  movgestNew_id INTEGER,
  movgestNew_ts_id INTEGER,
  data_creazione timestamp,
  data_modifica timestamp,
  fl_elab VARCHAR,
  scarto_code VARCHAR,
  scarto_desc VARCHAR
) ;





            