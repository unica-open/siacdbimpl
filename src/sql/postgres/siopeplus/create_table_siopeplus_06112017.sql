/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 06.11.2017 Sofia SIOPE PLUS
-- DDL creazione e adeguamento struttura dati
-- rilasciato in all.sql

alter table siac_t_ente_oil
 add ente_oil_codice_ipa varchar(50),
 add ente_oil_codice_istat varchar(50),
 add ente_oil_codice_tramite varchar(150),
 add ente_oil_codice_tramite_bt varchar(150),
 add ente_oil_riferimento varchar(150),
 add ente_oil_siope_plus boolean default false;




alter table mif_t_ordinativo_spesa
 add mif_ord_codice_ente_ipa varchar(50),
 add mif_ord_codice_ente_istat varchar(50),
 add mif_ord_codice_ente_tramite varchar(150),
 add mif_ord_codice_ente_tramite_bt varchar(150),
 add mif_ord_riferimento_ente varchar(150),
 add mif_ord_importo_benef varchar(50),
 add mif_ord_pagam_postalizza varchar(150),
 add mif_ord_commissioni_esenzione varchar(150),
 add mif_ord_indir_del varchar(150),
 add mif_ord_stato_del varchar(150),
 add mif_ord_partiva_del varchar(150),
 add mif_ord_class_tipo_debito varchar(150),
 add mif_ord_class_tipo_debito_nc varchar(150),
 add mif_ord_class_cig varchar(150),
 add mif_ord_class_motivo_nocig varchar(150),
 add mif_ord_class_missione varchar(150),
 add mif_ord_class_programma varchar(150),
 add mif_ord_class_economico varchar(150),
 add mif_ord_class_importo_economico varchar(150),
 add mif_ord_class_transaz_ue varchar(150),
 add mif_ord_class_ricorrente_spesa varchar(150),
 add mif_ord_class_cofog_codice varchar(150),
 add mif_ord_class_cofog_importo varchar(50),
 add mif_ord_codice_distinta  varchar(50),
 add mif_ord_codice_atto_contabile  varchar(100);


alter table mif_t_ordinativo_spesa
alter column  mif_ord_class_codice_cup TYPE varchar(150);

alter table mif_t_ordinativo_spesa
 alter column  mif_ord_rif_doc_esterno TYPE varchar(150),
 alter column  mif_ord_lingua TYPE varchar(150);


alter table mif_t_ordinativo_spesa_id
 add mif_ord_siope_tipo_debito_id INTEGER,
 add mif_ord_siope_assenza_motivazione_id integer;


alter table mif_t_ordinativo_spesa_documenti
add   mif_ord_doc_codice_ipa_ente  varchar(50),
add   mif_ord_doc_tipo             varchar(50),
add   mif_ord_doc_tipo_a           varchar(50),
add   mif_ord_doc_id_lotto_sdi     varchar(150),
add   mif_ord_doc_tipo_analog      varchar(50),
add   mif_ord_doc_codfisc_emis     varchar(50),
add   mif_ord_doc_anno             varchar(4),
add   mif_ord_doc_numero           varchar(100),
add   mif_ord_doc_importo          varchar(50),
add   mif_ord_doc_data_scadenza    varchar(20),
add   mif_ord_doc_motivo_scadenza  varchar(100),
add   mif_ord_doc_natura_spesa     varchar(50);



alter table mif_t_ordinativo_entrata
 add mif_ord_codice_ente_ipa varchar(50),
 add mif_ord_codice_ente_istat varchar(50),
 add mif_ord_codice_ente_tramite varchar(150),
 add mif_ord_codice_ente_tramite_bt varchar(150),
 add mif_ord_riferimento_ente varchar(150),
 add mif_ord_vers_cc_postale varchar(50),
 add mif_ord_class_tipo_debito varchar(150),
 add mif_ord_class_tipo_debito_nc varchar(150),
 add mif_ord_class_economico   varchar(150),
 add mif_ord_class_importo_economico varchar(50),
 add mif_ord_class_transaz_ue varchar(150),
 add mif_ord_class_ricorrente_entrata varchar(150),
 add mif_ord_bollo_carico varchar(150),
 add mif_ord_stato_versante varchar(10),
 add mif_ord_codice_distinta  varchar(50),
 add mif_ord_codice_atto_contabile  varchar(100);

alter table mif_t_ordinativo_entrata_id
 add MIF_ORD_CODBOLLO_ID integer;




CREATE TABLE siac_d_codicebollo_plus (
  codbollo_plus_id SERIAL,
  codbollo_plus_code VARCHAR(200) NOT NULL,
  codbollo_plus_desc VARCHAR(500) NOT NULL,
  codbollo_plus_esente boolean    not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_codicebollo_plus PRIMARY KEY(codbollo_plus_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_codicebollo_plus FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_codicebollo_plus_1 ON siac_d_codicebollo_plus
  USING btree (codbollo_plus_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE TABLE siac_r_codicebollo_plus (
  codbollo_rel_id SERIAL,
  codbollo_id   integer not null,
  codbollo_plus_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_codicebollo_plus PRIMARY KEY(codbollo_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_codicebollo_plus FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_codicebollo_siac_r_codicebollo_plus FOREIGN KEY (codbollo_id)
    REFERENCES siac_d_codicebollo(codbollo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_codicebollo_plus_siac_r_codicebollo_plus FOREIGN KEY (codbollo_plus_id)
    REFERENCES siac_d_codicebollo_plus(codbollo_plus_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


CREATE TABLE siac_d_commissione_tipo_plus (
  comm_tipo_plus_id SERIAL,
  comm_tipo_plus_code VARCHAR(200) NOT NULL,
  comm_tipo_plus_desc VARCHAR(500) NOT NULL,
  comm_tipo_plus_esente boolean not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_commissione_tipo_plus PRIMARY KEY(comm_tipo_plus_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_commissione_tipo_plus FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_commissione_tipo_plus_1 ON siac.siac_d_commissione_tipo_plus
  USING btree (comm_tipo_plus_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);



CREATE TABLE siac_r_commissione_tipo_plus (
  comm_tipo_rel_id SERIAL,
  comm_tipo_id   integer not null,
  comm_tipo_plus_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_commissione_tipo_plus PRIMARY KEY(comm_tipo_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_commissione_tipo_plus FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_commissione_tipo_plus_siac_r_commissione_tipo_plus FOREIGN KEY (comm_tipo_plus_id)
    REFERENCES siac_d_commissione_tipo_plus(comm_tipo_plus_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_commissione_tipo_siac_r_commissione_tipo_plus FOREIGN KEY (comm_tipo_id)
    REFERENCES siac_d_commissione_tipo(comm_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


CREATE TABLE siac_r_accredito_tipo_plus(
  accredito_tipo_plus_rel_id SERIAL,
  accredito_tipo_oil_id   integer not null,
  accredito_tipo_oil_desc_incasso      varchar(150) not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_accredito_tipo_plus PRIMARY KEY(accredito_tipo_plus_rel_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_accredito_tipo_plus FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_accredito_tipo_oil_siac_r_accredito_tipo_plus FOREIGN KEY (accredito_tipo_oil_id)
    REFERENCES siac_d_accredito_tipo_oil(accredito_tipo_oil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);