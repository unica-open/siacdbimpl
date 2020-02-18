/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select *
from siac_t_ente_proprietario ente
-- 10

select *
from siac_t_ente_oil
where ente_proprietario_id=10

select r.*
from siac_r_gestione_ente r, siac_d_gestione_livello d
where d.ente_proprietario_id=10
--and   d.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_UNIIT'
and   d.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_SIOPE_PLUS'
and   r.gestione_livello_id=d.gestione_livello_id
and   r.data_cancellazione is null
and   r.validita_fine is null;

select *
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=10

-- MANDMIF_SPLUS 223
-- REVMIF_SPLUS  224
-- A.R.P.E.A. - Agenzia Regionale

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=10
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where  tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and    mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
)
order by mif.flusso_elab_mif_ordine


select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=10
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where  tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and    mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
)
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
            ||  10||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  223
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=5
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
            ||  10||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  224
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=5
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS';

select -- replace(mif.flusso_elab_mif_param,'IX','IT'),
        mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=10
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where  tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and    mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
)
--and  mif.flusso_elab_mif_param like '%IX%'
and  mif.flusso_elab_mif_code in
    ('tipo_pagamento','abi_beneficiario','cab_beneficiario','numero_conto_corrente_beneficiario','caratteri_controllo',
     'codice_cin','codice_paese','sepa_credit_transfer')
order by mif.flusso_elab_mif_ordine



select *
from siac_d_codicebollo p
where p.ente_proprietario_id=10

select *
from siac_d_codicebollo_plus p
where p.ente_proprietario_id=10

select p.*,
       bollo.*
from siac_d_codicebollo_plus p,siac_r_codicebollo_plus r, siac_d_codicebollo bollo
where p.ente_proprietario_id=10
and   r.codbollo_plus_id=p.codbollo_plus_id
and   bollo.codbollo_id=r.codbollo_id
and   r.data_cancellazione is null
and   r.validita_fine is null

select *
from siac_d_commissione_tipo_plus p
where p.ente_proprietario_id=10

select *
from siac_d_commissione_tipo p
where p.ente_proprietario_id=10


select p.*,
       tipo.*
from siac_d_commissione_tipo_plus p,siac_r_commissione_tipo_plus r, siac_d_commissione_tipo tipo
where p.ente_proprietario_id=10
and   r.comm_tipo_plus_id=p.comm_tipo_plus_id
and   r.comm_tipo_id=tipo.comm_tipo_id


select gruppo.accredito_gruppo_code,
       gruppo.accredito_gruppo_desc,
       tipo.*
from siac_d_accredito_tipo tipo,siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=10
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
order by 1


select  tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
        gruppo.accredito_gruppo_code,
        sog.soggetto_code, sog.soggetto_desc,
        r.ordine,
        mdp.*
from siac_t_modpag mdp, siac_D_accredito_tipo tipo,siac_d_accredito_gruppo gruppo,
     siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_t_soggetto sog, siac_r_modpag_ordine r,siac_r_soggetto_stato rsog, siac_d_soggetto_Stato sogstato
where tipo.ente_proprietario_id=10
and   tipo.accredito_tipo_code='ST'
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
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null
order by 1,sog.soggetto_code,r.ordine
-- 4


select  tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
        gruppo.accredito_gruppo_code,
        sog.soggetto_code, sog.soggetto_desc,
        r.ordine,
        mdp.*
from siac_t_modpag mdp, siac_D_accredito_tipo tipo,siac_d_accredito_gruppo gruppo,
     siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_t_soggetto sog, siac_r_modpag_ordine r,siac_r_soggetto_stato rsog, siac_d_soggetto_Stato sogstato
where tipo.ente_proprietario_id=10
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
and   gruppo.accredito_gruppo_code='CBI'
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null
order by 1,sog.soggetto_code,r.ordine

select tipo.accredito_tipo_code,
       doc.doc_anno,
       dstato.doc_stato_code,
       mdp.*
