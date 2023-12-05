/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
rop table if exists migr_liquidazione;
drop table if exists migr_liquidazione_scarto;
drop table if exists siac_r_migr_liquidazione_t_liquidazione;

create table migr_liquidazione
(
 migr_liquidazione_id    SERIAL,
 liquidazione_id         integer  not null,
 numero_liquidazione     integer  not null,
 anno_esercizio          varchar(4) not null,
 numero_liquidazione_orig     integer  not null,
 anno_esercizio_orig     varchar(4) not null,
 data_emissione          varchar(10) not null,
 descrizione             varchar(500) not null,
 data_emissione_orig     varchar(10) not null,
 importo                 NUMERIC DEFAULT 0 NOT NULL,
 codice_soggetto         INTEGER  not null,
 sede_id                 INTEGER  , -- id tabella migr_sede_secondaria oracle
 codice_progben          varchar(10),
 codice_modpag_del       varchar(10),
 stato_operativo         varchar(1)   not null,
 anno_provvedimento      varchar(4)   null,
 numero_provvedimento    INTEGER      null,
 numero_provvedimento_calcolato    INTEGER      null,
 tipo_provvedimento      varchar(20)  null,
 sac_provvedimento       varchar(20)  null,
 oggetto_provvedimento   varchar(500) null,
 note_provvedimento      varchar(500) null,
 stato_provvedimento     varchar(50)  null,
 numero_impegno          INTEGER  default 0 null,
 anno_impegno            varchar(4) not null,
 numero_subimpegno       INTEGER  default 0 null,
 numero_mutuo            varchar(200) null,
 cofog                   varchar(50)  null,
 pdc_finanziario         varchar(50)  null,
 ente_proprietario_id    INTEGER not null,
 fl_elab				         CHAR(1) DEFAULT 'N' NOT NULL,
 data_creazione 		     TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  -- 20.11.2015 aggiunto campo siope_spesa
 siope_spesa             varchar(50)  null
/*saranno da aggiungerre gli attributi della transazione elementare ovvero:
 missione                VARCHAR2(50)  null,
 programma               VARCHAR2(50)  null,
 cofog                   VARCHAR2(50)  null,
 transazione_ue_spesa    VARCHAR2(50)  null,
 siope_spesa             VARCHAR2(50)  null,
 spesa_ricorrente        VARCHAR2(50)  null,
 perimetro_sanitario_spesa VARCHAR2(50) null,
 politiche_regionali_unitarie VARCHAR2(50) null,
 pdc_economico_patr           VARCHAR2(50) null,
*/
,
  CONSTRAINT pk_siac_t_migr_liquidazione PRIMARY KEY(migr_liquidazione_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_migr_liquidazione_id FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE  INDEX idx_siac_t_migr_liquidazione ON migr_liquidazione
  USING btree (numero_liquidazione,anno_esercizio,ente_proprietario_id);
CREATE  INDEX idx_siac_t_migr_liquidazione_movgest ON migr_liquidazione
  USING btree (anno_impegno,numero_impegno,ente_proprietario_id);
CREATE INDEX idx_siac_t_migr_liquidazione_ente ON siac.migr_liquidazione
  USING btree (ente_proprietario_id);
CREATE INDEX idx_siac_t_migr_liquidazione_ente2 ON siac.migr_liquidazione
  USING btree (ente_proprietario_id,fl_elab);

create table migr_liquidazione_scarto
(
  migr_liquidazione_scarto_id serial,
  migr_liquidazione_id	  	integer not null,
  numero_liquidazione     	INTEGER  not null,
  anno_esercizio          	varchar(4) not null,
  motivo_scarto           	varchar(2500) not null,
  dettaglio_scarto          varchar(2500) null,
  data_creazione 			TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id 		INTEGER NOT NULL,
  CONSTRAINT pk_migr_liquidazione_scarto PRIMARY KEY(migr_liquidazione_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_liquidazione_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE siac_r_migr_liquidazione_t_liquidazione (
  migr_liquidazione_rel_id SERIAL,
  migr_liquidazione_id INTEGER NOT NULL,
  liquidazione_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_siac_r_migr_liquidazione_t_liquidazione PRIMARY KEY(migr_liquidazione_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_migr_liquidazione_t_liquidazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);