/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- DDL

CREATE TABLE siac_t_elab_threshold (
	elthres_id         SERIAL NOT NULL,
	elthres_code       VARCHAR NOT NULL,
	elthres_value      BIGINT NOT NULL,
	validita_inizio    TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine      TIMESTAMP WITHOUT TIME ZONE,
	data_creazione     TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica      TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione   VARCHAR(200) NOT NULL
);

-- Valutare se il codice possa essere su una tabella di decodifica a parte, e avere la FK corrispondente

ALTER TABLE siac.siac_t_elab_threshold ADD CONSTRAINT PK_siac_t_elab_threshold PRIMARY KEY (elthres_id);

CREATE UNIQUE INDEX IDX_siac_t_elab_threshold_1
ON siac.siac_t_elab_threshold (elthres_code, validita_inizio) WHERE data_cancellazione IS NULL;

-- DML
INSERT INTO siac_t_elab_threshold (elthres_code, elthres_value, validita_inizio, login_operazione)
SELECT tmp.code, tmp.threshold, now(), 'admin'
FROM (VALUES ('COMPLETA_ATTO_ALLEGATO', 50),
	('EMETTITORE_INCASSO', 50),
	('EMETTITORE_PAGAMENTO', 50)) AS tmp(code, threshold)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_t_elab_threshold tet
	WHERE tet.elthres_code = tmp.code
);
