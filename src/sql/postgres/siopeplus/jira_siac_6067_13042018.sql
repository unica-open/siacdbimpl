/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 13.04.2018 Sofia JIRA siac-6097

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
)
order by mif.flusso_elab_mif_ordine


select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='creditore_effettivo'
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
)
order by mif.flusso_elab_mif_ordine

begin;
-- CSI|CO|REGOLARIZZAZIONE|COMPENSAZIONE
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CSI|CO|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='creditore_effettivo'
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
);


rollback;
begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CSI|CO|6|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP|ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A'
where mif.flusso_elab_mif_code='creditore_effettivo'
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
);


select op.ord_numero,
       op.ord_stato_code,
       op.ord_id,
       op.statoord_validita_inizio,
       op.statoord_validita_fine,
       tipo.accredito_tipo_code,
       tipo.accredito_tipo_desc,
       mdp.*

from siac_v_bko_ordinativo_op_stati op,siac_r_ordinativo_modpag rmdp,
     siac_r_soggetto_relaz rsog, siac_r_soggrel_modpag srel, siac_t_modpag mdp,
     siac_d_accredito_tipo tipo,siac_d_relaz_tipo rel
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.statoord_validita_fine is null
and   rmdp.ord_id=op.ord_id
and   rmdp.modpag_id is null
and   rsog.soggetto_relaz_id=rmdp.soggetto_relaz_id
and   srel.soggetto_relaz_id=rsog.soggetto_relaz_id
and   mdp.modpag_id=srel.modpag_id
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   rel.relaz_tipo_id=rsog.relaz_tipo_id
and   rel.relaz_tipo_code='CSI'
--and   op.ord_numero=8231
and   op.ord_numero=8210
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null
and   srel.data_cancellazione is null
and   srel.validita_fine is null
and   rmdp.data_cancellazione is null
and   rmdp.validita_fine is null

order by op.ord_numero desc,
         op.statoord_validita_inizio,
         op.statoord_validita_fine

-- ord_id=84128
-- 2018/8231
-- modpag_id=144909 soggetto_id=131782


select sog.soggetto_code, sog.soggetto_desc
from siac_r_ordinativo_soggetto rsog, siac_t_soggetto sog
where rsog.ord_id=84128
and   sog.soggetto_id=rsog.soggetto_id


select oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc,
       tipo.*
from siac_d_accredito_tipo_oil oil,siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=2
and   oil.login_operazione='admin-siope+'
--and   oil.accredito_tipo_oil_desc='DISPOSIZIONE DOCUMENTO ESTERNO'
--and   oil.accredito_tipo_oil_desc='COMPENSAZIONE'
and   tipo.accredito_tipo_code='MAV'
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null

begin;
update siac_t_modpag mdp
set    accredito_tipo_id=tipo.accredito_tipo_id
from siac_d_accredito_tipo tipo
where mdp.modpag_id=144909
and   tipo.ente_proprietario_id=mdp.ente_proprietario_id
and   tipo.accredito_tipo_code='MAV'


-- 80776
begin;
update siac_r_ordinativo_stato rs
set    data_cancellazione=now(),
       validita_fine=now()
from siac_d_ordinativo_stato stato
where rs.ord_id=80482
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code='T'
and   rs.data_cancellazione is null
and   rs.validita_fine is null

update siac_r_ordinativo_stato rs
set    data_cancellazione=null,
       validita_fine=null
from siac_d_ordinativo_stato stato
where rs.ord_id=80482
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code='I'


update siac_t_ordinativo ord
set    ord_trasm_oil_data=null
where ord.ord_id=80482