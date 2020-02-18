/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table if exists migr_impegno CASCADE;
drop table if exists migr_impegno_accertamento CASCADE;
drop table if exists migr_accertamento CASCADE;
drop table if exists migr_classif_impacc CASCADE;

drop table if exists siac_r_migr_impegno_movgest_ts CASCADE;
drop table if exists siac_r_migr_accertamento_movgest_ts CASCADE;

drop table if exists migr_impegno_modifica CASCADE;
drop table if exists migr_accertamento_mod CASCADE;

drop table if exists migr_impacc_scarto CASCADE; -- DAVIDE - 12.07.2016 - inserita per gestione vincoli

CREATE TABLE migr_impegno (
  migr_impegno_id SERIAL,
  impegno_id INTEGER NOT NULL,
  tipo_movimento CHAR(1) NOT NULL,
  anno_esercizio VARCHAR(4) NOT NULL,
  anno_impegno VARCHAR(4) NOT NULL,
  numero_impegno INTEGER DEFAULT 0,
  numero_subimpegno INTEGER DEFAULT 0,
  pluriennale CHAR(1),
  capo_riacc CHAR(1),
  numero_capitolo INTEGER,
  numero_articolo INTEGER,
  numero_ueb VARCHAR (50),
  data_emissione VARCHAR(10) NOT NULL,
  data_scadenza VARCHAR(10),
  stato_operativo CHAR(1) NOT NULL,
  importo_iniziale NUMERIC DEFAULT 0 NOT NULL,
  importo_attuale NUMERIC DEFAULT 0 NOT NULL,
  descrizione VARCHAR(500)  NULL,
  anno_capitolo_orig VARCHAR(4),
  numero_capitolo_orig INTEGER,
  numero_articolo_orig INTEGER,
  numero_ueb_orig VARCHAR (50),
  anno_provvedimento VARCHAR(4),
  numero_provvedimento INTEGER,
  tipo_provvedimento VARCHAR(20),
  direzione_provvedimento VARCHAR(20),
  oggetto_provvedimento VARCHAR(500),
  note_provvedimento VARCHAR(500),
  stato_provvedimento VARCHAR(50),
  soggetto_determinato CHAR(1) DEFAULT 'N' NOT NULL,
  codice_soggetto INTEGER,
  classe_soggetto VARCHAR(250),
  nota VARCHAR(250),
  cup VARCHAR(15),
  cig VARCHAR(10),
  tipo_impegno VARCHAR(15),
  anno_impegno_plur VARCHAR(4),
  numero_impegno_plur INTEGER,
  anno_impegno_riacc VARCHAR(4),
  numero_impegno_riacc INTEGER,
  opera VARCHAR(50),
  cod_interv_class VARCHAR(50),
  pdc_finanziario VARCHAR(50),
  missione VARCHAR(50),
  programma VARCHAR(50),
  cofog VARCHAR(50),
  transazione_ue_spesa VARCHAR(50),
  siope_spesa VARCHAR(50),
  spesa_ricorrente VARCHAR(50),
  perimetro_sanitario_spesa VARCHAR(50),
  politiche_regionali_unitarie VARCHAR(50),
  pdc_economico_patr VARCHAR(50),
  classificatore_1 VARCHAR(250),
  classificatore_2 VARCHAR(250),
  classificatore_3 VARCHAR(250),
  classificatore_4 VARCHAR(250),
  classificatore_5 VARCHAR(250),
  ente_proprietario_id INTEGER NOT NULL,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  parere_finanziario INTEGER NOT NULL,
  CONSTRAINT pk_siac_t_migr_impegno PRIMARY KEY(migr_impegno_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_impegno FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE TABLE migr_impegno_accertamento (
  migr_vincolo_impacc_id SERIAL,
  vincolo_impacc_id INTEGER NOT NULL,
  anno_impegno VARCHAR(4) NOT NULL,
  numero_impegno INTEGER NOT NULL,
  anno_accertamento VARCHAR(4) NOT NULL,
  numero_accertamento INTEGER NOT NULL,
  importo NUMERIC DEFAULT 0 NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_impacc PRIMARY KEY(migr_vincolo_impacc_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_impacc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE migr_accertamento (
  migr_accertamento_id SERIAL,
  accertamento_id INTEGER NOT NULL,
  tipo_movimento CHAR(1) NOT NULL,
  anno_esercizio VARCHAR(4) NOT NULL,
  anno_accertamento VARCHAR(4) NOT NULL,
  numero_accertamento INTEGER DEFAULT 0,
  numero_subaccertamento INTEGER DEFAULT 0,
  pluriennale CHAR(1),
  capo_riacc CHAR(1),
  numero_capitolo INTEGER,
  numero_articolo INTEGER,
  numero_ueb VARCHAR (50),
  data_emissione VARCHAR(10) NOT NULL,
  data_scadenza VARCHAR(10),
  stato_operativo CHAR(1) NOT NULL,
  importo_iniziale NUMERIC DEFAULT 0 NOT NULL,
  importo_attuale NUMERIC DEFAULT 0 NOT NULL,
  descrizione VARCHAR(500)  NULL,
  anno_capitolo_orig VARCHAR(4),
  numero_capitolo_orig INTEGER,
  numero_articolo_orig INTEGER,
  numero_ueb_orig VARCHAR (50),
  anno_provvedimento VARCHAR(4),
  numero_provvedimento INTEGER,
  tipo_provvedimento VARCHAR(20),
  direzione_provvedimento VARCHAR(20),
  oggetto_provvedimento VARCHAR(500),
  note_provvedimento VARCHAR(500),
  stato_provvedimento VARCHAR(50),
  soggetto_determinato CHAR(1) DEFAULT 'N' NOT NULL,
  codice_soggetto INTEGER,
  classe_soggetto VARCHAR(250),
  nota VARCHAR(250),
  automatico CHAR(1) DEFAULT 'N' NOT NULL,
  anno_accertamento_plur VARCHAR(4),
  numero_accertamento_plur INTEGER,
  anno_accertamento_riacc VARCHAR(4),
  numero_accertamento_riacc INTEGER,
  opera VARCHAR(50),
  pdc_finanziario VARCHAR(50),
  transazione_ue_entrata VARCHAR(50),
  siope_entrata VARCHAR(50),
  entrata_ricorrente VARCHAR(50),
  perimetro_sanitario_entrata VARCHAR(50),
  pdc_economico_patr VARCHAR(50),
  classificatore_1 VARCHAR(250),
  classificatore_2 VARCHAR(250),
  classificatore_3 VARCHAR(250),
  classificatore_4 VARCHAR(250),
  classificatore_5 VARCHAR(250),
  parere_finanziario INTEGER NOT NULL,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_accertamento PRIMARY KEY(migr_accertamento_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_accertamento FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE TABLE migr_classif_impacc (
  migr_classif_tipo_id SERIAL,
  classif_tipo_id INTEGER NOT NULL,
  tipo CHAR(1) NOT NULL,
  codice VARCHAR(100) NOT NULL,
  descrizione VARCHAR(500) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_classif_impacc PRIMARY KEY(migr_classif_tipo_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_classif_impacc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE siac_r_migr_accertamento_movgest_ts (
  migr_accertamento_rel_id serial,
  migr_accertamento_id INTEGER NOT NULL,
  movgest_ts_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_accert_movgest_ts PRIMARY KEY(migr_accertamento_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_accert_movgest_ts FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE siac_r_migr_impegno_movgest_ts (
  migr_impegno_rel_id SERIAL,
  migr_impegno_id INTEGER NOT NULL,
  movgest_ts_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_impegno_movgest_ts PRIMARY KEY(migr_impegno_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_imp_movgest_ts FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE migr_impegno_modifica (
 impegno_mod_id SERIAL,
 tipo_movimento VARCHAR(1) NOT NULL,
 anno_esercizio VARCHAR(4) NOT NULL,
 anno_impegno VARCHAR(4) NOT NULL,
 numero_impegno INTEGER NOT NULL,
 numero_subimpegno INTEGER NOT NULL,
 numero_modifica INTEGER NOT NULL,
 tipo_modifica VARCHAR(10) NOT NULL,
 descrizione VARCHAR(500) NOT NULL,
 anno_provvedimento VARCHAR(4) NULL,
 numero_provvedimento INTEGER NULL,
 tipo_provvedimento VARCHAR(20) NULL,
 direzione_provvedimento VARCHAR(20) NULL,
 oggetto_provvedimento VARCHAR(500) NULL,
 note_provvedimento VARCHAR(500) NULL,
 stato_provvedimento VARCHAR(50) NULL,
 importo NUMERIC DEFAULT 0 NOT NULL,
 stato_operativo VARCHAR(1) NOT NULL,
 data_modifica VARCHAR(10) NOT NULL,
 ente_proprietario_id INTEGER NOT NULL,
 fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_impegno_modifica PRIMARY KEY(impegno_mod_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_impegno_modifica FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE 
);

CREATE TABLE migr_accertamento_mod (
 accertamento_mod_id SERIAL,
 tipo_movimento VARCHAR(1) NOT NULL,
 anno_esercizio VARCHAR(4) NOT NULL,
 anno_accertamento VARCHAR(4) NOT NULL,
 numero_accertamento INTEGER NOT NULL,
 numero_subaccertamento INTEGER NOT NULL,
 numero_modifica INTEGER NOT NULL,
 tipo_modifica VARCHAR(10) NOT NULL,
 descrizione VARCHAR(500) NOT NULL,
 anno_provvedimento VARCHAR(4) NULL,
 numero_provvedimento INTEGER NULL,
 tipo_provvedimento VARCHAR(20)  NULL,
 direzione_provvedimento VARCHAR(20)  NULL,
 oggetto_provvedimento VARCHAR(500) NULL,
 note_provvedimento VARCHAR(500) NULL,
 stato_provvedimento VARCHAR(50)  NULL,
 importo NUMERIC DEFAULT 0 NOT NULL,
 stato_operativo VARCHAR(1) NOT NULL,
 data_modifica VARCHAR (10) NOT NULL,
 ente_proprietario_id INTEGER NOT NULL,
 fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_accertamento_mod PRIMARY KEY(accertamento_mod_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_accertamento_mod FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

-- DAVIDE - 12.07.2016 - inserita per gestione vincoli
CREATE TABLE migr_impacc_scarto (
  migr_vincolo_impacc_scarto_id SERIAL,
  vincolo_impacc_id INTEGER NOT NULL,
  anno_esercizio          	varchar(4) not null,
  motivo_scarto           	varchar(2500) not null,
  data_creazione 			TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id 		INTEGER NOT NULL,
  CONSTRAINT pk_migr_vincolo_impacc_scarto PRIMARY KEY(migr_vincolo_impacc_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_vincolo_impacc_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);