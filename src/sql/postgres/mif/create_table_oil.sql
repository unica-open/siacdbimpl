/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac_t_ente_oil
(
  ente_oil_id SERIAL,
  ente_oil_aid VARCHAR(50) not null,
  ente_oil_abi VARCHAR(50) not null,
  ente_oil_progressivo VARCHAR(50) not null,
  ente_oil_idTLQWeb VARCHAR(50) not null,
  ente_oil_codice VARCHAR(50) not null,
  ente_oil_conto_evidenza  VARCHAR(50) null,
  ente_oil_firma_manleva BOOLEAN default false not null,
  ente_oil_firme_ord  boolean default false not null,
  ente_oil_quiet_ord  boolean default false not null,
  ente_oil_tes_desc VARCHAR(200) null,
  ente_oil_resp_ord VARCHAR(200) null,
  ente_oil_resp_amm VARCHAR(200) null,
  ente_proprietario_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_t_ente_oil PRIMARY KEY(ente_oil_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_ente_oil FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


CREATE TABLE siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_id SERIAL,
  accredito_tipo_oil_code VARCHAR(200) NOT NULL,
  accredito_tipo_oil_desc VARCHAR(500) NOT NULL,
  accredito_tipo_oil_area VARCHAR(50) NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_d_accredito_tipo_oil_pkey PRIMARY KEY(accredito_tipo_oil_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_accredito_tipo_oil FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_accredito_tipo_oil_code ON siac_d_accredito_tipo_oil
  USING btree (accredito_tipo_oil_code COLLATE pg_catalog."default",  ente_proprietario_id);



CREATE TABLE siac_r_accredito_tipo_oil (
  accredito_tipo_oil_rel_id SERIAL,
  accredito_tipo_id INTEGER,
  accredito_tipo_oil_id INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_accredito_tipo_oil PRIMARY KEY(accredito_tipo_oil_rel_id),
  CONSTRAINT siac_d_accredito_tipo_siac_r_accredito_tipo FOREIGN KEY (accredito_tipo_id)
    REFERENCES siac_d_accredito_tipo(accredito_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_accredito_tipo_siac_r_accredito_tipo_oil FOREIGN KEY (accredito_tipo_oil_id)
    REFERENCES siac_d_accredito_tipo_oil(accredito_tipo_oil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_accredito_tipo_oil FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);