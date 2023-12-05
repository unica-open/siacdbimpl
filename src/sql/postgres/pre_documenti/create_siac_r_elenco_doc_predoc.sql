/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table siac_r_elenco_doc_predoc;

CREATE TABLE siac_r_elenco_doc_predoc (
  eldoc_predoc_rel_id SERIAL,
  predoc_id INTEGER NOT NULL,
  eldoc_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_elenco_doc_predoc PRIMARY KEY(eldoc_predoc_rel_id),
  CONSTRAINT siac_t_elenco_doc_siac_r_elenco_doc_predoc FOREIGN KEY (eldoc_id)
    REFERENCES siac_t_elenco_doc(eldoc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ente_proprietario_siac_r_elenco_doc_predoc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_predoc_siac_r_elenco_doc_predoc FOREIGN KEY (predoc_id)
    REFERENCES siac_t_predoc(predoc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_r_elenco_doc_predoc_1 ON siac_r_elenco_doc_predoc
  USING btree (predoc_id, eldoc_id, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

drop table siac_t_predoc_definisci_scarto;

CREATE TABLE siac_t_predoc_definisci_scarto (
  predoc_def_scarto_id SERIAL,
  definizione_data     TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  definizione_id       integer not null,
  predoc_id INTEGER NOT NULL,
  eldoc_id INTEGER NULL,
  motivo_scarto varchar(1500) not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_t_predoc_definisci_scarto PRIMARY KEY(predoc_def_scarto_id)/*,
  CONSTRAINT siac_t_elenco_doc_siac_t_predoc_def_scarto FOREIGN KEY (eldoc_id)
    REFERENCES siac_t_elenco_doc(eldoc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ente_proprietario_siac_t_predoc_def_scarto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_predoc_siac_t_predoc_def_scarto FOREIGN KEY (predoc_id)
    REFERENCES siac_t_predoc(predoc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE*/
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_t_predoc_def_scarto_1 ON siac_t_predoc_definisci_scarto
  USING btree (definizione_id,predoc_id, eldoc_id, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX idx_siac_t_predoc_def_scarto_2 ON siac_t_predoc_definisci_scarto
  USING btree (definizione_id);

CREATE INDEX idx_siac_t_predoc_def_scarto_3 ON siac_t_predoc_definisci_scarto
  USING btree (definizione_data);

CREATE INDEX idx_siac_t_predoc_def_scarto_4 ON siac_t_predoc_definisci_scarto
  USING btree (predoc_id);

CREATE INDEX idx_siac_t_predoc_def_scarto_5 ON siac_t_predoc_definisci_scarto
  USING btree (eldoc_id);