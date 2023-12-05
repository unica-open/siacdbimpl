/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--inserimento azioni
--insert azione OP-COM-limitaCompVarDec
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GESC007-limitaCompVarDec', 'Utilizza solo componente fresca', a.azione_tipo_id, b.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, now(), a.ente_proprietario_id,  'admin'
FROM siac.siac_d_azione_tipo a JOIN siac.siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'BIL_ALTRO'
AND NOT EXISTS (
  SELECT 1
  FROM siac.siac_t_azione z
  WHERE z.azione_code = 'OP-GESC007-limitaCompVarDec'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);
