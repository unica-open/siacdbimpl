/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac_t_attr (
  attr_code,
  attr_desc,
  attr_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  login_operazione)
SELECT 
	'flagSoggettoDurc',
    'Flag Soggetto a DURC',
    (SELECT at.attr_tipo_id FROM siac_d_attr_tipo at WHERE at.attr_tipo_code='B' AND at.ente_proprietario_id=e.ente_proprietario_id),
    now(),
    e.ente_proprietario_id,
    now(),
    now(),
    'admin'
FROM siac_t_ente_proprietario e
WHERE NOT EXISTS (
	SELECT * FROM siac_t_attr a 
    WHERE a.attr_code='flagSoggettoDurc'
    AND a.ente_proprietario_id=e.ente_proprietario_id
);

