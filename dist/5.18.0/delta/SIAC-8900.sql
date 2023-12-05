/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-8900 - Paolo - INIZIO
/*per il parametro PROGETTO_ABILITA_GESTIONE_ESERCIZIO_PROVVISORIO*/
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
	true,
	x.note,
	now(),
	'admin'
 from siac_t_ente_proprietario e, 
(values 
	('progetto.abilita.gestione.esercizioProvvisorio', 'Abilita gestione esercizio provvisorio') 
) as x (nome, note) 
where not exists ( select 1 from siac_t_parametro_config_ente p where parametro_nome = x.nome and e.ente_proprietario_id = p.ente_proprietario_id)
and e.ente_code in ('REGP', 'CMTO', 'AIPO', 'CRP')
and e.in_uso
; 

--SIAC-8900 - Paolo - FINE