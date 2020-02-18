/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 22.01.2019 Sofia HD-INC000002978533_p101
-- HD-INC000002978533_p101_ConfAvvioSiope+_22012019.sql
-- attivazione

update siac_r_gestione_ente r
set    gestione_livello_id=dnew.gestione_livello_id,
       data_modifica=now(),
       login_operazione=r.login_operazione||'-admin-siope+'
from siac_d_gestione_livello d,siac_d_gestione_livello dnew
where d.ente_proprietario_id=16
and   d.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_UNIIT'
and   r.gestione_livello_id=d.gestione_livello_id
and   dnew.ente_proprietario_id=d.ente_proprietario_id
and   dnew.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_SIOPE_PLUS'
and   r.data_cancellazione is null
and   r.validita_fine is null;

update siac_t_ente_oil e
set    ente_oil_siope_plus=true,
       ente_oil_firme_ord=true,
       ente_oil_quiet_ord=true,
       ente_oil_genera_xml=true
where e.ente_proprietario_id=16;

--- configurazione

update siac_t_ente_oil e
set    ente_oil_codice_ipa='UFNWJ9', -- <codice_ente>
       ente_oil_codice_istat='324482', -- <codice_istat_ente>
       ente_oil_codice_tramite='A2A-04255500', -- <codice_tramite_ente>
       ente_oil_codice_tramite_bt='A2A-32854436', -- <codice_tramite_BT>
       ente_oil_codice_pcc_uff='pn_cmbos',
       ente_oil_codice_opi=null,
       ente_oil_invio_escl_annulli=TRUE,
       ente_oil_abi='02008',
       ente_oil_codice='0858100'
