/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Inserimento azioni
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GEN-gestisciPRNotaIntManGSA', 'Inserisci prima nota integrata manuale', ta.azione_tipo_id, ga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
WHERE ta.ente_proprietario_id = e.ente_proprietario_id
AND ga.ente_proprietario_id = e.ente_proprietario_id
AND ta.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND ga.gruppo_azioni_code = 'GEN_GSA'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione z
	WHERE z.azione_tipo_id=ta.azione_tipo_id
	AND z.azione_code='OP-GEN-gestisciPRNotaIntManGSA'
);

INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GEN-ricPRNotaIntManGSA', 'Ricerca prima nota integrata manuale', ta.azione_tipo_id, ga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
WHERE ta.ente_proprietario_id = e.ente_proprietario_id
AND ga.ente_proprietario_id = e.ente_proprietario_id
AND ta.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND ga.gruppo_azioni_code = 'GEN_GSA'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione z
	WHERE z.azione_tipo_id=ta.azione_tipo_id
	AND z.azione_code='OP-GEN-ricPRNotaIntManGSA'
);

-- Inserimento evento e tipo
INSERT INTO siac_d_evento_tipo (evento_tipo_code, evento_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'EXTR', 'EXTR', now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_evento_tipo det
	WHERE det.ente_proprietario_id = tep.ente_proprietario_id
	AND det.evento_tipo_code = 'EXTR'
);

INSERT INTO siac_r_causale_ep_tipo_evento_tipo (causale_ep_tipo_id, evento_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dcet.causale_ep_tipo_id, det.evento_tipo_id, now(), dcet.ente_proprietario_id, 'admin'
FROM siac_d_causale_ep_tipo dcet
JOIN siac_d_evento_tipo det ON det.ente_proprietario_id = dcet.ente_proprietario_id
WHERE dcet.causale_ep_tipo_code = 'INT'
AND det.evento_tipo_code = 'EXTR'
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_causale_ep_tipo_evento_tipo rcetet
	WHERE rcetet.causale_ep_tipo_id = dcet.causale_ep_tipo_id
	AND rcetet.evento_tipo_id = det.evento_tipo_id
	AND rcetet.ente_proprietario_id = dcet.ente_proprietario_id
);

-- Gli eventi inseriti sono EXTR (fittizio, per l'interfaccia utente), EXTR-I per l'impegno, EXTR-A per l'accertamento, EXTR-IS per il subimpegno, EXTR-AS per il subaccertamento
INSERT INTO siac_d_evento (evento_code, evento_desc, evento_tipo_id, collegamento_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, det.evento_tipo_id, dct.collegamento_tipo_id, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo det ON det.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES
	('EXTR', 'EXTR', 'EXTR', NULL),
	('EXTR-I', 'EXTR-Impegno', 'EXTR', 'I'),
	('EXTR-A', 'EXTR-Accertamento', 'EXTR', 'A'),
	('EXTR-SI', 'EXTR-SubImpegno', 'EXTR', 'SI'),
	('EXTR-SA', 'EXTR-SubAccertamento', 'EXTR', 'SA'))
	AS tmp(code, descr, tipo, coll)
LEFT OUTER JOIN siac_d_collegamento_tipo dct ON (dct.ente_proprietario_id = tep.ente_proprietario_id AND dct.collegamento_tipo_code = tmp.coll)
WHERE det.evento_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_evento de
	WHERE de.ente_proprietario_id = tep.ente_proprietario_id
	AND de.evento_tipo_id = det.evento_tipo_id
	AND de.evento_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

-- Creazione della causale di default
INSERT INTO siac_t_causale_ep (causale_ep_code, causale_ep_desc, causale_ep_tipo_id, ambito_id, validita_inizio, ente_proprietario_id, login_creazione, login_operazione)
SELECT 'EXTR', 'EXTR', dcet.causale_ep_tipo_id , da.ambito_id, now(), tep.ente_proprietario_id, 'admin', 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_causale_ep_tipo dcet ON (tep.ente_proprietario_id = dcet.ente_proprietario_id)
JOIN siac_d_ambito da ON (tep.ente_proprietario_id = da.ente_proprietario_id)
WHERE dcet.causale_ep_tipo_code = 'INT'
AND da.ambito_code = 'AMBITO_GSA'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_causale_ep tce
	WHERE tce.ente_proprietario_id = tep.ente_proprietario_id
	AND tce.causale_ep_tipo_id = dcet.causale_ep_tipo_id
	AND tce.ambito_id = da.ambito_id
	AND tce.causale_ep_code = 'EXTR'
	AND tce.data_cancellazione IS NULL
);

INSERT INTO siac_r_evento_causale (evento_id, causale_ep_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT de.evento_id, tce.causale_ep_id, now(), de.ente_proprietario_id, 'admin'
FROM siac_d_evento de
JOIN siac_t_causale_ep tce ON (de.ente_proprietario_id = tce.ente_proprietario_id)
WHERE de.evento_code = 'EXTR'
AND tce.causale_ep_code = 'EXTR'
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_evento_causale rec
	WHERE rec.ente_proprietario_id = de.ente_proprietario_id
	AND rec.causale_ep_id = tce.causale_ep_id
	AND rec.evento_id = de.evento_id
	AND rec.data_cancellazione IS NULL
);

INSERT INTO siac_r_causale_ep_stato (causale_ep_id, causale_ep_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tce.causale_ep_id, dces.causale_ep_stato_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tce.ente_proprietario_id, 'admin'
FROM siac_t_causale_ep tce
JOIN siac_d_causale_ep_stato dces ON (tce.ente_proprietario_id = dces.ente_proprietario_id)
WHERE dces.causale_ep_stato_code = 'V'
AND tce.causale_ep_code = 'EXTR'
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_causale_ep_stato rces
	WHERE rces.ente_proprietario_id = tce.ente_proprietario_id
	AND rces.causale_ep_id = tce.causale_ep_id
	AND rces.causale_ep_stato_id = dces.causale_ep_stato_id
);