/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table if exists  migr_elenco_doc_allegati cascade;
drop table if exists  migr_atto_allegato cascade;
drop table if exists  migr_atto_allegato_sog cascade;
drop table if exists  migr_doc_spesa cascade;
drop table if exists  migr_docquo_spesa cascade;
drop table if exists  migr_doc_entrata cascade;
drop table if exists  migr_docquo_entrata cascade;
drop table if exists  migr_relaz_documenti cascade;


drop table if exists  MIGR_DOC_SPESA_SCARTO cascade;
drop table if exists  MIGR_DOCQUO_SPESA_SCARTO cascade;
drop table if exists  MIGR_DOC_ENTRATA_SCARTO cascade;
drop table if exists  MIGR_DOCQUO_ENTRATA_SCARTO cascade;
drop table if exists  migr_elenco_doc_scarto cascade;
drop table if exists  migr_atto_allegato_scarto cascade;
drop table if exists  migr_relaz_documenti_scarto cascade;

drop table if exists siac_r_migr_doc_spesa_t_doc cascade;
drop table if exists siac_r_migr_docquo_spesa_t_subdoc cascade;

drop table if exists siac_r_migr_doc_entrata_t_doc cascade;
drop table if exists siac_r_migr_docquo_entrata_t_subdoc cascade;

drop table if exists siac_r_migr_elenco_doc_all_t_elenco_doc cascade;
drop table if exists siac_r_migr_atto_all_t_atto_allegato cascade;
drop table if exists siac_r_migr_relaz_documenti_doc cascade;

-- tabelle per migrazione iva
--drop table if exists migr_doc_spesa_iva cascade;
drop table if exists migr_docquo_spesa_iva cascade;
drop table if exists migr_docquo_spesa_iva_aliquota cascade;
drop table if exists migr_relaz_docquo_spesa_iva cascade;

drop table if exists MIGR_DOCQUO_SPESA_IVA_SCARTO cascade;
drop table if exists migr_docquo_spesa_iva_aliquota_scarto cascade;
drop table if exists migr_relaz_docquo_spesa_iva_scarto cascade;

--drop table if exists siac_r_migr_docspesaiva_t_doc_iva cascade;
drop table if exists siac_r_migr_docquospesaiva_t_subdoc_iva cascade;
drop table if exists siac_r_migr_docquospesaivaaliq_t_ivamov cascade;
drop table if exists siac_r_migr_relazdocquospesaiva_subdoc cascade;

-- fine tabelle per migrazione iva

