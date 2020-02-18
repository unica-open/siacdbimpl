/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac_d_ambito (ambito_code, ambito_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.ambito_code, tmp.ambito_desc, tep.ente_proprietario_id, now(), 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES('AMBITO_INV', 'Ambito inventario')	
) AS tmp(ambito_code, ambito_desc)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_ambito dcvs
	WHERE dcvs.ambito_code = tmp.ambito_code
	AND dcvs.ente_proprietario_id = tep.ente_proprietario_id
	AND dcvs.data_cancellazione IS NULL
)
ORDER BY tep.ente_proprietario_id, tmp.ambito_code;


INSERT INTO siac_d_pn_prov_accettazione_stato (pn_sta_acc_prov_code, pn_sta_acc_prov_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.pn_sta_acc_prov_code, tmp.pn_sta_acc_prov_desc, tep.ente_proprietario_id, now(), 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES
	('1', 'Definitivo'),
	('2', 'Rifiutato'),
	('3', 'Provvisorio')
) AS tmp(pn_sta_acc_prov_code, pn_sta_acc_prov_desc)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_pn_prov_accettazione_stato dcvs
	WHERE dcvs.pn_sta_acc_prov_code = tmp.pn_sta_acc_prov_code
	AND dcvs.ente_proprietario_id = tep.ente_proprietario_id
	AND dcvs.data_cancellazione IS NULL
)
ORDER BY tep.ente_proprietario_id, tmp.pn_sta_acc_prov_code;

INSERT INTO siac_d_pn_def_accettazione_stato (pn_sta_acc_def_code, pn_sta_acc_def_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.pn_sta_acc_def_code, tmp.pn_sta_acc_def_desc, tep.ente_proprietario_id, now(), 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES
	('1', 'Integrato con inventario'),
	('2', 'Rifiutato'),
	('3', 'Da accettare')
) AS tmp(pn_sta_acc_def_code, pn_sta_acc_def_desc)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_pn_def_accettazione_stato dcvs
	WHERE dcvs.pn_sta_acc_def_code = tmp.pn_sta_acc_def_code
	AND dcvs.ente_proprietario_id = tep.ente_proprietario_id
	AND dcvs.data_cancellazione IS NULL
)
ORDER BY tep.ente_proprietario_id, tmp.pn_sta_acc_def_code;
--
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.azione_code, tmp.azione_desc, dat.azione_tipo_id, dga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, now(), dat.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = dat.ente_proprietario_id)
JOIN (VALUES
	('OP-INV-gestisciAmmMassivo','Inserisci ammortamento massivo', 'ATTIVITA_SINGOLA', 'INV')
) AS tmp(azione_code, azione_desc, azione_tipo_code, gruppo_azioni_code) ON (tmp.azione_tipo_code = dat.azione_tipo_code AND tmp.gruppo_azioni_code = dga.gruppo_azioni_code)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_code = tmp.azione_code
	AND ta.ente_proprietario_id = dat.ente_proprietario_id
	AND ta.data_cancellazione IS NULL
);
