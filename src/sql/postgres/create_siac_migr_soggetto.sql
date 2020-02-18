/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- tabelle stage PostGreSQL

drop table if exists migr_soggetto CASCADE;
drop table if exists migr_soggetto_scarto CASCADE;
drop table if exists migr_soggetto_classe CASCADE;
drop table if exists migr_indirizzo_secondario CASCADE;
drop table if exists migr_recapito_soggetto CASCADE;
drop table if exists migr_sede_secondaria CASCADE;
drop table if exists migr_modpag CASCADE;
drop table if exists migr_relaz_soggetto CASCADE;
drop table if exists migr_mod_accredito CASCADE;
drop table if exists migr_classe CASCADE;

drop table if exists siac_r_migr_soggetto_soggetto CASCADE;

drop table if exists siac_r_migr_soggetto_classe_rel_classe CASCADE;
drop table if exists siac_r_migr_indirizzo_secondario_indirizzo CASCADE;
drop table if exists siac_r_migr_recapito_soggetto_recapito CASCADE;
drop table if exists siac_r_migr_sede_secondaria_rel_sede CASCADE;
drop table if exists siac_r_migr_modpag_modpag CASCADE;
drop table if exists siac_r_migr_relaz_soggetto_relaz CASCADE;
drop table if exists siac_r_migr_mod_accredito_accredito CASCADE;

drop table if exists siac_r_migr_classe_soggclasse;


