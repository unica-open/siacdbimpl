/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 16.04.2018 Sofia SIAC-5934
-- fnc_mif_ordinativo_sblocca
-- fnc_mif_ordinativo_get_cursor
-- aggiunta campi

-- 16.04.2018 Sofia SIAC-6067
-- fnc_mif_ordinativo_entrata_splus
-- fnc_mif_ordinativo_spesa_splus
-- aggiunta campo
-- siac_t_ente_oil.ente_oil_invio_escl_annulli=true per regp, cmto e alessandria


-- 19.04.2018 Sofia SIAC-6097
-- aggiornamento creditore_effettivo
-- fnc_mif_ordinativo_spesa_splus


select *
from siac_v_bko_ordinativo_op_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
order by op.ord_numero desc,
         op.statoord_validita_inizio,
         op.statoord_validita_fine


select *
from siac_v_bko_ordinativo_op_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   exists
(
select 1
from siac_r_ordinativo r, siac_d_relaz_tipo tipo
where r.ord_id_da=op.ord_id
and   tipo.relaz_tipo_id=r.relaz_tipo_id
and   tipo.relaz_tipo_code='SOS_ORD'
and   r.data_cancellazione is null
and   r.validita_fine is null
)
order by op.ord_numero desc,
         op.statoord_validita_inizio,
         op.statoord_validita_fine


select *
from siac_v_bko_ordinativo_oi_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
order by op.ord_numero desc,
         op.statoord_validita_inizio,
         op.statoord_validita_fine


select *
from siac_v_bko_ordinativo_op_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_numero=116
/*and   op.ord_numero BETWEEN
8000 and 8300*/
--and   op.ord_numero=8218
--and   op.ord_numero=8218

--and   op.ord_numero=8225
--and   op.ord_numero in ( 8255,8254)
/*and   op.ord_numero in
(
6252,
8210,
8127,
8230,
6289,
3173,
7652)*/
order by op.ord_numero desc,
         op.statoord_validita_inizio,
         op.statoord_validita_fine
begin;
select
fnc_mif_ordinativo_sblocca
(
  2,
  'test',
  'P',
  '71752'::text
)


select *
from siac_v_bko_ordinativo_oi_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_numero BETWEEN
3610 and 3882
--3778 and 3831
--and   op.statoord_validita_fine is null
order by op.ord_numero desc,
         op.statoord_validita_inizio,
         op.statoord_validita_fine

--Reversali: 3865 è stata inserita mai trasmessa e ora annullata - 3875 è stata inserita e annullata nello stesso giorno

select *
from siac_r_ordinativo_stato r
where r.ord_id=83962

select *
from siac_t_ordinativo r
where r.ord_id=84045
-- 8177

with
ordinativo as
(
select *
from siac_v_bko_ordinativo_op_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
),
sosOrd as
(
select  r.ord_id_da, r.ord_id_a
from siac_r_ordinativo r , siac_d_relaz_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.relaz_tipo_code='SOS_ORD'
and   r.relaz_tipo_id=tipo.relaz_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null
)
select *
from ordinativo
where
--ordinativo.ord_numero=44
ordinativo.ord_numero in (8197,44)
and
(exists (select 1 from sosOrd where sosOrd.ord_id_da=ordinativo.ord_id)
or
exists (select 1 from sosOrd where sosOrd.ord_id_a=ordinativo.ord_id)
)
order by ordinativo.ord_numero,
         ordinativo.statoord_validita_inizio,
         ordinativo.statoord_validita_fine


select  * from siac_t_ordinativo ord
where ord.ord_id=84122

select *
from siac_r_ordinativo_stato r
where r.ord_id=83811