where e.ente_proprietario_id=16;

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
select
'MANDMIF_SPLUS',
'Siope+ - Flusso XML Mandati (ordinativi spesa)',
'MANDMIF_SPLUS',
'2019-01-01',
ente.ente_proprietario_id,
'admin-siope+',
true
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and not exists
(
select 1 from mif_d_flusso_elaborato_tipo mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
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
select
'REVMIF_SPLUS',
'Siope+ - Flusso XML Reversali (ordinativi incasso)',
'REVMIF_SPLUS',
'2019-01-01',
ente.ente_proprietario_id,
'admin-siope+',
true
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and not exists
(
select 1 from mif_d_flusso_elaborato_tipo mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
);

insert into mif_d_flusso_elaborato_tipo
(
  flusso_elab_mif_tipo_code,
  flusso_elab_mif_tipo_desc,
  flusso_elab_mif_nome_file,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select
 'GIOCASSA',
 'Siope+ - Giornale di Cassa',
 'GDC',
 '2019-01-01',
 ente.ente_proprietario_id,
 'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and not exists
(
select 1 from mif_d_flusso_elaborato_tipo mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and   mif.flusso_elab_mif_tipo_code='GIOCASSA'
);

insert into mif_d_flusso_elaborato_tipo
(
  flusso_elab_mif_tipo_code,
  flusso_elab_mif_tipo_desc,
  flusso_elab_mif_nome_file,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select
 'RICFIMIF',
 'Flusso acquisizione ricevute firme ordinativi',
 'RicSisC_RS',
 '2019-01-01',
 ente.ente_proprietario_id,
 'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and not exists
(
select 1 from mif_d_flusso_elaborato_tipo mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and   mif.flusso_elab_mif_tipo_code='RICFIMIF'
);


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
            ||  quote_nullable('2019-01-01')||','
            ||  16||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  223
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=16
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS';

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
            ||  quote_nullable('2019-01-01')||','
            ||  16||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  224
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=16
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS';


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
select
 '01',
 'ESENTE BOLLO',
 true,
 '2019-01-01'::timestamp,
 ente.ente_proprietario_id,
 'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and not exists
(
select 1
from siac_d_codicebollo_plus d
where d.ente_proprietario_id=ente.ente_proprietario_id
and   d.codbollo_plus_code='01'
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
select
 '02',
 'ASSOGGETTATO BOLLO A CARICO ENTE',
 false,
 '2019-01-01'::timestamp,
 ente.ente_proprietario_id,
 'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and not exists
(
select 1
from siac_d_codicebollo_plus d
where d.ente_proprietario_id=ente.ente_proprietario_id
and   d.codbollo_plus_code='02'
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
select
 '03',
 'ASSOGGETTATO BOLLO A CARICO BENEFICIARIO',
 false,
 '2017-01-01'::timestamp,
 ente.ente_proprietario_id,
 'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and not exists
(
select 1
from siac_d_codicebollo_plus d
where d.ente_proprietario_id=ente.ente_proprietario_id
and   d.codbollo_plus_code='03'
);

-- siac_d_codicebollo
insert into siac_d_codicebollo
(
  codbollo_code,
  codbollo_desc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select 'SE',
       'SOGGETTO A BOLLO A CARICO ENTE',
	   '2019-01-01'::timestamp,
       'admin-siope+',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and   not exists
(
select 1 from siac_d_codicebollo bollo
where bollo.ente_proprietario_id=ente.ente_proprietario_id
and   bollo.codbollo_code='SE'
and   bollo.data_cancellazione is null
and   bollo.validita_fine is null
);

-- siac_r_codicebollo_plus

-- inserimento siac_r_codicebollo_plus

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
       '2019-01-01'::timestamp,
       bollo.ente_proprietario_id,
       'admin-siope+'
from siac_d_codicebollo_plus plus, siac_d_codicebollo bollo
where plus.ente_proprietario_id=16
and   plus.codbollo_plus_desc='ESENTE BOLLO'
and   plus.codbollo_plus_esente=true
and   bollo.ente_proprietario_id=plus.ente_proprietario_id
and   bollo.codbollo_code in ('99','AI')
and   not exists
(
select 1
from siac_r_codicebollo_plus r
where r.codbollo_id=bollo.codbollo_id
and   r.codbollo_plus_id=plus.codbollo_plus_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);


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
       '2019-01-01'::timestamp,
       bollo.ente_proprietario_id,
       'admin-siope+'
from siac_d_codicebollo_plus plus, siac_d_codicebollo bollo
where plus.ente_proprietario_id=16
and   plus.codbollo_plus_desc='ASSOGGETTATO BOLLO A CARICO BENEFICIARIO'
and   bollo.ente_proprietario_id=plus.ente_proprietario_id
and   bollo.codbollo_code in ('SB')
and   not exists
(
select 1
from siac_r_codicebollo_plus r
where r.codbollo_id=bollo.codbollo_id
and   r.codbollo_plus_id=plus.codbollo_plus_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

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
       '2019-01-01'::timestamp,
       bollo.ente_proprietario_id,
       'admin-siope+'
from siac_d_codicebollo_plus plus, siac_d_codicebollo bollo
where plus.ente_proprietario_id=16
and   plus.codbollo_plus_desc='ASSOGGETTATO BOLLO A CARICO ENTE'
and   bollo.ente_proprietario_id=plus.ente_proprietario_id
and   bollo.codbollo_code in ('DRP','SE')
and   not exists
(
select 1
from siac_r_codicebollo_plus r
where r.codbollo_id=bollo.codbollo_id
and   r.codbollo_plus_id=plus.codbollo_plus_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

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
select
  'CE',
  'A CARICO ENTE',
  false,
  '2019-01-01'::timestamp,
  ente.ente_proprietario_id,
  'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_commissione_tipo_plus d
where d.ente_proprietario_id=ente.ente_proprietario_id
and   d.comm_tipo_plus_code='CE'
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
select
  'BN',
  'A CARICO BENEFICIARIO',
  false,
  '2019-01-01'::timestamp,
  ente.ente_proprietario_id,
  'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_commissione_tipo_plus d
where d.ente_proprietario_id=ente.ente_proprietario_id
and   d.comm_tipo_plus_code='BN'
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
select
  'ES',
  'ESENTE',
  true,
  '2019-01-01'::timestamp,
  ente.ente_proprietario_id,
  'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_commissione_tipo_plus d
where d.ente_proprietario_id=ente.ente_proprietario_id
and   d.comm_tipo_plus_code='ES'
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
       '2019-01-01'::timestamp,
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_commissione_tipo_plus plus, siac_d_commissione_tipo tipo
where plus.ente_proprietario_id=16
and   plus.comm_tipo_plus_desc='ESENTE'
and   plus.comm_tipo_plus_esente=true
and   tipo.ente_proprietario_id=plus.ente_proprietario_id
and   tipo.comm_tipo_code in ('ES')
and   not exists
(
select 1
from siac_r_commissione_tipo_plus r
where r.comm_tipo_id=tipo.comm_tipo_id
and   r.comm_tipo_plus_id=plus.comm_tipo_plus_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

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
       '2019-01-01'::timestamp,
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_commissione_tipo_plus plus, siac_d_commissione_tipo tipo
where plus.ente_proprietario_id=16
and   plus.comm_tipo_plus_desc='A CARICO ENTE'
and   tipo.ente_proprietario_id=plus.ente_proprietario_id
and   tipo.comm_tipo_code in ('CE')
and   not exists
(
select 1
from siac_r_commissione_tipo_plus r
where r.comm_tipo_id=tipo.comm_tipo_id
and   r.comm_tipo_plus_id=plus.comm_tipo_plus_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);


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
       '2019-01-01'::timestamp,
       tipo.ente_proprietario_id,
       'admin-siope+'
from siac_d_commissione_tipo_plus plus, siac_d_commissione_tipo tipo
where plus.ente_proprietario_id=16
and   plus.comm_tipo_plus_desc='A CARICO BENEFICIARIO'
and   tipo.ente_proprietario_id=plus.ente_proprietario_id
and   tipo.comm_tipo_code in ('BN')
and   not exists
(
select 1
from siac_r_commissione_tipo_plus r
where r.comm_tipo_id=tipo.comm_tipo_id
and   r.comm_tipo_plus_id=plus.comm_tipo_plus_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

--- chiusura delle vecchie codifiche e relazioni
update  siac_d_accredito_tipo_oil oil
set     data_cancellazione=now(),
        login_operazione=oil.login_operazione||'-admin-siope+'
where oil.ente_proprietario_id=16
and   oil.login_operazione!='admin-siope+'
and   oil.data_cancellazione is null;

update  siac_r_accredito_tipo_oil r
set     data_cancellazione=now(),
        login_operazione=r.login_operazione||'-admin-siope+'
where r.ente_proprietario_id=16
and   r.login_operazione!='admin-siope+'
and   r.data_cancellazione is null;

update siac_d_accredito_tipo tipo
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=tipo.login_operazione||'-admin-siope+'
where tipo.ente_proprietario_id=16
and   tipo.accredito_tipo_code in ('GF','CBI')
and   tipo.data_cancellazione is null;

-- siac_d_accredito_tipo
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
select  'BEE',
		'BONIFICO ESTERO EURO',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='CB'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='BEE'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


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
select  'ASBP',
		'ASSEGNO BANCARIO E POSTALE',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='ASBP'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


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
select  'ASC',
		'ASSEGNO CIRCOLARE',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='ASC'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

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
select  'F24EP',
		'F24EP',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='F24EP'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


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
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='CBI'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='GFA'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

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
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='GFB'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


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
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='REGA'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

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
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='REGB'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


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
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='REG'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

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
select  'VAP',
		'VAGLIA POSTALE',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='VAP'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


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
select  'VAT',
		'VAGLIA TESORO',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='VAT'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


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
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='ADA'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

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
select  'DEE',
		'DISPOSIZIONE DOCUMENTO ESTERNO',
        0,
        now(),
        gruppo.ente_proprietario_id,
        'admin-siope+',
        gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='DEE'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


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
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='STI'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);



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
where gruppo.ente_proprietario_id=16
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=gruppo.ente_proprietario_id
and   tipo.accredito_tipo_code='COM'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- update  MDP su CBI vecchi--> GFA
update  siac_t_modpag mdp
set     accredito_tipo_id=tiponew.accredito_tipo_id,
        data_modifica=now(),
        login_operazione=mdp.login_operazione||'admin-siope+'
from  siac_D_accredito_tipo tipo,siac_r_modpag_stato rs, siac_d_modpag_stato stato,
      siac_d_accredito_tipo tiponew
where tipo.ente_proprietario_id=16
and   tipo.accredito_tipo_code in ('GF')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and   tiponew.ente_proprietario_id=tipo.ente_proprietario_id
and   tiponew.accredito_tipo_code='GFA'
and   coalesce(mdp.contocorrente,'')!=''
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null;

insert into siac_r_modpag_stato
(
	modpag_id,
    modpag_stato_id,
    login_operazione,
    validita_inizio,
    ente_proprietario_id
)
select  mdp.modpag_id,
        statoBLOC.modpag_stato_id,
        'admin-siope+',
        now(),
        statoBLOC.ente_proprietario_id
from  siac_t_modpag mdp,siac_D_accredito_tipo tipo,siac_r_modpag_stato rs, siac_d_modpag_stato stato,
      siac_d_accredito_tipo tiponew,siac_d_modpag_stato statoBLOC
where tipo.ente_proprietario_id=16
and   tipo.accredito_tipo_code in ('GF')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and   tiponew.ente_proprietario_id=tipo.ente_proprietario_id
and   tiponew.accredito_tipo_code='GFA'
and   coalesce(mdp.contocorrente,'')=''
and   statobloc.ente_proprietario_id=16
and   statobloc.modpag_stato_code='BLOCCATO'
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null;

update siac_t_modpag mdp
set   data_cancellazione=now(),
      validita_fine=now(),
      login_operazione=mdp.login_operazione||'admin-siope+'
from  siac_D_accredito_tipo tipo,siac_r_modpag_stato rs, siac_d_modpag_stato stato,
      siac_d_accredito_tipo tiponew
where tipo.ente_proprietario_id=16
and   tipo.accredito_tipo_code in ('GF')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code!='BLOCCATO'
and   tiponew.ente_proprietario_id=tipo.ente_proprietario_id
and   tiponew.accredito_tipo_code='GFA'
and   coalesce(mdp.contocorrente,'')=''
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null;

insert into siac_r_modpag_stato
(
	modpag_id,
    modpag_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select mdp.modpag_id,
       statoB.modpag_stato_id,
       now(),
       'admon-siope+',
       tipo.ente_proprietario_id
from siac_t_modpag mdp, siac_D_accredito_tipo tipo,siac_d_accredito_gruppo gruppo,
     siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_t_soggetto sog, siac_r_modpag_ordine r,siac_r_soggetto_stato rsog, siac_d_soggetto_Stato sogstato,
     siac_d_modpag_stato statoB
where tipo.ente_proprietario_id=16
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and   sog.soggetto_id=mdp.soggetto_id
and   r.modpag_id=mdp.modpag_id
and   rsog.soggetto_id=sog.soggetto_id
and   sogstato.soggetto_stato_id=rsog.soggetto_stato_id
and   sogstato.soggetto_stato_code not in ('BLOCCATO','ANNULLATO')
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   gruppo.accredito_gruppo_code='CO'
and   coalesce(mdp.quietanziante ,'')!=''
and   COALESCE(mdp.quietanziante_codice_fiscale,'')=''
and   statob.ente_proprietario_id=tipo.ente_proprietario_id
and   statob.modpag_stato_code='BLOCCATO'
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null;

update  siac_r_modpag_stato rs
set     data_cancellazione=now(),
        validita_fine=now(),
        login_operazione=rs.login_operazione||'-admon-siope+'
from siac_t_modpag mdp, siac_D_accredito_tipo tipo,siac_d_accredito_gruppo gruppo,
     siac_d_modpag_stato stato,
     siac_t_soggetto sog, siac_r_modpag_ordine r,siac_r_soggetto_stato rsog, siac_d_soggetto_Stato sogstato,
     siac_d_modpag_stato statoB
where tipo.ente_proprietario_id=16
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and   sog.soggetto_id=mdp.soggetto_id
and   r.modpag_id=mdp.modpag_id
and   rsog.soggetto_id=sog.soggetto_id
and   sogstato.soggetto_stato_id=rsog.soggetto_stato_id
and   sogstato.soggetto_stato_code not in ('BLOCCATO','ANNULLATO')
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   gruppo.accredito_gruppo_code='CO'
and   coalesce(mdp.quietanziante ,'')!=''
and   COALESCE(mdp.quietanziante_codice_fiscale,'')=''
and   statob.ente_proprietario_id=tipo.ente_proprietario_id
and   statob.modpag_stato_code='BLOCCATO'
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null;


-- siac_d_accredito_tipo_oil

-- tipi_pagamento - inizio
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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='01'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='02'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='03'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='04'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='05'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='06'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='07'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='08'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='09'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='10'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='11'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='12'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='13'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='14'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='15'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='16'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='17'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);


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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='18'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);
-- tipi_pagamento - fine

-- tipi_incasso - inizio
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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='19'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='20'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where ente.ente_proprietario_id=16
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='21'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);
-- tipi_incasso - fine

-- inserimento relazioni tipi_pagamento
-- insert into siac_r_accredito_tipo_oil


-- 01 - CASSA

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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='01'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CT','CON')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);


-- 02 - BONIFICO BANCARIO E POSTALE
-- non usato


-- 03 - SEPA CREDIT TRANSFER
-- CB, CD, CCB
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='03'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CB')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

-- 04 - BONIFICO ESTERO EURO
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='04'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CB')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);


-- 05 - ACCREDITO CONTO CORRENTE POSTALE
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='05'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('CP','CCP')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

-- 06 - ASSEGNO BANCARIO E POSTALE

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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='06'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('ASBP')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

-- 07 - ASSEGNO CIRCOLARE
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='07'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('ASC','EA','CI')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);


-- 08 - F24EP

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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='08'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('F24EP','AE')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);


-- 09 - ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='09'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('GFA')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

-- 10 - ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='10'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('GFB')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

-- 11 - REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='11'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('REGA')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

-- 12 - REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='12'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('REGB')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

-- 13 - REGOLARIZZAZIONE
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='13'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('REG')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

-- 14 - VAGLIA POSTALE
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='14'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('VAP')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);


-- 15 - VAGLIA TESORO
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='15'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('VAT')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);


-- 16 - ADDEBITO PREAUTORIZZATO
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='16'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('ADA','RD')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

-- 17 - DISPOSIZIONE DOCUMENTO ESTERNO
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='17'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('STI','DEE','PO','RB','DA','BA','DB')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);


-- 18 - COMPENSAZIONE
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
where oil.ente_proprietario_id=16
and   oil.accredito_tipo_oil_code='18'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('COM')
and   tipo.data_cancellazione is null
and   oil.data_cancellazione is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

--- TIPO INCASSO
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
 where oil.ente_proprietario_id=16
 and   oil.accredito_tipo_oil_desc='ACCREDITO BANCA D''ITALIA'
 and   not exists
 (
 select 1
 from siac_r_accredito_tipo_plus r
 where r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null
 );

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
 where oil.ente_proprietario_id=16
 and   oil.accredito_tipo_oil_desc='REGOLARIZZAZIONE ACCREDITO BANCA D''ITALIA'
 and   not exists
 (
 select 1
 from siac_r_accredito_tipo_plus r
 where r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null
 );

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
 where oil.ente_proprietario_id=16
 and   oil.accredito_tipo_oil_desc='REGOLARIZZAZIONE'
 and   oil.data_cancellazione is null
  and   not exists
 (
 select 1
 from siac_r_accredito_tipo_plus r
 where r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null
 );

 --- CLASSIFICATORI LIBERI
 --- INCASSO
  -- gestione classificatori liberi incasso

  -- CLASSIFICATORE_26 Ordinativo di entrata Infruttifero
  -- CLASSIFICATORE_27 Ordinativo di entrata vincolato a conto
  -- CLASSIFICATORE_28 Modalità incasso Ordinativo di entrata
  -- CLASSIFICATORE_29 Ordinativo di entrata su prelievo da cc postale numero



 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di entrata Infruttifero'
 where tipo.ente_proprietario_id=16
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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_26'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='SI'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );

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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_26'
  and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='NO'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );

update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di entrata vincolato a conto'
 where tipo.ente_proprietario_id=16
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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_27'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='V'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );


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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_27'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='L'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );


--- modalita di incasso
update siac_d_class_tipo tipo
set    classif_tipo_desc='Modalità incasso Ordinativo di entrata'
where tipo.ente_proprietario_id=16
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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_28'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='01'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );


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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_28'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='02'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );


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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_28'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='03'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );


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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_28'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='04'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );


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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_28'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='05'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );







 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di entrata su prelievo da cc postale numero'
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_29';


 --- PAGAMENTO
-- CLASSIFICATORE_21 Ordinativo non frazionabile
-- CLASSIFICATORE_22 Ordinativo di pagamento Infruttifero
-- CLASSIFICATORE_23 Ordinativo di pagamento vincolato a conto
update siac_d_class_tipo tipo
set    classif_tipo_desc='Ordinativo di pagamento Infruttifero'
where tipo.ente_proprietario_id=16
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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_22'
  and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='SI'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );

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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_22'
   and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='NO'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );

 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di pagamento vincolato a conto'
 where tipo.ente_proprietario_id=16
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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_23'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='V'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );

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
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=16
 and   tipo.classif_tipo_code='CLASSIFICATORE_23'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='L'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );

 ------------- ricezioni


