/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into siac_d_bil_elem_det_comp_tipo
(
  elem_det_comp_tipo_code,
  elem_det_comp_tipo_desc,
  elem_det_comp_macro_tipo_id,
  elem_det_comp_tipo_stato_id,
  login_operazione,
  validita_inizio,
  ente_proprietario_id
)
select  '01',
		'Da attribuire',
        macro.elem_det_comp_macro_tipo_id,
        stato.elem_det_comp_tipo_stato_id,
        'SIAC-7139',
        now(),
        stato.ente_proprietario_id
from siac_t_ente_proprietario ente, siac_d_bil_elem_det_comp_macro_tipo macro,siac_d_bil_elem_det_comp_tipo_stato stato
where macro.ente_proprietario_id =ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_desc='Da attribuire'
and   stato.ente_proprietario_id=macro.ente_proprietario_id
and   stato.elem_det_comp_tipo_stato_code='V'
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_code='01'
and   tipo.elem_det_comp_tipo_desc='Da attribuire'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.elem_det_comp_tipo_stato_id=stato.elem_det_comp_tipo_stato_id
and   tipo.data_cancellazione is null
);