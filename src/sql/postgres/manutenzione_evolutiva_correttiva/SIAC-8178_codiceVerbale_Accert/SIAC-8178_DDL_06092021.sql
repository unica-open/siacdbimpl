/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into siac_t_attr 
(
	attr_code,
	attr_desc,
	attr_tipo_id,
	login_operazione,
	validita_inizio,
	ente_proprietario_id
)
select 'codVerbaleAccertamento',
       'Codice verbale accertamento',
       tipo.attr_tipo_id,
       'SIAC-8171',
        now(),
       tipo.ente_proprietario_id
from siac_d_attr_tipo tipo,siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.attr_tipo_code='X'
and   not exists
(
select 1
from siac_t_attr attr1
where attr1.attr_tipo_id=tipo.attr_tipo_id
and   attr1.attr_code='codVerbaleAccertamento'
and   attr1.data_cancellazione is null
)


select fnc_dba_add_column_params ('siac_dwh_accertamento',  'codice_verbale',  'VARCHAR(250)');

