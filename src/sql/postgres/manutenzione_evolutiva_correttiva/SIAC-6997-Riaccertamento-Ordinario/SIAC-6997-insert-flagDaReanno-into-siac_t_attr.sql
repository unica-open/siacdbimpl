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
select 'flagDaReanno',
       'flagDaReanno',
       tipo.attr_tipo_id,
       'SIAC-6997',
       now(),
	   tipo.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_attr_tipo tipo
where ente.ente_proprietario_id in (2,15)
and   tipo.ente_proprietario_id =ente.ente_proprietario_id
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
