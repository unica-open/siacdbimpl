/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- DDL
drop table if exists siac_t_bil_elem_det_var_comp;
drop table if exists siac_t_bil_elem_det_comp;
drop table if exists siac_d_bil_elem_det_comp_tipo;

drop table if exists siac_d_bil_elem_det_comp_tipo_def;
drop table if exists siac_d_bil_elem_det_comp_tipo_fase;
drop table if exists siac_d_bil_elem_det_comp_tipo_fonte;
drop table if exists siac_d_bil_elem_det_comp_tipo_ambito;
drop table if exists siac_d_bil_elem_det_comp_sotto_tipo;
drop table if exists siac_d_bil_elem_det_comp_macro_tipo;
drop table if exists siac_d_bil_elem_det_comp_tipo_stato;

CREATE TABLE siac.siac_d_bil_elem_det_comp_tipo_stato
(
    elem_det_comp_tipo_stato_id SERIAL,
    elem_det_comp_tipo_stato_code VARCHAR(200) NOT NULL,
    elem_det_comp_tipo_stato_desc VARCHAR(500) NOT NULL,
    validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
    validita_fine TIMESTAMP,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_stato PRIMARY KEY (elem_det_comp_tipo_stato_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_stato IS 'Stato dell''anagrafica componente (VALIDO, ANNULLATO)';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_stato.elem_det_comp_tipo_stato_code IS 'V, A';

CREATE INDEX siac_d_bil_elem_det_comp_tipo_stato_fk_ente_proprietario_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo_stato USING BTREE
 ( ente_proprietario_id );

CREATE UNIQUE INDEX siac_d_bil_elem_det_comp_tipo_stato_idx_1
 ON siac.siac_d_bil_elem_det_comp_tipo_stato
 ( elem_det_comp_tipo_stato_code, validita_inizio, ente_proprietario_id )
 where (data_cancellazione is null);

CREATE TABLE siac.siac_d_bil_elem_det_comp_tipo_def
(
                elem_det_comp_tipo_def_id SERIAL,
                elem_det_comp_tipo_def_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_def_desc VARCHAR(500) NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_def PRIMARY KEY (elem_det_comp_tipo_def_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_def IS 'Componente proposta come default su capitoli (Solo Previsione, Solo Gestione, Si, No)';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_def.elem_det_comp_tipo_def_code IS 'Solo Gestione, Solo Previsione, Si, No';


CREATE INDEX siac_d_bil_elem_det_comp_tipo_def_fk_ente_proprietario_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo_def USING BTREE
 ( ente_proprietario_id );

CREATE UNIQUE INDEX siac_d_bil_elem_det_comp_tipo_def_idx_1
 ON siac.siac_d_bil_elem_det_comp_tipo_def
 ( elem_det_comp_tipo_def_code, validita_inizio, ente_proprietario_id )
 where (data_cancellazione is null);



CREATE TABLE siac.siac_d_bil_elem_det_comp_macro_tipo (
                elem_det_comp_macro_tipo_id SERIAL,
                elem_det_comp_macro_tipo_code VARCHAR(200) NOT NULL,
                elem_det_comp_macro_tipo_desc VARCHAR(500) NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_macro_tipo PRIMARY KEY (elem_det_comp_macro_tipo_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_macro_tipo IS 'Macrotipo componente (Fresco,FPV,Avanzo)';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_macro_tipo.elem_det_comp_macro_tipo_code IS 'Fresco, FPV, Avanzo';


CREATE INDEX siac_d_bil_elem_det_comp_macro_tipo_code_idx_1
 ON siac.siac_d_bil_elem_det_comp_macro_tipo USING BTREE
 ( elem_det_comp_macro_tipo_code, validita_inizio, ente_proprietario_id )
 where (data_cancellazione is null);

CREATE INDEX siac_d_bil_elem_det_comp_macro_tipo_fk_ente_proprietario_idx
 ON siac.siac_d_bil_elem_det_comp_macro_tipo USING BTREE
 ( ente_proprietario_id );

CREATE TABLE siac.siac_d_bil_elem_det_comp_sotto_tipo (
                elem_det_comp_sotto_tipo_id SERIAL,
                elem_det_comp_sotto_tipo_code VARCHAR(200) NOT NULL,
                elem_det_comp_sotto_tipo_desc VARCHAR(500) NOT NULL,
				elem_det_comp_macro_tipo_id INTEGER NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_sotto_tipo PRIMARY KEY (elem_det_comp_sotto_tipo_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_sotto_tipo IS 'Sottotipo componente ( Programmato, Cumulato, Applicato )';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_sotto_tipo.elem_det_comp_sotto_tipo_code IS 'Programmato, Cumulato, Da definire';


CREATE UNIQUE INDEX siac_d_bil_elem_det_comp_sotto_tipo_code_idx_1
 ON siac.siac_d_bil_elem_det_comp_sotto_tipo
 ( elem_det_comp_sotto_tipo_code, elem_det_comp_macro_tipo_id,validita_inizio, ente_proprietario_id )
 where (data_cancellazione is null);

CREATE INDEX siac_d_bil_elem_det_comp_sotto_tipo_fk_macro_id_idx
 ON siac.siac_d_bil_elem_det_comp_sotto_tipo USING BTREE
 ( elem_det_comp_macro_tipo_id );

CREATE INDEX siac_d_bil_elem_det_comp_sotto_tipo_fk_ente_proprietario_id_idx
 ON siac.siac_d_bil_elem_det_comp_sotto_tipo USING BTREE
 ( ente_proprietario_id );


 CREATE TABLE siac.siac_d_bil_elem_det_comp_tipo_ambito (
                elem_det_comp_tipo_ambito_id SERIAL,
                elem_det_comp_tipo_ambito_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_ambito_desc VARCHAR(500) NOT NULL,
				elem_det_comp_macro_tipo_id INTEGER NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_ambito PRIMARY KEY (elem_det_comp_tipo_ambito_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_ambito IS 'Ambito componente';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_ambito.elem_det_comp_tipo_ambito_code IS 'Autonomo, Vincolato,Da definire';


CREATE INDEX siac_d_bil_elem_det_comp_tipo_ambito_fk_ente_proprietario_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo_ambito USING BTREE
 ( ente_proprietario_id );

CREATE UNIQUE INDEX siac_d_bil_elem_det_comp_tipo_ambito_idx_1
 ON siac.siac_d_bil_elem_det_comp_tipo_ambito
 ( elem_det_comp_tipo_ambito_code,elem_det_comp_macro_tipo_id, validita_inizio, ente_proprietario_id )
 where (data_cancellazione is null);


 CREATE INDEX siac_d_bil_elem_det_comp_tipo_ambito_fk_macro_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo_ambito USING BTREE
 ( elem_det_comp_macro_tipo_id );


 CREATE TABLE siac.siac_d_bil_elem_det_comp_tipo_fase (
                elem_det_comp_tipo_fase_id SERIAL,
                elem_det_comp_tipo_fase_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_fase_desc VARCHAR(500) NOT NULL,
				elem_det_comp_macro_tipo_id INTEGER NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_fase PRIMARY KEY (elem_det_comp_tipo_fase_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_fase IS 'Componente utilizzabile in fase Gestione, Previsione , ROR';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_fase.elem_det_comp_tipo_fase_code IS 'Gestione, Previsione, ROR';


CREATE INDEX siac_d_bil_elem_det_comp_tipo_fase_fk_ente_proprietario_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo_fase USING BTREE
 ( ente_proprietario_id );

CREATE UNIQUE INDEX siac_d_bil_elem_det_comp_tipo_fase_idx_1
 ON siac.siac_d_bil_elem_det_comp_tipo_fase
 ( elem_det_comp_tipo_fase_code, elem_det_comp_macro_tipo_id, validita_inizio, ente_proprietario_id )
 where (data_cancellazione is null);

 CREATE INDEX siac_d_bil_elem_det_comp_tipo_fase_fk_macro_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo_fase USING BTREE
 ( elem_det_comp_macro_tipo_id );


CREATE TABLE siac.siac_d_bil_elem_det_comp_tipo_fonte (
                elem_det_comp_tipo_fonte_id SERIAL,
                elem_det_comp_tipo_fonte_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_fonte_desc VARCHAR(500) NOT NULL,
				elem_det_comp_macro_tipo_id INTEGER NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_fonte PRIMARY KEY (elem_det_comp_tipo_fonte_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_fonte IS 'Fonte di finanziamento componente';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_fonte.elem_det_comp_tipo_fonte_code IS 'Fresco,Avanzo';


CREATE INDEX siac_d_bil_elem_det_comp_tipo_fonte_fk_ente_proprietario_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo_fonte
 ( ente_proprietario_id );

CREATE UNIQUE INDEX siac_d_bil_elem_det_comp_tipo_fonte_idx_1
 ON siac.siac_d_bil_elem_det_comp_tipo_fonte
 ( elem_det_comp_tipo_fonte_code, elem_det_comp_macro_tipo_id,validita_inizio, ente_proprietario_id )
 where (data_cancellazione is null);

 CREATE INDEX siac_d_bil_elem_det_comp_tipo_fonte_fk_macro_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo_fonte
 ( elem_det_comp_macro_tipo_id );

CREATE TABLE siac.siac_d_bil_elem_det_comp_tipo (
                elem_det_comp_tipo_id SERIAL,
                elem_det_comp_tipo_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_desc VARCHAR(500) NOT NULL,
                elem_det_comp_macro_tipo_id INTEGER,
                elem_det_comp_sotto_tipo_id INTEGER,
                elem_det_comp_tipo_ambito_id INTEGER,
                elem_det_comp_tipo_fonte_id INTEGER,
                elem_det_comp_tipo_fase_id INTEGER,
                elem_det_comp_tipo_def_id INTEGER,
                elem_det_comp_tipo_gest_aut BOOLEAN DEFAULT 'N' NOT NULL,
                elem_det_comp_tipo_stato_id INTEGER NOT NULL,
                periodo_id INTEGER,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo PRIMARY KEY (elem_det_comp_tipo_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo IS 'Anagrafica tipologie componenti stanziamento';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo.elem_det_comp_tipo_gest_aut IS 'Tipo di gestione della componente dello stanziamento manuale o solo automatica [N-manuale,S-automatica]';


CREATE INDEX siac_d_bil_elem_det_comp_tipo_fk_fonte_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo USING BTREE
 ( elem_det_comp_tipo_fonte_id );

CREATE INDEX siac_d_bil_elem_det_comp_tipo_fk_ente_proprietario_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo USING BTREE
 ( ente_proprietario_id );

CREATE INDEX siac_d_bil_elem_det_comp_tipo_fk_macro_tipo_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo USING BTREE
 ( elem_det_comp_macro_tipo_id );

CREATE INDEX siac_d_bil_elem_det_comp_tipo_fk_sotto_tipo_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo USING BTREE
 ( elem_det_comp_sotto_tipo_id );

CREATE INDEX siac_d_bil_elem_det_comp_tipo_fk_ambito_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo USING BTREE
 ( elem_det_comp_tipo_ambito_id );

CREATE INDEX siac_d_bil_elem_det_comp_tipo_fk_fase_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo USING BTREE
 ( elem_det_comp_tipo_fase_id );

CREATE INDEX siac_d_bil_elem_det_comp_tipo_fk_def_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo USING BTREE
 ( elem_det_comp_tipo_def_id );

CREATE INDEX siac_d_bil_elem_det_comp_tipo_fk_stato_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo USING BTREE
 ( elem_det_comp_tipo_stato_id );

CREATE INDEX siac_d_bil_elem_det_comp_tipo_fk_periodo_id_idx
 ON siac.siac_d_bil_elem_det_comp_tipo USING BTREE
 ( periodo_id );

CREATE UNIQUE INDEX siac_d_bil_elem_det_comp_tipo_idx_1
 ON siac.siac_d_bil_elem_det_comp_tipo
 ( elem_det_comp_tipo_code, elem_det_comp_macro_tipo_id, ente_proprietario_id, validita_inizio )
 where (data_cancellazione is null);



CREATE TABLE siac.siac_t_bil_elem_det_comp (
                elem_det_comp_id SERIAL,
                elem_det_id INTEGER NOT NULL,
                elem_det_comp_tipo_id INTEGER NOT NULL,
                elem_det_importo NUMERIC,
                validita_inizio TIMESTAMP NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_t_bil_elem_det_comp PRIMARY KEY (elem_det_comp_id)
);
COMMENT ON TABLE siac.siac_t_bil_elem_det_comp IS 'Componente Importi Stanziamento Capitolo';
COMMENT ON COLUMN siac.siac_t_bil_elem_det_comp.elem_det_importo IS 'Importo componente stanziamento capitolo';


CREATE INDEX siac_t_bil_elem_det_comp_fk_ente_proprietario_id_idx
 ON siac.siac_t_bil_elem_det_comp USING BTREE
 ( ente_proprietario_id );

CREATE INDEX siac_t_bil_elem_det_comp_fk_elem_det_id_idx
 ON siac.siac_t_bil_elem_det_comp USING BTREE
 ( elem_det_id );

CREATE INDEX siac_t_bil_elem_det_comp_fk_elem_det_com_tipo_id_idx
 ON siac.siac_t_bil_elem_det_comp USING BTREE
 ( elem_det_comp_tipo_id );

CREATE UNIQUE INDEX siac_t_bil_elem_det_comp_elem_det_idx_1
 ON siac.siac_t_bil_elem_det_comp USING BTREE
 ( elem_det_id, elem_det_comp_tipo_id, validita_inizio, ente_proprietario_id )
 where (data_cancellazione is null);

CREATE TABLE siac.siac_t_bil_elem_det_var_comp (
                elem_det_var_comp_id SERIAL,
                elem_det_var_id INTEGER NOT NULL,
                elem_det_comp_id INTEGER NOT NULL,
                elem_det_importo NUMERIC,
                elem_det_flag CHARACTER VARYING(1),
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_t_bil_elem_det_var_comp PRIMARY KEY (elem_det_var_comp_id)
);
COMMENT ON TABLE siac.siac_t_bil_elem_det_var_comp IS 'Dettaglio di variazione della componente Importi Stanziamento Capitolo';
COMMENT ON COLUMN siac.siac_t_bil_elem_det_var_comp.elem_det_importo IS 'Importo di varaizione componente stanziamento capitolo';
COMMENT ON COLUMN siac.siac_t_bil_elem_det_var_comp.elem_det_flag IS 'Flag cancellazione (A) o inserimento (N) variazione componente stanziamento capitolo';


CREATE INDEX siac_t_bil_elem_det_var_comp_fk_det_var_id_idx
 ON siac.siac_t_bil_elem_det_var_comp USING BTREE
 ( elem_det_var_id );

CREATE INDEX siac_t_bil_elem_det_var_comp_fk_det_comp_id_idx
 ON siac.siac_t_bil_elem_det_var_comp USING BTREE
 ( elem_det_comp_id );

CREATE INDEX siac_t_bil_elem_det_var_comp_fk_ente_proprietario_id_idx
 ON siac.siac_t_bil_elem_det_var_comp USING BTREE
 ( ente_proprietario_id );

CREATE INDEX siac_t_bil_elem_det_var_comp_idx_1
 ON siac.siac_t_bil_elem_det_var_comp USING BTREE
 ( elem_det_var_id, elem_det_comp_id, ente_proprietario_id, validita_inizio )
 where (data_cancellazione is null);


ALTER TABLE siac.siac_t_bil_elem_det_var_comp ADD CONSTRAINT siac_t_ente_proprietario_siac_t_bil_elem_det_var_comp_fk
FOREIGN KEY (ente_proprietario_id)
REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_t_bil_elem_det_comp ADD CONSTRAINT siac_t_ente_proprietario_siac_t_bil_elem_det_comp_fk
FOREIGN KEY (ente_proprietario_id)
REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo_def ADD CONSTRAINT siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_def_fk
FOREIGN KEY (ente_proprietario_id)
REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo ADD CONSTRAINT siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_fk
FOREIGN KEY (ente_proprietario_id)
REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo_ambito ADD CONSTRAINT siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_ambit175
FOREIGN KEY (ente_proprietario_id)
REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo_fonte ADD CONSTRAINT siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_fonte_fk
FOREIGN KEY (ente_proprietario_id)
REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo_fase ADD CONSTRAINT siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_fase_fk
FOREIGN KEY (ente_proprietario_id)
REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_sotto_tipo ADD CONSTRAINT siac_t_ente_proprietario_siac_d_bil_elem_det_comp_sotto_tipo_fk
FOREIGN KEY (ente_proprietario_id)
REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_macro_tipo ADD CONSTRAINT siac_t_ente_proprietario_siac_d_bil_elem_det_comp_macro_tipo_fk
FOREIGN KEY (ente_proprietario_id)
REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo ADD CONSTRAINT siac_d_bil_elem_det_comp_tipo_def_siac_d_bil_elem_det_comp_t541
FOREIGN KEY (elem_det_comp_tipo_def_id)
REFERENCES siac.siac_d_bil_elem_det_comp_tipo_def (elem_det_comp_tipo_def_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo ADD CONSTRAINT siac_d_bil_elem_det_comp_tipo_fase_siac_d_bil_elem_det_comp_999
FOREIGN KEY (elem_det_comp_tipo_fase_id)
REFERENCES siac.siac_d_bil_elem_det_comp_tipo_fase (elem_det_comp_tipo_fase_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo ADD CONSTRAINT siac_d_bil_elem_det_comp_tipo_fonte_siac_d_bil_elem_det_comp764
FOREIGN KEY (elem_det_comp_tipo_fonte_id)
REFERENCES siac.siac_d_bil_elem_det_comp_tipo_fonte (elem_det_comp_tipo_fonte_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo ADD CONSTRAINT siac_d_bil_elem_det_comp_tipo_stato_siac_d_bil_elem_det_comp_tipo_fk
FOREIGN KEY (elem_det_comp_tipo_stato_id)
REFERENCES siac.siac_d_bil_elem_det_comp_tipo_stato (elem_det_comp_tipo_stato_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;



ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo ADD CONSTRAINT siac_d_bil_elem_det_comp_tipo_ambito_siac_d_bil_elem_det_com286
FOREIGN KEY (elem_det_comp_tipo_ambito_id)
REFERENCES siac.siac_d_bil_elem_det_comp_tipo_ambito (elem_det_comp_tipo_ambito_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo ADD CONSTRAINT siac_d_bil_elem_det_comp_sotto_tipo_siac_d_bil_elem_det_comp415
FOREIGN KEY (elem_det_comp_sotto_tipo_id)
REFERENCES siac.siac_d_bil_elem_det_comp_sotto_tipo (elem_det_comp_sotto_tipo_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo ADD CONSTRAINT siac_d_bil_det_comp_macro_tipo_siac_d_bil_elem_det_comp_tipo_fk
FOREIGN KEY (elem_det_comp_macro_tipo_id)
REFERENCES siac.siac_d_bil_elem_det_comp_macro_tipo (elem_det_comp_macro_tipo_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;




ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo ADD CONSTRAINT siac_t_periodo_siac_d_bil_elem_det_comp_tipo_fk
FOREIGN KEY (periodo_id)
REFERENCES siac.siac_t_periodo (periodo_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_t_bil_elem_det_comp ADD CONSTRAINT siac_d_bil_elem_det_comp_siac_t_bil_elem_det_comp_fk
FOREIGN KEY (elem_det_comp_tipo_id)
REFERENCES siac.siac_d_bil_elem_det_comp_tipo (elem_det_comp_tipo_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;



ALTER TABLE siac.siac_t_bil_elem_det_comp ADD CONSTRAINT siac_t_bil_elem_det_siac_t_bil_elem_det_comp_fk
FOREIGN KEY (elem_det_id)
REFERENCES siac.siac_t_bil_elem_det (elem_det_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;



ALTER TABLE siac.siac_t_bil_elem_det_var_comp ADD CONSTRAINT siac_t_bil_elem_det_var_siac_t_bil_elem_det_var_comp_fk
FOREIGN KEY (elem_det_var_id)
REFERENCES siac.siac_t_bil_elem_det_var (elem_det_var_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE siac.siac_t_bil_elem_det_var_comp ADD CONSTRAINT siac_t_bil_elem_det_comp_siac_t_bil_elem_det_var_comp_fk
FOREIGN KEY (elem_det_comp_id)
REFERENCES siac.siac_t_bil_elem_det_comp (elem_det_comp_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

-- /DDL

-- AZIONI
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
select tmp.az_code, tmp.az_desc, ta.azione_tipo_id, ga.gruppo_azioni_id, tmp.az_url, to_timestamp('01/01/2017','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
from siac_d_azione_tipo ta
join siac_t_ente_proprietario e on (ta.ente_proprietario_id = e.ente_proprietario_id)
join siac_d_gruppo_azioni ga on (ga.ente_proprietario_id = e.ente_proprietario_id)
join (values
	('OP-GESC088-ricercaAnagraficaComponenti', 'Ricerca Anagrafica Componenti', 'ATTIVITA_SINGOLA', 'BIL_ALTRO', '/../siacbilapp/azioneRichiesta.do'),
	('OP-GESC089-inserisiciAnagraficaComponenti', 'Inserisci Anagrafica Componenti', 'ATTIVITA_SINGOLA', 'BIL_ALTRO', '/../siacbilapp/azioneRichiesta.do')
) as tmp (az_code, az_desc, az_tipo, az_gruppo, az_url) on (tmp.az_tipo = ta.azione_tipo_code and tmp.az_gruppo = ga.gruppo_azioni_code)
where not exists (
	select 1
	from siac_t_azione z
	where z.azione_tipo_id = ta.azione_tipo_id
	and z.azione_code = tmp.az_code
);

-- /AZIONI

-- DML
-- macro componente
-- Fresco, Avanzo, FPV, Da attribuire
insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Fresco',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='01'
and   tipo.elem_det_comp_macro_tipo_desc='Fresco'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'FPV',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='02'
and   tipo.elem_det_comp_macro_tipo_desc='FPV'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Avanzo',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='03'
and   tipo.elem_det_comp_macro_tipo_desc='Avanzo'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '04',
    'Da attribuire',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='04'
and   tipo.elem_det_comp_macro_tipo_desc='Da attribuire'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- sotto componente FPV
-- Programmato non impegnato
-- Cumulato
-- Applicato
insert into siac_d_bil_elem_det_comp_sotto_tipo
(
	elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
	elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Programmato non impegnato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_sotto_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_sotto_tipo_code='01'
and   tipo.elem_det_comp_sotto_tipo_desc='Programmato non impegnato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_sotto_tipo
(
	elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
	elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'Cumulato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_sotto_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_sotto_tipo_code='02'
and   tipo.elem_det_comp_sotto_tipo_desc='Cumulato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_sotto_tipo
(
	elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
	elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Applicato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_sotto_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_sotto_tipo_code='03'
and   tipo.elem_det_comp_sotto_tipo_desc='Applicato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- ambito componente Fresco
-- Autonomo
-- Vincolato
-- Da definire
insert into siac_d_bil_elem_det_comp_tipo_ambito
(
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Autonomo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='01'
and   macro.elem_det_comp_macro_tipo_desc='Fresco'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_ambito tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_ambito_code='01'
and   tipo.elem_det_comp_tipo_ambito_desc='Autonomo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_ambito
(
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'Vincolato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='01'
and   macro.elem_det_comp_macro_tipo_desc='Fresco'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_ambito tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_ambito_code='02'
and   tipo.elem_det_comp_tipo_ambito_desc='Vincolato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_ambito
(
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Da definire',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='01'
and   macro.elem_det_comp_macro_tipo_desc='Fresco'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_ambito tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_ambito_code='03'
and   tipo.elem_det_comp_tipo_ambito_desc='Da definire'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- Fonte componente
-- FPV
--  Fresco / Avanzo
-- Avanzo
--  Avanzo/Reiscrizione Perenti
insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '01',
    'Fresco',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='01'
and   tipo.elem_det_comp_tipo_fonte_desc='Fresco'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '02',
    'Avanzo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='02'
and   tipo.elem_det_comp_tipo_fonte_desc='Avanzo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '03',
    'Avanzo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='03'
and   macro.elem_det_comp_macro_tipo_desc='Avanzo'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='03'
and   tipo.elem_det_comp_tipo_fonte_desc='Avanzo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '04',
    'Reiscrizione Perenti',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='03'
and   macro.elem_det_comp_macro_tipo_desc='Avanzo'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='04'
and   tipo.elem_det_comp_tipo_fonte_desc='Reiscrizione Perenti'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- Momento per FPV
-- Gestione/ROR/ Bilancio previsione
insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Bilancio previsione',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='01'
and   tipo.elem_det_comp_tipo_fase_desc='Bilancio previsione'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'Gestione',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='02'
and   tipo.elem_det_comp_tipo_fase_desc='Gestione'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'ROR effettivo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='03'
and   tipo.elem_det_comp_tipo_fase_desc='ROR effettivo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '04',
    'ROR previsione',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='04'
and   tipo.elem_det_comp_tipo_fase_desc='ROR previsione'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

--- Default
insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Si',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='01'
and   tipo.elem_det_comp_tipo_def_desc='Si'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'No',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='02'
and   tipo.elem_det_comp_tipo_def_desc='No'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Solo Previsione',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='03'
and   tipo.elem_det_comp_tipo_def_desc='Solo Previsione'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '04',
    'Solo Gestione',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='04'
and   tipo.elem_det_comp_tipo_def_desc='Solo Gestione'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_stato (elem_det_comp_tipo_stato_code, elem_det_comp_tipo_stato_desc, validita_inizio, login_operazione, ente_proprietario_id)
select tmp.code, tmp.descr, now(), 'SIAC-6881', ente.ente_proprietario_id
from siac_t_ente_proprietario ente
cross join (values
    ('V', 'Valido'),
    ('A', 'Annullato')
) as tmp(code, descr)
where not exists (
    select 1
    from siac_d_bil_elem_det_comp_tipo_stato stato
    where stato.ente_proprietario_id = ente.ente_proprietario_id
    and stato.elem_det_comp_tipo_stato_code = tmp.code
    and stato.data_cancellazione is null
    and stato.validita_fine is null
);
-- /DML