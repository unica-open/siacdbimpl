/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table if exists migr_provvedimento CASCADE;
drop table if exists migr_provvedimento_scarto CASCADE;
drop table if exists siac_r_migr_provvedimento_attoamm CASCADE;

CREATE TABLE migr_provvedimento (
  migr_provvedimento_id     SERIAL,
  provvedimento_id   integer not null,
  anno_provvedimento VARCHAR(4),
  numero_provvedimento INTEGER,
  tipo_provvedimento VARCHAR(20),
  sac_provvedimento VARCHAR(20),
  oggetto_provvedimento VARCHAR(500),
  note_provvedimento VARCHAR(500),
  stato_provvedimento VARCHAR(50),
  ente_proprietario_id INTEGER NOT NULL,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_provvedimento PRIMARY KEY(migr_provvedimento_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_provvedimento FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE TABLE siac_r_migr_provvedimento_attoamm (
  migr_provvedimento_rel_id serial,
  migr_provvedimento_id INTEGER NOT NULL,
  attoamm_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_provvedimento_attoamm PRIMARY KEY(migr_provvedimento_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_provvedimento_attoamm FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE migr_provvedimento_scarto (
  migr_provvedimento_scarto_id     SERIAL,
  migr_provvedimento_id 	integer not null,
  anno_provvedimento VARCHAR(4),
  numero_provvedimento INTEGER,
  tipo_provvedimento VARCHAR(20),
  sac_provvedimento VARCHAR(20),
  motivo_scarto	            varchar(250) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_provvedimento_scarto PRIMARY KEY(migr_provvedimento_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_provvedimento_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);