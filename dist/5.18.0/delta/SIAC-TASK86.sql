/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-TASK #86 - Paolo - INIZIO
/*per il parametro NUMERAZIONE_AUTOMATICA_CAPITOLO*/
insert into siac_t_parametro_config_ente (
	ente_proprietario_id,
	parametro_nome,
	parametro_valore,
	parametro_note,
	validita_inizio,
	login_operazione 
) select 
	e.ente_proprietario_id ,
	x.nome,
	null,
	x.note,
	now(),
	'admin'
 from siac_t_ente_proprietario e, 
(values 
	('capitolo.inserisci.abilitaNumerazioneAutomatica', 'Abilitazione numerazione automatica capitoli CMTO'),
	('capitolo.inserisci.limiteNumerazioneAutomatica', 'Limite numerazione automatica capitoli CMTO') 
) as x (nome, note) 
where not exists ( select 1 from siac_t_parametro_config_ente p where parametro_nome = x.nome and e.ente_proprietario_id = p.ente_proprietario_id)
and e.ente_code = 'CMTO'
and e.in_uso
;
  
--SIAC-TASK #86 - Paolo - FINE