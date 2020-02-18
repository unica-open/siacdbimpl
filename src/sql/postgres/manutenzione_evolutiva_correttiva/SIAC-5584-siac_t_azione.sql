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
select 'OP-COM-ComplMultAttoAllegato',
'Completamento multiplo atti contabili/allegati',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacbilapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='ATTIVITA_SINGOLA'
and b.gruppo_azioni_code='FIN_BASE1' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-COM-ComplMultAttoAllegato'
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
select 'OP-COM-ConvMultAttoAllegato',
'Convalida multiplo atti contabili/allegati',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacbilapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='ATTIVITA_SINGOLA'
and b.gruppo_azioni_code='FIN_BASE1' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-COM-ConvMultAttoAllegato'
and z.ente_proprietario_id=a.ente_proprietario_id);