insert into siac_r_ordinativo_stato
(
	ord_id,
    ord_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select 83811,
       stato.ord_stato_id,
       now(),
       'test',
       stato.ente_proprietario_id
from siac_d_ordinativo_stato stato
where stato.ente_proprietario_id=2
and   stato.ord_stato_code='A'

select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc




select *
from siac_t_ente_oil oil
where oil.ente_proprietario_id=2



select *
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=2

select oil.accredito_tipo_oil_code,
       oil.accredito_tipo_oil_desc,
       tipo.accredito_tipo_code,
       tipo.accredito_tipo_desc
from siac_r_accredito_tipo_oil r,siac_d_accredito_tipo tipo, siac_d_accredito_tipo_oil oil,
     siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=2
and   r.accredito_tipo_id=tipo.accredito_tipo_id
and   oil.accredito_tipo_oil_id=r.accredito_tipo_oil_id
--and   r.login_operazione='admin-splus'
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
and   gruppo.accredito_gruppo_code='CBI'
--and   gruppo.accredito_gruppo_code='CCP'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null




select *
from siac_v_bko_ordinativo_op_stati op,siac_r_ordinativo_modpag rmdp,
     siac_r_soggrel_modpag
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
order by op.ord_numero desc,
         op.statoord_validita_inizio,
         op.statoord_validita_fine

select
 substr(
  'CSI|CO|6|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP|ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A|ACCREDITO CONTO CORRENTE POSTALE'
  ,
  position (
  split_part ('CSI|CO|6|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP|ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A|ACCREDITO CONTO CORRENTE POSTALE'
   , '|',3)
  IN 'CSI|CO|6|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP|ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A|ACCREDITO CONTO CORRENTE POSTALE'
  )



'CSI|CO|6|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP|ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A|ACCREDITO CONTO CORRENTE POSTALE'

select regexp_replace('Thomas', '.[mN]a.', 'M')

select regexp_replace('CSI||CO|6|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP|ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A|ACCREDITO CONTO CORRENTE POSTALE',
                      'CSI.CO.', '')


select replace('CSI|CO|6|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP|ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A|ACCREDITO CONTO CORRENTE POSTALE',
               split_part ('CSI|CO|6|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP|ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A|ACCREDITO CONTO CORRENTE POSTALE' ,
                            '|',1)||'|'||
               split_part ('CSI|CO|6|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP|ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A|ACCREDITO CONTO CORRENTE POSTALE'             ,
                            '|',2)||'|',  '')



-------------------------------------------------------------------------------------------------

-- qui qui per i casi di test

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
--and   op.ord_numero=1474
--and   op.ord_numero=6252 -- COM ok
--and   op.ord_numero=8210 -- MAV ok
--and   op.ord_numero=8127 -- CCP ok
--and   op.ord_numero=1474 -- F24 ok
--and   op.ord_numero=1151 -- CBI ok
--and   op.ord_numero=3173 -- REG ok
--and   op.ord_numero=7652 -- CB ok
/*and op.ord_numero in
(
6252,
8210,
8127,
8230,
6289,
3173,
7652
)
*/

and   rsog.data_cancellazione is null
and   rsog.validita_fine is null
and   srel.data_cancellazione is null
and   srel.validita_fine is null
and   rmdp.data_cancellazione is null
and   rmdp.validita_fine is null

order by op.ord_numero desc,
         op.statoord_validita_inizio,
         op.statoord_validita_fine

select rmdp.*
from siac_v_bko_ordinativo_op_stati op,siac_r_ordinativo_modpag rmdp
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_numero=1474
and   rmdp.ord_id=op.ord_id
order by op.ord_numero desc,
         op.statoord_validita_inizio,
         op.statoord_validita_fine


select rel.*
from siac_r_soggrel_modpag rel,siac_r_soggetto_relaz r
where r.soggetto_id_a=164950
and   rel.soggetto_relaz_id=r.soggetto_relaz_id
order by soggetto_id_da
-- 2688
-- 1000004331

select rel.*
from siac_r_soggrel_modpag rel,siac_r_soggetto_relaz r
where rel.soggetto_relaz_id=1000004328
and   rel.soggetto_relaz_id=r.soggetto_relaz_id
order by soggetto_id_da

select *
from siac_r_soggetto_relaz r
where r.soggetto_relaz_id=1000003370

select *
from siac_r_soggrel_modpag r
where r.soggetto_relaz_id=1000003370


select  *
from siac_t_soggetto s
where s.soggetto_id=164950
select *
from siac_r_ordinativo_modpag r
--where r.soggetto_relaz_id=1000004326
where r.soggetto_relaz_id=1000003370
-- ord_id=80776
-- soggetto_relaz_id=1000004326
-- 2686

select *
from siac_r_ordinativo_modpag r
where r.ord_id=73945
1000004330

-- 1000004328
insert into siac_r_ordinativo_modpag
(
ord_id,
soggetto_relaz_id,
validita_inizio,
login_operazione,
ente_proprietario_id
)
values
(84126,1000004327,now(),'test-siope',2);

select tipo.accredito_tipo_code,sog.soggetto_code, mdp.*
from siac_t_modpag mdp, siac_d_accredito_tipo tipo,siac_t_soggetto sog
where mdp.soggetto_id=131782
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   sog.soggetto_id=mdp.soggetto_id
-- 6252 COM
-- 8210 MAV - DISPOSIZIONE ..
-- 8127 -- CCP
-- 8230 -- F2  F24
-- 6289 -- CBI

-- 8141 -- REG .. da impostare


insert into siac_t_modpag
(
	soggetto_id,
    accredito_tipo_id,
    validita_inizio,
    login_operazione,
    login_creazione,
    ente_proprietario_id
)
select 131782,
       tipo.accredito_tipo_id,
       now(),
       'test',
       'test',
       tipo.ente_proprietario_id
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.accredito_tipo_code='F2'


insert into siac_r_modpag_stato
(
	modpag_id,
    modpag_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select mdp.modpag_id,
       stato.modpag_stato_id,
       now(),
       'test',
       mdp.ente_proprietario_id
from siac_t_modpag mdp, siac_d_modpag_stato stato
where mdp.soggetto_id=131782
and   mdp.login_operazione='test'
and   stato.ente_proprietario_id=mdp.ente_proprietario_id
and   stato.modpag_stato_code='VALIDO'


insert into siac_r_modpag_ordine
(
	soggetto_id,
    modpag_id,
    ordine,
    validita_inizio,
    login_operazione,
    login_creazione,
    ente_proprietario_id
)
select  mdp.soggetto_id,
		mdp.modpag_id,
        2,
        now(),
        'test',
        'test',
        mdp.ente_proprietario_id
from siac_t_modpag mdp
where mdp.soggetto_id=131782
and   mdp.login_operazione='test'


select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc
-- 3804

select *
from mif_t_ordinativo_sbloccato mif
where mif.ente_proprietario_id=2
and   mif.mif_ord_sblocca_elab_id=3802
order by mif.data_creazione desc



     select rel.*
      from siac_r_ordinativo_modpag s, siac_r_soggrel_modpag rel
      where s.ord_id=80776
      and s.soggetto_relaz_id is not null
      and rel.soggetto_relaz_id=s.soggetto_relaz_id
      and s.data_cancellazione is null
      and s.validita_fine is null
      and rel.data_cancellazione is null
      --  and rel.validita_fine is null
      -- 04.04.2018 Sofia SIAC-6064
      and date_trunc('day',now())<=date_trunc('day',coalesce(rel.validita_fine,now()))
      and exists  (select  1 from siac_r_soggrel_modpag rel1
                   where    rel.soggetto_relaz_id=s.soggetto_relaz_id
		           and      rel1.soggrelmpag_id=rel.soggrelmpag_id
         		   order by rel1.modpag_id
			       limit 1);


select *
from siac_t_modpag m
where m.modpag_id=202691


select mif.*
from  mif_d_flusso_elaborato mif
where mif.flusso_elab_mif_code='creditore_effettivo'
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
);