/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- insert multi-ente su CAP-UG componente "Da attribuire"
begin;
insert into siac_t_bil_elem_Det_comp
(
  elem_det_id,
  elem_det_comp_tipo_id,
  elem_det_importo,
  validita_inizio,
  login_operazione,
  ente_Proprietario_id
)
select query.elem_det_id,
       query.elem_det_comp_tipo_id,
       query.elem_det_importo,
       (query.anno_bilancio::varchar||'-01-01')::timestamp,
       'admin',
       query.ente_proprietario_id

from
(
with
cap_det as
(
select e.ente_proprietario_id,
       anno.anno_bilancio,
       anno.bil_id,
       tipo.elem_tipo_code,
       e.elem_code::integer elem_code,
       e.elem_code2::integer elem_code2,
       e.elem_id,
       tipo_det.elem_det_tipo_code,
       per.anno::integer anno_det,
       det.elem_det_id,
       det.elem_det_importo,
       det.periodo_id
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_det det,siac_d_bil_elem_det_tipo tipo_det,siac_t_periodo per
where tipo.elem_tipo_code in ('CAP-UG','CAP-UP')
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   det.elem_id=e.elem_id
and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
and   per.periodo_id=det.periodo_id
and   tipo_det.elem_det_tipo_code='STA'
and   Det.data_cancellazione is null
and   det.validita_fine is null
and   e.data_cancellazione is null
order by 1,2,3,4,5,6,per.anno::integer
),
tipo_comp as
(
select macro.elem_det_comp_macro_tipo_code,
       macro.elem_det_comp_macro_tipo_desc,
       tipo_comp.*
from siac_d_bil_elem_det_comp_tipo tipo_comp,siac_d_bil_elem_det_comp_macro_tipo macro
where macro.elem_det_comp_macro_tipo_desc ='Da attribuire'
and   macro.elem_det_comp_macro_tipo_id=tipo_comp.elem_det_comp_macro_tipo_id
and   tipo_comp.data_cancellazione is null
) ,
cap_det_comp as
(
select *
from siac_t_bil_elem_Det_comp comp
where comp.data_cancellazione is null
)
select cap_det.elem_id,
       cap_det.elem_code,
       cap_det.elem_det_id,
       cap_det.elem_det_importo,
       cap_det.anno_det,
       cap_det.periodo_id,
       cap_det.anno_bilancio,
       cap_det.bil_id,
       cap_det.elem_tipo_code,
       cap_det.ente_proprietario_id,
       tipo_comp.elem_det_comp_macro_tipo_desc,
       tipo_comp.elem_det_comp_tipo_id
from cap_det, tipo_comp
where cap_det.ente_proprietario_id=tipo_comp.ente_proprietario_id
and   not exists
(
select 1
from  cap_det_comp det_comp
where det_comp.elem_det_id=cap_det.elem_det_id
and   det_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
)
) query,siac_v_bko_anno_bilancio anno, siac_d_bil_elem_tipo tipo,  siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   anno.ente_proprietario_id=ente.ente_proprietario_id
and   anno.anno_bilancio=2019
and   tipo.ente_proprietario_id=ente.ente_proprietariO_id
and   tipo.elem_tipo_code='CAP-UG'
and   query.ente_proprietario_id=ente.ente_proprietario_id
and   query.bil_id=anno.bil_id
and   query.elem_tipo_code=tipo.elem_tipo_code;

--------- query verifica -----------------


select e.elem_code::integer, per.anno::integer,tipo_det.elem_det_tipo_code,
       det.*
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_det det,siac_d_bil_elem_det_tipo tipo_det,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UG'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2019
and   det.elem_id=e.elem_id
and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
and   per.periodo_id=det.periodo_id
and   tipo_det.elem_det_tipo_code='STA'
and   Det.data_cancellazione is null
and   det.validita_fine is null
and   e.data_cancellazione is null
order by 1,per.anno::integer

select e.elem_code::integer, per.anno::integer,tipo_det.elem_det_tipo_code,
       comp.elem_det_importo, comp.elem_det_comp_tipo_id, tipo_comp.elem_det_comp_tipo_desc,
       comp.data_creazione, comp.login_operazione,
       macro.elem_det_comp_macro_tipo_desc,
       det.*
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_det det,siac_d_bil_elem_det_tipo tipo_det,siac_t_periodo per,
     siac_t_bil_elem_det_comp comp,siac_d_bil_elem_det_comp_tipo tipo_comp,siac_d_bil_elem_det_comp_macro_tipo macro
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UG'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2019
and   det.elem_id=e.elem_id
and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
and   per.periodo_id=det.periodo_id
and   tipo_det.elem_det_tipo_code='STA'
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   macro.elem_det_comp_macro_tipo_id=tipo_comp.elem_det_comp_macro_tipo_id
and   Det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   e.data_cancellazione is null
order by 1,per.anno::integer