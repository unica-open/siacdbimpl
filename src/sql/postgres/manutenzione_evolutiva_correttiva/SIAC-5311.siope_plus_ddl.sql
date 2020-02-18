/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP TABLE IF EXISTS siac.siac_d_siope_tipo_debito;
DROP TABLE IF EXISTS siac.siac_d_siope_assenza_motivazione;
DROP TABLE IF EXISTS siac.siac_d_siope_documento_tipo;
DROP TABLE IF EXISTS siac.siac_d_siope_documento_tipo_analogico;
DROP TABLE IF EXISTS siac.siac_d_siope_scadenza_motivo;

-- CREATE TABLE
CREATE TABLE siac.siac_d_siope_tipo_debito (
    siope_tipo_debito_id         SERIAL NOT NULL,
    siope_tipo_debito_code       CHARACTER VARYING(200) NOT NULL,
    siope_tipo_debito_desc       CHARACTER VARYING(500) NOT NULL,
    siope_tipo_debito_desc_bnkit CHARACTER VARYING(500) NOT NULL,
    validita_inizio              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine                TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id         INTEGER  NOT NULL,
    data_creazione               TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica                TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione           TIMESTAMP WITHOUT TIME ZONE,
    login_operazione             CHARACTER VARYING(200) NOT NULL,
    CONSTRAINT PK_siac_d_siope_tipo_debito PRIMARY KEY (siope_tipo_debito_id),
    CONSTRAINT siac_t_ente_proprietario_siac_d_siope_tipo_debito FOREIGN KEY (ente_proprietario_id)
        REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX IDX_siac_d_siope_tipo_debito_1
ON siac.siac_d_siope_tipo_debito (siope_tipo_debito_code, siope_tipo_debito_desc, validita_inizio, ente_proprietario_id)
WHERE data_cancellazione IS NULL;

CREATE TABLE siac.siac_d_siope_assenza_motivazione (
    siope_assenza_motivazione_id         SERIAL NOT NULL,
    siope_assenza_motivazione_code       CHARACTER VARYING(200) NOT NULL,
    siope_assenza_motivazione_desc       CHARACTER VARYING(500) NOT NULL,
    siope_assenza_motivazione_desc_bnkit CHARACTER VARYING(500) NOT NULL,
    validita_inizio                      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine                        TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id                 INTEGER  NOT NULL,
    data_creazione                       TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica                        TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione                   TIMESTAMP WITHOUT TIME ZONE,
    login_operazione                     CHARACTER VARYING(200) NOT NULL,
    CONSTRAINT PK_siac_d_siope_assenza_motivazione PRIMARY KEY (siope_assenza_motivazione_id),
    CONSTRAINT siac_t_ente_proprietario_siac_d_siope_assenza_motivazione FOREIGN KEY (ente_proprietario_id)
        REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX IDX_siac_d_siope_assenza_motivazione_1
ON siac.siac_d_siope_assenza_motivazione (siope_assenza_motivazione_code, siope_assenza_motivazione_desc, validita_inizio, ente_proprietario_id)
WHERE data_cancellazione IS NULL;

CREATE TABLE siac.siac_d_siope_documento_tipo (
    siope_documento_tipo_id         SERIAL NOT NULL,
    siope_documento_tipo_code       CHARACTER VARYING(200) NOT NULL,
    siope_documento_tipo_desc       CHARACTER VARYING(500) NOT NULL,
    siope_documento_tipo_desc_bnkit CHARACTER VARYING(500) NOT NULL,
    validita_inizio                 TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine                   TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id            INTEGER  NOT NULL,
    data_creazione                  TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica                   TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione              TIMESTAMP WITHOUT TIME ZONE,
    login_operazione                CHARACTER VARYING(200) NOT NULL,
    CONSTRAINT PK_siac_d_siope_documento_tipo PRIMARY KEY (siope_documento_tipo_id),
    CONSTRAINT siac_t_ente_proprietario_siac_d_siope_documento_tipo FOREIGN KEY (ente_proprietario_id)
        REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX IDX_siac_d_siope_documento_tipo_1
ON siac.siac_d_siope_documento_tipo (siope_documento_tipo_code, siope_documento_tipo_desc, validita_inizio, ente_proprietario_id)
WHERE data_cancellazione IS NULL;

CREATE TABLE siac.siac_d_siope_documento_tipo_analogico (
    siope_documento_tipo_analogico_id         SERIAL NOT NULL,
    siope_documento_tipo_analogico_code       CHARACTER VARYING(200) NOT NULL,
    siope_documento_tipo_analogico_desc       CHARACTER VARYING(500) NOT NULL,
    siope_documento_tipo_analogico_desc_bnkit CHARACTER VARYING(500) NOT NULL,
    siope_documento_tipo_id                   INTEGER NOT NULL,
    validita_inizio                           TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine                             TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id                      INTEGER  NOT NULL,
    data_creazione                            TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica                             TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione                        TIMESTAMP WITHOUT TIME ZONE,
    login_operazione                          CHARACTER VARYING(200) NOT NULL,
    CONSTRAINT PK_siac_d_siope_documento_tipo_analogico PRIMARY KEY (siope_documento_tipo_analogico_id),
    CONSTRAINT siac_t_ente_proprietario_siac_d_siope_documento_tipo_analogico FOREIGN KEY (ente_proprietario_id)
        REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT siac_d_siope_documento_tipo_siac_d_siope_documento_tipo_analogico FOREIGN KEY (siope_documento_tipo_id)
        REFERENCES siac.siac_d_siope_documento_tipo(siope_documento_tipo_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX IDX_siac_d_siope_documento_tipo_analogico_1
ON siac.siac_d_siope_documento_tipo_analogico (siope_documento_tipo_analogico_code, siope_documento_tipo_analogico_desc, siope_documento_tipo_id, validita_inizio, ente_proprietario_id)
WHERE data_cancellazione IS NULL;

CREATE TABLE siac.siac_d_siope_scadenza_motivo (
    siope_scadenza_motivo_id         SERIAL NOT NULL,
    siope_scadenza_motivo_code       CHARACTER VARYING(200) NOT NULL,
    siope_scadenza_motivo_desc       CHARACTER VARYING(500) NOT NULL,
    siope_scadenza_motivo_desc_bnkit CHARACTER VARYING(500) NOT NULL,
    validita_inizio                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine                    TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id             INTEGER  NOT NULL,
    data_creazione                   TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica                    TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione               TIMESTAMP WITHOUT TIME ZONE,
    login_operazione                 CHARACTER VARYING(200) NOT NULL,
    CONSTRAINT PK_siac_d_siope_scadenza_motivo PRIMARY KEY (siope_scadenza_motivo_id),
    CONSTRAINT siac_t_ente_proprietario_siac_d_siope_scadenza_motivo FOREIGN KEY (ente_proprietario_id)
        REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX IDX_siac_d_siope_scadenza_motivo_1
ON siac.siac_d_siope_scadenza_motivo (siope_scadenza_motivo_code, siope_scadenza_motivo_desc, validita_inizio, ente_proprietario_id)
WHERE data_cancellazione IS NULL;


-- ALTER TABLE
ALTER TABLE siac.siac_t_movgest_ts ADD COLUMN siope_tipo_debito_id INTEGER;
ALTER TABLE siac.siac_t_movgest_ts ADD COLUMN siope_assenza_motivazione_id INTEGER;

ALTER TABLE siac.siac_t_liquidazione ADD COLUMN siope_tipo_debito_id INTEGER;
ALTER TABLE siac.siac_t_liquidazione ADD COLUMN siope_assenza_motivazione_id INTEGER;

ALTER TABLE siac.siac_t_ordinativo ADD COLUMN siope_tipo_debito_id INTEGER;
ALTER TABLE siac.siac_t_ordinativo ADD COLUMN siope_assenza_motivazione_id INTEGER;

ALTER TABLE siac.siac_t_subdoc ADD COLUMN siope_tipo_debito_id INTEGER;
ALTER TABLE siac.siac_t_subdoc ADD COLUMN siope_assenza_motivazione_id INTEGER;
ALTER TABLE siac.siac_t_subdoc ADD COLUMN siope_scadenza_motivo_id INTEGER;

ALTER TABLE siac.siac_t_doc ADD COLUMN siope_documento_tipo_id INTEGER;
ALTER TABLE siac.siac_t_doc ADD COLUMN siope_documento_tipo_analogico_id INTEGER;
ALTER TABLE siac.siac_t_doc ADD COLUMN doc_sdi_lotto_siope CHARACTER VARYING(200);

-- CONSTRAINTS
ALTER TABLE siac.siac_t_movgest_ts ADD CONSTRAINT siac_d_siope_tipo_debito_siac_t_movgest_ts FOREIGN KEY (siope_tipo_debito_id)
    REFERENCES siac.siac_d_siope_tipo_debito(siope_tipo_debito_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE siac.siac_t_movgest_ts ADD CONSTRAINT siac_d_siope_assenza_motivazione_siac_t_movgest_ts FOREIGN KEY (siope_assenza_motivazione_id)
    REFERENCES siac.siac_d_siope_assenza_motivazione(siope_assenza_motivazione_id) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE siac.siac_t_liquidazione ADD CONSTRAINT siac_d_siope_tipo_debito_siac_t_liquidazione FOREIGN KEY (siope_tipo_debito_id)
    REFERENCES siac.siac_d_siope_tipo_debito(siope_tipo_debito_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE siac.siac_t_liquidazione ADD CONSTRAINT siac_d_siope_assenza_motivazione_siac_t_liquidazione FOREIGN KEY (siope_assenza_motivazione_id)
    REFERENCES siac.siac_d_siope_assenza_motivazione(siope_assenza_motivazione_id) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE siac.siac_t_ordinativo ADD CONSTRAINT siac_d_siope_tipo_debito_siac_t_ordinativo FOREIGN KEY (siope_tipo_debito_id)
    REFERENCES siac.siac_d_siope_tipo_debito(siope_tipo_debito_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE siac.siac_t_ordinativo ADD CONSTRAINT siac_d_siope_assenza_motivazione_siac_t_ordinativo FOREIGN KEY (siope_assenza_motivazione_id)
    REFERENCES siac.siac_d_siope_assenza_motivazione(siope_assenza_motivazione_id) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE siac.siac_t_subdoc ADD CONSTRAINT siac_d_siope_tipo_debito_siac_t_subdoc FOREIGN KEY (siope_tipo_debito_id)
    REFERENCES siac.siac_d_siope_tipo_debito(siope_tipo_debito_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE siac.siac_t_subdoc ADD CONSTRAINT siac_d_siope_assenza_motivazione_siac_t_subdoc FOREIGN KEY (siope_assenza_motivazione_id)
    REFERENCES siac.siac_d_siope_assenza_motivazione(siope_assenza_motivazione_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE siac.siac_t_subdoc ADD CONSTRAINT siac_d_siope_scadenza_motivo_siac_t_subdoc FOREIGN KEY (siope_scadenza_motivo_id)
    REFERENCES siac.siac_d_siope_scadenza_motivo(siope_scadenza_motivo_id) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE siac.siac_t_doc ADD CONSTRAINT siac_d_siope_documento_tipo_siac_t_doc FOREIGN KEY (siope_documento_tipo_id)
    REFERENCES siac.siac_d_siope_documento_tipo(siope_documento_tipo_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE siac.siac_t_doc ADD CONSTRAINT siac_d_siope_documento_tipo_analogico_siac_t_doc FOREIGN KEY (siope_documento_tipo_analogico_id)
    REFERENCES siac.siac_d_siope_documento_tipo_analogico(siope_documento_tipo_analogico_id) ON DELETE NO ACTION ON UPDATE NO ACTION;