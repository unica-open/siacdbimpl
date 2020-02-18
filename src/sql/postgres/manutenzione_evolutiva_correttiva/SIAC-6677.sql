/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select * from fnc_dba_add_column_params ( 'siac_t_doc', 'doc_data_operazione', 'timestamp without time zone');
select * from fnc_dba_add_column_params ( 'siac_t_doc', 'cod_avviso_pago_pa', 'varchar(100)');
select * from fnc_dba_add_column_params ( 'siac_t_doc', 'iuv', 'varchar(100)');
select * from fnc_dba_add_column_params ( 'siac_t_doc', 'doc_numero_prima_auto_iva', 'varchar(200)');


INSERT INTO siac.siac_t_attr(
	attr_code,
	attr_desc, 
	attr_tipo_id, 
	tabella_nome, 
	validita_inizio, 
	ente_proprietario_id,
	data_creazione,
	data_modifica,
	login_operazione)
	select distinct 'flagNumerazioneAutomaticaDaIVA' , 'Flag Numerazione Automatica da IVA', 
	c.attr_tipo_id, null, current_timestamp, c.ente_proprietario_id, current_timestamp,current_timestamp, 
	'admin' from  siac.siac_d_attr_tipo c  where c.attr_tipo_code='B'
	and not exists
	(
	select 1
	from siac_t_attr attr
	where attr.ente_proprietario_id=c.ente_proprietario_id
	and attr.attr_tipo_id=c.attr_tipo_id
	and attr.attr_code='flagNumerazioneAutomaticaDaIVA'
	and attr.data_cancellazione is null
	and attr.validita_fine is null
	);
	
	
	INSERT INTO siac.siac_r_doc_tipo_attr(
	doc_tipo_id,
	attr_id, 
	"boolean",
	validita_inizio,
	ente_proprietario_id,
	data_creazione, 
	data_modifica, 
	login_operazione)
	select distinct 
	b.doc_tipo_id ,
	(select c.attr_id from siac.siac_t_attr c where c.attr_code = 'flagNumerazioneAutomaticaDaIVA'
	and b.ente_proprietario_id = c.ente_proprietario_id) as attr_id,
	'N', 
	current_timestamp, 
	b.ente_proprietario_id,
	current_timestamp, 
	current_timestamp,
	'admin'
	from siac.siac_d_doc_tipo b
	where not exists
	(
	select 1
	from siac_r_doc_tipo_attr attr
	where attr.ente_proprietario_id=b.ente_proprietario_id
	and attr.attr_id=(select c.attr_id from siac.siac_t_attr c where c.attr_code = 'flagNumerazioneAutomaticaDaIVA'
	and b.ente_proprietario_id = c.ente_proprietario_id) 
	and attr.data_cancellazione is null
	and attr.validita_fine is null
	);
	
	