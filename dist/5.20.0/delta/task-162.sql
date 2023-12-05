/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--task-162 - Paolo - INIZIO
/*per il parametro INSERISCI_ORDINATIVO_PAGAMENTO_DEFAULT_COMMISSIONI*/
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
	('ordinativo.pagamento.inserisci.default.commissioni', 'Inserisci ordinativo pagamento dafault commissioni') 
) as x (nome, note) 
where not exists ( select 1 from siac_t_parametro_config_ente p where parametro_nome = x.nome and e.ente_proprietario_id = p.ente_proprietario_id)
and e.ente_code = 'REGP'
and e.in_uso
; 
--task-162 - Paolo - FINE