-- siac_d_oil_ricevuta_tipo

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
  oil.oil_ricevuta_tipo_code,
  oil.oil_ricevuta_tipo_desc,
  oil.oil_ricevuta_tipo_code_fl,
  now(),
  'admin-siope+',
  ente.ente_proprietario_id
from siac_d_oil_ricevuta_tipo oil,siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and   oil.ente_proprietario_id=29
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   not exists
(
select 1
from siac_d_oil_ricevuta_tipo oil1
where oil1.ente_proprietario_id=ente.ente_proprietario_id
and   oil1.oil_ricevuta_tipo_code=oil.oil_ricevuta_tipo_code
and   oil1.data_cancellazione is null
and   oil1.validita_fine is null
);


-- insert siac_d_oil_esito_derivato
-- Q, S -- quietanza, storno quietanza


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
where tipo.ente_proprietario_id=16
and   tipo.oil_ricevuta_tipo_code='Q'
and   not exists
(
select 1
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=tipo.ente_proprietario_id
and   oil.oil_esito_derivato_code='QUIETANZA'
and   oil.oil_ricevuta_tipo_id=tipo.oil_ricevuta_tipo_id
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where tipo.ente_proprietario_id=16
and   tipo.oil_ricevuta_tipo_code='S'
and   not exists
(
select 1
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=tipo.ente_proprietario_id
and   oil.oil_esito_derivato_code='STORNO QUIETANZA'
and   oil.oil_ricevuta_tipo_id=tipo.oil_ricevuta_tipo_id
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);


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
where tipo.ente_proprietario_id=16
and   tipo.oil_ricevuta_tipo_code='P'
and   not exists
(
select 1
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=tipo.ente_proprietario_id
and   oil.oil_esito_derivato_code='PROVVISORIO'
and   oil.oil_ricevuta_tipo_id=tipo.oil_ricevuta_tipo_id
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where tipo.ente_proprietario_id=16
and   tipo.oil_ricevuta_tipo_code='PS'
and   not exists
(
select 1
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=tipo.ente_proprietario_id
and   oil.oil_esito_derivato_code='STORNO PROVVISORIO'
and   oil.oil_ricevuta_tipo_id=tipo.oil_ricevuta_tipo_id
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);

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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='QUIETANZA'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='MANDATO ESEGUITO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='QUIETANZA'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='MANDATO REGOLARIZZATO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='QUIETANZA'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='REVERSALE ESEGUITO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='QUIETANZA'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='REVERSALE REGOLARIZZATO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);



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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='STORNO QUIETANZA'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='MANDATO STORNATO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='STORNO QUIETANZA'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='MANDATO RIPRISTINATO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='STORNO QUIETANZA'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='REVERSALE STORNATO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='STORNO QUIETANZA'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='REVERSALE RIPRISTINATO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);



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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='PROVVISORIO'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='SOSPESO USCITA ESEGUITO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='STORNO PROVVISORIO'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='SOSPESO USCITA STORNATO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='PROVVISORIO'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='SOSPESO ENTRATA ESEGUITO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

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
where oil.ente_proprietario_id=16
and   oil.oil_esito_derivato_code='STORNO PROVVISORIO'
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.ente_proprietario_id=oil.ente_proprietario_id
and   q.oil_qualificatore_code='SOSPESO ENTRATA STORNATO'
and   q.oil_esito_derivato_id=oil.oil_ricevuta_tipo_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

