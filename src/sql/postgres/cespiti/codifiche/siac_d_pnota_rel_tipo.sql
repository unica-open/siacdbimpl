/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO
  siac.siac_d_prima_nota_rel_tipo
(
  pnota_rel_tipo_code,
  pnota_rel_tipo_desc,
  ente_proprietario_id,  
  validita_inizio,  
  data_creazione,
  data_modifica,
  login_operazione
)
SELECT tmp.code, tmp.descr, tep.ente_proprietario_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), now(),now(),'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('COGE-INV', 'Prima nota da contabilita generale'), ('INV-COGE', 'Prima nota da inventario contabile')) AS tmp(code, descr)
WHERE NOT EXISTS (select 1 
	from siac_d_prima_nota_rel_tipo z 
	where z.pnota_rel_tipo_code=tmp.code
	and z.ente_proprietario_id=tep.ente_proprietario_id
	and z.data_cancellazione is null
)
ORDER BY tep.ente_proprietario_id, tmp.code;