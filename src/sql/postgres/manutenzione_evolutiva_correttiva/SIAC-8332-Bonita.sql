/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac_d_variazione_stato (variazione_stato_tipo_code, variazione_stato_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2022-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin-SIAC-8332'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('BD', 'BOZZA-decentrata')) AS tmp(code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_variazione_stato dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.variazione_stato_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

update siac_t_azione az set azione_tipo_id = (
	select azione_tipo_id 
	from siac_d_azione_tipo tp 
	where tp.data_cancellazione  is null 
	and tp.azione_tipo_code = 'AVVIO_PROCESSO'
	and tp.ente_proprietario_id  = az.ente_proprietario_id 
), nomeprocesso ='VariazioneDiBilancio', nometask='VariazioneDiBilancio-InserimentoVariazioneDecentrata', verificauo = true
where az.azione_code = 'OP-GESC001-insVarDecentrato';

update siac_t_azione az set azione_tipo_id = (
	select azione_tipo_id 
	from siac_d_azione_tipo tp 
	where tp.data_cancellazione  is null 
	and tp.azione_tipo_code = 'ATTIVITA_PROCESSO'
	and tp.ente_proprietario_id  = az.ente_proprietario_id 
), nomeprocesso ='VariazioneDiBilancio', nometask='VariazioneDiBilancio-AggiornamentoVariazioneDecentrata', verificauo = true 
where az.azione_code = 'OP-GESC002-aggVarDecentrato';

select * from fnc_dba_add_column_params('siac_d_variazione_tipo', 'tipologia', 'varchar(10)');

update siac_d_variazione_tipo set tipologia = 'IMPORTO' where variazione_tipo_code <> 'CD';

update siac_d_variazione_tipo set tipologia = 'CODIFICHE' where variazione_tipo_code = 'CD';

select * from fnc_dba_add_column_params('siac_d_variazione_stato', 'azione_pendente_id', 'integer');

select * from fnc_dba_add_fk_constraint('siac_d_variazione_stato', 'siac_d_variazione_stato_siac_t_azione_fk', 'azione_pendente_id', 'siac_t_azione', 'azione_id');

update siac_d_variazione_stato st set azione_pendente_id = 
(select azione_id 
	from siac_t_azione az 
	where az.data_cancellazione  is null 
	and az.azione_code = 'OP-GESC002-aggVarDecentrato'
	and st.ente_proprietario_id  = az.ente_proprietario_id 
)
where st.variazione_stato_tipo_code ='BD';

update siac_d_variazione_stato st set azione_pendente_id = 
(select azione_id 
	from siac_t_azione az 
	where az.data_cancellazione  is null 
	and az.azione_code = 'OP-GESC002-aggVar'
	and az.azione_desc  like '%Bilancio%'
	and st.ente_proprietario_id  = az.ente_proprietario_id 
)
where st.variazione_stato_tipo_code ='B';

update siac_d_variazione_stato st set azione_pendente_id = 
(select azione_id 
	from siac_t_azione az 
	where az.data_cancellazione  is null 
	and az.azione_code = 'OP-GESC002-aggVar'
	and az.azione_desc  like '%Giunta%'
	and st.ente_proprietario_id  = az.ente_proprietario_id 
)
where st.variazione_stato_tipo_code ='G';

update siac_d_variazione_stato st set azione_pendente_id = 
(select azione_id 
	from siac_t_azione az 
	where az.data_cancellazione  is null 
	and az.azione_code = 'OP-GESC002-aggVar'
	and az.azione_desc  like '%Consiglio%'
	and st.ente_proprietario_id  = az.ente_proprietario_id 
)
where st.variazione_stato_tipo_code ='C';

update siac_d_variazione_stato st set azione_pendente_id = 
(select azione_id 
	from siac_t_azione az 
	where az.data_cancellazione  is null 
	and az.azione_code = 'OP-GESC003-defVar'
	and st.ente_proprietario_id  = az.ente_proprietario_id 
)
where st.variazione_stato_tipo_code ='P';


