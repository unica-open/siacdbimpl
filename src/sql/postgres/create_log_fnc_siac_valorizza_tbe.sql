/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create table log_fnc_siac_valorizza_tbe_movSpesa
(log_id SERIAL
 , movgest_ts_id integer not null
 , elem_id integer
 , motivo_scarto VARCHAR(2500) NOT NULL
 , data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL
 , ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_log_fnc_siac_valorizzatbemovspesa PRIMARY KEY(log_id),
  CONSTRAINT siac_t_ente_proprietario_log_fnc_siac_valorizzatbemovspesa FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

create table log_fnc_siac_valorizza_tbe_movEntrata
(log_id SERIAL
 , movgest_ts_id integer not null
 , elem_id integer
 , motivo_scarto VARCHAR(2500) NOT NULL
 , data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL
 , ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_log_fnc_siac_valorizzatbemoventrata PRIMARY KEY(log_id),
  CONSTRAINT siac_t_ente_proprietario_log_fnc_siac_valorizzatbemoventrata FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

create table log_fnc_siac_valorizza_tbe_liq
(log_id SERIAL
 , liq_id integer not null
 , liq_anno integer not null
 , liq_numero numeric not null
 , motivo_scarto VARCHAR(2500) NOT NULL
 , data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL
 , ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_log_fnc_siac_valorizzatbeliq PRIMARY KEY(log_id),
  CONSTRAINT siac_t_ente_proprietario_log_fnc_siac_valorizzatbeliq FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);