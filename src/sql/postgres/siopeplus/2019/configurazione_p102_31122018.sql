/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 31.12.2018 Sofia - p102 - Timo
-- da eseguire in all.sql
begin;
drop index idx_siac_d_accredito_tipo_oil_code;

CREATE UNIQUE INDEX idx_siac_d_accredito_tipo_oil_code ON siac.siac_d_accredito_tipo_oil
  USING btree (accredito_tipo_oil_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


/** inviare mail con estrazione dati
F2	PAGAMENTO A MEZZO F24 EP
GF	GIROFONDI BANCA D'ITALIA TAB A
GFB	GIROFONDI BANCA D'ITALIA TAB B **/


-- attivazione

update siac_r_gestione_ente r
set    gestione_livello_id=dnew.gestione_livello_id,
       data_modifica=now(),
       login_operazione=r.login_operazione||'-admin-siope+'
from siac_d_gestione_livello d,siac_d_gestione_livello dnew
where d.ente_proprietario_id=14
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
where e.ente_proprietario_id=14;



--- configurazione
-- richiedere i valori seguenti
update siac_t_ente_oil e
set    ente_oil_codice_ipa='UFKPX0', -- <codice_ente>
       ente_oil_codice_istat='910400', -- <codice_istat_ente>
       ente_oil_codice_tramite='A2A-04255500', -- <codice_tramite_ente>
       ente_oil_codice_tramite_bt='A2A-07899291', -- <codice_tramite_BT>
       ente_oil_codice_pcc_uff='pfpo_al',
       ente_oil_codice_opi=null,
       ente_oil_invio_escl_annulli=TRUE
where e.ente_proprietario_id=14;


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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
 'Gdc',
 '2019-01-01',
 ente.ente_proprietario_id,
 'admin-siope+'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
and not exists
(
select 1 from mif_d_flusso_elaborato_tipo mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and   mif.flusso_elab_mif_tipo_code='RICFIMIF'
);

select mif.*
from mif_d_flusso_elaborato mif, mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=14
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
order by mif.flusso_elab_mif_ordine

select mif.*
from mif_d_flusso_elaborato mif, mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=14
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
order by mif.flusso_elab_mif_ordine

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
            ||  14||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  207
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=14
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
            ||  14||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  208
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
and not exists
(
select 1
from siac_d_codicebollo_plus d
where d.ente_proprietario_id=ente.ente_proprietario_id
and   d.codbollo_plus_code='03'
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
where plus.ente_proprietario_id=14
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
where plus.ente_proprietario_id=14
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
where plus.ente_proprietario_id=14
and   plus.codbollo_plus_desc='ASSOGGETTATO BOLLO A CARICO ENTE'
and   bollo.ente_proprietario_id=plus.ente_proprietario_id
and   bollo.codbollo_code in ('DRP')
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where plus.ente_proprietario_id=14
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
where plus.ente_proprietario_id=14
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
where plus.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
and   oil.login_operazione!='admin-siope+'
and   oil.data_cancellazione is null;

update  siac_r_accredito_tipo_oil r
set     data_cancellazione=now(),
        login_operazione=r.login_operazione||'-admin-siope+'
where r.ente_proprietario_id=14
and   r.login_operazione!='admin-siope+'
and   r.data_cancellazione is null;


update siac_d_accredito_tipo tipo
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=tipo.login_operazione||'-admin-siope+'
where tipo.ente_proprietario_id=14
and   tipo.accredito_tipo_code in ('GF','GFB','F2')
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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


/*
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
);*/

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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
where gruppo.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where ente.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
-- CB, CD, CCB, AC
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
and   oil.accredito_tipo_oil_code='07'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('ASC')
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
where oil.ente_proprietario_id=14
and   oil.accredito_tipo_oil_code='08'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('F24EP')
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
and   oil.accredito_tipo_oil_code='16'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('ADA')
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
where oil.ente_proprietario_id=14
and   oil.accredito_tipo_oil_code='17'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('STI','DEE','DA','DB','F3','F4')
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
where oil.ente_proprietario_id=14
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

-- update  MDP su CBI vecchi--> GFA
update  siac_t_modpag mdp
set     accredito_tipo_id=tiponew.accredito_tipo_id,
        data_modifica=now(),
        login_operazione=mdp.login_operazione||'admin-siope+'
from  siac_D_accredito_tipo tipo,siac_r_modpag_stato rs, siac_d_modpag_stato stato,
      siac_d_accredito_tipo tiponew
where tipo.ente_proprietario_id=14
and   tipo.accredito_tipo_code in ('GF','GFB','F2')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and   tiponew.ente_proprietario_id=tipo.ente_proprietario_id
and   tiponew.accredito_tipo_code='GFA'
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null



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
 where oil.ente_proprietario_id=14
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
 where oil.ente_proprietario_id=14
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
 where oil.ente_proprietario_id=14
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
  -- CLASSIFICATORE_27 Modalità incasso Ordinativo di entrata
  -- CLASSIFICATORE_28 Ordinativo di entrata vincolato a conto
  -- CLASSIFICATORE_29 Ordinativo di entrata su prelievo da cc postale numero

 /*begin;
 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di entrata Infruttifero'
 where tipo.ente_proprietario_id=14
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
 where tipo.ente_proprietario_id=14
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
 where tipo.ente_proprietario_id=14
 and   tipo.classif_tipo_code='CLASSIFICATORE_26'
  and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='NO'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );*/


--- modalita di incasso
-- update siac_d_class_tipo tipo
-- set    classif_tipo_desc='Modalità incasso Ordinativo di entrata'
-- where tipo.ente_proprietario_id=14
-- and   tipo.classif_tipo_code='CLASSIFICATORE_27';

update siac_t_class c
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=c.login_operazione||'-admin-siope+'
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=14
and   tipo.classif_tipo_code='CLASSIFICATORE_27'
and   c.classif_tipo_id=tipo.classif_tipo_id
and   c.data_cancellazione is null
and   c.validita_fine is null;

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
 where tipo.ente_proprietario_id=14
 and   tipo.classif_tipo_code='CLASSIFICATORE_27'
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
 where tipo.ente_proprietario_id=14
 and   tipo.classif_tipo_code='CLASSIFICATORE_27'
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
 where tipo.ente_proprietario_id=14
 and   tipo.classif_tipo_code='CLASSIFICATORE_27'
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
 where tipo.ente_proprietario_id=14
 and   tipo.classif_tipo_code='CLASSIFICATORE_27'
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
 where tipo.ente_proprietario_id=14
 and   tipo.classif_tipo_code='CLASSIFICATORE_27'
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
 set    classif_tipo_desc='Ordinativo di entrata vincolato a conto'
 where tipo.ente_proprietario_id=14
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
 select 'V',
        'VINCOLATA',
        tipo.classif_tipo_id,
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=14
 and   tipo.classif_tipo_code='CLASSIFICATORE_28'
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
 where tipo.ente_proprietario_id=14
 and   tipo.classif_tipo_code='CLASSIFICATORE_28'
 and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='L'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );





 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di entrata su prelievo da cc postale numero'
 where tipo.ente_proprietario_id=14
 and   tipo.classif_tipo_code='CLASSIFICATORE_29';


--- PAGAMENTO
-- CLASSIFICATORE_21 Ordinativo non frazionabile
-- CLASSIFICATORE_22 Ordinativo di pagamento Infruttifero
-- CLASSIFICATORE_23 Ordinativo di pagamento vincolato a conto

update siac_d_class_tipo tipo
set    classif_tipo_desc='Ordinativo di pagamento Infruttifero'
where tipo.ente_proprietario_id=14
and   tipo.classif_tipo_code='CLASSIFICATORE_22';



/* insert into siac_t_class
 (
 	 classif_code,
     classif_desc,
     classif_tipo_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
 )
 select 'NO',
        'INFRUTTIFERA',
        tipo.classif_tipo_id,
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=14
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
        'FRUTTIFERA',
        tipo.classif_tipo_id,
        '2019-01-01'::timestamp,
        'admin-siope+',
        tipo.ente_proprietario_id
 from siac_D_class_tipo tipo
 where tipo.ente_proprietario_id=14
 and   tipo.classif_tipo_code='CLASSIFICATORE_22'
   and   not exists
 (
 select 1
 from siac_t_class c
 where c.classif_code='SI'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   c.data_cancellazione is null
 and   c.validita_fine is null
 );*/

 update siac_d_class_tipo tipo
 set    classif_tipo_desc='Ordinativo di pagamento vincolato a conto'
 where tipo.ente_proprietario_id=14
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
 where tipo.ente_proprietario_id=14
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
 where tipo.ente_proprietario_id=14
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
--- siac_d_oil_ricevuta_errore

insert into siac_d_oil_ricevuta_errore
(
  oil_ricevuta_errore_code,
  oil_ricevuta_errore_desc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select
  oil.oil_ricevuta_errore_code,
  oil.oil_ricevuta_errore_desc,
  now(),
  'admin-siope+',
  ente.ente_proprietario_id
from siac_d_oil_ricevuta_errore oil,siac_t_ente_proprietario ente
where ente.ente_proprietario_id=14
and   oil.ente_proprietario_id=29
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   not exists
(
select 1
from siac_d_oil_ricevuta_errore oil1
where oil1.ente_proprietario_id=ente.ente_proprietario_id
and   oil1.oil_ricevuta_errore_code=oil.oil_ricevuta_errore_code
and   oil1.data_cancellazione is null
and   oil1.validita_fine is null
);

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
where ente.ente_proprietario_id=14
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
where tipo.ente_proprietario_id=14
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
where tipo.ente_proprietario_id=14
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
where tipo.ente_proprietario_id=14
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
where tipo.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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
where oil.ente_proprietario_id=14
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



insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '48','ORDINATIVO NON FIRMATO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='48');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '49','ORDINATIVO QUIETANZATO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='49');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '58','PROVVISORIO DI CASSA ESISTENTE PER RICEVUTA DI STORNO DATA ANNULLAMENTO VALORIZZATA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='58');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '59','PROVVISORIO DI CASSA ESISTENTE PER RICEVUTA DI INSERIMENTO NUOVO PROVVISORIO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='59');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '0','ELABORAZIONE VALIDA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='0');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '1','RECORD TESTATA NON PRESENTE', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='1');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '2','RECORD CODA NON PRESENTE', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='2');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '3','RECORD RICEVUTA NON PRESENTE', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='3');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '4','RECORD DETTAGLIO RICEVUTA NON PRESENTE', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='4');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '5','TIPO FLUSSO  NON INDICATO SU RECORD TESTATA ( QUIETANZE )', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='5');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '6','TIPO FLUSSO  NON INDICATO SU RECORD TESTATA ( FIRME )', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='6');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '7','TIPO FLUSSO  NON INDICATO SU RECORD TESTATA ( PROVVISORI CASSA )', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='7');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '8','TIPO FLUSSO  NON INDICATO SU RECORD CODA ( QUIETANZE )', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='8');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '9','TIPO FLUSSO  NON INDICATO SU RECORD CODA ( FIRME )', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='9');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '10','TIPO FLUSSO  NON INDICATO SU RECORD CODA ( PROVVISORI CASSA )', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='10');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '11','DATA ORA FLUSSO NON PRESENTE SU RECORD DI TESTATA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='11');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '12','NUMERO RICEVUTE NON PRESENTE SU RECORD DI TESTATA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='12');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '13','DATI ENTE NON PRESENTI O NON VALIDI SU RECORD DI TESTATA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='13');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '14','DATA ORA FLUSSO NON PRESENTE SU RECORD DI TESTATA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='14');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '15','NUMERO RICEVUTE NON PRESENTE SU RECORD DI TESTATA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='15');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '16','DATI ENTE NON PRESENTI O NON VALIDI SU RECORD DI TESTATA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='16');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '17','RECORD RICEVUTA SENZA RECORD DI DETTAGLIO ', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='17');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '18','RECORD DETTAGLIO RICEVUTA SENZA RECORD DI RIFERIMENTO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='18');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '19','TIPO RECORD NON INDICATO O ERRATO SU RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='19');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '20','TIPO RECORD NON INDICATO O ERRATO SU DETTAGLIO RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='20');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '21','PROGRESSIVO NON VALORIZZATO PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='21');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '22','DATA O ORA MESSAGGIO NON INDICATO RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='22');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '23','ESITO DERIVATO NON INDICATO O NON AMMESSO PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='23');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '24','DATI ENTE NON PRESENTI O NON VALIDI SU RECORD RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='24');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '25','CODICE ESISTO NON POSITIVO PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='25');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '26','CODICE FUNZIONE NON VALORIZZATO O NON AMMESSO PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='26');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '27','CODICE QUALIFICATORE NON VALORIZZATO O NON AMMESSO PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='27');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '28','DATI ORDINATIVO NON INDICATI ( ANNO, NUMERO, DATA PAGAMENTO ) PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='28');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '29','ANNO ORDINATIVO NON CORRETTO RISPETTO ANNO BILANCIO CORRENTE PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='29');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '30','ORDINATIVO NON ESISTENTE PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='30');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '31','ORDINATIVO ANNULLATO PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='31');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '32','ORDINATIVO EMESSO IN DATA SUCCESSIVA ALLA DATA DI  RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='32');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '57','PROVVISORIO DI CASSA ESISTENTE PER RICEVUTA DI STORNO PROVVISORIO SOGGETTO INCONGRUENTE', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='57');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '33','ORDINATIVO NON TRASMESSO O TRASMESSO IN DATA SUCCESSIVA ALLA DATA DI  RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='33');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '34','ORDINATIVO FIRMATO IN DATA SUCCESSIVA ALLA DATA DI  RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='34');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '35','RECORD DETTAGLIO RICEVUTA CON PROGRESSIVO_RICEVUTA NON VALORIZZATO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='35');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '36','RECORD DETTAGLIO RICEVUTA CON NUMERO_RICEVUTA NON VALORIZZATO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='36');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '37','RECORD DETTAGLIO RICEVUTA CON IMPORTO_RICEVUTA NON VALORIZZATO O NON VALIDO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='37');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '38','TOTALE RICEVUTA SU RECORD DETTAGLIO NEGATIVO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='38');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '39','ERRORE IN LETTURA NUMERO RICEVUTA SU RECORD DI DETTAGLIO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='39');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '40','ERRORE IN LETTURA IMPORTO ORDINATIVO PER CONFRONTO CON IMPORTO RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='40');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '41','ERRORE IN LETTURA QUIETANZA ORDINATIVO IN FASE DI STORNO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='41');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '42','TOTALE QUIETANZATO SUPERIORE ALL''IMPORTO DELL''ORDINATIVO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='42');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '43','TOTALE QUIETANZATO NEGATIVO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='43');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '44','STATO ATTUALE ORDINATIVO NON CONGRUENTE CON L''OPERAZIONE DI AGGIORNAMENTO RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='44');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '45','DATI FIRMA NON INDICATI PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='45');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '46','ORDINATIVO FIRMATO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='46');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '47','ORDINATIVO QUIETANZATO IN DATA ANTECENDENTE ALLA DATA DI RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='47');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '50','DATI PROVVISSORIO DI CASSA NON INDICATI ( ANNO NUMERO DATA IMPORTO )', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='50');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '51','ANNO PROVVISORIO DI CASSA NON CORRETTO  RISPETTO ANNO BILANCIO CORRENTE PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='51');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '52','DATA EMISSIONE PROVVISORIO DI CASSA NON CORRETTA  RISPETTO ALLA DATA DI ELABORAZIONE PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='52');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '53','IMPORTO PROVVISORIO DI CASSA NON CORRETTO   PER RICEVUTA', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='53');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '54','PROVVISORIO DI CASSA INESISTENTE PER RICEVUTA DI STORNO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='54');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '55','PROVVISORIO DI CASSA ESISTENTE PER RICEVUTA DI STORNO COLLEGATO A ORDINATIVO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='55');
insert into siac_d_oil_ricevuta_errore ( oil_ricevuta_errore_code, oil_ricevuta_errore_desc, validita_inizio, login_operazione, ente_proprietario_id ) select '56','PROVVISORIO DI CASSA ESISTENTE PER RICEVUTA DI STORNO IMPORTO DI STORNO SUPERIORE IMPORTO PROVVISORIO', now(),'admin-siope+', ente.ente_proprietario_id from siac_t_ente_proprietario ente where not exists (select 1 from siac_d_oil_ricevuta_errore errore where errore.ente_proprietario_id=ente.ente_proprietario_id and errore.oil_ricevuta_errore_code='56');