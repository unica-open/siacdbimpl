/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


select * from fnc_dba_add_column_params('siac_t_movgest_ts_det_mod','mtdm_aggiudicazione_senza_sog','boolean');

CREATE TABLE IF NOT EXISTS siac_d_modifica_tipo_applicazione (
  mod_tipo_appl_id SERIAL,
  mod_tipo_appl_code VARCHAR(200) NOT NULL,
  mod_tipo_appl_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_modifica_tipo_applicazione PRIMARY KEY(mod_tipo_appl_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_modifica_tipo_applicazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


select fnc_dba_create_index(
'siac_d_modifica_tipo_applicazione'::text,
  'idx_siac_d_modifica_tipo_appl_1'::text,
  'mod_tipo_appl_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);

select fnc_dba_create_index(
'siac_d_modifica_tipo_applicazione'::text,
  'siac_d_modifica_tipo_applicazione_fk_ente_proprietario_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);

insert into siac_d_modifica_tipo_applicazione
(mod_tipo_appl_code,mod_tipo_appl_desc  ,validita_inizio, ente_proprietario_id  ,login_operazione)
select tmp.code, tmp.descr, to_timestamp('01/01/2020','dd/mm/yyyy'),a.ente_proprietario_id,'SIAC-7838'
from siac.siac_t_ente_proprietario a
CROSS JOIN (VALUES ('GEN'  ,'Generico'), ('ROR'  ,'ROR'), ('AGG-RID'  ,'Aggiudicazione-Riduzione'))as tmp (code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_modifica_tipo_applicazione ta
	WHERE ta.ente_proprietario_id = a.ente_proprietario_id
	AND ta.mod_tipo_appl_code = tmp.code
	AND ta.data_cancellazione IS NULL
);
  
  
  
CREATE TABLE IF NOT EXISTS siac_r_modifica_tipo_applicazione (
  mod_tipo_r_tipo_appl_id SERIAL,
  mod_tipo_id INTEGER NOT NULL,
  mod_tipo_appl_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_modifica_tipo_applicazione PRIMARY KEY(mod_tipo_r_tipo_appl_id),
  CONSTRAINT siac_d_modifica_tipo_tipo_applicazione_siac_r_modifica_tipo_applicazione FOREIGN KEY (mod_tipo_appl_id)
    REFERENCES siac.siac_d_modifica_tipo_applicazione(mod_tipo_appl_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_modifica_tipo_applicazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_modifica_tipo_tipo_applicazione_siac_r_modifica_tipo_applicazione FOREIGN KEY (mod_tipo_id)
    REFERENCES siac.siac_d_modifica_tipo(mod_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

select fnc_dba_create_index(
'siac_r_modifica_tipo_applicazione'::text,
  'idx_siac_r_modifica_tipo_applicazione_1'::text,
  'mod_tipo_id, mod_tipo_appl_id, validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);

select fnc_dba_create_index(
'siac_r_modifica_tipo_applicazione'::text,
  'siac_r_modifica_tipo_applicazione_fk_modifica_tipo_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);

insert into  siac_r_modifica_tipo_applicazione
(mod_tipo_id,mod_tipo_appl_id  ,validita_inizio, ente_proprietario_id  ,login_operazione)
select tipo.mod_tipo_id, applicazione.mod_tipo_appl_id, to_timestamp('01/01/2020','dd/mm/yyyy'), ente.ente_proprietario_id, 'SIAC-7838' 
from siac_t_ente_proprietario ente 
join siac_d_modifica_tipo tipo on tipo.ente_proprietario_id  = ente.ente_proprietario_id 
join siac_d_modifica_tipo_applicazione applicazione on (applicazione.ente_proprietario_id  = ente.ente_proprietario_id  and applicazione.ente_proprietario_id = ente.ente_proprietario_id)
where tipo.data_cancellazione  is null and applicazione .data_cancellazione  is null
and tipo.mod_tipo_code not like 'AGG' and applicazione.mod_tipo_appl_code='GEN'
and not exists(
	select 1 from siac_r_modifica_tipo_applicazione r_app
	where r_app.ente_proprietario_id = ente.ente_proprietario_id 
	and r_app.mod_tipo_id  = tipo.mod_tipo_id 
	and r_app.mod_tipo_appl_id  = applicazione.mod_tipo_appl_id 
	and r_app.data_cancellazione is null
);


insert into  siac_r_modifica_tipo_applicazione
(mod_tipo_id,mod_tipo_appl_id  ,validita_inizio, ente_proprietario_id  ,login_operazione)
select tipo.mod_tipo_id, applicazione.mod_tipo_appl_id, to_timestamp('01/01/2020','dd/mm/yyyy'), ente.ente_proprietario_id, 'SIAC-7838' 
from siac_t_ente_proprietario ente 
join siac_d_modifica_tipo tipo on tipo.ente_proprietario_id  = ente.ente_proprietario_id 
join siac_d_modifica_tipo_applicazione applicazione on (applicazione.ente_proprietario_id  = ente.ente_proprietario_id  and applicazione.ente_proprietario_id = ente.ente_proprietario_id)
where tipo.data_cancellazione  is null and applicazione .data_cancellazione  is null
and tipo.mod_tipo_code not like 'AGG' and applicazione.mod_tipo_appl_code='ROR'
and (upper(mod_tipo_desc) like 'ROR%' or upper(mod_tipo_desc) like 'ECO%')
and not exists(
	select 1 from siac_r_modifica_tipo_applicazione r_app
	where r_app.ente_proprietario_id = ente.ente_proprietario_id 
	and r_app.mod_tipo_id  = tipo.mod_tipo_id 
	and r_app.mod_tipo_appl_id  = applicazione.mod_tipo_appl_id 
	and r_app.data_cancellazione is null
);



insert into  siac_r_modifica_tipo_applicazione
(mod_tipo_id,mod_tipo_appl_id  ,validita_inizio, ente_proprietario_id  ,login_operazione)
select tipo.mod_tipo_id, applicazione.mod_tipo_appl_id, to_timestamp('01/01/2020','dd/mm/yyyy'), ente.ente_proprietario_id, 'SIAC-7838' 
from siac_t_ente_proprietario ente 
join siac_d_modifica_tipo tipo on tipo.ente_proprietario_id  = ente.ente_proprietario_id 
join siac_d_modifica_tipo_applicazione applicazione on (applicazione.ente_proprietario_id  = ente.ente_proprietario_id  and applicazione.ente_proprietario_id = ente.ente_proprietario_id)
where tipo.data_cancellazione  is null and applicazione .data_cancellazione  is null
and tipo.mod_tipo_code='AGG' and applicazione.mod_tipo_appl_code='AGG-RID'
and not exists(
	select 1 from siac_r_modifica_tipo_applicazione r_app
	where r_app.ente_proprietario_id = ente.ente_proprietario_id 
	and r_app.mod_tipo_id  = tipo.mod_tipo_id 
	and r_app.mod_tipo_appl_id  = applicazione.mod_tipo_appl_id 
	and r_app.data_cancellazione is null
);
  