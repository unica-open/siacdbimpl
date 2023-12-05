/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿begin;

select count(*) from siac_t_ente_proprietario

select count(*) , ente_proprietario_id
from fase_bil_d_elaborazione_tipo
group by ente_proprietario_id

insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APROVA_PREV','APPROVAZIONE BILANCIO DI PREVISIONE SU GESTIONE','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
 				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APROVA_PREV'));



insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APROVA_PREV_SIM','APPROVAZIONE BILANCIO DI PREVISIONE SU GESTIONE-SIMULAZIONE','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
  				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APROVA_PREV_SIM'));



insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APE_PREV','APERTURA BILANCIO DI PREVISIONE DA GESTIONE ANNO PRECEDENTE','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
  				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APE_PREV'));


insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APE_PROV','APERTURA BILANCIO DI GESTIONE PROVVISORIO DA GESTIONE ANNO PRECEDENTE','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
  				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APE_PROV'));

insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APE_GEST_PLURI','APERTURA BILANCIO DI GESTIONE - RIBALTAMENTO PLURIENNALI','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
  				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APE_GEST_PLURI'));


insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APE_CAP_CALC_RES','APERTURA BILANCIO : CALCOLO RESIDUI PRESUNTI E CASSA','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
  				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APE_CAP_CALC_RES'));

insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APE_GEST_LIQ_RES','APERTURA BILANCIO : RIBALTAMENTO LIQUIDAZIONI RESIDUE','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
  				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APE_GEST_LIQ_RES'));

insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APE_GEST_ACC_RES','APERTURA BILANCIO : RIBALTAMENTO ACCERTAMENTI RESIDUI','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
  				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APE_GEST_ACC_RES'));



insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APE_GEST_IMP_RES','APERTURA BILANCIO : RIBALTAMENTO IMPEGNI RESIDUI','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
  				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APE_GEST_IMP_RES'));

insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APE_GEST_VINCOLI','APERTURA BILANCIO : RIBALTAMENTO VINCOLI','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
  				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APE_GEST_VINCOLI'));


insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
(select 'APE_GEST_REIMP','APERTURA BILANCIO : GESTIONE REIMPUTAZIONE IMPEGNI-ACCERTAMENTI','2016-01-01','admin',ep.ente_proprietario_id
 from siac_t_ente_proprietario ep
 where  not exists (select 1
  				  from  fase_bil_d_elaborazione_tipo d
                  where d.ente_proprietario_id=ep.ente_proprietario_id
                  and   d.fase_bil_elab_tipo_code='APE_GEST_REIMP'));

rollback;