/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table if exists migr_capitolo_uscita CASCADE;
drop table if exists migr_capitolo_entrata CASCADE;
drop table if exists migr_attilegge_uscita CASCADE;
drop table if exists migr_attilegge_entrata CASCADE;
drop table if exists migr_vincolo_capitolo CASCADE;
drop table if exists migr_classif_capitolo CASCADE;
drop table if exists migr_capitolo_entrata_scarto CASCADE;
drop table if exists migr_capitolo_uscita_scarto CASCADE;


drop table if exists siac_r_migr_attilegge_ent CASCADE;
drop table if exists siac_r_migr_attilegge_usc CASCADE;
drop table if exists siac_r_migr_capitolo_uscita_bil_elem CASCADE;
drop table if exists siac_r_migr_capitolo_entrata_bil_elem CASCADE;

drop table if exists siac_r_migr_vincolo_capitolo;

CREATE TABLE migr_capitolo_uscita (
  migr_capusc_id     SERIAL,
  capusc_id	         integer not null,
  tipo_capitolo	     varchar(10) not null,
  anno_esercizio	 varchar(4) not null,
  numero_capitolo	 integer not null,
  numero_articolo	 integer not null,
  numero_ueb	     varchar (50) not null,
  descrizione	     varchar(600) not null,
  descrizione_articolo   varchar(600) null,
  titolo	         varchar(10)  null,
  macroaggregato	 varchar(10)  null,
  missione	         varchar(10)  null,
  programma	         varchar(10)  null,
  pdc_fin_quarto	 varchar(30) null,
  pdc_fin_quinto	 varchar(30) null,
  cofog	 			 varchar null,
  note	             varchar(150) null,
  flag_per_memoria	 char(1) default 'N' not null,
  flag_rilevante_iva char(1) default 'N' not null,
  tipo_finanziamento varchar(250) null,
  tipo_vincolo	     varchar(250) null,
  tipo_fondo	     varchar(250) null,
  siope_livello_1	 varchar(50) null,
  siope_livello_2	 varchar(50) null,
  siope_livello_3	 varchar(50) null,
  classificatore_1	 varchar(250) null,
  classificatore_2	 varchar(250) null,
  classificatore_3	 varchar(250) null,
  classificatore_4	 varchar(250) null,
  classificatore_5	 varchar(250) null,
  classificatore_6	 varchar(250) null,
  classificatore_7	 varchar(250) null,
  classificatore_8	 varchar(250) null,
  classificatore_9	 varchar(250) null,
  classificatore_10	 varchar(250) null,
  classificatore_11	 varchar(250) null,
  classificatore_12	 varchar(250) null,
  classificatore_13	 varchar(250) null,
  classificatore_14	 varchar(250) null,
  classificatore_15	 varchar(250) null,
  centro_resp	     varchar(10)  null,
  cdc	             varchar(10)  null,
  classe_capitolo    varchar(10)  default 'STD' not null,
  flag_impegnabile   varchar(1)   default 'S' not null,
  stanziamento_iniziale         NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_iniziale_res	    NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_iniziale_cassa	NUMERIC DEFAULT 0 NOT NULL,
  stanziamento	                NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_res	            NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_cassa	        NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_iniziale_anno2	NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_anno2         	NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_iniziale_anno3	NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_anno3         	NUMERIC DEFAULT 0 NOT NULL,
  dicuiimpegnato_anno1	        NUMERIC DEFAULT 0 NOT NULL,
  dicuiimpegnato_anno2 			NUMERIC DEFAULT 0 NOT NULL,
  dicuiimpegnato_anno3 			NUMERIC DEFAULT 0 NOT NULL,
  trasferimenti_comunitari      varchar(1)  null,     -- Davide - 30.03.016
  funzioni_delegate             varchar(1)  null,     -- Davide - 30.03.016
  ente_proprietario_id INTEGER NOT NULL,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  spesa_ricorrente VARCHAR(50),                                         -- DAVIDE - 22.08.2016 - aggiunto per COTO, PVTO
  CONSTRAINT pk_siac_t_migr_capitolo_uscita PRIMARY KEY(migr_capusc_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_capitolo_uscita FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE TABLE migr_capitolo_entrata (
  migr_capent_id     SERIAL,
  capent_id          NUMERIC not null,
  tipo_capitolo      VARCHAR(10) not null,
  anno_esercizio     VARCHAR(4) not null,
  numero_capitolo    integer not null,
  numero_articolo    NUMERIC not null,
  numero_ueb	     varchar (50) not null,
  descrizione        VARCHAR(600) not null,
  descrizione_articolo   varchar(600) null,
  titolo             VARCHAR(10)  null,
  tipologia          VARCHAR(10)  null,
  categoria          VARCHAR(10)  null,
  pdc_fin_quarto     VARCHAR(30),
  pdc_fin_quinto     VARCHAR(30),
  note               VARCHAR(150),
  flag_per_memoria	 char(1) default 'N' not null,
  flag_rilevante_iva CHAR(1) default 'N' not null,
  tipo_finanziamento VARCHAR(250),
  tipo_vincolo       VARCHAR(250),
  tipo_fondo         VARCHAR(250),
  siope_livello_1    VARCHAR(50),
  siope_livello_2    VARCHAR(50),
  siope_livello_3    VARCHAR(50),
  classificatore_1   VARCHAR(250),
  classificatore_2   VARCHAR(250),
  classificatore_3   VARCHAR(250),
  classificatore_4   VARCHAR(250),
  classificatore_5   VARCHAR(250),
  classificatore_6   VARCHAR(250),
  classificatore_7   VARCHAR(250),
  classificatore_8   VARCHAR(250),
  classificatore_9   VARCHAR(250),
  classificatore_10  VARCHAR(250),
  classificatore_11  VARCHAR(250),
  classificatore_12  VARCHAR(250),
  classificatore_13  VARCHAR(250),
  classificatore_14  VARCHAR(250),
  classificatore_15  VARCHAR(250),
  centro_resp        VARCHAR(10)  null,
  cdc                VARCHAR(10),
  classe_capitolo    varchar(10)  default 'STD' not null,
  flag_accertabile   varchar(1)   default 'S' not null,
  stanziamento_iniziale       NUMERIC default 0 not null,
  stanziamento_iniziale_res   NUMERIC default 0 not null,
  stanziamento_iniziale_cassa NUMERIC default 0 not null,
  stanziamento                NUMERIC default 0 not null,
  stanziamento_res            NUMERIC default 0 not null,
  stanziamento_cassa          NUMERIC default 0 not null,
  stanziamento_iniziale_anno2	NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_anno2         	NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_iniziale_anno3	NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_anno3         	NUMERIC DEFAULT 0 NOT NULL,
  trasferimenti_comunitari      varchar(1)  null,     -- Davide - 30.03.016
  ente_proprietario_id INTEGER NOT NULL,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  entrata_ricorrente VARCHAR(50),                                         -- DAVIDE - 22.08.2016 - aggiunto per COTO, PVTO
  CONSTRAINT pk_siac_t_migr_capitolo_entrata PRIMARY KEY(migr_capent_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_capent FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE migr_attilegge_uscita (
  migr_attilegge_usc_id SERIAL,
  attilegge_uscita_id	NUMERIC not null,
  tipo_capitolo	        varchar(10) not null,
  anno_esercizio	    varchar(4) not null,
  numero_capitolo	    NUMERIC(6) not null,
  numero_articolo	    NUMERIC(3) not null,
  anno_legge	        VARCHAR(4) not null,
  tipo_legge	        VARCHAR(2) not null,
  nro_legge 	        VARCHAR(10) not null,
  articolo	            VARCHAR(4) not null,
  comma	                VARCHAR(4) not null,
  punto	                VARCHAR(2) not null,
  gerarchia	            VARCHAR(2) null,
  inizio_finanz	        varchar(10) null,
  fine_finanz 	        varchar(10) null,
  descrizione	        VARCHAR(150) null,
  fl_elab               CHAR(1) DEFAULT 'N' NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_attilegge_usc PRIMARY KEY(migr_attilegge_usc_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_attilegge_usc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE migr_attilegge_entrata (
  migr_attilegge_ent_id SERIAL,
  attilegge_entrata_id	NUMERIC not null,
  tipo_capitolo	        varchar(10) not null,
  anno_esercizio	    varchar(4) not null,
  numero_capitolo	    NUMERIC(6) not null,
  numero_articolo	    NUMERIC(3) not null,
  anno_legge	        VARCHAR(4) not null,
  tipo_legge	        VARCHAR(2) not null,
  nro_legge 	        VARCHAR(10) not null,
  articolo	            VARCHAR(4) not null,
  comma	                VARCHAR(4) not null,
  punto	                VARCHAR(2) not null,
  gerarchia	            VARCHAR(2) null,
  inizio_finanz	        varchar(10) null,
  fine_finanz 	        varchar(10) null,
  descrizione	        VARCHAR(150) null,
  fl_elab               CHAR(1) DEFAULT 'N' NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_attilegge_ent PRIMARY KEY(migr_attilegge_ent_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_attilegge_ent FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE TABLE migr_vincolo_capitolo (
 migr_vincolo_id     serial,
 vincolo_id  	     numeric not null,
 vincolo_cap_id  	 numeric not null,
 tipo_vincolo_bil	 varchar(100) not null,
 tipo_vincolo	     varchar(100) not null,
 anno_esercizio	     varchar(4) not null,
 numero_capitolo_u	 numeric not null,
 numero_articolo_u	 numeric not null,
 numero_capitolo_e	 numeric not null,
 numero_articolo_e	 numeric not null,
 ente_proprietario_id INTEGER NOT NULL,
 fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 CONSTRAINT pk_siac_t_migr_vincolo_cap PRIMARY KEY(migr_vincolo_id),
 CONSTRAINT siac_t_ente_proprietario_siac_t_migr_vincolo_cap FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE migr_classif_capitolo (
  migr_classif_tipo_id SERIAL,
  classif_tipo_id	   numeric not null,
  tipo_capitolo	       varchar(10) not null,
  codice	           varchar(100) not null,
  descrizione	       varchar(250) not null,
  ente_proprietario_id INTEGER NOT NULL,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_classif_cap PRIMARY KEY(migr_classif_tipo_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_classif_cap FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);



CREATE TABLE siac_r_migr_capitolo_uscita_bil_elem (
  migr_capusc_rel_id serial,
  migr_capusc_id INTEGER NOT NULL,
  elem_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_capusc_bil_elem PRIMARY KEY(migr_capusc_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_capusc_bil_elem FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE siac_r_migr_capitolo_entrata_bil_elem (
  migr_capent_rel_id serial,
  migr_capent_id INTEGER NOT NULL,
  elem_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_capent_bil_elem PRIMARY KEY(migr_capent_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_capent_bil_elem FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE TABLE siac_r_migr_attilegge_usc (
  migr_attilegge_usc_rel_id serial,
  migr_attilegge_usc_id INTEGER NOT NULL,
  attolegge_bil_elem_id INTEGER NOT NULL,
  tipo_bil_elem	   varchar(10) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_attilegge_usc PRIMARY KEY(migr_attilegge_usc_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_attilegge_usc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE siac_r_migr_attilegge_ent (
  migr_attilegge_ent_rel_id serial,
  migr_attilegge_ent_id INTEGER NOT NULL,
  attolegge_bil_elem_id INTEGER NOT NULL,
  tipo_bil_elem	   varchar(10) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_attilegge_ent PRIMARY KEY(migr_attilegge_ent_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_attilegge_ent FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE siac_r_migr_vincolo_capitolo (
  migr_vincolo_rel_id serial,
  migr_vincolo_id     INTEGER NOT NULL,
  vincolo_id          INTEGER NOT NULL,
  tipo_vincolo_bil	  varchar(1) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_vincolo_cap PRIMARY KEY(migr_vincolo_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_vincolo_cap FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);



CREATE TABLE migr_capitolo_uscita_scarto (
  migr_capusc_scarto_id     SERIAL,
  migr_capusc_id			integer not null,
  elem_id                   integer not null,
  tipo_capitolo	            varchar(10) not null,
  motivo_scarto	            varchar(250) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_capusc_scarto PRIMARY KEY(migr_capusc_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_capusc_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE migr_capitolo_entrata_scarto (
  migr_capent_scarto_id     SERIAL,
  migr_capent_id			integer not null,
  elem_id                   integer not null,
  tipo_capitolo	            varchar(10) not null,
  motivo_scarto	            varchar(250) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_capent_scarto PRIMARY KEY(migr_capent_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_capent_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);
