/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.azcode, tmp.azdesc, ta.azione_tipo_id, ga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario e
JOIN siac_d_azione_tipo ta ON (ta.ente_proprietario_id = e.ente_proprietario_id)
JOIN siac_d_gruppo_azioni ga ON (ga.ente_proprietario_id = e.ente_proprietario_id)
CROSS JOIN (VALUES
	('OP-CEC-abilitaRimborsoSpese', 'Abilitazione richiesta economale rimborso spese'),
	('OP-CEC-abilitaPagamentoFatture', 'Abilitazione richiesta economale pagamento fatture'),
	('OP-CEC-abilitaAnticipoSpese', 'Abilitazione richiesta economale anticipo spese'),
	('OP-CEC-abilitaAnticipoPerTrasfertaDipendenti', 'Abilitazione richiesta economale anticipo per trasferta dipendenti'),
	('OP-CEC-abilitaAnticipoSpesePerMissione', 'Abilitazione richiesta economale anticipo spese per missione'),
	('OP-CEC-abilitaPagamento', 'Abilitazione richiesta economale pagamento')
) AS tmp(azcode, azdesc)
WHERE ta.azione_tipo_code = 'AZIONE_SECONDARIA'
AND ga.gruppo_azioni_code = 'CASSA ECONOMALE'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione z
	WHERE z.azione_tipo_id = ta.azione_tipo_id
	AND z.azione_code = tmp.azcode
)
ORDER BY e.ente_proprietario_id, tmp.azcode;
