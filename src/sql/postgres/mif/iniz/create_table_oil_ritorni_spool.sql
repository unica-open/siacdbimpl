/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table mif_t_elab_emap_hrer;
drop table mif_t_elab_emap_rr;
drop table mif_t_elab_emap_dr;

drop table mif_t_elab_emfe_hrer;
drop table mif_t_elab_emfe_rr;


CREATE TABLE mif_t_elab_emap_hrer
(
  mif_t_elab_hrer_id serial,
  flusso_elab_mif_id integer,
  id integer,
  tipo_record VARCHAR(2),
  data_ora_flusso VARCHAR(19),
  tipo_flusso CHAR(1),
  codice_abi_bt VARCHAR(5),
  codice_ente_bt VARCHAR(7),
  tipo_servizio VARCHAR(8),
  aid VARCHAR(6),
  num_ricevute VARCHAR(7),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id integer,
  CONSTRAINT mif_t_elab_emap_hrer_pkey PRIMARY KEY(mif_t_elab_hrer_id)
)
WITH (oids = false);

CREATE TABLE mif_t_elab_emap_rr
(
  mif_t_elab_rr_id serial,
  flusso_elab_mif_id integer,
  id integer,
  tipo_record VARCHAR(2),
  progressivo_ricevuta VARCHAR(7),
  data_messaggio VARCHAR(8),
  ora_messaggio VARCHAR(4),
  esito_derivato VARCHAR(2),
  qualificatore VARCHAR(3),
  codice_abi_bt VARCHAR(5),
  codice_ente VARCHAR(11),
  codice_ente_bt VARCHAR(7),
  codice_funzione VARCHAR(2),
  numero_ordinativo VARCHAR(7),
  esercizio VARCHAR(4),
  codice_esito VARCHAR(2),
  data_pagamento VARCHAR(10),
  importo_ordinativo VARCHAR(15),
  cro1 VARCHAR(11),
  cro2 VARCHAR(23),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id integer,
  CONSTRAINT mif_t_elab_emap_rr_pkey PRIMARY KEY(mif_t_elab_rr_id)
)
WITH (oids = false);

CREATE TABLE mif_t_elab_emap_dr (
  mif_t_elab_dr_id serial,
  flusso_elab_mif_id integer,
  id integer,
  tipo_record VARCHAR(2),
  progressivo_ricevuta VARCHAR(7),
  num_ricevuta VARCHAR(7),
  importo_ricevuta VARCHAR(15),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id integer,
  CONSTRAINT mif_t_elab_emap_dr_pkey PRIMARY KEY(mif_t_elab_dr_id)
)
WITH (oids = false);



CREATE TABLE mif_t_elab_emfe_hrer (
  mif_t_elab_hrer_id serial,
  flusso_elab_mif_id integer,
  id integer,
  tipo_record VARCHAR(2),
  data_ora_flusso VARCHAR(19),
  tipo_flusso CHAR(1),
  codice_abi_bt VARCHAR(5),
  codice_ente_bt VARCHAR(7),
  tipo_servizio VARCHAR(8),
  aid VARCHAR(6),
  num_ricevute VARCHAR(7),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id integer,
  CONSTRAINT mif_t_elab_emfe_hrer_pkey PRIMARY KEY(mif_t_elab_hrer_id)
)
WITH (oids = false);

CREATE TABLE mif_t_elab_emfe_rr (
  mif_t_elab_rr_id SERIAL,
  flusso_elab_mif_id INTEGER,
  id INTEGER,
  tipo_record VARCHAR(2),
  progressivo_ricevuta VARCHAR(7),
  data_messaggio VARCHAR(8),
  ora_messaggio VARCHAR(4),
  esito_derivato VARCHAR(2),
  qualificatore VARCHAR(3),
  codice_abi_bt VARCHAR(5),
  codice_ente VARCHAR(11),
  codice_ente_bt VARCHAR(7),
  codice_funzione VARCHAR(2),
  numero_ordinativo VARCHAR(7),
  esercizio VARCHAR(4),
  codice_esito VARCHAR(2),
  firma_data VARCHAR(10),
  firma_nome VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER,
  CONSTRAINT mif_t_elab_emfe_rr_pkey PRIMARY KEY(mif_t_elab_rr_id)
)
WITH (oids = false);

