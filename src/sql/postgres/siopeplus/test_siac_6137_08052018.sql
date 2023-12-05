/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 08.05.2018 siac-6137 --  REGOLARIZZAZIONI

-- fnc_mif_tipo_pagamento_splus


select *
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
--and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'

)
order by mif.flusso_elab_mif_ordine

select tipo.*
	from siac_d_accredito_tipo tipo
	where tipo.ente_proprietario_id=2
    and   tipo.accredito_tipo_desc like 'REG%'
	and   tipo.data_cancellazione is null
	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


select  tipo.accredito_tipo_code,
	    tipo.accredito_tipo_desc,
        op.*
from   siac_v_bko_ordinativo_op_valido op, siac_r_ordinativo_prov_cassa r,
       siac_r_ordinativo_modpag rmdp, siac_t_modpag mdp, siac_d_accredito_tipo tipo
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   r.ord_id=op.ord_id
and   rmdp.ord_id=op.ord_id
and   mdp.modpag_id=rmdp.modpag_id
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
--and   tipo.accredito_tipo_desc like 'REG%'
and   r.data_cancellazione is null
and   r.validita_fine is null
order by op.ord_numero desc

-- ord_numero=7815, 7816, 8202 CB
-- ord_id=83482

select *
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.accredito_tipo_code like 'REG%'

-- 436 REGA
-- 437 REGB
-- 438 REG

select oil.accredito_tipo_oil_code,
       oil.accredito_tipo_oil_desc,
       tipo.*
from siac_d_accredito_tipo tipo , siac_r_accredito_tipo_oil r, siac_d_accredito_tipo_oil oil
where tipo.ente_proprietario_id=2
and   tipo.accredito_tipo_code like 'REG%'
and   r.accredito_tipo_id=tipo.accredito_tipo_id
and   oil.accredito_tipo_oil_id=r.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null

select *
from siac_r_ordinativo_modpag r
where r.ord_id=83482
-- modpag_id=134574
select *
from siac_t_modpag m
where m.modpag_id=134574
-- 424

---

---INCASSI
select
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_desc like 'REG%'

select oil.accredito_tipo_oil_code, oil.accredito_tipo_oil_desc, r.*
     from siac_r_accredito_tipo_plus r ,siac_d_accredito_tipo_oil oil
     where oil.ente_proprietario_id=2
     and   oil.accredito_tipo_oil_desc like 'REG%'
     and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   oil.data_cancellazione is null
     and   oil.validita_fine is null

select c.*
from siac_d_class_tipo tipo, siac_t_class c
where tipo.ente_proprietario_id=2
and   tipo.classif_tipo_code='CLASSIFICATORE_28'
and   c.classif_tipo_id=tipo.classif_tipo_id
