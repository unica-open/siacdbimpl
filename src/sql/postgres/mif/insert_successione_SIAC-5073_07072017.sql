/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 07.07.2017 Sofia JIRA SIAC-5073
-- insert_successione_SIAC-5073_07072017.sql

-- inserimento accredito_tipo=SU
insert into siac_d_accredito_tipo
( accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id,
  validita_inizio
 )
 select 'SU',
        'SUCCESSIONE',
        12,
        gruppo.ente_proprietario_id,
        'admin',
        gruppo.accredito_gruppo_id,
        '2017-01-01'
 from siac_d_accredito_gruppo gruppo
 where gruppo.ente_proprietario_id=3
 and   gruppo.accredito_gruppo_code='CSI'
 and   not exists
 (
 select 1 from siac_d_accredito_tipo tipo1
 where tipo1.ente_proprietario_id=gruppo.ente_proprietario_id
 and   tipo1.accredito_tipo_code='SU'
 );



 -- inserimento relaz_tipo=SU
 insert into siac_d_relaz_tipo
 (
  relaz_tipo_code,
  relaz_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
 )
 select
  'SU',
  'SUCCESSIONE',
  '2017-01-01',
  3,
  'admin'
  where not exists
  (
  select  1 from siac_d_relaz_tipo tipo
  where tipo.ente_proprietario_id=3
  and   tipo.relaz_tipo_code='SU'
  );



-- inserimento siac_r_oil_relaz_tipo
insert into siac_r_oil_relaz_tipo
(
	relaz_tipo_id,
    oil_relaz_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select relaz_tipo_id,
       oil_relaz_tipo_id,
       '2017-01-01',
       'admin',
       tipo.ente_proprietario_id
from siac_d_relaz_tipo tipo, siac_d_oil_relaz_tipo oil
where tipo.ente_proprietario_id=3
and   tipo.relaz_tipo_code='SU'
and   oil.ente_proprietario_id=3
and   oil.oil_relaz_tipo_code='CSI'
and   not exists
(
select 1
from siac_r_oil_relaz_tipo r1
where r1.ente_proprietario_id=tipo.ente_proprietario_id
and   r1.relaz_tipo_id=tipo.relaz_tipo_id
and   r1.oil_relaz_tipo_id=oil.oil_relaz_tipo_id
);


