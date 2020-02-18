/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.desc, dat.azione_tipo_id, gda.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'), tep.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_t_ente_proprietario tep ON (dat.ente_proprietario_id = tep.ente_proprietario_id)
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = e.ente_proprietario_id)
CROSS JOIN (VALUES ('OP-SPE-CompDefPreDoc', 'Completa e Definisci da Elenco', 'ATTIVITA_SINGOLA', 'FIN2_PREDOC')) AS tmp(code, descr, tipo, gruppo)
WHERE dga.gruppo_azioni_code = tmp.gruppo
AND dat.azione_tipo_id = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_tipo_id = dat.azione_tipo_id
	AND ta.azione_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_r_ruolo_op_azione (ruolo_op_id, azione_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dro.ruolo_op_id, ta.azione_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_ruolo_op dro ON dro.ente_proprietario_id = tep.ente_proprietario_id
JOIN siac_t_azione ta ON ta.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('OP-SPE-CompDefPreDoc', 'ROP_DOCSPESA', '')) AS tmp(azione, ruolo, ente)
WHERE dro.ruolo_op_code = tmp.ruolo
AND ta.azione_code = tmp.azione
--AND UPPER(TRANSATE('', '', tep.ente_denominazione)) = UPPER(tmp.ente)
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_ruolo_op_azione rroa
	WHERE rroa.ente_proprietario_id = tep.ente_proprietario_id
	AND rroa.ruolo_op_id = dro.ruolo_op_id
	AND rroa.azione_id = ta.azione_id
	AND rroa.data_cancellazione IS NULL
);