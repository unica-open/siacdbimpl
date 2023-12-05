/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'cronop_data_approvazione_fattibilita' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'cronop_data_approvazione_programma_def' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'cronop_data_approvazione_programma_esec' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'cronop_data_avvio_procedura' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'cronop_data_aggiudicazione_lavori' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'cronop_data_inizio_lavori' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'cronop_data_fine_lavori' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'cronop_giorni_durata' , 'INTEGER');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'cronop_data_collaudo' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'gestione_quadro_economico' , 'BOOLEAN DEFAULT FALSE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_cronop', 'usato_per_fpv_prov' , 'BOOLEAN');



CREATE TABLE siac.siac_r_cronop_atto_amm (
  cronop_atto_amm_id SERIAL,
  cronop_id INTEGER NOT NULL,
  attoamm_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_cronop_atto_amm PRIMARY KEY(cronop_atto_amm_id),
  CONSTRAINT siac_t_atto_amm_siac_r_cronop_atto_amm FOREIGN KEY (attoamm_id)
    REFERENCES siac.siac_t_atto_amm(attoamm_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_cronop_atto_amm FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_cronop_siac_r_cronop_atto_amm FOREIGN KEY (cronop_id)
    REFERENCES siac.siac_t_cronop(cronop_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

INSERT INTO siac.siac_d_cronop_stato
(cronop_stato_code, cronop_stato_desc, validita_inizio, ente_proprietario_id, login_operazione)
select tmp.code,tmp.descr,to_timestamp('01/01/2017','dd/mm/yyyy'),a.ente_proprietario_id,'admin'
from siac.siac_t_ente_proprietario a
CROSS JOIN (
	VALUES ('PR', 'Provvisorio')
	) as tmp (code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_cronop_stato ta
	WHERE ta.ente_proprietario_id = a.ente_proprietario_id
	AND ta.cronop_stato_code = tmp.code
	AND ta.data_cancellazione IS NULL
);


CREATE TABLE IF NOT EXISTS siac.siac_r_movgest_ts_cronop_elem (
  movgest_ts_cronop_elem_id SERIAL,
  movgest_ts_id INTEGER NOT NULL,
  cronop_id INTEGER NOT NULL,
  cronop_elem_id INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_movgest_ts_cronop_elem PRIMARY KEY(movgest_ts_cronop_elem_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_movgest_ts_cronop_elem FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_movgest_ts_siac_r_movgest_ts_cronop_elem FOREIGN KEY (movgest_ts_id)
    REFERENCES siac.siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_cronop_elem_siac_r_movgest_ts_cronop_elem FOREIGN KEY (cronop_elem_id)
    REFERENCES siac.siac_t_cronop_elem(cronop_elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_cronop_siac_r_movgest_ts_cronop FOREIGN KEY (cronop_id)
    REFERENCES siac.siac_t_cronop(cronop_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
); 

INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.azione_tipo_id, dga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, to_timestamp('01/01/2013','dd/mm/yyyy'), tep.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_t_ente_proprietario tep ON (dat.ente_proprietario_id = tep.ente_proprietario_id)
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = tep.ente_proprietario_id)
CROSS JOIN (VALUES ('OP-GESC078-GestFPVProv', 
	'Gestione FPV non definitivi del cronop', 
	'AZIONE_SECONDARIA', 
	'BIL_ALTRO')) AS tmp(code, descr, tipo, gruppo)
WHERE dga.gruppo_azioni_code = tmp.gruppo
AND dat.azione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_tipo_id = dat.azione_tipo_id
	AND ta.azione_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;