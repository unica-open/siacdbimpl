/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO 
  siac.siac_d_modifica_tipo(
  mod_tipo_code,
  mod_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'RORM','ROR - Da mantenere',
to_timestamp('01/01/2017','dd/mm/yyyy'),a.ente_proprietario_id,
'admin'
from siac.siac_t_ente_proprietario a 
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_modifica_tipo ta
	WHERE ta.ente_proprietario_id = a.ente_proprietario_id
	AND ta.mod_tipo_code = 'RORM'
	AND ta.data_cancellazione IS NULL
);