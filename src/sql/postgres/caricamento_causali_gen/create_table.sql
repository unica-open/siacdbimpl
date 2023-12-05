/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table if exists siac_bko_t_caricamento_pdce_conto;
CREATE TABLE siac_bko_t_caricamento_pdce_conto
(
  carica_pdce_conto_id SERIAL,
  pdce_conto_code      VARCHAR not null,
  pdce_conto_desc      VARCHAR not null,
  tipo_operazione      varchar not null,
  classe_conto         varchar not null,
  livello              integer not null,
  codifica_bil         varchar not null,
  tipo_conto           varchar not null,
  conto_foglia         varchar,
  conto_di_legge       varchar,
  conto_codifica_interna varchar,
  ammortamento        varchar,
  conto_attivo        varchar not null default 'S',
  conto_segno_negativo varchar,
  caricato BOOLEAN DEFAULT false NOT NULL,
  ambito VARCHAR DEFAULT 'AMBITO_FIN'::character varying NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) DEFAULT 'admin-carica-pdce' NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine   TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id integer not null,
  CONSTRAINT pk_siac_bko_t_caricamento_pdce_conto PRIMARY KEY(carica_pdce_conto_id),
  CONSTRAINT siac_t_ente_proprietario_siac_bko_t_caricamento_pdce_conto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX siac_bko_t_caricamento_pdce_conto_idx ON siac_bko_t_caricamento_pdce_conto
  USING btree (pdce_conto_code COLLATE pg_catalog."default",
               pdce_conto_desc COLLATE pg_catalog."default",
               ambito COLLATE pg_catalog."default",
               ente_proprietario_id
               )
  WHERE (data_cancellazione IS NULL);


CREATE INDEX siac_bko_t_caricamento_pdce_conto_fk_ente_proprietario_id_idx ON siac_bko_t_caricamento_pdce_conto
  USING btree (ente_proprietario_id);


drop table if exists siac_bko_t_caricamento_causali;
CREATE TABLE siac_bko_t_caricamento_causali
(
  carica_cau_id SERIAL,
  pdc_fin VARCHAR,
  codice_causale VARCHAR,
  descrizione_causale VARCHAR,
  pdc_econ_patr VARCHAR,
  conto_iva VARCHAR,
  segno VARCHAR,
  livelli VARCHAR,
  tipo_conto VARCHAR,
  tipo_importo VARCHAR,
  utilizzo_conto VARCHAR,
  utilizzo_importo VARCHAR,
  causale_default VARCHAR,
  caricata BOOLEAN DEFAULT false NOT NULL,
  ambito VARCHAR DEFAULT 'AMBITO_FIN'::character varying NOT NULL,
  causale_tipo VARCHAR DEFAULT 'INT'::character varying NOT NULL,
  eu varchar not null,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) DEFAULT 'admin-carica-cau' NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine   TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id integer not null,
  CONSTRAINT pk_siac_bko_t_caricamento_causali PRIMARY KEY(carica_cau_id),
  CONSTRAINT siac_t_ente_proprietario_siac_bko_t_caricamento_causali FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX siac_bko_t_caricamento_causali_idx ON siac_bko_t_caricamento_causali
  USING btree (pdc_fin COLLATE pg_catalog."default",
               codice_causale COLLATE pg_catalog."default",
               descrizione_causale COLLATE pg_catalog."default",
               pdc_econ_patr COLLATE pg_catalog."default", conto_iva COLLATE pg_catalog."default",segno COLLATE pg_catalog."default",
               livelli COLLATE pg_catalog."default",
               tipo_conto COLLATE pg_catalog."default",
               tipo_importo COLLATE pg_catalog."default",
               utilizzo_conto COLLATE pg_catalog."default",
               utilizzo_importo COLLATE pg_catalog."default",
               causale_default COLLATE pg_catalog."default",
               ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE INDEX siac_bko_t_caricamento_causali_fk_ente_proprietario_id_idx ON siac_bko_t_caricamento_causali
  USING btree (ente_proprietario_id);

drop table if exists siac_bko_t_causale_evento;
CREATE TABLE siac_bko_t_causale_evento
(
  carica_cau_ev_id SERIAL,
  pdc_fin          varchar not null,
  codice_causale   varchar not null,
  tipo_evento      varchar not null,
  evento           varchar not null,
  eu               varchar not null,
  caricata BOOLEAN DEFAULT false NOT NULL,
  ambito VARCHAR DEFAULT 'AMBITO_FIN'::character varying NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) DEFAULT 'admin-carica-cau-ev' NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine   TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id integer not null,
  CONSTRAINT pk_siac_bko_t_causale_evento PRIMARY KEY(carica_cau_ev_id),
  CONSTRAINT siac_t_ente_proprietario_siac_bko_t_causale_evento FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_bko_t_causale_evento_fk_pdc_fin_idx ON siac_bko_t_causale_evento
  USING btree (pdc_fin);

CREATE INDEX siac_bko_t_causale_evento_fk_codice_causale_idx ON siac_bko_t_causale_evento
  USING btree (codice_causale);



CREATE INDEX siac_bko_t_causale_evento_fk_ente_proprietario_id_idx ON siac_bko_t_causale_evento
  USING btree (ente_proprietario_id);