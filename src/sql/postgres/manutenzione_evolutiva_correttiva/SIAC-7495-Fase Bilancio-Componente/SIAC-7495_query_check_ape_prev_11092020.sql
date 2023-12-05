/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select anno.anno_bilancio,
       fase.fase_operativa_code
from siac_r_bil_fase_operativa r,siac_v_bko_anno_bilancio anno,siac_d_fase_operativa fase
where fase.ente_proprietario_id=2
and   r.fase_operativa_id=fase.fase_operativa_id
and   anno.bil_id=r.bil_id


select anno.anno_bilancio, tipo.elem_tipo_code,count(*)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno
where tipo.ente_proprietario_id=2
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   e.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code
order by 1
-- CAP-UG 5211
-- CAP-EG 1199
-- CAP-UP 5216
-- CAP-EP 1199


select e.elem_code
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno
where tipo.ente_proprietario_id=2
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.anno_bilancio=2021
and   tipo.elem_tipo_code='CAP-EP'
and   anno.bil_id=e.bil_id
and   e.data_cancellazione is null
order by 1

select anno.anno_bilancio, tipo.elem_tipo_code,count(*)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code in ('CAP-UG','CAP-UP')
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio in (2020,2021)
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code
order by 1
-- 2020 CAP-UG 18320
-- 2021 CAP-UP 18339 3963 dopo modifica


select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
       per.anno::integer,det.elem_det_importo,
       tipo_comp.elem_det_comp_tipo_desc,
       comp.elem_det_importo
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UG'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2020
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
order by anno.anno_bilancio, tipo.elem_tipo_code,3,4




-- Q1
-- verifica esistenza capitoli con componente "da attribuire"

select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
       per.anno::integer,det.elem_det_importo,
       tipo_comp.elem_det_comp_tipo_desc,
       comp.elem_det_importo
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
and   tipo_comp.elem_det_comp_tipo_desc='Da attribuire'
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
order by anno.anno_bilancio, tipo.elem_tipo_code,3,4


-- Q2 - verifica esistenza capitoli con componente doppia da bonificare
select comp.*
from siac_t_bil_elem_det_comp comp,
(
select e.elem_code, det.elem_det_id, comp.elem_det_comp_tipo_id, count(*)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UG'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2020
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by e.elem_code, det.elem_det_id, comp.elem_det_comp_tipo_id
having count(*)>1
order by 1
) query
where comp.ente_proprietario_id=2
and   query.elem_det_id=comp.elem_det_id
and   query.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
--and   comp.elem_det_importo=0
and   comp.data_cancellazione is null

-- Q3 - verifica esistenza capitoli con componente solo per anno 2020
-- non dovrebbero essercene
select e.elem_code,
       tipo_comp.elem_det_comp_tipo_desc,
       det.periodo_id,
       per.anno,
       comp.elem_det_importo,
       comp.elem_det_comp_id
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,
     siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UG'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2020
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
and   not exists
(
select 1
from siac_t_bil_elem_det det1,siac_t_bil_elem_det_comp  comp1,
     siac_t_periodo per1
where det1.elem_id=e.elem_id
and   det1.elem_det_tipo_id=det.elem_det_tipo_id
and   per1.periodo_id=det1.periodo_id
and   per1.anno::integer in (2021,2022)
and   comp1.elem_det_id=det1.elem_det_id
and   comp1.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and   det1.data_cancellazione is null
and   det1.validita_fine is null
and   comp1.data_cancellazione is null
and   comp1.validita_fine is null
)
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
order by 1

-- Q4 capitoli di gestione senza corrispondente UP  componente
with
cap_ug as
(
select e.elem_code , det.periodo_id,
       comp.elem_det_comp_tipo_id
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,
     siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UG'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2020
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
and   per.anno::integer>2020
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
),
cap_up as
(
select e.elem_code , det.periodo_id,
       det.elem_det_id
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
)
select ug.*
from cap_ug ug
where
not exists
(select 1 from cap_up up ,siac_t_bil_elem_Det_comp comp
 where up.elem_code=ug.elem_code
 and   up.periodo_id=ug.periodo_id
 and   comp.elem_det_id=up.elem_det_id
 and   comp.elem_det_comp_tipo_id=ug.elem_det_comp_tipo_id
 and   comp.data_cancellazione is null
 and   comp.validita_fine is null
)
-- dopo TD tanti

-- Q5
-- capitoli senza componente, ce ne sono e hanno stanziamento 0
select query.*
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
where macro.ente_proprietario_id=2
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
       cap_det.ente_proprietario_id