CREATE TABLE migr_soggetto
(
 migr_soggetto_id 		serial,
 soggetto_id  			integer not null,
 codice_soggetto  		integer,
 delegato_id            integer default 0 not null,
 codice_progdel_del     integer,
 codice_progben_del     integer,
 fl_genera_codice       varchar(1) default 'N' not null,
 tipo_soggetto  		VARCHAR(3) not null,
 forma_giuridica  		varchar(150),
 ragione_sociale  		VARCHAR(150) not null,
 codice_fiscale  		VARCHAR(16),
 partita_iva  			VARCHAR(50),
 codice_fiscale_estero  VARCHAR(50),
 cognome  				VARCHAR(150),
 nome  					VARCHAR(150),
 sesso  				varchar(2),
 data_nascita  			varchar (10),
 comune_nascita  		VARCHAR(150),
 provincia_nascita  	VARCHAR(150),
 nazione_nascita  		VARCHAR(150),
 indirizzo_principale  	CHAR(1) DEFAULT 'N' NOT NULL,
 tipo_indirizzo  		varchar(200),
 tipo_via  				VARCHAR(200),
 via  					VARCHAR(500),
 numero_civico  		VARCHAR(7),
 interno  				VARCHAR(10),
 frazione  				VARCHAR(150),
 cap  					VARCHAR(5),
 comune  				VARCHAR(150),
 prov  					VARCHAR(150),
 nazione  				VARCHAR(150),
 avviso  				CHAR(1) DEFAULT 'N' NOT NULL,
 tel1        			VARCHAR(15),
 tel2  					VARCHAR(15),
 fax                    VARCHAR(15),
 sito_www               VARCHAR(150),
 email                  VARCHAR(150),
 contatto_generico      VARCHAR(250),
 stato_soggetto         varchar(20) not null,
 note                   VARCHAR(1000),
 generico	            CHAR(1) DEFAULT 'N' NULL,
 classif                VARCHAR(200),
 matricola_hr_spi       varchar(7),
 fl_elab                char(1) default 'N' not null,
 ente_proprietario_id INTEGER NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_soggetto PRIMARY KEY(migr_soggetto_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_soggetto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX migr_soggetto_idx ON migr_soggetto
USING btree (soggetto_id);

CREATE TABLE migr_soggetto_scarto
(
 migr_soggetto_scarto_id serial,
 migr_soggetto_id        integer not null,
 soggetto_id  			 integer not null,
 codice_soggetto  		 integer,
 delegato_id             integer default 0 not null,
 tipo_soggetto  		 VARCHAR(3) not null,
 codice_fiscale  		 VARCHAR(16),
 partita_iva  			 VARCHAR(50),
 ente_proprietario_id    INTEGER NOT NULL,
 data_creazione          TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 motivo_scarto			 VARCHAR(250),
  CONSTRAINT pk_siac_t_migr_soggetto_scarto PRIMARY KEY(migr_soggetto_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_soggetto_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table migr_soggetto_classe
(
 migr_soggetto_classe_id    serial,
 soggetto_classe_id         integer not null,
 soggetto_id                integer not null,
 classe_soggetto	        VARCHAR(200) not null,
 fl_elab                    char(1) default 'N' not null,
 ente_proprietario_id       INTEGER NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_soggetto_classe PRIMARY KEY(migr_soggetto_classe_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_soggetto_classe FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table migr_indirizzo_secondario
(
  migr_indirizzo_id        serial,
  indirizzo_id	           integer not null,
  soggetto_id	           integer not null,
  codice_indirizzo	       integer null,
  indirizzo_principale	   CHAR(1) DEFAULT 'N' NOT NULL,
  tipo_indirizzo	       varchar(200) not null,
  tipo_via	               VARCHAR(200) null,
  via	                   VARCHAR(500) not null,
  numero_civico	           VARCHAR(7),
  interno	               VARCHAR(10),
  frazione	               VARCHAR(150),
  cap	                   VARCHAR(5),
  comune	               VARCHAR(150),
  prov	                   VARCHAR(150),
  nazione	               VARCHAR(150),
  avviso	               CHAR(1) DEFAULT 'N' NOT NULL,
  fl_elab              char(1) default 'N' not null,
  ente_proprietario_id       INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_indirizzo_secondario PRIMARY KEY(migr_indirizzo_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_indirizzo_secondario FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table migr_recapito_soggetto
(
 migr_recapito_id  serial,
 recapito_id	   integer not null,
 soggetto_id	   integer not null,
 indirizzo_id	   integer null,
 tipo_recapito	   varchar(20) not null,
 recapito 	       VARCHAR(150) not null,
 avviso	           char(1) default 'N' not null,
 fl_elab           char(1) default 'N' not null,
 ente_proprietario_id       INTEGER NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 CONSTRAINT pk_siac_t_migr_recapito_soggetto PRIMARY KEY(migr_recapito_id),
 CONSTRAINT siac_t_ente_proprietario_siac_t_migr_recapito_soggetto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


create table migr_sede_secondaria
(
 migr_sede_id           serial,
 sede_id	            integer not null,
 soggetto_id            integer not null,
 codice_indirizzo       integer null,
 codice_modpag	        varchar(10) not null,
 ragione_sociale        VARCHAR(150) not null,
 tel1                   VARCHAR(100),
 tel2	                VARCHAR(100),
 fax	                VARCHAR(100),
 sito_www	            VARCHAR(150),
 email	                VARCHAR(150),
 contatto_generico	    VARCHAR(250),
 note	                VARCHAR(500),
 tipo_relazione	        VARCHAR(50) not null,
 tipo_indirizzo	        VARCHAR(200) not null,
 indirizzo_principale	CHAR(1) DEFAULT 'N' NOT NULL,
 tipo_via	            VARCHAR(200)  null,
 via	                VARCHAR(500),
 numero_civico	        VARCHAR(7),
 interno	            VARCHAR(10),
 frazione	            VARCHAR(150),
 cap	                varchar(5),
 comune	                varchar(150),
 prov	                varchar(150),
 nazione	            VARCHAR(150),
 avviso	                CHAR(1) DEFAULT 'N' NOT NULL,
 fl_elab              char(1) default 'N' not null,
 ente_proprietario_id       INTEGER NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pk_siac_t_migr_sede_secondaria PRIMARY KEY(migr_sede_id),
    CONSTRAINT siac_t_ente_proprietario_siac_t_migr_sede_secondaria FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table migr_modpag
(
 migr_modpag_id       serial,
 modpag_id	          integer not null,
 soggetto_id	      integer not null,
 sede_id	          integer,
 codice_modpag	      varchar(10),
 codice_modpag_del    varchar(10),
 delegato_id	      integer default 0 not null,
 fl_genera_codice     varchar(1) default 'N' not null,
 cessione	          varchar(3),
 sede_secondaria	  CHAR(1) DEFAULT 'N' NOT NULL,
 codice_accredito	  VARCHAR(6) not null,
 iban	              VARCHAR(34),
 bic	              VARCHAR(11),
 abi                  VARCHAR(200),
 cab                  VARCHAR(200),
 conto_corrente	      VARCHAR(15),
 conto_corrente_intest   VARCHAR(500),
 quietanzante	      VARCHAR(500),
 codice_fiscale_quiet VARCHAR(16),
 delegato    	      VARCHAR(150),
 codice_fiscale_del   VARCHAR(16),
 data_nascita_qdel    varchar (10),
 luogo_nascita_qdel	  varchar(150),
 stato_nascita_qdel	  varchar(150),
 stato_modpag	      VARCHAR(20) not null,
 note	              VARCHAR(1000),
 email	              VARCHAR(150),
 fl_elab              char(1) default 'N' not null,
 ente_proprietario_id       INTEGER NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pk_siac_t_migr_modpag_k PRIMARY KEY(migr_modpag_id),
    CONSTRAINT siac_t_ente_proprietario_siac_t_migr_modpag FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE INDEX migr_modpag_idx ON migr_modpag
USING btree (soggetto_id);

create table migr_relaz_soggetto
(
 migr_relaz_id   serial,
 relaz_id	     integer not null,
 tipo_relazione	 VARCHAR(200) not null,
 soggetto_id_da	 integer not null,
 modpag_id_da	 integer,
 soggetto_id_a	 integer not null,
 modpag_id_a	 integer,
 fl_elab              char(1) default 'N' not null,
 ente_proprietario_id       INTEGER NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pk_siac_t_migr_relaz_soggetto PRIMARY KEY(migr_relaz_id),
    CONSTRAINT siac_t_ente_proprietario_siac_t_migr_relaz_soggetto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
 );



create table migr_mod_accredito
(
 migr_accredito_id serial,
 accredito_id	   integer not null,
 codice	           varchar(10) not null,
 descri	           varchar(150) default 'ND' not null,
 tipo_accredito    varchar(10) not null,
 priorita          integer default 0 not null,
 decodificaOIL     varchar(150),
 fl_elab              char(1) default 'N' not null,
 ente_proprietario_id       INTEGER NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pk_siac_t_migr_mod_accredito PRIMARY KEY(migr_accredito_id),
    CONSTRAINT siac_t_ente_proprietario_siac_t_migr_accredito_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


create table migr_classe
(
 migr_classe_id       serial,
 classe_id	          integer not null,
 classe_code	      varchar(100) not null,
 classe_desc	      varchar(200) not null,
 codice_soggetto	  integer null,
 note_soggetto	      varchar(200) null,
 fl_elab              char(1) default 'N' not null,
 data_creazione       TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 ente_proprietario_id INTEGER NOT NULL,
 CONSTRAINT pk_migr_classe PRIMARY KEY(migr_classe_id),
 CONSTRAINT siac_t_ente_proprietario_migr_classe FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

--- relazioni tra tabelle di migrazione e tabelle siac (identificativi creati da migrazione)
--- migr_soggetto --> soggetto
create table siac_r_migr_soggetto_soggetto
(
	migr_soggetto_rel_id serial,
    migr_soggetto_id integer not null,
    soggetto_id integer not null,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    ente_proprietario_id       INTEGER NOT NULL,
    CONSTRAINT pk_siac_r_migr_soggetto_soggetto PRIMARY KEY(migr_soggetto_rel_id),
    CONSTRAINT siac_t_ente_proprietario_siac_r_migr_soggetto_sogg FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

-- migr_soggetto_classe --> r_soggetto_classe
create table siac_r_migr_soggetto_classe_rel_classe
(
	migr_soggetto_classe_rel_id serial,
    migr_soggetto_classe_id integer not null,
    soggetto_classe_r_id integer not null,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    ente_proprietario_id       INTEGER NOT NULL,
    CONSTRAINT pk_siac_r_migr_soggetto_classe_rel_classe PRIMARY KEY(migr_soggetto_classe_rel_id),
    CONSTRAINT siac_t_ente_proprietario_siac_r_migr_soggetto_classe_rel_sogg FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

-- migr_indirizzo_secondario --> indirizzo_soggetto
create table siac_r_migr_indirizzo_secondario_indirizzo
(
  migr_indirizzo_rel_id        serial,
  migr_indirizzo_id      	   integer not null,
  indirizzo_id				   integer not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id       INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_indirizzo_secondario_indirizzo PRIMARY KEY(migr_indirizzo_rel_id),
    CONSTRAINT siac_t_ente_proprietario_siac_r_migr_indirizzo_sec FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

-- migr_recapito_soggetto --> recapito_soggetto
create table siac_r_migr_recapito_soggetto_recapito
(
	migr_recapito_rel_id     serial,
    migr_recapito_id         integer not null,
    recapito_id				 integer not null,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    ente_proprietario_id       INTEGER NOT NULL,
	CONSTRAINT pk_siac_r_migr_recapito_soggetto_recapito PRIMARY KEY(migr_recapito_rel_id),
    CONSTRAINT siac_t_ente_proprietario_siac_r_migr_recapito_sogg FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

-- migr_sede_secodaria --> relaz_soggetto ( SEDE_SECONDARIA )
create table siac_r_migr_sede_secondaria_rel_sede
(
	migr_sede_rel_id     serial,
    migr_sede_id         integer not null,
    soggetto_relaz_id	 integer not null,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    ente_proprietario_id       INTEGER NOT NULL,
	CONSTRAINT pk_siac_r_migr_sede_secondaria_rel_sede PRIMARY KEY(migr_sede_rel_id),
    CONSTRAINT siac_t_ente_proprietario_siac_r_migr_sede_sec_rel FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

-- migr_modpag --> modpag
create table siac_r_migr_modpag_modpag
(
	migr_modpag_rel_id     serial,
    migr_modpag_id		   integer not null,
    modpag_id			   integer not null,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    ente_proprietario_id       INTEGER NOT NULL,
	CONSTRAINT pk_siac_r_migr_modpag_modpag PRIMARY KEY(migr_modpag_rel_id),
    CONSTRAINT siac_t_ente_proprietario_siac_r_migr_modpag_modpag FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


-- t_migr_relaz_soggetto --> soggetto_relaz ( cessioni e altro )
create table siac_r_migr_relaz_soggetto_relaz
(
  migr_relaz_r_id   serial,
  migr_relaz_id     integer not null,
  soggetto_relaz_id integer not NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id       INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_relaz_soggetto_relaz PRIMARY KEY(migr_relaz_r_id),
   CONSTRAINT siac_t_ente_proprietario_siac_r_migr_relaz_soggetto_rel FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
 );


-- mod_accredito --> accredito_tipo
create table siac_r_migr_mod_accredito_accredito
(
 migr_accredito_r_id serial,
 migr_accredito_id   integer not null,
 accredito_tipo_id        integer not null,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id       INTEGER NOT NULL,
 CONSTRAINT pk_siac_r_migr_mod_accredito_accredito PRIMARY KEY(migr_accredito_r_id),
 CONSTRAINT siac_t_ente_proprietario_siac_r_migr_mod_accredito_accre FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);



--- relazioni tra tabelle di migrazione e tabelle siac (identificativi creati da migrazione)
--- migr_classe --> siac_d_soggetto_classe
create table siac_r_migr_classe_soggclasse
(
	migr_classe_rel_id serial,
    migr_classe_id     integer not null,
    classe_id          integer not null,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    ente_proprietario_id       INTEGER NOT NULL,
    CONSTRAINT pk_siac_r_migr_classe_soggclasse PRIMARY KEY(migr_classe_rel_id),
    CONSTRAINT siac_t_ente_proprietario_siac_r_migr_classe_soggclasse FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_r_migr_modpag_modpag_idx ON siac_r_migr_modpag_modpag
USING btree (migr_modpag_id,ente_proprietario_id);


CREATE INDEX siac_r_migr_soggetto_soggetto_idx ON siac_r_migr_soggetto_soggetto
USING btree (migr_soggetto_id,ente_proprietario_id);