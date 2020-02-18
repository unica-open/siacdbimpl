/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-REP-ReportVariazioniBilancio-2016',
'Sezione report variazioni bilancio',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacrepapp/azioneRichiestaContentOnly.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='REPORTISTICA' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-REP-ReportVariazioniBilancio-2016'
and z.ente_proprietario_id=a.ente_proprietario_id);


INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-REP-ReportVariazioniBilancio-2017',
'Sezione report variazioni bilancio',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacrepapp/azioneRichiestaContentOnly.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='REPORTISTICA' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-REP-ReportVariazioniBilancio-2017'
and z.ente_proprietario_id=a.ente_proprietario_id);


INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-REP-ReportVariazioniBilancio-2018',
'Sezione report variazioni bilancio',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacrepapp/azioneRichiestaContentOnly.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='REPORTISTICA' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-REP-ReportVariazioniBilancio-2018'
and z.ente_proprietario_id=a.ente_proprietario_id);



INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-REP-ReportVariazioniBilancio-2019',
'Sezione report variazioni bilancio',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacrepapp/azioneRichiestaContentOnly.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='REPORTISTICA' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-REP-ReportVariazioniBilancio-2019'
and z.ente_proprietario_id=a.ente_proprietario_id);




insert into siac_r_ruolo_op_azione
(
  ruolo_op_id,
  azione_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_cancellazione,
  login_operazione
)
select 
rop.ruolo_op_id,
a0.azione_id,
now(),
null,
a0.ente_proprietario_id,
null,
'admin' 
from siac_t_azione a0,
(select ra.ruolo_op_id from siac_t_azione a, 
siac_r_ruolo_op_azione ra
where ra.azione_id=a.azione_id
and a.azione_code='OP-GESC004-ricVar'
and ra.data_cancellazione is NULL
and ra.validita_fine IS NULL
) rop
where a0.azione_code like 'OP-REP-ReportVariazioniBilancio-____'
and not exists (
select 1 from siac_r_ruolo_op_azione ra0
where ra0.azione_id=a0.azione_id
and ra0.ruolo_op_id=rop.ruolo_op_id)




