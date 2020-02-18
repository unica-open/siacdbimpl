/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Q(1) impostazione MDP
-- modalità di accredito nuove
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

-- 03.04.2018 Sofia
-- fatto con remedy INC000002416807
-- modalità di accredito da bloccare
-- 'DISDE','GEN','LIQUI','PAPRE','TESOR'
-- bloccare tutte le MDP (anche CSI)
-- verificare esistenza documenti e liquidazioni non pagate x estrazioni

select *
from siac_d_modpag_stato stato
where stato.ente_proprietario_id=29

select *
from siac_d_relaz_stato stato
where stato.ente_proprietario_id=29

-- MDP
select mdp.*
from siac_t_modpag mdp, siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_d_accredito_tipo tipo
where mdp.ente_proprietario_id=29
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('ANNULLATO','BLOCCATO')
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('DISDE','GEN','LIQUI','PAPRE','TESOR')
and   rs.data_cancellazione is null
and   rs.validita_fine is null
-- 738 da bloccare

select mdp.*
from siac_r_soggetto_relaz rel, siac_d_relaz_tipo tiporel,
     siac_r_soggetto_relaz_stato rsrel, siac_d_relaz_stato statorel,
     siac_r_soggrel_modpag rmdp,
     siac_t_modpag mdp, siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_d_accredito_tipo tipo
where  rel.ente_proprietario_id=29
and    tiporel.relaz_tipo_id=rel.relaz_tipo_id
and    tiporel.relaz_tipo_code='CSI'
and    rsrel.soggetto_relaz_id=rel.soggetto_relaz_id
and    statorel.relaz_stato_id=rsrel.relaz_stato_id
and    statorel.relaz_stato_code not in ('ANNULLATO','BLOCCATO')
and    rmdp.soggetto_relaz_id=rel.soggetto_relaz_id
and    mdp.modpag_id=rmdp.modpag_id
and    rs.modpag_id=mdp.modpag_id
and    stato.modpag_stato_id=rs.modpag_stato_id
and    stato.modpag_stato_code not in ('ANNULLATO','BLOCCATO')
and    tipo.accredito_tipo_id=mdp.accredito_tipo_id
and    tipo.accredito_tipo_code in ('DISDE','GEN','LIQUI','PAPRE','TESOR')
and    rs.data_cancellazione is null
and    rs.validita_fine is null
and    rel.data_cancellazione is null
and    rel.validita_fine is null
and    rsrel.data_cancellazione is null
and    rsrel.validita_fine is null
and    rmdp.data_cancellazione is null
and    rmdp.validita_fine is null
-- 0

select count(*)
       , docstato.doc_stato_code
from siac_r_subdoc_modpag rsub,siac_t_subdoc sub,siac_t_doc doc, siac_r_doc_stato rdoc, siac_d_doc_stato docstato,
     siac_t_modpag mdp, siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_d_accredito_tipo tipo
where mdp.ente_proprietario_id=29
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('ANNULLATO','BLOCCATO')
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('DISDE','GEN','LIQUI','PAPRE','TESOR')
and   rsub.modpag_id=mdp.modpag_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   rdoc.doc_id=doc.doc_id
and   docstato.doc_stato_id=rdoc.doc_stato_id
and   docstato.doc_stato_code not in ('ST','A','EM')
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
and   rdoc.data_cancellazione is null
and   rdoc.validita_fine is null

group by docstato.doc_stato_code
-- 18

select count(*)
from siac_t_liquidazione liq,siac_r_liquidazione_stato rsliq,siac_d_liquidazione_stato statoliq,
     siac_v_bko_anno_bilancio anno,
	 siac_t_modpag mdp, siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_d_accredito_tipo tipo
where liq.ente_proprietario_id=29
and   rsliq.liq_id=liq.liq_id
and   statoliq.liq_stato_id=rsliq.liq_stato_id
and   statoliq.liq_stato_code!='A'
and   anno.bil_id=liq.bil_id
and   anno.anno_bilancio=2018
and   mdp.modpag_id=liq.modpag_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('ANNULLATO','BLOCCATO')
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('DISDE','GEN','LIQUI','PAPRE','TESOR')
and   not exists
(
select 1
from siac_r_liquidazione_ord sord
where sord.liq_id=liq.liq_id
and   sord.data_cancellazione is null
and   sord.validita_fine is null

)
and   rsliq.data_cancellazione is null
and   rsliq.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
-- 332
-- 12 senza ordinativi
-- 03.04.2018 Sofia
-- fatto con remedy INC000002416807 - fine



-- Q(2) -- relazioni tipo_pagamento
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


--- Q(3) - inserire i cc_postali su CLASSIFICATORE_28

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


-- Q(4) attivazione siope+
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
-- <codice_ente>THQYH6</codice_ente>
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
set    ente_oil_codice_ipa='THQYH6', -- <codice_ente>
       ente_oil_codice_istat='000082420', -- <codice_istat_ente>
       ente_oil_codice_tramite='A2AA-29095250', -- <codice_tramite_ente>
       ente_oil_codice_tramite_bt='A2AA-23515664', -- <codice_tramite_BT>
       ente_oil_codice_pcc_uff='c_a182'
where e.ente_proprietario_id=29;