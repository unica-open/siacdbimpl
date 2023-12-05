/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into siac_t_attr(
  attr_code,
  attr_desc,
  attr_tipo_id,
  login_operazione,
  validita_inizio,
  ente_proprietario_id
)
select 'flagDaReanno',
       'flagDaReanno',
       tipo.attr_tipo_id,
       'SIAC-6997',
       now(),
	   tipo.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_attr_tipo tipo
where --ente.ente_proprietario_id in (2,15)
--and   
tipo.ente_proprietario_id =ente.ente_proprietario_id
and   tipo.attr_tipo_code='B'
and not exists
(
select 1
from siac_t_attr attr
where  attr.ente_proprietario_id=ente.ente_proprietario_id
and    attr.attr_tipo_id=tipo.attr_tipo_id
and    attr.attr_code='flagDaReanno'
and    attr.data_cancellazione is null
and    attr.validita_fine is null
);

SELECT * FROM fnc_dba_add_column_params ('siac_t_modifica', 'elab_ror_reanno' , 'BOOLEAN DEFAULT false');

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
	