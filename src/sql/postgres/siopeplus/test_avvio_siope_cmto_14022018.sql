/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select ord.ord_numero::integer,
       ord.ord_id,
	   accre.accredito_tipo_code, accre.accredito_tipo_desc,
       gruppo.accredito_gruppo_code,
       accre.accredito_tipo_id,
       mdp.*
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_modpag rmdp, siac_t_modpag mdp , siac_d_accredito_tipo accre,siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=3
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   ord.ord_numero=60
and   rmdp.ord_id=ord.ord_id
and   mdp.modpag_id=rmdp.modpag_id
and   accre.accredito_tipo_id=mdp.accredito_tipo_id
and   gruppo.accredito_gruppo_id=accre.accredito_gruppo_id



select *
from
fnc_mif_tipo_pagamento_splus( 32889,
												   'ES',
                                                   'IT',
                                                   'SEPA',
                                                   'EXTRASEPA',
                                                   '1',
                                                   'REG',
                                                   'COM',
 												   781,
                                                   'CB',
                                                   5500::numeric,
                                                   false,
                                                   now()::timestamp,
                                                   now()::timestamp,
                                                  3);


select gruppo.accredito_gruppo_code,
       tipo.accredito_tipo_code,
       tipo.accredito_tipo_desc
     from siac_d_accredito_gruppo gruppo, siac_d_accredito_tipo tipo
     where tipo.ente_proprietario_id=3
--     and   tipo.accredito_tipo_code='1'
     and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
     and   gruppo.accredito_gruppo_code='CB'
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


select r.accredito_tipo_oil_rel_id,
       oil.accredito_tipo_oil_code, oil.accredito_tipo_oil_desc,
       oil.accredito_tipo_oil_area,
       gruppo.accredito_gruppo_code,
       tipo.accredito_tipo_code, tipo.accredito_tipo_desc
from siac_d_accredito_tipo_oil oil, siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo,
     siac_d_accredito_gruppo gruppo
where oil.ente_proprietario_id=3
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
and   r.data_cancellazione is  null
--and   oil.accredito_tipo_oil_code in ('02','03','04')
order by oil.accredito_tipo_oil_code::integer

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
where oil.ente_proprietario_id=3
and   oil.accredito_tipo_oil_code='02'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('9')
and   tipo.data_cancellazione is null;

begin;

update  siac_r_accredito_tipo_oil r
set     data_cancellazione=now()
where r.ente_proprietario_id=3
and   r.accredito_tipo_oil_rel_id between  395 and 400;

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
where oil.ente_proprietario_id=3
and   oil.accredito_tipo_oil_code='02'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code='1'
and   tipo.data_cancellazione is null;

-- controllare
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
where oil.ente_proprietario_id=3
and   oil.accredito_tipo_oil_code='03'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code='1'
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
where oil.ente_proprietario_id=3
and   oil.accredito_tipo_oil_code='02'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code in ('9')
and   tipo.data_cancellazione is null;

-- controllare

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
where oil.ente_proprietario_id=3
and   oil.accredito_tipo_oil_code='04'
and   tipo.ente_proprietario_id=oil.ente_proprietario_id
and   tipo.accredito_tipo_code='1'
and   tipo.data_cancellazione is null;

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=3
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)
order by mif.flusso_elab_mif_ordine


select oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc
  from siac_d_accredito_tipo_oil oil, siac_r_accredito_tipo_oil raccre
  where raccre.accredito_tipo_id=775
  and   raccre.data_cancellazione is null
  and   raccre.validita_fine is null
  and   oil.accredito_tipo_oil_id=raccre.accredito_tipo_oil_id
  and   coalesce(oil.accredito_tipo_oil_area,'IT')=coalesce('SEPA','IT')
  and   oil.data_cancellazione is null
  and   date_trunc('day',dataElaborazione)>=date_trunc('day',oil.validita_inizio)
  and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(oil.validita_fine,dataElaborazione));


select c.*
from siac_t_class c, siac_d_class_tipo tipo
where tipo.ente_proprietario_id=3
and   tipo.classif_tipo_code='CLASSIFICATORE_26'
and   c.classif_tipo_id=tipo.classif_tipo_id

select *
from mif_r_conto_tesoreria_fruttifero

alter table mif_r_conto_tesoreria_fruttifero
add fruttifero_oi varchar(20)

update mif_r_conto_tesoreria_fruttifero
set  fruttifero_oi=fruttifero


-- 160 e 161
select ord.ord_numero::integer,
       ord.ord_id,
	   accre.accredito_tipo_code, accre.accredito_tipo_desc,
       gruppo.accredito_gruppo_code,
       accre.accredito_tipo_id,
       mdp.*
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_modpag rmdp, siac_r_soggetto_relaz rel,siac_r_soggrel_modpag relm,
     siac_t_modpag mdp , siac_d_accredito_tipo accre,siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=3
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   ord.ord_numero in (160,161)
and   rmdp.ord_id=ord.ord_id
and   rel.soggetto_relaz_id=rmdp.soggetto_relaz_id
and   relm.soggetto_relaz_id=rel.soggetto_relaz_id
and   mdp.modpag_id=relm.modpag_id
and   accre.accredito_tipo_id=mdp.accredito_tipo_id
and   gruppo.accredito_gruppo_id=accre.accredito_gruppo_id
-- ord_id=33063,33065

select mif.mif_ord_pagam_tipo,
       mif.mif_ord_pagam_code,
       mif.mif_ord_importo,
       mif.*
from mif_t_ordinativo_spesa mif
where mif.mif_ord_ord_id in (33063,33065)

-- accredito_tipo_id=783
-- iban IT81A0306930750100000067174

select *
from
fnc_mif_tipo_pagamento_splus( 33065,
												   'IT',
                                                   'IT',
                                                   'SEPA',
                                                   'EXTRASEPA',
                                                   '1',
                                                   'REG',
                                                   'COM',
 												   783,
                                                   'CB',
                                                   21146.66::numeric,
                                                   false,
                                                   now()::timestamp,
                                                   now()::timestamp,
                                                  3);