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
select 'OP-COM-bloccaCTE-Acc',
'blocca combo Transazione Elementare entrate',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacfinapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=a.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='FIN_BASE1' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-COM-bloccaCTE-Acc'
and z.ente_proprietario_id=a.ente_proprietario_id and z.data_cancellazione is null);

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
select 'OP-COM-bloccaCTE-Imp',
'blocca combo Transazione Elementare spese',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacfinapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=a.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='FIN_BASE1' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-COM-bloccaCTE-Imp'
and z.ente_proprietario_id=a.ente_proprietario_id and z.data_cancellazione is null);
