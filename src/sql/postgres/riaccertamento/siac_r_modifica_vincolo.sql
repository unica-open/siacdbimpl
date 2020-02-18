/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE TABLE siac.siac_r_modifica_vincolo (
  modvinc_id SERIAL,
  mod_id INTEGER,
  movgest_ts_r_id INTEGER,
  modvinc_tipo_operazione VARCHAR,
  importo_delta NUMERIC,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_modifica_vincolo PRIMARY KEY(modvinc_id),
  CONSTRAINT siac_r_movgest_ts_siac_r_modifica_vincolo FOREIGN KEY (movgest_ts_r_id)
    REFERENCES siac.siac_r_movgest_ts(movgest_ts_r_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_modifica_siac_r_modifica_vincolo FOREIGN KEY (mod_id)
    REFERENCES siac.siac_t_modifica(mod_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
) 
WITH (oids = false);

COMMENT ON COLUMN siac.siac_r_modifica_vincolo.modvinc_tipo_operazione
IS 'INSERIMENTO / ANNULLA';

CREATE INDEX idx_siac_r_modifica_vincolo_1 ON siac.siac_r_modifica_vincolo
  USING btree (mod_id, movgest_ts_r_id, modvinc_tipo_operazione COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);