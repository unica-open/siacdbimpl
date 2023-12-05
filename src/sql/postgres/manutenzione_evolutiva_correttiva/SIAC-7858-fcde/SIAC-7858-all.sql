/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- siac_d_acc_fondi_dubbia_esig_tipo
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_tipo(
    afde_tipo_id SERIAL PRIMARY KEY,
    afde_tipo_code VARCHAR(50) NOT NULL,
    afde_tipo_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_tipo FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_stato
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_stato(
    afde_stato_id SERIAL PRIMARY KEY,
    afde_stato_code VARCHAR(50) NOT NULL,
    afde_stato_priorita INTEGER NOT NULL,
    afde_stato_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_stato FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_tipo_media
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_tipo_media(
    afde_tipo_media_id SERIAL PRIMARY KEY,
    afde_tipo_media_code VARCHAR(50) NOT NULL,
    afde_tipo_media_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_tipo_media FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_tipo_media_confronto
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_tipo_media_confronto(
    afde_tipo_media_conf_id SERIAL PRIMARY KEY,
    afde_tipo_media_conf_code VARCHAR(50) NOT NULL,
    afde_tipo_media_conf_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_tipo_media_confronto FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_t_acc_fondi_dubbia_esig_bil
CREATE TABLE IF NOT EXISTS siac.siac_t_acc_fondi_dubbia_esig_bil(
    afde_bil_id SERIAL PRIMARY KEY,
    bil_id INTEGER NOT NULL,
    afde_tipo_id INTEGER NOT NULL,
    afde_stato_id INTEGER NOT NULL,
    afde_bil_versione INTEGER NOT NULL,
    afde_bil_accantonamento_graduale NUMERIC,
    afde_bil_quinquennio_riferimento INTEGER,
    afde_bil_riscossione_virtuosa BOOLEAN,
    afde_bil_crediti_stralciati NUMERIC,
    afde_bil_crediti_stralciati_fcde NUMERIC,
    afde_bil_accertamenti_anni_successivi NUMERIC,
    afde_bil_accertamenti_anni_successivi_fcde NUMERIC,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_bil_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil(bil_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_d_acc_fondi_dubbia_esig_tipo_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (afde_tipo_id) REFERENCES siac.siac_d_acc_fondi_dubbia_esig_tipo(afde_tipo_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_d_acc_fondi_dubbia_esig_stato_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (afde_stato_id) REFERENCES siac.siac_d_acc_fondi_dubbia_esig_stato(afde_stato_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_t_ente_proprietario_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_t_acc_fondi_dubbia_esig_bil_num
CREATE TABLE IF NOT EXISTS siac.siac_t_acc_fondi_dubbia_esig_bil_num (
    afde_bil_num_id SERIAL PRIMARY KEY,
    bil_id INTEGER NOT NULL,
    afde_tipo_id INTEGER NOT NULL,
    afde_bil_versione INTEGER NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_bil_siac_t_acc_fondi_dubbia_esig_bil_num FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil(bil_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_d_acc_fondi_dubbia_esig_tipo_siac_t_acc_fondi_dubbia_esig_bil_num FOREIGN KEY (afde_tipo_id) REFERENCES siac.siac_d_acc_fondi_dubbia_esig_tipo(afde_tipo_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_t_ente_proprietario_siac_t_acc_fondi_dubbia_esig_bil_num FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);
CREATE UNIQUE INDEX siac_t_acc_fondi_dubbia_esig_bil_num_uq ON siac.siac_t_acc_fondi_dubbia_esig_bil_num USING btree (bil_id, afde_tipo_id) WHERE (data_cancellazione IS NULL);

-- siac_t_acc_fondi_dubbia_esig
-- Tutti i campi sono inizialmente nullable per evitare problematiche con il pregresso.
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_1', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_2', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_3', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_4', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_1', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_2', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_3', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_4', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_utente', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_semplice_totali', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_semplice_rapporti', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_ponderata_totali', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_ponderata_rapporti', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_confronto', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_note', 'TEXT');
-- SIAC-8393-8394 si aggiungono i campi dell'accantonamento per i 3 anni
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_accantonamento_anno', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_accantonamento_anno1', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_accantonamento_anno2', 'NUMERIC');


-- Metadati
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_1_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_2_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_3_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_4_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_1_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_2_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_3_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_4_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_media_utente_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_accantonamento_anno_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_accantonamento_anno1_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_accantonamento_anno2_originale', 'NUMERIC');

-- FK
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_d_acc_fondi_dubbia_esig_tipo_media_siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_id', 'siac_d_acc_fondi_dubbia_esig_tipo_media', 'afde_tipo_media_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_conf_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_d_acc_fondi_dubbia_esig_tipo_media_confronto_siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_conf_id', 'siac_d_acc_fondi_dubbia_esig_tipo_media_confronto', 'afde_tipo_media_conf_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_tipo_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_d_acc_fondi_dubbia_esig_tipo_siac_t_acc_fondi_dubbia_esig', 'afde_tipo_id', 'siac_d_acc_fondi_dubbia_esig_tipo', 'afde_tipo_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'elem_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_t_bil_elem_siac_t_acc_fondi_dubbia_esig', 'elem_id', 'siac_t_bil_elem', 'elem_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_bil_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_t_acc_fondi_dubbia_esig_bil_siac_t_acc_fondi_dubbia_esig', 'afde_bil_id', 'siac_t_acc_fondi_dubbia_esig_bil', 'afde_bil_id');

-- siac_d_tipo_campo
CREATE TABLE IF NOT EXISTS siac.siac_d_tipo_campo(
  tc_id SERIAL PRIMARY KEY,
  tc_code VARCHAR(250) NOT NULL,
  tc_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_t_ente_proprietario_siac_d_tipo_campo FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);
-- siac_t_visibilita
CREATE TABLE IF NOT EXISTS siac.siac_t_visibilita (
  vis_id SERIAL PRIMARY KEY,
  vis_campo VARCHAR(250) NOT NULL,
  vis_visibile BOOLEAN NOT NULL,
  tc_id INTEGER NOT NULL,
  vis_funzionalita VARCHAR(250),
  azione_id INTEGER,
  vis_default TEXT,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_t_ente_proprietario_siac_t_visibilita FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
  CONSTRAINT siac_d_tipo_campo_siac_t_visibilita FOREIGN KEY (tc_id) REFERENCES siac.siac_d_tipo_campo(tc_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
  CONSTRAINT siac_t_azione_siac_t_visibilita FOREIGN KEY (azione_id) REFERENCES siac.siac_t_azione(azione_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_tipo
INSERT INTO siac.siac_d_acc_fondi_dubbia_esig_tipo (afde_tipo_code, afde_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
	('PREVISIONE', 'Previsione'),
	('RENDICONTO', 'Rendiconto'),
	('GESTIONE', 'Gestione')
) AS tmp(code, descr)
CROSS JOIN siac.siac_t_ente_proprietario tep
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_acc_fondi_dubbia_esig_tipo current
	WHERE current.afde_tipo_code = tmp.code
	AND current.ente_proprietario_id = tep.ente_proprietario_id
);

-- siac_d_acc_fondi_dubbia_esig_stato
INSERT INTO siac.siac_d_acc_fondi_dubbia_esig_stato (afde_stato_code, afde_stato_desc, afde_stato_priorita, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.priorita, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
	('BOZZA', 'Bozza', 1),
	('DEFINITIVA', 'Definitiva', 0)
) AS tmp(code, descr, priorita)
CROSS JOIN siac.siac_t_ente_proprietario tep
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_acc_fondi_dubbia_esig_stato current
	WHERE current.afde_stato_code = tmp.code
	AND current.ente_proprietario_id = tep.ente_proprietario_id
);

-- siac_d_acc_fondi_dubbia_esig_tipo_media
INSERT INTO siac.siac_d_acc_fondi_dubbia_esig_tipo_media (afde_tipo_media_code, afde_tipo_media_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
	('SEMP_TOT', 'Media semplice dei totali'),
	('SEMP_RAP', 'Media semplice dei rapporti'),
	('POND_TOT', 'Media ponderata dei totali'),
	('POND_RAP', 'Media ponderata dei rapporti'),
	('UTENTE', 'Media utente')
) AS tmp(code, descr)
CROSS JOIN siac.siac_t_ente_proprietario tep
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_acc_fondi_dubbia_esig_tipo_media current
	WHERE current.afde_tipo_media_code = tmp.code
	AND current.ente_proprietario_id = tep.ente_proprietario_id
);

-- siac_d_acc_fondi_dubbia_esig_tipo_media_confronto
INSERT INTO siac.siac_d_acc_fondi_dubbia_esig_tipo_media_confronto (afde_tipo_media_conf_code, afde_tipo_media_conf_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
	('PREVISIONE', 'Previsione'),
	('GESTIONE', 'Gestione')
) AS tmp(code, descr)
CROSS JOIN siac.siac_t_ente_proprietario tep
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_acc_fondi_dubbia_esig_tipo_media_confronto current
	WHERE current.afde_tipo_media_conf_code = tmp.code
	AND current.ente_proprietario_id = tep.ente_proprietario_id
);

-- siac_t_attr
INSERT INTO siac.siac_t_attr (attr_code, attr_desc, attr_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.attr_tipo_id, now(), dat.ente_proprietario_id, 'ADMIN'
FROM (VALUES
	('FlagEntrataDubbiaEsigFCDE', 'Entrata di dubbia esigibilità (FCDE)', 'B')
) AS tmp(code, descr, tipo)
JOIN siac_d_attr_tipo dat ON dat.attr_tipo_code = tmp.tipo
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_t_attr current
	WHERE current.attr_code = tmp.code
	AND current.ente_proprietario_id = dat.ente_proprietario_id
);

-- siac_d_tipo_campo
INSERT INTO siac.siac_d_tipo_campo(tc_code, tc_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
  ('NUMERIC', 'Numerico'),
  ('INTEGER', 'Intero'),
  ('TEXT', 'Testo'),
  ('BOOLEAN', 'Boolean')
) AS tmp(code, descr)
CROSS JOIN siac.siac_t_ente_proprietario tep
WHERE NOT EXISTS (
  SELECT 1
  FROM siac.siac_d_tipo_campo current
  WHERE current.tc_code = tmp.code
  AND current.ente_proprietario_id = tep.ente_proprietario_id
  AND current.data_cancellazione IS NULL
);

-- siac_t_azione
INSERT INTO siac.siac_t_azione(azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.azione_tipo_id, dga.gruppo_azioni_id, tmp.url, tmp.verificauo, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
  ('OP-ENT-ConfStpFdceGes', 'Gestione Fondo Crediti Dubbia Esigibilità - Gestione', 'ATTIVITA_SINGOLA', 'BIL_CAP_GES', '/../siacbilapp/azioneRichiesta.do', FALSE)
) AS tmp(code, descr, tipo, gruppo, url, verificauo)
CROSS JOIN siac.siac_t_ente_proprietario tep
JOIN siac.siac_d_gruppo_azioni dga ON (dga.gruppo_azioni_code = tmp.gruppo AND dga.ente_proprietario_id = tep.ente_proprietario_id)
JOIN siac.siac_d_azione_tipo dat ON (dat.azione_tipo_code = tmp.tipo AND dat.ente_proprietario_id = tep.ente_proprietario_id)
WHERE NOT EXISTS (
  SELECT 1
  FROM siac.siac_t_azione current
  WHERE current.azione_code = tmp.code
  AND current.ente_proprietario_id = tep.ente_proprietario_id
  AND current.data_cancellazione IS NULL
);

-- siac_t_visibilita
INSERT INTO siac.siac_t_visibilita(vis_campo, vis_visibile, tc_id, vis_funzionalita, azione_id, vis_default, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.campo, tmp.visibile, dtc.tc_id, tmp.funzionalita, ta.azione_id, tmp.def, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
  ('quinquennio_riferimento', TRUE, 'INTEGER', 'FCDE_PREV', 'OP-ENT-ConfStpFdce', NULL),
  ('accantonamento_graduale', TRUE, 'NUMERIC', 'FCDE_PREV', 'OP-ENT-ConfStpFdce', NULL),
  ('riscossione_virtuosa', TRUE, 'BOOLEAN', 'FCDE_PREV', 'OP-ENT-ConfStpFdce', NULL),
  
  ('quinquennio_riferimento', TRUE, 'INTEGER', 'FCDE_REND', 'OP-ENT-ConfStpFdceRen', NULL),
  ('accantonamento_graduale', FALSE, 'NUMERIC', 'FCDE_REND', 'OP-ENT-ConfStpFdceRen', '100'),
  ('riscossione_virtuosa', FALSE, 'BOOLEAN', 'FCDE_REND', 'OP-ENT-ConfStpFdceRen', 'false'),
  
  ('quinquennio_riferimento', TRUE, 'INTEGER', 'FCDE_REND', 'OP-ENT-ConfStpFdceGes', NULL),
  ('accantonamento_graduale', FALSE, 'NUMERIC', 'FCDE_REND', 'OP-ENT-ConfStpFdceGes', '100'),
  ('riscossione_virtuosa', FALSE, 'BOOLEAN', 'FCDE_REND', 'OP-ENT-ConfStpFdceGes', 'false')
) AS tmp(campo, visibile, tipo, funzionalita, azione, def)
CROSS JOIN siac_t_ente_proprietario tep
JOIN siac_d_tipo_campo dtc ON (dtc.tc_code = tmp.tipo AND dtc.ente_proprietario_id = tep.ente_proprietario_id)
LEFT OUTER JOIN siac_t_azione ta ON (ta.azione_code = tmp.azione AND ta.ente_proprietario_id = tep.ente_proprietario_id)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_t_visibilita current
	WHERE current.vis_campo = tmp.campo
	AND current.vis_funzionalita = tmp.funzionalita
	AND current.azione_id = ta.azione_id
	AND current.ente_proprietario_id = tep.ente_proprietario_id
);

-- EXCEL PREVISIONE
DROP FUNCTION IF EXISTS siac.fnc_siac_acc_fondi_dubbia_esig_by_attr_bil(INTEGER);
CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_by_attr_bil(p_afde_bil_id INTEGER)
	RETURNS TABLE(
		versione                 INTEGER,
		fase_attributi_bilancio  VARCHAR,
		stato_attributi_bilancio VARCHAR,
--		utente                   VARCHAR,
		data_ora_elaborazione    TIMESTAMP WITHOUT TIME ZONE,
		anni_esercizio           VARCHAR,
		riscossione_virtuosa     BOOLEAN,
		quinquennio_riferimento  VARCHAR,
		capitolo                 VARCHAR,
		articolo                 VARCHAR,
		ueb                      VARCHAR,
		titolo_entrata           VARCHAR,
		tipologia                VARCHAR,
		categoria                VARCHAR,
		sac                      VARCHAR,
		incassi_4                NUMERIC,
		accertamenti_4           NUMERIC,
		incassi_3                NUMERIC,
		accertamenti_3           NUMERIC,
		incassi_2                NUMERIC,
		accertamenti_2           NUMERIC,
		incassi_1                NUMERIC,
		accertamenti_1           NUMERIC,
		incassi_0                NUMERIC,
		accertamenti_0           NUMERIC,
		media_semplice_totali    NUMERIC,
		media_semplice_rapporti  NUMERIC,
		media_ponderata_totali   NUMERIC,
		media_ponderata_rapporti NUMERIC,
		media_utente             NUMERIC,
		percentuale_minima       NUMERIC,
		percentuale_effettiva    NUMERIC,
		stanziamento_0           NUMERIC,
		stanziamento_1           NUMERIC,
		stanziamento_2           NUMERIC,
		accantonamento_fcde_0    NUMERIC,
		accantonamento_fcde_1    NUMERIC,
		accantonamento_fcde_2    NUMERIC,
		accantonamento_graduale  NUMERIC
	) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		)
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				WHEN 'SEMP_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				WHEN 'POND_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				WHEN 'POND_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
				WHEN 'UTENTE'   THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS stanziamento_0
			, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS stanziamento_1
			, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS stanziamento_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
		percentuale_effettiva := v_loop_var.acc_fde_media;
		stanziamento_0        := v_loop_var.stanziamento_0;
		stanziamento_1        := v_loop_var.stanziamento_1;
		stanziamento_2        := v_loop_var.stanziamento_2;
		-- /10000 perche' ho due percentuali per cui moltiplico (v_loop_var.acc_fde_media e accantonamento_graduale)
		-- SIAC-8446: arrotondo gli importi a due cifre decimali
		accantonamento_fcde_0 := ROUND(v_loop_var.stanziamento_0 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		accantonamento_fcde_1 := ROUND(v_loop_var.stanziamento_1 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		accantonamento_fcde_2 := ROUND(v_loop_var.stanziamento_2 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
		INTO
			incassi_4
			, accertamenti_4
			, incassi_3
			, accertamenti_3
			, incassi_2
			, accertamenti_2
			, incassi_1
			, accertamenti_1
			, incassi_0
			, accertamenti_0
			, media_semplice_totali
			, media_semplice_rapporti
			, media_ponderata_totali
			, media_ponderata_rapporti
			, media_utente
			, percentuale_minima
		FROM siac_t_acc_fondi_dubbia_esig
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- EXCEL GESTIONE
DROP FUNCTION IF EXISTS siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil(INTEGER);
CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil(p_afde_bil_id INTEGER)
	RETURNS TABLE(
		versione                     INTEGER,
		fase_attributi_bilancio      VARCHAR,
		stato_attributi_bilancio     VARCHAR,
--		utente                       VARCHAR,
		data_ora_elaborazione        TIMESTAMP WITHOUT TIME ZONE,
		anni_esercizio               VARCHAR,
		riscossione_virtuosa		 BOOLEAN,
		quinquennio_riferimento      VARCHAR,
		capitolo                     VARCHAR,
		articolo                     VARCHAR,
		ueb                          VARCHAR,
		titolo_entrata               VARCHAR,
		tipologia                    VARCHAR,
		categoria                    VARCHAR,
		sac                          VARCHAR,
		incasso_conto_competenza     NUMERIC,
		accertato_conto_competenza   NUMERIC,
--		stanziato                    NUMERIC,
--		max_stanziato_accertato_0    NUMERIC,
--		max_stanziato_accertato_1    NUMERIC,
--		max_stanziato_accertato_2    NUMERIC,
		percentuale_incasso_gestione NUMERIC,
		percentuale_accantonamento   NUMERIC,
		tipo_precedente              VARCHAR,
		percentuale_precedente       NUMERIC,
		percentuale_minima           NUMERIC,
		percentuale_effettiva        NUMERIC,
		stanziamento_0               NUMERIC,
		stanziamento_1               NUMERIC,
		stanziamento_2               NUMERIC,
		accantonamento_fcde_0        NUMERIC,
		accantonamento_fcde_1        NUMERIC,
		accantonamento_fcde_2        NUMERIC,
		accantonamento_graduale      NUMERIC
	) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		)
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				WHEN 'UTENTE'   THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS stanziamento_0
			, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS stanziamento_1
			, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS stanziamento_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
		percentuale_effettiva := v_loop_var.acc_fde_media;
		stanziamento_0        := v_loop_var.stanziamento_0;
		stanziamento_1        := v_loop_var.stanziamento_1;
		stanziamento_2        := v_loop_var.stanziamento_2;
		-- /10000 perche' ho due percentuali per cui moltiplico (v_loop_var.acc_fde_media e accantonamento_graduale)
		-- SIAC-8446: arrotondo gli importi a due cifre decimali
		accantonamento_fcde_0 := ROUND(v_loop_var.stanziamento_0 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		accantonamento_fcde_1 := ROUND(v_loop_var.stanziamento_1 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		accantonamento_fcde_2 := ROUND(v_loop_var.stanziamento_2 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
			, siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_desc
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
		INTO
			  incasso_conto_competenza
			, accertato_conto_competenza
			, percentuale_incasso_gestione
			, percentuale_accantonamento
			, tipo_precedente
			, percentuale_precedente
			, percentuale_minima
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media_confronto ON (siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_conf_id AND siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.data_cancellazione IS NULL)
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- EXCEL RENDICONTO
DROP FUNCTION IF EXISTS siac.fnc_siac_acc_fondi_dubbia_esig_rendiconto_by_attr_bil(INTEGER);
CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_rendiconto_by_attr_bil(p_afde_bil_id INTEGER)
	RETURNS TABLE(
		versione                 INTEGER,
		fase_attributi_bilancio  VARCHAR,
		stato_attributi_bilancio VARCHAR,
--		utente                   VARCHAR,
		data_ora_elaborazione    TIMESTAMP WITHOUT TIME ZONE,
		anni_esercizio           VARCHAR,
		riscossione_virtuosa     BOOLEAN,
		quinquennio_riferimento  VARCHAR,
		capitolo                 VARCHAR,
		articolo                 VARCHAR,
		ueb                      VARCHAR,
		titolo_entrata           VARCHAR,
		tipologia                VARCHAR,
		categoria                VARCHAR,
		sac                      VARCHAR,
		residui_4                NUMERIC,
		incassi_conto_residui_4  NUMERIC,
		residui_3                NUMERIC,
		incassi_conto_residui_3  NUMERIC,
		residui_2                NUMERIC,
		incassi_conto_residui_2  NUMERIC,
		residui_1                NUMERIC,
		incassi_conto_residui_1  NUMERIC,
		residui_0                NUMERIC,
		incassi_conto_residui_0  NUMERIC,
		media_semplice_totali    NUMERIC,
		media_semplice_rapporti  NUMERIC,
		media_ponderata_totali   NUMERIC,
		media_ponderata_rapporti NUMERIC,
		media_utente             NUMERIC,
		percentuale_minima       NUMERIC,
		percentuale_effettiva    NUMERIC,
		residui_finali           NUMERIC,
	--	residui_finali_1         NUMERIC,
	--	residui_finali_2         NUMERIC,
		accantonamento_fcde      NUMERIC,
	--	accantonamento_fcde_1    NUMERIC,
	--	accantonamento_fcde_2    NUMERIC,
		accantonamento_graduale  NUMERIC
	) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			-- TODO: aggiungere i dati delle variazioni non definitive e non annullate
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		)
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				WHEN 'SEMP_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				WHEN 'POND_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				WHEN 'POND_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
				WHEN 'UTENTE'   THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS residui_finali
			--, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS residui_finali_1
			--, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS residui_finali_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
		percentuale_effettiva := v_loop_var.acc_fde_media;
		residui_finali        := v_loop_var.residui_finali;
		--residui_finali_1      := v_loop_var.residui_finali_1;		
		--residui_finali_2      := v_loop_var.residui_finali_2;
		-- /100 perche' ho una percentuale per cui moltiplico (v_loop_var.acc_fde_media)
		accantonamento_fcde   := v_loop_var.residui_finali * v_loop_var.acc_fde_media / 100;
		--accantonamento_fcde_1 := v_loop_var.residui_finali_1 * v_loop_var.acc_fde_media / 100;
		--accantonamento_fcde_2 := v_loop_var.residui_finali_2 * v_loop_var.acc_fde_media / 100;
		
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
			-- SIAC-8446 - lettura del dato da DB
			, siac_t_acc_fondi_dubbia_esig.acc_fde_accantonamento_anno
		INTO
			incassi_conto_residui_4
			, residui_4
			, incassi_conto_residui_3
			, residui_3
			, incassi_conto_residui_2
			, residui_2
			, incassi_conto_residui_1
			, residui_1
			, incassi_conto_residui_0
			, residui_0
			, media_semplice_totali
			, media_semplice_rapporti
			, media_ponderata_totali
			, media_ponderata_rapporti
			, media_utente
			, percentuale_minima
			, accantonamento_fcde
		FROM siac_t_acc_fondi_dubbia_esig
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


-- MEDI DI CONFRONTO PER LA GESTIONE
DROP FUNCTION IF EXISTS siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER);
CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER)
RETURNS SETOF VARCHAR AS 
$body$
DECLARE
    v_messaggiorisultato VARCHAR;
    v_perc_media_confronto NUMERIC;
    v_tipo_media_confronto VARCHAR;
    v_uid_capitolo_previsione INTEGER;
    v_elem_code VARCHAR;
    v_elem_code2 VARCHAR;
BEGIN

	SELECT stbe.elem_code, stbe.elem_code2 
	FROM siac_t_bil_elem stbe 
	WHERE stbe.elem_id = p_uid_elem_gestione
	AND stbe.data_cancellazione IS NULL INTO v_elem_code, v_elem_code2;

	v_messaggiorisultato := 'Ricerca per capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di GESTIONE';
	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	
    v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti precedenti di GESTIONE';
    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

    v_tipo_media_confronto := 'GESTIONE';

    SELECT COALESCE (
        -- (
        --     SELECT tafdeEquiv.perc_acc_fondi
        --     FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        --     JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        --     JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        --     JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        --     JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        --     JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        --     JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        --     WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
        --     AND tafdeEquiv.elem_id = p_uid_elem_gestione
        --     AND step.ente_proprietario_id = p_uid_ente_proprietario
        --     AND sdafdes.afde_stato_code = 'DEFINITIVA'
        --     AND tafdeEquiv.data_cancellazione IS NULL 
        --     AND tafdeEquiv.validita_fine IS NULL 
        --     ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1
        -- ),
        (
            SELECT tafdeEquiv.perc_acc_fondi 
            FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
            JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
            JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
            JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
            JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
            --JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
            --JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
            WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
            AND tafdeEquiv.elem_id = p_uid_elem_gestione
            AND step.ente_proprietario_id = p_uid_ente_proprietario
            --AND sdafdes.afde_stato_code = 'BOZZA'
            AND tafdeEquiv.data_cancellazione IS NULL 
            AND tafdeEquiv.validita_fine IS NULL 
            ORDER BY stafdeb.afde_bil_versione ASC LIMIT 1
        )
    ) INTO v_perc_media_confronto;

    
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO TROVATA IN GESTIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco uid del capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        SELECT stbe.elem_id
        FROM siac_t_bil_elem stbe 
        JOIN siac_t_bil stb ON stbe.bil_id = stb.bil_id 
        JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id 
        JOIN siac_d_bil_elem_tipo sdbet ON stbe.elem_tipo_id = sdbet.elem_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = stbe.ente_proprietario_id 
        WHERE stbe.elem_code = v_elem_code 
        AND stbe.elem_code2 = v_elem_code2
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND stp.anno = p_anno_bilancio::VARCHAR
        AND sdbet.elem_tipo_code = 'CAP-EP'
        AND stbe.data_cancellazione IS NULL INTO v_uid_capitolo_previsione;
        
        IF v_uid_capitolo_previsione IS NOT NULL THEN
            v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - UID: [' || v_uid_capitolo_previsione || '] TROVATO.';
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	    END IF;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti precedenti di PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_tipo_media_confronto := 'PREVISIONE';

        SELECT COALESCE (
            (
                SELECT tafdeEquiv.perc_acc_fondi
                FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
                JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
                JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
                JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
                JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
                JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
                JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
                WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
                AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
                AND step.ente_proprietario_id = p_uid_ente_proprietario
                AND sdafdes.afde_stato_code = 'DEFINITIVA'
                AND tafdeEquiv.data_cancellazione IS NULL 
                AND tafdeEquiv.validita_fine IS NULL 
                ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1
            ),
            (
                SELECT tafdeEquiv.perc_acc_fondi 
                FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
                JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
                JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
                JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
                JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
                JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
                JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
                WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
                AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
                AND step.ente_proprietario_id = p_uid_ente_proprietario
                AND sdafdes.afde_stato_code = 'BOZZA'
                AND tafdeEquiv.data_cancellazione IS NULL 
                AND tafdeEquiv.validita_fine IS NULL 
                ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1
            )
        ) INTO v_perc_media_confronto;
    
    END IF;

    IF v_perc_media_confronto IS NOT NULL THEN
		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - MEDIA DI CONFRONTO: [' || v_perc_media_confronto || ' - ' || v_tipo_media_confronto || ' ]';
	ELSE 
		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO TROVATA';
    END IF;

    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

	-- [0, 1] => [0] percentuale incasso precedente, [1] => tipoMedia
    RETURN QUERY VALUES (v_perc_media_confronto::VARCHAR), (v_tipo_media_confronto);

    EXCEPTION
        WHEN RAISE_EXCEPTION THEN
            v_messaggiorisultato := v_messaggiorisultato || ' - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;
        WHEN others THEN
            v_messaggiorisultato := v_messaggiorisultato || ' others - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;


--SIAC-8154 - Maurizio - INIZIO 

DROP FUNCTION if exists siac."BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita"(p_ente_prop_id integer, p_anno varchar, p_anno_competenza varchar);
DROP FUNCTION if exists siac."BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_EELL"(p_ente_prop_id integer, p_anno varchar, p_anno_competenza varchar);
DROP FUNCTION if exists siac."BILR148_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_cons"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR170_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dettaglio"(p_ente_prop_id integer, p_anno varchar, p_anno_competenza varchar);
DROP FUNCTION if exists siac."BILR182_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dett_rend"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR183_FCDE_assestamento"(p_ente_prop_id integer, p_anno varchar);

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR148_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_cons" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  residui_attivi numeric,
  residui_attivi_prec numeric,
  totale_residui_attivi numeric,
  importo_minimo_fondo numeric,
  bil_ele_code3 varchar,
  flag_cassa integer,
  accertamenti_succ numeric,
  crediti_stralciati numeric,
  fondo_dubbia_esig numeric,
  afde_bil_crediti_stralciati numeric,
  afde_bil_crediti_stralciati_fcde numeric,
  afde_bil_accertamenti_anni_successivi numeric,
  afde_bil_accertamenti_anni_successivi_fcde numeric,
  colonna_e numeric
) AS
$body$
DECLARE

classifBilRec record;
bilancio_id integer;
annoCapImp_int integer;
tipomedia varchar;
RTN_MESSAGGIO text;
afde_bilancioId integer;
var_afde_bil_crediti_stralciati numeric;
var_afde_bil_crediti_stralciati_fcde numeric;
var_afde_bil_accertamenti_anni_successivi numeric;
var_afde_bil_accertamenti_anni_successivi_fcde numeric;
  
BEGIN
RTN_MESSAGGIO:='select 1';

annoCapImp_int:= p_anno::integer; 

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

/*
	SIAC-8154 13/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    
select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

if tipomedia is null then
   tipomedia = 'SEMPLICE';
end if;

*/

--SIAC-8154 21/07/2021
--devo leggere afde_bil_id che serve per l'accesso alla tabella 
--siac.siac_t_acc_fondi_dubbia_esig 
select 	fondi_bil.afde_bil_id, 
	COALESCE(fondi_bil.afde_bil_crediti_stralciati,0),
	COALESCE(fondi_bil.afde_bil_crediti_stralciati_fcde,0),
    COALESCE(fondi_bil.afde_bil_accertamenti_anni_successivi,0),
    COALESCE(fondi_bil.afde_bil_accertamenti_anni_successivi_fcde,0)    
	into afde_bilancioId, var_afde_bil_crediti_stralciati,
    var_afde_bil_crediti_stralciati_fcde, var_afde_bil_accertamenti_anni_successivi,
    var_afde_bil_accertamenti_anni_successivi_fcde    
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='RENDICONTO' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;
    
--    var_afde_bil_crediti_stralciati:=100;
--    var_afde_bil_crediti_stralciati_fcde:=200;
--    var_afde_bil_accertamenti_anni_successivi:=300;
--    var_afde_bil_accertamenti_anni_successivi_fcde:=400;
    
return query
select zz.* from (
with clas as (
	select classif_tipo_desc1 titent_tipo_desc, titolo_code titent_code,
    	 titolo_desc titent_desc, titolo_validita_inizio titent_validita_inizio,
         titolo_validita_fine titent_validita_fine, 
         classif_tipo_desc2 tipologia_tipo_desc,
         tipologia_id, strutt.tipologia_code tipologia_code, 
         strutt.tipologia_desc tipologia_desc,
         tipologia_validita_inizio, tipologia_validita_fine,
         classif_tipo_desc3 categoria_tipo_desc,
         categoria_id, strutt.categoria_code categoria_code, 
         strutt.categoria_desc categoria_desc,
         categoria_validita_inizio, categoria_validita_fine,
         ente_proprietario_id
    from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, 
    											   p_anno,'') strutt 
),
capall as (
with
cap as (
select bil_elem.elem_id,bil_elem.elem_code,bil_elem.elem_desc,
  bil_elem.elem_code2,bil_elem.elem_desc2,bil_elem.elem_id_padre,
  bil_elem.elem_code3,class.classif_id , 
  fcde.acc_fde_denominatore,fcde.acc_fde_denominatore_1,
  fcde.acc_fde_denominatore_2,
  fcde.acc_fde_denominatore_3,fcde.acc_fde_denominatore_4,
  fcde.acc_fde_numeratore,fcde.acc_fde_numeratore_1,
  fcde.acc_fde_numeratore_2,
  fcde.acc_fde_numeratore_3,fcde.acc_fde_numeratore_4,
  case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
        COALESCE(fcde.acc_fde_media_semplice_rapporti, 0)          
    else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
      COALESCE(fcde.acc_fde_media_semplice_totali, 0)        
    else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
        COALESCE(fcde.acc_fde_media_ponderata_rapporti, 0)
    else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
        COALESCE(fcde.acc_fde_media_ponderata_totali,0)     
    else case when tipo_media.afde_tipo_media_code ='UTENTE' then
        COALESCE(fcde.acc_fde_media_utente, 0)      
    end end end end end perc_media_applicata
from siac_t_bil_elem bil_elem,	
--SIAC-8154 07/10/2021.
--aggiunto legame con la tabella dell'fcde perche' si devono
--estrarre solo i capitoli coinvolti.
	 siac_t_acc_fondi_dubbia_esig fcde
     	left join siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
        	on tipo_media.afde_tipo_media_id=fcde.afde_tipo_media_id,
     siac_d_bil_elem_tipo bil_elem_tipo,
     siac_r_bil_elem_class r_bil_elem_class,
 	 siac_t_class class,	
     siac_d_class_tipo d_class_tipo,
	 siac_r_bil_elem_categoria r_bil_elem_categ,	
     siac_d_bil_elem_categoria d_bil_elem_categ, 
     siac_r_bil_elem_stato r_bil_elem_stato, 
     siac_d_bil_elem_stato d_bil_elem_stato 
where bil_elem.elem_tipo_id		 = bil_elem_tipo.elem_tipo_id 
and   r_bil_elem_class.elem_id   = bil_elem.elem_id
and   class.classif_id           = r_bil_elem_class.classif_id
and   d_class_tipo.classif_tipo_id      = class.classif_tipo_id
and   d_bil_elem_categ.elem_cat_id          = r_bil_elem_categ.elem_cat_id
and   r_bil_elem_categ.elem_id              = bil_elem.elem_id
and   r_bil_elem_stato.elem_id              = bil_elem.elem_id
and   d_bil_elem_stato.elem_stato_id        = r_bil_elem_stato.elem_stato_id
and   fcde.elem_id						= bil_elem.elem_id
and   bil_elem.ente_proprietario_id = p_ente_prop_id
and   bil_elem.bil_id               = bilancio_id
and   fcde.afde_bil_id				=  afde_bilancioId
and   bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'
and   d_class_tipo.classif_tipo_code	 = 'CATEGORIA'
and	  d_bil_elem_categ.elem_cat_code	     = 'STD'
and	  d_bil_elem_stato.elem_stato_code	     = 'VA'
and   bil_elem.data_cancellazione   is null
and	  bil_elem_tipo.data_cancellazione   is null
and	  r_bil_elem_class.data_cancellazione	 is null
and	  class.data_cancellazione	 is null
and	  d_class_tipo.data_cancellazione 	 is null
and	  r_bil_elem_categ.data_cancellazione 	 is null
and	  d_bil_elem_categ.data_cancellazione	 is null
and	  r_bil_elem_stato.data_cancellazione   is null
and	  d_bil_elem_stato.data_cancellazione   is null
and   fcde.data_cancellazione is null
), 
resatt as ( -- Residui Attivi 
select capitolo.elem_id,
       sum (dt_movimento.movgest_ts_det_importo) residui_accertamenti,
       CASE 
         WHEN movimento.movgest_anno < annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'I' THEN
            'RESATT' 
         WHEN movimento.movgest_anno = annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'A' THEN  
            'ACCERT' 
         ELSE
            'ALTRO'
       END tipo_importo         
from siac_t_bil_elem                  capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id 
inner join siac_d_movgest_tipo        tipo_mov on movimento.movgest_tipo_id = tipo_mov.movgest_tipo_id 
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id 
inner join siac_r_movgest_ts_stato    r_movimento_stato on ts_movimento.movgest_ts_id = r_movimento_stato.movgest_ts_id 
inner join siac_d_movgest_stato       tipo_stato on r_movimento_stato.movgest_stato_id = tipo_stato.movgest_stato_id
inner join siac_t_movgest_ts_det      dt_movimento on ts_movimento.movgest_ts_id = dt_movimento.movgest_ts_id 
inner join siac_d_movgest_ts_tipo     ts_mov_tipo on ts_movimento.movgest_ts_tipo_id = ts_mov_tipo.movgest_ts_tipo_id
inner join siac_d_movgest_ts_det_tipo dt_mov_tipo on dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id 
where capitolo.ente_proprietario_id     =   p_ente_prop_id
and   capitolo.bil_id      				=	bilancio_id
and   t_capitolo.elem_tipo_code    		= 	'CAP-EG'
and   movimento.movgest_anno 	        <= 	annoCapImp_int
and   movimento.bil_id					=	bilancio_id
and   tipo_mov.movgest_tipo_code    	=   'A' 
and   tipo_stato.movgest_stato_code     in  ('D','N')
and   ts_mov_tipo.movgest_ts_tipo_code  =   'T'
and   dt_mov_tipo.movgest_ts_det_tipo_code in ('I','A')
and   capitolo.data_cancellazione     	is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione    	is null 
and   movimento.data_cancellazione     	is null 
and   tipo_mov.data_cancellazione     	is null 
and   r_movimento_stato.data_cancellazione is null 
and   ts_movimento.data_cancellazione   is null 
and   tipo_stato.data_cancellazione    	is null 
and   dt_movimento.data_cancellazione   is null 
and   ts_mov_tipo.data_cancellazione    is null 
and   dt_mov_tipo.data_cancellazione    is null
and   now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and   now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
group by tipo_importo, capitolo.elem_id
),
resrisc as ( -- Riscossione residui
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_residui,
            CASE 
             WHEN movimento.movgest_anno < annoCapImp_int THEN
                'RISRES'
             ELSE
                'RISCOMP'
             END tipo_importo                    
from  siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
      siac_t_ordinativo				    ordinativo,
      siac_d_ordinativo_tipo			tipo_ordinativo,
      siac_r_ordinativo_stato			r_stato_ordinativo,
      siac_d_ordinativo_stato			stato_ordinativo,
      siac_t_ordinativo_ts 			    ordinativo_det,
      siac_t_ordinativo_ts_det 		    ordinativo_imp,
      siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
      siac_t_movgest     				movimento,
      siac_t_movgest_ts    			    ts_movimento, 
      siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
where r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
    and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
    and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
    and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
    and	ordinativo.ord_id					=	ordinativo_det.ord_id
    and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
    and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
    and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
    and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
    and	ts_movimento.movgest_id				=	movimento.movgest_id
    and ordinativo_det.ente_proprietario_id	    =	p_ente_prop_id
    and	tipo_ordinativo.ord_tipo_code		= 	'I'	-- Incasso
    ------------------------------------------------------------------------------------------		
    ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
    and	stato_ordinativo.ord_stato_code			<> 'A' -- Annullato
    -----------------------------------------------------------------------------------------------
    and	ordinativo.bil_id					=	bilancio_id
    and movimento.bil_id					=	bilancio_id	
    and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	-- Importo attuale
    and	movimento.movgest_anno				<=	annoCapImp_int	
    and	r_capitolo_ordinativo.data_cancellazione	is null
    and	ordinativo.data_cancellazione				is null
    and	tipo_ordinativo.data_cancellazione			is null
    and	r_stato_ordinativo.data_cancellazione		is null
    and	stato_ordinativo.data_cancellazione			is null
    and ordinativo_det.data_cancellazione			is null
    and ordinativo_imp.data_cancellazione			is null
    and ordinativo_imp_tipo.data_cancellazione		is null
    and	movimento.data_cancellazione				is null
    and	ts_movimento.data_cancellazione				is null
    and	r_ordinativo_movgest.data_cancellazione		is null
    and now() between r_capitolo_ordinativo.validita_inizio and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now() between r_stato_ordinativo.validita_inizio and COALESCE(r_stato_ordinativo.validita_fine,now())
	and now() between r_ordinativo_movgest.validita_inizio and COALESCE(r_ordinativo_movgest.validita_fine,now())
group by tipo_importo, r_capitolo_ordinativo.elem_id
),
resriacc as ( -- Riaccertamenti residui
select capitolo.elem_id,
       sum (t_movgest_ts_det_mod.movgest_ts_det_importo) riaccertamenti_residui
from siac_t_bil_elem     capitolo , 
     siac_r_movgest_bil_elem   r_mov_capitolo, 
     siac_d_bil_elem_tipo    t_capitolo, 
     siac_t_movgest     movimento, 
     siac_d_movgest_tipo    tipo_mov, 
     siac_t_movgest_ts    ts_movimento, 
     siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato, 
     siac_t_movgest_ts_det   dt_movimento, 
     siac_d_movgest_ts_tipo   ts_mov_tipo, 
     siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
     siac_t_modifica t_modifica,
     siac_r_modifica_stato r_mod_stato,
     siac_d_modifica_stato d_mod_stato,
     siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
     where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
       and r_mov_capitolo.elem_id    		=	capitolo.elem_id
       and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
       and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
       and movimento.movgest_id      		= 	ts_movimento.movgest_id 
       and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
       and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
       and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
       and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
       and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
       and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
       and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
       and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id 
       and r_mod_stato.mod_id=t_modifica.mod_id              
       and capitolo.ente_proprietario_id   = p_ente_prop_id           
       and capitolo.bil_id      				=	bilancio_id
       and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
       and movimento.movgest_anno 	< 	annoCapImp_int
       and movimento.bil_id					=	bilancio_id
       and tipo_mov.movgest_tipo_code    	= 'A' 
       and tipo_stato.movgest_stato_code   in ('D','N')
       and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
       and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
       and d_mod_stato.mod_stato_code='V'    
       and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
       and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
       and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
       and capitolo.data_cancellazione     	is null 
       and r_mov_capitolo.data_cancellazione is null 
       and t_capitolo.data_cancellazione    	is null 
       and movimento.data_cancellazione     	is null 
       and tipo_mov.data_cancellazione     	is null 
       and r_movimento_stato.data_cancellazione   is null 
       and ts_movimento.data_cancellazione   is null 
       and tipo_stato.data_cancellazione    	is null 
       and dt_movimento.data_cancellazione   is null 
       and ts_mov_tipo.data_cancellazione    is null 
       and dt_mov_tipo.data_cancellazione    is null
       and t_movgest_ts_det_mod.data_cancellazione    is null
       and r_mod_stato.data_cancellazione    is null
       and t_modifica.data_cancellazione    is null     
     group by capitolo.elem_id	
),
/*
	SIAC-8154 13/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/      
/*
minfondo as ( -- Importo minimo del fondo
SELECT
 rbilelem.elem_id, 
 CASE 
   WHEN tipomedia = 'SEMPLICE' THEN
        round((COALESCE(datifcd.perc_acc_fondi,0)+
        COALESCE(datifcd.perc_acc_fondi_1,0)+
        COALESCE(datifcd.perc_acc_fondi_2,0)+
        COALESCE(datifcd.perc_acc_fondi_3,0)+
        COALESCE(datifcd.perc_acc_fondi_4,0))/5,2)
   ELSE
        round((COALESCE(datifcd.perc_acc_fondi,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_1,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_2,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_3,0)*0.35+
        COALESCE(datifcd.perc_acc_fondi_4,0)*0.35),2)
 END perc_media
 -- ,1 flag_cassa -- SIAC-5854
 , 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
 WHERE rbilelem.acc_fde_id = datifcd.acc_fde_id 
 AND   datifcd.ente_proprietario_id = p_ente_prop_id 
 AND   rbilelem.data_cancellazione is null
), */
minfondo as ( -- Importo minimo del fondo
SELECT
 datifcd.elem_id,   
 case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
    	COALESCE(acc_fde_media_semplice_rapporti, 0)          
    else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
      COALESCE(acc_fde_media_semplice_totali, 0)        
    else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
    	COALESCE(acc_fde_media_ponderata_rapporti, 0)
    else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
    	COALESCE(acc_fde_media_ponderata_totali,0)     
    else case when tipo_media.afde_tipo_media_code ='UTENTE' then
    	COALESCE(acc_fde_media_utente, 0)      
    end end end end end perc_media,        
 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, 
    siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
 WHERE tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
   AND datifcd.ente_proprietario_id = p_ente_prop_id 
   and datifcd.afde_bil_id  = afde_bilancioId
   AND datifcd.data_cancellazione is null
   AND tipo_media.data_cancellazione is null
),
accertcassa as ( -- Accertato per cassa -- SIAC-5854
SELECT rbea.elem_id, 0 flag_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.data_cancellazione is null
AND    ta.data_cancellazione is null
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S'
),
acc_succ as ( -- Accertamenti imputati agli esercizi successivi a quello cui il rendiconto si riferisce
select capitolo.elem_id,
       --sum (t_movgest_ts_det_mod.movgest_ts_det_importo) accertamenti_succ
       sum (dt_movimento.movgest_ts_det_importo) accertamenti_succ
from siac_t_bil_elem     capitolo , 
     siac_r_movgest_bil_elem   r_mov_capitolo, 
     siac_d_bil_elem_tipo    t_capitolo, 
     siac_t_movgest     movimento, 
     siac_d_movgest_tipo    tipo_mov, 
     siac_t_movgest_ts    ts_movimento, 
     siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato, 
     siac_t_movgest_ts_det   dt_movimento, 
     siac_d_movgest_ts_tipo   ts_mov_tipo, 
     siac_d_movgest_ts_det_tipo  dt_mov_tipo     
     where capitolo.bil_id      				=	bilancio_id
     and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id     
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and capitolo.ente_proprietario_id   = p_ente_prop_id
     and movimento.bil_id					=	bilancio_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	> 	annoCapImp_int      
     and tipo_mov.movgest_tipo_code    	= 'A'       
     and tipo_stato.movgest_stato_code   in ('D','N')      
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'          
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now()) 
     and capitolo.data_cancellazione     	is null 
     and r_mov_capitolo.data_cancellazione is null 
     and t_capitolo.data_cancellazione    	is null 
     and movimento.data_cancellazione     	is null 
     and tipo_mov.data_cancellazione     	is null 
     and r_movimento_stato.data_cancellazione   is null 
     and ts_movimento.data_cancellazione   is null 
     and tipo_stato.data_cancellazione    	is null 
     and dt_movimento.data_cancellazione   is null 
     and ts_mov_tipo.data_cancellazione    is null 
     and dt_mov_tipo.data_cancellazione    is null     
     group by capitolo.elem_id	
),
cred_stra as ( -- Crediti stralciati
 select    
   capitolo.elem_id,
   abs(sum (t_movgest_ts_det_mod.movgest_ts_det_importo)) crediti_stralciati
    from siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
      siac_t_modifica t_modifica,
      siac_d_modifica_tipo d_modif_tipo,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
	  and movimento.ente_proprietario_id   = p_ente_prop_id 
      and movimento.bil_id					=	bilancio_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno 	        <= 	annoCapImp_int      
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'
      /*and ((d_modif_tipo.mod_tipo_code in ('CROR','ECON') and p_anno <= '2016')
            or
           (d_modif_tipo.mod_tipo_code like 'FCDE%' and p_anno >= '2017')
          ) */
      and d_modif_tipo.mod_tipo_code in ('CROR','ECON')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null      
group by capitolo.elem_id),
--SIAC-8154.
--Le query seguenti so no quelle utilizzate per il calcolo dei residui.
stanz_residuo_capitolo as(
  select bil_elem.elem_id, 
      sum(bil_elem_det.elem_det_importo) importo_residui   
  from siac_t_bil_elem bil_elem,	
       siac_t_acc_fondi_dubbia_esig fcde,
       siac_d_bil_elem_tipo bil_elem_tipo,
       siac_t_bil_elem_det bil_elem_det,
       siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
       siac_t_periodo per
  where bil_elem.elem_id = fcde.elem_id
  and bil_elem.elem_tipo_id = bil_elem_tipo.elem_tipo_id
  and bil_elem.elem_id=bil_elem_det.elem_id
  and bil_elem_det.elem_det_tipo_id=d_bil_elem_det_tipo.elem_det_tipo_id
  and per.periodo_id=bil_elem_det.periodo_id
  and bil_elem.ente_proprietario_id= p_ente_prop_id
  and fcde.afde_bil_id				=  afde_bilancioId
  and bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'    
  and d_bil_elem_det_tipo.elem_det_tipo_code='STR'
  and per.anno			= p_anno
  and bil_elem.data_cancellazione IS NULL
  and fcde.data_cancellazione IS NULL
  and bil_elem_tipo.data_cancellazione IS NULL
  and bil_elem_det.data_cancellazione IS NULL
  and d_bil_elem_det_tipo.data_cancellazione IS NULL  
  and bil_elem_det.validita_inizio < CURRENT_TIMESTAMP
  and (bil_elem_det.validita_fine IS NULL OR
       bil_elem_det.validita_fine > CURRENT_TIMESTAMP)
  group by bil_elem.elem_id),
stanz_residuo_capitolo_mod as (
  select bil_elem.elem_id, 
  sum(bil_elem_det_var.elem_det_importo) importo_residui_mod    
  from siac_t_bil_elem bil_elem,	
       siac_t_acc_fondi_dubbia_esig fcde,
       siac_d_bil_elem_tipo bil_elem_tipo,
       siac_t_bil_elem_det bil_elem_det,
       siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
       siac_t_periodo per,
       siac_t_bil_elem_det_var bil_elem_det_var,
       siac_r_variazione_stato r_var_stato,
       siac_d_variazione_stato d_var_stato
  where bil_elem.elem_id = fcde.elem_id
  and bil_elem.elem_tipo_id = bil_elem_tipo.elem_tipo_id
  and bil_elem.elem_id=bil_elem_det.elem_id
  and bil_elem_det.elem_det_tipo_id=d_bil_elem_det_tipo.elem_det_tipo_id
  and per.periodo_id=bil_elem_det.periodo_id
  and bil_elem_det_var.elem_det_id=bil_elem_det.elem_det_id
  and bil_elem_det_var.variazione_stato_id=r_var_stato.variazione_stato_id
  and r_var_stato.variazione_stato_tipo_id=d_var_stato.variazione_stato_tipo_id
  and bil_elem.ente_proprietario_id= p_ente_prop_id
  and fcde.afde_bil_id				=  afde_bilancioId
  and bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'    
  and d_bil_elem_det_tipo.elem_det_tipo_code='STR'
  and per.anno 						= p_anno
  and d_var_stato.variazione_stato_tipo_code not in ('A','D')
  and bil_elem.data_cancellazione IS NULL
  and fcde.data_cancellazione IS NULL
  and bil_elem_tipo.data_cancellazione IS NULL
  and bil_elem_det.data_cancellazione IS NULL
  and bil_elem_det_var.data_cancellazione IS NULL
  and r_var_stato.data_cancellazione IS NULL
  and d_var_stato.data_cancellazione IS NULL
  and d_bil_elem_det_tipo.data_cancellazione IS NULL  
  and bil_elem_det.validita_inizio < CURRENT_TIMESTAMP
  and (bil_elem_det.validita_fine IS NULL OR
       bil_elem_det.validita_fine > CURRENT_TIMESTAMP)
  group by bil_elem.elem_id)
select 
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.classif_id categoria_id,
coalesce(resatt1.residui_accertamenti,0) residui_attivi,
--SIAC-8154 07/10/2021.
--i residui dell'anno precedente devono essere presi dalla tabella
--dell'fcde.
/*
(coalesce(resatt1.residui_accertamenti,0) -
	coalesce(resrisc1.importo_residui,0) +
	coalesce(resriacc.riaccertamenti_residui,0)) residui_attivi_prec,*/
(+COALESCE(cap.acc_fde_denominatore,0)+
COALESCE(cap.acc_fde_denominatore_1,0)+COALESCE(cap.acc_fde_denominatore_2,0)+
COALESCE(cap.acc_fde_denominatore_3,0)+COALESCE(cap.acc_fde_denominatore_4,0))residui_attivi_prec,           
coalesce(minfondo.perc_media,0) perc_media,
-- minfondo.flag_cassa, -- SIAC-5854
coalesce(minfondo.flag_fondo,0) flag_fondo, -- SIAC-5854
coalesce(accertcassa.flag_cassa,1) flag_cassa, -- SIAC-5854
coalesce(acc_succ.accertamenti_succ,0) accertamenti_succ,
coalesce(cred_stra.crediti_stralciati,0) crediti_stralciati,
coalesce(resrisc2.importo_residui,0) residui_competenza,
coalesce(resatt2.residui_accertamenti,0) accertamenti,
--(coalesce(resatt2.residui_accertamenti,0) -
-- coalesce(resrisc2.importo_residui,0)) importo_finale
coalesce(stanz_residuo_capitolo.importo_residui,0) importo_residui,
COALESCE(stanz_residuo_capitolo_mod.importo_residui_mod,0) importo_residui_mod,
cap.perc_media_applicata
from cap
left join resatt resatt1
	on cap.elem_id=resatt1.elem_id and resatt1.tipo_importo = 'RESATT'
left join resatt resatt2
	on cap.elem_id=resatt2.elem_id and resatt2.tipo_importo = 'ACCERT'
left join resrisc resrisc1
	on cap.elem_id=resrisc1.elem_id and resrisc1.tipo_importo = 'RISRES'
left join resrisc resrisc2
	on cap.elem_id=resrisc2.elem_id and resrisc2.tipo_importo = 'RISCOMP'
left join resriacc
	on cap.elem_id=resriacc.elem_id
left join minfondo
	on cap.elem_id=minfondo.elem_id
left join accertcassa
	on cap.elem_id=accertcassa.elem_id
left join acc_succ
	on cap.elem_id=acc_succ.elem_id
left join cred_stra
	on cap.elem_id=cred_stra.elem_id
left join stanz_residuo_capitolo
	on cap.elem_id=stanz_residuo_capitolo.elem_id
left join stanz_residuo_capitolo_mod
	on cap.elem_id=stanz_residuo_capitolo_mod.elem_id
),
fondo_dubbia_esig as (
select  importi.repimp_desc programma_code,
        coalesce(importi.repimp_importo,0) imp_fondo_dubbia_esig
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
		siac_t_bil 						bilancio,
	 	siac_t_periodo 					anno_eserc,
        siac_t_periodo 					anno_comp
where   bilancio.periodo_id				=	anno_eserc.periodo_id 		
and     importi.bil_id					=	bilancio.bil_id 			
and     r_report_importi.rep_id			=	report.rep_id				
and     r_report_importi.repimp_id		=	importi.repimp_id			
and     importi.periodo_id 				=	anno_comp.periodo_id
   				
and     report.ente_proprietario_id		=	p_ente_prop_id				
and		anno_eserc.anno					=	p_anno 						
and 	report.rep_codice				=	'BILR148'
  --24/05/2021 SIAC-8212.
  --Cambiato il codice che identifica le variabili per aggiungere una nota utile
  --all'utente per la compilazione degli importi.
  --and     importi.repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
and 	importi.repimp_codice like 'Colonna E Allegato c) FCDE Rendiconto%'
and     report.data_cancellazione is null
and     importi.data_cancellazione is null
and     r_report_importi.data_cancellazione is null
and     anno_eserc.data_cancellazione is null
and     anno_comp.data_cancellazione is null
and     importi.repimp_desc <> ''
)
select 
p_anno::varchar bil_anno,
''::varchar titent_tipo_code,
clas.titent_tipo_desc::varchar,
clas.titent_code::varchar,
clas.titent_desc::varchar,
''::varchar tipologia_tipo_code,
clas.tipologia_tipo_desc::varchar,
clas.tipologia_code::varchar,
clas.tipologia_desc::varchar,
''::varchar	categoria_tipo_code,
clas.categoria_tipo_desc::varchar,
clas.categoria_code::varchar,
clas.categoria_desc::varchar,
capall.bil_ele_code::varchar,
capall.bil_ele_desc::varchar,
capall.bil_ele_code2::varchar,
capall.bil_ele_desc2::varchar,
capall.bil_ele_id::integer,
capall.bil_ele_id_padre::integer,
COALESCE(capall.importo_residui::numeric,0) + 
	COALESCE(capall.importo_residui_mod::numeric,0) residui_attivi,
COALESCE(capall.residui_attivi_prec::numeric,0) residui_attivi_prec,
COALESCE(capall.importo_residui::numeric + capall.importo_residui_mod +
 capall.residui_attivi_prec::numeric,0) totale_residui_attivi,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  COALESCE(round((capall.importo_residui::numeric + 
  capall.importo_residui_mod::numeric +
  capall.residui_attivi_prec::numeric) * (1 - perc_media::numeric/100),2),0)
 ELSE
 0
END 
importo_minimo_fondo,
capall.bil_ele_code3::varchar,
--COALESCE(capall.flag_cassa::integer,0) flag_cassa, -- SAIC-5854
COALESCE(capall.flag_cassa::integer,1) flag_cassa, -- SAIC-5854       
COALESCE(capall.accertamenti_succ::numeric,0) accertamenti_succ,
COALESCE(capall.crediti_stralciati::numeric,0) crediti_stralciati,
imp_fondo_dubbia_esig,
var_afde_bil_crediti_stralciati,
var_afde_bil_crediti_stralciati_fcde,
var_afde_bil_accertamenti_anni_successivi,
var_afde_bil_accertamenti_anni_successivi_fcde,
(COALESCE(capall.importo_residui::numeric,0) + 
	COALESCE(capall.importo_residui_mod::numeric,0)) * 
    (100 - capall.perc_media_applicata) / 100
from clas 
	left join capall on clas.categoria_id = capall.categoria_id  
	left join fondo_dubbia_esig on fondo_dubbia_esig.programma_code = clas.tipologia_code   
) as zz;

/*raise notice 'query: %',queryfin;
RETURN QUERY queryfin;*/

    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR182_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dett_rend" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  residui_attivi numeric,
  residui_attivi_prec numeric,
  totale_residui_attivi numeric,
  importo_minimo_fondo numeric,
  bil_ele_code3 varchar,
  flag_cassa integer,
  accertamenti_succ numeric,
  crediti_stralciati numeric,
  fondo_dubbia_esig numeric,
  perc_media numeric,
  perc_complementare numeric
) AS
$body$
DECLARE

classifBilRec record;
bilancio_id integer;
annoCapImp_int integer;
tipomedia varchar;
RTN_MESSAGGIO text;
afde_bilancioId integer;

BEGIN
RTN_MESSAGGIO:='select 1';

annoCapImp_int:= p_anno::integer; 

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

/*
	SIAC-8154 15/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    
select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

if tipomedia is null then
   tipomedia = 'SEMPLICE';
end if;

*/

--SIAC-8154 21/07/2021
--devo leggere afde_bil_id che serve per l'accesso alla tabella 
--siac.siac_t_acc_fondi_dubbia_esig 
select 	fondi_bil.afde_bil_id
	into afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='RENDICONTO' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;
    
return query
select zz.* from (
with clas as (
	select classif_tipo_desc1 titent_tipo_desc, titolo_code titent_code,
    	 titolo_desc titent_desc, titolo_validita_inizio titent_validita_inizio,
         titolo_validita_fine titent_validita_fine, 
         classif_tipo_desc2 tipologia_tipo_desc,
         tipologia_id, strutt.tipologia_code tipologia_code, 
         strutt.tipologia_desc tipologia_desc,
         tipologia_validita_inizio, tipologia_validita_fine,
         classif_tipo_desc3 categoria_tipo_desc,
         categoria_id, strutt.categoria_code categoria_code, 
         strutt.categoria_desc categoria_desc,
         categoria_validita_inizio, categoria_validita_fine,
         ente_proprietario_id
    from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, 
    											   p_anno,'') strutt 
),
capall as (
with
cap as (
select
a.elem_id,
a.elem_code,
a.elem_desc,
a.elem_code2,
a.elem_desc2,
a.elem_id_padre,
a.elem_code3,
d.classif_id
from siac_t_bil_elem a,	
     siac_d_bil_elem_tipo b,
     siac_r_bil_elem_class c,
 	 siac_t_class d,	
     siac_d_class_tipo e,
	 siac_r_bil_elem_categoria f,	
     siac_d_bil_elem_categoria g, 
     siac_r_bil_elem_stato h, 
     siac_d_bil_elem_stato i 
where a.elem_tipo_id		 = b.elem_tipo_id 
    and   c.elem_id              = a.elem_id
    and   d.classif_id           = c.classif_id
    and   e.classif_tipo_id      = d.classif_tipo_id
    and   g.elem_cat_id          = f.elem_cat_id
    and   f.elem_id              = a.elem_id
    and   h.elem_id              = a.elem_id
    and   i.elem_stato_id        = h.elem_stato_id
    and a.ente_proprietario_id = p_ente_prop_id
    and   a.bil_id               = bilancio_id
    and   b.elem_tipo_code 	     = 'CAP-EG'
    and   e.classif_tipo_code	 = 'CATEGORIA'
    and	  g.elem_cat_code	     = 'STD'
    and	  i.elem_stato_code	     = 'VA'
    and   a.data_cancellazione   is null
    and	  b.data_cancellazione   is null
    and	  c.data_cancellazione	 is null
    and	  d.data_cancellazione	 is null
    and	  e.data_cancellazione 	 is null
    and	  f.data_cancellazione 	 is null
    and	  g.data_cancellazione	 is null
    and	  h.data_cancellazione   is null
    and	  i.data_cancellazione   is null
), 
resatt as ( -- Residui Attivi 
select capitolo.elem_id,
       sum (dt_movimento.movgest_ts_det_importo) residui_accertamenti,
       CASE 
         WHEN movimento.movgest_anno < annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'I' THEN
            'RESATT' 
         WHEN movimento.movgest_anno = annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'A' THEN  
            'ACCERT' 
         ELSE
            'ALTRO'
       END tipo_importo         
from siac_t_bil_elem                  capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id 
inner join siac_d_movgest_tipo        tipo_mov on movimento.movgest_tipo_id = tipo_mov.movgest_tipo_id 
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id 
inner join siac_r_movgest_ts_stato    r_movimento_stato on ts_movimento.movgest_ts_id = r_movimento_stato.movgest_ts_id 
inner join siac_d_movgest_stato       tipo_stato on r_movimento_stato.movgest_stato_id = tipo_stato.movgest_stato_id
inner join siac_t_movgest_ts_det      dt_movimento on ts_movimento.movgest_ts_id = dt_movimento.movgest_ts_id 
inner join siac_d_movgest_ts_tipo     ts_mov_tipo on ts_movimento.movgest_ts_tipo_id = ts_mov_tipo.movgest_ts_tipo_id
inner join siac_d_movgest_ts_det_tipo dt_mov_tipo on dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id 
where capitolo.ente_proprietario_id     =   p_ente_prop_id
and   capitolo.bil_id      				=	bilancio_id
and   t_capitolo.elem_tipo_code    		= 	'CAP-EG'
and   movimento.movgest_anno 	        <= 	annoCapImp_int
and   movimento.bil_id					=	bilancio_id
and   tipo_mov.movgest_tipo_code    	=   'A' 
and   tipo_stato.movgest_stato_code     in  ('D','N')
and   ts_mov_tipo.movgest_ts_tipo_code  =   'T'
and   dt_mov_tipo.movgest_ts_det_tipo_code in ('I','A')
and   capitolo.data_cancellazione     	is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione    	is null 
and   movimento.data_cancellazione     	is null 
and   tipo_mov.data_cancellazione     	is null 
and   r_movimento_stato.data_cancellazione is null 
and   ts_movimento.data_cancellazione   is null 
and   tipo_stato.data_cancellazione    	is null 
and   dt_movimento.data_cancellazione   is null 
and   ts_mov_tipo.data_cancellazione    is null 
and   dt_mov_tipo.data_cancellazione    is null
and   now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and   now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
group by tipo_importo, capitolo.elem_id
),
resrisc as ( -- Riscossione residui
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_residui,
            CASE 
             WHEN movimento.movgest_anno < annoCapImp_int THEN
                'RISRES'
             ELSE
                'RISCOMP'
             END tipo_importo                    
from  siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
      siac_t_ordinativo				    ordinativo,
      siac_d_ordinativo_tipo			tipo_ordinativo,
      siac_r_ordinativo_stato			r_stato_ordinativo,
      siac_d_ordinativo_stato			stato_ordinativo,
      siac_t_ordinativo_ts 			    ordinativo_det,
      siac_t_ordinativo_ts_det 		    ordinativo_imp,
      siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
      siac_t_movgest     				movimento,
      siac_t_movgest_ts    			    ts_movimento, 
      siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
where r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
    and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
    and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
    and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
    and	ordinativo.ord_id					=	ordinativo_det.ord_id
    and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
    and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
    and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
    and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
    and	ts_movimento.movgest_id				=	movimento.movgest_id
    and ordinativo_det.ente_proprietario_id	    =	p_ente_prop_id
    and	tipo_ordinativo.ord_tipo_code		= 	'I'	-- Incasso
    ------------------------------------------------------------------------------------------		
    ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
    and	stato_ordinativo.ord_stato_code			<> 'A' -- Annullato
    and	ordinativo.bil_id					=	bilancio_id
    and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	-- Importo attuale
    and	movimento.movgest_anno				<=	annoCapImp_int	
    and movimento.bil_id					=	bilancio_id	
    and	r_capitolo_ordinativo.data_cancellazione	is null
    and	ordinativo.data_cancellazione				is null
    and	tipo_ordinativo.data_cancellazione			is null
    and	r_stato_ordinativo.data_cancellazione		is null
    and	stato_ordinativo.data_cancellazione			is null
    and ordinativo_det.data_cancellazione			is null
    and ordinativo_imp.data_cancellazione			is null
    and ordinativo_imp_tipo.data_cancellazione		is null
    and	movimento.data_cancellazione				is null
    and	ts_movimento.data_cancellazione				is null
    and	r_ordinativo_movgest.data_cancellazione		is null
    and now() between r_capitolo_ordinativo.validita_inizio and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now() between r_stato_ordinativo.validita_inizio and COALESCE(r_stato_ordinativo.validita_fine,now())
    and now() between r_ordinativo_movgest.validita_inizio and COALESCE(r_ordinativo_movgest.validita_fine,now())
group by tipo_importo, r_capitolo_ordinativo.elem_id
),
resriacc as ( -- Riaccertamenti residui
select capitolo.elem_id,
       sum (t_movgest_ts_det_mod.movgest_ts_det_importo) riaccertamenti_residui
from siac_t_bil_elem     capitolo , 
     siac_r_movgest_bil_elem   r_mov_capitolo, 
     siac_d_bil_elem_tipo    t_capitolo, 
     siac_t_movgest     movimento, 
     siac_d_movgest_tipo    tipo_mov, 
     siac_t_movgest_ts    ts_movimento, 
     siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato, 
     siac_t_movgest_ts_det   dt_movimento, 
     siac_d_movgest_ts_tipo   ts_mov_tipo, 
     siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
     siac_t_modifica t_modifica,
     siac_r_modifica_stato r_mod_stato,
     siac_d_modifica_stato d_mod_stato,
     siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
     where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
     and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
     and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
     and r_mod_stato.mod_id=t_modifica.mod_id
	 and capitolo.ente_proprietario_id   = p_ente_prop_id                                   
     and capitolo.bil_id      				=	bilancio_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	< 	annoCapImp_int
     and movimento.bil_id					=	bilancio_id
     and tipo_mov.movgest_tipo_code    	= 'A' 
     and tipo_stato.movgest_stato_code   in ('D','N')
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
     and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
     and d_mod_stato.mod_stato_code='V'
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
     and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
     and capitolo.data_cancellazione     	is null 
     and r_mov_capitolo.data_cancellazione is null 
     and t_capitolo.data_cancellazione    	is null 
     and movimento.data_cancellazione     	is null 
     and tipo_mov.data_cancellazione     	is null 
     and r_movimento_stato.data_cancellazione   is null 
     and ts_movimento.data_cancellazione   is null 
     and tipo_stato.data_cancellazione    	is null 
     and dt_movimento.data_cancellazione   is null 
     and ts_mov_tipo.data_cancellazione    is null 
     and dt_mov_tipo.data_cancellazione    is null
     and t_movgest_ts_det_mod.data_cancellazione    is null
     and r_mod_stato.data_cancellazione    is null
     and t_modifica.data_cancellazione    is null     
   group by capitolo.elem_id	
),
/*
	SIAC-8154 13/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/    
/*
minfondo as ( -- Importo minimo del fondo
SELECT
 rbilelem.elem_id, 
 CASE 
   WHEN tipomedia = 'SEMPLICE' THEN
        round((COALESCE(datifcd.perc_acc_fondi,0)+
        COALESCE(datifcd.perc_acc_fondi_1,0)+
        COALESCE(datifcd.perc_acc_fondi_2,0)+
        COALESCE(datifcd.perc_acc_fondi_3,0)+
        COALESCE(datifcd.perc_acc_fondi_4,0))/5,2)
   ELSE
        round((COALESCE(datifcd.perc_acc_fondi,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_1,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_2,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_3,0)*0.35+
        COALESCE(datifcd.perc_acc_fondi_4,0)*0.35),2)
 END perc_media
 -- ,1 flag_cassa -- SIAC-5854
 , 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
 WHERE rbilelem.acc_fde_id = datifcd.acc_fde_id 
 AND   datifcd.ente_proprietario_id = p_ente_prop_id 
 AND   rbilelem.data_cancellazione is null
), */
minfondo as ( -- Importo minimo del fondo
SELECT
 datifcd.elem_id,   
 case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
    COALESCE(acc_fde_media_semplice_rapporti, 0)          
    else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
      COALESCE(acc_fde_media_semplice_totali, 0)        
    else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
    	COALESCE(acc_fde_media_ponderata_rapporti, 0)
    else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
    	COALESCE(acc_fde_media_ponderata_totali,0)     
    else case when tipo_media.afde_tipo_media_code ='UTENTE' then
    	COALESCE(acc_fde_media_utente, 0)      
    end end end end end perc_media,          
 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, 
    siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
 WHERE tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
   AND datifcd.ente_proprietario_id = p_ente_prop_id 
   and datifcd.afde_bil_id = afde_bilancioId
   AND datifcd.data_cancellazione is null
   AND tipo_media.data_cancellazione is null
),
accertcassa as ( -- Accertato per cassa -- SIAC-5854
SELECT rbea.elem_id, 0 flag_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.data_cancellazione is null
AND    ta.data_cancellazione is null
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S'
),
acc_succ as ( -- Accertamenti imputati agli esercizi successivi a quello cui il rendiconto si riferisce
select capitolo.elem_id,
       --sum (t_movgest_ts_det_mod.movgest_ts_det_importo) accertamenti_succ
       sum (dt_movimento.movgest_ts_det_importo) accertamenti_succ
from siac_t_bil_elem     capitolo , 
     siac_r_movgest_bil_elem   r_mov_capitolo, 
     siac_d_bil_elem_tipo    t_capitolo, 
     siac_t_movgest     movimento, 
     siac_d_movgest_tipo    tipo_mov, 
     siac_t_movgest_ts    ts_movimento, 
     siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato, 
     siac_t_movgest_ts_det   dt_movimento, 
     siac_d_movgest_ts_tipo   ts_mov_tipo, 
     siac_d_movgest_ts_det_tipo  dt_mov_tipo 
     where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and capitolo.ente_proprietario_id   = p_ente_prop_id                              
     and capitolo.bil_id      				=	bilancio_id      
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	> 	annoCapImp_int
     and movimento.bil_id					=	bilancio_id
     and tipo_mov.movgest_tipo_code    	= 'A' 
     and tipo_stato.movgest_stato_code   in ('D','N')
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
     and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale      
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
     and capitolo.data_cancellazione     	is null 
     and r_mov_capitolo.data_cancellazione is null 
     and t_capitolo.data_cancellazione    	is null 
     and movimento.data_cancellazione     	is null 
     and tipo_mov.data_cancellazione     	is null 
     and r_movimento_stato.data_cancellazione   is null 
     and ts_movimento.data_cancellazione   is null 
     and tipo_stato.data_cancellazione    	is null 
     and dt_movimento.data_cancellazione   is null 
     and ts_mov_tipo.data_cancellazione    is null 
     and dt_mov_tipo.data_cancellazione    is null
  group by capitolo.elem_id	               
),
cred_stra as ( -- Crediti stralciati
 select    
   capitolo.elem_id,
   abs(sum (t_movgest_ts_det_mod.movgest_ts_det_importo)) crediti_stralciati
    from siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
      siac_t_modifica t_modifica,
      siac_d_modifica_tipo d_modif_tipo,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id 
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and capitolo.ente_proprietario_id   = p_ente_prop_id  
      and capitolo.bil_id     				=	bilancio_id     
      and movimento.bil_id					=	bilancio_id                                                    
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno 	        <= 	annoCapImp_int
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
      /*and ((d_modif_tipo.mod_tipo_code in ('CROR','ECON') and p_anno <= '2016')
            or
           (d_modif_tipo.mod_tipo_code like 'FCDE%' and p_anno >= '2017')
          ) */
      and d_modif_tipo.mod_tipo_code in ('CROR','ECON')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now()) 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null
group by capitolo.elem_id
)
select 
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.classif_id categoria_id,
coalesce(resatt1.residui_accertamenti,0) residui_attivi,
(coalesce(resatt1.residui_accertamenti,0) -
coalesce(resrisc1.importo_residui,0) +
coalesce(resriacc.riaccertamenti_residui,0)) residui_attivi_prec,
coalesce(minfondo.perc_media,0) perc_media,
-- minfondo.flag_cassa, -- SIAC-5854
coalesce(minfondo.flag_fondo,0) flag_fondo, -- SIAC-5854
coalesce(accertcassa.flag_cassa,1) flag_cassa, -- SIAC-5854
coalesce(acc_succ.accertamenti_succ,0) accertamenti_succ,
coalesce(cred_stra.crediti_stralciati,0) crediti_stralciati,
coalesce(resrisc2.importo_residui,0) residui_competenza,
coalesce(resatt2.residui_accertamenti,0) accertamenti,
(coalesce(resatt2.residui_accertamenti,0) -
 coalesce(resrisc2.importo_residui,0)) importo_finale
from cap
left join resatt resatt1
on cap.elem_id=resatt1.elem_id and resatt1.tipo_importo = 'RESATT'
left join resatt resatt2
on cap.elem_id=resatt2.elem_id and resatt2.tipo_importo = 'ACCERT'
left join resrisc resrisc1
on cap.elem_id=resrisc1.elem_id and resrisc1.tipo_importo = 'RISRES'
left join resrisc resrisc2
on cap.elem_id=resrisc2.elem_id and resrisc2.tipo_importo = 'RISCOMP'
left join resriacc
on cap.elem_id=resriacc.elem_id
left join minfondo
on cap.elem_id=minfondo.elem_id
left join accertcassa
on cap.elem_id=accertcassa.elem_id
left join acc_succ
on cap.elem_id=acc_succ.elem_id
left join cred_stra
on cap.elem_id=cred_stra.elem_id
),
fondo_dubbia_esig as (
select  importi.repimp_desc programma_code,
        coalesce(importi.repimp_importo,0) imp_fondo_dubbia_esig
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
        siac_t_periodo 					anno_comp
where 	r_report_importi.rep_id			=	report.rep_id				
and     r_report_importi.repimp_id		=	importi.repimp_id 	
and     importi.periodo_id 				=	anno_comp.periodo_id			
and     report.ente_proprietario_id		=	p_ente_prop_id				
and		importi.bil_id					=   bilancio_id				
and 	report.rep_codice				=	'BILR148'  			
and     importi.repimp_desc <> ''
--and     importi.repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
and 	importi.repimp_codice like 'Colonna E Allegato c) FCDE Rendiconto%'
and     report.data_cancellazione is null
and     importi.data_cancellazione is null
and     r_report_importi.data_cancellazione is null
and     anno_comp.data_cancellazione is null
)
select 
p_anno::varchar bil_anno,
''::varchar titent_tipo_code,
clas.titent_tipo_desc::varchar,
clas.titent_code::varchar,
clas.titent_desc::varchar,
''::varchar tipologia_tipo_code,
clas.tipologia_tipo_desc::varchar,
clas.tipologia_code::varchar,
clas.tipologia_desc::varchar,
''::varchar	categoria_tipo_code,
clas.categoria_tipo_desc::varchar,
clas.categoria_code::varchar,
clas.categoria_desc::varchar,
capall.bil_ele_code::varchar,
capall.bil_ele_desc::varchar,
capall.bil_ele_code2::varchar,
capall.bil_ele_desc2::varchar,
capall.bil_ele_id::integer,
capall.bil_ele_id_padre::integer,
COALESCE(capall.importo_finale::numeric,0) residui_attivi,
COALESCE(capall.residui_attivi_prec::numeric,0) residui_attivi_prec,
COALESCE(capall.importo_finale::numeric + capall.residui_attivi_prec::numeric,0) totale_residui_attivi,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  COALESCE(round((capall.importo_finale::numeric + capall.residui_attivi_prec::numeric) * (1 - capall.perc_media::numeric/100),2),0)
 ELSE
 0
END 
importo_minimo_fondo,
capall.bil_ele_code3::varchar,
--COALESCE(capall.flag_cassa::integer,0) flag_cassa, -- SAIC-5854
COALESCE(capall.flag_cassa::integer,1) flag_cassa, -- SAIC-5854       
COALESCE(capall.accertamenti_succ::numeric,0) accertamenti_succ,
COALESCE(capall.crediti_stralciati::numeric,0) crediti_stralciati,
imp_fondo_dubbia_esig,
COALESCE(capall.perc_media::numeric,0) perc_media,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  (100 - COALESCE(capall.perc_media,0))::numeric
 ELSE
 0
END 
perc_complementare
from clas 
left join capall on clas.categoria_id = capall.categoria_id  
left join fondo_dubbia_esig on fondo_dubbia_esig.programma_code = clas.tipologia_code   
) as zz;

/*raise notice 'query: %',queryfin;
RETURN QUERY queryfin;*/

    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR183_FCDE_assestamento" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titolo_id integer,
  code_titolo varchar,
  desc_titolo varchar,
  tipologia_id integer,
  code_tipologia varchar,
  desc_tipologia varchar,
  categoria_id integer,
  code_categoria varchar,
  desc_categoria varchar,
  elem_id integer,
  capitolo_prev varchar,
  elem_desc varchar,
  flag_acc_cassa varchar,
  pdce_code varchar,
  perc_delta numeric,
  imp_stanziamento_comp numeric,
  imp_accertamento_comp numeric,
  imp_reversale_comp numeric,
  percaccantonamento numeric
) AS
$body$
DECLARE

bilancio_id integer;
anno_int integer;
flagAccantGrad varchar;
RTN_MESSAGGIO text;
afde_bilancioId integer;

BEGIN
RTN_MESSAGGIO:='select 1';

anno_int:= p_anno::integer;

select a.bil_id
into  bilancio_id
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

/*
	SIAC-8154 20/07/2021
    Gli attributi sono sulla tabella siac_t_acc_fondi_dubbia_esig_bil
select attr_bilancio."boolean"
into flagAccantGrad
from siac_r_bil_attr attr_bilancio, siac_t_attr attr
where attr_bilancio.bil_id = bilancio_id
and   attr_bilancio.attr_id = attr.attr_id
and   attr.attr_code = 'accantonamentoGraduale'
and   attr_bilancio.data_cancellazione is null
and   attr_bilancio.ente_proprietario_id = p_ente_prop_id;

if flagAccantGrad = 'N' then
    percAccantonamento = 100;
else
    select COALESCE(attr_bilancio.numerico, 0)
    into percAccantonamento
    from siac_r_bil_attr attr_bilancio, siac_t_attr attr
    where attr_bilancio.bil_id = bilancio_id
    and attr_bilancio.attr_id = attr.attr_id
    and attr.attr_code = 'percentualeAccantonamentoAnno'
    and attr_bilancio.data_cancellazione is null
    and attr_bilancio.ente_proprietario_id = p_ente_prop_id;
end if;
*/

percAccantonamento:=0;
select COALESCE(fondi_bil.afde_bil_accantonamento_graduale,0),
	fondi_bil.afde_bil_id
	into percAccantonamento, afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='PREVISIONE' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;
    
raise notice 'percAccantonamento = %', percAccantonamento;

return query
select zz.* from (
with strut_bilancio as(
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, null)),
capitoli as(
  select cl.classif_id categoria_id,
  anno_eserc.anno anno_bilancio,
  e.elem_id,
  e.elem_code||'/'||e.elem_code2||'/'||e.elem_code3 capitolo_prev,
  e.elem_desc
    --SIAC-8154 20/07/2021
    -- il capitolo e' su siac_t_acc_fondi_dubbia_esig
  --r_bil_elem_dubbia_esig.acc_fde_id
  from  siac_r_bil_elem_class rc,
        siac_t_bil_elem e,
        siac_d_class_tipo ct,
        siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento,
        siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
        siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
        	--SIAC-8154 20/07/2021
        	-- il capitolo e' su siac_t_acc_fondi_dubbia_esig
        --siac_r_bil_elem_acc_fondi_dubbia_esig r_bil_elem_dubbia_esig
  where ct.classif_tipo_id				=	cl.classif_tipo_id
  and cl.classif_id					=	rc.classif_id
  and bilancio.periodo_id				=	anno_eserc.periodo_id
  and e.bil_id						=	bilancio.bil_id
  and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id
  and e.elem_id						=	rc.elem_id
  and	e.elem_id						=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
  and	e.elem_id						=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
  --and r_bil_elem_dubbia_esig.elem_id  =   e.elem_id
  and e.ente_proprietario_id			=	p_ente_prop_id
  and e.bil_id                        =   bilancio_id
  and tipo_elemento.elem_tipo_code 	= 	'CAP-EP'
  and	stato_capitolo.elem_stato_code	=	'VA'
  and ct.classif_tipo_code			=	'CATEGORIA'
  and	cat_del_capitolo.elem_cat_code	=	'STD'
  and e.data_cancellazione 				is null
  and	r_capitolo_stato.data_cancellazione	is null
  and	r_cat_capitolo.data_cancellazione	is null
  and	rc.data_cancellazione				is null
  and	ct.data_cancellazione 				is null
  and	cl.data_cancellazione 				is null
  and	bilancio.data_cancellazione 		is null
  and	anno_eserc.data_cancellazione 		is null
  and	tipo_elemento.data_cancellazione	is null
  and	stato_capitolo.data_cancellazione 	is null
  and	cat_del_capitolo.data_cancellazione	is null
  --and r_bil_elem_dubbia_esig.data_cancellazione is null
),
conto_pdce as(
select t_class_upb.classif_code, r_capitolo_upb.elem_id
from
    siac_d_class_tipo	class_upb,
    siac_t_class		t_class_upb,
    siac_r_bil_elem_class r_capitolo_upb
where
    t_class_upb.classif_tipo_id = class_upb.classif_tipo_id
    and t_class_upb.classif_id = r_capitolo_upb.classif_id
    and t_class_upb.ente_proprietario_id = p_ente_prop_id
    and class_upb.classif_tipo_code like 'PDC_%'
    and	class_upb.data_cancellazione 			is null
    and t_class_upb.data_cancellazione 			is null
    and r_capitolo_upb.data_cancellazione 			is null
),
flag_acc_cassa as (
select rbea."boolean", rbea.elem_id
from   siac_r_bil_elem_attr rbea, siac_t_attr ta
where  rbea.attr_id = ta.attr_id
and    rbea.data_cancellazione is null
and    ta.data_cancellazione is null
and    ta.attr_code = 'FlagAccertatoPerCassa'
and    ta.ente_proprietario_id = p_ente_prop_id
),
/*
	SIAC-8154 13/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/  
/*fondo  as (
select fondi_dubbia_esig.acc_fde_id, fondi_dubbia_esig.perc_delta
from   siac_t_acc_fondi_dubbia_esig fondi_dubbia_esig
where  fondi_dubbia_esig.ente_proprietario_id = p_ente_prop_id
and    fondi_dubbia_esig.data_cancellazione is null
),*/
fondo  as (
select fondi_dubbia_esig.elem_id, fondi_dubbia_esig.perc_delta
from   siac_t_acc_fondi_dubbia_esig fondi_dubbia_esig
where  fondi_dubbia_esig.ente_proprietario_id = p_ente_prop_id
and    fondi_dubbia_esig.afde_bil_id  = afde_bilancioId
and    fondi_dubbia_esig.data_cancellazione is null
),
stanziamento_comp as (
select 	capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3 capitolo_rend,
        sum(capitolo_importi.elem_det_importo) imp_stanziamento_comp
from 	siac_t_bil_elem_det capitolo_importi,
        siac_d_bil_elem_det_tipo capitolo_imp_tipo,
        siac_t_periodo capitolo_imp_periodo,
        siac_t_bil_elem capitolo,
        siac_d_bil_elem_tipo tipo_elemento,
        siac_t_bil bilancio,
        siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
        siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where 	bilancio.periodo_id				=	capitolo_imp_periodo.periodo_id
and	capitolo.bil_id						=	bilancio_id
and	capitolo.elem_id					=	capitolo_importi.elem_id
and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id
and	capitolo.elem_id					=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
and	capitolo.elem_id					=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
and capitolo_importi.ente_proprietario_id = p_ente_prop_id
and	tipo_elemento.elem_tipo_code 		= 	'CAP-EG'
and	stato_capitolo.elem_stato_code		=	'VA'
and	capitolo_imp_periodo.anno           = 	p_anno
and	cat_del_capitolo.elem_cat_code		=	'STD'
and capitolo_imp_tipo.elem_det_tipo_code  = 'STA'
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	bilancio.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3
),
accertamento_comp as (
select capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3 capitolo_rend,
       sum (dt_movimento.movgest_ts_det_importo) imp_accertamento_comp
from   siac_t_bil_elem     capitolo ,
       siac_r_movgest_bil_elem   r_mov_capitolo,
       siac_d_bil_elem_tipo    t_capitolo,
       siac_t_movgest     movimento,
       siac_d_movgest_tipo    tipo_mov,
       siac_t_movgest_ts    ts_movimento,
       siac_r_movgest_ts_stato   r_movimento_stato,
       siac_d_movgest_stato    tipo_stato,
       siac_t_movgest_ts_det   dt_movimento,
       siac_d_movgest_ts_tipo   ts_mov_tipo,
       siac_d_movgest_ts_det_tipo  dt_mov_tipo
where capitolo.elem_tipo_id      		= t_capitolo.elem_tipo_id
and r_mov_capitolo.elem_id    		    = capitolo.elem_id
and r_mov_capitolo.movgest_id    		= movimento.movgest_id
and movimento.movgest_tipo_id    		= tipo_mov.movgest_tipo_id
and movimento.movgest_id      		    = ts_movimento.movgest_id
and ts_movimento.movgest_ts_id    	    = r_movimento_stato.movgest_ts_id
and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id
and ts_movimento.movgest_ts_tipo_id     = ts_mov_tipo.movgest_ts_tipo_id
and ts_movimento.movgest_ts_id    	    = dt_movimento.movgest_ts_id
and dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id
and movimento.ente_proprietario_id      = p_ente_prop_id
and t_capitolo.elem_tipo_code    		= 'CAP-EG'
and movimento.movgest_anno              = anno_int
and movimento.bil_id                    = bilancio_id
and capitolo.bil_id     				= bilancio_id
and tipo_mov.movgest_tipo_code    	    = 'A'
and tipo_stato.movgest_stato_code       in ('D','N')
and ts_mov_tipo.movgest_ts_tipo_code    = 'T'
and dt_mov_tipo.movgest_ts_det_tipo_code = 'A'
and now()
  between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and now()
  between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
and capitolo.data_cancellazione     	is null
and r_mov_capitolo.data_cancellazione is null
and t_capitolo.data_cancellazione    	is null
and movimento.data_cancellazione     	is null
and tipo_mov.data_cancellazione     	is null
and r_movimento_stato.data_cancellazione   is null
and ts_movimento.data_cancellazione   is null
and tipo_stato.data_cancellazione    	is null
and dt_movimento.data_cancellazione   is null
and ts_mov_tipo.data_cancellazione    is null
and dt_mov_tipo.data_cancellazione    is null
group by capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3
),
reversale_comp as (
select capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3 capitolo_rend,
       sum (t_ord_ts_det.ord_ts_det_importo) imp_reversale_comp
from   siac_t_bil_elem     capitolo ,
       siac_r_ordinativo_bil_elem   r_ord_capitolo,
       siac_d_bil_elem_tipo    t_capitolo,
       siac_t_ordinativo t_ordinativo,
       siac_t_ordinativo_ts t_ord_ts,
       siac_t_ordinativo_ts_det t_ord_ts_det,
       siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
       siac_r_ordinativo_stato r_ord_stato,
       siac_d_ordinativo_stato d_ord_stato,
       siac_d_ordinativo_tipo d_ord_tipo,
-- ST SIAC-6291 inserita condizione per movimento di competenza: tavole
       siac_r_ordinativo_ts_movgest_ts    r_ord_mov,
       siac_t_movgest     movimento,
       siac_t_movgest_ts    ts_movimento
where capitolo.elem_tipo_id      		 = t_capitolo.elem_tipo_id
and   r_ord_capitolo.elem_id    		 = capitolo.elem_id
and   t_ordinativo.ord_id                = r_ord_capitolo.ord_id
and   t_ordinativo.ord_id                = t_ord_ts.ord_id
and   t_ord_ts.ord_ts_id                 = t_ord_ts_det.ord_ts_id
and   t_ordinativo.ord_id                = r_ord_stato.ord_id
and   r_ord_stato.ord_stato_id           = d_ord_stato.ord_stato_id
and   d_ord_tipo.ord_tipo_id             = t_ordinativo.ord_tipo_id
AND   d_ts_det_tipo.ord_ts_det_tipo_id   = t_ord_ts_det.ord_ts_det_tipo_id
and   t_ordinativo.ente_proprietario_id  = p_ente_prop_id
--ST SIAC-6291 condizione per movimento di competenza: Join
and   movimento.movgest_id      		 = ts_movimento.movgest_id
and   r_ord_mov.movgest_ts_id      		 = ts_movimento.movgest_ts_id
and   r_ord_mov.ord_ts_id                = t_ord_ts.ord_ts_id
--
and   t_capitolo.elem_tipo_code    		 =  'CAP-EG'
and   t_ordinativo.ord_anno              = anno_int
and   capitolo.bil_id                    = bilancio_id
and   t_ordinativo.bil_id                = bilancio_id
and   d_ord_stato.ord_stato_code         <>'A'
and   d_ord_tipo.ord_tipo_code           = 'I'
and   d_ts_det_tipo.ord_ts_det_tipo_code = 'A'
and   capitolo.data_cancellazione     	is null
and   r_ord_capitolo.data_cancellazione     	is null
and   t_capitolo.data_cancellazione     	is null
and   t_ordinativo.data_cancellazione     	is null
and   t_ord_ts.data_cancellazione     	is null
and   t_ord_ts_det.data_cancellazione     	is null
and   d_ts_det_tipo.data_cancellazione     	is null
and   r_ord_stato.data_cancellazione     	is null
and   r_ord_stato.validita_fine is null -- S.T. SIACC-6280
and   d_ord_stato.data_cancellazione     	is null
and   d_ord_tipo.data_cancellazione     	is null
-- ST SIAC-6291 condizione per movimento di competenza
and   r_ord_mov.data_cancellazione      is null
and movimento.movgest_anno              = anno_int
--
group by capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3
)
select
p_anno,
strut_bilancio.titolo_id::integer titolo_id,
strut_bilancio.titolo_code::varchar code_titolo,
strut_bilancio.titolo_desc::varchar desc_titolo,
strut_bilancio.tipologia_id::integer tipologia_id,
strut_bilancio.tipologia_code::varchar code_tipologia,
strut_bilancio.tipologia_desc::varchar desc_tipologia,
strut_bilancio.categoria_id::integer categoria_id,
strut_bilancio.categoria_code::varchar code_categoria,
strut_bilancio.categoria_desc::varchar desc_categoria,
capitoli.elem_id::integer elem_id,
capitoli.capitolo_prev::varchar capitolo_prev,
capitoli.elem_desc::varchar elem_desc,
COALESCE(flag_acc_cassa."boolean", 'N')::varchar flag_acc_cassa,
conto_pdce.classif_code::varchar pdce_code,
COALESCE(fondo.perc_delta,0)::numeric perc_delta,
COALESCE(stanziamento_comp.imp_stanziamento_comp,0)::numeric imp_stanziamento_comp,
COALESCE(accertamento_comp.imp_accertamento_comp,0)::numeric imp_accertamento_comp,
COALESCE(reversale_comp.imp_reversale_comp,0)::numeric imp_reversale_comp,
percAccantonamento::numeric
from strut_bilancio
inner join capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
inner join conto_pdce on conto_pdce.elem_id = capitoli.elem_id
--left join  fondo on fondo.acc_fde_id = capitoli.acc_fde_id
left join  fondo on fondo.elem_id = capitoli.elem_id
left join  flag_acc_cassa on flag_acc_cassa.elem_id = capitoli.elem_id
left join  stanziamento_comp on stanziamento_comp.capitolo_rend = capitoli.capitolo_prev
left join  accertamento_comp on accertamento_comp.capitolo_rend = capitoli.capitolo_prev
left join  reversale_comp on reversale_comp.capitolo_rend = capitoli.capitolo_prev
) as zz;

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR170_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dettaglio" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  importo_collb numeric,
  importo_collc numeric,
  flag_acc_cassa boolean,
  perc_delta numeric,
  perc_media numeric,
  percaccantonamento numeric
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
flagAccantGrad varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strpercAccantonamento varchar;
--percAccantonamento numeric;
tipomedia varchar;
perc1 numeric;
perc2 numeric;
perc3 numeric;
perc4 numeric;
perc5 numeric;
fde_media_utente  numeric;
fde_media_semplice_totali numeric;
fde_media_semplice_rapporti  numeric;
fde_media_ponderata_totali  numeric;
fde_media_ponderata_rapporti  numeric;
afde_bilancioId integer;

