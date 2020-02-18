/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/* ---------------------------------------------------------------------- */
/*  Create table siac_t_gsa_classif                                 */
/* ---------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS siac.siac_t_gsa_classif (
  gsa_classif_id       SERIAL NOT NULL,
  gsa_classif_code     VARCHAR(200) NOT NULL,
  gsa_classif_desc     VARCHAR(500) NOT NULL,
  gsa_classif_id_padre INTEGER,
  livello              INTEGER NOT NULL,
  ambito_id            INTEGER NOT NULL,
  validita_inizio      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine        TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione       TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica        TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione   TIMESTAMP WITHOUT TIME ZONE,
  login_operazione     VARCHAR(200) NOT NULL,
  login_creazione VARCHAR(200) NOT NULL,
  login_modifica VARCHAR(200),
  login_cancellazione VARCHAR(200)
);


/* ---------------------------------------------------------------------- */
/*  Add foreign keys siac_d_gsa_classif_stato                             */
/* ---------------------------------------------------------------------- */
ALTER TABLE siac.siac_t_gsa_classif DROP CONSTRAINT IF EXISTS PK_siac_t_gsa_classif;
ALTER TABLE siac.siac_t_gsa_classif DROP CONSTRAINT IF EXISTS siac_t_ente_proprietario_siac_t_gsa_classif;
ALTER TABLE siac.siac_t_gsa_classif DROP CONSTRAINT IF EXISTS siac_t_gsa_classif_siac_t_gsa_classif;

