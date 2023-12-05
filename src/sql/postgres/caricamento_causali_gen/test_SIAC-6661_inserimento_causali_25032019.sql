/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿rollback;
begin;
select
fnc_siac_bko_caricamento_causali
(
  2019,
  2,
  'AMBITO_FIN',
   'SIAC-6661',
  now()::timestamp
);

NOTICE:  numeroCausali=240 (260)
NOTICE:  numeroStatoCausali=240
NOTICE:  numeroPdcFinCausali=240
NOTICE:  numeroContiCausali=474 (517)
NOTICE:  numeroContiSEGNOCausali=480
NOTICE:  numeroContiTIPOIMPORTOCausali=474
NOTICE:  numeroContiUTILIZZOCONTOCausali=474
NOTICE:  numeroContiUTILIZZOIMPORTOCausali=474
NOTICE:  numeroCausaliEvento=606 -- ok
NOTICE:  Inserimento causale di generale ambitoCode=AMBITO_FIN. Inserite 240 causali.


NOTICE:  numeroCausali=240
NOTICE:  numeroStatoCausali=240
NOTICE:  numeroPdcFinCausali=240
NOTICE:  numeroContiCausali=474
NOTICE:  numeroContiSEGNOCausali=480
NOTICE:  numeroContiTIPOIMPORTOCausali=474
NOTICE:  numeroContiUTILIZZOCONTOCausali=474
NOTICE:  numeroContiUTILIZZOIMPORTOCausali=474
NOTICE:  numeroCausaliEvento=606
NOTICE:  Inserimento causale di generale ambitoCode=AMBITO_FIN. Inserite 240 causali.


select count(*)
from siac_bko_t_caricamento_causali bko
where caricata=false
-- 523
-- 480

select distinct bko.codice_causale
from siac_bko_t_caricamento_causali bko
where caricata=false
-- 260
-- 240

select distinct bko.codice_causale, bko.pdc_econ_patr
from siac_bko_t_caricamento_causali bko
where caricata=false
-- 517 causale-conti
-- 474 causale-conti
select distinct bko.codice_causale, bko.pdc_econ_patr,bko.segno
from siac_bko_t_caricamento_causali bko
where caricata=false
-- 480


select  *
from siac_bko_t_causale_evento bko
-- 665

select  distinct bko.codice_causale, bko.evento--,bko.eu
from siac_bko_t_causale_evento bko
where  exists
(select 1 from siac_bko_t_caricamento_causali c
where c.caricata=false
and   c.codice_causale=bko.codice_causale)
-- 609

select distinct bko.codice_causale
from siac_bko_t_caricamento_causali bko
where not exists
(select 1 from siac_t_causale_ep ep
 where ep.ente_proprietario_id=2
 and   ep.causale_ep_code=bko.codice_causale
 and   ep.login_operazione   like '%SIAC-6661%')

select *
from siac_t_causale_ep ep
where ep.ente_proprietario_id=2
and   ep.login_operazione  like '%SIAC-6661%'
-- 240

select *
from siac_r_causale_ep_stato r
where r.ente_proprietario_id=2
and   r.login_operazione  like '%SIAC-6661%'

select *
from siac_r_causale_ep_class r
where r.ente_proprietario_id=2
and   r.login_operazione  like '%SIAC-6661%'


select *
from siac_r_causale_ep_pdce_conto r
where r.ente_proprietario_id=2
and   r.login_operazione  like '%SIAC-6661%'

select *
from siac_r_causale_ep_pdce_conto_oper r
where r.ente_proprietario_id=2
and   r.login_operazione  like '%SIAC-6661%'

select *
from siac_r_evento_causale r
where r.ente_proprietario_id=2
and   r.login_operazione  like '%SIAC-6661%'



select distinct bko.codice_causale
from siac_bko_t_caricamento_causali bko
where  exists
(select 1 from siac_t_causale_ep ep
 where ep.ente_proprietario_id=2
 and   ep.causale_ep_code=bko.codice_causale
 and   ep.login_operazione  not like '%SIAC-6661%'
)
-- 20
select distinct ep.causale_ep_code, ambito.ambito_code, ep.login_operazione
from siac_bko_t_caricamento_causali bko, siac_t_causale_ep ep,siac_d_ambito ambito
where ep.ente_proprietario_id=2
 and   ep.causale_ep_code=bko.codice_causale
 and   ambito.ambito_id=ep.ambito_id
 and   ep.data_cancellazione is null
 and   ep.validita_fine is null

