/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- Dalla Q2 in poi query per verifiche mandati, liquidazioni e documenti collegati a MDP da bloccare per chiusura dei codici accredito
-- Q1-MODALITA DI PAGAMENTO
-- query di verifica delle MDP 
-- tutte quelle che saranno esistenti dovranno essere chiuse o bloccate o annullate
-- non dovranno essercene in modifica e tutte le altre saranno bloccate - fornire estrazioni 
select  sog.ente_proprietario_id , sog.soggetto_code, sog.soggetto_desc, stato.soggetto_stato_code ,stato_mdp.modpag_stato_code ,
             oil.accredito_tipo_oil_desc , tipo.accredito_tipo_code , tipo.accredito_tipo_desc ,gruppo.accredito_gruppo_desc 
from siac_t_soggetto sog,siac_t_modpag mdp ,siac_d_accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil oil,
           siac_r_soggetto_stato rs,siac_d_soggetto_stato stato, siac_r_modpag_stato  rs_mdp,siac_d_modpag_stato stato_mdp,siac_d_accredito_gruppo gruppo
where sog.ente_proprietario_id in (2,3,4,5,10,16)
and     mdp.soggetto_id=sog.soggetto_id
and     tipo.accredito_tipo_id =mdp.accredito_tipo_id 
and     r.accredito_tipo_id =tipo.accredito_tipo_id 
and     oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and    gruppo.accredito_gruppo_id =tipo.accredito_gruppo_id               
and     rs.soggetto_id=sog.soggetto_id 
and     stato.soggetto_stato_id =rs.soggetto_stato_id 
and     stato.soggetto_stato_code not in ('BLOCCATO','ANNULLATO')
and     rs_mdp.modpag_id =mdp.modpag_id 
and     stato_mdp.modpag_stato_id=rs_mdp.modpag_stato_id 
and     stato_mdp.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and     tipo.data_cancellazione  is null 
and     tipo.validita_fine  is null 
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
and     sog.data_cancellazione  is null 
and     sog.validita_fine  is null 
and     mdp.data_cancellazione  is null 
and     mdp.validita_fine  is null 
and     rs_mdp.data_cancellazione  is null 
and     rs_mdp.validita_fine  is null 
and     rs.data_cancellazione  is null 
and     rs.validita_fine  is null 
order by 1,3

select  sog_da.ente_proprietario_id , sog_da.soggetto_code , sog_da.soggetto_desc , stato_da.soggetto_stato_code ,
            sog.soggetto_code, sog.soggetto_desc, stato.soggetto_stato_code ,stato_mdp.modpag_stato_code ,stato_rel.relaz_stato_code ,
             oil.accredito_tipo_oil_desc , tipo.accredito_tipo_code , tipo.accredito_tipo_desc ,gruppo.accredito_gruppo_desc 
from siac_t_soggetto sog,siac_t_modpag mdp ,siac_d_accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil oil,
           siac_r_soggetto_stato rs,siac_d_soggetto_stato stato, siac_r_modpag_stato  rs_mdp,siac_d_modpag_stato stato_mdp,siac_d_accredito_gruppo gruppo,
           siac_r_soggetto_relaz  rel , siac_r_soggetto_relaz_stato  rs_rel,siac_d_relaz_stato  stato_rel,
           siac_t_soggetto sog_da , siac_r_soggetto_stato rs_da ,siac_d_soggetto_stato stato_da 
where sog.ente_proprietario_id in (2,3,4,5,10,16)
and     mdp.soggetto_id=sog.soggetto_id
and     tipo.accredito_tipo_id =mdp.accredito_tipo_id 
and     r.accredito_tipo_id =tipo.accredito_tipo_id 
and     oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and    gruppo.accredito_gruppo_id =tipo.accredito_gruppo_id               
and     rs.soggetto_id=sog.soggetto_id 
and     stato.soggetto_stato_id =rs.soggetto_stato_id 
and     stato.soggetto_stato_code not in ('BLOCCATO','ANNULLATO')
and     rs_mdp.modpag_id =mdp.modpag_id 
and     stato_mdp.modpag_stato_id=rs_mdp.modpag_stato_id 
and     stato_mdp.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and     rel.soggetto_id_a =sog.soggetto_id 
and     rs_rel.soggetto_relaz_id =rel.soggetto_relaz_id 
and     stato_rel.relaz_stato_id =rs_rel.relaz_stato_id 
and     stato_rel.relaz_stato_code  not in ('BLOCCATO','ANNULLATO')
and     sog_da.soggetto_id=rel.soggetto_id_da 
and     rs_da.soggetto_id=sog_da.soggetto_id 
and     stato_da.soggetto_stato_id =rs_da.soggetto_stato_id 
and     tipo.data_cancellazione  is null 
and     tipo.validita_fine  is null 
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
and     sog.data_cancellazione  is null 
and     sog.validita_fine  is null 
and     mdp.data_cancellazione  is null 
and     mdp.validita_fine  is null 
and     rs_mdp.data_cancellazione  is null 
and     rs_mdp.validita_fine  is null 
and     rs.data_cancellazione  is null 
and     rs.validita_fine  is null 
and     rel.data_cancellazione  is null 
and     rel.validita_fine  is null 
and     rs_rel.data_cancellazione  is null 
and     rs_rel.validita_fine  is null 
and     rs_da.data_cancellazione  is null 
and     rs_da.validita_fine  is null 
and     sog_da.data_cancellazione  is null 
and     sog_da.validita_fine  is null 
order by 1,3

