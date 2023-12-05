/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select r.ente_proprietario_id, anno.anno_bilancio, fase.fase_operativa_code,r.bil_id
from siac_r_bil_fase_operativa r,siac_d_fase_operativa fase, siac_v_bko_anno_bilancio anno
where fase.ente_proprietario_id=3
and   r.fase_operativa_id = fase.fase_operativa_id
and   anno.bil_id=r.bil_id
order by r.ente_proprietario_id, anno.anno_bilancio
--2019


select *
from version_control

select p.bil_id, p.programma_tipo_id, p.*
from siac_t_programma p
where p.ente_proprietario_id=3
-- 9336


select p.bil_id, tipo.programma_tipo_code, p.*
from siac_t_programma p,siac_d_programma_tipo tipo
where p.ente_proprietario_id=3
and   tipo.programma_tipo_id=p.programma_tipo_id

select p.bil_id, anno.anno_bilancio,tipo.programma_tipo_code, p.*
from siac_t_programma p,siac_d_programma_tipo tipo,siac_v_bko_anno_bilancio anno
where p.ente_proprietario_id=3
and   tipo.programma_tipo_id=p.programma_tipo_id
and   anno.bil_Id=p.bil_Id

select p.bil_id, p.programma_tipo_id, p.*
from siac_t_programma p
where p.ente_proprietario_id=3
and   p.programma_tipo_id is null

select p.bil_id, p.programma_tipo_id, p.*
from siac_t_programma p
where p.ente_proprietario_id=3
and   p.bil_id is null


--- con cronoprogramma
with
progr as
(
select  *
from siac_t_programma p
where p.ente_proprietario_id=3
and   p.bil_id is null
),
cronop as
(
select c.ente_proprietario_id,c.programma_id, max(per.anno::integer) anno_bilancio
from siac_t_cronop c, siac_t_bil bil,siac_t_periodo per
where c.ente_proprietario_id=3
and   bil.bil_id=c.bil_id
and   per.periodo_id=bil.periodo_id
group by c.programma_id,c.ente_proprietario_id
)
select cronop.anno_bilancio, bil.bil_id, progr.*
from progr,cronop , siac_t_bil bil,siac_t_periodo per
where cronop.programma_id=progr.programma_id
and   cronop.ente_proprietario_id=progr.ente_proprietario_id
and   per.ente_proprietario_id=cronop.ente_proprietario_id
and   per.anno::integer=cronop.anno_bilancio
and   bil.periodo_id=per.periodo_id
order by 1
-- 204
-- 2019 138

--- senza cronoprogramma
with
progr as
(
select   p.*
from siac_t_programma p
where p.ente_proprietario_id=3
and   p.bil_id is null
)
select progr.*
from progr
where
not exists (select 1 from siac_t_cronop c where c.programma_id=progr.programma_id)
-- 9132

select per.anno::integer, tipo.programma_tipo_code, p.*
from siac_t_programma p,siac_t_bil bil , siac_t_periodo per,
     siac_d_programma_tipo tipo
where p.ente_proprietario_id=3
and   tipo.programma_tipo_id=p.programma_tipo_id
and   bil.bil_id=p.bil_id
and   per.periodo_id=bil.periodo_id
order by per.anno::integer


select p.ente_proprietario_id,p.bil_id,anno.ente_proprietario_id,anno.anno_bilancio, tipo.programma_tipo_code, count(*)
from siac_t_programma p,siac_d_programma_tipo tipo,siac_v_bko_anno_bilancio anno,
     siac_r_programma_stato rs,siac_d_programma_stato stato
where p.ente_proprietario_id =3
and   tipo.programma_tipo_id=p.programma_tipo_id
and   anno.bil_id=p.bil_id
and   rs.programma_id=p.programma_id
and   stato.programma_stato_id=rs.programma_stato_id
and   stato.programma_stato_code='VA'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   p.data_cancellazione is null
and   p.validita_fine is null
group by p.ente_proprietario_id,p.bil_id,anno.ente_proprietario_id, tipo.programma_tipo_code, anno.anno_bilancio

-- 8700