from siac_t_modpag mdp, siac_D_accredito_tipo tipo,siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_r_subdoc_modpag rsub, siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rstato, siac_d_doc_stato dstato
where tipo.ente_proprietario_id=10
and   tipo.accredito_tipo_code in ('CBI')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and   rsub.modpag_id=mdp.modpag_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   rstato.doc_id=doc.doc_id
and   dstato.doc_Stato_id=rstato.doc_stato_id
and   dstato.doc_Stato_code not in ('EM','ST','AN')
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
and   rstato.data_cancellazione is null
and   rstato.validita_fine is null


select tipo.accredito_tipo_code,
       liq.liq_anno, liq.liq_numero,
       mdp.*
from siac_t_modpag mdp, siac_D_accredito_tipo tipo,siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_v_bko_liquidazione_valida liq
where tipo.ente_proprietario_id=10
and   tipo.accredito_tipo_code in ('CBI')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and   liq.modpag_id=mdp.modpag_id
and   liq.anno_bilancio=2018
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null

with
liquidaz as
(
select tipo.accredito_tipo_code,
       liq.liq_anno, liq.liq_numero,
       liq.liq_id,
       liq.liq_importo--,
      -- mdp.*
from siac_t_modpag mdp, siac_D_accredito_tipo tipo,siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_v_bko_liquidazione_valida liq
where tipo.ente_proprietario_id=10
and   tipo.accredito_tipo_code in ('CBI')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and   liq.modpag_id=mdp.modpag_id
and   liq.anno_bilancio=2018
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
),
pagato as
(
select rliq.liq_id, sum(det.ord_ts_det_importo) pagato
from siac_v_bko_Ordinativo_op_valido op,siac_r_liquidazione_ord rliq,siac_t_ordinativo_ts ts,
     siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipo
where op.ente_proprietario_id=10
and   op.anno_bilancio=2018
and   ts.ord_id=op.ord_id
and   det.ord_ts_id=ts.ord_ts_id
and   tipo.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
and   tipo.ord_ts_det_tipo_code='A'
and   rliq.sord_id=ts.ord_ts_id
and   rliq.data_cancellazione is null
and   rliq.validita_fine is null
group by rliq.liq_id
)
select liquidaz.*,
       pagato.pagato
from liquidaz left join pagato on (liquidaz.liq_id=pagato.liq_id)
where pagato.pagato is  null or liquidaz.liq_importo>coalesce(pagato.pagato,0)
-- NO

-- CO senza dati quietanzante
select  tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
        gruppo.accredito_gruppo_code,
        sog.soggetto_code, sog.soggetto_desc,
        r.ordine,
        mdp.*
from siac_t_modpag mdp, siac_D_accredito_tipo tipo,siac_d_accredito_gruppo gruppo,
     siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_t_soggetto sog, siac_r_modpag_ordine r,siac_r_soggetto_stato rsog, siac_d_soggetto_Stato sogstato
where tipo.ente_proprietario_id=10
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
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null
order by 1,sog.soggetto_code,r.ordine
-- no


-- CSI su quietanza
select accre.accredito_tipo_code, count(*)
from siac_r_soggetto_relaz rel, siac_d_relaz_tipo tipo, siac_r_soggetto_relaz_stato rrelstato, siac_d_relaz_stato relstato,
     siac_r_soggrel_modpag relmdp,
     siac_t_modpag mdp,siac_d_accredito_tipo accre,siac_r_modpag_stato rs, siac_d_modpag_stato stato
where tipo.ente_proprietario_id=10
and   tipo.relaz_tipo_code='CSI'
and   rel.relaz_tipo_id=tipo.relaz_tipo_id
and   rrelstato.soggetto_relaz_id=rel.soggetto_relaz_id
and   relstato.relaz_stato_id=rrelstato.relaz_stato_id
and   relstato.relaz_stato_code not in ('BLOCCATO','ANNULLATO')
and   relmdp.soggetto_relaz_id=rel.soggetto_relaz_id
and   mdp.modpag_id=relmdp.modpag_id
and   mdp.accredito_tipo_id=accre.accredito_tipo_id
and   accre.accredito_tipo_code in ('CT','CON')
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and   rel.data_cancellazione is null
and   rel.validita_fine is null
and   rrelstato.data_cancellazione is null
and   rrelstato.validita_fine is null
and   relmdp.data_cancellazione is null
and   relmdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
group by accre.accredito_tipo_code
-- 0

