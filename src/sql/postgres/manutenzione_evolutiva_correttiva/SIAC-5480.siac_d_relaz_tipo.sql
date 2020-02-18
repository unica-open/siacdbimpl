/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO 
  siac.siac_d_relaz_tipo
(
  relaz_tipo_code,
  relaz_tipo_desc,
  relaz_entita_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'REI_ORD','ORDINATIVO SUBORDINATO - DA INCASSO A PAGAMENTO',b.relaz_entita_id,
to_timestamp('01/01/2017','dd/mm/yyyy'),a.ente_proprietario_id,
'admin'
from siac.siac_t_ente_proprietario a
left join siac.siac_d_relaz_entita b
on b.ente_proprietario_id=a.ente_proprietario_id
and b.relaz_entita_code=null	