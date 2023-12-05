/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

--- impegnabile
insert into siac_d_bil_elem_det_comp_tipo_imp
(
	elem_det_comp_tipo_imp_code,
    elem_det_comp_tipo_imp_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Si',
    now(),
    'SIAC-7349',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_imp tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_imp_code='01'
and   tipo.elem_det_comp_tipo_imp_desc='Si'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


insert into siac_d_bil_elem_det_comp_tipo_imp
(
	elem_det_comp_tipo_imp_code,
    elem_det_comp_tipo_imp_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'No',
    now(),
    'SIAC-7349',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_imp tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_imp_code='02'
and   tipo.elem_det_comp_tipo_imp_desc='No'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);




insert into siac_d_bil_elem_det_comp_tipo_imp
(
	elem_det_comp_tipo_imp_code,
    elem_det_comp_tipo_imp_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Auto',
    now(),
    'SIAC-7349',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_imp tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_imp_code='03'
and   tipo.elem_det_comp_tipo_imp_desc='Auto'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);