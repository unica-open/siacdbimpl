/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac_t_azione 
( azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  validita_inizio,
  ente_proprietario_id,
  login_operazione)
SELECT 'OP-FLUSSO-CESPITI', 'Gestione flusso cespiti', 
		(SELECT at.azione_tipo_id FROM siac_d_azione_tipo at 
         WHERE at.azione_tipo_code='AZIONE_SECONDARIA' AND
         at.ente_proprietario_id=e.ente_proprietario_id),
         (SELECT ga.gruppo_azioni_id FROM siac_d_gruppo_azioni ga
         WHERE ga.gruppo_azioni_code='INV' AND 
         ga.ente_proprietario_id=e.ente_proprietario_id),
         '/../siacintegser/ElaboraFileService',
         NOW(),
         e.ente_proprietario_id,
         'admin'
FROM siac_t_ente_proprietario e
WHERE NOT EXISTS (
	SELECT 1 FROM siac_t_azione a
    WHERE a.azione_code='OP-FLUSSO-CESPITI' 
    AND a.ente_proprietario_id=e.ente_proprietario_id
);

        


INSERT INTO siac_d_file_tipo
( file_tipo_code,
  file_tipo_desc,
  azione_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione)
SELECT 
	'CESPITI',
    'Caricamento massivo cespiti',
    (SELECT a.azione_id FROM siac_t_azione a 
    WHERE a.azione_code='OP-FLUSSO-CESPITI' 
    AND a.ente_proprietario_id=e.ente_proprietario_id),
    NOW(),
    e.ente_proprietario_id,
	'admin'    
FROM siac_t_ente_proprietario e
WHERE NOT EXISTS (
	SELECT 1 FROM siac_d_file_tipo ft
    WHERE ft.file_tipo_code='FLUSSO_CESPITI' 
    AND ft.ente_proprietario_id=e.ente_proprietario_id
);

          