/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select anno.anno_bilancio, tipo.programma_tipo_code, p.*
from siac_t_programma p,siac_d_programma_tipo tipo,
     siac_v_bko_anno_bilancio anno
where p.ente_proprietario_id =2
and   tipo.programma_tipo_id=p.programma_tipo_id
and   anno.bil_id=p.bil_id
and   anno.anno_bilancio=2020
and   p.data_cancellazione is null
and   p.validita_fine is null
order by  1,2


select per.anno, tipo.programma_tipo_code, p.*
from siac_t_programma p,siac_d_programma_tipo tipo,
     siac_t_bil anno,siac_t_periodo per
where p.ente_proprietario_id =2
and   tipo.programma_tipo_id=p.programma_tipo_id
and   anno.bil_id=p.bil_id
and   per.periodo_id=anno.periodo_id
--and   per.anno::integer=2020
and   p.programma_id in (597, 615)
and   p.data_cancellazione is null
and   p.validita_fine is null
order by  1,2

select *
from fase_bil_t_elaborazione fase
where fase.ente_proprietario_id=2
order by fase.fase_bil_elab_id desc

select per.anno, fase.fase_operativa_code
from siac_r_bil_fase_operativa r,siac_d_fase_operativa fase,  siac_t_bil anno,siac_t_periodo per
where fase.ente_proprietario_id=2
and   fase.fase_operativa_id=r.fase_operativa_id
and   anno.bil_id=r.bil_id
and   per.periodo_id=anno.periodo_id
order by per.anno

select tipo.elem_tipo_code , count(*)
from siac_t_bil anno,siac_t_periodo per, siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato
where tipo.ente_proprietario_id=2
and   e.elem_tipo_id=tipo.elem_tipo_id
and   anno.bil_id=e.bil_id
and   per.periodo_id=anno.periodo_id
and   per.anno::integer=2020
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   stato.elem_stato_code!='AN'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   e.data_cancellazione is null
group by tipo.elem_tipo_code

begin;
select
fnc_fasi_bil_gest_apertura_all
(
  2020,
  'E',
  99,
  true,
  true,
  2,
  'test',
  now()::timestamp
)

select *
from fase_bil_t_elaborazione_log log
where log.ente_proprietario_id=2
and   log.fase_bil_elab_id=121
order by log.fase_bil_elab_log_id


begin;
select
fnc_fasi_bil_gest_apertura_pluri
(
  2,
  2020,
  'test',
  now()::timestamp
)

select count(*)
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='A'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_anno>anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
-- 83
-- 177

select mov.movgest_anno, mov.movgest_numero, tipop.programma_tipo_code, prog.*
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts_programma rp,siac_t_programma prog, siac_d_programma_tipo tipop
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_anno>anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   rp.movgest_ts_id=ts.movgest_ts_id
and   prog.programma_id=rp.programma_id
and   tipop.programma_tipo_id=prog.programma_tipo_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
and   rp.data_cancellazione is null
and   rp.validita_fine is null
and   prog.data_cancellazione is null
and   prog.validita_fine is null


select count(*)
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
where tipo.ente_proprietario_id=2
--and   tipo.movgest_tipo_code='I'
and   tipo.movgest_tipo_code='A'

and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2020
and   mov.movgest_anno>=anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null

select mov.movgest_anno, mov.movgest_numero, rst.*
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts_storico_imp_acc rst
where tipo.ente_proprietario_id=2
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2020
and   mov.movgest_anno>=anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   rst.movgest_ts_id=ts.movgest_ts_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null


select mov.movgest_anno, mov.movgest_numero, rp.*
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts_programma rp
where tipo.ente_proprietario_id=2
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2020
and   mov.movgest_anno>=anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   rp.movgest_ts_id=ts.movgest_ts_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null

select mov.movgest_anno, mov.movgest_numero, acc.*
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts r, siac_v_bko_accertamento_valido acc
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
--and   mov.movgest_anno>anno.anno_bilancio
and   mov.movgest_anno=anno.anno_bilancio