------------- UPDATE
-- tipo_programma P
begin;
update siac_t_programma p
set    programma_tipo_id=tipo.programma_tipo_id,
       data_modifica=now(),
       login_operazione=p.login_operazione||'-SIAC-6255'
from siac_d_programma_tipo tipo
where tipo.ente_proprietario_id=3
and   tipo.programma_tipo_code='P'
and   p.ente_proprietario_id=tipo.ente_proprietario_id
and   p.programma_tipo_id is null;
-- 9336

-- bil_id con cronoprogramma
rollback;
begin;
update siac_t_programma pUPD
set    bil_id=query.bil_id,
       data_modifica=now(),
       login_operazione=pUPD.login_operazione||'-SIAC-6255'
from
(
with
progr as
(
select  *
from siac_t_programma p
where p.ente_proprietario_id=3
and   p.bil_id is null
),
cronop as
(
select c.ente_proprietario_id,c.programma_id, max(per.anno::integer) anno_bilancio
from siac_t_cronop c, siac_t_bil bil,siac_t_periodo per
where c.ente_proprietario_id=3
and   bil.bil_id=c.bil_id
and   per.periodo_id=bil.periodo_id
group by c.programma_id,c.ente_proprietario_id
)
select  cronop.anno_bilancio, bil.bil_id, progr.programma_id
from progr,cronop , siac_t_bil bil,siac_t_periodo per
where cronop.programma_id=progr.programma_id
and   cronop.ente_proprietario_id=progr.ente_proprietario_id
and   per.ente_proprietario_id=cronop.ente_proprietario_id
and   per.anno::integer=cronop.anno_bilancio
and   bil.periodo_id=per.periodo_id
) query
where pUPD.ente_proprietario_id=3
and   pUPD.programma_id=query.programma_id
and   pUPD.bil_id is null;

-- bil_id senza cronoprogramma
rollback;
begin;
update siac_t_programma pUPD
set    bil_id=query.bil_id,
       data_modifica=now(),
       login_operazione=pUPD.login_operazione||'-SIAC-6255'
from
(
with
progr as
(
select  bil.bil_id,per.anno::integer anno_bilancio, p.programma_id
from siac_t_programma p,siac_t_periodo per, siac_t_bil bil
where p.ente_proprietario_id=3
and   p.bil_id is null
and   per.ente_proprietario_id=p.ente_proprietario_id
and   per.anno::integer=2019
and   bil.periodo_id=per.periodo_id
)
select progr.*
from progr
where
not exists (select 1 from siac_t_cronop c where c.programma_id=progr.programma_id)
)
query
where pUPD.ente_proprietario_id=3
and   pUPD.programma_id=query.programma_id
and   pUPD.bil_id is null;

-------------------------------------------------
-- ribaltamento da P a G dei dati 2019

begin;
select
fnc_fasi_bil_gest_apertura_programmi
(
  2019,
  3,
  'G',
  'SIAC-6255',
  now()::timestamp
);


------------- movimenti

---- impegni 2019 collegati a programmi

