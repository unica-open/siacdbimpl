/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select *
from siac_bko_t_caricamento_pdce_conto bko
where bko.tipo_operazione='I'
-- 50
select *
from siac_bko_t_caricamento_pdce_conto bko
where bko.tipo_operazione='A'
-- 23

begin;
select
fnc_siac_bko_caricamento_pdce_conto
( 2019,
  3,
  'AMBITO_FIN',
  'SIAC-6661',
  now()::timestamp
)

NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_t_class]. 96479028
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree]. 492646
NOTICE:  Conti livello V inseriti=8
NOTICE:  Conti livello VI inseriti=31
NOTICE:  Conti livello VII inseriti=11
NOTICE:  Attributi pdce_conto_foglia inseriti=38
NOTICE:  Attributi pdce_conto_di_legge inseriti=50
NOTICE:  Attributi pdce_ammortamento inseriti=0
NOTICE:  Attributi pdce_conto_attivo inseriti=50
NOTICE:  Attributi pdce_conto_segno_negativo inseriti=0
NOTICE:  Codifiche di bilancio  pdce_conto inserite=44
NOTICE:  Codifiche di bilancio  pdce_conto inserite=25
NOTICE:  Inserimento conti PDC_ECON di generale ambitoCode=AMBITO_FIN. Elaborazione terminata.

rollback;
begin;
select
fnc_siac_bko_caricamento_causali
(
  2019,
  3,
  'AMBITO_FIN',
   'SIAC-6661',
  now()::timestamp
);

select count(*)
from siac_bko_t_caricamento_causali bko
where caricata=false
-- 480

select distinct bko.codice_causale
from siac_bko_t_caricamento_causali bko
-- 237



NOTICE:  numeroCausali=237
NOTICE:  numeroStatoCausali=237
NOTICE:  numeroPdcFinCausali=237
NOTICE:  numeroContiCausali=474
NOTICE:  numeroContiSEGNOCausali=480
NOTICE:  numeroContiTIPOIMPORTOCausali=474
NOTICE:  numeroContiUTILIZZOCONTOCausali=474
NOTICE:  numeroContiUTILIZZOIMPORTOCausali=474
NOTICE:  numeroCausaliEvento=556
NOTICE:  Inserimento causale di generale ambitoCode=AMBITO_FIN. Inserite 237 causali.


select  *
from siac_bko_t_causale_evento bko
-- 665

select  distinct bko.codice_causale, bko.evento--,bko.eu
from siac_bko_t_causale_evento bko
where  exists
(select 1 from siac_bko_t_caricamento_causali c
where c.caricata=false
and   c.codice_causale=bko.codice_causale)

select ep.causale_ep_id,
       evento.evento_id,
       ep.causale_ep_code,
       evento.evento_code,
       count(*)

from siac_t_ente_proprietario ente,siac_bko_t_causale_evento bko,siac_t_causale_ep ep,
     siac_d_evento evento,siac_d_evento_tipo tipo
    where ente.ente_proprietario_id=3
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

    select distinct ep.causale_ep_id,
       evento.evento_id

from siac_t_ente_proprietario ente,siac_bko_t_causale_evento bko,siac_t_causale_ep ep,
     siac_d_evento evento,siac_d_evento_tipo tipo
    where ente.ente_proprietario_id=3
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

    select distinct ep.causale_ep_code,stato.causale_ep_stato_code,ambito.ambito_code,ep.validita_inizio
from  siac_t_causale_ep ep,siac_r_causale_ep_stato rs,siac_d_causale_ep_stato stato,
     siac_d_ambito ambito
where ep.ente_proprietario_id=3
and   ep.causale_ep_code like '%U.2.02.04.07.005%'
and   rs.causale_ep_id=ep.causale_ep_id
and   stato.causale_ep_stato_id=rs.causale_ep_stato_id
and   ambito.ambito_id=ep.ambito_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
