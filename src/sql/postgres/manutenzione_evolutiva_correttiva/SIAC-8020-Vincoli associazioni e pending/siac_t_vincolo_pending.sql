/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop table if exists siac.siac_t_vincolo_pending;
CREATE TABLE if not exists siac.siac_t_vincolo_pending
(
  vincolo_pending_id serial,
  movgest_ts_r_id integer not null,
  bil_anno varchar(4) not null,
  importo_pending numeric not null default 0,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL  DEFAULT now(),
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id integer not null,
  data_creazione  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  data_modifica  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  login_operazione varchar(200) not null,
  CONSTRAINT pk_siac_vincolo_pending PRIMARY KEY(vincolo_pending_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_vincolo_pend FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_r_movgest_ts_siac_t_vincolo_pend FOREIGN KEY (movgest_ts_r_id)
    REFERENCES siac.siac_r_movgest_ts(movgest_ts_r_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE	
);

CREATE INDEX idx_siac_t_vincolo_pending_fk_ente_proprietario_id ON siac.siac_t_vincolo_pending
  USING btree (ente_proprietario_id);
  
CREATE UNIQUE INDEX idx_siac_t_vincolo_pending_fk_siac_r_movgest_ts ON siac.siac_t_vincolo_pending
  USING btree (movgest_ts_r_id, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

alter table siac.siac_t_vincolo_pending owner to siac;