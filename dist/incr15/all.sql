/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
---SIAC-5311 (file /incr14/siope_beta)
-- SIAC-5311 INIZIO

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

INSERT INTO siac.siac_d_siope_documento_tipo(siope_documento_tipo_code, siope_documento_tipo_desc, siope_documento_tipo_desc_bnkit, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('E', 'Elettronico', 'ELETTRONICO'),
	('A', 'Analogico', 'ANALOGICO')) AS tmp (code, descr, bnkit)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_documento_tipo dsdt
	WHERE dsdt.ente_proprietario_id = tep.ente_proprietario_id
	AND dsdt.siope_documento_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac.siac_d_siope_documento_tipo_analogico(siope_documento_tipo_analogico_code, siope_documento_tipo_analogico_desc, siope_documento_tipo_analogico_desc_bnkit, siope_documento_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, dsdt.siope_documento_tipo_id, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_siope_documento_tipo dsdt ON dsdt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('FA', 'Fattura analogica', 'FATT_ANALOGICA', 'A'),
	('DE', 'Documento equivalente', 'DOC_EQUIVALENTE', 'A')) AS tmp (code, descr, bnkit, tipo)
WHERE dsdt.siope_documento_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_documento_tipo_analogico dsdta
	WHERE dsdta.ente_proprietario_id = tep.ente_proprietario_id
	AND dsdta.siope_documento_tipo_analogico_code = tmp.code
	AND dsdta.siope_documento_tipo_id = dsdt.siope_documento_tipo_id
)
ORDER BY tep.ente_proprietario_id, tmp.code, tmp.tipo;

INSERT INTO siac.siac_d_siope_scadenza_motivo(siope_scadenza_motivo_code, siope_scadenza_motivo_desc, siope_scadenza_motivo_desc_bnkit, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('SF', 'Scadenza fattura', 'SCAD_FATTURA'),
	('CSF', 'Corretta scadenza fattura', 'CORRETTA_SCAD_FATTURA'),
	('SDT', 'Sospensione decorrenza termini', 'SOSP_DECORRENZA_TERMINI')) AS tmp (code, descr, bnkit)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_scadenza_motivo dssm
	WHERE dssm.ente_proprietario_id = tep.ente_proprietario_id
	AND dssm.siope_scadenza_motivo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac.siac_d_siope_assenza_motivazione(siope_assenza_motivazione_code, siope_assenza_motivazione_desc, siope_assenza_motivazione_desc_bnkit, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('AL', 'Acquisto locazione', 'ACQUISTO_LOCAZIONE'),
	('AR', 'Arbitrato', 'ARBITRATO'),
	('SB', 'Servizi BNKIT', 'SERVIZI_BNKIT'), 
	('CO', 'Contratti', 'CONTRATTI'),
	('AP', 'Appalti', 'APPALTI'),
	('AE', 'Appalti energia', 'APPALTI_ENERGIA'),
	('SP', 'Sponsorizzazione', 'SPONSORIZZAZIONE'),
	('PR', 'Prestazioni', 'PRESTAZIONI'),
	('SS', 'Scelta socio', 'SCELTA_SOCIO'),
	('ID', 'CIG in corso di definizione', '')) AS tmp (code, descr, bnkit)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_assenza_motivazione dsam
	WHERE dsam.ente_proprietario_id = tep.ente_proprietario_id
	AND dsam.siope_assenza_motivazione_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac.siac_d_siope_tipo_debito(siope_tipo_debito_code, siope_tipo_debito_desc, siope_tipo_debito_desc_bnkit, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('CO', 'Commerciale', 'COMMERCIALE'),
	('NC', 'Non commerciale', 'NON_COMMERCIALE')) AS tmp (code, descr, bnkit)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_tipo_debito dstd
	WHERE dstd.ente_proprietario_id = tep.ente_proprietario_id
	AND dstd.siope_tipo_debito_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac.siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('ORDINATIVI_MIF_TRASMISSIONE', 'Trasmissione ordinativi MIF')) AS tmp (code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac.siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('ORDINATIVI_MIF_TRASMETTI_SIOPE_PLUS', 'Trasmissione ordinativi MIF a SIOPE+', 'ORDINATIVI_MIF_TRASMISSIONE'),
	('ORDINATIVI_MIF_TRASMETTI_UNIIT', 'Trasmissione ordinativi MIF a UNIIT', 'ORDINATIVI_MIF_TRASMISSIONE')) AS tmp (code, descr, tipo)
WHERE tmp.tipo = dgt.gestione_tipo_code
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_livello_code = tmp.code
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
)
ORDER BY tep.ente_proprietario_id, tmp.code, tmp.tipo;