ALTER TABLE siac.siac_t_gsa_classif ADD CONSTRAINT PK_siac_t_gsa_classif PRIMARY KEY (gsa_classif_id);
ALTER TABLE siac.siac_t_gsa_classif ADD CONSTRAINT siac_t_ente_proprietario_siac_t_gsa_classif FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE siac.siac_t_gsa_classif ADD CONSTRAINT siac_t_gsa_classif_siac_t_gsa_classif FOREIGN KEY (gsa_classif_id_padre)
	REFERENCES siac.siac_t_gsa_classif(gsa_classif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;	

/* ---------------------------------------------------------------------- */
/*  Create table siac_d_gsa_classif_stato                                 */
/* ---------------------------------------------------------------------- */	
	
CREATE TABLE IF NOT EXISTS siac.siac_d_gsa_classif_stato (
    gsa_classif_stato_id   SERIAL NOT NULL,
    gsa_classif_stato_code CHARACTER VARYING(200) NOT NULL,
    gsa_classif_stato_desc CHARACTER VARYING(500) NOT NULL,
    validita_inizio        TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine          TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id   INTEGER NOT NULL,
    data_creazione         TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica          TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione     TIMESTAMP WITHOUT TIME ZONE,
    login_operazione       CHARACTER VARYING(200) NOT NULL    
);

DROP INDEX IF EXISTS IDX_siac_d_gsa_classif_stato_1;

CREATE UNIQUE INDEX IDX_siac_d_gsa_classif_stato_1
ON siac.siac_d_gsa_classif_stato (gsa_classif_stato_code, validita_inizio, ente_proprietario_id) WHERE data_cancellazione IS NULL;

/* ---------------------------------------------------------------------- */
/*  Add foreign keys siac_d_gsa_classif_stato                             */
/* ---------------------------------------------------------------------- */

ALTER TABLE siac.siac_d_gsa_classif_stato DROP CONSTRAINT IF EXISTS PK_siac_d_gsa_classif_stato;
ALTER TABLE siac.siac_d_gsa_classif_stato DROP CONSTRAINT IF EXISTS siac_t_ente_proprietario_siac_d_gsa_classif_stato;

ALTER TABLE siac.siac_d_gsa_classif_stato ADD CONSTRAINT PK_siac_d_gsa_classif_stato PRIMARY KEY (gsa_classif_stato_id);
ALTER TABLE siac.siac_d_gsa_classif_stato ADD CONSTRAINT siac_t_ente_proprietario_siac_d_gsa_classif_stato FOREIGN KEY (ente_proprietario_id)
        REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION;
		
/* ---------------------------------------------------------------------- */
/*  Create table siac_r_gsa_classif_stato                                 */
/* ---------------------------------------------------------------------- */		
		
CREATE TABLE IF NOT EXISTS siac.siac_r_gsa_classif_stato (
    gsa_classif_r_stato_id SERIAL  NOT NULL,
    gsa_classif_id         INTEGER NOT NULL,
    gsa_classif_stato_id   INTEGER NOT NULL,
    validita_inizio        TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine          TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id   INTEGER NOT NULL,
    data_creazione         TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica          TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione     TIMESTAMP WITHOUT TIME ZONE,
    login_operazione       CHARACTER VARYING(200) NOT NULL
);

DROP INDEX IF EXISTS IDX_siac_r_gsa_classif_stato_1;
CREATE UNIQUE INDEX IDX_siac_r_gsa_classif_stato_1 ON siac.siac_r_gsa_classif_stato (gsa_classif_id,gsa_classif_stato_id,validita_inizio,ente_proprietario_id) WHERE data_cancellazione IS NULL;

/* ---------------------------------------------------------------------- */
/* Add foreign key constraints to siac_r_gsa_classif_stato                                           */
/* ---------------------------------------------------------------------- */

ALTER TABLE siac.siac_r_gsa_classif_stato DROP CONSTRAINT IF EXISTS siac_d_gsa_classif_stato_siac_r_gsa_classif_stato;
ALTER TABLE siac.siac_r_gsa_classif_stato DROP CONSTRAINT IF EXISTS siac_t_gsa_classif_stato_siac_r_gsa_classif_stato;
ALTER TABLE siac.siac_r_gsa_classif_stato DROP CONSTRAINT IF EXISTS siac_t_ente_proprietario_siac_r_gsa_classif_stato;
ALTER TABLE siac.siac_r_gsa_classif_stato DROP CONSTRAINT IF EXISTS PK_siac_r_gsa_classif_stato;

ALTER TABLE siac.siac_r_gsa_classif_stato ADD CONSTRAINT PK_siac_r_gsa_classif_stato PRIMARY KEY (gsa_classif_r_stato_id);

ALTER TABLE siac.siac_r_gsa_classif_stato ADD CONSTRAINT siac_d_gsa_classif_stato_siac_r_gsa_classif_stato 
    FOREIGN KEY (gsa_classif_stato_id)
	REFERENCES siac.siac_d_gsa_classif_stato (gsa_classif_stato_id)
	ON DELETE NO ACTION
    ON UPDATE NO ACTION;

ALTER TABLE siac.siac_r_gsa_classif_stato ADD CONSTRAINT siac_t_gsa_classif_stato_siac_r_gsa_classif_stato 
    FOREIGN KEY (gsa_classif_id)
	REFERENCES siac.siac_t_gsa_classif(gsa_classif_id)
	ON DELETE NO ACTION
    ON UPDATE NO ACTION;

ALTER TABLE siac.siac_r_gsa_classif_stato ADD CONSTRAINT siac_t_ente_proprietario_siac_r_gsa_classif_stato 
    FOREIGN KEY (ente_proprietario_id)
	REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
	ON DELETE NO ACTION
    ON UPDATE NO ACTION;

/* ---------------------------------------------------------------------- */
/*  Create table siac_r_gsa_classif_prima_nota                                 */
/* ---------------------------------------------------------------------- */
	
CREATE TABLE IF NOT EXISTS siac.siac_r_gsa_classif_prima_nota (
    gsa_classif_r_pnota_id SERIAL  NOT NULL,
    gsa_classif_id         INTEGER NOT NULL,
    pnota_id               INTEGER NOT NULL,
    validita_inizio        TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine          TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id   INTEGER NOT NULL,
    data_creazione         TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica          TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione     TIMESTAMP WITHOUT TIME ZONE,
    login_operazione       CHARACTER VARYING(200) NOT NULL
);

DROP INDEX IF EXISTS IDX_siac_r_gsa_classif_prima_nota_1;
CREATE UNIQUE INDEX IDX_siac_r_gsa_classif_prima_nota_1 ON siac.siac_r_gsa_classif_prima_nota (gsa_classif_id,pnota_id,validita_inizio,ente_proprietario_id) WHERE data_cancellazione IS NULL;

/* ---------------------------------------------------------------------- */
/* Add foreign key constraints to siac_r_gsa_classif_prima_nota                                           */
/* ---------------------------------------------------------------------- */

ALTER TABLE siac.siac_r_gsa_classif_prima_nota DROP CONSTRAINT IF EXISTS siac_t_prima_nota_siac_r_gsa_classif_prima_nota;
ALTER TABLE siac.siac_r_gsa_classif_prima_nota DROP CONSTRAINT IF EXISTS siac_t_gsa_classif_siac_r_gsa_classif_prima_nota;
ALTER TABLE siac.siac_r_gsa_classif_prima_nota DROP CONSTRAINT IF EXISTS siac_t_ente_proprietario_siac_r_gsa_classif_prima_nota;
ALTER TABLE siac.siac_r_gsa_classif_prima_nota DROP CONSTRAINT IF EXISTS PK_siac_r_gsa_classif_prima_nota;

ALTER TABLE siac.siac_r_gsa_classif_prima_nota ADD CONSTRAINT PK_siac_r_gsa_classif_prima_nota PRIMARY KEY (gsa_classif_r_pnota_id);

ALTER TABLE siac.siac_r_gsa_classif_prima_nota ADD CONSTRAINT siac_t_prima_nota_siac_r_gsa_classif_prima_nota 
    FOREIGN KEY (pnota_id)
	REFERENCES siac.siac_t_prima_nota (pnota_id)
	ON DELETE NO ACTION
    ON UPDATE NO ACTION;

ALTER TABLE siac.siac_r_gsa_classif_prima_nota ADD CONSTRAINT siac_t_gsa_classif_siac_r_gsa_classif_prima_nota 
    FOREIGN KEY (gsa_classif_id)
	REFERENCES siac.siac_t_gsa_classif(gsa_classif_id)
	ON DELETE NO ACTION
    ON UPDATE NO ACTION;

ALTER TABLE siac.siac_r_gsa_classif_prima_nota ADD CONSTRAINT siac_t_ente_proprietario_siac_r_gsa_classif_prima_nota 
    FOREIGN KEY (ente_proprietario_id)
	REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
	ON DELETE NO ACTION
    ON UPDATE NO ACTION;	

-- DML

INSERT INTO siac.siac_d_gsa_classif_stato(
	gsa_classif_stato_code, 
	gsa_classif_stato_desc,
	validita_inizio, 
	ente_proprietario_id,
	login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('V', 'Valido'),
	('A', 'Annullato')) AS tmp (code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gsa_classif_stato dsdt
	WHERE dsdt.ente_proprietario_id = tep.ente_proprietario_id
	AND dsdt.gsa_classif_stato_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;


-- Creazione dell'azione
INSERT INTO siac.siac_t_azione (
	azione_code,
	azione_desc,
	azione_tipo_id,
	gruppo_azioni_id,
	urlapplicazione,
	verificauo,
	validita_inizio,
	ente_proprietario_id,
	login_operazione
)
SELECT
	'OP-GEN-gestisciClassificatoriGSA',
	'Configura classificatore GSA',
	a.azione_tipo_id,b.gruppo_azioni_id,
	'/../siacbilapp/azioneRichiesta.do',
	FALSE,
	now(),
	a.ente_proprietario_id,
	'admin'
FROM
	siac_d_azione_tipo a,
	siac_d_gruppo_azioni b
WHERE b.ente_proprietario_id = a.ente_proprietario_id
AND a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = 'GEN_GSA'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione z
	WHERE z.azione_code = 'OP-GEN-gestisciClassificatoriGSA'
	AND z.ente_proprietario_id=a.ente_proprietario_id
);