h_count integer :=0;



BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

flag_acc_cassa:= true;


/*
	SIAC-8154 20/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    Gli attributi sono sulla tabella siac_t_acc_fondi_dubbia_esig_bil.
    
-- percentuale accantonamento bilancio
if p_anno_competenza = annoCapImp then
   	strpercAccantonamento = 'percentualeAccantonamentoAnno';
elseif  p_anno_competenza = annoCapImp1 then
	strpercAccantonamento = 'percentualeAccantonamentoAnno1';
else 
	strpercAccantonamento = 'percentualeAccantonamentoAnno2';
end if;




select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

select attr_bilancio."boolean"
into flagAccantGrad  from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'accantonamentoGraduale' and 
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;


if flagAccantGrad = 'N' then
   percAccantonamento = 100;
else  
    select COALESCE(attr_bilancio.numerico, 0)
    into percAccantonamento from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
    siac_r_bil_attr attr_bilancio, siac_t_attr attr
    where 
    bilancio.periodo_id = anno_eserc.periodo_id and
    anno_eserc.anno = 	p_anno and
    bilancio.bil_id =  attr_bilancio.bil_id and
    attr_bilancio.attr_id= attr.attr_id and
    attr.attr_code = strpercAccantonamento and 
    attr_bilancio.data_cancellazione is null and
    attr_bilancio.ente_proprietario_id=p_ente_prop_id;
end if;

if tipomedia is null then
	tipomedia = 'SEMPLICE';
end if;

*/