create table  migr_atto_allegato
(
  migr_atto_allegato_id serial,
  atto_allegato_id integer not null,
  tipo_provvedimento varchar(20) null,
  anno_provvedimento  varchar(4) not null,
  numero_provvedimento_calcolato varchar(20) not null,
  numero_provvedimento  varchar(20) not null ,
  sac_provvedimento varchar(20) null,
  settore varchar(50) null,
  causale varchar(500) not null,
  annotazioni varchar(500) null,
  note varchar(500) null,
  pratica varchar(500) null,
  responsabile_amm varchar(500) null,
  responsabile_cont varchar(500) null,
  altri_allegati varchar(500) null,
  dati_sensibili char(1) DEFAULT 'N' not null,
  data_scadenza  varchar(10) null,
  causale_sospensione varchar(500) null,
  data_sospensione varchar(10) null,
  data_riattivazione varchar(10) null,
  codice_soggetto integer default 0 not null,
  stato varchar(10) not null,
  data_completamento varchar(10) ,
  numero_titolario varchar(500),
  anno_titolario varchar(4),
  versione integer,
  utente_creazione  varchar(50) not null,
  utente_modifica varchar(50)  null,
  ente_proprietario_id integer not null,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  attoal_flag_ritenute CHAR(1) DEFAULT 'N' NOT NULL,                 -- DAVIDE - 03.01.2017
  CONSTRAINT pk_siac_t_migr_atto_allegato PRIMARY KEY(migr_atto_allegato_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_atto_allegato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE  INDEX idx_siac_t_migr_atto_alleggato_prov ON migr_atto_allegato
  USING btree (anno_provvedimento,numero_provvedimento, tipo_provvedimento, sac_provvedimento, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_atto_allegato_al ON migr_atto_allegato
  USING btree (atto_allegato_id, ente_proprietario_id);

create table  migr_atto_allegato_sog
(
  migr_atto_allegato_sog_id serial,
  atto_allegato_sog_id integer not null,
  atto_allegato_id integer not null,
  codice_soggetto integer default 0 not null,
  causale_sospensione varchar(500) null,
  data_sospensione varchar(10) null,
  data_riattivazione varchar(10) null,
  ente_proprietario_id integer not null,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_atto_allegato_sog PRIMARY KEY(migr_atto_allegato_sog_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_atto_allegato_sog FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE  INDEX idx_siac_t_migr_atto_allegato_sog_al ON migr_atto_allegato_sog
  USING btree (atto_allegato_id, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_atto_allegato_sog_als ON migr_atto_allegato_sog
  USING btree (atto_allegato_id,atto_allegato_sog_id, ente_proprietario_id);

create table  migr_elenco_doc_allegati
(
  migr_elenco_doc_id serial,
  elenco_doc_id  integer not null,
  atto_allegato_id  integer not null,
  anno_elenco  varchar(4) not null,
  numero_elenco  integer not null,
  stato  varchar(3) not null,
  data_trasmissione  varchar(10) null,
  tipo_provvedimento varchar(20) null,
  anno_provvedimento  varchar(4) not null,
  numero_provvedimento  varchar(20) not null ,
  sac_provvedimento varchar(20) null,
  ente_proprietario_id integer not null,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT pk_siac_t_migr_elenco_doc_allegati PRIMARY KEY(migr_elenco_doc_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_migr_elenco_doc_all_id FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE  INDEX idx_siac_t_migr_elenco_doc_all_el ON migr_elenco_doc_allegati
  USING btree (anno_elenco, numero_elenco, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_elenco_doc_all_prov ON migr_elenco_doc_allegati
  USING btree (anno_provvedimento,numero_provvedimento, tipo_provvedimento, sac_provvedimento, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_elenco_doc_all_al ON migr_elenco_doc_allegati
  USING btree (atto_allegato_id, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_elenco_doc_all_elid ON migr_elenco_doc_allegati
  USING btree (elenco_doc_id, ente_proprietario_id);




create table migr_doc_spesa
(
 migr_docspesa_id serial,
 docspesa_id	integer not null,
 tipo	varchar(10) not null,
 anno	varchar(4) not null,
 numero	varchar(50) not null,
 codice_soggetto	integer not null,
 sede_id integer,
 codice_soggetto_pag	integer not null,
 stato	varchar(3) not null,
 descrizione	varchar(500) not null,
 date_emissione	varchar(10)  not null,
 data_scadenza	varchar(10)  null,
 data_scandenza_new	varchar(19) null,
 termine_pagamento	integer not null,
 importo	NUMERIC DEFAULT 0 NOT NULL,
 arrotondamento	NUMERIC DEFAULT 0 NOT NULL,
 bollo	varchar(5) null,
 codice_pcc	varchar(10) null,
 codice_ufficio	varchar(10) null,
 data_ricezione	varchar(19) null,
 data_repertorio	varchar(19) null,
 numero_repertorio	integer not null,
 anno_repertorio	varchar(4) null,
 note	varchar(500) null,
 causale_sospensione	varchar(500) null,
 data_sospensione	varchar(19) null,
 data_riattivazione	varchar(19) null,
 codice_fiscale_pign	varchar(16) null,
 tipo_impresa	varchar(5) null,
 data_registro_fatt	varchar(10) null,
 numero_registro_fatt	integer not null,
 anno_registro_fatt	varchar(4) null,
 collegato_cec varchar(1) not NULL,
 utente_creazione	varchar(50) not null,
 utente_modifica	varchar(50) not null,
 ente_proprietario_id integer not null,
 fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 CONSTRAINT pk_siac_t_migr_doc_spesa PRIMARY KEY(migr_docspesa_id),
 CONSTRAINT siac_t_ente_proprietario_siac_t_migr_doc_spesa_id FOREIGN KEY (ente_proprietario_id)
   REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE  INDEX idx_siac_t_migr_doc_spesa_key ON migr_doc_spesa
  USING btree (tipo,anno,numero,codice_soggetto, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_doc_spesa_sog ON migr_doc_spesa
  USING btree (codice_soggetto, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_doc_spesa_pag ON migr_doc_spesa
  USING btree (codice_soggetto_pag, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_doc_spesa_stato ON migr_doc_spesa
  USING btree (stato, ente_proprietario_id);


create table migr_docquo_spesa
(
 migr_docquo_spesa_id serial,
 docquospesa_id	integer not null,
 docspesa_id	integer not null,
 tipo	varchar(10) not null,
 anno	varchar(4) not null,
 numero	varchar(50) not null,
 codice_soggetto	integer not null,
 frazione	integer not null,
 sede_id integer,
 elenco_doc_id	integer not null,
 codice_soggetto_pag	integer not null,
 codice_modpag	varchar(10)  null,
 codice_modpag_del	varchar(10)  null,
 codice_indirizzo	integer not null,
 sede_secondaria varchar(1) default 'N' not null,
 importo	NUMERIC DEFAULT 0 NOT NULL,
 importo_da_dedurre	NUMERIC DEFAULT 0 NOT NULL,
 anno_esercizio	varchar(4) null,
 anno_impegno	varchar(4) null,
 numero_impegno	integer not null,
 numero_subimpegno	integer not null,
 anno_provvedimento	varchar(4)  null,
 numero_provvedimento	integer null,
 tipo_provvedimento	varchar(20) null,
 sac_provvedimento	varchar(20)  null,
 oggetto_provvedimento	varchar(500) null,
 note_provvedimento	varchar(500) null,
 stato_provvedimento	varchar(50) null,
 descrizione	varchar(500) null,
 numero_iva	varchar(20) null,
 flag_rilevante_iva	char(1) default 'N' not null,
 data_scadenza	varchar(10) null,
 data_scadenza_new	varchar(19) null,
 cup	varchar(20) null,
 cig	varchar(20) null,
 commissioni	varchar(2) null,
 causale_sospensione	varchar(500) null,
 data_sospensione	varchar(19)  null,
 data_riattivazione	varchar(19) null,
 flag_ord_singolo	char(1) default 'N' not null,
 flag_avviso	char(1) default 'N' not null,
 tipo_avviso	varchar(10) null,
 flag_esproprio	char(1) default 'N' not null,
 flag_manuale	char(1),
 note	varchar(500) null,
 causale_ordinativo	varchar(500) null,
 numero_mutuo	integer not null,
 annotazione_certif_crediti	varchar(500) null,
 data_certif_crediti	varchar(19) null,
 note_certif_crediti	varchar(500) null,
 numero_certif_crediti	varchar(50) null,
 flag_certif_crediti	char(1)     null,
 numero_liquidazione	integer not null,
 numero_mandato	integer not null,
 anno_elenco  varchar(4)  null,
 numero_elenco  integer default 0 not null,
 importo_splitreverse NUMERIC null,
 tipo_iva_splitreverse varchar(10) null,
 data_pagamento_cec varchar(10) null,
 utente_creazione	varchar(50) null,
 utente_modifica	varchar(50) null ,
 ente_proprietario_id integer not null,
 fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 codice_pcc     varchar(10),
 codice_ufficio varchar(10)
 CONSTRAINT pk_siac_t_migr_docquo_spesa PRIMARY KEY(migr_docquo_spesa_id),
 CONSTRAINT siac_t_ente_proprietario_siac_t_migr_docquo_spesa_id FOREIGN KEY (ente_proprietario_id)
   REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);




CREATE  INDEX idx_siac_t_migr_docquo_spesa_key ON migr_docquo_spesa
  USING btree (tipo,anno,numero,codice_soggetto,frazione, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_docquo_spesa_doc_key ON migr_docquo_spesa
  USING btree (tipo,anno,numero,codice_soggetto, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_docquo_spesa_mdp ON migr_docquo_spesa
  USING btree (codice_modpag,codice_soggetto, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_docquo_spesa_mdp_del ON migr_docquo_spesa
  USING btree (codice_modpag_del, codice_modpag,codice_soggetto,ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_docquo_spesa_mdp_ind ON migr_docquo_spesa
  USING btree (codice_indirizzo,codice_soggetto,ente_proprietario_id);

create table migr_doc_entrata
(
 migr_docentrata_id serial,
 docentrata_id	integer not null,
 tipo	varchar(10) not null,
 anno	varchar(4) not null,
 numero	varchar(20) not null,
 codice_soggetto	integer not null,
 codice_soggetto_inc	integer not null,
 stato	varchar(3) not null,
 descrizione	varchar(500) not null,
 data_emissione	varchar(10) not null,
 data_scadenza	varchar(10) null,
 importo	NUMERIC DEFAULT 0 NOT NULL,
 arrotondamento	NUMERIC DEFAULT 0 NOT NULL,
 bollo	varchar(5) null,
 data_repertorio	varchar(19) null,
 numero_repertorio	integer not null,
 anno_repertorio	varchar(4) null,
 note	varchar(500) null,
 data_registro_fatt	varchar(10) null,
 numero_registro_fatt	integer not null,
 anno_registro_fatt	varchar(4) null,
 utente_creazione	varchar(50) not null,
 utente_modifica	varchar(50) not null,
 ente_proprietario_id integer not null,
 fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 CONSTRAINT pk_siac_t_migr_doc_entrata PRIMARY KEY(migr_docentrata_id),
 CONSTRAINT siac_t_ente_proprietario_siac_t_migr_doc_entrata_id FOREIGN KEY (ente_proprietario_id)
   REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE  INDEX idx_siac_t_migr_doc_entrata_key ON migr_doc_entrata
  USING btree (tipo,anno,numero,codice_soggetto, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_doc_entrata_sog ON migr_doc_entrata
  USING btree (codice_soggetto, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_doc_entrata_inc ON migr_doc_entrata
  USING btree (codice_soggetto_inc, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_doc_entrata_stato ON migr_doc_entrata
  USING btree (stato, ente_proprietario_id);


create table migr_docquo_entrata
(
 migr_docquo_entrata_id serial,
 docquoentrata_id	integer not null,
 docentrata_id	integer not null,
 tipo	varchar(10) not null,
 anno	varchar(4) not null,
 numero	varchar(20) not null,
 codice_soggetto	integer not null,
 codice_soggetto_inc	integer not null,
 frazione	integer not null,
 elenco_doc_id	integer not null,
 importo	NUMERIC DEFAULT 0 NOT NULL,
 anno_esercizio	varchar(4) null,
 anno_accertamento	varchar(4) null,
 numero_accertamento	integer not null,
 numero_subaccertamento	integer not null,
 anno_provvedimento	varchar(4)  null,
 numero_provvedimento	integer null,
 tipo_provvedimento	varchar(20) null,
 sac_provvedimento	varchar(20)  null,
 oggetto_provvedimento	varchar(500) null,
 note_provvedimento	varchar(500) null,
 stato_provvedimento	varchar(50) null,
 descrizione	varchar(500) null,
 numero_iva	varchar(20) null,
 flag_rilevante_iva	char(1) default 'N' not null,
 data_scadenza	varchar(10) null,
 flag_ord_singolo	char(1) default 'N' not null,
 flag_avviso	char(1) default 'N' not null,
 tipo_avviso	varchar(10) null,
 flag_esproprio	char(1) default 'N' not null,
 flag_manuale	char(1),
 note	varchar(500) null,
 numero_riscossione	integer not null,
 anno_elenco  varchar(4)  null,
 numero_elenco  integer default 0 not null,
 utente_creazione	varchar(50) not null,
 utente_modifica	varchar(50) null ,
 ente_proprietario_id integer not null,
 fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 CONSTRAINT pk_siac_t_migr_docquo_entrata PRIMARY KEY(migr_docquo_entrata_id),
 CONSTRAINT siac_t_ente_proprietario_siac_t_migr_docquo_entrata_id FOREIGN KEY (ente_proprietario_id)
   REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE  INDEX idx_siac_t_migr_docquo_entrata_key ON migr_docquo_entrata
  USING btree (tipo,anno,numero,codice_soggetto,frazione, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_docquo_entrata_doc_key ON migr_docquo_entrata
  USING btree (tipo,anno,numero,codice_soggetto, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_docquo_entrata_sog ON migr_docquo_entrata
  USING btree (codice_soggetto, ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_docquo_entrata_sin ON migr_docquo_entrata
  USING btree (codice_soggetto_inc, ente_proprietario_id);




create table migr_relaz_documenti
(
 migr_relaz_doc_id serial,
 relazdoc_id	integer not null,
 relaz_tipo	varchar(10) not null,
 tipo_da	varchar(10) not null,
 anno_da	varchar(4) not null,
 numero_da	varchar(20) not null,
 codice_soggetto_da	integer not null,
 doc_id_da	integer not null,
 tipo_a	varchar(10) not null,
 anno_a	varchar(4) not null,
 numero_a	varchar(20) not null,
 codice_soggetto_a	integer not null,
 doc_id_a	integer not null,
 ente_proprietario_id integer not null,
 fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 CONSTRAINT pk_siac_t_migr_relaz_documenti PRIMARY KEY(migr_relaz_doc_id),
 CONSTRAINT siac_t_ente_proprietario_siac_t_migr_relaz_documenti_id FOREIGN KEY (ente_proprietario_id)
   REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE  INDEX idx_siac_t_migr_relaz_documenti_key_da ON migr_relaz_documenti
  USING btree (tipo_da,anno_da,numero_da,codice_soggetto_da,ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_relaz_documenti_key_a ON migr_relaz_documenti
  USING btree (tipo_a,anno_a,numero_a,codice_soggetto_a,ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_relaz_documenti_da ON migr_relaz_documenti
  USING btree (doc_id_da,ente_proprietario_id);

CREATE  INDEX idx_siac_t_migr_relaz_documenti_a ON migr_relaz_documenti
  USING btree (doc_id_a,ente_proprietario_id);

create table migr_atto_allegato_scarto
(
  migr_atto_allegato_scarto_id serial,
  migr_atto_allegato_id integer,
  motivo_scarto      VARCHAR(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_atto_allegato_scarto PRIMARY KEY(migr_atto_allegato_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_atto_allegato_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table migr_elenco_doc_scarto
(
  migr_elenco_doc_scarto_id serial,
  migr_elenco_doc_id integer,
  motivo_scarto      VARCHAR(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_elenco_doc_scarto PRIMARY KEY(migr_elenco_doc_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_doc_spesa_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table migr_relaz_documenti_scarto
(
  migr_relaz_doc_scarto_id serial,
  migr_relaz_doc_id integer,
  motivo_scarto      VARCHAR(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_relaz_documenti_scarto PRIMARY KEY(migr_relaz_doc_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_relaz_documenti_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table MIGR_DOC_SPESA_SCARTO
(
  migr_doc_spesa_scarto_id serial,
  migr_doc_spesa_id integer not null,
  motivo_scarto          VARCHAR(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_doc_spesa_scarto PRIMARY KEY(migr_doc_spesa_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_doc_spesa_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


create table MIGR_DOCQUO_SPESA_SCARTO
(
  migr_docquo_spesa_scarto_id serial,
  migr_docquo_spesa_id integer,
  motivo_scarto          VARCHAR(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_docquo_spesa_scarto PRIMARY KEY(migr_docquo_spesa_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_doc_spesa_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);



create table MIGR_DOC_ENTRATA_SCARTO
(
  migr_doc_entrata_scarto_id serial,
  migr_doc_entrata_id integer not null,
  motivo_scarto          VARCHAR(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_doc_entrata_scarto PRIMARY KEY(migr_doc_entrata_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_doc_entrata_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);




create table MIGR_DOCQUO_ENTRATA_SCARTO
(
  migr_docquo_entrata_scarto_id serial,
  migr_docquo_entrata_id integer,
  motivo_scarto          VARCHAR(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_docquo_entrata_scarto PRIMARY KEY(migr_docquo_entrata_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_doc_spesa_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE TABLE siac_r_migr_doc_spesa_t_doc
(
  migr_doc_spesa_rel_id serial,
  migr_doc_spesa_id integer not null,
  doc_id integer,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_doc_spesa_t_doc PRIMARY KEY(migr_doc_spesa_rel_id),
  CONSTRAINT siac_t_ente_proprietario_migr_doc_spesa_t_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

);

CREATE TABLE siac_r_migr_docquo_spesa_t_subdoc
(
  migr_docquo_spesa_rel_id serial,
  migr_docquo_spesa_id integer not null,
  subdoc_id integer,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_docquo_spesa_t_subdoc PRIMARY KEY(migr_docquo_spesa_rel_id),
  CONSTRAINT siac_t_ente_proprietario_migr_docquo_spesa_t_subdoc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

);
CREATE  INDEX siac_r_migr_docquo_spesa_t_subdoc_subdoc ON siac_r_migr_docquo_spesa_t_subdoc
  USING btree (subdoc_id,ente_proprietario_id);

CREATE TABLE siac_r_migr_doc_entrata_t_doc
(
  migr_doc_entrata_rel_id serial,
  migr_doc_entrata_id integer not null,
  doc_id integer,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_doc_entrata_t_doc PRIMARY KEY(migr_doc_entrata_rel_id),
  CONSTRAINT siac_t_ente_proprietario_migr_doc_entrata_t_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

);

CREATE TABLE siac_r_migr_docquo_entrata_t_subdoc
(
  migr_docquo_entrata_rel_id serial,
  migr_docquo_entrata_id integer not null,
  subdoc_id integer,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_docquo_entrata_t_subdoc PRIMARY KEY(migr_docquo_entrata_rel_id),
  CONSTRAINT siac_t_ente_proprietario_migr_docquo_entrata_t_subdoc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

);

CREATE  INDEX siac_r_migr_docquo_entrata_t_subdoc_subdoc ON siac_r_migr_docquo_entrata_t_subdoc
  USING btree (subdoc_id,ente_proprietario_id);

CREATE TABLE siac_r_migr_elenco_doc_all_t_elenco_doc
(
  migr_elenco_doc_rel_id serial,
  migr_elenco_doc_id integer not null,
  eldoc_id integer,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_elenco_doc_all_t_elenco PRIMARY KEY(migr_elenco_doc_rel_id),
  CONSTRAINT siac_t_ente_proprietario_migr_elenco_doc_all_t_elenco FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

);

CREATE  INDEX siac_r_migr_elenco_doc_all_t_elenco_eldoc ON siac_r_migr_elenco_doc_all_t_elenco_doc
  USING btree (eldoc_id,ente_proprietario_id);

CREATE TABLE siac_r_migr_atto_all_t_atto_allegato
(
  migr_atto_allegato_rel_id serial,
  migr_atto_allegato_id integer not null,
  attoal_id integer,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_atto_all_t_atto_allegato PRIMARY KEY(migr_atto_allegato_rel_id),
  CONSTRAINT siac_t_ente_proprietario_migr_atto_all_t_atto_all FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

);

CREATE  INDEX siac_r_migr_atto_all_t_atto_allegato_attoall ON siac_r_migr_atto_all_t_atto_allegato
  USING btree (attoal_id,ente_proprietario_id);


CREATE TABLE siac_r_migr_relaz_documenti_doc
(
  migr_relaz_doc_rel_id serial,
  migr_relaz_doc_id integer not null,
  doc_r_id integer,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_relaz_documenti_doc PRIMARY KEY(migr_relaz_doc_rel_id),
  CONSTRAINT siac_t_ente_proprietario_migr_relaz_documenti_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

);

CREATE  INDEX siac_r_migr_relaz_documenti_doc_doc ON siac_r_migr_relaz_documenti_doc
  USING btree (doc_r_id,ente_proprietario_id);

CREATE  INDEX siac_r_migr_relaz_documenti_doc_migr ON siac_r_migr_relaz_documenti_doc
  USING btree (migr_relaz_doc_id,ente_proprietario_id);


-- TABELLE IVA
create table migr_docquo_spesa_iva
( migr_docquo_spesa_iva_id serial,
  docquo_spesa_iva_id integer not null,
  anno_esercizio varchar(4)not null,
  numero_docquo_iva integer not null,
  docspesa_id  integer not null,
  tipo varchar(10) not null,
  anno	varchar(4) not null,
  numero varchar(30) not null,
  codice_soggetto	integer not null,
  sezionale varchar(2) not null,
  tipo_registro varchar(2) not null,
  gruppo varchar(3) not null,
  numero_prot_prov varchar(200) not null,
  data_prot_prov varchar(10) not null,
  data_registrazione varchar(10) not null,
  stato varchar(2) not null,
  flag_registrazione_tipo_iva varchar(2) not null,
  flag_registrazione_iva varchar(1) not null,
  flag_intracomunitario varchar(1) not null,
  flag_rilevante_irap varchar(1) not null,
  flag_nota_credito varchar(1) not null,
  ente_proprietario_id integer not null,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 CONSTRAINT pk_siac_t_migr_docquospesaiva PRIMARY KEY(migr_docquo_spesa_iva_id),
 CONSTRAINT siac_t_ente_proprietario_siac_t_migr_docquospesaiva_id FOREIGN KEY (ente_proprietario_id)
   REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE  INDEX migr_docquo_spesa_iva_doc_spesa ON migr_docquo_spesa_iva
  USING btree (docspesa_id);


create table migr_docquo_spesa_iva_aliquota
( migr_docquospesa_iva_aliquota_id serial,
  docquospesa_iva_aliquota_id integer not null,
  docquo_spesa_iva_id integer not null,
  tipo  varchar(10) not null,
  anno	varchar(4) not null,
  numero varchar(30) not null,
  codice_soggetto integer not null,
  cod_aliquota varchar(3) not null,
  importo_imponibile NUMERIC not null,
  imposta NUMERIC not null,
  totale NUMERIC not null,
  ente_proprietario_id integer not null,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 CONSTRAINT pk_siac_t_migr_docquospesaivaaliq PRIMARY KEY(migr_docquospesa_iva_aliquota_id),
 CONSTRAINT siac_t_ente_proprietario_siac_t_migr_docquospesaivaaliq_id FOREIGN KEY (ente_proprietario_id)
   REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE  INDEX migr_docquospesaivaaliq_docquospesaiva ON migr_docquo_spesa_iva_aliquota
  USING btree (docquo_spesa_iva_id);


create table migr_relaz_docquo_spesa_iva
(migr_relazdocquo_id serial,
 relazdocquo_id integer not null,
 relaz_tipo varchar(10) not null,
 tipo_da varchar(10) not null,
 anno_da varchar(4) not null,
 numero_da varchar(30) not null,
 codice_soggetto_da integer not null,
 docquo_spesa_iva_id_da integer not null,
 tipo_a  varchar(10) not null,
 anno_a varchar(4) not null,
 numero_a varchar(30) not null,
 codice_soggetto_a integer not null,
 docquo_spesa_iva_id_a integer not null,
  ente_proprietario_id integer not null,
  fl_elab CHAR(1) DEFAULT 'N' NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 CONSTRAINT pk_siac_t_migr_relazdocquospesaiva PRIMARY KEY(migr_relazdocquo_id),
 CONSTRAINT siac_t_ente_proprietario_siac_t_migr_relazdocquospesaiva_id FOREIGN KEY (ente_proprietario_id)
   REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE siac_r_migr_docquospesaiva_t_subdoc_iva
(
  migr_docquo_spesa_iva_rel_id serial,
  migr_docquo_spesa_iva_id integer not null,
  subdociva_id integer,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_docquospesaiva_t_subdoc_iva PRIMARY KEY(migr_docquo_spesa_iva_rel_id),
  CONSTRAINT siac_t_ente_proprietario_migr_docquospesaiva_t_subdoc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE siac_r_migr_docquospesaivaaliq_t_ivamov
(migr_docquo_spesa_iva_aliquota_t_ivamov_rel_id SERIAL,
 migr_docquospesa_iva_aliquota_id integer not null,
 ivamov_id  integer not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_docquospesaivaaliq_t_ivamov PRIMARY KEY(migr_docquo_spesa_iva_aliquota_t_ivamov_rel_id),
  CONSTRAINT siac_t_ente_proprietario_migr_docquospesaivaaliq_t_ivamov FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE TABLE siac_r_migr_relazdocquospesaiva_subdoc
(migr_relazdocquo_rel_id SERIAL,
 migr_relazdocquo_id integer not null,
 doc_r_id  integer not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_relazdocquospesaiva_subdoc PRIMARY KEY(migr_relazdocquo_rel_id),
  CONSTRAINT siac_t_ente_proprietario_migr_relazdocquospesaiva_subdoc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table MIGR_DOCQUO_SPESA_IVA_SCARTO
(
  migr_docquo_spesa_iva_scarto_id serial,
  migr_docquo_spesa_iva_id integer not null,
  motivo_scarto  VARCHAR(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_docquospesaiva_scarto PRIMARY KEY(migr_docquo_spesa_iva_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_docquospesaiva_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table migr_docquo_spesa_iva_aliquota_scarto
(
  migr_docquospesa_iva_aliquota_scarto_id serial,
  migr_docquospesa_iva_aliquota_id integer not null,
  motivo_scarto  VARCHAR(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_docquospesaivaaliquota_scarto PRIMARY KEY(migr_docquospesa_iva_aliquota_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_docquospesaivaaliquota_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

create table migr_relaz_docquo_spesa_iva_scarto
(
  migr_relazdocquo_scarto_id serial,
  migr_relazdocquo_id integer not null,
  motivo_scarto  VARCHAR(2500) not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_migr_relazdocquospesaiva_scarto PRIMARY KEY(migr_relazdocquo_scarto_id),
  CONSTRAINT siac_t_ente_proprietario_migr_relazdocquospesaiva_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);