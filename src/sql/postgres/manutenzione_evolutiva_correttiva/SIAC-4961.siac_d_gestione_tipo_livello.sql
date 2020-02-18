/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('GESTIONE_ACCREDITO', 'Codici Accredito Elaborazioni Massive')) AS tmp(code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('ACCREDITO_CONTANTI', '', 'GESTIONE_ACCREDITO'),
	('ACCREDITO_CONTO_BANCA', '', 'GESTIONE_ACCREDITO')) AS tmp(code, descr, tipo)
WHERE dgt.gestione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_r_gestione_ente (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dgl.gestione_livello_id, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('ACCREDITO_CONTANTI'),
	('ACCREDITO_CONTO_BANCA')) AS tmp(livello)
WHERE dgl.gestione_livello_code = tmp.livello
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
	AND rge.data_cancellazione IS NULL
);