percAccantonamento:=0;
select COALESCE(fondi_bil.afde_bil_accantonamento_graduale,0),
	fondi_bil.afde_bil_id
	into percAccantonamento, afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='PREVISIONE' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;
    
raise notice 'percAccantonamento = % - afde_bil_id = %', 
	percAccantonamento, afde_bilancioId;

TipoImpComp='STA';  -- competenza 
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';

select fnc_siac_random_user()
into	user_table;

insert into siac_rep_tit_tip_cat_riga_anni
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, 
	user_table);

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and e.elem_id						=	rc.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and pdc_tipo.classif_tipo_code like 'PDC_%'
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null;

insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
             siac_d_bil_elem_tipo tipo_elemento,
             siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 						
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id		
        and capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	and	anno_eserc.anno							= 	p_anno 
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_imp_periodo.anno in (p_anno_competenza)
        and	stato_capitolo.elem_stato_code		=	'VA'
		--and	cat_del_capitolo.elem_cat_code		=	'STD' 
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null      
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente
    order by capitolo_imp_tipo.elem_det_tipo_code, 
    	capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;

for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop


titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
codice_pdc:=classifBilRec.codice_pdc;

-- SIAC-5854 INIZIO
SELECT true
INTO   flag_acc_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.elem_id = classifBilRec.bil_ele_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S';

