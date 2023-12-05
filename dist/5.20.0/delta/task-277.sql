/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/




insert into siac_d_commissione_tipo  
(
comm_tipo_code,
comm_tipo_desc,
validita_inizio ,
login_operazione ,
ente_proprietario_id 
)
select 'ES1',
           'AMMPUBB',
           now(),
           'SIAC-TASK-277',
           ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id =2
and      not exists 
(
select 1 
from siac_d_commissione_tipo  tipo1 
where tipo1.ente_proprietario_id =ente.ente_proprietario_id 
and      tipo1.comm_tipo_code ='ES1'
and      tipo1.data_cancellazione  is null 
and      tipo1.validita_fine is null 
);

insert into siac_r_commissione_tipo_plus 
(
comm_tipo_id,
comm_tipo_plus_id ,
validita_inizio ,
login_operazione ,
ente_proprietario_id 
)
select tipo.comm_tipo_id,
           plus.comm_tipo_plus_id ,
           now(),
           'SIAC-TASK-277',
           tipo.ente_proprietario_id 
from siac_t_ente_proprietario  ente ,siac_d_commissione_tipo  tipo,siac_d_commissione_tipo_plus  plus
where ente.ente_proprietario_id =2
and      tipo.ente_proprietario_id =ente.ente_proprietario_id 
and      tipo.comm_tipo_code ='ES1'
and      plus.ente_proprietario_id =2
and      plus.comm_tipo_plus_code ='ES'
and      plus.comm_tipo_plus_esente =true
and      not exists 
(
select 1 
from siac_r_commissione_tipo_plus  r  
where r.ente_proprietario_id =ente.ente_proprietario_id  
and     r.comm_tipo_plus_id =plus.comm_tipo_plus_id 
and     r.comm_tipo_id =tipo.comm_tipo_id 
and     r.data_cancellazione  is null 
and    r.validita_fine  is null 
);