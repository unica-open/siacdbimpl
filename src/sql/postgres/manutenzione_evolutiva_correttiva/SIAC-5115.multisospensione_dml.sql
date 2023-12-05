/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac.siac_d_pcc_operazione_tipo(pccop_tipo_code, pccop_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('CCS', 'CANCELLAZIONE COMUNICAZIONI SCADENZA')) AS tmp (code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_pcc_operazione_tipo dpot
	WHERE dpot.ente_proprietario_id = tep.ente_proprietario_id
	AND dpot.pccop_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;