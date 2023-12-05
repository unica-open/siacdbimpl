/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

select *
from fase_bil_d_elaborazione_tipo  tipo 
where tipo.ente_proprietario_id =3


insert into fase_bil_d_elaborazione_tipo  
(
fase_bil_elab_tipo_code, 
fase_bil_elab_tipo_desc ,
validita_inizio ,
login_operazione ,
ente_proprietario_id 
)
select 'APE_PREV_VINCOLI',
            'APERTURA BILANCIO PREVISIONE: ALLINEAMENTO VINCOLI',
            now(),
            'SIAC-TASK-234',
            ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id =3

select fase.fase_operativa_code , anno.anno_bilancio 
from siac_r_bil_fase_operativa  r,siac_d_fase_operativa  fase,siac_v_bko_anno_bilancio  anno 
where fase.ente_proprietario_id =2
and      r.fase_operativa_id =fase.fase_operativa_id 
and     anno.bil_id=r.bil_id 

select anno.anno_bilancio , tipo.vincolo_tipo_code ,stato.vincolo_stato_code , vinc.*
from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo,siac_v_bko_anno_bilancio anno ,siac_r_vincolo_stato rs,siac_d_vincolo_Stato stato 
where tipo.ente_proprietario_id =3
and     vinc.vincolo_tipo_id=tipo.vincolo_tipo_id 
and     anno.periodo_id=vinc.periodo_id 
and     anno.anno_bilancio in (2023,2024)
and     rs.vincolo_id=vinc.vincolo_id 
and   stato.vincolo_stato_id =rs.vincolo_stato_id 
and   stato.vincolo_stato_code !='A'
and    vinc.data_cancellazione  is null 
and    vinc.validita_fine  is null 
and    rs.data_cancellazione  is null 
and    rs.validita_fine  is null 
order  by 1,2
2023	G	1054
2023	P	970
2024	P	1065

select anno.anno_bilancio , tipo.vincolo_tipo_code ,count(*)
from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo,siac_v_bko_anno_bilancio anno ,siac_r_vincolo_stato rs,siac_d_vincolo_Stato stato 
where tipo.ente_proprietario_id =3
and     vinc.vincolo_tipo_id=tipo.vincolo_tipo_id 
and     anno.periodo_id=vinc.periodo_id 
and     anno.anno_bilancio in (2023,2024)
and     rs.vincolo_id=vinc.vincolo_id 
and   stato.vincolo_stato_id =rs.vincolo_stato_id 
and   stato.vincolo_stato_code !='A'
and    vinc.data_cancellazione  is null 
and    vinc.validita_fine  is null 
and    rs.data_cancellazione  is null 
and    rs.validita_fine  is null 
group by anno.anno_bilancio , tipo.vincolo_tipo_code 
order  by 1,2
-- 2023	G	1059
-- 2023	P	1045
-- 2024	P	1059
select 
fnc_fasi_bil_prev_allinea_vincoli
(
  2023,
  3,
  'SIAC-TASK-234',
 now()::timestamp
 )

 
 100010/0
 100231/0
 
 
 67350
 
 select cap.elem_id , cap.*
 from siac_v_bko_capitolo_valido  cap 
 where cap.ente_proprietario_id=2
 and     cap.anno_bilancio =2023
 and     cap.elem_tipo_code in ('CAP-UG','CAP-EG')
 and     cap.elem_stato_code ='VA'
 and    not exists 
 ( 
 select 1 from siac_r_vincolo_bil_elem r 
 where r.elem_id=cap.elem_id 
 and     r.data_cancellazione  is null 
 and     r.validita_fine  is null 
 )
 order by cap.elem_id 
 
 select anno.anno_bilancio , tipo.vincolo_tipo_code ,vinc.vincolo_code, r.vincolo_elem_id ,cap.elem_tipo_code, cap.elem_code
from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo,siac_v_bko_anno_bilancio anno ,siac_r_vincolo_stato rs,siac_d_vincolo_Stato stato ,siac_r_vincolo_bil_elem  r ,siac_v_bko_capitolo_valido cap 
where tipo.ente_proprietario_id =2
and     vinc.vincolo_tipo_id=tipo.vincolo_tipo_id 
and     anno.periodo_id=vinc.periodo_id 
and     anno.anno_bilancio in (2024)
and     rs.vincolo_id=vinc.vincolo_id 
and   stato.vincolo_stato_id =rs.vincolo_stato_id 
and   stato.vincolo_stato_code !='A'
and   r.vincolo_id=vinc.vincolo_id 
and   cap.elem_id=r.elem_id
and    R.data_cancellazione  is null 
and    r.validita_fine  is null 
and    vinc.data_cancellazione  is null 
and    vinc.validita_fine  is null 
and    rs.data_cancellazione  is null 
and    rs.validita_fine  is null 
order  by r.vincolo_elem_id  desc 