--- UPD1 - BLOCCO SOGGETTO REL MDP 
insert into siac_r_soggetto_relaz_stato 
(
soggetto_relaz_id,
relaz_stato_id,
validita_inizio ,
login_operazione ,
ente_proprietario_id 
)
select distinct 
           rel.soggetto_relaz_id ,
           statoB.relaz_stato_id ,
           now(),
           'SIAC-TASK-56',
           stato.ente_proprietario_id 
from siac_t_soggetto sog,siac_t_modpag mdp ,siac_d_accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil oil,
           siac_r_soggetto_stato rs,siac_d_soggetto_stato stato, siac_r_modpag_stato  rs_mdp,siac_d_modpag_stato stato_mdp,siac_d_accredito_gruppo gruppo,
           siac_r_soggetto_relaz  rel , siac_r_soggetto_relaz_stato  rs_rel,siac_d_relaz_stato  stato_rel,
           siac_t_soggetto sog_da , siac_r_soggetto_stato rs_da ,siac_d_soggetto_stato stato_da ,
           siac_d_relaz_stato  statoB
where sog.ente_proprietario_id in (2,3,4,5,10,16)
and     mdp.soggetto_id=sog.soggetto_id
and     tipo.accredito_tipo_id =mdp.accredito_tipo_id 
and     r.accredito_tipo_id =tipo.accredito_tipo_id 
and     oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and    gruppo.accredito_gruppo_id =tipo.accredito_gruppo_id               
and     rs.soggetto_id=sog.soggetto_id 
and     stato.soggetto_stato_id =rs.soggetto_stato_id 
and     stato.soggetto_stato_code not in ('BLOCCATO','ANNULLATO')
and     rs_mdp.modpag_id =mdp.modpag_id 
and     stato_mdp.modpag_stato_id=rs_mdp.modpag_stato_id 
and     stato_mdp.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and     rel.soggetto_id_a =sog.soggetto_id 
and     rs_rel.soggetto_relaz_id =rel.soggetto_relaz_id 
and     stato_rel.relaz_stato_id =rs_rel.relaz_stato_id 
and     stato_rel.relaz_stato_code  not in ('BLOCCATO','ANNULLATO')
and     sog_da.soggetto_id=rel.soggetto_id_da 
and     rs_da.soggetto_id=sog_da.soggetto_id 
and     stato_da.soggetto_stato_id =rs_da.soggetto_stato_id 
and     statoB.ente_proprietario_id =stato_rel.ente_proprietario_id 
and     statoB.relaz_stato_code='BLOCCATO'
and     tipo.data_cancellazione  is null 
and     tipo.validita_fine  is null 
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
and     sog.data_cancellazione  is null 
and     sog.validita_fine  is null 
and     mdp.data_cancellazione  is null 
and     mdp.validita_fine  is null 
and     rs_mdp.data_cancellazione  is null 
and     rs_mdp.validita_fine  is null 
and     rs.data_cancellazione  is null 
and     rs.validita_fine  is null 
and     rel.data_cancellazione  is null 
and     rel.validita_fine  is null 
and     rs_rel.data_cancellazione  is null 
and     rs_rel.validita_fine  is null 
and     rs_da.data_cancellazione  is null 
and     rs_da.validita_fine  is null 
and     sog_da.data_cancellazione  is null 
and     sog_da.validita_fine  is null;

