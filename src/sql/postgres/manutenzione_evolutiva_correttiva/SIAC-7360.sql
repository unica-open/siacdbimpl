/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.azione_code, tmp.azione_desc, dat.azione_tipo_id, dga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, now(), dat.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = dat.ente_proprietario_id)
JOIN (VALUES
	('OP-ENT-GestisciModifica', 'Gestisci modifica entrata', 'AZIONE_SECONDARIA', 'FIN_BASE1'),
	('OP-SPE-GestisciModifica', 'Gestisci modifica spesa', 'AZIONE_SECONDARIA', 'FIN_BASE1')	
) AS tmp(azione_code, azione_desc, azione_tipo_code, gruppo_azioni_code) ON (tmp.azione_tipo_code = dat.azione_tipo_code AND tmp.gruppo_azioni_code = dga.gruppo_azioni_code)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_code = tmp.azione_code
	AND ta.ente_proprietario_id = dat.ente_proprietario_id
	AND ta.data_cancellazione IS NULL
);
