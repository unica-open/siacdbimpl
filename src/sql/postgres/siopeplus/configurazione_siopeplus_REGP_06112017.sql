/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 06.11.2017 Sofia
-- configurazione regp

-- CONFIGURAZIONI ENTE

update siac_t_ente_oil e
set    ente_oil_codice_ipa='UFES06', -- <codice_ente>
       ente_oil_codice_istat='000714250', -- <codice_istat_ente>
       ente_oil_codice_tramite='A2A-08517066', -- <codice_tramite_ente>
       ente_oil_codice_tramite_bt='A2A-32854436', -- <codice_tramite_BT>
       ente_oil_codice_pcc_uff='AX8DPY',
       ente_oil_codice_opi='RPI_OPI'
where e.ente_proprietario_id=2;

--Il <codice_tramite_ente> per i flussi di produzione è A2A-04255500
--Il <codice_tramite_BT> per i flussi di produzione è A2A-38628908
update siac_t_ente_oil e
set    ente_oil_codice_tramite='A2A-04255500', -- <codice_tramite_ente>
       ente_oil_codice_tramite_bt='A2A-38628908' -- <codice_tramite_BT>
where e.ente_proprietario_id=2;


-- inserimento tipo MANDMIF_PLUS
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
'2017-01-01',
2,
'admin-siope+',
true
);

-- inserimento tipo REVMIF_SPLUS
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
'2017-01-01',
2,
'admin-siope+',
true
);

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
 '2017-01-01'::timestamp,
 2,
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
 '2017-01-01'::timestamp,
 2,
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
 '2017-01-01'::timestamp,
 2,
 'admin-siope+'
);


-- inserimento siac_r_codicebollo_plus

-- 11|AI|E1|E2|E3|E4|E5|E6|E7|E8|E9|99
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
       '2017-01-01'::timestamp,
       bollo.ente_proprietario_id,
       'admin-siope+'
from siac_d_codicebollo_plus plus, siac_d_codicebollo bollo
where plus.ente_proprietario_id=2
and   plus.codbollo_plus_desc='ESENTE BOLLO'
and   plus.codbollo_plus_esente=true
and   bollo.ente_proprietario_id=plus.ente_proprietario_id
and   bollo.codbollo_code in ('AI','E1','E2','E3','E4','E5','E6','E7','E8','E9','99');

-- 2|SB|B|SI|I
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
       '2017-01-01'::timestamp,
       bollo.ente_proprietario_id,
       'admin-siope+'
from siac_d_codicebollo_plus plus, siac_d_codicebollo bollo
where plus.ente_proprietario_id=2
and   plus.codbollo_plus_desc='ASSOGGETTATO BOLLO A CARICO BENEFICIARIO'
and   bollo.ente_proprietario_id=plus.ente_proprietario_id
and   bollo.codbollo_code in ('SB');

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
       '2017-01-01'::timestamp,
       bollo.ente_proprietario_id,
       'admin-siope+'
from siac_d_codicebollo_plus plus, siac_d_codicebollo bollo
where plus.ente_proprietario_id=2
and   plus.codbollo_plus_desc='ASSOGGETTATO BOLLO A CARICO ENTE'
and   bollo.ente_proprietario_id=plus.ente_proprietario_id
and   bollo.codbollo_code in ('TP');


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
  '2017-01-01'::timestamp,
  2,
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
  '2017-01-01'::timestamp,
  2,
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
  '2017-01-01'::timestamp,
  2,
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
       '2017-01-01'::timestamp,
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_commissione_tipo_plus plus, siac_d_commissione_tipo tipo
where plus.ente_proprietario_id=2
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
       '2017-01-01'::timestamp,
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_commissione_tipo_plus plus, siac_d_commissione_tipo tipo
where plus.ente_proprietario_id=2
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
       '2017-01-01'::timestamp,
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_commissione_tipo_plus plus, siac_d_commissione_tipo tipo
where plus.ente_proprietario_id=2
and   plus.comm_tipo_plus_desc='A CARICO BENEFICIARIO'
and   tipo.ente_proprietario_id=plus.ente_proprietario_id
and   tipo.comm_tipo_code in ('BN');

-- TIPO PAGAMENTO
-- insert into siac_d_accredito_tipo
insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
)
select  'GFA',
		'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_code='CBI';

insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
)
select  'GFB',
		'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_code='CB';

insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
)
select  'REGA',
		'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_code='GE';

insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
)
select  'REGB',
		'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_code='GE';

insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
)
select  'REG',
		'REGOLARIZZAZIONE',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_code='GE';

insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
)
select  'STI',
		'STIPENDI',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_code='GE';

insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
)
select  'ADA',
		'ADDEBITO PREAUTORIZZATO',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_code='GE';

insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
)
select  'COM',
		'COMPENSAZIONE',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_code='GE';

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
select '01',
       'CASSA',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '02',
       'BONIFICO BANCARIO E POSTALE',
       'IT',
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '03',
       'SEPA CREDIT TRANSFER',
       'SEPA',
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '04',
       'BONIFICO ESTERO EURO',
       'EXTRASEPA',
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '05',
       'ACCREDITO CONTO CORRENTE POSTALE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '06',
       'ASSEGNO BANCARIO E POSTALE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '07',
       'ASSEGNO CIRCOLARE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '08',
       'F24EP',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '09',
       'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '10',
       'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '11',
       'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '12',
       'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '13',
       'REGOLARIZZAZIONE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '14',
       'VAGLIA POSTALE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '15',
       'VAGLIA TESORO',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '16',
       'ADDEBITO PREAUTORIZZATO',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '17',
       'DISPOSIZIONE DOCUMENTO ESTERNO',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;


insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '18',
       'COMPENSAZIONE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

-- insert into siac_d_accredito_tipo_oil - fine


-- insert into siac_r_accredito_tipo_oil
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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='01'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CT')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='17'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('FI')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='16'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('RI')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='02'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('BP','CB','CCB')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='03'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CB')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='04'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CB')
and   tipo.data_cancellazione is null;


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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='05'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CP')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='06'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('AB')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='07'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('AC')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='08'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('F2','F3')
and   tipo.data_cancellazione is null;


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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='09'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('GFA')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='09'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('GF')
and   tipo.data_cancellazione is null;


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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='10'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('GFB')
and   tipo.data_cancellazione is null;


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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='11'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('REGA')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='12'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('REGB')
and   tipo.data_cancellazione is null;


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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='13'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('REG')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='17'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('STI')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='16'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('ADA')
and   tipo.data_cancellazione is null;

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
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_code='18'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('COM')
and   tipo.data_cancellazione is null;

--- chiusura delle relazioni vecchie
update  siac_r_accredito_tipo_oil r
set     data_cancellazione=now()
where r.ente_proprietario_id=2
and   r.login_operazione!='admin-siope+';

begin;
update  siac_d_accredito_tipo_oil r
set     data_cancellazione=now()
where r.ente_proprietario_id=2
and   r.login_operazione!='admin-siope+';