update siac_r_soggetto_relaz_stato  rs_rel
set      data_cancellazione=now(),
           validita_fine=now(),
           login_operazione =rs_rel.login_operazione ||'-SIAC-TASK-56'
from siac_t_soggetto sog,siac_t_modpag mdp ,siac_d_accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil oil,
           siac_r_soggetto_stato rs,siac_d_soggetto_stato stato, siac_r_modpag_stato  rs_mdp,siac_d_modpag_stato stato_mdp,siac_d_accredito_gruppo gruppo,
           siac_r_soggetto_relaz  rel , siac_d_relaz_stato  stato_rel,
           siac_t_soggetto sog_da , siac_r_soggetto_stato rs_da ,siac_d_soggetto_stato stato_da 
where sog.ente_proprietario_id in (2,3,4,5,10,16)
and     mdp.soggetto_id=sog.soggetto_id
and     tipo.accredito_tipo_id =mdp.accredito_tipo_id 
and     r.accredito_tipo_id =tipo.accredito_tipo_id 
and     oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and    gruppo.accredito_gruppo_id =tipo.accredito_gruppo_id               
and     rs.soggetto_id=sog.soggetto_id 
and     stato.soggetto_stato_id =rs.soggetto_stato_id 
and     stato.soggetto_stato_code not in ('BLOCCATO','ANNULLATO')
and     rs_mdp.modpag_id =mdp.modpag_id 
and     stato_mdp.modpag_stato_id=rs_mdp.modpag_stato_id 
and     stato_mdp.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and     rel.soggetto_id_a =sog.soggetto_id 
and     rs_rel.soggetto_relaz_id =rel.soggetto_relaz_id 
and     stato_rel.relaz_stato_id =rs_rel.relaz_stato_id 
and     stato_rel.relaz_stato_code !='BLOCCATO'
and     sog_da.soggetto_id=rel.soggetto_id_da 
and     rs_da.soggetto_id=sog_da.soggetto_id 
and     stato_da.soggetto_stato_id =rs_da.soggetto_stato_id 
and     tipo.data_cancellazione  is null 
and     tipo.validita_fine  is null 
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
and     sog.data_cancellazione  is null 
and     sog.validita_fine  is null 
and     mdp.data_cancellazione  is null 
and     mdp.validita_fine  is null 
and     rs_mdp.data_cancellazione  is null 
and     rs_mdp.validita_fine  is null 
and     rs.data_cancellazione  is null 
and     rs.validita_fine  is null 
and     rel.data_cancellazione  is null 
and     rel.validita_fine  is null 
and     rs_rel.data_cancellazione  is null 
and     rs_rel.validita_fine  is null 
and     rs_da.data_cancellazione  is null 
and     rs_da.validita_fine  is null 
and     sog_da.data_cancellazione  is null 
and     sog_da.validita_fine  is null;

--- UPD2 - BLOCCO SOGGETTO  MDP 
insert into siac_r_modpag_stato 
(
modpag_id,
modpag_stato_id,
login_operazione ,
validita_inizio ,
ente_proprietario_id 
)
select mdp.modpag_id ,
           statoB.modpag_stato_id ,
           'SIAC-TASK-56',
           now(),
           statoB.ente_proprietario_id 
from siac_t_soggetto sog,siac_t_modpag mdp ,siac_d_accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil oil,
           siac_r_soggetto_stato rs,siac_d_soggetto_stato stato, siac_r_modpag_stato  rs_mdp,siac_d_modpag_stato stato_mdp,siac_d_accredito_gruppo gruppo,
           siac_d_modpag_stato statoB
where sog.ente_proprietario_id in (2,3,4,5,10,16)
and     mdp.soggetto_id=sog.soggetto_id
and     tipo.accredito_tipo_id =mdp.accredito_tipo_id 
and     r.accredito_tipo_id =tipo.accredito_tipo_id 
and     oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and    gruppo.accredito_gruppo_id =tipo.accredito_gruppo_id               
and     rs.soggetto_id=sog.soggetto_id 
and     stato.soggetto_stato_id =rs.soggetto_stato_id 
and     stato.soggetto_stato_code not in ('BLOCCATO','ANNULLATO')
and     rs_mdp.modpag_id =mdp.modpag_id 
and     stato_mdp.modpag_stato_id=rs_mdp.modpag_stato_id 
and     stato_mdp.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and     statoB.ente_proprietario_id =stato_mdp.ente_proprietario_id 
and     statoB.modpag_stato_code ='BLOCCATO'
and     tipo.data_cancellazione  is null 
and     tipo.validita_fine  is null 
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
and     sog.data_cancellazione  is null 
and     sog.validita_fine  is null 
and     mdp.data_cancellazione  is null 
and     mdp.validita_fine  is null 
and     rs_mdp.data_cancellazione  is null 
and     rs_mdp.validita_fine  is null 
and     rs.data_cancellazione  is null 
and     rs.validita_fine  is null;