select relStato.relaz_stato_code, relStato.relaz_stato_desc,relSogStato.*
from siac_r_soggetto_relaz rel, siac_r_soggrel_modpag rmdp,
     siac_t_modpag mdp, siac_d_accredito_tipo tipo,siac_d_accredito_gruppo gruppo,
     --siac_r_modpag_stato rstato
     --, siac_d_modpag_stato stato,
     siac_d_relaz_tipo tiporel,
     siac_r_soggetto_relaz_stato relSogStato,
     siac_d_relaz_stato relStato
where gruppo.ente_proprietario_id=10
and   gruppo.accredito_gruppo_code='CO'
and   tipo.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   mdp.quietanziante is not null
and   mdp.quietanziante_codice_fiscale is not null
and   ( length(mdp.quietanziante_codice_fiscale)!=16 or mdp.quietanziante_codice_fiscale='9999999999999999')
--and   rstato.modpag_id=mdp.modpag_id
--and   stato.modpag_stato_id=rstato.modpag_stato_id
--and   stato.modpag_stato_code not in ('ANNULLATO','BLOCCATO')
and   rmdp.modpag_id=mdp.modpag_id
and   rel.soggetto_relaz_id=rmdp.soggetto_relaz_id
and   tiporel.relaz_tipo_id=rel.relaz_tipo_id
and   tiporel.relaz_tipo_code in ('CSI','FA','PI')
and   rel.data_cancellazione is null
and   rel.validita_fine is null
and   rmdp.data_cancellazione is null
and   rmdp.validita_fine is null
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
--and   rstato.data_cancellazione is null
--and   rstato.validita_fine is null
and   relSogStato.soggetto_relaz_id = rel.soggetto_relaz_id
and   relSogStato.relaz_stato_id = relStato.relaz_stato_id
and   relSogStato.data_cancellazione is null
and   relSogStato.validita_fine is null
and   relStato.relaz_stato_code not in ('ANNULLATO','BLOCCATO');
-- 0

select *
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=10
and   oil.data_cancellazione is null
order by oil.accredito_tipo_oil_code::integer


select *
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=10
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null

select oil.accredito_tipo_oil_code, oil.accredito_tipo_oil_desc,oil.accredito_tipo_oil_area,
       r.login_operazione,
       gruppo.accredito_gruppo_code,
       gruppo.accredito_gruppo_desc,
       tipo.*
from siac_d_accredito_tipo_oil oil,siac_d_accredito_tipo tipo,siac_d_accredito_gruppo gruppo,
     siac_r_accredito_tipo_oil r
where oil.ente_proprietario_id=10
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
and   oil.data_cancellazione is null
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
order by oil.accredito_tipo_oil_code::integer

select  oil.accredito_tipo_oil_code, oil.accredito_tipo_oil_desc,
        r.*
from siac_r_accredito_tipo_plus r, siac_D_accredito_tipo_oil oil
where oil.ente_proprietario_id=10
and   oil.data_cancellazione is null
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
order by oil.accredito_tipo_oil_code::integer

select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=10
and   tipo.classif_tipo_code in ('CLASSIFICATORE_26','CLASSIFICATORE_27','CLASSIFICATORE_28','CLASSIFICATORE_29',
                                 'CLASSIFICATORE_30')


select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=10
and   tipo.classif_tipo_code in ('CLASSIFICATORE_21','CLASSIFICATORE_22','CLASSIFICATORE_23','CLASSIFICATORE_24',
                                 'CLASSIFICATORE_25')



select *
from siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=10


select *
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=10
and   oil.login_operazione='admin-siope+'

select *
from siac_d_oil_qualificatore oil
where oil.ente_proprietario_id=10
and   oil.login_operazione='admin-siope+'

select *
from siac_d_oil_ricevuta_errore oil
where oil.ente_proprietario_id=10
order by oil.oil_ricevuta_errore_id