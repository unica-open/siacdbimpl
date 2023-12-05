/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

insert into siac_t_attr 
(
attr_code,
attr_desc,
attr_tipo_id,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 'annoScritturaEconomicoPatrimoniale',
           'annoScritturaEconomicoPatrimoniale',
           tipo.attr_tipo_id ,
           now(),
           'SIAC-8881',
           tipo.ente_proprietario_id 
from siac_d_attr_tipo tipo 
where tipo.ente_proprietario_id in (2,3,4,5,10,16)
and      tipo.attr_tipo_code ='X'
and      not exists 
(select 1 from siac_t_attr attr1 where attr1.ente_proprietario_id=tipo.ente_proprietario_id and   attr1.attr_code='annoScritturaEconomicoPatrimoniale');