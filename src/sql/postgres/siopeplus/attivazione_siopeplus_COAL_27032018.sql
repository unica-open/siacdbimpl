/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Q(1) inserimento mif_d_flusso_elaborato_tipo
select *
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=29
-- inserimento tipo MANDMIF_PLUS id=203
insert into mif_d_flusso_elaborato_tipo
(flusso_elab_mif_tipo_code,
 flusso_elab_mif_tipo_desc,
 flusso_elab_mif_nome_file,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 flusso_elab_mif_tipo_dec
)
values
(
'MANDMIF_SPLUS',
'Siope+ - Flusso XML Mandati (ordinativi spesa)',
'MANDMIF_SPLUS',
'2018-01-01',
29,
'admin-siope+',
true
);

-- inserimento tipo REVMIF_SPLUS id=204
insert into mif_d_flusso_elaborato_tipo
(flusso_elab_mif_tipo_code,
 flusso_elab_mif_tipo_desc,
 flusso_elab_mif_nome_file,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 flusso_elab_mif_tipo_dec
)
values
(
'REVMIF_SPLUS',
'Siope+ - Flusso XML Reversali (ordinativi incasso)',
'REVMIF_SPLUS',
'2018-01-01',
29,
'admin-siope+',
true
);

-- inserimento tipo GIOCASSA id=205
-- insert into mif_d_flusso_elaborato_tipo
insert into mif_d_flusso_elaborato_tipo
(
  flusso_elab_mif_tipo_code,
  flusso_elab_mif_tipo_desc,
  flusso_elab_mif_nome_file,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
 'GIOCASSA',
 'Siope+ - Giornale di Cassa',
 'GDC',
 now(),
 29,
 'admin-siope+'
);

-- inserimento tipo FIRME id=206
-- insert into mif_d_flusso_elaborato_tipo
insert into mif_d_flusso_elaborato_tipo
(
  flusso_elab_mif_tipo_code,
  flusso_elab_mif_tipo_desc,
  flusso_elab_mif_nome_file,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
 'RICFIMIF',
 'Siope+ - Flusso acquisizione ricevute firme ordinativi',
 'RicSisC_RS',
 now(),
 29,
 'admin-siope+'
);


-- Q(2) impostazione bollo
-- 00 IMPOSTA DI BOLLO ASSOLTA IN MODO VIRTUALE. AUTORIZZAZIONE AGENZIA DELLE ENTRATE III UFFICIO DI BOLOGNA N. 2002/45041 DEL 17/12/2002
-- 77 IVA ASSOLTA
-- 99 ESENTE DA BOLLO
select *
from siac_d_codicebollo d
where d.ente_proprietario_id=29

select *
from siac_d_codicebollo_plus d
where d.ente_proprietario_id=29


begin;
-- inserimento siac_d_codicebollo_plus
insert into siac_d_codicebollo_plus
(
  codbollo_plus_code,
  codbollo_plus_desc,
  codbollo_plus_esente,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
 '01',
 'ESENTE BOLLO',
 true,
 '2018-01-01'::timestamp,
 29,
 'admin-siope+'
);

insert into siac_d_codicebollo_plus
(
  codbollo_plus_code,
  codbollo_plus_desc,
  codbollo_plus_esente,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
 '02',
 'ASSOGGETTATO BOLLO A CARICO ENTE',
 false,
 '2018-01-01'::timestamp,
 29,
 'admin-siope+'
);

insert into siac_d_codicebollo_plus
(
  codbollo_plus_code,
  codbollo_plus_desc,
  codbollo_plus_esente,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
 '03',
 'ASSOGGETTATO BOLLO A CARICO BENEFICIARIO',
 false,
 '2018-01-01'::timestamp,
 29,
 'admin-siope+'
);


-- inserimento siac_r_codicebollo_plus

