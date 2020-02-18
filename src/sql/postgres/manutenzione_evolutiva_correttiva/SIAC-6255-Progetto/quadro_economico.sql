/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.azione_tipo_id, dga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, to_timestamp('01/01/2019','dd/mm/yyyy'), tep.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_t_ente_proprietario tep ON (dat.ente_proprietario_id = tep.ente_proprietario_id)
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = tep.ente_proprietario_id)
CROSS JOIN (VALUES ('OP-GESC077-quadroEconomico', 'Quadro Economico', 'ATTIVITA_SINGOLA', 'BIL_ALTRO')) AS tmp(code, descr, tipo, gruppo)
WHERE dga.gruppo_azioni_code = tmp.gruppo
AND dat.azione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_tipo_id = dat.azione_tipo_id
	AND ta.azione_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

CREATE TABLE IF NOT EXISTS siac.siac_d_quadro_economico_parte (
  parte_id SERIAL,
  parte_code VARCHAR(200) NOT NULL,
  parte_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_quadro_economico_parte PRIMARY KEY(parte_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_quadro_economico_parte FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
) ;

CREATE TABLE IF NOT EXISTS siac.siac_d_quadro_economico_stato (
  quadro_economico_stato_id SERIAL,
  quadro_economico_stato_code VARCHAR(200) NOT NULL,
  quadro_economico_stato_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_quadro_economico_stato PRIMARY KEY(quadro_economico_stato_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_quadro_economico_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

select fnc_dba_create_index(
'siac_d_quadro_economico_stato'::text,
  'idx_siac_d_quadro_economico_stato_1'::text,
  'quadro_economico_stato_code, validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);

insert into siac_d_quadro_economico_stato
(quadro_economico_stato_code,quadro_economico_stato_desc  ,validita_inizio, ente_proprietario_id  ,login_operazione)
select tmp.code, tmp.descr, to_timestamp('01/01/2019','dd/mm/yyyy'),a.ente_proprietario_id,'admin'
from siac.siac_t_ente_proprietario a
CROSS JOIN (VALUES ('A'  ,'Annullato'), ('V'  ,'Valido'))as tmp (code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_quadro_economico_stato ta
	WHERE ta.ente_proprietario_id = a.ente_proprietario_id
	AND ta.quadro_economico_stato_code = tmp.code
	AND ta.data_cancellazione IS NULL
);


CREATE TABLE IF NOT EXISTS siac_t_quadro_economico (
  quadro_economico_id SERIAL,
  quadro_economico_code VARCHAR(200) NOT NULL,
  quadro_economico_desc VARCHAR(500) NOT NULL,
  quadro_economico_id_padre INTEGER,
  livello INTEGER NOT NULL, --valori ammessi: 0, 1, 2...
  parte_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  login_creazione VARCHAR(200) NOT NULL,
  login_modifica VARCHAR(200),
  login_cancellazione VARCHAR(200),
  CONSTRAINT pk_siac_t_quadro_economico PRIMARY KEY(quadro_economico_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_quadro_economico FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_quadro_economico_siac_t_quadro_economico FOREIGN KEY (quadro_economico_id_padre)
    REFERENCES siac.siac_t_quadro_economico(quadro_economico_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
) ;


CREATE TABLE IF NOT EXISTS siac_r_quadro_economico_stato (
  quadro_economico_r_stato_id SERIAL,
  quadro_economico_id INTEGER NOT NULL,
  quadro_economico_stato_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_quadro_economico_stato PRIMARY KEY(quadro_economico_r_stato_id),
  CONSTRAINT siac_d_quadro_economico_stato_siac_r_quadro_economico_stato FOREIGN KEY (quadro_economico_stato_id)
    REFERENCES siac.siac_d_quadro_economico_stato(quadro_economico_stato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_quadro_economico_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_quadro_economico_stato_siac_r_quadro_economico_stato FOREIGN KEY (quadro_economico_id)
    REFERENCES siac.siac_t_quadro_economico(quadro_economico_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

select fnc_dba_create_index(
'siac_r_quadro_economico_stato'::text,
  'idx_siac_r_quadro_economico_stato_1'::text,
  'quadro_economico_id, quadro_economico_stato_id, validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);

select fnc_dba_create_index(
'siac_r_quadro_economico_stato'::text,
  'siac_r_quadro_economico_stato_fk_quadro_economico_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);

select fnc_dba_create_index(
'siac_r_quadro_economico_stato'::text,
  'siac_r_quadro_economico_stato_fk_quadro_economico_stato_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);


insert into siac_d_quadro_economico_parte
(
  parte_code
  ,parte_desc
  ,validita_inizio
  ,ente_proprietario_id
  ,login_operazione
)
select tmp.code, tmp.descr, to_timestamp('01/01/2019','dd/mm/yyyy'), a.ente_proprietario_id, 'admin'
from siac_t_ente_proprietario a
cross join (values('A', 'A'), ('B', 'B'), ('C', 'C')) as tmp(code, descr)
where not exists (
select 1
from siac_d_quadro_economico_parte da
where da.ente_proprietario_id = a.ente_proprietario_id
and da.parte_code = tmp.code
and da.data_cancellazione is null
);

---- COLLEGAMENTO TRA QUADRO ECONOMICO E CRONOPROGRAMMA

SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop_elem_det', 'quadro_economico_id_padre' , 'INTEGER');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop_elem_det', 'quadro_economico_id_figlio' , 'INTEGER');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop_elem_det', 'quadro_economico_det_importo' , 'NUMERIC');

SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_t_cronop_elem_det',
	'siac_t_cronop_elem_det_siac_t_quadro_economico_padre',
    'quadro_economico_id_padre',
  	'siac_t_quadro_economico',
    'quadro_economico_id'
);

SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_t_cronop_elem_det',
	'siac_t_cronop_elem_det_siac_t_quadro_economico_figlio',
    'quadro_economico_id_figlio',
  	'siac_t_quadro_economico',
    'quadro_economico_id'
);

--ALTER TABLE siac_t_quadro_economico ADD CONSTRAINT uck_siac_t_quadro_economico_code_parte UNIQUE (quadro_economico_code,parte_id,quadro_economico_id_padre);
