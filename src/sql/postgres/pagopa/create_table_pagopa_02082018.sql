/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
rollback;
begin;

drop table pagopa_t_elaborazione_log;

drop table if exists pagopa_bck_t_subdoc;

drop table if exists pagopa_bck_t_subdoc_attr;
drop table if exists pagopa_bck_t_subdoc_atto_amm;
drop table if exists pagopa_bck_t_subdoc_prov_cassa;
drop table if exists pagopa_bck_t_subdoc_movgest_ts;
drop table if exists pagopa_bck_t_doc_sog;
drop table if exists pagopa_bck_t_doc_stato;
drop table if exists pagopa_bck_t_doc_attr;
drop table if exists pagopa_bck_t_doc_class;
drop table if exists pagopa_bck_t_registrounico_doc;
drop table if exists pagopa_bck_t_subdoc_num;
drop table if exists pagopa_bck_t_doc;


drop table if exists pagopa_t_riconciliazione_doc;
drop table if exists pagopa_t_elaborazione_flusso;
drop table if exists pagopa_t_riconciliazione;
drop table if exists pagopa_r_elaborazione_file;
drop table if exists pagopa_t_elaborazione;
drop table if exists siac_t_file_pagopa;
drop table if exists pagopa_d_elaborazione_stato;
drop table if exists siac_d_file_pagopa_stato;
drop table if exists pagopa_d_riconciliazione_errore;

---
alter table siac_t_doc_num add column doc_tipo_id integer not null;