IF flag_acc_cassa IS NULL THEN
   flag_acc_cassa := false;
END IF;
-- SIAC-5854 FINE

/*
	SIAC-8154 21/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/ 
/*
select COALESCE(datifcd.perc_acc_fondi,0), 
COALESCE(datifcd.perc_acc_fondi_1,0), COALESCE(datifcd.perc_acc_fondi_2,0),
COALESCE(datifcd.perc_acc_fondi_3,0), COALESCE(datifcd.perc_acc_fondi_4,0), 
COALESCE(datifcd.perc_delta,0), 
-- false -- SIAC-5854
1
into perc1, perc2, perc3, perc4, perc5, perc_delta
-- , flag_acc_cassa -- SIAC-5854
, h_count
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
where
  rbilelem.elem_id=classifBilRec.bil_ele_id and  
  rbilelem.acc_fde_id = datifcd.acc_fde_id and
  rbilelem.data_cancellazione is null;

if tipomedia = 'SEMPLICE' then
    perc_media = round((perc1+perc2+perc3+perc4+perc5)/5,2);
else 
    perc_media = round((perc1*0.10+perc2*0.10+perc3*0.10+perc4*0.35+perc5*0.35),2);
end if;

if perc_media is null then
   perc_media := 0;
end if;

if perc_delta is null then
   perc_delta := 0;
end if;
*/

