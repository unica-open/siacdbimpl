/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- QA3 default
-- per test 
insert into pagopa_r_iqs2_configura_sac
(
pagopa_iqs2_conf_sac_code,
classif_id,
validita_inizio ,
login_operazione ,
ente_proprietario_id 
)
select '29',
            c.classif_id,
            now(),
            'SIAC-TASK-125-126',
            c.ente_proprietario_id 
from siac_t_ente_proprietario  ente,siac_t_class c,siac_d_class_tipo tipo  
where ente.ente_proprietario_id =2
and      tipo.ente_proprietario_id =ente.ente_proprietario_id 
and      tipo.classif_tipo_code in ('CDC','CDR')
and      c.classif_tipo_id=tipo.classif_tipo_id 
--and      c.classif_code='QA3'
and      c.classif_code='A1409C'
and      c.data_cancellazione   is null 
and     c.validita_fine  is null 

-- caricare inizialmente solo la 29
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '1',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '2',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '3',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '4',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '5',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '6',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '7',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '8',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '9',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='TA1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='TA1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '10',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UB1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UB1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '11',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UB1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UB1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '12',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC3' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC3' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '13',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '14',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='TA2' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='TA2' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '15',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='QA4' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='QA4' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '16',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UB0' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UB0' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '17',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='SA3-1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='SA3-1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '18',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='SA3-1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='SA3-1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '19',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='SA3-1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='SA3-1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '20',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='SA3-1' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='SA3-1' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '21',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='QA3' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='QA3' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '22',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='TA2' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='TA2' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '23',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='TA0' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='TA0' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '24',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='QA3' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='QA3' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '25',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='QA3' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='QA3' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '26',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='UC3' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='UC3' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '27',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='TA0' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='TA0' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '28',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='TA3' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='TA3' and r.data_cancellazione is null and r.validita_fine is null );
insert into pagopa_r_iqs2_configura_sac ( pagopa_iqs2_conf_sac_code, classif_id, validita_inizio , login_operazione , ente_proprietario_id  ) select '29',c.classif_id, now()::timestamp, 'SIAC-125-126', tipo.ente_proprietario_id from siac_t_class c,siac_d_class_tipo tipo where tipo.ente_proprietario_id in (2,3,4,5,10,16) and tipo.classif_tipo_code in ('CDC','CDR') and c.classif_tipo_id=tipo.classif_tipo_id and c.classif_code='QA3' and c.data_cancellazione is null and c.validita_fine is null and not exists (select 1 from pagopa_r_iqs2_configura_sac r where r.ente_proprietario_id=tipo.ente_proprietario_id and r.pagopa_iqs2_conf_sac_code='QA3' and r.data_cancellazione is null and r.validita_fine is null );

-- PPAY
insert into pagopa_r_iqs2_configura_sac
(
pagopa_iqs2_conf_sac_code,
classif_id,
validita_inizio ,
login_operazione ,
ente_proprietario_id 
)
select 'UC1',
            c.classif_id,
            now(),
            'SIAC-TASK-125-126',
            c.ente_proprietario_id 
from siac_t_ente_proprietario  ente,siac_t_class c,siac_d_class_tipo tipo  
where ente.ente_proprietario_id  in (2,3,4,5,10,16)
and      tipo.ente_proprietario_id =ente.ente_proprietario_id 
and      tipo.classif_tipo_code in ('CDC','CDR')
and      c.classif_tipo_id=tipo.classif_tipo_id 
--and      c.classif_code='UC1'
and      c.classif_code='A1409C'
and      not exists 
(
select 1 
from pagopa_r_iqs2_configura_sac r 
where r.ente_proprieario_id=tipo.ente_proprietario_id  
and     r.pagopa_iqs2_conf_sac_code ='UC1'
and     r.data_cancellazione  is null 
and     r.validita_fine  is null
)
and      c.data_cancellazione   is null 
and     c.validita_fine  is null; 




insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'IN_ACQUISIZIONE',
  'ACQUISIZIONE IN CORSO',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and     not exists 
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='IN_ACQUISIZIONE'
);


insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'ACQUISITO',
  'ACQUISITO IN ATTESA DI ELABORAZIONE',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and     not exists 
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='ACQUISITO'
);


insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'RIFIUTATO',
  'RIFIUTATO PER ERRORI IN FASE DI ACQUISIZIONE',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and not exists
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='RIFIUTATO'
);

insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'ELABORATO_IN_CORSO',
  'ELABORAZIONE IN CORSO',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and not exists
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='ELABORATO_IN_CORSO'
);



insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'ELABORATO_IN_CORSO_ER',
  'ELABORAZIONE IN CORSO CON ESITI ERRATO',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and not exists
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='ELABORATO_IN_CORSO_ER'
);


insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'ELABORATO_IN_CORSO_SC',
  'ELABORAZIONE IN CORSO CON ESITI SCARTATO',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and not exists
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='ELABORATO_IN_CORSO_SC'
);


insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'ELABORATO_OK',
  'ELABORATO CON ESITO POSITIVO -  DOCUMENTI EMESSI',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and not exists
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='ELABORATO_OK'
);

insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'ELABORATO_KO',
  'ELABORATO CON ESITO ERRATO -  DOCUMENTI EMESSI - PRESENZA ERRORI - SCARTI',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and not exists
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='ELABORATO_KO'
);


insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'ELABORATO_ERRATO',
  'ELABORATO CON ESITO ERRATO',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and not exists
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='ELABORATO_ERRATO'
);


insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'ELABORATO_SCARTATO',
  'ELABORATO CON ESITO SCARTATO',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and not exists
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='ELABORATO_SCARTATO'
);

insert into siac_d_file_pagopa_iqs2_stato  
(
file_pagopa_iqs2_stato_code,
file_pagopa_iqs2_stato_desc,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 
  'ANNULLATO',
  'ANNULLATO',
  now(),
  'SIAC-125-126',
  ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and not exists
(
select 1 
from siac_d_file_pagopa_iqs2_stato stato 
where stato.ente_proprietario_id =ente.ente_proprietario_id 
and     stato.file_pagopa_iqs2_stato_code ='ANNULLATO'
);


