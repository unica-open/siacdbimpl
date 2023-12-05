/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
--nuove colonne 'lisce' sulla siac_t_programma
SELECT * FROM fnc_dba_add_column_params ('siac_t_programma', 'programma_responsabile_unico' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_t_programma', 'programma_spazi_finanziari' , 'BOOLEAN');
SELECT * FROM fnc_dba_add_column_params ('siac_t_programma', 'bil_id' , 'INTEGER');
SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_t_programma',
	'siac_t_programma_siac_t_bil',
    'bil_id',
  	'siac_t_bil',
    'bil_id'
);

--nuove codifiche collegate alla siac_t_programma e collegamento con siac_t_programma
CREATE TABLE IF NOT EXISTS siac.siac_d_programma_affidamento (
  programma_affidamento_id SERIAL,
  programma_affidamento_code VARCHAR(200) NOT NULL,
  programma_affidamento_desc VARCHAR(500) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_programma_affidamento PRIMARY KEY(programma_affidamento_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_programma_affidamento FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

select fnc_dba_create_index(
'siac_d_programma_affidamento'::text,
  'idx_siac_d_programma_affidamento'::text,
  'programma_affidamento_code, validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);


SELECT * FROM fnc_dba_add_column_params ('siac_t_programma', 'programma_affidamento_id' , 'INTEGER');

SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_t_programma',
	'siac_t_programma_siac_d_programma_affidamento',
    'programma_affidamento_id',
  	'siac_d_programma_affidamento',
    'programma_affidamento_id'
);

CREATE TABLE IF NOT EXISTS siac.siac_d_programma_tipo(
  programma_tipo_id SERIAL,
  programma_tipo_code VARCHAR(200) NOT NULL,
  programma_tipo_desc VARCHAR(500) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_programma_tipo PRIMARY KEY(programma_tipo_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_programma_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

select fnc_dba_create_index(
'siac_d_programma_tipo'::text,
  'idx_siac_d_programma_tipo'::text,
  'programma_tipo_code, validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);


SELECT * FROM fnc_dba_add_column_params ('siac_t_programma', 'programma_tipo_id' , 'INTEGER');
SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_t_programma',
	'siac_t_programma_siac_d_programma_tipo',
    'programma_tipo_id',
  	'siac_d_programma_tipo',
    'programma_tipo_id'
);

--popolamento delle nuove tabelle di decodifica
INSERT INTO siac.siac_d_programma_affidamento
(programma_affidamento_code, programma_affidamento_desc, validita_inizio, ente_proprietario_id, login_operazione)
select tmp.code,tmp.descr,to_timestamp('01/01/2017','dd/mm/yyyy'),a.ente_proprietario_id,'admin'
from siac.siac_t_ente_proprietario a
CROSS JOIN (
	VALUES ('URG', 'LAVORI DI SOMMA URGENZA'),
	('AP', 'PROCEDURA APERTA'),
	('NEG-INF', 'PROCEDURA NEGOZIATA PREVIA GARA INFORMALE'),
	('NEG-DIR', 'PROCEDURA NEGOZIATA CON AFFIDAMENTO DIRETTO'),
	('PR', 'PROCEDURA RISTRETTA'),
	('AMM-DIR', 'AFFIDAMENTO IN ECONOMIA IN AMMINISTRAZIONE DIRETTA'),
	('COT-INF', 'AFFIDAMENTO IN ECON. A COTTIMO FIDUCIARIO PREVIA GARA INFORMALE'),
	('COT-DIR', 'AFFIDAMENTO IN ECONOMIA A COTTIMO FIDUCIARIO AFFIDAMENTO DIRETTO'),
	('GAR-ASS', 'ADESIONE A GARE IN FORME ASSOCIATE (ES. CONSIP)'),
	('VAR', 'VARIANTE IN CORSO D''OPERA'),
	('ALTR', 'ALTRO')
	) as tmp (code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_programma_affidamento ta
	WHERE ta.ente_proprietario_id = a.ente_proprietario_id
	AND ta.programma_affidamento_code = tmp.code
	AND ta.data_cancellazione IS NULL
);

INSERT INTO siac.siac_d_programma_tipo
(programma_tipo_code, programma_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
select tmp.code,tmp.descr,to_timestamp('01/01/2017','dd/mm/yyyy'),a.ente_proprietario_id,'admin'
from siac.siac_t_ente_proprietario a
CROSS JOIN (
	VALUES ('P', 'PREVISIONE'),
	('G', 'GESTIONE')
	) as tmp (code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_programma_tipo ta
	WHERE ta.ente_proprietario_id = a.ente_proprietario_id
	AND ta.programma_tipo_code = tmp.code
	AND ta.data_cancellazione IS NULL
);

--- il tipo programma e' chiave: gestisco il pregresso
update  siac_t_programma tp
set     programma_tipo_id =tipo.programma_tipo_id
from    siac_d_programma_tipo tipo
where tipo.ente_proprietario_id  = tp.ente_proprietario_id
and   tp.programma_tipo_id is null
and   tipo.programma_tipo_code = 'P';

