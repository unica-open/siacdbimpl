/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--Inserimento azione GESC001-insVarDecentrato e relazione con ruolo
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GESC001-insVarDecentrato','Inserisci Variazione di Bilancio',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacbilapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac.siac_d_azione_tipo a JOIN siac.siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = 'BIL_ALTRO'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-GESC001-insVarDecentrato'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

--Inserimento azione OP-GESC002-aggVarDecentrato
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GESC002-aggVarDecentrato','Aggiorna Variazione Decentrata',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacbilapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac.siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = ''
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-GESC002-aggVarDecentrato'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

/*
INSERT INTO siac_r_ruolo_op_azione (ruolo_op_id, azione_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dro.ruolo_op_id, ta.azione_id, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_ruolo_op dro ON dro.ente_proprietario_id = tep.ente_proprietario_id
JOIN siac_t_azione ta ON ta.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('OP-GESC001-insVarDecentrato', 'ruolo op decentrato', '')) AS tmp(azione, ruolo, ente)
WHERE dro.ruolo_op_code = tmp.ruolo AND tep.ente_proprietario_id = 2
AND ta.azione_code = tmp.azione
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_ruolo_op_azione rroa
	WHERE rroa.ente_proprietario_id = tep.ente_proprietario_id
	AND rroa.ruolo_op_id = dro.ruolo_op_id
	AND rroa.azione_id = ta.azione_id
	AND rroa.data_cancellazione IS NULL
);*/
---
--update desc Classificatore3
update siac_d_class_tipo set classif_tipo_desc='Capitolo Budget' 
where classif_tipo_code='CLASSIFICATORE_3' and ente_proprietario_id in 
(select ente_proprietario_id from siac_t_ente_proprietario)
and not exists (select 1 from siac_d_class_tipo z where z.classif_tipo_desc='Capitolo Budget');

--insert values for Capitolo Budget
insert into siac_t_class
(classif_code,  classif_desc,  classif_tipo_id, validita_inizio,  ente_proprietario_id, data_creazione,login_operazione)
select '01','SI', tipo.classif_tipo_id, now(), e.ente_proprietario_id, now(), 'SIAC-6884'
  from siac_d_class_tipo tipo,  siac_t_ente_proprietario e
  where  tipo.ente_proprietario_id = e.ente_proprietario_id
  and tipo.classif_tipo_code='CLASSIFICATORE_3'
  and not exists (
    select 1
    from siac_t_class z
	where z.classif_tipo_id=tipo.classif_tipo_id and z.classif_code='01'
  );


insert into siac_t_class
(classif_code,  classif_desc,  classif_tipo_id, validita_inizio,  ente_proprietario_id, data_creazione,login_operazione)
select '02','NO', tipo.classif_tipo_id, now(), e.ente_proprietario_id, now(), 'SIAC-6884'
  from siac_d_class_tipo tipo,  siac_t_ente_proprietario e
  where  tipo.ente_proprietario_id = e.ente_proprietario_id
  and tipo.classif_tipo_code='CLASSIFICATORE_3'
  and not exists (
    select 1
    from siac_t_class z
	where z.classif_tipo_id=tipo.classif_tipo_id and z.classif_code='02'
  );

 --Alter table con nuove colonne
SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'data_apertura_proposta' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'classif_id' , 'INTEGER');
SELECT * FROM fnc_dba_add_fk_constraint('siac_t_variazione', 'siac_t_class_siac_t_variazione', 'classif_id', 'siac.siac_t_class', 'classif_id');

SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'data_chiusura_proposta' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'data_definitiva' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'flag_consiglio', 'BOOLEAN DEFAULT false NOT NULL');
SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'flag_giunta', 'BOOLEAN DEFAULT false NOT NULL');
----


INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2019-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('REGIONE_PIEMONTE_INS_CAP_VAR_DEC', 'Regione Piemonte Inserimento capitolo in variazione decentrata')) AS tmp(code, descr)
WHERE tep.ente_denominazione ='Regione Piemonte' AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;
-------------------------------
INSERT INTO siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('TRUE', 'TRUE', 'REGIONE_PIEMONTE_INS_CAP_VAR_DEC')) AS tmp(code, descr, tipo)
WHERE dgt.gestione_tipo_code = tmp.tipo AND tep.ente_denominazione ='Regione Piemonte'
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
	AND dgt.gestione_tipo_code = tmp.tipo
)
ORDER BY tep.ente_proprietario_id, tmp.code;
-----
INSERT INTO siac_r_gestione_ente (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dgl.gestione_livello_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('TRUE', 'Regione Piemonte')) AS tmp(livello, ente)
WHERE tep.ente_denominazione = tmp.ente
AND dgl.gestione_livello_code = tmp.livello
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
	AND rge.data_cancellazione IS NULL
);



