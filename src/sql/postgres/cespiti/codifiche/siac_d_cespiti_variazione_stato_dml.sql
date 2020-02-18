/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac_d_cespiti_variazione_stato (ces_var_stato_code, ces_var_stato_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.ces_var_stato_code, tmp.ces_var_stato_desc, tep.ente_proprietario_id, now(), 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES
	('P', 'Provvisorio'),
	('D', 'Definitivo'),
	('A', 'Annullato')
) AS tmp(ces_var_stato_code, ces_var_stato_desc)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_cespiti_variazione_stato dcvs
	WHERE dcvs.ces_var_stato_code = tmp.ces_var_stato_code
	AND dcvs.ente_proprietario_id = tep.ente_proprietario_id
	AND dcvs.data_cancellazione IS NULL
)
ORDER BY tep.ente_proprietario_id, tmp.ces_var_stato_code;
