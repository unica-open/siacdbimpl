/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into siac_t_class
(
	classif_code,
    classif_desc,
    classif_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select 'CON',
       'Consulenze',
       tipo.classif_tipo_id,
       now(),
       'SIAC-6255',
       ente.ente_proprietario_id

from siac_t_ente_proprietario ente,siac_d_class_tipo tipo
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.classif_tipo_code='TIPO_AMBITO'
and   not exists
(
select 1
from siac_t_class c1
where c1.ente_proprietario_id=ente.ente_proprietario_id
and   c1.classif_tipo_id=tipo.classif_tipo_id
and   c1.classif_code='CON'
and   c1.data_cancellazione is null
);
