/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table siac.siac_r_bil_elem_previsione_impacc;
CREATE TABLE IF NOT EXISTS siac.siac_r_bil_elem_previsione_impacc 
(
	bil_elem_prev_id serial NOT NULL,
	elem_id integer NOT NULL,
	importo_prev_anno1 numeric null,
	importo_prev_anno2 numeric null,
	importo_prev_anno3 numeric null,
	importo_prev_note  varchar(500) null ,
    validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT null,
	CONSTRAINT pk_siac_r_bil_elem_prev PRIMARY KEY (bil_elem_prev_id),
	CONSTRAINT siac_t_bil_elem_siac_r_bil_elem_prev FOREIGN KEY (elem_id) REFERENCES siac.siac_t_bil_elem(elem_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_bil_elem_prev FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE UNIQUE INDEX idx_siac_r_bil_elem_prev_1 ON siac_r_bil_elem_previsione_impacc USING btree (elem_id,  validita_inizio, ente_proprietario_id)
WHERE (data_cancellazione IS NULL);
CREATE INDEX siac_r_bil_elem_prev_fk_elem_id_idx ON siac_r_bil_elem_previsione_impacc USING btree (elem_id);
CREATE INDEX siac_r_bil_elem_prev_fk_ente_proprietario_id_idx ON siac_r_bil_elem_previsione_impacc USING btree (ente_proprietario_id);

alter table siac.siac_r_bil_elem_previsione_impacc  OWNER to siac;

  
drop view if exists siac.siac_v_dwh_bil_elem_previsione_impacc;
drop view if exists siac.siac_v_dwh_bil_elem_prev_impacc;
drop view if exists siac.siac_v_dwh_bil_elem_prev_iacc;
CREATE OR REPLACE VIEW siac.siac_v_dwh_bil_elem_prev_iacc  
(
ente_proprietario_id,
ente_denominazione,
bil_anno,
elem_tipo_code_capitolo,
elem_tipo_desc_capitolo,
elem_code_capitolo,
elem_code_articolo,
elem_code_ueb,
elem_importo_prev_anno1,
elem_importo_prev_anno2,
elem_importo_prev_anno3,
elem_importo_prev_note
)
as
select ente.ente_proprietario_id,
       ente.ente_denominazione, 
       per.anno::varchar(4) bil_anno,
       tipo.elem_tipo_code elem_tipo_code_capitolo,
       tipo.elem_tipo_desc elem_tipo_desc_capitolo,
       e.elem_code elem_code_capitolo,
       e.elem_code2 elem_code_articolo,
       e.elem_code3 elem_code_ueb,
       r.importo_prev_anno1 elem_importo_prev_anno1,
       r.importo_prev_anno2 elem_importo_prev_anno2,
       r.importo_prev_anno3 elem_importo_prev_anno3,
       r.importo_prev_note
from siac_r_bil_elem_previsione_impacc r,
     siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_t_ente_proprietario ente
where  e.ente_proprietario_id=ente.ente_proprietario_id 
and    e.elem_id=r.elem_id
and    tipo.elem_tipo_id=e.elem_tipo_id
and    bil.bil_id=e.bil_id
and    per.periodo_id=bil.periodo_id
and    r.data_cancellazione is null 
and    r.validita_fine is null 
and    e.data_cancellazione is null;


alter view siac.siac_v_dwh_bil_elem_prev_iacc  OWNER to siac;

INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GESC090-prevImpegnatoAccertatoCap','Ricerca Capitoli Previsione a Chiudere per Impegnato/Accertato',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacbilapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin-SIAC-8191'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = 'BIL_ALTRO'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-GESC090-prevImpegnatoAccertatoCap'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-FLUSSO-PREVISIONE-IMP-ACC','Gestione capitoli per impegnato accertato',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacintegser/ElaboraFileService',now(),a.ente_proprietario_id,'admin-SIAC-8191'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = 'BIL_ALTRO'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-FLUSSO-PREVISIONE-IMP-ACC'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

INSERT INTO siac_d_file_tipo (file_tipo_code, file_tipo_desc, azione_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'PREVISIOONE-IMP-ACC','Capitoli previsione a chiudere impegnato/accertato',a.azione_id, now(),a.ente_proprietario_id,'admin-SIAC-8191'
FROM siac_t_azione a
WHERE a.azione_code = 'OP-FLUSSO-PREVISIONE-IMP-ACC'
AND NOT EXISTS (
  SELECT 1
  FROM siac_d_file_tipo z
  WHERE z.file_tipo_code = 'PREVISIONE-IMP-ACC'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('UPLOAD_MULTIPLI_PREVISIONE_CHIUDERE', 'permetti upload multipli nella previsione a chiudere')) AS tmp(code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('FALSE', 'codice TRUE per abilitare FALSE per disabilitare', 'UPLOAD_MULTIPLI_PREVISIONE_CHIUDERE')) AS tmp(code, descr, tipo)
WHERE dgt.gestione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
	AND dgl.gestione_livello_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_r_gestione_ente (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dgl.gestione_livello_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
JOIN siac_d_gestione_tipo dgt on dgt.gestione_tipo_id  = dgl.gestione_tipo_id 
--CROSS JOIN (VALUES ('TRUE')) AS tmp(livello)
where dgt.gestione_tipo_code  = 'UPLOAD_MULTIPLI_PREVISIONE_CHIUDERE'
and dgl.gestione_livello_code ='FALSE'
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
	AND rge.data_cancellazione IS NULL
);
