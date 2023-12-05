/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 22.01.2019 Sofia HD-INC000002978533_p101
-- HD-INC000002978533_p101_ConfAvvioSiope+_verifica_22012019.sql

select *
from siac_t_ente_oil
where ente_proprietario_id=16


select r.*
from siac_r_gestione_ente r, siac_d_gestione_livello d
where d.ente_proprietario_id=16
and   d.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_SIOPE_PLUS'
and   r.gestione_livello_id=d.gestione_livello_id
and   r.data_cancellazione is null
and   r.validita_fine is null;

select *
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=16


-- MANDMIF_SPLUS 223
-- MANDMIF_SPLUS 224

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=16
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
where mif.ente_proprietario_id=16
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where  tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and    mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
)
order by mif.flusso_elab_mif_ordine


select *
from siac_d_codicebollo p
where p.ente_proprietario_id=16

select *
from siac_d_codicebollo_plus p
where p.ente_proprietario_id=16

select p.*,
       bollo.*
from siac_d_codicebollo_plus p,siac_r_codicebollo_plus r, siac_d_codicebollo bollo
where p.ente_proprietario_id=16
and   r.codbollo_plus_id=p.codbollo_plus_id
and   bollo.codbollo_id=r.codbollo_id
and   r.data_cancellazione is null
and   r.validita_fine is null


select *
from siac_d_commissione_tipo_plus p
where p.ente_proprietario_id=16

select *
from siac_d_commissione_tipo p
where p.ente_proprietario_id=16


select p.*,
       tipo.*
from siac_d_commissione_tipo_plus p,siac_r_commissione_tipo_plus r, siac_d_commissione_tipo tipo
where p.ente_proprietario_id=16
and   r.comm_tipo_plus_id=p.comm_tipo_plus_id
and   r.comm_tipo_id=tipo.comm_tipo_id

select gruppo.accredito_gruppo_code,
       gruppo.accredito_gruppo_desc,
       tipo.*
from siac_d_accredito_tipo tipo,siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=16
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
order by 1

select tipo.accredito_tipo_code, mdp.*
from siac_t_modpag mdp, siac_D_accredito_tipo tipo,siac_r_modpag_stato rs, siac_d_modpag_stato stato
where tipo.ente_proprietario_id=16
and   tipo.accredito_tipo_code in ('GF','CBI')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   rs.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=rs.modpag_stato_id
and   stato.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
-- 2


-- CO senza dati quietanzante
select  tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
        gruppo.accredito_gruppo_code,
        sog.soggetto_code, sog.soggetto_desc,
        r.ordine,
        mdp.*
from siac_t_modpag mdp, siac_D_accredito_tipo tipo,siac_d_accredito_gruppo gruppo,
     siac_r_modpag_stato rs, siac_d_modpag_stato stato,
     siac_t_soggetto sog, siac_r_modpag_ordine r,siac_r_soggetto_stato rsog, siac_d_soggetto_Stato sogstato
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
and   mdp.data_cancellazione is null
and   mdp.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null
order by 1,sog.soggetto_code,r.ordine
-- 18

-- CSI su quietanza
select accre.accredito_tipo_code, count(*)
from siac_r_soggetto_relaz rel, siac_d_relaz_tipo tipo, siac_r_soggetto_relaz_stato rrelstato, siac_d_relaz_stato relstato,
     siac_r_soggrel_modpag relmdp,
     siac_t_modpag mdp,siac_d_accredito_tipo accre,siac_r_modpag_stato rs, siac_d_modpag_stato stato
where tipo.ente_proprietario_id=16
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

select *
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=16
and   oil.data_cancellazione is null
order by oil.accredito_tipo_oil_code::integer



select oil.accredito_tipo_oil_code, oil.accredito_tipo_oil_desc,oil.accredito_tipo_oil_area,
       gruppo.accredito_gruppo_code,
       gruppo.accredito_gruppo_desc,
       tipo.*
from siac_d_accredito_tipo_oil oil,siac_d_accredito_tipo tipo,siac_d_accredito_gruppo gruppo,
     siac_r_accredito_tipo_oil r
where oil.ente_proprietario_id=16
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
where oil.ente_proprietario_id=16
and   oil.data_cancellazione is null
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
order by oil.accredito_tipo_oil_code::integer

select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=16
and   tipo.classif_tipo_code in ('CLASSIFICATORE_26','CLASSIFICATORE_27','CLASSIFICATORE_28','CLASSIFICATORE_29',
                                 'CLASSIFICATORE_30')

select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=16
and   tipo.classif_tipo_code in ('CLASSIFICATORE_21','CLASSIFICATORE_22','CLASSIFICATORE_23','CLASSIFICATORE_24',
                                 'CLASSIFICATORE_25')

select *
from siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=16

select *
from siac_d_oil_esito_derivato oil
where oil.ente_proprietario_id=16

select *
from siac_d_oil_qualificatore oil
where oil.ente_proprietario_id=16

select *
from siac_d_oil_ricevuta_errore oil
where oil.ente_proprietario_id=16
order by oil.oil_ricevuta_errore_id
