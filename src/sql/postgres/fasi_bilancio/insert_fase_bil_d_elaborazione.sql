/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- caricamento fase_bil_d_elaborazione_tipo

insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
 values
('APROVA_PREV','APPROVAZIONE BILANCIO DI PREVISIONE SU GESTIONE','2016-01-01','admin',&ente);


insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
 values
('APROVA_PREV_SIM','APPROVAZIONE BILANCIO DI PREVISIONE SU GESTIONE-SIMULAZIONE','2016-01-01','admin',&ente);


insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
 values
('APE_PREV','APERTURA BILANCIO DI PREVISIONE DA GESTIONE ANNO PRECEDENTE','2016-01-01','admin',&ente);

insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
 values
('APE_PROV','APERTURA BILANCIO DI GESTIONE PROVVISORIO DA GESTIONE ANNO PRECEDENTE','2016-01-01','admin',&ente);

insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
 values
('APE_GEST_PLURI','APERTURA BILANCIO DI GESTIONE - RIBALTAMENTO PLURIENNALI','2016-01-01','admin',&ente);

insert into fase_bil_d_elaborazione_tipo
(fase_bil_elab_tipo_code,fase_bil_elab_tipo_desc,
 validita_inizio,login_operazione, ente_proprietario_id)
 values
('APE_CAP_CALC_RES','APERTURA BILANCIO : CALCOLO RESIDUI PRESUNTI E CASSA','2016-01-01','admin',&ente);

select * from fase_bil_d_elaborazione_tipo
where ente_proprietario_id=&ente