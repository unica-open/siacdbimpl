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
  validita_inizio,
  ente_proprietario_id,
  login_operazione
) select 'OP-ENT-PreDocNoModAcc', 'Predoc entrata - modifica acc. non ammessa', ta.azione_tipo_id, ga.gruppo_azioni_id,
 '/../siacbilapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'),
 e.ente_proprietario_id, 'admin'
  from siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
  where  ta.ente_proprietario_id = e.ente_proprietario_id
  and ga.ente_proprietario_id = e.ente_proprietario_id
  and ta.azione_tipo_code = 'AZIONE_SECONDARIA'
  and ga.gruppo_azioni_code = 'FIN_BASE2'
  and not exists (select 1 from siac_t_azione z where z.azione_tipo_id=ta.azione_tipo_id
  and z.azione_code='OP-ENT-PreDocNoModAcc')
  ;