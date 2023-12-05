/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


INSERT INTO siac.siac_d_mutuo_stato(mutuo_stato_code, mutuo_stato_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.codice, tmp.descrizione, e.ente_proprietario_id, now() as validita_inizio, 'admin' as login_operazione
FROM (VALUES
	('P', 'PREDEFINITIVO')
) AS tmp(codice, descrizione)
JOIN siac_t_ente_proprietario e on e.in_uso
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_mutuo_stato ms
	WHERE ms.mutuo_stato_code = tmp.codice
	and ms.ente_proprietario_id = e.ente_proprietario_id
);