-- firme
insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,
  oil_ricevuta_tipo_desc,
  oil_ricevuta_tipo_code_fl,
  ente_proprietario_id,
  login_operazione,
  validita_inizio
)
select
  'F',
  'Firma ordinativo',
  'S',
  ente.ente_proprietario_id,
  'admin-siope+',
  now()::timestamp
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=16
and   not exists
(
select 1 from siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.oil_ricevuta_tipo_code='F'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_oil_esito_derivato
(
oil_esito_derivato_code,
oil_esito_derivato_desc,
oil_ricevuta_tipo_id,
validita_inizio,
login_operazione,
ente_proprietario_id
)
select '00',
       'Firma ordinativo',
       tipo.oil_ricevuta_tipo_id,
       now(),
       'admin-siope+',
       tipo.ente_proprietario_id
from siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=16
and   tipo.oil_ricevuta_tipo_code='F'
and   not exists
(
select 1 from siac_d_oil_esito_derivato esito
where esito.ente_proprietario_id=tipo.ente_proprietario_id
and   esito.oil_esito_derivato_code='00'
and   esito.oil_ricevuta_tipo_id=tipo.oil_ricevuta_tipo_id
and   esito.data_cancellazione is null
and   esito.validita_fine is null
);


insert into siac_d_oil_qualificatore
(
oil_qualificatore_code,
oil_qualificatore_desc,
oil_qualificatore_segno,
oil_qualificatore_dr_rec,
oil_esito_derivato_id,
validita_inizio,
login_operazione,
ente_proprietario_id
)
select
'FM',
'Pacchetto di Mandati Firmati',
'U',
false,
oil.oil_esito_derivato_id,
now(),
'admin-siope+',
oil.ente_proprietario_id
from siac_d_oil_esito_derivato oil, siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=16
and   tipo.oil_ricevuta_tipo_code='F'
and   oil.oil_ricevuta_tipo_id=tipo.oil_ricevuta_tipo_id
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.oil_qualificatore_code='FM'
and   q.oil_esito_derivato_id=oil.oil_esito_derivato_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

insert into siac_d_oil_qualificatore
(
oil_qualificatore_code,
oil_qualificatore_desc,
oil_qualificatore_segno,
oil_qualificatore_dr_rec,
oil_esito_derivato_id,
validita_inizio,
login_operazione,
ente_proprietario_id
)
select
'FR',
'Pacchetto di Reversali Firmati',
'E',
false,
oil.oil_esito_derivato_id,
now(),
'admin-siope+',
oil.ente_proprietario_id
from siac_d_oil_esito_derivato oil, siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=16
and   tipo.oil_ricevuta_tipo_code='F'
and   oil.oil_ricevuta_tipo_id=tipo.oil_ricevuta_tipo_id
and   not exists
(
select 1
from siac_d_oil_qualificatore q
where q.oil_qualificatore_code='FR'
and   q.oil_esito_derivato_id=oil.oil_esito_derivato_id
and   q.data_cancellazione is null
and   q.validita_fine is null
);