-- 3|00|77|99
insert into siac_r_codicebollo_plus
(
  codbollo_id,
  codbollo_plus_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select bollo.codbollo_id,
       plus.codbollo_plus_id,
       '2018-01-01'::timestamp,
       bollo.ente_proprietario_id,
       'admin-siope+'
from siac_d_codicebollo_plus plus, siac_d_codicebollo bollo
where plus.ente_proprietario_id=29
and   plus.codbollo_plus_desc='ESENTE BOLLO'
and   plus.codbollo_plus_esente=true
and   bollo.ente_proprietario_id=plus.ente_proprietario_id
and   bollo.codbollo_code in ('00','77','99');


-- Q(3) impostazione commissioni

-- BN BENEFICIARIO
-- ES ESENTE
-- CE CARICO ENTE
select *
from siac_d_commissione_tipo_plus d
where d.ente_proprietario_id=29

--  insert in siac_d_commissione_tipo_plus
insert into siac_d_commissione_tipo_plus
(
  comm_tipo_plus_code,
  comm_tipo_plus_desc,
  comm_tipo_plus_esente,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'CE',
  'A CARICO ENTE',
  false,
  '2018-01-01'::timestamp,
  29,
  'admin-siope+'
);


insert into siac_d_commissione_tipo_plus
(
  comm_tipo_plus_code,
  comm_tipo_plus_desc,
  comm_tipo_plus_esente,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'BN',
  'A CARICO BENEFICIARIO',
  false,
  '2018-01-01'::timestamp,
  29,
  'admin-siope+'
);


insert into siac_d_commissione_tipo_plus
(
  comm_tipo_plus_code,
  comm_tipo_plus_desc,
  comm_tipo_plus_esente,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'ES',
  'ESENTE',
  true,
  '2018-01-01'::timestamp,
  29,
  'admin-siope+'
);

-- insert into siac_r_commissione_tipo_plus
insert into siac_r_commissione_tipo_plus
(
  comm_tipo_id,
  comm_tipo_plus_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.comm_tipo_id,
       plus.comm_tipo_plus_id,
       '2018-01-01'::timestamp,
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_commissione_tipo_plus plus, siac_d_commissione_tipo tipo
where plus.ente_proprietario_id=29
and   plus.comm_tipo_plus_desc='ESENTE'
and   plus.comm_tipo_plus_esente=true
and   tipo.ente_proprietario_id=plus.ente_proprietario_id
and   tipo.comm_tipo_code in ('ES');

insert into siac_r_commissione_tipo_plus
(
  comm_tipo_id,
  comm_tipo_plus_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.comm_tipo_id,
       plus.comm_tipo_plus_id,
       '2018-01-01'::timestamp,
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_commissione_tipo_plus plus, siac_d_commissione_tipo tipo
where plus.ente_proprietario_id=29
and   plus.comm_tipo_plus_desc='A CARICO ENTE'
and   tipo.ente_proprietario_id=plus.ente_proprietario_id
and   tipo.comm_tipo_code in ('CE');

insert into siac_r_commissione_tipo_plus
(
  comm_tipo_id,
  comm_tipo_plus_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.comm_tipo_id,
       plus.comm_tipo_plus_id,
       '2018-01-01'::timestamp,
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_commissione_tipo_plus plus, siac_d_commissione_tipo tipo
where plus.ente_proprietario_id=29
and   plus.comm_tipo_plus_desc='A CARICO BENEFICIARIO'
and   tipo.ente_proprietario_id=plus.ente_proprietario_id
and   tipo.comm_tipo_code in ('BN');


-- Q(4) impostazione MDP
-- modalità di accredito nuove
-- da caricare
insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  accredito_gruppo_id,
  login_operazione,
  validita_inizio,
  ente_proprietario_id
)
select  'STI',
        'STIPENDI',
        0,
        gruppo.accredito_gruppo_id,
        'admin-siope+',
        '2018-01-01'::timestamp,
        gruppo.ente_proprietario_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=29
and   gruppo.accredito_gruppo_code='GE';

-- Q(5) impostazione tipo pagamento OK
select *
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=29
begin;
rollback;
-- insert into siac_d_accredito_tipo_oil - inizio
insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '21',
       'CASSA',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;


insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '22',
       'BONIFICO BANCARIO E POSTALE',
       'IT',
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;


insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '23',
       'SEPA CREDIT TRANSFER',
       'SEPA',
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '24',
       'BONIFICO ESTERO EURO',
       'EXTRASEPA',
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '25',
       'ACCREDITO CONTO CORRENTE POSTALE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '26',
       'ASSEGNO BANCARIO E POSTALE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;


insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '27',
       'ASSEGNO CIRCOLARE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;


insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '28',
       'F24EP',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;


insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '29',
       'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;


insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '30',
       'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;


insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '31',
       'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;


insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '32',
       'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '33',
       'REGOLARIZZAZIONE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '34',
       'VAGLIA POSTALE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '35',
       'VAGLIA TESORO',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '36',
       'ADDEBITO PREAUTORIZZATO',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '37',
       'DISPOSIZIONE DOCUMENTO ESTERNO',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;


insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '38',
       'COMPENSAZIONE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

-- insert into siac_d_accredito_tipo_oil - fine

select *
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=29
and   oil.login_operazione='admin-siope+'
order by oil.accredito_tipo_oil_code::integer
-- da 21 a 38



begin;
-- CON,DEQUI - CASSA
-- DISDE,GEN, LIQUI,PAPRE,RIDBA,TESOR - CASSA ?? da capire
select gruppo.accredito_gruppo_code,
       tipo.*
from siac_d_accredito_tipo tipo,siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=29
and   tipo.accredito_tipo_code in
(
'CON',  --CO
'DEQUI', --CO
'DISDE',
'GEN',
'LIQUI',
'PAPRE',
'RIDBA',
'TESOR'
)
and  gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id

-- insert into siac_r_accredito_tipo_oil - inizio
-- CASSA
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='CASSA'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CON','DEQUI')
and   tipo.data_cancellazione is null;






-- CB

select gruppo.accredito_gruppo_code,
       tipo.*
from siac_d_accredito_tipo tipo,siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=29
and   tipo.accredito_tipo_code in
(
'BOCAS',
'BONIF',
'CCB'
)
and  gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id

-- BONIFICO BANCARIO E POSTALE
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='BONIFICO BANCARIO E POSTALE'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('BOCAS','BONIF','CCB')
and   tipo.data_cancellazione is null;

-- SEPA CREDIT TRANSFER
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='SEPA CREDIT TRANSFER'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code ='BONIF'
and   tipo.data_cancellazione is null;

-- BONIFICO ESTERO EURO
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='BONIFICO ESTERO EURO'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code ='BONIF'
and   tipo.data_cancellazione is null;

select gruppo.accredito_gruppo_code,
       tipo.*
from siac_d_accredito_tipo tipo,siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=29
and   tipo.accredito_tipo_code in
(
'CCP',
'POSTA'
)
and  gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id

-- ACCREDITO CONTO CORRENTE POSTALE
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='ACCREDITO CONTO CORRENTE POSTALE'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CCP','POSTA')
and   tipo.data_cancellazione is null;

select gruppo.accredito_gruppo_code,
       tipo.*
from siac_d_accredito_tipo tipo,siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=29
and   tipo.accredito_tipo_code in
(
'ATR',
'CITRA'
)
and  gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id


-- ASSEGNO BANCARIO E POSTALE
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='ASSEGNO BANCARIO E POSTALE'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code ='ATR'
and   tipo.data_cancellazione is null;

-- ASSEGNO CIRCOLARE
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='ASSEGNO CIRCOLARE'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code ='CITRA'
and   tipo.data_cancellazione is null;

select gruppo.accredito_gruppo_code,
       tipo.*
from siac_d_accredito_tipo tipo,siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=29
and   tipo.accredito_tipo_code in
(
'F24EP',
'CBI',
'GIRO',
'GIROF'
)
and  gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id


-- F24EP
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='F24EP'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code ='F24EP'
and   tipo.data_cancellazione is null;

-- ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CBI','GIRO')
and   tipo.data_cancellazione is null;

-- ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('GIROF')
and   tipo.data_cancellazione is null;

-- REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('REGA')
and   tipo.data_cancellazione is null;


-- REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('REGB')
and   tipo.data_cancellazione is null;

-- REGOLARIZZAZIONE
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='REGOLARIZZAZIONE'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('REG')
and   tipo.data_cancellazione is null;

-- DISPOSIZIONE DOCUMENTO ESTERNO
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='DISPOSIZIONE DOCUMENTO ESTERNO'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('DDE','MRF','STI','RIDBA')
and   tipo.data_cancellazione is null;

-- COMPENSAZIONE
insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_accredito_tipo_oil oil, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.accredito_tipo_oil_desc='COMPENSAZIONE'
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('LICOM','COM')
and   tipo.data_cancellazione is null;

begin;
-- chiusura rel e oil precedenti
update  siac_r_accredito_tipo_oil r
set     data_cancellazione=now()
where r.ente_proprietario_id=29
and   r.login_operazione!='admin-siope+';

update  siac_d_accredito_tipo_oil r
set     data_cancellazione=now()
where r.ente_proprietario_id=29
and   r.login_operazione!='admin-siope+';

select oil.accredito_tipo_oil_code, oil.accredito_tipo_oil_desc,
       oil.accredito_tipo_oil_area,
       tipo.accredito_tipo_code, tipo.accredito_tipo_desc
from siac_d_accredito_tipo_oil oil, siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=29
and   oil.login_operazione='admin-siope+'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   r.data_cancellazione is  null
and   r.validita_fine is  null
order by oil.accredito_tipo_oil_code::integer

-- Q(6) impostazione tipo incasso - regolarizzazioni
--- TIPO INCASSO
select *
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=29
and   oil.validita_fine is null
and   oil.data_cancellazione is null

select oil.accredito_tipo_oil_code,
       oil.accredito_tipo_oil_desc,
       r.accredito_tipo_oil_desc_incasso
from siac_d_accredito_tipo_oil oil,siac_r_accredito_tipo_plus r
where oil.ente_proprietario_id=29
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   oil.validita_fine is null
and   oil.data_cancellazione is null
and   r.validita_fine is null
and   r.data_cancellazione is null



-- insert into tipi_incassi siac_d_accredito_tipo_oil per tipi_incassi
begin;
insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '39',
       'ACCREDITO BANCA D''ITALIA',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '40',
       'PRELIEVO DA CC POSTALE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '41',
       'REGOLARIZZAZIONE ACCREDITO BANCA D''ITALIA',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=29;


-- tipi_incassi regolarizzazione
-- insert into siac_r_accredito_tipo_plus
insert into siac_r_accredito_tipo_plus
 (
  accredito_tipo_oil_id,
  accredito_tipo_oil_desc_incasso,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
 )
 select oil.accredito_tipo_oil_id,
        'REGOLARIZZAZIONE ACCREDITO BANCA D''ITALIA',
        now(),
        oil.ente_proprietario_id,
        'admin-siope+'
 from siac_d_accredito_tipo_oil oil
 where oil.ente_proprietario_id=29
 and   oil.accredito_tipo_oil_desc='ACCREDITO BANCA D''ITALIA'
 and   oil.data_cancellazione is null
 and   oil.validita_fine is null;

insert into siac_r_accredito_tipo_plus
 (
  accredito_tipo_oil_id,
  accredito_tipo_oil_desc_incasso,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
 )
 select oil.accredito_tipo_oil_id,
        'REGOLARIZZAZIONE ACCREDITO BANCA D''ITALIA',
        now(),
        oil.ente_proprietario_id,
        'admin-siope+'
 from siac_d_accredito_tipo_oil oil
 where oil.ente_proprietario_id=29
 and   oil.accredito_tipo_oil_desc='REGOLARIZZAZIONE ACCREDITO BANCA D''ITALIA'
 and   oil.data_cancellazione is null
 and   oil.validita_fine is null;


insert into siac_r_accredito_tipo_plus
 (
  accredito_tipo_oil_id,
  accredito_tipo_oil_desc_incasso,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
 )
 select oil.accredito_tipo_oil_id,
        'REGOLARIZZAZIONE',
        now(),
        oil.ente_proprietario_id,
        'admin-siope+'
 from siac_d_accredito_tipo_oil oil
 where oil.ente_proprietario_id=29
 and   oil.accredito_tipo_oil_desc='REGOLARIZZAZIONE'
 and   oil.data_cancellazione is null
 and   oil.validita_fine is null;


-- Q(7) impostazione classificatori liberi

--- CLASSIFICATORI LIBERI
--- INCASSO
--- CLASSIFICATORE_26 (si) fruttifiro
--- CLASSIFICATORE_27 (si) mod. incasso
--- CLASSIFICATORE_28 (si new) cc postale
--  CLASSIFICATORE_29 (si new) vincolato
--  CLASSIFICATORE_30
--- PAGAMENTO
--- CLASSIFICATORE_21 (si) frazionabile
--- CLASSIFICATORE_22 (si) fruttifero
--- CLASSIFICATORE_23 (si new) vincolato
--- CLASSIFICATORE_24, CLASSIFICATORE_25

select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code in
(
 'CLASSIFICATORE_26',
 'CLASSIFICATORE_27',
 'CLASSIFICATORE_28',
 'CLASSIFICATORE_29',
 'CLASSIFICATORE_30'
)

select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code in
(
 'CLASSIFICATORE_21',
 'CLASSIFICATORE_22',
 'CLASSIFICATORE_23',
 'CLASSIFICATORE_24',
 'CLASSIFICATORE_25'
)

-- TIPO_INCASSO CLASSIFICATORE_27
-- esistono gia su CLASSIFICATORE_27
-- solo inserimento di PRELIEVO DA CC POSTALE

select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code ='CLASSIFICATORE_27'

select c.classif_code,c.classif_desc
from siac_t_class c, siac_d_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code='CLASSIFICATORE_27'
and   c.classif_tipo_id=tipo.classif_tipo_id


insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select '06',
        'PRELIEVO DA CC POSTALE',
        tipo.classif_tipo_id,
        '2018-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=29
 and   tipo.classif_tipo_code='CLASSIFICATORE_27';

-- CLASSIFICATORE_28
-- CC POSTALI per modalita di incasso PRELIEVO DA CC POSTALE
select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code like 'CLASSIFICATORE_28'

begin;
update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di entrata su prelievo da cc postale numero'
 where tipo.ente_proprietario_id=29
 and   tipo.classif_tipo_code='CLASSIFICATORE_28';

-- mancano cc da inserire sulla siac_t_class
insert into siac_t_class
(
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
)
select '', -- devono fornirceli
       '',
       tipo.classif_tipo_id,
       '2018-01-01'::timestamp,
       'admin-siope+',
       tipo.ente_proprietario_id
from siac_D_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code='CLASSIFICATORE_28';


-- VINCOLO
-- CLASSIFICATORE_29
select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code like 'CLASSIFICATORE_29'

begin;
update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di entrata vincolo conto'
 where tipo.ente_proprietario_id=29
 and   tipo.classif_tipo_code='CLASSIFICATORE_29';

insert into siac_t_class
(
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
)
select 'V',
       'VINCOLATO',
       tipo.classif_tipo_id,
       '2018-01-01'::timestamp,
       'admin-siope+',
       tipo.ente_proprietario_id
from siac_D_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code='CLASSIFICATORE_29';

insert into siac_t_class
(
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
)
select 'L',
       'LIBERO',
       tipo.classif_tipo_id,
       '2018-01-01'::timestamp,
       'admin-siope+',
       tipo.ente_proprietario_id
from siac_D_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code='CLASSIFICATORE_29';

select c.classif_code,c.classif_desc
from siac_t_class c, siac_d_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code='CLASSIFICATORE_29'
and   c.classif_tipo_id=tipo.classif_tipo_id


--- classificatori liberi spesa
--  CLASSIFICATORE_23 - Ordinativo di spesa vincolato
select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code ='CLASSIFICATORE_23'

begin;
update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di spesa vincolo conto'
 where tipo.ente_proprietario_id=29
 and   tipo.classif_tipo_code='CLASSIFICATORE_23';

insert into siac_t_class
(
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
)
select 'V',
       'VINCOLATO',
       tipo.classif_tipo_id,
       '2018-01-01'::timestamp,
       'admin-siope+',
       tipo.ente_proprietario_id
from siac_D_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code='CLASSIFICATORE_23';

insert into siac_t_class
(
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
)
select 'L',
       'LIBERO',
       tipo.classif_tipo_id,
       '2018-01-01'::timestamp,
       'admin-siope+',
       tipo.ente_proprietario_id
from siac_D_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code='CLASSIFICATORE_23';


select c.classif_code,c.classif_desc
from siac_t_class c, siac_d_class_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.classif_tipo_code='CLASSIFICATORE_23'
and   c.classif_tipo_id=tipo.classif_tipo_id



-- Q(8) impostazione giornale di cassa

-- GIORNALE DI CASSA
select *
from siac_d_oil_ricevuta_tipo  oil
where oil.ente_proprietario_id=29

select *
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
select *
from siac_d_oil_qualificatore  oil
where oil.ente_proprietario_id=29

-- ricevuta tipo
insert into siac_d_oil_ricevuta_tipo
(
	oil_ricevuta_tipo_code,
    oil_ricevuta_tipo_desc,
    oil_ricevuta_tipo_code_fl,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
      tipo.oil_ricevuta_tipo_code,
      tipo.oil_ricevuta_tipo_desc,
      tipo.oil_ricevuta_tipo_code_fl,
      '2018-01-01'::timestamp,
      'admin-siope+',
      ente.ente_proprietario_id
from siac_d_oil_ricevuta_tipo tipo, siac_t_ente_proprietario ente
where tipo.ente_proprietario_id=4
and   ente.ente_proprietario_id=29;

-- insert siac_d_oil_esito_derivato
-- Q, S -- quietanza, storno quietanza
begin;
insert into siac_d_oil_esito_derivato
(
  oil_esito_derivato_code,
  oil_esito_derivato_desc,
  oil_ricevuta_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'QUIETANZA',
       'QUIETANZA',
       tipo.oil_ricevuta_tipo_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.oil_ricevuta_tipo_code='Q';

insert into siac_d_oil_esito_derivato
(
  oil_esito_derivato_code,
  oil_esito_derivato_desc,
  oil_ricevuta_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'STORNO QUIETANZA',
       'STORNO QUIETANZA',
       tipo.oil_ricevuta_tipo_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.oil_ricevuta_tipo_code='S';

-- P , PS provvisorio, storno provvisorio
insert into siac_d_oil_esito_derivato
(
  oil_esito_derivato_code,
  oil_esito_derivato_desc,
  oil_ricevuta_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'PROVVISORIO',
       'PROVVISORIO',
       tipo.oil_ricevuta_tipo_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.oil_ricevuta_tipo_code='P';

insert into siac_d_oil_esito_derivato
(
  oil_esito_derivato_code,
  oil_esito_derivato_desc,
  oil_ricevuta_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'STORNO PROVVISORIO',
       'STORNO PROVVISORIO',
       tipo.oil_ricevuta_tipo_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=29
and   tipo.oil_ricevuta_tipo_code='PS';

-- insert siac_d_oil_qualificatore
-- quietanza
insert into siac_d_oil_qualificatore
(
 oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'MANDATO ESEGUITO',
       'MANDATO ESEGUITO',
       'U',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='QUIETANZA';

insert into siac_d_oil_qualificatore
(
 oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'MANDATO REGOLARIZZATO',
       'MANDATO REGOLARIZZATO',
       'U',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='QUIETANZA';

insert into siac_d_oil_qualificatore
(
 oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'REVERSALE ESEGUITO',
       'REVERSALE ESEGUITO',
       'E',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='QUIETANZA';

insert into siac_d_oil_qualificatore
(
  oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'REVERSALE REGOLARIZZATO',
       'REVERSALE REGOLARIZZATO',
       'E',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='QUIETANZA';



-- storno quietanza
insert into siac_d_oil_qualificatore
(
 oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'MANDATO STORNATO',
       'MANDATO STORNATO',
       'U',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='STORNO QUIETANZA';

insert into siac_d_oil_qualificatore
(
 oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'MANDATO RIPRISTINATO',
       'MANDATO RIPRISTINATO',
       'U',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='STORNO QUIETANZA';

insert into siac_d_oil_qualificatore
(
 oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'REVERSALE STORNATO',
       'REVERSALE STORNATO',
       'E',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='STORNO QUIETANZA';

insert into siac_d_oil_qualificatore
(
  oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'REVERSALE RIPRISTINATO',
       'REVERSALE RIPRISTINATO',
       'E',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='STORNO QUIETANZA';



-- provvisori


insert into siac_d_oil_qualificatore
(
 oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'SOSPESO USCITA ESEGUITO',
       'SOSPESO USCITA ESEGUITO',
       'U',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='PROVVISORIO';

insert into siac_d_oil_qualificatore
(
 oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'SOSPESO USCITA STORNATO',
       'SOSPESO USCITA STORNATO',
       'U',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='STORNO PROVVISORIO';

insert into siac_d_oil_qualificatore
(
 oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'SOSPESO ENTRATA ESEGUITO',
       'SOSPESO ENTRATA ESEGUITO',
       'E',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='PROVVISORIO';

insert into siac_d_oil_qualificatore
(
 oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  oil_qualificatore_dr_rec
)
select 'SOSPESO ENTRATA STORNATO',
       'SOSPESO ENTRATA STORNATO',
       'E',
       oil.oil_esito_derivato_id,
       now(),
       oil.ente_proprietario_id,
       'admin-siope+',
       false
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=29
and   oil.oil_esito_derivato_code='STORNO PROVVISORIO';


-- Q(9) attivazione siope+
begin;
update siac_r_gestione_ente r
set    gestione_livello_id=dnew.gestione_livello_id,
       data_modifica=now(),
       login_operazione=r.login_operazione||'-admin-siope+'
from siac_d_gestione_livello d,siac_d_gestione_livello dnew
where d.ente_proprietario_id=29
and   d.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_UNIIT'
and   r.gestione_livello_id=d.gestione_livello_id
and   dnew.ente_proprietario_id=d.ente_proprietario_id
and   dnew.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_SIOPE_PLUS'
and   r.data_cancellazione is null
and   r.validita_fine is null;


update siac_t_ente_oil e
set    ente_oil_siope_plus=true
where e.ente_proprietario_id=29;



-- CONFIGURAZIONI ENTE
-- <codice_ABI_BT>05584</codice_ABI_BT>
-- <codice_ente>UFUD0S</codice_ente>
-- <descrizione_ente>Comune di Alessandria</descrizione_ente>
-- <codice_istat_ente>000082420</codice_istat_ente>
-- <codice_fiscale_ente>00429440068</codice_fiscale_ente>
-- <codice_tramite_ente>A2AA-29095250</codice_tramite_ente>
-- <codice_tramite_BT>A2AA-23515664</codice_tramite_BT>
-- <codice_ente_BT>0600300</codice_ente_BT>


select *
from siac_t_ente_oil oil
where oil.ente_proprietario_id=29

begin;
update siac_t_ente_oil e
set    ente_oil_codice_ipa='UFUD0S', -- <codice_ente>
       ente_oil_codice_istat='000082420', -- <codice_istat_ente>
       ente_oil_codice_tramite='A2AA-29095250', -- <codice_tramite_ente>
       ente_oil_codice_tramite_bt='A2AA-23515664', -- <codice_tramite_BT>
       ente_oil_codice_pcc_uff='c_a182'
where e.ente_proprietario_id=29;



select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=29
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)
order by mif.flusso_elab_mif_ordine

--- aggiornare mif_d_flusso_elaborato per MANDMIF_SPLUS
-- <descrizione_ente>=Comune di Alessandria
-- <codice_fiscale>=00429440068
-- <codice_ente_bt>=0600300
-- <codice_ABI_BT>=05584
-- <tipo_pagamento>=IT|BONIF|REG|SEPA|EXTRASEPA
-- <destinazione>= def. LIBERO

--- aggiornare mif_d_flusso_elaborato per REVMIF_SPLUS -- dovrebbe essere a posto
-- <descrizione_ente>=Comune di Alessandria
-- <codice_fiscale>=00429440068
-- <codice_ente_bt>=0600300
-- <codice_ABI_BT>=05584
-- <tipo_riscossione>=CLASSIFICATORE_27|RIT_ORD|SPR|SUB_ORD|IRPEF|INPS|IRPEG
-- <numero_ccp>=PRELIEVO DA CC POSTALE|CLASSIFICATORE_28
-- <destinazione>=CLASSIFICATORE_29 def LIBERO

--- Q(10) inserimento mif_d_flusso_elaborato per MANDMIF_SPLUS - INIZIO - eseguito

-- da creare

select 'INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values ('
            ||  d.flusso_elab_mif_ordine||','
            ||  quote_nullable(d.flusso_elab_mif_code)||','
            ||  quote_nullable(d.flusso_elab_mif_desc)||','
            ||  d.flusso_elab_mif_attivo||','
            ||  quote_nullable(d.flusso_elab_mif_code_padre)||','
            ||  quote_nullable(d.flusso_elab_mif_tabella)||','
            ||  quote_nullable(d.flusso_elab_mif_campo)||','
            ||  quote_nullable(d.flusso_elab_mif_default)||','
            ||  d.flusso_elab_mif_elab||','
            ||  quote_nullable(d.flusso_elab_mif_param)||','
            ||  quote_nullable('2018-01-01')||','
            ||  29||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  203
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=2
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS';

--- inserimento mif_d_flusso_elaborato per MANDMIF_SPLUS - FINE - eseguito


---Q(11) inserimento mif_d_flusso_elaborato per REVMIF_SPLUS - INIZIO - eseguito

select 'INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values ('
            ||  d.flusso_elab_mif_ordine||','
            ||  quote_nullable(d.flusso_elab_mif_code)||','
            ||  quote_nullable(d.flusso_elab_mif_desc)||','
            ||  d.flusso_elab_mif_attivo||','
            ||  quote_nullable(d.flusso_elab_mif_code_padre)||','
            ||  quote_nullable(d.flusso_elab_mif_tabella)||','
            ||  quote_nullable(d.flusso_elab_mif_campo)||','
            ||  quote_nullable(d.flusso_elab_mif_default)||','
            ||  d.flusso_elab_mif_elab||','
            ||  quote_nullable(d.flusso_elab_mif_param)||','
            ||  quote_nullable('2018-01-01')||','
            ||  29||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  204
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=2
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS';


--- inserimento mif_d_flusso_elaborato per REVMIF_SPLUS - FINE - eseguito