and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   r.movgest_ts_b_id=ts.movgest_ts_id
and   acc.movgest_ts_id=r.movgest_ts_a_id
--and   mov.movgest_anno::integer=2021
--and   mov.movgest_numero::integer in (5,6)
and   mov.movgest_anno::integer=2019
and   mov.movgest_numero::integer =491

and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
order by 1,2


select imp.movgest_anno, imp.movgest_numero, r.*
from siac_r_movgest_ts_storico_imp_acc r,siac_v_bko_impegno_valido imp
where r.ente_proprietario_id=2
and   imp.movgest_ts_id=r.movgest_ts_id

select * from siac_r_movgest_ts_storico_imp_acc
insert into siac_r_movgest_ts_storico_imp_acc
(
  movgest_ts_id,
  movgest_anno_acc,
  movgest_numero_acc,
  movgest_subnumero_acc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select ts.movgest_ts_id,
       acc.movgest_anno,
       acc.movgest_numero,
       acc.movgest_subnumero,
       now(),
       'test',
       ts.ente_proprietario_id
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts r, siac_v_bko_accertamento_valido acc
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_anno>anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   r.movgest_ts_b_id=ts.movgest_ts_id
and   acc.movgest_ts_id=r.movgest_ts_a_id
and   mov.movgest_anno::integer=2021
and   mov.movgest_numero::integer in (5,6)
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null

insert into siac_r_movgest_ts_storico_imp_acc
(
  movgest_ts_id,
  movgest_anno_acc,
  movgest_numero_acc,
  movgest_subnumero_acc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select ts.movgest_ts_id,
       acc.movgest_anno,
       acc.movgest_numero,
       acc.movgest_subnumero,
       now(),
       'test',
       ts.ente_proprietario_id
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts r, siac_v_bko_accertamento_valido acc
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_anno=anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   r.movgest_ts_b_id=ts.movgest_ts_id
and   acc.movgest_ts_id=r.movgest_ts_a_id
and   mov.movgest_anno::integer=2019
--and   mov.movgest_numero::integer =491
and   mov.movgest_numero::integer =783

and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null

insert into siac_r_movgest_ts_storico_imp_acc
(
  movgest_ts_id,
  movgest_anno_acc,
  movgest_numero_acc,
  movgest_subnumero_acc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select ts.movgest_ts_id,
       2018,
       2407,
       0,
       now(),
       'test',
       ts.ente_proprietario_id
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_anno=anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   mov.movgest_anno::integer=2019
and   mov.movgest_numero::integer =786

and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null


select mov.movgest_anno, mov.movgest_numero
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
--and   anno.anno_bilancio=2019
--and   mov.movgest_anno<=anno.anno_bilancio
and   anno.anno_bilancio=2020
and   mov.movgest_anno<anno.anno_bilancio

and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null


select mov.movgest_anno, mov.movgest_numero, r.*
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts_storico_imp_acc r
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_anno<=anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   r.movgest_ts_id=ts.movgest_ts_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null

select mov.movgest_anno, mov.movgest_numero, r.*
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts_storico_imp_acc r
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2020
--and   mov.movgest_anno<=anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   r.movgest_ts_id=ts.movgest_ts_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null


select mov.movgest_anno, mov.movgest_numero, r.*
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts_storico_imp_acc r
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_anno<=anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   r.movgest_ts_id=ts.movgest_ts_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null

select mov.movgest_anno, mov.movgest_numero, r.*
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts_programma r
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
--and   anno.anno_bilancio=2019
--and   mov.movgest_anno<=anno.anno_bilancio
and   anno.anno_bilancio=2020
and   mov.movgest_anno<anno.anno_bilancio

and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   r.movgest_ts_id=ts.movgest_ts_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null


select mov.movgest_anno, mov.movgest_numero, r.*
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts_programma r
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
--and   anno.anno_bilancio=2019
and   anno.anno_bilancio=2020
--and   mov.movgest_anno<=anno.anno_bilancio
and   mov.movgest_anno<anno.anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   r.movgest_ts_id=ts.movgest_ts_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null

rollback;
begin;
select
fnc_fasi_bil_gest_apertura_imp
(
  2020,
  2,
  'test',
  now()::timestamp
)


select mov.movgest_anno, mov.movgest_numero,ts.movgest_ts_code
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='A'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
/*and   anno.anno_bilancio=2019
and   mov.movgest_anno<=anno.anno_bilancio*/
and   anno.anno_bilancio=2020
and   mov.movgest_anno<anno.anno_bilancio

and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
order by 1,2

select mov.bil_id, p.bil_id,p.programma_id,mov.movgest_anno, mov.movgest_numero,ts.movgest_ts_code,
       tipop.programma_tipo_code, p.*
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_r_movgest_ts_programma rp, siac_t_programma p,siac_d_programma_tipo tipop
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='A'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_anno<=anno.anno_bilancio
/*and   anno.anno_bilancio=2020
and   mov.movgest_anno<anno.anno_bilancio*/

and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   rp.movgest_ts_id=ts.movgest_ts_id
and   p.programma_id=rp.programma_id
and   tipop.programma_tipo_id=p.programma_tipo_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null
and   rp.data_cancellazione is null
and   rp.validita_fine is null

order by 1,2

-- 597, 615


-- 5153
rollback;
begin;
select
fnc_fasi_bil_gest_apertura_acc
(
  2020,
  2,
  'test',
  now()::timestamp
)
begin;
insert into siac_r_movgest_ts_programma
(
	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select ts.movgest_ts_id,
       p.programma_id,
       now(),
       'test',
       p.ente_proprietario_id
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_programma p
where tipo.ente_proprietario_id=2
and   tipo.movgest_tipo_code='A'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_anno<=anno.anno_bilancio
/*and   anno.anno_bilancio=2020
and   mov.movgest_anno<anno.anno_bilancio*/
and   mov.movgest_anno=2019
and   mov.movgest_numero in (149,150)
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   p.programma_id in (597, 615)

and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   Ts.validita_fine is null


select r.*
from siac_r_movgest_ts r, siac_v_bko_impegno_valido imp
where imp.ente_proprietario_id=2
and   imp.anno_bilancio=2019
and   r.movgest_ts_b_id=imp.movgest_ts_id
and   r.data_cancellazione is null
and   r.validita_fine is null
-- 128
select r.*
from siac_r_movgest_ts r, siac_v_bko_impegno_valido imp
where imp.ente_proprietario_id=2
and   imp.anno_bilancio=2020
and   r.movgest_ts_b_id=imp.movgest_ts_id
and   r.data_cancellazione is null
and   r.validita_fine is null

select r.*
from siac_r_movgest_ts r
where r.ente_proprietario_id=2
and   r.data_cancellazione is null
and   r.validita_fine is null
-- 6591
--6603
select imp.anno_bilancio,imp.movgest_anno, imp.movgest_numero, r.*
from siac_r_movgest_ts_storico_imp_acc r,siac_v_bko_impegno_valido imp
where r.ente_proprietario_id=2
and   imp.movgest_ts_id=r.movgest_ts_id
order by 1,2
-- 24


rollback;
begin;
select
fnc_fasi_bil_gest_apertura_vincoli
(
  2020,
  2,
  false,
  'test-oggi-sofia',
  now()::timestamp)


select  *
from  fase_bil_t_gest_apertura_vincoli fase
where fase.ente_proprietario_id=2
and   fase.fase_bil_elab_id=182;

select *
from siac_r_movgest_ts r
where r.movgest_ts_r_id=15741

select mov.movgest_anno, mov.movgest_numero, imp.movgest_ts_code, stato.movgest_stato_code,mov.*
from siac_t_movgest_Ts imp,siac_t_movgest mov,siac_v_bko_anno_bilancio anno,siac_d_movgest_tipo tipo,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
where mov.ente_proprietario_id=2
and   tipo.movgest_tipo_id=mov.movgest_tipo_id
and   tipo.movgest_tipo_code='I'
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2020
and   mov.movgest_anno::integer<2020
and   mov.movgest_id=imp.movgest_id
and   rs.movgest_ts_id=imp.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
order by 1,2


select mov.movgest_anno, mov.movgest_numero, imp.movgest_ts_code, stato.movgest_stato_code,r.*
from siac_t_movgest_Ts imp,siac_t_movgest mov,siac_v_bko_anno_bilancio anno,siac_d_movgest_tipo tipo,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,siac_r_movgest_ts r
where mov.ente_proprietario_id=2
and   tipo.movgest_tipo_id=mov.movgest_tipo_id
and   tipo.movgest_tipo_code='I'
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_id=imp.movgest_id
and   mov.movgest_anno::integer=2019
and   mov.movgest_numero::integer=795
and   rs.movgest_ts_id=imp.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   r.movgest_ts_b_id=imp.movgest_ts_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null

order by 1,2


and   mov.movgest_anno::integer=2019
and   mov.movgest_numero::integer=795

-- 2019/2
select acc.*
from siac_v_bko_accertamento_valido acc
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2019
and   acc.movgest_anno=2019
and   acc.movgest_numero=2
-- 106926
begin;
insert into siac_r_movgest_ts
(
	movgest_ts_a_id,
    movgest_ts_b_id,
    movgest_ts_importo,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select  106926,
        imp.movgest_ts_id,
        100,
        now(),
        'test',
        imp.ente_proprietario_id
from siac_t_movgest_Ts imp,siac_t_movgest mov,siac_v_bko_anno_bilancio anno,siac_d_movgest_tipo tipo,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
where mov.ente_proprietario_id=2
and   tipo.movgest_tipo_id=mov.movgest_tipo_id
and   tipo.movgest_tipo_code='I'
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2019
and   mov.movgest_id=imp.movgest_id
and   mov.movgest_anno::integer=2019
and   mov.movgest_numero::integer=795
and   rs.movgest_ts_id=imp.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null

select * from siac_r_movgest_ts_storico_imp_acc
-- 27
select * from siac_r_movgest_ts_programma  r
where r.ente_proprietario_id=2
-- 142
select * from siac_r_movgest_ts_cronop_elem r
where r.ente_proprietario_id=2
--97


begin;
select
fnc_fasi_bil_gest_apertura_programmi
(
  2020,
  2,
  'G',
  'test',
  now()::timestamp
)


begin;
select
fnc_fasi_bil_prev_approva_all
(
  2020,
  'G',
  99,
  true,
  true,
  2,
  'test',
  now()::timestamp
)

rollback;
begin;
select
fnc_fasi_bil_gest_reimputa
(
  2,
  2020,
  'test',
  now()::timestamp,
  'I');

-- 125

select attr.attr_code, r.boolean, r.*
    from siac_v_bko_anno_bilancio anno, siac_r_bil_attr r,siac_t_attr attr
    where attr.ente_proprietario_id=2
    and   r.attr_id=attr.attr_id
    and   anno.bil_id=r.bil_id
    and   anno.anno_bilancio=2020

select *
from siac_r_bil_Attr r
where r.bil_attr_id=484

select imp.movgest_ts_id,imp.data_creazione, mov.movgest_anno, mov.movgest_numero, imp.movgest_ts_code, stato.movgest_stato_code
from siac_t_movgest_Ts imp,siac_t_movgest mov,siac_v_bko_anno_bilancio anno,siac_d_movgest_tipo tipo,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
where mov.ente_proprietario_id=2
and   tipo.movgest_tipo_id=mov.movgest_tipo_id
and   tipo.movgest_tipo_code='I'
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2020
and   mov.movgest_id=imp.movgest_id
and   rs.movgest_ts_id=imp.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
order by imp.data_creazione desc


select *
from fase_bil_t_reimputazione fase
where fase.ente_proprietario_id=2
and fase.fasebilelabid=208
-- 125116 , 124871

select *
from siac_v_bko_impegno_valido imp
where imp.movgest_ts_id in (125116 , 124871)

select *
from siac_v_bko_impegno_valido imp,siac_r_movgest_ts_programma r
where imp.movgest_ts_id in (144641 , 144642)
and   r.movgest_ts_id=imp.movgest_ts_id

select *
from siac_r_movgest_ts_storico_imp_acc r
--where r.movgest_ts_id  in (125116 , 124871)
where r.movgest_ts_id  in (144641, 144641)

select *
from siac_r_movgest_ts_cronop_elem r
where r.ente_proprietario_id=2
-- 97

insert into siac_r_movgest_ts_storico_imp_acc
(
	movgest_ts_id,
    movgest_anno_acc,
    movgest_numero_acc,
    movgest_subnumero_acc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select imp.movgest_ts_id,
       2018,
       791,
       0,
       now(),
       'test-sofia',
       imp.ente_proprietario_id
from siac_v_bko_impegno_valido imp
where imp.movgest_ts_id in (125116 , 124871)

select *
from fase_bil_t_reimputazione fase
where fase.ente_proprietario_id=2
and fase.movgest_ts_id  in (125116 , 124871)

insert into siac_r_movgest_ts_programma
(
	programma_id,
	movgest_ts_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select 597,
       imp.movgest_ts_id,
       now(),
       'test-sofia',
       imp.ente_proprietario_id

from siac_v_bko_impegno_valido imp
where imp.movgest_ts_id in (125116 , 124871)

select  anno.anno_bilancio, p.programma_code,stato.cronop_stato_code, cronop.*
from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
     siac_t_programma p,siac_v_bko_anno_bilancio anno
where cronop.programma_id=597
and   rs.cronop_id=cronop.cronop_id
and   stato.cronop_stato_id=rs.cronop_stato_id
and   p.programma_id=597
and   anno.bil_id=p.bil_id
and   cronop.data_cancellazione is null
and   cronop.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null


------------ MAS-2019 01 CR03 è PROVVISORIO dovrebbe essere valido !!

select anno.anno_bilancio , tipo.programma_tipo_code,sc.cronop_stato_code,rsc.data_creazione,c.*
from siac_t_programma p,siac_d_programma_tipo tipo,siac_v_bko_anno_bilancio anno, siac_t_cronop c,
     siac_r_cronop_stato rsc,siac_d_cronop_stato sc
where p.ente_proprietario_id=2
and   p.programma_code='MAS-2019 01'
and   tipo.programma_tipo_id=p.programma_tipo_Id
and   anno.bil_id=p.bil_id
and   c.programma_id=p.programma_id
and   rsc.cronop_id=c.cronop_id
and   sc.cronop_stato_id=rsc.cronop_stato_id
and   p.data_cancellazione is null
and   p.validita_fine is null
and   c.data_cancellazione is null
and   c.validita_fine is null
and   rsc.data_cancellazione is null
and   rsc.validita_fine is null
-- 1334
insert into siac_r_movgest_ts_cronop_elem
(
	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id

)
select imp.movgest_ts_id,
        869,
        now(),
        'test',
        imp.ente_proprietario_id
from siac_v_bko_impegno_valido imp
where imp.movgest_ts_id in (125116 , 124871)

/*
update siac_r_cronop_stato rs
set    cronop_stato_id=
from siac_d_cronop_stato stato*/



select r.*
from siac_v_bko_impegno_valido imp,siac_r_movgest_ts r
where imp.movgest_ts_id in (125116 , 124871)
and   r.movgest_ts_b_id=imp.movgest_ts_id
select *
from siac_t_movgest_ts ts
where ts.movgest_ts_Id=124581
select *
from siac_r_movgest_ts r
where r.ente_proprietario_id=2
order by r.movgest_ts_r_id desc
-- 144643
begin;
select
fnc_fasi_bil_gest_reimputa_vincoli
 (
  2,
  2020,
  'test',
  now()::timestamp
 )