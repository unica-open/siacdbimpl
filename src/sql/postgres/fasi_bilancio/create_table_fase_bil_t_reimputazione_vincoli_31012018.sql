/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table fase_bil_t_reimputazione_vincoli

CREATE TABLE fase_bil_t_reimputazione_vincoli
(
  reimputazione_vinc_id serial,
  reimputazione_id integer,
  fasebilelabid INTEGER NOT NULL,
  bil_id integer,
  mod_id integer,
  movgest_ts_r_id integer,
  movgest_ts_a_id integer,
  movgest_ts_b_id integer,
  avav_id integer,
  importo_vincolo numeric,
  bil_new_id   integer,
  movgest_ts_r_new_id integer,
  movgest_ts_a_new_id integer,
  movgest_ts_b_new_id integer,
  avav_new_id integer,
  importo_vincolo_new NUMERIC,
  fl_elab VARCHAR,
  scarto_code VARCHAR,
  scarto_desc VARCHAR,
  login_operazione VARCHAR,
  data_creazione TIMESTAMP WITHOUT TIME ZONE,
  data_modifica TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER
)
WITH (oids = false);