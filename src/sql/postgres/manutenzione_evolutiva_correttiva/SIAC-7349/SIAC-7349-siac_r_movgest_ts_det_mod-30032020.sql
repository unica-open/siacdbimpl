/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Table: siac.siac_r_movgest_ts_det_mod

-- DROP TABLE siac.siac_r_movgest_ts_det_mod;



CREATE TABLE IF NOT EXISTS siac.siac_r_movgest_ts_det_mod
(
	
	movgest_ts_det_mod_r_id SERIAL,
	movgest_ts_det_mod_entrata_id integer NOT NULL,
	movgest_ts_det_mod_spesa_id integer NOT NULL,
	movgest_ts_det_mod_importo numeric,
	movgest_ts_det_mod_impo_residuo numeric,
    validita_inizio timestamp without time zone NOT NULL,
    validita_fine timestamp without time zone,
    ente_proprietario_id integer NOT NULL,
    data_creazione timestamp without time zone NOT NULL DEFAULT now(),
    data_modifica timestamp without time zone NOT NULL DEFAULT now(),
    data_cancellazione timestamp without time zone,
    login_operazione character varying(200)  NOT NULL,
    CONSTRAINT pk_r_movgest_ts_det_mod PRIMARY KEY (movgest_ts_det_mod_r_id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;
COMMENT ON TABLE siac.siac_r_movgest_ts_det_mod IS 'Associazione delle modifiche tra impegni e accertamenti';

ALTER TABLE siac.siac_r_movgest_ts_det_mod
    OWNER to siac;
	
SELECT * FROM  fnc_dba_add_fk_constraint('siac_r_movgest_ts_det_mod', 'siac_t_ente_proprietario_siac_r_movgest_ts_det_mod', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');	
SELECT * FROM  fnc_dba_add_fk_constraint('siac_r_movgest_ts_det_mod', 'siac_t_movgest_ts_det_mod_siac_r_movgest_ts_det_mod_entrata', 'movgest_ts_det_mod_entrata_id', 'siac_t_movgest_ts_det_mod', 'movgest_ts_det_mod_id');	
SELECT * FROM  fnc_dba_add_fk_constraint('siac_r_movgest_ts_det_mod', 'siac_t_movgest_ts_det_mod_siac_r_movgest_ts_det_mod_spesa', 'movgest_ts_det_mod_spesa_id', 'siac_t_movgest_ts_det_mod', 'movgest_ts_det_mod_id');	
	
	
SELECT * FROM fnc_dba_create_index('siac_r_movgest_ts_det_mod', 'idx_siac_r_movgest_ts_det_mod_1','movgest_ts_det_mod_entrata_id, movgest_ts_det_mod_spesa_id,validita_inizio, ente_proprietario_id', 'data_cancellazione is null', false);
SELECT * FROM fnc_dba_create_index('siac_r_movgest_ts_det_mod', 'siac_r_movgest_ts_det_mod_imp_fk_ente_proprietario_id_idx','ente_proprietario_id', null, false);
SELECT * FROM fnc_dba_create_index('siac_r_movgest_ts_det_mod', 'siac_r_movgest_ts_det_mod_imp_mod_entrata_id_idx','movgest_ts_det_mod_entrata_id', null, false);
SELECT * FROM fnc_dba_create_index('siac_r_movgest_ts_det_mod', 'siac_r_movgest_ts_det_mod_imp_mod_spesa_id_idx','movgest_ts_det_mod_spesa_id', null, false);
 
 
 