select bko.*
from siac_bko_t_caricamento_causali bko, siac_t_causale_ep ep,siac_d_ambito ambito
where ep.ente_proprietario_id=2
 and   ep.causale_ep_code=bko.codice_causale
 and   ambito.ambito_id=ep.ambito_id
 -- 43
 begin;
 update siac_bko_t_caricamento_causali bko
 set    caricata=true
 from siac_t_causale_ep ep
 where ep.ente_proprietario_id=2
 and   ep.causale_ep_code=bko.codice_causale

-----------------------

select *
from  siac_bko_t_caricamento_causali bko
where bko.codice_causale like '%U.2.02.04.07.005%'
-- 35

--queste invece sono sbagliate sul file
-- ORD-U.3.01.0105.001
--ORD-U.3.01.0105.002
--ORD-U.3.01.0105.003

select distinct bko.codice_causale
from  siac_bko_t_caricamento_causali bko
where bko.codice_causale in
(
'ORD-U.3.01.0105.001',
'ORD-U.3.01.0105.002',
'ORD-U.3.01.0105.003'
)


select  bko.caricata,ep.causale_ep_code,stato.causale_ep_stato_code,ambito.ambito_code,ep.validita_inizio,
        bko.*
from  siac_bko_t_caricamento_causali bko,siac_t_causale_ep ep,siac_r_causale_ep_stato rs,siac_d_causale_ep_stato stato,
     siac_d_ambito ambito
where bko.codice_causale in
(
'ORD-U.3.01.0105.001',
'ORD-U.3.01.0105.002',
'ORD-U.3.01.0105.003'
)
and   ep.ente_proprietario_id=2
and   ep.causale_ep_code=bko.codice_causale
and   rs.causale_ep_id=ep.causale_ep_id
and   stato.causale_ep_stato_id=rs.causale_ep_stato_id
and   ambito.ambito_id=ep.ambito_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null


select distinct bko.caricata,ep.causale_ep_code,stato.causale_ep_stato_code,ambito.ambito_code,ep.validita_inizio
from  siac_bko_t_caricamento_causali bko,siac_t_causale_ep ep,siac_r_causale_ep_stato rs,siac_d_causale_ep_stato stato,
     siac_d_ambito ambito
where bko.codice_causale like '%U.2.02.04.07.005%'
and   ep.ente_proprietario_id=2
and   ep.causale_ep_code=bko.codice_causale
and   rs.causale_ep_id=ep.causale_ep_id
and   stato.causale_ep_stato_id=rs.causale_ep_stato_id
and   ambito.ambito_id=ep.ambito_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null

rollback;
begin;
update siac_bko_t_caricamento_causali bko
set    codice_causale='ORD-U.3.01.01.05.001'
where codice_causale='ORD-U.3.01.0105.001'

update siac_bko_t_caricamento_causali bko
set    codice_causale='ORD-U.3.01.01.05.002'
where codice_causale='ORD-U.3.01.0105.002'

update siac_bko_t_caricamento_causali bko
set    codice_causale='ORD-U.3.01.01.05.003'
where codice_causale='ORD-U.3.01.0105.003'



-----------------------
select ep.causale_ep_id,
       evento.evento_id,
       ep.causale_ep_code,
       evento.evento_code,
       count(*)

from siac_t_ente_proprietario ente,siac_bko_t_causale_evento bko,siac_t_causale_ep ep,
     siac_d_evento evento,siac_d_evento_tipo tipo
    where ente.ente_proprietario_id=2
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.login_operazione like '%'||'SIAC-6661'||'-'||bko.eu||'%'
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.causale_ep_code=bko.codice_causale
    and   tipo.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.evento_tipo_code=bko.tipo_evento
    and   evento.evento_tipo_id=tipo.evento_tipo_id
    and   evento.evento_code=bko.evento
    and   bko.caricata=false
/*    and    exists
    (
    select 1 from siac_r_evento_causale r1
    where r1.causale_ep_id = ep.causale_ep_id
    and   r1.evento_id=evento.evento_id
    and   r1.login_operazione not like '%SIAC-6661%'
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )*/
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    group by ep.causale_ep_id,
       evento.evento_id,
       ep.causale_ep_code,
       evento.evento_code
    having count(*)>1
    order by 1,2


    select  *
    from siac_bko_t_causale_evento bko
    where bko.codice_causale in
    (
    'ROR-I-RP-U.3.01.01.05.003',
    'ROR-I-RP-U.3.01.01.05.002',
    'ROR-I-RP-U.3.01.01.05.001'
    )
    and  bko.evento ='ROR-I-RP-INS'
    -- ROR-I-RP-U.3.01.01.05.003 ROR-I-RP-INS
    -- ROR-I-RP-U.3.01.01.05.002
    -- ROR-I-RP-U.3.01.01.05.001=bko.codice_causale