raise notice 'bil_ele_id = %', classifBilRec.bil_ele_id;

fde_media_utente:=0;
fde_media_semplice_totali:=0; 
fde_media_semplice_rapporti:=0;
fde_media_ponderata_totali:=0; 
fde_media_ponderata_rapporti:=0;
perc_delta:=0;
perc_media:=0;
tipomedia:='';

if classifBilRec.bil_ele_id IS NOT NULL then
  select  datifcd.perc_delta, 1, tipo_media.afde_tipo_media_code,
  COALESCE(datifcd.acc_fde_media_utente,0), 
  COALESCE(datifcd.acc_fde_media_semplice_totali,0),
  COALESCE(datifcd.acc_fde_media_semplice_rapporti,0), 
  COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
  COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0)
  into perc_delta, h_count, tipomedia,
  fde_media_utente, fde_media_semplice_totali, fde_media_semplice_rapporti,
  fde_media_ponderata_totali, fde_media_ponderata_rapporti
   FROM siac_t_acc_fondi_dubbia_esig datifcd, 
      siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
  where tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
    and datifcd.elem_id=classifBilRec.bil_ele_id 
    and datifcd.afde_bil_id  = afde_bilancioId
    and datifcd.data_cancellazione is null
    and tipo_media.data_cancellazione is null;