from cap_det
where   not exists
(
select 1
from  cap_det_comp det_comp
where det_comp.elem_det_id=cap_det.elem_det_id
)
) query, siac_v_bko_anno_bilancio anno, siac_d_bil_elem_tipo tipo,  siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2
and   anno.ente_proprietario_id=ente.ente_proprietario_id
and   anno.anno_bilancio=2021
and   tipo.ente_proprietario_id=ente.ente_proprietariO_id
and   tipo.elem_tipo_code='CAP-UP'
and   query.ente_proprietario_id=ente.ente_proprietario_id
and   query.bil_id=anno.bil_id
and   query.elem_tipo_code=tipo.elem_tipo_code;

-- Q6 - verifica esistenza capitoli con stanziato differente da tot. componente
-- non devono essercene
select
       e.elem_code::integer elem_code,
       per.anno::integer anno_det,
       det.elem_det_importo,
       coalesce(sum(comp.elem_det_importo),0),
       det.elem_det_id
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_d_bil_elem_det_tipo tipo_det,siac_t_periodo per,
     siac_t_bil_elem_det det
      left join siac_t_bil_elem_det_comp comp
                join siac_d_bil_elem_det_comp_tipo comp_tipo
                  on  ( comp_tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id and  comp_tipo.data_cancellazione is null )
            on (comp.elem_det_id=det.elem_det_id and  comp.data_cancellazione is null)
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2020
and   det.elem_id=e.elem_id
and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
and   per.periodo_id=det.periodo_id
and   tipo_det.elem_det_tipo_code='STA'
and   Det.data_cancellazione is null
and   det.validita_fine is null
and   e.data_cancellazione is null
group by e.elem_code::integer ,
         per.anno::integer,
         det.elem_det_importo,
         det.elem_det_id
having det.elem_det_importo!=coalesce(sum(comp.elem_det_importo),0)
order by 1,2

-- Q7 - verifica esistenza capitoli con numero di componenti non *3
select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
       count(*),mod(count(*),3)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer
having mod(count(*),3)!=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3,4

