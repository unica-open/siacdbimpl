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