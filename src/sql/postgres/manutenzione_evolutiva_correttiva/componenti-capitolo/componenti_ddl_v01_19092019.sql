/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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