end if;

if tipomedia = 'SEMP_RAP' then
    perc_media = fde_media_semplice_rapporti;         
elsif tipomedia = 'SEMP_TOT' then
    perc_media = fde_media_semplice_totali;        
elsif tipomedia = 'POND_RAP' then
      perc_media = fde_media_ponderata_rapporti;  
elsif tipomedia = 'POND_TOT' then
      perc_media = fde_media_ponderata_totali;    
elsif tipomedia = 'UTENTE' then  --Media utente
      perc_media = fde_media_utente;   
end if;

raise notice 'tipomedia % - media: % - delta: %', tipomedia , perc_media, perc_delta ;

--- colonna b del report = stanziamento capitolo * percentualeAccantonamentoAnno(1,2) * perc_media
--- colonna c del report = stanziamento capitolo * perc_delta della tabella 

---if p_anno_competenza = annoCapImp then
   	importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
    importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_delta/100) * percAccantonamento/100,2);
--elseif  p_anno_competenza = annoCapImp1 then
--	importo_collb:= round(classifBilRec.stanziamento_prev_anno1 * (perc_media/100) * percAccantonamento/100,2);
--    importo_collc:= round(classifBilRec.stanziamento_prev_anno1 * perc_delta/100,2);
--else 
--	importo_collb:= round(classifBilRec.stanziamento_prev_anno2 * (perc_media/100) * percAccantonamento/100,2);
--    importo_collc:= round(classifBilRec.stanziamento_prev_anno2 * perc_delta/100,2);
--end if;

