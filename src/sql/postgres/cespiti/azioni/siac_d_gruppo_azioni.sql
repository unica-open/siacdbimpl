/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO
  siac.siac_d_gruppo_azioni
(
  gruppo_azioni_code,
  gruppo_azioni_desc,
  titolo, 
  validita_inizio,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  login_operazione
)
select 'INV',
'Inventario',
'12 - Inventario',
now(),
a.ente_proprietario_id,
now(),
now(),
'admin'
from siac_t_ente_proprietario a
where
not exists (select 1 
from siac_d_gruppo_azioni z 
where z.gruppo_azioni_code='INV'
and z.ente_proprietario_id=a.ente_proprietario_id
and z.data_cancellazione is null);