alter table siac_t_doc_num  add CONSTRAINT siac_d_doc_tipo_siac_t_doc_num FOREIGN KEY (doc_tipo_id)
    REFERENCES siac_d_doc_tipo(doc_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE;
---


CREATE TABLE pagopa_t_elaborazione_log
(
  pagopa_elab_log_id SERIAL,
  pagopa_elab_id INTEGER  NULL,
  pagopa_file_id integer null,
  pagopa_elab_log_operazione VARCHAR(2500) NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_elab_t_elaborazione_log PRIMARY KEY(pagopa_elab_log_id),
  CONSTRAINT pagopa_t_elaborazione_pagopa_t_elaborazione_log FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_file_pagopa_pagopa_t_elaborazione_log FOREIGN KEY (pagopa_file_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elaborazione_log FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_elaborazione_log
IS 'Elaborazioni riconciliazione PAGOPA - LOG.';

-- pagopa_d_riconciliazione_errore

CREATE TABLE pagopa_d_riconciliazione_errore (
  pagopa_ric_errore_id SERIAL,
  pagopa_ric_errore_code VARCHAR(200) NOT NULL,
  pagopa_ric_errore_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_d_ric_errore PRIMARY KEY(pagopa_ric_errore_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_d_ric_errore FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_pagopa_d_ric_errore_1 ON pagopa_d_riconciliazione_errore
  USING btree (pagopa_ric_errore_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX pagopa_d_ric_errore_stato_fk_ente_proprietario_id_idx ON pagopa_d_riconciliazione_errore
  USING btree (ente_proprietario_id);



-- siac_d_file_pagopo_stato
CREATE TABLE siac_d_file_pagopa_stato (
  file_pagopa_stato_id SERIAL,
  file_pagopa_stato_code VARCHAR(200) NOT NULL,
  file_pagopa_stato_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_file_pagopa_stato PRIMARY KEY(file_pagopa_stato_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_file_pagopa_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_file_pagopa_stato_1 ON siac_d_file_pagopa_stato
  USING btree (file_pagopa_stato_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX siac_d_file_pagopa_stato_fk_ente_proprietario_id_idx ON siac_d_file_pagopa_stato
  USING btree (ente_proprietario_id);



-- siac_t_file_pagopa
CREATE TABLE siac_t_file_pagopa (
  file_pagopa_id SERIAL,
  file_pagopa_size NUMERIC NOT NULL,
  file_pagopa BYTEA,
  file_pagopa_code VARCHAR NOT NULL,
  file_pagopa_note VARCHAR,
  file_pagopa_anno integer not NULL,
  file_pagopa_stato_id INTEGER NOT NULL,
  file_pagopa_errore_id integer,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_t_file_pagopa PRIMARY KEY(file_pagopa_id),
  CONSTRAINT siac_d_file_pagopa_stato_siac_t_file_pagopa FOREIGN KEY (file_pagopa_stato_id)
    REFERENCES siac_d_file_pagopa_stato(file_pagopa_stato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_riconciliazione_errore_siac_t_file_pagopa FOREIGN KEY (file_pagopa_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_t_file_pagopa FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE siac_t_file_pagopa
IS 'Tabella di archivio file XML riconciliazione PAGOPA';

COMMENT ON COLUMN siac_t_file_pagopa.file_pagopa_type
IS 'Internet media type';

CREATE INDEX idx_siac_t_file_pagopa_1 ON siac_t_file_pagopa
  USING btree (file_pagopa_name COLLATE pg_catalog."default", ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX siac_t_file_pagopa_fk_ente_proprietario_id_idx ON siac_t_file_pagopa
  USING btree (ente_proprietario_id);

CREATE INDEX siac_t_file_pagopa_fk_file_pagopa_stato_id_idx ON siac_t_file_pagopa
  USING btree (file_pagopa_stato_id);

-- pagopa_d_elaborazione_stato
CREATE TABLE pagopa_d_elaborazione_stato (
  pagopa_elab_stato_id SERIAL,
  pagopa_elab_stato_code VARCHAR(200) NOT NULL,
  pagopa_elab_stato_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_d_elab_stato PRIMARY KEY(pagopa_elab_stato_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_d_elaborazione_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_pagopa_d_elaborazione_stato_1 ON pagopa_d_elaborazione_stato
  USING btree (pagopa_elab_stato_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX pagopa_d_elaborazione_stato_fk_ente_proprietario_id_idx ON pagopa_d_elaborazione_stato
  USING btree (ente_proprietario_id);

-- pagopa_t_elaborazione

CREATE TABLE pagopa_t_elaborazione (
  pagopa_elab_id SERIAL,
  pagopa_elab_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_elab_stato_id INTEGER NOT NULL,
  pagopa_elab_note VARCHAR(1500) NOT NULL,
  pagopa_elab_file_id  varchar(250),
  pagopa_elab_file_ora varchar(250),
  pagopa_elab_file_ente varchar(250),
  pagopa_elab_file_fruitore varchar(250),
  file_pagopa_id   integer  null,
  pagopa_elab_errore_id integer,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_elaborazione PRIMARY KEY(pagopa_elab_id),
  CONSTRAINT siac_t_file_pagopa_pagopa_t_elaborazione FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elaborazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_elaborazione_stato_pagopa_t_elaborazione FOREIGN KEY (pagopa_elab_stato_id)
    REFERENCES pagopa_d_elaborazione_stato(pagopa_elab_stato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_riconciliazione_errore_pagopa_t_elaborazione FOREIGN KEY (pagopa_elab_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_elaborazione
IS 'Tabella di elaborazione dei file XML riconciliazione PAGOPO';



COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_id
IS 'Identificativo file XML';

COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_ora
IS 'Ora generazione file XML';

COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_ente
IS 'Codice Ente file  XML';

COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_fruitore
IS 'Codice Fruitore file XML';

COMMENT ON COLUMN pagopa_t_elaborazione.file_pagopa_id
IS 'Identificativo file XML in siac_t_file_pagopa.';


CREATE INDEX pagopa_t_elaborazione_fk_ente_proprietario_id_idx ON pagopa_t_elaborazione
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_elaborazione_fk_pagopa_elab_stato_id_idx ON pagopa_t_elaborazione
  USING btree (pagopa_elab_stato_id);


CREATE INDEX pagopa_t_elaborazione_fk_siac_t_file_pagopa_idx ON pagopa_t_elaborazione
  USING btree (file_pagopa_id);


CREATE TABLE pagopa_r_elaborazione_file (
  pagopa_r_elab_id SERIAL,
  pagopa_elab_id integer not null,
  file_pagopa_id   integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_r_elaborazione_file PRIMARY KEY(pagopa_r_elab_id),
  CONSTRAINT siac_t_file_pagopa_pagopa_r_elaborazione_file FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_r_elaborazione_file FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_r_elaborazione_file FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_r_elaborazione_file
IS 'Tabella di relazione tra PAGOPA file XML e PAGOPA elaborazione.';

COMMENT ON COLUMN pagopa_r_elaborazione_file.pagopa_elab_id
IS 'Identificativo elaborazione';

COMMENT ON COLUMN pagopa_r_elaborazione_file.file_pagopa_id
IS 'Identificativo file XML';


CREATE INDEX pagopa_r_elaborazione_file_fk_ente_proprietario_id_idx ON pagopa_r_elaborazione_file
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_r_elaborazione_file_fk_file_pagopa_id_idx ON pagopa_r_elaborazione_file
  USING btree (file_pagopa_id);



CREATE INDEX pagopa_r_elaborazione_file_fk_pagopa_elab_id_idx ON pagopa_r_elaborazione_file
  USING btree (pagopa_elab_id);



-- pagopa_t_riconciliazione

CREATE TABLE pagopa_t_riconciliazione (
  pagopa_ric_id SERIAL,
  pagopa_ric_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  -- XML - inizio
  -- intestazione XML
  pagopa_ric_file_id  varchar,
  pagopa_ric_file_ora TIMESTAMP WITHOUT TIME ZONE,
  pagopa_ric_file_ente varchar,
  pagopa_ric_file_fruitore varchar,
  pagopa_ric_file_num_flussi integer,
  pagopa_ric_file_tot_flussi  numeric, -- importo
  -- intestazione FLUSSO
  pagopa_ric_flusso_id  varchar,
  pagopa_ric_flusso_nome_mittente  varchar,
  pagopa_ric_flusso_data  TIMESTAMP WITHOUT TIME ZONE,
  pagopa_ric_flusso_tot_pagam  numeric, -- importo
  pagopa_ric_flusso_anno_esercizio  integer,
  pagopa_ric_flusso_anno_provvisorio  integer,
  pagopa_ric_flusso_num_provvisorio  integer,
  -- dettaglio flusso
  pagopa_ric_flusso_voce_code  varchar,
  pagopa_ric_flusso_voce_desc  varchar,
  pagopa_ric_flusso_tematica varchar,
  pagopa_ric_flusso_sottovoce_code  varchar,
  pagopa_ric_flusso_sottovoce_desc  varchar,
  pagopa_ric_flusso_sottovoce_importo  numeric, -- importo
  pagopa_ric_flusso_anno_accertamento  integer,
  pagopa_ric_flusso_num_accertamento  integer,
  pagopa_ric_flusso_num_capitolo  integer,
  pagopa_ric_flusso_num_articolo  integer,
  pagopa_ric_flusso_pdc_v_fin  varchar,
  pagopa_ric_flusso_titolo  varchar,
  pagopa_ric_flusso_tipologia varchar,
  pagopa_ric_flusso_categoria  varchar,
  pagopa_ric_flusso_codice_benef  varchar,
  pagopa_ric_flusso_str_amm  varchar,
  -- XML - fine
  file_pagopa_id integer not null,
  pagopa_ric_flusso_stato_elab varchar default 'N' not null ,
  pagopa_ric_errore_id integer, -- riferimento errore_id in caso di errore
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_riconciliazione PRIMARY KEY(pagopa_ric_id),
  CONSTRAINT siac_t_file_pagopa_pagopa_t_riconciliazione FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_ric_err_pagopa_t_riconciliazione FOREIGN KEY (pagopa_ric_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_riconciliazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_riconciliazione
IS 'Tabella di tracciatura piatta dati presenti in  file XML riconciliazione PAGOPO';



COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_id
IS 'Identificativo XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_ora
IS 'Ora generazione file complessivo XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_ente
IS 'Codice Ente file  XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_fruitore
IS 'Codice Fruitore file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_num_flussi
IS 'Numero di flussi contenuti in file XML';


COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_tot_flussi
IS 'Totale dei flussi contenuti in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_id
IS 'Identificativo flusso contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_anno_esercizio
IS 'Anno esercizio di riferimento del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_anno_provvisorio
IS 'Anno provvisorio di riferimento del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_num_provvisorio
IS 'Numero provvisorio di riferimento del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_voce_code
IS 'Codice voce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_sottovoce_code
IS 'Codice sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_sottovoce_importo
IS 'Importo dettaglio  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_anno_accertamento
IS 'Anno accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_num_accertamento
IS 'Numero accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';



COMMENT ON COLUMN pagopa_t_riconciliazione.file_pagopa_id
IS 'Identificativo file XML in siac_t_file_pagopa.';


COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_stato_elab
IS 'Stato di elaborazione del singolo dettaglio  - dettaglio del singolo flusso  contenuto in file XML - [N-No S-Si E-Err X-Scarto]';


CREATE INDEX pagopa_t_riconciliazione_ric_file_id_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_file_id);

CREATE INDEX pagopa_t_riconciliazione_ric_flusso_id_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_provvisorio_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_anno_esercizio,pagopa_ric_flusso_anno_provvisorio,pagopa_ric_flusso_num_provvisorio,
               pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_voce_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_voce_code,
  			   pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_sottovoce_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_sottovoce_code,
               pagopa_ric_flusso_voce_code,
               pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_accertamento_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_anno_esercizio,pagopa_ric_flusso_anno_accertamento,pagopa_ric_flusso_num_accertamento,
               pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_fk_file_pagopa_id_idx ON pagopa_t_riconciliazione
  USING btree (file_pagopa_id);

CREATE INDEX pagopa_t_riconciliazione_fk_ente_proprietario_id_idx ON pagopa_t_riconciliazione
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_riconciliazione_ric_errore_id_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_errore_id);



-- pagopa_t_elaborazione_flusso
CREATE TABLE pagopa_t_elaborazione_flusso (
  pagopa_elab_flusso_id SERIAL,
  pagopa_elab_flusso_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_elab_flusso_stato_id INTEGER NOT NULL,
  pagopa_elab_flusso_note VARCHAR(750) NOT NULL,
  pagopa_elab_ric_flusso_id  varchar,
  pagopa_elab_flusso_nome_mittente  varchar,
  pagopa_elab_ric_flusso_data  varchar,
  pagopa_elab_flusso_tot_pagam  numeric, -- importo
  pagopa_elab_flusso_anno_esercizio  integer,
  pagopa_elab_flusso_anno_provvisorio  integer,
  pagopa_elab_flusso_num_provvisorio  integer,
  pagopa_elab_flusso_provc_id  integer,
  pagopa_elab_id  integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_elaborazione_flusso PRIMARY KEY(pagopa_elab_flusso_id),
  CONSTRAINT pagopa_t_elaborazione_pagopa_t_elab_flusso FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_t_elab_flusso FOREIGN KEY (pagopa_elab_flusso_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elab_flusso FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_elaborazione_stato_pagopa_t_elab_flusso FOREIGN KEY (pagopa_elab_flusso_stato_id)
    REFERENCES pagopa_d_elaborazione_stato(pagopa_elab_stato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_elaborazione_flusso
IS 'Tabella di elaborazione del singolo flusso riconciliazione PAGOPO contenuto nel file XML ';



COMMENT ON COLUMN pagopa_t_elaborazione_flusso.pagopa_elab_ric_flusso_id
IS 'Identificativo flusso riconciliazione PAGOPO nel file XML';

COMMENT ON COLUMN pagopa_t_elaborazione_flusso.pagopa_elab_ric_flusso_data
IS 'Ora generazione flusso riconciliazione PAGOPO nel file XML';

COMMENT ON COLUMN pagopa_t_elaborazione_flusso.pagopa_elab_id
IS 'Identificativo elaborazione file XML in pagopa_t_elaborazione.';


CREATE INDEX pagopa_t_elaborazione_flusso_fk_ente_proprietario_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_elaborazione_flusso_fk_pagopa_elab_stato_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_flusso_stato_id);


CREATE INDEX pagopa_t_elaborazione_flusso_fk_pagopa_t_elab_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_id);

CREATE INDEX pagopa_t_elaborazione_flusso_pagopa_elab_ric_flusso_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_ric_flusso_id);


CREATE INDEX pagopa_t_elaborazione_flusso_provvisorio_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_flusso_anno_esercizio,pagopa_elab_flusso_anno_provvisorio,pagopa_elab_flusso_num_provvisorio,
               pagopa_elab_ric_flusso_id);

CREATE INDEX pagopa_t_elaborazione_flusso_provvisorio_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_flusso_provc_id);




-- pagopa_t_riconciliazione_doc
CREATE TABLE pagopa_t_riconciliazione_doc (
  pagopa_ric_doc_id SERIAL,
  pagopa_ric_doc_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_ric_doc_voce_code  varchar,
  pagopa_ric_doc_voce_desc  varchar,
  pagopa_ric_doc_voce_tematica  varchar,
  pagopa_ric_doc_sottovoce_code  varchar,
  pagopa_ric_doc_sottovoce_desc  varchar,
  pagopa_ric_doc_sottovoce_importo  numeric,
  pagopa_ric_doc_anno_esercizio  integer,
  pagopa_ric_doc_anno_accertamento  integer,
  pagopa_ric_doc_num_accertamento  integer,
  pagopa_ric_doc_num_capitolo  integer,
  pagopa_ric_doc_num_articolo  integer,
  pagopa_ric_doc_pdc_v_fin  varchar,
  pagopa_ric_doc_titolo  varchar,
  pagopa_ric_doc_tipologia varchar,
  pagopa_ric_doc_categoria  varchar,
  pagopa_ric_doc_codice_benef  varchar,
  pagopa_ric_doc_str_amm  varchar,
  -- identificativi contabilia - associati dopo elaborazione
  pagopa_ric_doc_subdoc_id integer,
  pagopa_ric_doc_provc_id integer,
  pagopa_ric_doc_movgest_ts_id integer,
  pagopa_ric_doc_stato_elab varchar default 'N' not null ,
  pagopa_ric_errore_id integer, -- riferimento errore_id in caso di errore
  pagopa_ric_id  integer, -- riferimento t_riconciliazione
  pagopa_elab_flusso_id integer, -- riferimento t_elaborazione_flusso
    -- XML - fine
  file_pagopa_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_riconciliazione_doc PRIMARY KEY(pagopa_ric_doc_id),
  CONSTRAINT pagopa_t_elaborazione_flusso_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_elab_flusso_id)
    REFERENCES pagopa_t_elaborazione_flusso(pagopa_elab_flusso_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_riconciliazione_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_id)
    REFERENCES pagopa_t_riconciliazione(pagopa_ric_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_file_pagopa_pagopa_t_riconciliazione_doc FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_movgest_ts_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_doc_movgest_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_doc_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_riconc_err_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_riconciliazione_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_riconciliazione_doc
IS 'Tabella di elaborazione dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_id
IS 'Riferimento identificativo relativo dettaglio in pagopa_t_riconciliazione';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_elab_flusso_id
IS 'Riferimento identificativo elaborazione flusso in pagopa_t_elaborazione_flusso';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_subdoc_id
IS 'Riferimento identificativo subdocumento emesso in Contabilia';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_movgest_ts_id
IS 'Riferimento identificativo accertamento Contabilia collegato';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_provc_id
IS 'Riferimento identificativo provvisorio di cassa Contabilia collegato';


COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_anno_esercizio
IS 'Anno esercizio di riferimento';


COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_voce_code
IS 'Codice voce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_sottovoce_code
IS 'Codice sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_sottovoce_importo
IS 'Importo dettaglio  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_anno_accertamento
IS 'Anno accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_num_accertamento
IS 'Numero accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_stato_elab
IS 'Stato di elaborazione del singolo dettaglio  - dettaglio del singolo flusso  contenuto in file XML - [N-No S-Si E-Err X-Scarto]';


CREATE INDEX pagopa_t_riconciliazione_doc_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_id);

CREATE INDEX pagopa_t_riconciliazione_doc_flusso_elab_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_elab_flusso_id);


CREATE INDEX pagopa_t_riconciliazione_doc_sottovoce_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_sottovoce_code,
               pagopa_ric_doc_voce_code);

CREATE INDEX pagopa_t_riconciliazione_doc_accertamento_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_anno_esercizio,pagopa_ric_doc_anno_accertamento,pagopa_ric_doc_num_accertamento);

CREATE INDEX pagopa_t_riconciliazione_doc_subdoc_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_subdoc_id);

CREATE INDEX pagopa_t_riconciliazione_doc_movgest_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_movgest_ts_id);

CREATE INDEX pagopa_t_riconciliazione_doc_provc_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_provc_id);


CREATE INDEX pagopa_t_riconciliazione_doc_fk_ente_proprietario_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (ente_proprietario_id);


CREATE INDEX pagopa_t_riconciliazione_doc_fk_file_pagopa_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (file_pagopa_id);

-------------------------- BACKUP



CREATE TABLE pagopa_bck_t_subdoc
(
  pagopa_bck_subdoc_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  subdoc_id integer,
  subdoc_numero INTEGER,
  subdoc_desc VARCHAR(500),
  subdoc_importo NUMERIC,
  subdoc_nreg_iva VARCHAR(500),
  subdoc_data_scadenza TIMESTAMP WITHOUT TIME ZONE,
  subdoc_convalida_manuale CHAR(1),
  subdoc_importo_da_dedurre NUMERIC,
  subdoc_splitreverse_importo NUMERIC,
  subdoc_pagato_cec BOOLEAN,
  subdoc_data_pagamento_cec TIMESTAMP WITHOUT TIME ZONE,
  contotes_id INTEGER,
  dist_id INTEGER,
  comm_tipo_id INTEGER,
  doc_id INTEGER NOT NULL,
  subdoc_tipo_id INTEGER NOT NULL,
  notetes_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  bck_login_creazione VARCHAR(200),
  bck_login_modifica VARCHAR(200),
  bck_login_cancellazione VARCHAR(200),
  siope_tipo_debito_id INTEGER,
  siope_assenza_motivazione_id INTEGER,
  siope_scadenza_motivo_id INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc PRIMARY KEY(pagopa_bck_subdoc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc
IS 'Tabella di backup siac_t_subdoc per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_id_idx ON pagopa_bck_t_subdoc
  USING btree (pagopa_bck_subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_subdoc_id_idx ON pagopa_bck_t_subdoc
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_id_idx ON pagopa_bck_t_subdoc
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_elab_id_idx ON pagopa_bck_t_subdoc
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_subdoc_attr
(
  pagopa_bck_subdoc_attr_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  subdoc_attr_id integer,
  subdoc_id INTEGER,
  attr_id INTEGER,
  tabella_id integer,
  "boolean" CHAR(1),
  percentuale NUMERIC,
  testo VARCHAR(500),
  numerico NUMERIC,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_attr PRIMARY KEY(pagopa_bck_subdoc_attr_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_attr FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_attr FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_attr FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc_attr
IS 'Tabella di backup siac_r_subdoc_attr per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_attr.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_attr.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_attr_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (pagopa_bck_subdoc_attr_id);

CREATE INDEX pagopa_bck_t_subdoc_attr_subdoc_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_attr_provc_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_attr_elab_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_subdoc_atto_amm
(
  pagopa_bck_subdoc_attoamm_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  subdoc_atto_amm_id integer,
  subdoc_id INTEGER,
  attoamm_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_atto_amm PRIMARY KEY(pagopa_bck_subdoc_attoamm_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_attoamm FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_attoamm FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_attoamm FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_subdoc_atto_amm
IS 'Tabella di backup siac_r_subdoc_atto_amm per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_atto_amm.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_atto_amm.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_attoamm_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (pagopa_bck_subdoc_attoamm_id);

CREATE INDEX pagopa_bck_t_subdoc_attoamm_subdoc_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_attoamm_provc_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_attoamm_elab_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (pagopa_elab_id);

create table pagopa_bck_t_subdoc_prov_cassa
(
  pagopa_bck_subdoc_provc_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  subdoc_provc_id integer,
  subdoc_id INTEGER,
  provc_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_provc PRIMARY KEY(pagopa_bck_subdoc_provc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_provc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_provc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_provc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc_prov_cassa
IS 'Tabella di backup siac_r_subdoc_prov_cassa per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_prov_cassa.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_prov_cassa.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_provc_subdoc_provc_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (pagopa_bck_subdoc_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_subdoc_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_provc_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_elab_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_subdoc_movgest_ts
(
  pagopa_bck_subdoc_movgest_ts_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  subdoc_movgest_ts_id integer,
  subdoc_id INTEGER,
  movgest_ts_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_mov PRIMARY KEY(pagopa_bck_subdoc_movgest_ts_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_mov FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_mov FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_mov FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc_movgest_ts
IS 'Tabella di backup siac_r_subdoc_movgest_ts per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_movgest_ts.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_movgest_ts.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_movgest_ts_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (pagopa_bck_subdoc_movgest_ts_id);

CREATE INDEX pagopa_bck_t_subdoc_mov_subdoc_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_mov_provc_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_mov_elab_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc_sog
(
  pagopa_bck_doc_sog_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  doc_sog_id integer,
  doc_id INTEGER,
  soggetto_id INTEGER,
  ruolo_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_sog PRIMARY KEY(pagopa_bck_doc_sog_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_sog FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_sog FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_sog FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_sog
IS 'Tabella di backup siac_r_doc_sog per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_sog.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_sog.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_sog_id_idx ON pagopa_bck_t_doc_sog
  USING btree (pagopa_bck_doc_sog_id);

CREATE INDEX pagopa_bck_t_doc_sog_doc_id_idx ON pagopa_bck_t_doc_sog
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_sog_provc_id_idx ON pagopa_bck_t_doc_sog
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_sog_elab_id_idx ON pagopa_bck_t_doc_sog
  USING btree (pagopa_elab_id);

create TABLE pagopa_bck_t_doc_stato
(
  pagopa_bck_doc_stato_r_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  doc_stato_r_id integer,
  doc_id INTEGER,
  doc_stato_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_stato PRIMARY KEY(pagopa_bck_doc_stato_r_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_stato FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_stato FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_stato
IS 'Tabella di backup siac_r_doc_stato per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_stato.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_stato.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_stato_stato_r_id_idx ON pagopa_bck_t_doc_stato
  USING btree (pagopa_bck_doc_stato_r_id);

CREATE INDEX pagopa_bck_t_doc_stato_doc_id_idx ON pagopa_bck_t_doc_stato
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_stato_provc_id_idx ON pagopa_bck_t_doc_stato
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_stato_elab_id_idx ON pagopa_bck_t_doc_stato
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc_attr
(
  pagopa_bck_doc_attr_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  doc_attr_id integer,
  doc_id INTEGER,
  attr_id INTEGER,
  tabella_id integer,
  "boolean" CHAR(1),
  percentuale NUMERIC,
  testo VARCHAR(500),
  numerico NUMERIC,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_attr PRIMARY KEY(pagopa_bck_doc_attr_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_attr FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_attr FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_attr FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_attr
IS 'Tabella di backup siac_r_doc_attr per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_attr.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_attr.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_attr_id_idx ON pagopa_bck_t_doc_attr
  USING btree (pagopa_bck_doc_attr_id);

CREATE INDEX pagopa_bck_t_doc_attr_doc_id_idx ON pagopa_bck_t_doc_attr
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_attr_provc_id_idx ON pagopa_bck_t_doc_attr
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_attr_elab_id_idx ON pagopa_bck_t_doc_attr
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc_class
(
  pagopa_bck_doc_classif_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  doc_classif_id integer,
  doc_id INTEGER,
  classif_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_class PRIMARY KEY(pagopa_bck_doc_classif_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_class FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_class FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_class FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_class
IS 'Tabella di backup siac_r_doc_class per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_class.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_Class.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_classif_id_idx ON pagopa_bck_t_doc_class
  USING btree (pagopa_bck_doc_classif_id);

CREATE INDEX pagopa_bck_t_doc_class_doc_id_idx ON pagopa_bck_t_doc_class
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_class_provc_id_idx ON pagopa_bck_t_doc_class
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_class_elab_id_idx ON pagopa_bck_t_doc_class
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_registrounico_doc
(
  pagopa_bck_rudoc_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  rudoc_id integer,
  rudoc_registrazione_anno INTEGER,
  rudoc_registrazione_numero INTEGER,
  rudoc_registrazione_data TIMESTAMP WITHOUT TIME ZONE,
  doc_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_reg_doc PRIMARY KEY(pagopa_bck_rudoc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_reg_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_reg_doc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_reg_doc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_registrounico_doc
IS 'Tabella di backup siac_t_registrounico_doc per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_registrounico_doc.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_registrounico_doc.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_reg_doc_rudoc_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (pagopa_bck_rudoc_id);

CREATE INDEX pagopa_bck_t_doc_reg_doc_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_reg_doc_provc_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_reg_doc_elab_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (pagopa_elab_id);

create table pagopa_bck_t_subdoc_num
(
   pagopa_bck_subdoc_num_id	 serial,
   pagopa_provc_id integer not null,
   pagopa_elab_id integer not null,
   subdoc_num_id integer,
   doc_id INTEGER,
   subdoc_numero INTEGER,
   bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
   bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
   bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
   bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
   bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
   bck_login_operazione  VARCHAR(200),
   validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
   validita_fine TIMESTAMP WITHOUT TIME ZONE,
   ente_proprietario_id INTEGER NOT NULL,
   data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
   data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
   data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
   login_operazione  VARCHAR(200) NOT NULL,
   CONSTRAINT pk_pagopa_bck_t_subdoc_num PRIMARY KEY(pagopa_bck_subdoc_num_id),
   CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_num FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_sudoc_num FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_num FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_subdoc_num
IS 'Tabella di backup pagopa_bck_t_subdoc_num per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_num.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_num.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_num_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (pagopa_bck_subdoc_num_id);

CREATE INDEX pagopa_bck_t_subdoc_num_doc_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_subdoc_num_provc_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_num_elab_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc
(
  pagopa_bck_doc_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  doc_id integer,
  doc_anno INTEGER,
  doc_numero VARCHAR(200),
  doc_desc VARCHAR(500),
  doc_importo NUMERIC,
  doc_beneficiariomult BOOLEAN,
  doc_data_emissione TIMESTAMP WITHOUT TIME ZONE,
  doc_data_scadenza TIMESTAMP WITHOUT TIME ZONE,
  doc_tipo_id INTEGER,
  codbollo_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  bck_login_creazione VARCHAR(200),
  bck_login_modifica VARCHAR(200),
  bck_login_cancellazione VARCHAR,
  pcccod_id INTEGER,
  pccuff_id INTEGER,
  doc_collegato_cec BOOLEAN,
  doc_contabilizza_genpcc BOOLEAN,
  siope_documento_tipo_id INTEGER,
  siope_documento_tipo_analogico_id INTEGER,
  doc_sdi_lotto_siope VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc PRIMARY KEY(pagopa_bck_doc_id),
   CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_num FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_doc
IS 'Tabella di backup pagopa_bck_t_doc per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_id_idx ON pagopa_bck_t_doc
  USING btree (pagopa_bck_doc_id);

CREATE INDEX pagopa_bck_t_doc_doc_id_idx ON pagopa_bck_t_doc
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_provc_id_idx ON pagopa_bck_t_doc
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_elab_id_idx ON pagopa_bck_t_doc
  USING btree (pagopa_elab_id);