--- TIPO INCASSO
-- insert into tipi_incassi siac_d_accredito_tipo_oil per tipi_incassi
insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '19',
       'ACCREDITO BANCA D''ITALIA',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  accredito_tipo_oil_area,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '20',
       'PRELIEVO DA CC POSTALE',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;

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
       'REGOLARIZZAZIONE ACCREDITO BANCA D''ITALIA',
       null,
       now(),
       ente.ente_proprietario_id,
       'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2;


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
 where oil.ente_proprietario_id=2
 and   oil.accredito_tipo_oil_desc='ACCREDITO BANCA D''ITALIA';

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
 where oil.ente_proprietario_id=2
 and   oil.accredito_tipo_oil_desc='REGOLARIZZAZIONE ACCREDITO BANCA D''ITALIA';

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
 where oil.ente_proprietario_id=2
 and   oil.accredito_tipo_oil_desc='REGOLARIZZAZIONE';

 --- CLASSIFICATORI LIBERI
 --- INCASSO
 -- gestione classificatori liberi incasso
 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di entrata Infruttifero'
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_26';


 insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select 'SI',
        'INFRUTTIFERO',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_26';

 insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select 'NO',
        'FRUTTIFERO',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_26';

 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di entrata vincolato a conto'
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_27';

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
        'VINCOLATA',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_27';

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
        'LIBERA',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_27';

 --- modalita di incasso
 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Modalità incasso Ordinativo di entrata'
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_28';

insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select '01',
        'CASSA',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_28';

 insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select '02',
        'ACCREDITO BANCA D''ITALIA',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_28';

 insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select '03',
        'REGOLARIZZAZIONE',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_28';

 insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select '04',
        'PRELIEVO DA CC POSTALE',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_28';

 insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select '05',
        'COMPENSAZIONE',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_28';

 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di entrata su prelievo da cc postale numero'
 where tipo.ente_proprietario_id=2
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
 select '15470107',
        '15470107',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '22207120',
        '22207120',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '79017737',
        '79017737',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '10531101',
        '10531101',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '23687106',
        '23687106',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '26103143',
        '26103143',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '10364107',
        '10364107',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '4101',
        '4101',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '37616703',
        '37616703',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '165100',
        '165100',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '189100',
        '189100',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '15395106',
        '15395106',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '22208128',
        '22208128',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '60767258',
        '60767258',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '93322337',
        '93322337',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '1018526952',
        '1018526952',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '1023349408',
        '1023349408',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '1023349465',
        '1023349465',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '1023349598',
        '1023349598',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '1023349648',
        '1023349648',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '1023349101',
        '1023349101',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '1023349168',
        '1023349168',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '1023349267',
        '1023349267',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '1023349341',
        '1023349341',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
 select '1031379470',
        '1031379470',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_29';

 --- PAGAMENTO

 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di pagamento Infruttifero'
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_22';

  insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select 'SI',
        'INFRUTTIFERA',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_22';

 insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select 'NO',
        'FRUTTIFERA',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_22';

 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di pagamento vincolato a conto'
 where tipo.ente_proprietario_id=2
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
        'VINCOLATA',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
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
        'LIBERA',
        tipo.classif_tipo_id,
        '2017-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=2
 and   tipo.classif_tipo_code='CLASSIFICATORE_23';



 --------------- inserimento mif_d_flusso_elaborato per MANDMIF_SPLUS - INIZIO
 INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (1,'flusso_ordinativi',NULL,true,NULL,NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (2,'testata_flusso',NULL,true,'flusso_ordinativi',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and data_cancellazione is null and validita_fine is null limit 1',true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (3,'codice_ABI_BT','Codice ABI della banca destinataria del flusso trasmesso',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_codice_abi_bt','2008',true,NULL,'2017-01-01',2,'admin',1,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (4,'identificativo_flusso','Codice alfanumerico attribuito univocamente al flusso inviato da parte della PA',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_id_flusso_oil',NULL,true,NULL,'2017-01-01',2,'admin',2,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (5,'data_ora_creazione_flusso','YYYY-MM-DDThh:mm:ss',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_data_creazione_flusso',NULL,true,NULL,'2017-01-01',2,'admin',3,'select to_char(NOW(), ''YYYY-MM-DD hh:mm:ss'')',true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (6,'codice_ente','Contiene il codice IPA, che corrisponde al Codice Univoco ufficio della Fatturazione elettronica',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_codice_ente_ipa',NULL,true,NULL,'2017-01-01',2,'admin',4,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (7,'descrizione_ente','Contiene la denominazione IPA',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_desc_ente','Regione Piemonte',true,NULL,'2017-01-01',2,'admin',5,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (8,'codice_istat_ente','Contiene il Codice ISTAT-SIOPE, solo per enti che dispongano di tale codice',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_codice_ente_istat',NULL,true,NULL,'2017-01-01',2,'admin',6,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (9,'codice_fiscale_ente','Contiene il Codice Fiscale Ente',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_codice_ente','80087670016',true,NULL,'2017-01-01',2,'admin',7,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (10,'codice_tramite_ente','Contiene il codice, rilasciato dalla Banca dItalia che identifica univocamente il soggetto delegato dallente al colloquio con SIOPE+',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_codice_ente_tramite',NULL,true,NULL,'2017-01-01',2,'admin',8,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (11,'codice_tramite_BT','Contiene il codice, rilasciato dalla Banca dItalia che identifica univocamente il soggetto delegato dalla BT al colloquio con SIOPE+',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_codice_ente_tramite_bt',NULL,true,NULL,'2017-01-01',2,'admin',9,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (12,'codice_ente_BT','Codice univoco interno, attribuito dalla BT, per mezzo del quale la PA e  riconosciuta dalla banca medesima',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_codice_ente_bt','6220100',true,NULL,'2017-01-01',2,'admin',10,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (13,'riferimento_ente','Eventuale codice concordato tra PA e BT per particolari esigenze',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_spesa','mif_ord_riferimento_ente',NULL,true,NULL,'2017-01-01',2,'admin',11,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (14,'testata_esercizio',NULL,true,'flusso_ordinativi',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and mif_ord_anno_esercizio=:mif_ord_anno_esercizio and data_cancellazione is null and validita_fine is null limit 1',false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (15,'esercizio','Indica lanno desercizio finanziario o contabile',true,'flusso_ordinativi.testata_esercizio','mif_t_ordinativo_spesa','mif_ord_anno_esercizio',NULL,true,NULL,'2017-01-01',2,'admin',12,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (16,'ordinativi',NULL,true,'flusso_ordinativi',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and mif_ord_anno_esercizio=:mif_ord_anno_esercizio and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT :limitOrdinativi OFFSET :offsetOrdinativi',false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (17,'mandato',NULL,true,'flusso_ordinativi.ordinativi',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (18,'tipo_operazione','Tipo operazione relativo allo stato dell ordinativo e della trasmisione (INSERIMENTO,ANNULLO,VARIAZIONE,SOSTITUZIONE)',true,'flusso_ordinativi.ordinativi.mandato','mif_t_ordinativo_spesa','mif_ord_codice_funzione',NULL,true,NULL,'2017-01-01',2,'admin',13,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (19,'numero_mandato','Indica il numero del mandato a cui fanno riferimento tutti i dati che seguono',true,'flusso_ordinativi.ordinativi.mandato','mif_t_ordinativo_spesa','mif_ord_numero',NULL,true,NULL,'2017-01-01',2,'admin',14,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (20,'data_mandato','Indica la data di emissione del mandato da parte della PA, nel formato YYYY-MM-DD',true,'flusso_ordinativi.ordinativi.mandato','mif_t_ordinativo_spesa','mif_ord_data',NULL,true,NULL,'2017-01-01',2,'admin',15,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (21,'importo_mandato','Importo del mandato in oggetto',true,'flusso_ordinativi.ordinativi.mandato','mif_t_ordinativo_spesa','mif_ord_importo',NULL,true,NULL,'2017-01-01',2,'admin',16,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (22,'conto_evidenza','Conto evidenza concordato tra la PA e la BT',true,'flusso_ordinativi.ordinativi.mandato','mif_t_ordinativo_spesa','mif_ord_bci_conto_tes',NULL,true,NULL,'2017-01-01',2,'admin',17,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (23,'estremi_provvedimento_autorizzativo','Indica la tipologia e gli eventuali estremi del provvedimento di autorizzazione della spesa',true,'flusso_ordinativi.ordinativi.mandato','mif_t_ordinativo_spesa','mif_ord_estremi_attoamm',NULL,true,'SPR|ALG','2017-01-01',2,'admin',18,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (24,'responsabile_provvedimento','Identifica il responsabile del provvedimento',true,'flusso_ordinativi.ordinativi.mandato','mif_t_ordinativo_spesa','mif_ord_resp_attoamm',NULL,true,NULL,'2017-01-01',2,'admin',19,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (25,'ufficio_responsabile','Eventuale indicazione dellufficio emittente',false,'flusso_ordinativi.ordinativi.mandato','mif_t_ordinativo_spesa','mif_ord_uff_resp_attomm',NULL,true,NULL,'2017-01-01',2,'admin',20,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (26,'bilancio',NULL,true,'flusso_ordinativi.ordinativi.mandato',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (27,'codifica_bilancio','Identifica il codice di bilancio',true,'flusso_ordinativi.ordinativi.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_codifica_bilancio',NULL,true,NULL,'2017-01-01',2,'admin',21,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (28,'descrizione_codifica','Descrizione del codice di bilancio in esame',true,'flusso_ordinativi.ordinativi.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_desc_codifica_bil',NULL,true,NULL,'2017-01-01',2,'admin',22,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (29,'gestione','Indica la competenza COMPETENZA/RESIDUO',true,'flusso_ordinativi.ordinativi.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_gestione','COMPETENZA|RESIDUO',true,NULL,'2017-01-01',2,'admin',23,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (30,'anno_residuo','Indica lanno residuo, nel formato YYYY',true,'flusso_ordinativi.ordinativi.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_anno_res',NULL,true,NULL,'2017-01-01',2,'admin',24,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (31,'numero_articolo','Indica il numero dellarticolo',false,'flusso_ordinativi.ordinativi.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_articolo',NULL,true,NULL,'2017-01-01',2,'admin',25,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (32,'voce_economica','Indica la voce economica',false,'flusso_ordinativi.ordinativi.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_voce_eco',NULL,true,NULL,'2017-01-01',2,'admin',26,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (33,'importo_bilancio','Importo relativo al codice bilancio e articolo precedentemente indicati',true,'flusso_ordinativi.ordinativi.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_importo_bil',NULL,true,NULL,'2017-01-01',2,'admin',27,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (34,'funzionario_delegato','Aggregazione opzionale funzionario_delegato',false,'flusso_ordinativi.ordinativi.mandato','mif_t_ordinativo_spesa',NULL,NULL,true,NULL,'2017-01-01',2,'admin',28,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (35,'codice_funzionario_delegato','Indica il codice fiscale o altro codice concordato tra PA e BT del funzionario delegato.',false,'flusso_ordinativi.ordinativi.mandato.funzionario_delegato','mif_t_ordinativo_spesa',NULL,NULL,true,NULL,'2017-01-01',2,'admin',29,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (36,'importo_funzionario_delegato','Importo attribuito al funzionario delegato',false,'flusso_ordinativi.ordinativi.mandato.funzionario_delegato','mif_t_ordinativo_spesa',NULL,NULL,true,NULL,'2017-01-01',2,'admin',30,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (37,'tipologia_pagamento_funzionario_delegato','Tipologia del pagamento funzionario delegato',false,'flusso_ordinativi.ordinativi.mandato.funzionario_delegato','mif_t_ordinativo_spesa',NULL,NULL,true,NULL,'2017-01-01',2,'admin',31,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (38,'numero_pagamento_funzionario_delegato','Numero del pagamento attribuito al funzionario delegato',false,'flusso_ordinativi.ordinativi.mandato.funzionario_delegato','mif_t_ordinativo_spesa',NULL,NULL,true,NULL,'2017-01-01',2,'admin',32,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (39,'informazioni_beneficiario',NULL,true,'flusso_ordinativi.ordinativi.mandato',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (40,'progressivo_beneficiario','Indica il numero progressivo del beneficiario allinterno dello stesso ordinativo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_progr_benef','1',true,NULL,'2017-01-01',2,'admin',33,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (41,'importo_beneficiario','Importo relativo al beneficiario in oggetto',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_importo_benef',NULL,true,NULL,'2017-01-01',2,'admin',34,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (42,'tipo_pagamento','Tipo pagamento Siope Plus',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_tipo','COMPENSAZIONE',true,'IT|CB|REG|SEPA|EXTRASEPA','2017-01-01',2,'admin',35,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (43,'impignorabili','Indica pagamenti riferibili a somme non passibili di pignoramento',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_progr_impignor','SI',true,NULL,'2017-01-01',2,'admin',36,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (44,'frazionabile','Si riferisce a pagamenti non frazionabili, in vigenza di esercizio provvisorio, unico valore ammesso NO',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_class_codice_gest_fraz','NO',true,'2017-01-01|CLASSIFICATORE_21|01|flagFrazionabile','2017-01-01',2,'admin',37,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (45,'gestione_provvisoria','Puo assumere il solo valore SI in caso di mancata approvazione del bilancio di previsione entro il termine di legge',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_class_codice_gest_prov','SI',true,'E','2017-01-01',2,'admin',38,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (46,'data_esecuzione_pagamento','Indica la data di esecuzione del pagamento; deve essere una data futura, nel formato YYYY-MM-DD secondo il formalismo ISO 8601',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_data_esec',NULL,true,'REGOLARIZZAZIONE','2017-01-01',2,'admin',39,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (47,'data_scadenza_pagamento','E  la data di disponibilita  dei fondi sul conto corrente di destinazione, nel formato YYYY-MM-DD secondo il formalismo ISO 8601[1]. ',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_data_scad',NULL,true,'','2017-01-01',2,'admin',40,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (48,'destinazione','LIBERA/VINCOLATA - classificatore o legame con conto corrente di tesoreria',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_progr_dest','LIBERA',true,'CLASSIFICATORE_23','2017-01-01',2,'admin',41,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (49,'numero_conto_banca_italia_ente_ricevente','Indica il numero di conto o contabilita  speciale dellente beneficiario in Banca dItalia, nel caso di operazioni di girofondi Banca dItalia, linformazione seguente tipo_contabilita_ente_ricevente indica la natura del conto Banca dItalia di destinazione',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_bci_conto',NULL,true,'CBI|REGOLARIZZAZIONE','2017-01-01',2,'admin',42,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (50,'tipo_contabilita_ente_ricevente','FRUTTIFERA/INFRUTTIFERA - classificatore o legame con conto tesoreria',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_bci_tipo_contabil','INFRUTTIFERA',true,'CLASSIFICATORE_22|SI|INFRUTTIFERA|FRUTTIFERA','2017-01-01',2,'admin',43,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (51,'tipo_postalizzazione','A fronte di un tipo_pagamento ASSEGNO BANCARIO E POSTALE o ASSEGNO CIRCOLARE',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_postalizza','COME DA CONVENZIONE',true,'ASSEGNO BANCARIO E POSTALE|ASSEGNO CIRCOLARE','2017-01-01',2,'admin',44,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (52,'classificazione',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (53,'codice_cgu','Codice associato ad ogni ordinativo di pagamento costituito dal codice SIOPE',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione','mif_t_ordinativo_spesa','mif_ord_class_codice_cge',NULL,true,'SIOPE_SPESA_I|XXXX|2017-01-01|PDC_V','2017-01-01',2,'admin',45,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (54,'codice_cup','Codice Unico Progetto',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione','mif_t_ordinativo_spesa','mif_ord_class_codice_cup',NULL,true,'cup','2017-01-01',2,'admin',46,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (55,'codice_cpv','Identifica il Common Procurement Vocabulary',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione','mif_t_ordinativo_spesa','mif_ord_class_codice_cpv',NULL,true,NULL,'2017-01-01',2,'admin',47,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (56,'importo','Importo associato allUnita  Elementare Statistica',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione','mif_t_ordinativo_spesa','mif_ord_class_importo',NULL,true,NULL,'2017-01-01',2,'admin',48,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (57,'classificazione_dati_siope_uscite',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (58,'tipo_debito_siope_c','Contiene il tipo di debito commerciale dellente',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite','mif_t_ordinativo_spesa','mif_ord_class_tipo_debito','',true,'COMMERCIALE','2017-01-01',2,'admin',49,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (59,'tipo_debito_siope_nc','Contiene il tipo di debito non commerciale dellente',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite','mif_t_ordinativo_spesa','mif_ord_class_tipo_debito_nc',NULL,true,'NON_COMMERCIALE','2017-01-01',2,'admin',50,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (60,'codice_cig_siope','Contiene il Codice CIG che identifica una dato appalto',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite','mif_t_ordinativo_spesa','mif_ord_class_cig',NULL,true,'cig','2017-01-01',2,'admin',51,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (61,'motivo_esclusione_cig_siope','Specifica il motivo dellesclusione del Codice CIG',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite','mif_t_ordinativo_spesa','mif_ord_class_motivo_nocig',NULL,true,NULL,'2017-01-01',2,'admin',52,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (62,'fatture_siope',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_spesa_documenti where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (63,'fattura_siope','Contiene la fattura eventualmente associata al mandato',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (64,'codice_ipa_ente_siope','Contiene il Codice IPA del destinatario della fattura come indicato nella fattura stessa ',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_codice_ipa_ente',NULL,true,'30|FPR|FAT,NCD','2017-01-01',2,'admin',53,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (65,'tipo_documento_siope_e','Indica se si tratta di un documento elettronico',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_tipo','',true,'ELETTRONICO','2017-01-01',2,'admin',54,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (66,'tipo_documento_siope_a','Indica se si tratta di un documento analogico',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_tipo_a',NULL,true,'ANALOGICO','2017-01-01',2,'admin',55,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (67,'identificativo_lotto_sdi_siope','Contiene lIdentificativo del Lotto SDI con cui e  stata trasmessa la fattura elettronica',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_id_lotto_sdi',NULL,true,'','2017-01-01',2,'admin',56,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (68,'tipo_documento_analogico_siope','Indica la tipologia del documento nel caso in cui questo e  non si riferisca ad una fattura elettronica PA',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_tipo_analog','',true,'','2017-01-01',2,'admin',57,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (69,'codice_fiscale_emittente_siope','Codice fiscale dellemittente la fattura analogica o il documento equivalente',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_codfisc_emis',NULL,true,'ANALOGICO','2017-01-01',2,'admin',58,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (70,'anno_emissione_fattura_siope','Indica lanno di emissione della fattura analogica o del documento equivalente, nel formato YYYY',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_anno',NULL,true,NULL,'2017-01-01',2,'admin',59,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (71,'dati_fattura_siope',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (72,'numero_fattura_siope','Contiene il numero della fattura',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope.dati_fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_numero',NULL,true,NULL,'2017-01-01',2,'admin',60,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (73,'importo_siope','Contiene limporto in pagamento per la fattura',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope.dati_fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_importo',NULL,true,NULL,'2017-01-01',2,'admin',61,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (74,'data_scadenza_pagam_siope','Contiene la data di scadenza del pagamento, nel formato YYYY-MM-DD secondo il formalismo ISO 8601',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope.dati_fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_data_scadenza',NULL,true,'dataScadenzaDopoSospensione','2017-01-01',2,'admin',62,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (75,'motivo_scadenza_siope','Indica la ragione che determina la scadenza del pagamento',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope.dati_fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_motivo_scadenza','',true,NULL,'2017-01-01',2,'admin',63,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (76,'natura_spesa_siope','Contiene la natura di spesa della fattura',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.fatture_siope.fattura_siope.dati_fattura_siope','mif_t_ordinativo_spesa_documenti','mif_ord_doc_natura_spesa','',true,'1|CORRENTE|2|CAPITALE','2017-01-01',2,'admin',64,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (77,'dati_ARCONET_siope',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (78,'codice_missione_siope','Contiene il Codice Missione',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.dati_ARCONET_siope','mif_t_ordinativo_spesa','mif_ord_class_missione',NULL,true,'Spesa - MissioniProgrammi','2017-01-01',2,'admin',65,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (79,'codice_programma_siope','Contiene il Codice Programma',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.dati_ARCONET_siope','mif_t_ordinativo_spesa','mif_ord_class_programma',NULL,true,'PROGRAMMA','2017-01-01',2,'admin',66,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (80,'codice_economico_siope','Contiene il Codice Economico',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.dati_ARCONET_siope','mif_t_ordinativo_spesa','mif_ord_class_economico',NULL,true,'PDC_V|OP','2017-01-01',2,'admin',67,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (81,'importo_codice_economico_siope','Contiene l importo del Codice Economico',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.dati_ARCONET_siope','mif_t_ordinativo_spesa','mif_ord_class_importo_economico',NULL,true,NULL,'2017-01-01',2,'admin',68,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (82,'codice_UE_siope','Contiene il Codice UE',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.dati_ARCONET_siope','mif_t_ordinativo_spesa','mif_ord_class_transaz_ue',NULL,true,'TRANSAZIONE_UE_SPESA','2017-01-01',2,'admin',69,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (83,'codice_uscita_siope','Contiene identificativo uscita RICORRENTE/NON RICORRENTE',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.dati_ARCONET_siope','mif_t_ordinativo_spesa','mif_ord_class_ricorrente_spesa','',true,'RICORRENTE_SPESA','2017-01-01',2,'admin',70,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (84,'cofog_siope',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.dati_ARCONET_siope',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (85,'codice_cofog_siope','Contiente il codice Cofog',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.dati_ARCONET_siope.cofog_siope','mif_t_ordinativo_spesa','mif_ord_class_cofog_codice',NULL,true,'GRUPPO_COFOG','2017-01-01',2,'admin',71,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (86,'importo_cofog_siope','Contiene l importo Cofog',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite.dati_ARCONET_siope.cofog_siope','mif_t_ordinativo_spesa','mif_ord_class_cofog_importo',NULL,true,NULL,'2017-01-01',2,'admin',72,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (87,'bollo',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (88,'assoggettamento_bollo','Tipo assoggettamento bollo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_carico','ESENTE BOLLO|DOCUMENTO A REGOLARIZZAZIONE DI PROVVISORI/SOSPESI',true,'REGOLARIZZAZIONE|F24EP','2017-01-01',2,'admin',73,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (89,'causale_esenzione_bollo','Motivazione di esenzione del bollo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ordin_bollo_caus_esenzione','',true,'','2017-01-01',2,'admin',74,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (90,'spese',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (91,'soggetto_destinatario_delle_spese','Soggetto destinatario delle spese ( commissioni )',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.spese','mif_t_ordinativo_spesa','mif_ord_commissioni_carico',NULL,true,NULL,'2017-01-01',2,'admin',75,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (92,'natura_pagamento','Motivazione dell esenzione delle spese',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.spese','mif_t_ordinativo_spesa','mif_ord_commissioni_natura',NULL,true,NULL,'2017-01-01',2,'admin',76,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (93,'causale_esenzione_spese','Descrizione dell esenzione se non esiste motivazione',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.spese','mif_t_ordinativo_spesa','mif_ord_commissioni_esenzione',NULL,true,NULL,'2017-01-01',2,'admin',77,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (94,'beneficiario',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,'','2017-01-01',2,'admin',78,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (95,'anagrafica_beneficiario','Indica il nome o la ragione sociale del beneficiario',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_anag_benef',NULL,true,'CBI','2017-01-01',2,'admin',79,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (96,'indirizzo_beneficiario','Indica l indirizzo del beneficiario',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_indir_benef',NULL,true,NULL,'2017-01-01',2,'admin',80,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (97,'cap_beneficiario','Indica il CAP del beneficiario',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_cap_benef',NULL,true,NULL,'2017-01-01',2,'admin',81,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (98,'localita_beneficiario','Indica la localita  del beneficiario. Comune di residenza',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_localita_benef',NULL,true,NULL,'2017-01-01',2,'admin',82,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (99,'provincia_beneficiario','Indica la provincia del beneficiario. ',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_prov_benef',NULL,true,NULL,'2017-01-01',2,'admin',83,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (100,'stato_beneficiario','Indicato lo stato del beneficiario',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_stato_benef',NULL,true,NULL,'2017-01-01',2,'admin',84,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (101,'partita_iva_beneficiario','Indica la partita iva del beneficiario',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_partiva_benef',NULL,true,NULL,'2017-01-01',2,'admin',85,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (102,'codice_fiscale_beneficiario','Indica il codice fiscale del beneficiario',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_codfisc_benef',NULL,true,'CO','2017-01-01',2,'admin',86,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (103,'delegato','Sezione relativa al soggetto quietanzante',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_benef_quiet',NULL,true,'CO|REGOLARIZZAZIONE','2017-01-01',2,'admin',87,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (104,'anagrafica_delegato','Indica il nome del quietanzante',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_anag_quiet',NULL,true,NULL,'2017-01-01',2,'admin',88,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (105,'indirizzo_delegato','Indica l indirizzo del quietanzante',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_indir_quiet',NULL,true,NULL,'2017-01-01',2,'admin',89,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (106,'cap_delegato','Indica il Cap del quietanzante',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_cap_quiet',NULL,true,NULL,'2017-01-01',2,'admin',90,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (107,'localita_delegato','Indica la localita  del quietanzante',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_localita_quiet',NULL,true,NULL,'2017-01-01',2,'admin',91,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (108,'provincia_delegato','Indica la provincia del quietanzante',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_prov_quiet',NULL,true,NULL,'2017-01-01',2,'admin',92,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (109,'stato_delegato','Indica lo stato del quietanzante',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_stato_quiet',NULL,true,NULL,'2017-01-01',2,'admin',93,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (110,'partiva_iva_delegato','Indica la partita iva del quietanzante',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_partiva_quiet',NULL,true,NULL,'2017-01-01',2,'admin',94,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (111,'codice_fiscale_delegato','Indica il codice fiscale del quietanzante',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_codfisc_quiet',NULL,true,NULL,'2017-01-01',2,'admin',95,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (112,'creditore_effettivo','Sezione relativa alla cessione incasso',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_delegato',NULL,true,'CSI|CO|REGOLARIZZAZIONE','2017-01-01',2,'admin',96,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (113,'anagrafica_creditore_effettivo','Indica il soggetto di cessione del creditore effettivo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.creditore_effettivo','mif_t_ordinativo_spesa','mif_ord_anag_del',NULL,true,NULL,'2017-01-01',2,'admin',97,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (114,'indirizzo_creditore_effettivo','Indica l indirizzo di cessione del creditore effettivo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.creditore_effettivo','mif_t_ordinativo_spesa','mif_ord_indir_del',NULL,true,NULL,'2017-01-01',2,'admin',98,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (115,'cap_creditore_effettivo','Indica il cap di cessione del creditore effettivo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.creditore_effettivo','mif_t_ordinativo_spesa','mif_ord_cap_del',NULL,true,NULL,'2017-01-01',2,'admin',99,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (116,'localita_creditore_effettivo','Indica la localita  di cessione del creditore effettivo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.creditore_effettivo','mif_t_ordinativo_spesa','mif_ord_localita_del',NULL,true,NULL,'2017-01-01',2,'admin',100,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (117,'provincia_creditore_effettivo','Inidica la provincia di cessione del creditore effettivo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.creditore_effettivo','mif_t_ordinativo_spesa','mif_ord_prov_del',NULL,true,NULL,'2017-01-01',2,'admin',101,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (118,'stato_creditore_effettivo','Indica lo stato di cessione del creditore effettivo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.creditore_effettivo','mif_t_ordinativo_spesa','mif_ord_stato_del',NULL,true,NULL,'2017-01-01',2,'admin',102,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (119,'partita_iva_creditore_effettivo','Indica la partita iva di cessione del creditore effettivo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.creditore_effettivo','mif_t_ordinativo_spesa','mif_ord_partiva_del',NULL,true,NULL,'2017-01-01',2,'admin',103,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (120,'codice_fiscale_creditore_effettivo','Indicato il codice fiscale di cessione del creditore effettivo',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.creditore_effettivo','mif_t_ordinativo_spesa','mif_ord_codfisc_del',NULL,true,NULL,'2017-01-01',2,'admin',104,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (121,'piazzatura','Sezione estremi di pagamento',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_piazzatura',NULL,true,'2|CB|CCP|3|INSERIMENTO|VARIAZIONE|ANNULLO|@REGOLARIZZAZIONE@COMPENSAZIONE','2017-01-01',2,'admin',105,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (122,'abi_beneficiario','Abi',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_abi_benef',NULL,true,'CB|IT','2017-01-01',2,'admin',106,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (123,'cab_beneficiario','Cab',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cab_benef',NULL,true,'CB|IT','2017-01-01',2,'admin',107,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (124,'numero_conto_corrente_beneficiario','Num CC',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cc_benef',NULL,true,'CB|IT|CCP','2017-01-01',2,'admin',108,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (125,'caratteri_controllo','CRTL',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_ctrl_benef',NULL,true,'CB|IT','2017-01-01',2,'admin',109,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (126,'codice_cin','Cin',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cin_benef',NULL,true,'CB|IT','2017-01-01',2,'admin',110,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (127,'codice_paese','Paese',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cod_paese_benef',NULL,true,'CB|IT','2017-01-01',2,'admin',111,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (128,'denominazione_banca_destinataria','Denominazione Banca',false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_denom_banca_benef',NULL,true,'CB','2017-01-01',2,'admin',112,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (129,'sepa_credit_transfer','Sezione pagamenti SEPA',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,'IT|CB|SEPA','2017-01-01',2,'admin',113,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (130,'iban','IBAN SEPA',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_iban_tr',NULL,true,NULL,'2017-01-01',2,'admin',114,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (131,'bic','BIC SEPA',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_bic_tr',NULL,true,NULL,'2017-01-01',2,'admin',115,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (132,'identificativo_end_to_end',NULL,false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',116,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (133,'identificativo_category_purpose',NULL,false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',117,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (134,'code',NULL,false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',118,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (135,'proprietary',NULL,false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',119,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (136,'codice_versante',NULL,false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',120,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (137,'causale','Causale pagamento',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_causale',NULL,true,'cup|cig','2017-01-01',2,'admin',121,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (138,'sospesi','Sezione provvisori di spesa',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_spesa_ricevute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (139,'sospeso',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sospesi',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (140,'numero_provvisorio','Numero provvisorio di spesa',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sospesi.sospeso','mif_t_ordinativo_spesa_ricevute','mif_ord_ric_numero',NULL,true,NULL,'2017-01-01',2,'admin',122,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (141,'importo_provvisorio','Importo provvisorio di spesa',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sospesi.sospeso','mif_t_ordinativo_spesa_ricevute','mif_ord_ric_importo',NULL,true,NULL,'2017-01-01',2,'admin',123,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (142,'ritenute_testata','Sezione ritenute',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_spesa_ritenute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (143,'ritenute','Sezione ritenute',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.ritenute_testata',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (144,'importo_ritenute','Importo ritenuta',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.ritenute_testata.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_importo',NULL,true,'RIT_ORD|SPR|SUB_ORD|IRPEF|INPS|IRPEG','2017-01-01',2,'admin',124,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (145,'numero_reversale','Numero ordinativo di incasso ritenuta',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.ritenute_testata.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_numero',NULL,true,NULL,'2017-01-01',2,'admin',125,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (146,'progressivo_versante',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.ritenute_testata.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_progr_rev','1',true,NULL,'2017-01-01',2,'admin',126,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (147,'informazioni_aggiuntive','Raggruppamento di informazioni facoltative',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (148,'lingua','Lingua',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_lingua','ITALIANO',true,NULL,'2017-01-01',2,'admin',127,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (149,'riferimento_documento_esterno','Riferimento documento esterno',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_rif_doc_esterno','DISPOSIZIONE DOCUMENTO ESTERNO|STIPENDI',true,'DISPOSIZIONE DOCUMENTO ESTERNO|BONIFICO ESTERO EURO|STI','2017-01-01',2,'admin',128,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (150,'sostituzione_mandato','Sezione Mandato sostituizione',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_sost_mand',NULL,true,'SOS_ORD','2017-01-01',2,'admin',129,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (151,'numero_mandato_da_sostituire','Numero Mandato da sostuire',true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_num_ord_colleg',NULL,true,NULL,'2017-01-01',2,'admin',130,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (152,'progressivo_beneficiario_da_sostuire',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_progr_ord_colleg','1',true,NULL,'2017-01-01',2,'admin',131,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (153,'esercizio_mandato_da_sostituire',NULL,true,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_anno_ord_colleg',NULL,true,NULL,'2017-01-01',2,'admin',132,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (154,'dati_a_disposizione_ente_beneficiario',NULL,false,'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (155,'dati_a_disposizione_ente_mandato',NULL,true,'flusso_ordinativi.ordinativi.mandato',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (156,'codice_raggruppamento',NULL,true,'flusso_ordinativi.ordinativi.mandato.dati_a_disposizione_ente_mandato','mif_t_ordinativo_spesa','mif_ord_codice_distinta',NULL,true,NULL,'2017-01-01',2,'admin',133,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (157,'atto_contabile',NULL,true,'flusso_ordinativi.ordinativi.mandato.dati_a_disposizione_ente_mandato','mif_t_ordinativo_spesa','mif_ord_codice_atto_contabile',NULL,true,'ALG','2017-01-01',2,'admin',134,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));

 --------------- inserimento mif_d_flusso_elaborato per MANDMIF_SPLUS - FINE


  --------------- inserimento mif_d_flusso_elaborato per REVMIF_SPLUS - INIZIO

 INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (1,'flusso_ordinativi',NULL,true,NULL,NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (2,'testata_flusso',NULL,true,'flusso_ordinativi',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_entrata where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and data_cancellazione is null and validita_fine is null limit 1',true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (3,'codice_ABI_BT','Codice ABI della banca destinataria del flusso trasmesso',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_codice_abi_bt','2008',true,NULL,'2017-01-01',2,'admin',1,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (4,'identificativo_flusso','Codice alfanumerico attribuito univocamente al flusso inviato da parte della PA',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_id_flusso_oil',NULL,true,NULL,'2017-01-01',2,'admin',2,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (5,'data_ora_creazione_flusso','YYYY-MM-DDThh:mm:ss',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_data_creazione_flusso',NULL,true,NULL,'2017-01-01',2,'admin',3,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (6,'codice_ente','Contiene il codice IPA, che corrisponde al Codice Univoco ufficio della Fatturazione elettronica',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_codice_ente_ipa',NULL,true,NULL,'2017-01-01',2,'admin',4,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (7,'descrizione_ente','Contiene la denominazione IPA',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_desc_ente','Regione Piemonte',true,NULL,'2017-01-01',2,'admin',5,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (8,'codice_istat_ente','Contiene il Codice ISTAT-SIOPE, solo per enti che dispongano di tale codice',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_codice_ente_istat',NULL,true,NULL,'2017-01-01',2,'admin',6,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (9,'codice_fiscale_ente','Contiene il Codice Fiscale Ente',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_codice_ente','80087670016',true,NULL,'2017-01-01',2,'admin',7,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (10,'codice_tramite_ente','Contiene il codice, rilasciato dalla Banca dItalia che identifica univocamente il soggetto delegato dallente al colloquio con SIOPE+',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_codice_ente_tramite',NULL,true,NULL,'2017-01-01',2,'admin',8,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (11,'codice_tramite_BT','Contiene il codice, rilasciato dalla Banca dItalia che identifica univocamente il soggetto delegato dalla BT al colloquio con SIOPE+',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_codice_ente_tramite_bt',NULL,true,NULL,'2017-01-01',2,'admin',9,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (12,'codice_ente_BT','Codice univoco interno, attribuito dalla BT, per mezzo del quale la PA e  riconosciuta dalla banca medesima',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_codice_ente_bt','6220100',true,NULL,'2017-01-01',2,'admin',10,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (13,'riferimento_ente','Eventuale codice concordato tra PA e BT per particolari esigenze',true,'flusso_ordinativi.testata_flusso','mif_t_ordinativo_entrata','mif_ord_riferimento_ente',NULL,true,NULL,'2017-01-01',2,'admin',11,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (14,'testata_esercizio',NULL,true,'flusso_ordinativi',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_entrata where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and mif_ord_anno_esercizio=:mif_ord_anno_esercizio and data_cancellazione is null and validita_fine is null limit 1',false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (15,'esercizio','Indica lanno desercizio finanziario o contabile',true,'flusso_ordinativi.testata_esercizio','mif_t_ordinativo_entrata','mif_ord_anno_esercizio',NULL,true,NULL,'2017-01-01',2,'admin',12,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (16,'ordinativi',NULL,true,'flusso_ordinativi',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_entrata where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and mif_ord_anno_esercizio=:mif_ord_anno_esercizio and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT :limitOrdinativi OFFSET :offsetOrdinativi',false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (17,'reversale',NULL,true,'flusso_ordinativi.ordinativi',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (18,'tipo_operazione','Tipo operazione relativo allo stato dell ordinativo e della trasmisione (INSERIMENTO,ANNULLO,VARIAZIONE,SOSTITUZIONE)',true,'flusso_ordinativi.ordinativi.reversale','siac_t_ordinativo_entrata','mif_ord_codice_funzione',NULL,true,NULL,'2017-01-01',2,'admin',13,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (19,'numero_reversale','Indica il numero della reversale a cui fanno riferimento tutti i dati che seguono',true,'flusso_ordinativi.ordinativi.reversale','siac_t_ordinativo_entrata','mif_ord_numero',NULL,true,NULL,'2017-01-01',2,'admin',14,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (20,'data_reversale','Indica la data di emissione della reversale da parte della PA, nel formato YYYY-MM-DD',true,'flusso_ordinativi.ordinativi.reversale','siac_t_ordinativo_entrata','mif_ord_data',NULL,true,NULL,'2017-01-01',2,'admin',15,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (21,'importo_reversale','Importo della reversale in oggetto',true,'flusso_ordinativi.ordinativi.reversale','siac_t_ordinativo_entrata','mif_ord_importo',NULL,true,NULL,'2017-01-01',2,'admin',16,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (22,'conto_evidenza','Conto evidenza concordato tra la PA e la BT',true,'flusso_ordinativi.ordinativi.reversale','siac_t_ordinativo_entrata','mif_ord_destinazione',NULL,true,NULL,'2017-01-01',2,'admin',17,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (23,'bilancio',NULL,true,'flusso_ordinativi.ordinativi.reversale',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (24,'codifica_bilancio','Identifica il codice di bilancio',true,'flusso_ordinativi.ordinativi.reversale.bilancio','siac_t_ordinativo_entrata','mif_ord_codifica_bilancio',NULL,true,NULL,'2017-01-01',2,'admin',18,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (25,'descrizione_codifica','Descrizione del codice di bilancio in esame',true,'flusso_ordinativi.ordinativi.reversale.bilancio','siac_t_ordinativo_entrata','mif_ord_desc_codifica',NULL,true,NULL,'2017-01-01',2,'admin',19,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (26,'gestione','Indica la competenza COMPETENZA/RESIDUO',true,'flusso_ordinativi.ordinativi.reversale.bilancio','siac_t_ordinativo_entrata','mif_ord_gestione','COMPETENZA|RESIDUO',true,NULL,'2017-01-01',2,'admin',20,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (27,'anno_residuo','Indica lanno residuo, nel formato YYYY',true,'flusso_ordinativi.ordinativi.reversale.bilancio','siac_t_ordinativo_entrata','mif_ord_anno_res',NULL,true,NULL,'2017-01-01',2,'admin',21,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (28,'numero_articolo','Indica il numero dellarticolo',false,'flusso_ordinativi.ordinativi.reversale.bilancio','siac_t_ordinativo_entrata','mif_ord_articolo',NULL,true,NULL,'2017-01-01',2,'admin',22,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (29,'voce_economica','Indica la voce economica',false,'flusso_ordinativi.ordinativi.reversale.bilancio','siac_t_ordinativo_entrata','mif_ord_voce_eco',NULL,true,NULL,'2017-01-01',2,'admin',23,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (30,'importo_bilancio','Importo relativo al codice bilancio e articolo precedentemente indicati',true,'flusso_ordinativi.ordinativi.reversale.bilancio','siac_t_ordinativo_entrata','mif_ord_importo_bil',NULL,true,NULL,'2017-01-01',2,'admin',24,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (31,'informazioni_versante',NULL,true,'flusso_ordinativi.ordinativi.reversale',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (32,'progressivo_versante','Indica il numero progressivo del beneficiario allinterno dello stesso ordinativo',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante','siac_t_ordinativo_entrata','mif_ord_progr_vers','1',true,NULL,'2017-01-01',2,'admin',25,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (33,'importo_versante','Importo relavito al versante in oggetto',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante','siac_t_ordinativo_entrata','mif_ord_vers_importo',NULL,true,NULL,'2017-01-01',2,'admin',26,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (34,'tipo_riscossione','Tipo incasso',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante','siac_t_ordinativo_entrata','mif_ord_vers_tipo_riscos','COMPENSAZIONE|REGOLARIZZAZIONE|CASSA',true,'CLASSIFICATORE_28|RIT_ORD|SPR|SUB_ORD|IRPEF|INPS|IRPEG','2017-01-01',2,'admin',27,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (35,'numero_ccp','Numero CC per prelievo da CC postale',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante','siac_t_ordinativo_entrata','mif_ord_vers_cc_postale',NULL,true,'PRELIEVO DA CC POSTALE|CLASSIFICATORE_29','2017-01-01',2,'admin',28,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (36,'tipo_entrata',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante','siac_t_ordinativo_entrata','mif_ord_bci_tipo_entrata','INFRUTTIFERO',true,'CLASSIFICATORE_26|SI|INFRUTTIFERO|FRUTTIFERO','2017-01-01',2,'admin',29,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (37,'destinazione',NULL,false,'flusso_ordinativi.ordinativi.reversale.informazioni_versante','siac_t_ordinativo_entrata','mif_ord_vers_cod_riscos','LIBERA',true,'CLASSIFICATORE_27','2017-01-01',2,'admin',30,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (38,'classificazione','Indicazione congiunta codice_CGE',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (39,'codice_cge',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione','siac_t_ordinativo_entrata','mif_ord_class_codice_cge',NULL,true,'SIOPE_ENTRATA_I|XXXX|2017-01-01|PDC_V','2017-01-01',2,'admin',31,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (40,'importo',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione','siac_t_ordinativo_entrata','mif_ord_class_importo',NULL,true,NULL,'2017-01-01',2,'admin',32,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (41,'classificazione_dati_siope_entrate',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (42,'tipo_debito_siope_c','Tipo debito commerciale',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate','siac_t_ordinativo_entrata','mif_ord_class_tipo_debito','COMMERCIALE',true,'SPR','2017-01-01',2,'admin',33,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (43,'tipo_debito_siope_nc','Tipo debito non commerciale',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate','siac_t_ordinativo_entrata','mif_ord_class_tipo_debito_nc','NON_COMMERCIALE',true,'','2017-01-01',2,'admin',34,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (44,'fatture_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_spesa_documenti where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id
',false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (45,'fattura_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (46,'codice_ipa_ente_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_codice_ipa_ente',NULL,true,'30|FPR|FAT,NCD','2017-01-01',2,'admin',35,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (47,'tipo_documento_siope_e','Tipo documento elettronico',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_tipo',NULL,true,'ELETTRONICO','2017-01-01',2,'admin',36,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (48,'tipo_documento_siope_a','Tipo documento analogico',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_tipo_a',NULL,true,'ANALOGICO','2017-01-01',2,'admin',37,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (49,'identificativo_lotto_sdi_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_id_lotto_sdi',NULL,true,NULL,'2017-01-01',2,'admin',38,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (50,'tipo_documento_analogico_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_tipo_analog',NULL,true,NULL,'2017-01-01',2,'admin',39,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (51,'codice_fiscale_emittente_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_codfisc_emis',NULL,true,'ANALOGICO','2017-01-01',2,'admin',40,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (52,'anno_emissione_fattura_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_anno',NULL,true,NULL,'2017-01-01',2,'admin',41,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (53,'dati_fattura_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (54,'numero_fattura_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope.dati_fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_numero',NULL,true,NULL,'2017-01-01',2,'admin',42,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (55,'importo_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope.dati_fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_importo',NULL,true,NULL,'2017-01-01',2,'admin',43,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (56,'data_scadenza_pagam_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope.dati_fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_data_scadenza',NULL,true,'dataScadenzaDopoSospensione','2017-01-01',2,'admin',44,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (57,'motivo_scadenza_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope.dati_fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_motivo_scadenza',NULL,true,NULL,'2017-01-01',2,'admin',45,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (58,'natura_spesa_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope.dati_fattura_siope','siac_t_ordinativo_spesa_documenti','mif_ord_doc_natura_spesa',NULL,true,'1|CORRENTE|2|CAPITALE|MACROAGGREGATO','2017-01-01',2,'admin',46,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (59,'dati_ARCONET_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (60,'codice_economico_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.dati_ARCONET_siope','mif_t_ordinativo_entrata','mif_ord_class_economico',NULL,true,'PDC_V|OI','2017-01-01',2,'admin',47,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (61,'importo_codice_economico_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.dati_ARCONET_siope','mif_t_ordinativo_entrata','mif_ord_class_importo_economico',NULL,true,NULL,'2017-01-01',2,'admin',48,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (62,'codice_UE_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.dati_ARCONET_siope','mif_t_ordinativo_entrata','mif_ord_class_transaz_ue',NULL,true,'TRANSAZIONE_UE_ENTRATA','2017-01-01',2,'admin',49,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (63,'codice_entrata_siope',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.dati_ARCONET_siope','mif_t_ordinativo_entrata','mif_ord_class_ricorrente_entrata',NULL,true,'RICORRENTE_ENTRATA','2017-01-01',2,'admin',50,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (64,'bollo',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (65,'assoggettamento_bollo','Tipo assoggettamento bollo',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.bollo','mif_t_ordinativo_entrata','mif_ord_bollo_carico','ESENTE BOLLO|DOCUMENTO A REGOLARIZZAZIONE DI PROVVISORI/SOSPESI',true,'REGOLARIZZAZIONE','2017-01-01',2,'admin',51,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (66,'causale_esenzione_bollo','Motivazione di esenzione del bollo',true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.bollo','mif_t_ordinativo_entrata','mif_ord_bollo_esenzione',NULL,true,NULL,'2017-01-01',2,'admin',52,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (67,'versante',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (68,'anagrafica_versante',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.versante','mif_t_ordinativo_entrata','mif_ord_anag_versante',NULL,true,NULL,'2017-01-01',2,'admin',53,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (69,'indirizzo_versante',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.versante','mif_t_ordinativo_entrata','mif_ord_indir_versante',NULL,true,NULL,'2017-01-01',2,'admin',54,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (70,'cap_versante',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.versante','mif_t_ordinativo_entrata','mif_ord_cap_versante',NULL,true,NULL,'2017-01-01',2,'admin',55,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (71,'localita_versante',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.versante','mif_t_ordinativo_entrata','mif_ord_localita_versante',NULL,true,NULL,'2017-01-01',2,'admin',56,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (72,'provincia_versante',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.versante','mif_t_ordinativo_entrata','mif_ord_prov_versante',NULL,true,NULL,'2017-01-01',2,'admin',57,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (73,'stato_versante',NULL,false,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.versante','mif_t_ordinativo_entrata','mif_ord_stato_versante',NULL,true,NULL,'2017-01-01',2,'admin',58,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (74,'partita_iva_versante',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.versante','mif_t_ordinativo_entrata','mif_ord_partiva_versante',NULL,true,NULL,'2017-01-01',2,'admin',59,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (75,'codice_fiscale_versante',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.versante','mif_t_ordinativo_entrata','mif_ord_codfisc_versante',NULL,true,NULL,'2017-01-01',2,'admin',60,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (76,'causale',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante','mif_t_ordinativo_entrata','mif_ord_vers_causale',NULL,true,NULL,'2017-01-01',2,'admin',61,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (77,'sospesi',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,'select * from mif_t_ordinativo_entrata_ricevute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (78,'sospeso',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.sospesi',NULL,NULL,NULL,true,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (79,'numero_provvisorio',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.sospesi.sospeso','mif_t_ordinativo_entrata_ricevute','mif_ord_ric_numero',NULL,true,NULL,'2017-01-01',2,'admin',62,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (80,'importo_provvisorio',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.sospesi.sospeso','mif_t_ordinativo_entrata_ricevute','mif_ord_ric_importo',NULL,true,NULL,'2017-01-01',2,'admin',63,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (81,'mandato_associato',NULL,false,'flusso_ordinativi.ordinativi.reversale.informazioni_versante',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (82,'numero_mandato',NULL,false,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.mandato_associato','mif_t_ordinativo_entrata','mif_ord_sost_rev',NULL,true,NULL,'2017-01-01',2,'admin',64,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (83,'progressivo_beneficiario',NULL,false,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.mandato_associato','mif_t_ordinativo_entrata',NULL,'1',true,NULL,'2017-01-01',2,'admin',65,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (84,'informazioni_aggiuntive',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (85,'lingua',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.informazioni_aggiuntive','mif_t_ordinativo_entrata','mif_ord_lingua','ITALIANO',true,NULL,'2017-01-01',2,'admin',66,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (86,'riferimento_documento_esterno',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.informazioni_aggiuntive','mif_t_ordinativo_entrata','mif_ord_rif_doc_esterno','DISPOSIZIONE DOCUMENTO ESTERNO',true,NULL,'2017-01-01',2,'admin',67,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (88,'sostituzione_reversale',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (89,'numero_reversale_da_sostituire',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.sostituzione_reversale','mif_t_ordinativo_entrata','mif_ord_num_ord_colleg',NULL,true,NULL,'2017-01-01',2,'admin',68,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (90,'progressivo_versante_da_sostituire',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.sostituzione_reversale','mif_t_ordinativo_entrata','mif_ord_progr_ord_colleg','1',true,NULL,'2017-01-01',2,'admin',69,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (91,'esercizio_reversale_da_sostituire',NULL,true,'flusso_ordinativi.ordinativi.reversale.informazioni_versante.sostituzione_reversale','mif_t_ordinativo_entrata','mif_ord_anno_ord_colleg',NULL,true,NULL,'2017-01-01',2,'admin',70,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (92,'dati_a_disposizione_ente_versante',NULL,false,'flusso_ordinativi.ordinativi.reversale.informazioni_versante',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,false,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (93,'dati_a_disposizione_ente_reversale',NULL,true,'flusso_ordinativi.ordinativi.reversale',NULL,NULL,NULL,false,NULL,'2017-01-01',2,'admin',0,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (94,'codice_raggruppamento',NULL,true,'flusso_ordinativi.ordinativi.reversale.dati_a_disposizione_ente_reversale','mif_t_ordinativo_entrata','mif_ord_codice_distinta',NULL,true,NULL,'2017-01-01',2,'admin',71,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));

INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (95,'atto_contabile',NULL,true,'flusso_ordinativi.ordinativi.reversale.dati_a_disposizione_ente_reversale','mif_t_ordinativo_entrata','mif_ord_codice_atto_contabile',NULL,true,'ALG','2017-01-01',2,'admin',72,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));
--------------- inserimento mif_d_flusso_elaborato per REVMIF_SPLUS - FINE