raise notice 'bil_ele_id % - importo_collb %', classifBilRec.bil_ele_id , importo_collb;

raise notice 'bil_ele_id % - percAccantonamento %', classifBilRec.bil_ele_id , percAccantonamento ;

if h_count is null or flag_acc_cassa = true then  -- SIAC-5854
  importo_collb:=0;
  importo_collc:=0;
  -- flag_acc_cassa:=true; -- SIAC-5854
END if;

-- importi capitolo

/*raise notice 'record';*/
return next;
bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc:=0;
importo_collb:=0;
importo_collc:=0;
flag_acc_cassa:=true;
perc_delta:=0;
perc_media:=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  importo_collb numeric,
  importo_collc numeric,
  flag_acc_cassa boolean
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
flagAccantGrad varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strpercAccantonamento varchar;
percAccantonamento numeric;
tipomedia varchar;
perc1 numeric;
perc2 numeric;
perc3 numeric;
perc4 numeric;
perc5 numeric;
fde_media_utente  numeric;
fde_media_semplice_totali numeric;
fde_media_semplice_rapporti  numeric;
fde_media_ponderata_totali  numeric;
fde_media_ponderata_rapporti  numeric;

perc_delta numeric;
perc_media numeric;
afde_bilancioId integer;
perc_massima numeric;

h_count integer :=0;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

flag_acc_cassa:= true;

/*
	SIAC-8154 20/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    Gli attributi sono sulla tabella siac_t_acc_fondi_dubbia_esig_bil.

-- percentuale accantonamento bilancio
if p_anno_competenza = annoCapImp then
   	strpercAccantonamento = 'percentualeAccantonamentoAnno';
elseif  p_anno_competenza = annoCapImp1 then
	strpercAccantonamento = 'percentualeAccantonamentoAnno1';
else 
	strpercAccantonamento = 'percentualeAccantonamentoAnno2';
end if;



select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

select attr_bilancio."boolean"
into flagAccantGrad  from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'accantonamentoGraduale' and 
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;


if flagAccantGrad = 'N' then
   percAccantonamento = 100;
else  
    select COALESCE(attr_bilancio.numerico, 0)
    into percAccantonamento from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
    siac_r_bil_attr attr_bilancio, siac_t_attr attr
    where 
    bilancio.periodo_id = anno_eserc.periodo_id and
    anno_eserc.anno = 	p_anno and
    bilancio.bil_id =  attr_bilancio.bil_id and
    attr_bilancio.attr_id= attr.attr_id and
    attr.attr_code = strpercAccantonamento and 
    attr_bilancio.data_cancellazione is null and
    attr_bilancio.ente_proprietario_id=p_ente_prop_id;
end if;

if tipomedia is null then
	tipomedia = 'SEMPLICE';
end if;
*/

percAccantonamento:=0;
select COALESCE(fondi_bil.afde_bil_accantonamento_graduale,0),
	fondi_bil.afde_bil_id
	into percAccantonamento, afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='PREVISIONE' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';

select fnc_siac_random_user()
into	user_table;