update siac_r_modpag_stato  rs_mdp
set      data_cancellazione=now(),
           validita_fine=now(),
           login_operazione =rs_mdp.login_operazione ||'-SIAC-TASK-56'
from siac_t_soggetto sog,siac_t_modpag mdp ,siac_d_accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil oil,
           siac_r_soggetto_stato rs,siac_d_soggetto_stato stato, siac_d_modpag_stato stato_mdp,siac_d_accredito_gruppo gruppo
where sog.ente_proprietario_id in (2,3,4,5,10,16)
and     mdp.soggetto_id=sog.soggetto_id
and     tipo.accredito_tipo_id =mdp.accredito_tipo_id 
and     r.accredito_tipo_id =tipo.accredito_tipo_id 
and     oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and    gruppo.accredito_gruppo_id =tipo.accredito_gruppo_id               
and     rs.soggetto_id=sog.soggetto_id 
and     stato.soggetto_stato_id =rs.soggetto_stato_id 
and     stato.soggetto_stato_code not in ('BLOCCATO','ANNULLATO')
and     rs_mdp.modpag_id =mdp.modpag_id 
and     stato_mdp.modpag_stato_id=rs_mdp.modpag_stato_id 
and     stato_mdp.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and     stato_mdp.modpag_stato_code !='BLOCCATO'
and     tipo.data_cancellazione  is null 
and     tipo.validita_fine  is null 
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
and     sog.data_cancellazione  is null 
and     sog.validita_fine  is null 
and     mdp.data_cancellazione  is null 
and     mdp.validita_fine  is null 
and     rs_mdp.data_cancellazione  is null 
and     rs_mdp.validita_fine  is null 
and     rs.data_cancellazione  is null 
and     rs.validita_fine  is null;

-- codici accredito da chiudere 
select oil.ente_proprietario_id , oil.accredito_tipo_oil_desc ,oil.accredito_tipo_oil_code , oil.accredito_tipo_oil_area ,tipo.accredito_tipo_code , tipo.accredito_tipo_desc , gruppo.accredito_gruppo_code 
from siac_d_accredito_tipo tipo ,siac_d_accredito_gruppo  gruppo ,siac_d_accredito_tipo_oil  oil,siac_r_accredito_tipo_oil  r
where tipo.ente_proprietario_id in ( 2,3,4,5,10,16)
and      tipo.accredito_gruppo_id =gruppo.accredito_gruppo_id 
and      r.accredito_tipo_id=tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
and     tipo.data_cancellazione  is null 
and     tipo.validita_fine  is null 
order by 1,2;

-- UPD3 - chiusura accredito 
update siac_d_accredito_tipo tipo
set       data_cancellazione=now(),
             validita_fine=now(),
             login_operazione =tipo.login_operazione ||'-SIAC-TASK-56'