-----------------------

select *
from  siac_bko_t_caricamento_causali bko
where bko.codice_causale like '%U.2.02.04.07.005%'
-- 35

--queste invece sono sbagliate sul file
-- ORD-U.3.01.0105.001
--ORD-U.3.01.0105.002
--ORD-U.3.01.0105.003

select distinct bko.codice_causale
from  siac_bko_t_caricamento_causali bko
where bko.codice_causale in
(
'ORD-U.3.01.0105.001',
'ORD-U.3.01.0105.002',
'ORD-U.3.01.0105.003'
)


select  bko.caricata,ep.causale_ep_code,stato.causale_ep_stato_code,ambito.ambito_code,ep.validita_inizio,
        bko.*
from  siac_bko_t_caricamento_causali bko,siac_t_causale_ep ep,siac_r_causale_ep_stato rs,siac_d_causale_ep_stato stato,
     siac_d_ambito ambito
where bko.codice_causale in
(
'ORD-U.3.01.0105.001',
'ORD-U.3.01.0105.002',
'ORD-U.3.01.0105.003'
)
and   ep.ente_proprietario_id=2
and   ep.causale_ep_code=bko.codice_causale
and   rs.causale_ep_id=ep.causale_ep_id
and   stato.causale_ep_stato_id=rs.causale_ep_stato_id
and   ambito.ambito_id=ep.ambito_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null


select distinct bko.caricata,ep.causale_ep_code,stato.causale_ep_stato_code,ambito.ambito_code,ep.validita_inizio
from  siac_bko_t_caricamento_causali bko,siac_t_causale_ep ep,siac_r_causale_ep_stato rs,siac_d_causale_ep_stato stato,
     siac_d_ambito ambito
where bko.codice_causale like '%U.2.02.04.07.005%'
and   ep.ente_proprietario_id=2
and   ep.causale_ep_code=bko.codice_causale
and   rs.causale_ep_id=ep.causale_ep_id
and   stato.causale_ep_stato_id=rs.causale_ep_stato_id
and   ambito.ambito_id=ep.ambito_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null

rollback;
begin;
update siac_bko_t_caricamento_causali bko
set    codice_causale='ORD-U.3.01.01.05.001'
where codice_causale='ORD-U.3.01.0105.001'

update siac_bko_t_caricamento_causali bko
set    codice_causale='ORD-U.3.01.01.05.002'
where codice_causale='ORD-U.3.01.0105.002'

update siac_bko_t_caricamento_causali bko
set    codice_causale='ORD-U.3.01.01.05.003'
where codice_causale='ORD-U.3.01.0105.003'



-----------------------
select ep.causale_ep_id,
       evento.evento_id,
       ep.causale_ep_code,
       evento.evento_code,
       count(*)

from siac_t_ente_proprietario ente,siac_bko_t_causale_evento bko,siac_t_causale_ep ep,
     siac_d_evento evento,siac_d_evento_tipo tipo
    where ente.ente_proprietario_id=2
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.login_operazione like '%'||'SIAC-6661'||'-'||bko.eu||'%'
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.causale_ep_code=bko.codice_causale
    and   tipo.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.evento_tipo_code=bko.tipo_evento
    and   evento.evento_tipo_id=tipo.evento_tipo_id
    and   evento.evento_code=bko.evento
    and   bko.caricata=false
/*    and    exists
    (
    select 1 from siac_r_evento_causale r1
    where r1.causale_ep_id = ep.causale_ep_id
    and   r1.evento_id=evento.evento_id
    and   r1.login_operazione not like '%SIAC-6661%'
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )*/
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    group by ep.causale_ep_id,
       evento.evento_id,
       ep.causale_ep_code,
       evento.evento_code
    having count(*)>1
    order by 1,2


    select  *
    from siac_bko_t_causale_evento bko
    where bko.codice_causale in
    (
    'ROR-I-RP-U.3.01.01.05.003',
    'ROR-I-RP-U.3.01.01.05.002',
    'ROR-I-RP-U.3.01.01.05.001'
    )
    and  bko.evento ='ROR-I-RP-INS'
    -- ROR-I-RP-U.3.01.01.05.003 ROR-I-RP-INS
    -- ROR-I-RP-U.3.01.01.05.002
    -- ROR-I-RP-U.3.01.01.05.001