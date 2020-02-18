/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table if exists migr_mutuo cascade;
drop table if exists migr_voce_mutuo cascade;
drop table if exists migr_mutuo_scarto cascade;
drop table if exists migr_voce_mutuo_scarto cascade;
drop table if exists siac_r_migr_mutuo_t_mutuo cascade;
drop table if exists siac_r_migr_voce_mutuo_t_mutuo_voce cascade;

CREATE TABLE MIGR_MUTUO
(
  migr_mutuo_id     SERIAL,
  mutuo_id integer not null,
  codice_mutuo varchar(200) not null,
  descrizione varchar(500),
  tipo_mutuo varchar(10) not null,
  importo_iniziale NUMERIC DEFAULT 0 NOT NULL,
  importo_attuale NUMERIC DEFAULT 0 NOT NULL,
  durata varchar(2) not null,
  numero_registrazione varchar(15),
  data_inizio varchar(10) not null,
  data_fine varchar(10) not null,
  stato_operativo varchar(1) not null,
  codice_soggetto integer,
  anno_provvedimento varchar(4),
  numero_provvedimento integer,
  tipo_provvedimento varchar(20),
  sac_provvedimento varchar(20),
  oggetto_provvedimento varchar(500),
  note_provvedimento varchar(500),
  stato_provvedimento varchar(50),
  note varchar(250),
  ente_proprietario_id integer not null,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_mutuo PRIMARY KEY(migr_mutuo_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_migr_mutuo_id FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE MIGR_VOCE_MUTUO
(
  migr_voce_mutuo_id serial,
  voce_mutuo_id integer not null,
  codice_voce_mutuo varchar(200),
  nro_mutuo varchar (5),
  descrizione varchar(500),
  importo_iniziale NUMERIC DEFAULT 0 NOT NULL,
  importo_attuale NUMERIC DEFAULT 0 NOT NULL,
  tipo_voce_mutuo varchar(10) not null,
  anno_impegno   varchar(4) not null,
  numero_impegno integer  default 0 not null,
  anno_esercizio varchar(4) not null,
  ente_proprietario_id integer not null,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_voce_mutuo PRIMARY KEY(migr_voce_mutuo_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_voce_mutuo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);
create table migr_mutuo_scarto
(
  migr_mutuo_scarto_id serial,
  migr_mutuo_id	integer not null,
  codice_mutuo    varchar(200) ,
  motivo_scarto   varchar(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_mutuo_scarto PRIMARY KEY(migr_mutuo_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_mutuo_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table migr_voce_mutuo_scarto
(
  migr_voce_mutuo_scarto_id serial,
  migr_voce_mutuo_id	integer  not null,
  nro_mutuo         varchar(5) ,
  numero_impegno    integer,
  anno_impegno   		varchar(4),
  anno_esercizio 		varchar(4),
  motivo_scarto          varchar(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_voce_mutuo_scarto PRIMARY KEY(migr_voce_mutuo_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_voce_mutuo_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE TABLE siac_r_migr_mutuo_t_mutuo (
  migr_mutuo_rel_id SERIAL,
  migr_mutuo_id INTEGER NOT NULL,
  mut_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_mutuo_t_mutuo PRIMARY KEY(migr_mutuo_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_mutuo_t_mutuo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE siac_r_migr_voce_mutuo_t_mutuo_voce (
  migr_voce_mutuo_rel_id SERIAL,
  migr_voce_mutuo_id INTEGER NOT NULL,
  mut_voce_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_voce_mutuo_t_mutuo_voce PRIMARY KEY(migr_voce_mutuo_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_voce_mutuo_t_mutuo_voce FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);