select mov.movgest_anno, mov.movgest_numero,
       (case when tipots.movgest_Ts_tipo_code='T'  then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
       stato.movgest_stato_code,tipop.programma_tipo_code,p.*
from siac_r_movgest_ts_programma r,
     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
     siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_programma p,siac_d_programma_tipo tipop
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   bil.bil_id=mov.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_Ts_tipo_id=ts.movgest_ts_tipo_id
and   r.movgest_ts_id=ts.movgest_ts_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   p.programma_id=r.programma_id
and   tipop.programma_tipo_id=p.programma_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
order by 1,2,3
-- 11424

-- impegni 2019 collegati a programmi con equivalente programma gestione 2019
with
impegno as
(
select mov.movgest_anno, mov.movgest_numero,
       (case when tipots.movgest_Ts_tipo_code='T'  then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
       stato.movgest_stato_code,p.programma_code, p.programma_id
from siac_r_movgest_ts_programma r,
     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
     siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_programma p
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   bil.bil_id=mov.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_Ts_tipo_id=ts.movgest_ts_tipo_id
and   r.movgest_ts_id=ts.movgest_ts_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   p.programma_id=r.programma_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   p.data_cancellazione is null
and   p.validita_fine is null
order by 1,2,3
),
progr as
(
select p.programma_code, p.programma_id
from siac_t_programma p, siac_d_programma_tipo tipo, siac_t_bil bil,siac_t_periodo per
where tipo.ente_proprietario_id=3
and   tipo.programma_tipo_code='G'
and   p.programma_tipo_id=tipo.programma_tipo_id
and   bil.bil_id=p.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   p.data_cancellazione is null
and   p.validita_fine is null
)
select impegno.movgest_anno, impegno.movgest_numero,
       impegno.movgest_subnumero,
       impegno.movgest_stato_code,
       impegno.programma_code,
       progr.programma_id
from impegno, progr
where progr.programma_code=impegno.programma_code
order by 1,2,3
-- 10825
--- aggiornamento collegamento impegni

-- inserimento nuove rel.
rollback;
begin;
insert into siac_r_movgest_ts_programma
(
	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select query.movgest_ts_id,
	   query.programma_id,
       now(),
       'SIAC-6255',
       query.ente_proprietario_id
from
(
with
impegno as
(
select mov.movgest_anno, mov.movgest_numero,
       (case when tipots.movgest_Ts_tipo_code='T'  then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
       stato.movgest_stato_code,p.programma_code,
       p.programma_id programma_old_id,
       ts.movgest_ts_id,
       ts.ente_proprietario_id
from siac_r_movgest_ts_programma r,
     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
     siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_programma p
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   bil.bil_id=mov.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_Ts_tipo_id=ts.movgest_ts_tipo_id
and   r.movgest_ts_id=ts.movgest_ts_id
and   r.login_operazione not like '%SIAC-6255%'
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   p.programma_id=r.programma_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   p.data_cancellazione is null
and   p.validita_fine is null
order by 1,2,3
),
progr as
(
select p.programma_code, p.programma_id
from siac_t_programma p, siac_d_programma_tipo tipo, siac_t_bil bil,siac_t_periodo per
where tipo.ente_proprietario_id=3
and   tipo.programma_tipo_code='G'
and   p.programma_tipo_id=tipo.programma_tipo_id
and   bil.bil_id=p.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   p.data_cancellazione is null
and   p.validita_fine is null
)
select impegno.movgest_ts_id,
	   impegno.programma_old_id,
       progr.programma_id,
       impegno.ente_proprietario_id
from impegno, progr
where progr.programma_code=impegno.programma_code
) query;


-- chiusura vecchie

begin;
update siac_r_movgest_ts_programma rUPD
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=rUPD.login_operazione
from
(
with
impegno as
(
select mov.movgest_anno, mov.movgest_numero,
       (case when tipots.movgest_Ts_tipo_code='T'  then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
       stato.movgest_stato_code,p.programma_code, p.programma_id,
       r.movgest_ts_programma_id
from siac_r_movgest_ts_programma r,
     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
     siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_programma p
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   bil.bil_id=mov.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_Ts_tipo_id=ts.movgest_ts_tipo_id
and   r.movgest_ts_id=ts.movgest_ts_id
and   r.login_operazione not like '%SIAC-6255%'
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   p.programma_id=r.programma_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   p.data_cancellazione is null
and   p.validita_fine is null
order by 1,2,3
)
select impegno.movgest_ts_programma_id
from impegno
) query
where rUPD.movgest_ts_programma_id=query.movgest_ts_programma_id
and   rUPD.data_cancellazione is null
and   rUPD.validita_fine is null;

-- accertamenti 2019 associati a programmi
select mov.movgest_anno, mov.movgest_numero,
       (case when tipots.movgest_Ts_tipo_code='T'  then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
       stato.movgest_stato_code,tipop.programma_tipo_code,p.*
from siac_r_movgest_ts_programma r,
     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
     siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_programma p,siac_d_programma_tipo tipop
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='A'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   bil.bil_id=mov.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_Ts_tipo_id=ts.movgest_ts_tipo_id
and   r.movgest_ts_id=ts.movgest_ts_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   p.programma_id=r.programma_id
and   tipop.programma_tipo_id=p.programma_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
order by 1,2,3
--749
-- accertamenti 2019 collegati a programmi con equivalente programma gestione 2019
with
impegno as
(
select mov.movgest_anno, mov.movgest_numero,
       (case when tipots.movgest_Ts_tipo_code='T'  then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
       stato.movgest_stato_code,p.programma_code, p.programma_id
from siac_r_movgest_ts_programma r,
     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
     siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_programma p
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='A'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   bil.bil_id=mov.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_Ts_tipo_id=ts.movgest_ts_tipo_id
and   r.movgest_ts_id=ts.movgest_ts_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   p.programma_id=r.programma_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   p.data_cancellazione is null
and   p.validita_fine is null
order by 1,2,3
),
progr as
(
select p.programma_code, p.programma_id
from siac_t_programma p, siac_d_programma_tipo tipo, siac_t_bil bil,siac_t_periodo per
where tipo.ente_proprietario_id=3
and   tipo.programma_tipo_code='G'
and   p.programma_tipo_id=tipo.programma_tipo_id
and   bil.bil_id=p.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   p.data_cancellazione is null
and   p.validita_fine is null
)
select impegno.movgest_anno, impegno.movgest_numero,
       impegno.movgest_subnumero,
       impegno.movgest_stato_code,
       impegno.programma_code,
       progr.programma_id
from impegno, progr
where progr.programma_code=impegno.programma_code
order by 1,2,3
-- 665


--- aggiornamento collegamento accertamenti

-- inserimento nuove rel.
rollback;
begin;
insert into siac_r_movgest_ts_programma
(
	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select query.movgest_ts_id,
	   query.programma_id,
       now(),
       'SIAC-6255',
       query.ente_proprietario_id
from
(
with
impegno as
(
select mov.movgest_anno, mov.movgest_numero,
       (case when tipots.movgest_Ts_tipo_code='T'  then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
       stato.movgest_stato_code,p.programma_code,
       p.programma_id programma_old_id,
       ts.movgest_ts_id,
       ts.ente_proprietario_id
from siac_r_movgest_ts_programma r,
     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
     siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_programma p
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='A'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   bil.bil_id=mov.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_Ts_tipo_id=ts.movgest_ts_tipo_id
and   r.movgest_ts_id=ts.movgest_ts_id
and   r.login_operazione not like '%SIAC-6255%'
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   p.programma_id=r.programma_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   p.data_cancellazione is null
and   p.validita_fine is null
order by 1,2,3
),
progr as
(
select p.programma_code, p.programma_id
from siac_t_programma p, siac_d_programma_tipo tipo, siac_t_bil bil,siac_t_periodo per
where tipo.ente_proprietario_id=3
and   tipo.programma_tipo_code='G'
and   p.programma_tipo_id=tipo.programma_tipo_id
and   bil.bil_id=p.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   p.data_cancellazione is null
and   p.validita_fine is null
)
select impegno.movgest_ts_id,
	   impegno.programma_old_id,
       progr.programma_id,
       impegno.ente_proprietario_id
from impegno, progr
where progr.programma_code=impegno.programma_code
) query;


-- chiusura vecchie

begin;
update siac_r_movgest_ts_programma rUPD
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=rUPD.login_operazione
from
(
with
impegno as
(
select mov.movgest_anno, mov.movgest_numero,
       (case when tipots.movgest_Ts_tipo_code='T'  then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
       stato.movgest_stato_code,p.programma_code, p.programma_id,
       r.movgest_ts_programma_id
from siac_r_movgest_ts_programma r,
     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
     siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_programma p
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='A'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   bil.bil_id=mov.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2019
and   ts.movgest_id=mov.movgest_id
and   tipots.movgest_Ts_tipo_id=ts.movgest_ts_tipo_id
and   r.movgest_ts_id=ts.movgest_ts_id
and   r.login_operazione not like '%SIAC-6255%'
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   p.programma_id=r.programma_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   p.data_cancellazione is null
and   p.validita_fine is null
order by 1,2,3
)
select impegno.movgest_ts_programma_id
from impegno
) query
where rUPD.movgest_ts_programma_id=query.movgest_ts_programma_id
and   rUPD.data_cancellazione is null
and   rUPD.validita_fine is null;