from  siac_d_accredito_gruppo  gruppo ,siac_d_accredito_tipo_oil  oil,siac_r_accredito_tipo_oil  r
where tipo.ente_proprietario_id in ( 2,3,4,5,10,16)
and      tipo.accredito_gruppo_id =gruppo.accredito_gruppo_id 
and      r.accredito_tipo_id=tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( 
                 oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%'
                 or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%'  )
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null;

update siac_d_accredito_tipo_oil  oil 
set       data_cancellazione=now(),
             validita_fine=now(),
             login_operazione =oil.login_operazione ||'-SIAC-TASK-56'
from  siac_r_accredito_tipo_oil  r
where oil.ente_proprietario_id in ( 2,3,4,5,10,16)
and       ( 
                 oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%'
                 or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%'  )
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null;


update siac_r_accredito_tipo_oil  r 
set       data_cancellazione=now(),
             validita_fine=now(),
             login_operazione =r.login_operazione ||'-SIAC-TASK-56'
from    siac_d_accredito_tipo_oil  oil
where  oil.ente_proprietario_id in ( 2,3,4,5,10,16)
and       ( 
                 oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%'
                 or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%'  )
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      oil.data_cancellazione  is not null 
and      oil.login_operazione  like '%SIAC-TASK-56'
and      r.data_cancellazione  is null 
and      r.validita_fine  is null; 

-- UPD4 inserimento nuovo codice accredito 
insert into siac_d_accredito_tipo_oil 
(
    accredito_tipo_oil_code,
	accredito_tipo_oil_desc,
	validita_inizio,
	login_operazione,
	ente_proprietario_id
)
select '70',
            'ACCREDITO TESORERIA PROVINCIALE STATO',
            now(),
            'SIAC-TASK-56',
            ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id  in (2,3,4,5,10,16)
and     not exists 
(
select 1 
from siac_d_accredito_tipo_oil  oil 
where oil.ente_proprietario_id =ente.ente_proprietario_id 
and     oil.accredito_tipo_oil_desc ='ACCREDITO TESORERIA PROVINCIALE STATO'
and     oil.accredito_tipo_oil_code ='70'
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
);

insert into siac_d_accredito_tipo 
(
    accredito_tipo_code,
	accredito_tipo_desc ,
	accredito_gruppo_id,
	accredito_priorita,
	validita_inizio ,
	login_operazione ,
	ente_proprietario_id 
)
select 'ATP',
            'ACCREDITO TESORERIA PROVINCIALE STATO',
            gruppo.accredito_gruppo_id,
            0,
            now(),
            'SIAC-TASK-56',
            gruppo.ente_proprietario_id 
from siac_d_accredito_gruppo  gruppo 
where gruppo.ente_proprietario_id in (2,3,4,5,10,16)
and      gruppo.accredito_gruppo_code ='CB'
and     not exists 
(
select 1
from siac_d_accredito_tipo accre
where accre.ente_proprietario_id =gruppo.ente_proprietario_id 
and     ( accre.accredito_tipo_code ='ATP' or  accre.accredito_tipo_desc ='ACCREDITO TESORERIA PROVINCIALE STATO' )
and     accre.data_cancellazione  is null 
and     accre.validita_fine  is null 
);


insert into siac_r_accredito_tipo_oil 
(
    accredito_tipo_id,
	accredito_tipo_oil_id,
	validita_inizio ,
	login_operazione ,
	ente_proprietario_id 
)
select accre.accredito_tipo_id,
           oil.accredito_tipo_oil_id,
           now(),
           'SIAC-TASK-56',
           accre.ente_proprietario_id 
from siac_d_accredito_tipo  accre,siac_d_accredito_tipo_oil oil 
where oil.ente_proprietario_id in (2,3,4,5,10,16)
and     oil.accredito_tipo_oil_desc ='ACCREDITO TESORERIA PROVINCIALE STATO'
and     accre.ente_proprietario_id =oil.ente_proprietario_id 
and     accre.accredito_tipo_desc ='ACCREDITO TESORERIA PROVINCIALE STATO'
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
and     accre.data_cancellazione  is null 
and     accre.validita_fine  is null 
and     not exists 
(
select 
from siac_r_accredito_tipo_oil r 
where r.ente_proprietario_id =oil.ente_proprietario_id 
and     r.login_operazione ='SIAC-TASK-56'
and     r.data_cancellazione  is null 
and     r.validita_fine  is null
);

-- UPD5 aggiornamento conf MANDMIF_SPLUS
select mif.*
from mif_d_flusso_elaborato_tipo tipo,mif_d_flusso_elaborato  mif 
where tipo.ente_proprietario_id in (2,3,4,5,10,16)
and      tipo.flusso_elab_mif_tipo_code ='MANDMIF_SPLUS'
and      mif.flusso_elab_mif_tipo_id =tipo.flusso_elab_mif_tipo_id 
and     mif.flusso_elab_mif_code='tipo_pagamento'
order by mif.ente_proprietario_id , mif.flusso_elab_mif_ordine 
-- IX|CB|REG|SEPA|EXTRASEPA|ATP

update mif_d_flusso_elaborato  mif
set      flusso_elab_mif_param ='IX|CB|REG|SEPA|EXTRASEPA|ATP',
            data_modifica=now(),
            login_operazione =mif.login_operazione ||'-SIAC-TASK-56'
from mif_d_flusso_elaborato_tipo tipo 
where tipo.ente_proprietario_id in (2,3,4,5,10,16)
and      tipo.flusso_elab_mif_tipo_code ='MANDMIF_SPLUS'
and      mif.flusso_elab_mif_tipo_id =tipo.flusso_elab_mif_tipo_id 
and     mif.flusso_elab_mif_code='tipo_pagamento'
and     mif.login_operazione not like '%SIAC-TASK-56%';

-- verifiche per estrazioni e trattamento dati su movimenti 
-- Q2 - MANDATI - verifica esistenza mandati
-- dopo update UPD  dovranno essere relativi a MDP bloccate
select op.ente_proprietario_id ,op.anno_bilancio ,op.ord_numero , op.ord_stato_code , stato.modpag_stato_code,tipo.accredito_tipo_desc , oil.accredito_tipo_oil_desc , sog.soggetto_code, sog.soggetto_desc 
from siac_v_bko_ordinativo_op_valido op ,siac_r_ordinativo_modpag  rmdp,siac_t_modpag mdp ,siac_d_Accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil  oil ,
           siac_r_modpag_stato rs,siac_d_modpag_stato stato ,siac_t_soggetto sog 
where op.ente_proprietario_id in (2,3,4,5,10,16)
and      op.anno_bilancio >=2023
and      rmdp.ord_id=op.ord_id 
and      mdp.modpag_id =rmdp.modpag_id 
and      tipo.accredito_tipo_id=mdp.accredito_tipo_id 
and      r.accredito_tipo_id =tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and      rs.modpag_id =mdp.modpag_id 
and      stato.modpag_stato_id =rs.modpag_stato_id 
and      stato.modpag_stato_code  not in ('BLOCCATO','ANNULLATO')
and      sog.soggetto_id=mdp.soggetto_id
and      rmdp.data_cancellazione  is null 
and      rmdp.validita_fine  is null 
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      rs.data_cancellazione  is null 
and      rs.validita_fine  is null 
order by 1,2,3


select op.ente_proprietario_id ,op.anno_bilancio, op.ord_numero , op.ord_stato_code , tipo.accredito_tipo_desc , oil.accredito_tipo_oil_desc , stato.modpag_stato_code ,stato_rel.relaz_stato_code ,
            rel_tipo.relaz_tipo_code , sog_da.soggetto_code, sog_da.soggetto_desc, 
            sog_a.soggetto_code, sog_a.soggetto_desc 
from siac_v_bko_ordinativo_op_valido op ,
           siac_r_ordinativo_soggetto  rsog,
           siac_r_soggetto_relaz  relaz,siac_d_relaz_tipo rel_tipo, siac_t_modpag mdp ,siac_d_Accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil  oil ,
           siac_r_modpag_stato rs,siac_d_modpag_stato stato ,siac_r_soggetto_relaz_stato  rs_rel,siac_d_relaz_stato  stato_rel,
           siac_t_soggetto sog_da, siac_t_soggetto sog_a 
where op.ente_proprietario_id in (2,3,4,5,10,16)
and      op.anno_bilancio >=2023
and      rsog.ord_id=op.ord_id 
and      relaz.soggetto_id_da =rsog.soggetto_id 
and      rel_tipo.relaz_tipo_id=relaz.relaz_tipo_id 
and      rel_tipo.relaz_tipo_code ='CSI'
and      mdp.modpag_id =relaz.soggetto_id_a  
and      rs.modpag_id=mdp.modpag_id 
and      stato.modpag_stato_id =rs.modpag_stato_id 
and      stato.modpag_stato_code  not in ('BLOCCATO','ANNULLATO')
and      rs_rel.soggetto_relaz_id =relaz.soggetto_relaz_id 
and      stato_rel.relaz_stato_id =rs_rel.relaz_stato_id 
and      stato_rel.relaz_stato_code  not in ('BLOCCATO','ANNULLATO')
and      tipo.accredito_tipo_id=mdp.accredito_tipo_id 
and      r.accredito_tipo_id =tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%'
                           or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and     sog_da.soggetto_id =relaz.soggetto_id_da 
and     sog_a.soggetto_id=relaz.soggetto_id_a 
and      rsog.data_cancellazione  is null 
and      rsog.validita_fine  is null 
and      relaz.data_cancellazione  is null 
and      relaz.validita_fine  is null 
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      rs.data_cancellazione  is null 
and      rs.validita_fine  is null 
and      rs_rel.data_cancellazione  is null 
and      rs_rel.validita_fine  is null 
order by 1,2,3


-- Q3 - LIQUIDAZIONI- verifica esistenza liquidazioni
-- dopo update UPD  dovranno essere relative a MDP bloccate
-- fornire estrazioni per cambiare le MDP
select liq.ente_proprietario_id , liq.anno_bilancio ,liq.liq_anno,liq.liq_numero , liq.liq_stato_code  ,tipo.accredito_tipo_code, tipo.accredito_tipo_desc , oil.accredito_tipo_oil_desc ,stato.modpag_stato_code ,sog.soggetto_code, sog.soggetto_desc 
from siac_v_bko_liquidazione_valida liq, siac_t_liquidazione liq_mdp ,siac_t_modpag mdp ,siac_d_Accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil  oil ,
          siac_r_modpag_stato rs,siac_d_modpag_stato stato ,siac_t_soggetto sog 
where liq.ente_proprietario_id in (2,3,4,5,10,16)
and      liq.anno_bilancio >=2023
and      liq_mdp.liq_id=liq.liq_id 
and      mdp.modpag_id =liq_mdp.modpag_id 
and     sog.soggetto_id =mdp.soggetto_id
and      rs.modpag_id =mdp.modpag_id 
and      stato.modpag_stato_id =rs.modpag_stato_id 
and      stato.modpag_stato_code   not in ('BLOCCATO','ANNULLATO')
and      tipo.accredito_tipo_id=mdp.accredito_tipo_id 
and      r.accredito_tipo_id =tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and      not exists 
(
select 1 
from siac_r_liquidazione_ord rord,siac_t_ordinativo_ts ts,siac_t_ordinativo op ,siac_r_ordinativo_stato rs,siac_d_ordinativo_stato stato
where rord.liq_id=liq.liq_id 
and     ts.ord_ts_id=rord.sord_id 
and     op.ord_id=ts.ord_id 
and     op.bil_id=liq.bil_id 
and     rs.ord_id=op.ord_id 
and     stato.ord_Stato_id=rs.ord_stato_id 
and     stato.ord_stato_code!='A'
and     rord.data_cancellazione  is null 
and     rord.validita_fine   is null 
and     rs.data_cancellazione  is null 
and     rs.validita_fine   is null 
and     ts.data_cancellazione  is null 
and     ts.validita_fine   is null 
and     op.data_cancellazione  is null 
and     op.validita_fine   is null 
)
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      rs.data_cancellazione  is null 
and      rs.validita_fine  is null 
order by 1,2,3,4

-- Q4 - verifica esistenza documenti non liquidati
-- dopo update UPD  dovranno essere relativi a MDP bloccate
-- fornire estrazioni per cambiare le MDP
select tipo_doc.ente_proprietario_id , tipo_doc.doc_tipo_code, doc.doc_anno, doc.doc_numero,sub.subdoc_numero, stato.doc_stato_code , tipo.accredito_tipo_desc , oil.accredito_tipo_oil_desc , sub.subdoc_id,
            stato_mdp.modpag_stato_code , sog.soggetto_code, sog.soggetto_desc 
from siac_t_doc doc,siac_d_doc_tipo tipo_doc, siac_t_subdoc sub,siac_r_doc_Stato rs,siac_d_doc_stato stato, 
          siac_r_subdoc_modpag  rmdp,siac_t_modpag mdp ,siac_d_Accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil  oil ,
          siac_r_modpag_stato rs_mdp,siac_d_modpag_stato stato_mdp,siac_t_soggetto sog 
where tipo_doc.ente_proprietario_id in (2,3,4,5,10,16)
and      doc.doc_tipo_id=tipo_doc.doc_tipo_id 
and      sub.doc_id=doc.doc_id 
and      rs.doc_id=doc.doc_id 
and      stato.doc_stato_id=rs.doc_stato_id 
and      stato.doc_stato_code not in ('A','ST','L','EM')
and      rmdp.subdoc_id=sub.subdoc_id 
and     sog.soggetto_id=mdp.soggetto_id
and      mdp.modpag_id =rmdp.modpag_id 
and      tipo.accredito_tipo_id=mdp.accredito_tipo_id 
and      r.accredito_tipo_id =tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and      not exists 
(
select 1 
from siac_r_subdoc_liquidazione rliq,siac_t_liquidazione liq,siac_r_liquidazione_Stato rs_liq,siac_d_liquidazione_stato stato_liq, 
          siac_v_bko_anno_bilancio_only  anno
where rliq.subdoc_id=sub.subdoc_id 
and     rs_liq.liq_id=rliq.liq_id 
and     stato_liq.liq_Stato_id=rs_liq.liq_stato_id 
and     stato_liq.liq_Stato_code!='A'
and     liq.liq_id=rs_liq.liq_id
and     anno.bil_id=liq.bil_id 
and     anno.anno_bilancio >=2023
and     rs_liq.data_cancellazione  is null 
and     rs_liq.validita_fine  is null 
and     rliq.data_cancellazione  is null 
and     rliq.validita_fine  is null 
and     liq.data_cancellazione  is null 
and     liq.validita_fine  is null 
)
and      rs_mdp.modpag_id=mdp.modpag_id 
and      stato_mdp.modpag_stato_id =rs_mdp.modpag_stato_id 
and      stato_mdp.modpag_stato_code  not in ('BLOCCATO','ANNULLATO')
and      rmdp.data_cancellazione  is null 
and      rmdp.validita_fine  is null 
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      rs.data_cancellazione  is null 
and      rs.validita_fine  is null 
and      rs_mdp.data_cancellazione  is null 
and      rs_mdp.validita_fine  is null 
order by 1, doc.doc_id

select tipo_doc.ente_proprietario_id ,tipo_doc.doc_tipo_code, doc.doc_anno, doc.doc_numero,sub.subdoc_numero, stato.doc_stato_code , tipo.accredito_tipo_desc , oil.accredito_tipo_oil_desc , sub.subdoc_id,
            stato_mdp.modpag_stato_code ,stato_relaz.relaz_stato_code 
from siac_t_doc doc,siac_d_doc_tipo tipo_doc, siac_t_subdoc sub,siac_r_doc_Stato rs,siac_d_doc_stato stato, 
          siac_r_subdoc_modpag  rmdp,siac_t_modpag mdp ,siac_d_Accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil  oil ,
          siac_r_soggrel_modpag  rel_mdp,siac_r_modpag_stato rs_mdp,siac_d_modpag_stato stato_mdp,
          siac_r_soggetto_relaz_stato  rs_rel,siac_d_relaz_stato  stato_relaz
where tipo_doc.ente_proprietario_id in (2,3,4,5,10,16)
and      doc.doc_tipo_id=tipo_doc.doc_tipo_id 
and      sub.doc_id=doc.doc_id 
and      rs.doc_id=doc.doc_id 
and      stato.doc_stato_id=rs.doc_stato_id 
and      stato.doc_stato_code not in ('A','ST','L','EM')
and      rmdp.subdoc_id =sub.subdoc_id
and      rel_mdp.soggrelmpag_id =rmdp.soggrelmpag_id 
and      mdp.modpag_id =rel_mdp.modpag_id 
and      tipo.accredito_tipo_id=mdp.accredito_tipo_id 
and      r.accredito_tipo_id =tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
               or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and      not exists 
(
select 1 
from siac_r_subdoc_liquidazione rliq,siac_t_liquidazione liq,siac_r_liquidazione_Stato rs_liq,siac_d_liquidazione_stato stato_liq, 
          siac_v_bko_anno_bilancio_only  anno
where rliq.subdoc_id=sub.subdoc_id 
and     rs_liq.liq_id=rliq.liq_id 
and     stato_liq.liq_Stato_id=rs_liq.liq_stato_id 
and     stato_liq.liq_Stato_code!='A'
and     liq.liq_id=rs_liq.liq_id
and     anno.bil_id=liq.bil_id 
and     anno.anno_bilancio >=2023
and     rs_liq.data_cancellazione  is null 
and     rs_liq.validita_fine  is null 
and     rliq.data_cancellazione  is null 
and     rliq.validita_fine  is null 
and     liq.data_cancellazione  is null 
and     liq.validita_fine  is null 
)
and      rs_mdp.modpag_id=mdp.modpag_id 
and      stato_mdp.modpag_stato_id =rs_mdp.modpag_stato_id 
and      stato_mdp.modpag_stato_code  not in ('BLOCCATO','ANNULLATO')
and      rs_rel.soggetto_relaz_id =rel_mdp.soggetto_relaz_id 
and      stato_relaz.relaz_stato_id =rs_rel.relaz_stato_id 
and      stato_relaz.relaz_stato_code    not in ('BLOCCATO','ANNULLATO')
and      rel_mdp.data_cancellazione  is null 
and      rel_mdp.validita_fine  is null 
and      rmdp.data_cancellazione  is null 
and      rmdp.validita_fine  is null 
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      rs.data_cancellazione  is null 
and      rs.validita_fine  is null 
and      rs_mdp.data_cancellazione  is null 
and      rs_mdp.validita_fine  is null 
and      rs_rel.data_cancellazione  is null 
and      rs_rel.validita_fine  is null 
order by 1,doc.doc_id
