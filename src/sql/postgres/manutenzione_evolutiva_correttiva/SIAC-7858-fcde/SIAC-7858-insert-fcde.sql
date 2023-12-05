/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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

--