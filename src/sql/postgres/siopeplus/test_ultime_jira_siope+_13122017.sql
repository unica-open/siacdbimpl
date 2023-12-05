/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- REGOLARIZZAZIONE ACCREDITO BANCA d'ITALIA

select *
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.accredito_tipo_desc like 'REG%'

select *
from siac_d_accredito_tipo_oil tipo
where tipo.ente_proprietario_id=2
and   tipo.accredito_tipo_oil_desc like 'REG%'

select *
from siac_r_accredito_tipo_plus tipo
where tipo.ente_proprietario_id=2
and   tipo.accredito_tipo_oil_desc_incasso is not null

 select r.accredito_tipo_oil_desc_incasso, oil.accredito_tipo_oil_desc
     from siac_r_accredito_tipo_plus r ,siac_d_accredito_tipo_oil oil
     where oil.ente_proprietario_id=2
     and   oil.accredito_tipo_oil_desc='ACCREDITO BANCA D''ITALIA'
     and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   oil.data_cancellazione is null
     and   oil.validita_fine is null

select o.accredito_tipo_oil_code,o.accredito_tipo_oil_desc,
       tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
       o.accredito_tipo_oil_area
from siac_d_accredito_tipo_oil  o,siac_d_accredito_tipo tipo, siac_r_accredito_tipo_oil r
where o.ente_proprietario_id=2
and   extract('year' from  o.validita_inizio)='2017'
and   r.accredito_tipo_oil_id=o.accredito_tipo_oil_id
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null
order by 1

select ord.ord_numero::integer,
       stato.ord_stato_code,
       ord.ord_id
from siac_v_bko_anno_bilancio anno , siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_stato r, siac_d_ordinativo_stato  stato,
     siac_r_ordinativo_modpag rm, siac_t_modpag mdp, siac_d_accredito_tipo accre
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   r.ord_id=ord.ord_id
and   stato.ord_stato_id=r.ord_stato_id
and   rm.ord_id=ord.ord_id
and   mdp.modpag_id=rm.modpag_id
and   accre.accredito_tipo_id=mdp.accredito_tipo_id
and   accre.accredito_tipo_code='GFB'
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rm.data_cancellazione is null
and   rm.validita_fine is null

-- ord_numero=13765
-- ord_id=20395

select ord.ord_numero::integer,
       stato.ord_stato_code,
       ord.ord_id,
       ts.ord_ts_data_scadenza
from siac_v_bko_anno_bilancio anno , siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_stato r, siac_d_ordinativo_stato  stato, siac_t_ordinativo_ts ts
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   r.ord_id=ord.ord_id
and   stato.ord_stato_id=r.ord_stato_id
and   ts.ord_id=ord.ord_id
and   ts.ord_ts_data_scadenza is not null
and   r.data_cancellazione is null
and   r.validita_fine is null
order by 1 desc

select ts.*
from siac_t_ordinativo_ts ts
where ts.ord_id=20377

select *
from siac_t_ordinativo_ts ts
where ord_id=20395
select *
from siac_r_ordinativo_prov_cassa r
where r.ord_id=20395

begin;
delete from mif_t_ordinativo_spesa_id

select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   exists
(select 1
from mif_d_flusso_elaborato_tipo tipo
where  mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and     tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS' )
order by mif.flusso_elab_mif_ordine

select c.*
from siac_t_class c,siac_d_class_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.classif_tipo_code='CLASSIFICATORE_28'
and   c.classif_tipo_id=tipo.classif_tipo_id

select ord.ord_id, ord.ord_numero::integer,rc.*
from siac_r_ordinativo_class rc,siac_t_ordinativo ord
where rc.classif_id=75644607
and   ord.ord_id=rc.ord_id
and   rc.data_cancellazione is null
and   rc.validita_fine is null

-- 6325 6344

--- AGGIORNAMENTO DA FARE in PROD
select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='assoggettamento_bollo'
and   exists
(select 1
from mif_d_flusso_elaborato_tipo tipo
where  mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and     tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS' )
order by mif.flusso_elab_mif_ordine

rollback;
begin;
update mif_d_flusso_elaborato mif
set   flusso_elab_mif_param='REGOLARIZZAZIONE|REGOLARIZZAZIONE ACCREDITO BANCA D''ITALIA'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='assoggettamento_bollo'