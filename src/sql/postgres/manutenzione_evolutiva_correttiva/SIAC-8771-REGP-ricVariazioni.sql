/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GESC004-ricVarLimitaAVariazioniDefDec','Ricerca variazioni  limitata a variazioni di bilancio definitive decentrate',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacbilapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'BIL_ALTRO'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-GESC004-ricVarLimitaAVariazioniDefDec'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);