-- Q8 - estrazione capitoli con STA a zero - questi potrebbero tutti rimanere senza componente
select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,

       sum(Det.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,Siac_d_bil_elem_det_tipo tipo_det,
     siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   per.periodo_id=det.periodo_id
and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
and   tipo_det.elem_det_tipo_code='STA'
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer
having sum(Det.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3
-- 3915
with
cap as
(
select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
	   e.elem_id,
       sum(Det.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,Siac_d_bil_elem_det_tipo tipo_det,
     siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   per.periodo_id=det.periodo_id
and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
and   tipo_det.elem_det_tipo_code='STA'
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer, e.elem_id
having sum(Det.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3
) ,
det_cap as
(
select det.elem_id, tipo.elem_det_tipo_code, sum(det.elem_det_importo) elem_det_importo
from siac_t_bil_elem_det det,siac_d_bil_elem_Det_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.elem_Det_tipo_code in ('SCA','STR')
and   det.elem_det_tipo_id=tipo.elem_det_tipo_id
and   det.data_cancellazione is null
group by det.elem_id, tipo.elem_det_tipo_code
)
select cap.*,
       det_STR.elem_det_importo STR_elem_Det_importo ,
       det_SCA.elem_det_importo SCA_elem_Det_importo
from cap, det_cap det_SCA, det_cap det_STR
where det_SCA.elem_id=cap.elem_id
and   det_SCA.elem_det_tipo_code='SCA'
and   det_STR.elem_id=cap.elem_id
and   det_STR.elem_det_tipo_code='STR'
order by 1, 2,3


-- Q9 - estrazione capitoli con componenti a zero
select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
	   tipo_comp.elem_det_comp_tipo_desc,
       sum(comp.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,tipo_comp.elem_det_comp_tipo_desc
having sum(comp.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3
-- 4788
select distinct query.elem_code
from
(
select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
	   tipo_comp.elem_det_comp_tipo_desc,
       sum(comp.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,tipo_comp.elem_det_comp_tipo_desc
having sum(comp.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3)  query
-- 3925
-- possono essere > dei cap con STA zero
-- possono avere componenti a zero ma avere STA valorizzata
-- inoltre un cap potrebbe avere diverse componenti a zero


-- estrazione capitoli con componenti a zero per capitolo
select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
	   tipo_comp.elem_det_comp_tipo_desc,
       sum(comp.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
and   e.elem_code::integer=100010
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,tipo_comp.elem_det_comp_tipo_desc
having sum(comp.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3

-- estrazione capitoli con componenti a zero - estrazione dei capitoli - stanziamenti
-- potrebbero esserci STA valorizzati in quanto ricerca righe di componente a zero in generale
SELECT query_cap.elem_code, per.anno::integer,
       tipo.elem_det_tipo_code,
       det.elem_det_importo
from siac_t_bil_elem_det det,siac_d_bil_elem_det_tipo tipo,siac_t_periodo per,
(
select distinct query.elem_id,query.elem_code::integer elem_code
from
(
select e.elem_code::integer,
       e.elem_id,
	   tipo_comp.elem_det_comp_tipo_desc,
       sum(comp.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,e.elem_id,tipo_comp.elem_det_comp_tipo_desc
having sum(comp.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3
) query
) query_Cap
where tipo.ente_proprietario_id=2
and   tipo.elem_det_tipo_code in ('SCA','STA','STR')
and   det.elem_det_tipo_id=tipo.elem_det_tipo_id
and   per.periodo_id=det.periodo_id
and   query_cap.elem_id=det.elem_id
and   det.data_cancellazione is null
order by query_cap.elem_code, per.anno::integer,tipo.elem_Det_tipo_code


-- estrazione capitoli/componenti con componenti a zero
select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
       e.elem_id,
       tipo_comp.elem_det_comp_tipo_id,
	   tipo_comp.elem_det_comp_tipo_desc,
       sum(comp.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
--and   e.elem_code::integer=100232
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
         e.elem_id,
         tipo_comp.elem_det_comp_tipo_id,
         tipo_comp.elem_det_comp_tipo_desc
having sum(comp.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3
-- 4788

-- quelle a zero che non si possono invalidare
-- in quanto esistono variazioni

select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
       e.elem_id,
       tipo_comp.elem_det_comp_tipo_id,
	   tipo_comp.elem_det_comp_tipo_desc,
       sum(comp.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
--and   e.elem_code::integer=100232
and   exists
(
select 1
from siac_t_bil_elem_det_comp comp_comp,
     siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
and   dvar.elem_id=e.elem_id
and   comp_comp.data_cancellazione is null
and   dvar_comp.data_cancellazione is null
and   dvar.data_cancellazione is null
)
/*and not exists
(
select 1
from siac_r_movgest_bil_elem re
where  re.elem_id=e.elem_id
and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and    re.data_cancellazione is null
)*/
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
         e.elem_id,
         tipo_comp.elem_det_comp_tipo_id,
         tipo_comp.elem_det_comp_tipo_desc
having sum(comp.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3


-- estrazione capitoli con componenti a zero
-- quelle a zero che si possono invalidare

select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
       e.elem_id,
       tipo_comp.elem_det_comp_tipo_id,
	   tipo_comp.elem_det_comp_tipo_desc,
       sum(comp.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
--and   e.elem_code::integer=100010
and not exists
(
select 1
from siac_t_bil_elem_det_comp comp_comp,
     siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
and   dvar.elem_id=e.elem_id
and   comp_comp.data_cancellazione is null
and   dvar_comp.data_cancellazione is null
and   dvar.data_cancellazione is null
)
and not exists
(
select 1
from siac_r_movgest_bil_elem re
where  re.elem_id=e.elem_id
and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and    re.data_cancellazione is null
)
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
         e.elem_id,
         tipo_comp.elem_det_comp_tipo_id,
         tipo_comp.elem_det_comp_tipo_desc
having sum(comp.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3
-- 4784

-- X UPDATE
-- query per implementare UPDATE delle componenti con importo a zero
-- non variate e non impegnate
select query.elem_code,per.anno::integer,
       tipo.elem_det_comp_tipo_desc,
       comp.elem_det_importo,
       det.elem_Det_importo,
       query.elem_id

from  siac_t_bil_elem_det det ,siac_t_periodo per,
      siac_d_bil_elem_det_comp_tipo tipo,siac_t_bil_elem_det_comp comp,
(
select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
       e.elem_id,
       tipo_comp.elem_det_comp_tipo_id,
	   tipo_comp.elem_det_comp_tipo_desc,
       sum(comp.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
--and   e.elem_code::integer=100010
and not exists
(
select 1
from siac_t_bil_elem_det_comp comp_comp,
     siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
and   dvar.elem_id=e.elem_id
and   comp_comp.data_cancellazione is null
and   dvar_comp.data_cancellazione is null
and   dvar.data_cancellazione is null
)
and not exists
(
select 1
from siac_r_movgest_bil_elem re
where  re.elem_id=e.elem_id
and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and    re.data_cancellazione is null
)
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
         e.elem_id,
         tipo_comp.elem_det_comp_tipo_id,
         tipo_comp.elem_det_comp_tipo_desc
having sum(comp.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3
) query
where tipo.ente_proprietario_id=2
and   comp.elem_Det_comp_tipo_id=tipo.elem_det_comp_tipo_id
and   det.elem_Det_id=comp.elem_det_id
and   per.periodo_id=det.periodo_id
and   query.elem_id=det.elem_id
and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
and   det.data_cancellazione is null
and   comp.data_cancellazione is null
order by query.elem_code,per.anno::integer,
         tipo.elem_det_comp_tipo_desc
-- 14352
-- select 14352/3=4784

with
comp_to_del as
(

select query.elem_code,per.anno::integer anno,
       tipo.elem_det_comp_tipo_desc,
       comp.elem_det_importo,
       det.elem_Det_importo,
       query.elem_id

from  siac_t_bil_elem_det det ,siac_t_periodo per,
      siac_d_bil_elem_det_comp_tipo tipo,siac_t_bil_elem_det_comp comp,
(
select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
       e.elem_id,
       tipo_comp.elem_det_comp_tipo_id,
	   tipo_comp.elem_det_comp_tipo_desc,
       sum(comp.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
--and   e.elem_code::integer=100010
and not exists
(
select 1
from siac_t_bil_elem_det_comp comp_comp,
     siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
and   dvar.elem_id=e.elem_id
and   comp_comp.data_cancellazione is null
and   dvar_comp.data_cancellazione is null
and   dvar.data_cancellazione is null
)
and not exists
(
select 1
from siac_r_movgest_bil_elem re
where  re.elem_id=e.elem_id
and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and    re.data_cancellazione is null
)
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
         e.elem_id,
         tipo_comp.elem_det_comp_tipo_id,
         tipo_comp.elem_det_comp_tipo_desc
having sum(comp.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3
) query
where tipo.ente_proprietario_id=2
and   comp.elem_Det_comp_tipo_id=tipo.elem_det_comp_tipo_id
and   det.elem_Det_id=comp.elem_det_id
and   per.periodo_id=det.periodo_id
and   query.elem_id=det.elem_id
and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
and   det.data_cancellazione is null
and   comp.data_cancellazione is null
order by query.elem_code,per.anno::integer,
         tipo.elem_det_comp_tipo_desc
),
comp_cap as
(
select det.elem_id, sum(comp.elem_det_importo) elem_det_importo_comp
from siac_t_bil_elem_det det,siac_t_bil_elem_det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo
where tipo.ente_proprietario_id=2
and   comp.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
and   det.elem_det_id=comp.elem_det_id
and   comp.data_cancellazione is null
and   det.data_cancellazione is null
group by det.elem_id
)
select comp_to_del.*, coalesce(comp_cap.elem_det_importo_comp,0)
from comp_to_del left join comp_cap on (comp_to_del.elem_id=comp_cap.elem_id)
order by comp_to_del.elem_code,comp_to_del.anno,
       comp_to_del.elem_det_comp_tipo_desc


---- UPDATE
-- 14352
rollback;
begin;
update siac_t_bil_elem_det_comp comp
set    data_cancellazione=now(),
       login_operazione=comp.login_operazione ||'-INVALIDA COMP ZERO-SIAC-7495'
from  siac_t_bil_elem_det det ,siac_t_periodo per,
      siac_d_bil_elem_det_comp_tipo tipo,
(
select anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
       e.elem_id,
       tipo_comp.elem_det_comp_tipo_id,
	   tipo_comp.elem_det_comp_tipo_desc,
       sum(comp.elem_det_importo)
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
     siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
where tipo.ente_proprietario_id=2
and   tipo.elem_tipo_code='CAP-UP'
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   anno.anno_bilancio=2021
and   det.elem_id=e.elem_id
and   comp.elem_det_id=det.elem_det_id
and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
and   per.periodo_id=det.periodo_id
--and   e.elem_code::integer=100010
and not exists
(
select 1
from siac_t_bil_elem_det_comp comp_comp,
     siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
and   dvar.elem_id=e.elem_id
and   comp_comp.data_cancellazione is null
and   dvar_comp.data_cancellazione is null
and   dvar.data_cancellazione is null
)
and not exists
(
select 1
from siac_r_movgest_bil_elem re
where  re.elem_id=e.elem_id
and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
and    re.data_cancellazione is null
)
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   det.validita_fine is null
and   comp.data_cancellazione is null
and   comp.validita_fine is null
and   tipo_comp.data_cancellazione is null
group by anno.anno_bilancio, tipo.elem_tipo_code,e.elem_code::integer,
         e.elem_id,
         tipo_comp.elem_det_comp_tipo_id,
         tipo_comp.elem_det_comp_tipo_desc
having sum(comp.elem_det_importo)=0
order by anno.anno_bilancio, tipo.elem_tipo_code,3
) query
where tipo.ente_proprietario_id=2
and   comp.elem_Det_comp_tipo_id=tipo.elem_det_comp_tipo_id
and   det.elem_Det_id=comp.elem_det_id
and   per.periodo_id=det.periodo_id
and   query.elem_id=det.elem_id
and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
and   det.data_cancellazione is null
and   comp.data_cancellazione is null