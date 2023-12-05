/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

insert into siac_d_modifica_tipo
(
  mod_tipo_code,
  mod_tipo_desc,
  login_operazione,
  validita_inizio,
  ente_proprietario_id
)
select 'REANNO',
       'REANNO - Reimputazione in corso d''anno',
       'SIAC-6997',
       now(),
	   ente.ente_proprietario_id
from siac.siac_t_ente_proprietario ente
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_modifica_tipo dbt
	WHERE dbt.ente_proprietario_id = ente.ente_proprietario_id
	AND dbt.mod_tipo_id=(SELECT mod_tipo_id 
	 FROM siac.siac_d_modifica_tipo 
	 WHERE mod_tipo_code=TRIM('REANNO')  AND ente_proprietario_id=ente.ente_proprietario_id )
);	   
	  