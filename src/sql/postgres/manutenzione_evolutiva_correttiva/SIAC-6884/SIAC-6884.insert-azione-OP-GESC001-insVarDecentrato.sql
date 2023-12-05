/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GESC001-insVarDecentrato','Inserisci Variazione di Bilancio',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacbilapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac.siac_d_azione_tipo a JOIN siac.siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = 'BIL_ALTRO'
AND NOT EXISTS (
  SELECT 1
  FROM siac.siac_t_azione z
  WHERE z.azione_code = 'OP-GESC001-insVarDecentrato'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

INSERT INTO siac.siac_r_ruolo_op_azione (ruolo_op_id, azione_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dro.ruolo_op_id, ta.azione_id, now(), tep.ente_proprietario_id, 'admin'
FROM siac.siac_t_ente_proprietario tep
JOIN siac.siac_d_ruolo_op dro ON dro.ente_proprietario_id = tep.ente_proprietario_id
JOIN siac.siac_t_azione ta ON ta.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('OP-GESC001-insVarDecentrato', 'ruolo op decentrato', '')) AS tmp(azione, ruolo, ente)
WHERE dro.ruolo_op_code = tmp.ruolo AND tep.ente_proprietario_id = 2
AND ta.azione_code = tmp.azione
AND NOT EXISTS (
	SELECT 1
	FROM siac.siac_r_ruolo_op_azione rroa
	WHERE rroa.ente_proprietario_id = tep.ente_proprietario_id
	AND rroa.ruolo_op_id = dro.ruolo_op_id
	AND rroa.azione_id = ta.azione_id
	AND rroa.data_cancellazione IS NULL
);