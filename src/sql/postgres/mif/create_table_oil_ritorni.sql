/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
rop table siac_d_oil_qualificatore;
drop table siac_d_oil_esito_derivato;
drop table siac_d_oil_ricevuta_errore;

drop table siac_r_prov_cassa_oil_ricevuta;
drop table siac_r_ordinativo_quietanza;
drop table siac_r_ordinativo_storno;
drop table siac_r_ordinativo_firma;



drop table mif_t_elab_emap_hrer;
drop table mif_t_elab_emap_rr;
drop table mif_t_elab_emap_dr;

drop table mif_t_elab_emfe_hrer;
drop table mif_t_elab_emfe_rr;

drop table mif_t_elab_emat_hrer;
drop table mif_t_elab_emat_rr;

drop table siac_t_oil_ricevuta;
drop table mif_t_oil_ricevuta;

drop table siac_d_oil_ricevuta_tipo;






CREATE TABLE siac_d_oil_ricevuta_errore
(
  oil_ricevuta_errore_id SERIAL,
  oil_ricevuta_errore_code VARCHAR(200) NOT NULL,
  oil_ricevuta_errore_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_oil_ricevuta_errore PRIMARY KEY(oil_ricevuta_errore_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_oil_ricevuta_errore FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_oil_ricevuta_errore_code ON siac_d_oil_ricevuta_errore
  USING btree (oil_ricevuta_errore_code COLLATE pg_catalog."default",  ente_proprietario_id);


CREATE TABLE siac_d_oil_ricevuta_tipo
(
  oil_ricevuta_tipo_id SERIAL,
  oil_ricevuta_tipo_code VARCHAR(200) NOT NULL,
  oil_ricevuta_tipo_desc VARCHAR(500) NOT NULL,
  oil_ricevuta_tipo_code_fl varchar(10) not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_oil_ricevuta_tipo PRIMARY KEY(oil_ricevuta_tipo_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_oil_ricevuta_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_oil_ricevuta_tipo_code ON siac_d_oil_ricevuta_tipo
  USING btree (oil_ricevuta_tipo_code COLLATE pg_catalog."default",  ente_proprietario_id);



CREATE TABLE siac_d_oil_esito_derivato
(
  oil_esito_derivato_id SERIAL,
  oil_esito_derivato_code VARCHAR(200) NOT NULL,
  oil_esito_derivato_desc VARCHAR(500) NOT NULL,
  oil_ricevuta_tipo_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_oil_esito_derivato PRIMARY KEY(oil_esito_derivato_id),
  CONSTRAINT siac_d_oil_ricevuta_tipo_siac_d_oil_esito_derivato FOREIGN KEY (oil_ricevuta_tipo_id)
    REFERENCES siac_d_oil_ricevuta_tipo(oil_ricevuta_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_d_oil_esito_derivato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_oil_esito_derivato_code ON siac_d_oil_esito_derivato
  USING btree (oil_esito_derivato_code COLLATE pg_catalog."default",  ente_proprietario_id);

CREATE TABLE siac_d_oil_qualificatore
(
  oil_qualificatore_id SERIAL,
  oil_qualificatore_code VARCHAR(200) NOT NULL,
  oil_qualificatore_desc VARCHAR(500) NOT NULL,
  oil_qualificatore_segno char not null,
  oil_esito_derivato_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_oil_qualificatore PRIMARY KEY(oil_qualificatore_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_oil_qualificatore FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_oil_esito_derivato_siac_d_oil_qualificatore FOREIGN KEY (oil_esito_derivato_id)
    REFERENCES siac_d_oil_esito_derivato(oil_esito_derivato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_oil_qualificatore_code ON siac_d_oil_qualificatore
  USING btree (oil_qualificatore_code COLLATE pg_catalog."default",  ente_proprietario_id);

CREATE TABLE siac_t_oil_ricevuta
(
  oil_ricevuta_id SERIAL,
  oil_ricevuta_anno integer  null,
  oil_ricevuta_numero integer  null,
  oil_ricevuta_data TIMESTAMP WITHOUT TIME ZONE  NULL,
  oil_ricevuta_tipo char  null,
  oil_ricevuta_importo numeric  null,
  oil_ricevuta_cro1 varchar(50) null,
  oil_ricevuta_cro2 varchar(50) null,
  oil_ricevuta_note_tes varchar(500) null,
  oil_ricevuta_denominazione varchar(500) null,
  oil_ricevuta_note VARCHAR(500) null,
  oil_ricevuta_errore_id integer null, -- creare tabella degli errori
  oil_ricevuta_tipo_id integer not null,
  oil_ord_bil_id integer  null,
  oil_ord_id integer null,
  flusso_elab_mif_id integer not null,
  oil_progr_ricevuta_id integer null,      -- FK (non fisica) verso tabella di caricamento flusso *RR
  oil_progr_dett_ricevuta_id integer null, -- FK (non fisica) verso tabella di caricamento flusso *DR
  oil_ord_anno_bil integer null,
  oil_ord_numero integer null,
  oil_ord_importo numeric null,
  oil_ord_data_emissione TIMESTAMP WITHOUT TIME ZONE null,
  oil_ord_data_annullamento TIMESTAMP WITHOUT TIME ZONE null,
  oil_ord_trasm_oil_data TIMESTAMP WITHOUT TIME ZONE null,
  oil_ord_data_quietanza TIMESTAMP WITHOUT TIME ZONE null,
  oil_ord_data_firma TIMESTAMP WITHOUT TIME ZONE null,
  oil_ord_nome_firma  varchar(200)  null,
  oil_ord_importo_quiet numeric null,
  oil_ord_importo_storno numeric null,
  oil_ord_importo_quiet_tot numeric null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_t_oil_ricevuta PRIMARY KEY(oil_ricevuta_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_oil_ricevuta FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ordinativo_siac_t_oil_ricevuta FOREIGN KEY (oil_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT mif_t_flusso_elaborato_siac_t_oil_ricevuta FOREIGN KEY (flusso_elab_mif_id)
    REFERENCES mif_t_flusso_elaborato(flusso_elab_mif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_oil_ricevuta_tipo_siac_t_oil_ricevuta FOREIGN KEY (oil_ricevuta_tipo_id)
    REFERENCES siac_d_oil_ricevuta_tipo(oil_ricevuta_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE siac_t_oil_ricevuta
IS 'Tabella di anagrafica delle ricevute caricate da esterno';

comment on column siac_t_oil_ricevuta.oil_ricevuta_anno
is 'Anno della ricevuta';

comment on column siac_t_oil_ricevuta.oil_ricevuta_numero
is 'Numero della ricevuta';

comment on column siac_t_oil_ricevuta.oil_ricevuta_data
is 'Data della ricevuta';

comment on column siac_t_oil_ricevuta.oil_ricevuta_importo
is 'Importo della ricevuta';

comment on column siac_t_oil_ricevuta.oil_ricevuta_tipo
is 'Tipo della ricevuta [E,S]';

comment on column siac_t_oil_ricevuta.oil_ricevuta_tipo_id
is 'Tipo ricevuta FK [siac_d_oil_ricevuta_tipo Q,P,S,F]';

comment on column siac_t_oil_ricevuta.flusso_elab_mif_id
is 'Identificativo di elaborazione del flusso di caricamento dati [mif_t_flusso_elaborato]';

comment on column siac_t_oil_ricevuta.oil_ricevuta_errore_id
is 'Identificativo di errore di elaborazione della ricevuta [siac_d_oil_ricevuta_errore]';

comment on column siac_t_oil_ricevuta.oil_progr_ricevuta_id
is 'Identificativo ricevuta in tabella di log di elaborazione del flusso [mif_emap_rr, mif_emat_rr,mif_emfe_rr]';

comment on column siac_t_oil_ricevuta.oil_ord_id
is 'Identificativo ordinativo cui riferisce la ricevuta [siac_t_ordinativo]';


comment on column siac_t_oil_ricevuta.oil_ord_anno_bil
is 'Anno di bilancio ordinativo cui riferisce la ricevuta';

comment on column siac_t_oil_ricevuta.oil_ord_numero
is 'Numero ordinativo cui riferisce la ricevuta';

comment on column siac_t_oil_ricevuta.oil_ord_data_emissione
is 'Data emissione ordinativo cui riferisce la ricevuta';

comment on column siac_t_oil_ricevuta.oil_ord_importo
is 'Importo ordinativo cui riferisce la ricevuta';

comment on column siac_t_oil_ricevuta.oil_ord_data_annullamento
is 'Data di annullamento ordinativo cui riferisce la ricevuta';

comment on column siac_t_oil_ricevuta.oil_ord_trasm_oil_data
is 'Data di trasmissione OIL ordinativo cui riferisce la ricevuta';

comment on column siac_t_oil_ricevuta.oil_ord_data_firma
is 'Data firma ordinativo cui riferisce la ricevuta';


comment on column siac_t_oil_ricevuta.oil_ord_importo_quiet
is 'Totale importo solo quietanzamento [parziale valido] ordinativo cui riferisce la ricevuta';


comment on column siac_t_oil_ricevuta.oil_ord_importo_storno
is 'Totale importo solo storno [parziale valido] ordinativo cui riferisce la ricevuta';


comment on column siac_t_oil_ricevuta.oil_ord_importo_quiet_tot
is 'Totale quietanzato effettivo [somma quiet-storni validi] ordinativo cui riferisce la ricevuta';



CREATE TABLE siac_r_ordinativo_quietanza (
  ord_quietanza_id SERIAL,
  ord_id INTEGER NOT NULL,
  ord_quietanza_data TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  ord_quietanza_numero integer not null,
  ord_quietanza_importo numeric not null,
  ord_quietanza_cro varchar(100) null,
  oil_ricevuta_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_r_ordinativo_quietanza_pkey PRIMARY KEY(ord_quietanza_id),
  CONSTRAINT siac_t_ordinativo_siac_r_ordinativo_quietanza FOREIGN KEY (ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_ordinativo_quietanza FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_oil_ricevuta_siac_r_ordinativo_quietanza FOREIGN KEY (oil_ricevuta_id)
    REFERENCES siac_t_oil_ricevuta(oil_ricevuta_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE TABLE siac_r_ordinativo_storno (
  ord_storno_id SERIAL,
  ord_id INTEGER NOT NULL,
  ord_storno_data TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  ord_storno_numero integer not null,
  ord_storno_importo numeric not null,
  oil_ricevuta_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_r_ordinativo_storno_pkey PRIMARY KEY(ord_storno_id),
  CONSTRAINT siac_t_ordinativo_siac_r_ordinativo_storno FOREIGN KEY (ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_ordinativo_quietanza FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_oil_ricevuta_siac_r_ordinativo_storno FOREIGN KEY (oil_ricevuta_id)
    REFERENCES siac_t_oil_ricevuta(oil_ricevuta_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE TABLE siac_r_ordinativo_firma (
  ord_firma_id SERIAL,
  ord_id INTEGER NOT NULL,
  ord_firma_data TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  ord_firma varchar(200) not null,
  oil_ricevuta_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_r_ordinativo_firma_pkey PRIMARY KEY(ord_firma_id),
  CONSTRAINT siac_t_ordinativo_siac_r_ordinativo_firma FOREIGN KEY (ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_ordinativo_firma FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_oil_ricevuta_siac_r_ordinativo_firma FOREIGN KEY (oil_ricevuta_id)
    REFERENCES siac_t_oil_ricevuta(oil_ricevuta_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


CREATE TABLE siac_r_prov_cassa_oil_ricevuta (
  provc_oil_ricevuta_id SERIAL,
  provc_id INTEGER NOT NULL,
  oil_ricevuta_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_r_prov_cassa_oil_ricevuta_pkey PRIMARY KEY(provc_oil_ricevuta_id),
  CONSTRAINT siac_t_prov_cassa_siac_r_prov_cassa_oil_ricevuta FOREIGN KEY (provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_prov_cassa_oil_ricevuta FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_oil_ricevuta_siac_r_prov_cassa_oil_ricevuta FOREIGN KEY (oil_ricevuta_id)
    REFERENCES siac_t_oil_ricevuta(oil_ricevuta_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


CREATE TABLE mif_t_oil_ricevuta
(
  oil_ricevuta_id SERIAL,
  oil_ricevuta_anno integer  null,
  oil_ricevuta_numero integer  null,
  oil_ricevuta_data TIMESTAMP WITHOUT TIME ZONE  NULL,
  oil_ricevuta_tipo char  null,
  oil_ricevuta_importo numeric  null,
  oil_ricevuta_cro1 varchar(50) null,
  oil_ricevuta_cro2 varchar(50) null,
  oil_ricevuta_note_tes varchar(500) null,
  oil_ricevuta_denominazione varchar(500) null,
  oil_ricevuta_note VARCHAR(500) null,
  oil_ricevuta_errore_id integer null, -- creare tabella degli errori
  oil_ricevuta_tipo_id integer not null,
  oil_ord_bil_id integer  null,
  oil_ord_id integer null,
  oil_provc_id integer null,
  flusso_elab_mif_id integer not null,
  oil_progr_ricevuta_id integer null,      -- FK (non fisica) verso tabella di caricamento flusso tabella *RR
  oil_progr_dett_ricevuta_id integer null, -- FK (non fisica) verso tabella di caricamento flusso *DR
  oil_ord_anno_bil integer null,
  oil_ord_numero integer null,
  oil_ord_importo numeric null,
  oil_ord_data_emissione TIMESTAMP WITHOUT TIME ZONE null,
  oil_ord_data_annullamento TIMESTAMP WITHOUT TIME ZONE null,
  oil_ord_trasm_oil_data TIMESTAMP WITHOUT TIME ZONE null,
  oil_ord_data_firma TIMESTAMP WITHOUT TIME ZONE null,
  oil_ord_data_quietanza TIMESTAMP WITHOUT TIME ZONE null,
  oil_ord_nome_firma  varchar(200) null,
  oil_ord_importo_quiet numeric null,
  oil_ord_importo_storno numeric null,
  oil_ord_importo_quiet_tot numeric null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_mif_t_oil_ricevuta PRIMARY KEY(oil_ricevuta_id),
  CONSTRAINT siac_t_ente_proprietario_mif_t_oil_ricevuta FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ordinativo_mit_t_oil_ricevuta FOREIGN KEY (oil_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_mit_t_oil_ricevuta FOREIGN KEY (oil_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT mif_t_flusso_elaborato_mif_t_oil_ricevuta FOREIGN KEY (flusso_elab_mif_id)
    REFERENCES mif_t_flusso_elaborato(flusso_elab_mif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_oil_ricevuta_tipo_mif_t_oil_ricevuta FOREIGN KEY (oil_ricevuta_tipo_id)
    REFERENCES siac_d_oil_ricevuta_tipo(oil_ricevuta_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_oil_ricevuta
IS 'Tabella di anagrafica temporanea delle ricevute caricate da esterno';


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




CREATE TABLE mif_t_elab_emat_hrer (
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
  CONSTRAINT mif_t_elab_emat_hrer_pkey PRIMARY KEY(mif_t_elab_hrer_id)
)
WITH (oids = false);


CREATE TABLE mif_t_elab_emat_rr (
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
  codice_esito VARCHAR(2),
  esercizio VARCHAR(4),
  numero_ordinativo VARCHAR(7),
  data_ordinativo VARCHAR(10),
  importo_ordinativo VARCHAR(15),
  nome_cognome VARCHAR(140),
  causale VARCHAR(370),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER,
  CONSTRAINT mif_t_elab_emat_rr_pkey PRIMARY KEY(mif_t_elab_rr_id)
)
WITH (oids = false);
