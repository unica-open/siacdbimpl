/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac.siac_d_siope_assenza_motivazione(siope_assenza_motivazione_code, siope_assenza_motivazione_desc, siope_assenza_motivazione_desc_bnkit, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('CL', 'Cig da definire in fase di liquidazione', '')) AS tmp (code, descr, bnkit)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_assenza_motivazione dsam
	WHERE dsam.ente_proprietario_id = tep.ente_proprietario_id
	AND dsam.siope_assenza_motivazione_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;
