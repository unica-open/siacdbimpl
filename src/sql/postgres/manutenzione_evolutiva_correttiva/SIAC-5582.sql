/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac_t_attr (attr_code, attr_desc, attr_tipo_id, tabella_nome, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.attr_tipo_id, null, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_attr_tipo dat ON dat.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES('FlagAccertatoPerCassa', 'FlagAccertatoPerCassa')) AS tmp(code, descr)
WHERE tep.data_cancellazione IS NULL
AND dat.attr_tipo_code = 'B'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_attr ta
	WHERE ta.attr_tipo_id = dat.attr_tipo_id
	AND ta.ente_proprietario_id = tep.ente_proprietario_id
	AND ta.attr_code = tmp.code
);