insert into siac_rep_tit_tip_cat_riga_anni
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, 
	user_table);
 

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.elem_id						=	rc.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and ct.classif_tipo_code			=	'CATEGORIA' 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and pdc_tipo.classif_tipo_code like 'PDC_%'
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null;

insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
             siac_d_bil_elem_tipo tipo_elemento,
             siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo,
            siac_t_acc_fondi_dubbia_esig fcde
    where 	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and   fcde.elem_id						= capitolo.elem_id
        and capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	and	anno_eserc.anno							= 	p_anno				
        and   fcde.afde_bil_id				=  afde_bilancioId
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_imp_periodo.anno in (p_anno_competenza)
        and	stato_capitolo.elem_stato_code		=	'VA'
		--and	cat_del_capitolo.elem_cat_code		=	'STD' 
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null 
        and fcde.data_cancellazione IS NULL     
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;
               
for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop


titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
codice_pdc:=classifBilRec.codice_pdc;


-- SIAC-5854 INIZIO
SELECT true
INTO   flag_acc_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.elem_id = classifBilRec.bil_ele_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S';

IF flag_acc_cassa IS NULL THEN
   flag_acc_cassa := false;
END IF;
-- SIAC-5854 FINE

/*
	SIAC-8154 21/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/ 
/*
select COALESCE(datifcd.perc_acc_fondi,0), 
COALESCE(datifcd.perc_acc_fondi_1,0), COALESCE(datifcd.perc_acc_fondi_2,0),
COALESCE(datifcd.perc_acc_fondi_3,0), COALESCE(datifcd.perc_acc_fondi_4,0), 
COALESCE(datifcd.perc_delta,0), 
-- false -- SIAC-5854
1
into perc1, perc2, perc3, perc4, perc5, perc_delta
-- , flag_acc_cassa -- SIAC-5854
, h_count
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
where
  rbilelem.elem_id=classifBilRec.bil_ele_id and  
  rbilelem.acc_fde_id = datifcd.acc_fde_id and
  rbilelem.data_cancellazione is null;

if tipomedia = 'SEMPLICE' then
    perc_media = round((perc1+perc2+perc3+perc4+perc5)/5,2);
else 
    perc_media = round((perc1*0.10+perc2*0.10+perc3*0.10+perc4*0.35+perc5*0.35),2);
end if;

if perc_media is null then
   perc_media := 0;
end if;

if perc_delta is null then
   perc_delta := 0;
end if;
*/

raise notice 'bil_ele_id = %', classifBilRec.bil_ele_id;

fde_media_utente:=0;
fde_media_semplice_totali:=0; 
fde_media_semplice_rapporti:=0;
fde_media_ponderata_totali:=0; 
fde_media_ponderata_rapporti:=0;
perc_delta:=0;
perc_media:=0;
tipomedia:='';

if classifBilRec.bil_ele_id IS NOT NULL then
  select  datifcd.perc_delta, 1, tipo_media.afde_tipo_media_code,
  COALESCE(datifcd.acc_fde_media_utente,0), 
  COALESCE(datifcd.acc_fde_media_semplice_totali,0),
  COALESCE(datifcd.acc_fde_media_semplice_rapporti,0), 
  COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
  COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0),
  greatest (COALESCE(datifcd.acc_fde_media_semplice_totali,0),
  	 COALESCE(datifcd.acc_fde_media_semplice_rapporti,0),
  	COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
    COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0))
  into perc_delta, h_count, tipomedia,
  fde_media_utente, fde_media_semplice_totali, fde_media_semplice_rapporti,
  fde_media_ponderata_totali, fde_media_ponderata_rapporti, perc_massima
   FROM siac_t_acc_fondi_dubbia_esig datifcd, 
      siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
  where tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
    and datifcd.elem_id=classifBilRec.bil_ele_id 
    and datifcd.afde_bil_id  = afde_bilancioId
    and datifcd.data_cancellazione is null
    and tipo_media.data_cancellazione is null;
end if;

if tipomedia = 'SEMP_RAP' then
    perc_media = fde_media_semplice_rapporti;         
elsif tipomedia = 'SEMP_TOT' then
    perc_media = fde_media_semplice_totali;        
elsif tipomedia = 'POND_RAP' then
      perc_media = fde_media_ponderata_rapporti;  
elsif tipomedia = 'POND_TOT' then
      perc_media = fde_media_ponderata_totali;    
elsif tipomedia = 'UTENTE' then  --Media utente
      perc_media = fde_media_utente;   
end if;

raise notice 'tipomedia % - media: % - delta: % - massima %', tipomedia , perc_media, perc_delta, perc_massima ;

--- colonna b del report = stanziamento capitolo * percentualeAccantonamentoAnno(1,2) * perc_media
--- colonna c del report = stanziamento capitolo * perc_delta della tabella 

--SIAC-8154 14/10/2021
--la colonna C diventa quello che prima era la colonna B
--la colonna B invece della percentuale media deve usa la percentuale 
--che ha il valore massimo (esclusa quella utente).
--importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
--importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_delta/100) * percAccantonamento/100,2);   
importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_massima/100) * percAccantonamento/100,2);
importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);

raise notice 'importo_collb % - %', classifBilRec.bil_ele_id , importo_collb;

raise notice 'percAccantonamento % - %', classifBilRec.bil_ele_id , percAccantonamento ;

if h_count is null or flag_acc_cassa = true then
  importo_collb:=0;
  importo_collc:=0;
  -- flag_acc_cassa:=true; -- SIAC-5854
END if;

-- importi capitolo

return next;

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc:=0;
importo_collb:=0;
importo_collc:=0;
flag_acc_cassa:=true;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_EELL" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
h_count integer :=0;
v_fam_titolotipologiacategoria varchar:='00003';


BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';

select fnc_siac_random_user()
into	user_table;



insert into siac_rep_tit_tip_cat_riga_anni
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, 
	user_table);

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_id			=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and e.elem_id						=	rc.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and ct.classif_tipo_code			=	'CATEGORIA'
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and pdc_tipo.classif_tipo_code like 'PDC_%'
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null;

insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
             siac_d_bil_elem_tipo tipo_elemento,
             siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id		
        and capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	and	anno_eserc.anno							= 	p_anno 												    							
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_imp_periodo.anno 				in (p_anno_competenza)
        and	stato_capitolo.elem_stato_code		=	'VA'
		and	cat_del_capitolo.elem_cat_code		=	'STD' 
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null      
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;
               


for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop

titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
codice_pdc:=classifBilRec.codice_pdc;


-- importi capitolo

/*raise notice 'record';*/
return next;
bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc:=0;


end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


update siac_t_xbrl_mapping_fatti
set xbrl_mapfat_variabile='totale_crediti_bil',
	data_modifica=now(),
    login_operazione= login_operazione|| ' - SIAC-8154'
where xbrl_mapfat_rep_codice='BILR148'
and xbrl_mapfat_variabile='crediti_stralciati_tot_crediti';

update siac_t_xbrl_mapping_fatti
set xbrl_mapfat_variabile='fondo_sval_crediti_bil',
	data_modifica=now(),
    login_operazione= login_operazione|| ' - SIAC-8154'
where xbrl_mapfat_rep_codice='BILR148'
and xbrl_mapfat_variabile='Copia_crediti_stralciati_tot_crediti';

update siac_t_xbrl_mapping_fatti
set xbrl_mapfat_variabile='totale_crediti_accert',
	data_modifica=now(),
    login_operazione= login_operazione|| ' - SIAC-8154'
where xbrl_mapfat_rep_codice='BILR148'
and xbrl_mapfat_variabile='accertamenti_successivi';


--SIAC-8154 - Maurizio - FINE


-- FNC CALCOLO CREDITI STRALCIATI
CREATE OR REPLACE FUNCTION siac.fnc_calcola_crediti_stralciati (
  p_ente_prop_id integer,
  p_anno varchar,
  p_afde_bilancio_id integer
)
RETURNS TABLE (
  afde_bil_crediti_stralciati numeric,
  afde_bil_crediti_stralciati_fcde numeric,
  afde_bil_accertamenti_anni_successivi numeric,
  afde_bil_accertamenti_anni_successivi_fcde numeric
) AS
$body$
DECLARE

bilancio_id integer;
RTN_MESSAGGIO text;

BEGIN

/* SIAC-8384 15/10/2021.
	Funzione creata per resitutire i valori dei crediti stralciati secondo le
    nuove regole comunicate.
    E' richiamata direttamente da Contabilia per presentare i campi nella
    maschera di FCDE.
*/

afde_bil_crediti_stralciati:=0;
afde_bil_crediti_stralciati_fcde:=0;
afde_bil_accertamenti_anni_successivi:=0;
afde_bil_accertamenti_anni_successivi_fcde:=0;


select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id  
  and b.periodo_id=a.periodo_id
  and b.anno=p_anno;


--Somma delle modifiche di accertamento (INEROR - ROR - Cancellazione per Inesigibilita' - entrate) 
-- + (INESIG - Cancellazione per Inesigibilita') con anno <=n
--Quindi rendiconto 2021 : modifiche accertamenti <=2021 - senza perimetro capitoli di pertinenza, 
--Titolo 1, 2, 3, 4 e 5.      
with struttura as (select *
 from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
capitoli as (      
    select class.classif_id categoria_id,
       t_movgest_ts_det_mod.movgest_ts_det_importo
      from siac_t_bil_elem     capitolo , 
        siac_r_movgest_bil_elem   r_mov_capitolo, 
        siac_d_bil_elem_tipo    t_capitolo, 
        siac_t_movgest     movimento, 
        siac_d_movgest_tipo    tipo_mov, 
        siac_t_movgest_ts    ts_movimento, 
        siac_r_movgest_ts_stato   r_movimento_stato, 
        siac_d_movgest_stato    tipo_stato, 
        siac_t_movgest_ts_det   dt_movimento, 
        siac_d_movgest_ts_tipo   ts_mov_tipo, 
        siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
        siac_t_modifica t_modifica,
        siac_d_modifica_tipo d_modif_tipo,
        siac_r_modifica_stato r_mod_stato,
        siac_d_modifica_stato d_mod_stato,
        siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
        siac_t_class class,	
        siac_d_class_tipo d_class_tipo,
        siac_r_bil_elem_class r_bil_elem_class
      where r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
      and   class.classif_id           = r_bil_elem_class.classif_id
	  and   d_class_tipo.classif_tipo_id      = class.classif_tipo_id
      and   r_bil_elem_class.elem_id   = capitolo.elem_id
	  and movimento.ente_proprietario_id   = p_ente_prop_id 
      and movimento.bil_id					=	bilancio_id 
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      	--accertamenti con anno <=anno bilancio
      and movimento.movgest_anno 	        <= 	p_anno::integer 
      and tipo_mov.movgest_tipo_code    	= 'A' --accertamenti
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'
      --Prima era:
      --and d_modif_tipo.mod_tipo_code in ('CROR','ECON')
      and d_modif_tipo.mod_tipo_code in ('INEROR','INESIG')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and d_class_tipo.classif_tipo_code	 = 'CATEGORIA'      
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null  
      and class.data_cancellazione    is null  
      and d_class_tipo.data_cancellazione is null  
      and r_bil_elem_class.data_cancellazione is null)   
select  COALESCE(abs(sum(movgest_ts_det_importo)),0) afde_bil_crediti_stralciati,
    	COALESCE(abs(sum(movgest_ts_det_importo)),0) afde_bil_crediti_stralciati_fcde
into afde_bil_crediti_stralciati, afde_bil_crediti_stralciati_fcde
from struttura
	left join capitoli 
    	on struttura.categoria_id=capitoli.categoria_id 
where struttura.titolo_code::integer between 1 and 5   ;


--Sommatoria di accertamenti pluriennali >2021 SOLO del titolo 5 + accertamenti
-- pluriennali RATEIZZATI del Titolo 1 e del Titolo 3 - 
--Nel perimetro dei capitoli pertinenti ed utilizzati per il calcolo del fondo

--NB: ad oggi non e' possibile distinguere gli accertamenti pluriennali Rateizzati
-- dagli accertaementi pluriennali normali perche' non ci sono flag/menu' che li 
--identifichino. Proporremo agli enti di utilizzare un classificatore che verra' 
--settato con la dicitura "Rateizzazione del credito" per cui vi arrivera' 
--dettagliata richiesta a strettissimo giro.


with struttura as (select *
 from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
capitoli as (      
    select class.classif_id categoria_id,       
       dt_movimento.movgest_ts_det_importo
      from siac_t_bil_elem     capitolo , 
        siac_r_movgest_bil_elem   r_mov_capitolo, 
        siac_d_bil_elem_tipo    t_capitolo, 
        siac_t_movgest     movimento, 
        siac_d_movgest_tipo    tipo_mov, 
        siac_t_movgest_ts    ts_movimento, 
        siac_r_movgest_ts_stato   r_movimento_stato, 
        siac_d_movgest_stato    tipo_stato, 
        siac_t_movgest_ts_det   dt_movimento, 
        siac_d_movgest_ts_tipo   ts_mov_tipo, 
        siac_d_movgest_ts_det_tipo  dt_mov_tipo ,        
        siac_t_class class,	
        siac_d_class_tipo d_class_tipo,
        siac_r_bil_elem_class r_bil_elem_class,
        siac_t_acc_fondi_dubbia_esig fcde
      where r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and class.classif_id           = r_bil_elem_class.classif_id
	  and d_class_tipo.classif_tipo_id      = class.classif_tipo_id
      and r_bil_elem_class.elem_id   = capitolo.elem_id
      and fcde.elem_id						= capitolo.elem_id
	  and movimento.ente_proprietario_id   = p_ente_prop_id 
      and movimento.bil_id					=	bilancio_id 
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      	--accertamenti con anno > anno bilancio     
      and movimento.movgest_anno 	        > 	p_anno::integer 
      and tipo_mov.movgest_tipo_code    	= 'A' --accertamenti
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale        
      and d_class_tipo.classif_tipo_code	 = 'CATEGORIA'  
      and fcde.afde_bil_id				=  p_afde_bilancio_id    
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and class.data_cancellazione    is null  
      and d_class_tipo.data_cancellazione is null  
      and r_bil_elem_class.data_cancellazione is null
      and fcde.data_cancellazione is null)   
select	COALESCE(sum(movgest_ts_det_importo),0) afde_bil_accertamenti_anni_successivi,
    	COALESCE(sum(movgest_ts_det_importo),0) afde_bil_accertamenti_anni_successivi_fcde
	into afde_bil_accertamenti_anni_successivi, afde_bil_accertamenti_anni_successivi_fcde
from struttura
	left join capitoli 
    	on struttura.categoria_id=capitoli.categoria_id 
	--devono essere presi solo i pluriennali del titolo 5 e i pluriennali
    --rateizzati dei titoli 1 e 3.
    --Al momento non si sa come distinguere quelli rateizzati.        
where struttura.titolo_code::integer in (1,3,5) ;      


return next;


exception
when no_data_found THEN
    raise notice 'nessun dato trovato.';
    return;
when others  THEN
    RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
        
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;