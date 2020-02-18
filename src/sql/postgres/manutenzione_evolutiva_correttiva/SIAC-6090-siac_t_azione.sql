/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Inserimento azione nuova
INSERT INTO siac.siac_t_azione (
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
SELECT
  'OP-ENT-CompDefPreDoc',
  'Completa e Definisci Predisposizioni di Incasso',
  a.azione_tipo_id,
  b.gruppo_azioni_id,
  '/../siacbilapp/azioneRichiesta.do',
  FALSE,
  now(),
  a.ente_proprietario_id,
  'admin'
FROM siac_d_azione_tipo a
JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = 'FIN_BASE2'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-ENT-CompDefPreDoc'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

-- Update azione esistente
UPDATE siac_t_azione
SET azione_desc = 'Completa e Definisci Predisposizioni di Pagamento'
WHERE azione_code = 'OP-SPE-CompDefPreDoc';
