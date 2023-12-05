/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-------------------
------- CODIFICHE:
-------------------
---TIPO CALCOLO CATEGORIA CESPITI
CREATE TABLE IF NOT EXISTS siac_d_cespiti_categoria_calcolo_tipo (
	cescat_calcolo_tipo_id SERIAL,
	cescat_calcolo_tipo_code VARCHAR(200) NOT NULL,
	cescat_calcolo_tipo_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_cespiti_categoria_calcolo_tipo PRIMARY KEY(cescat_calcolo_tipo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_cespiti_categoria_calcolo_tipo FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);
CREATE UNIQUE INDEX idx_siac_d_cespiti_categoria_calcolo_tipo_1 ON siac_d_cespiti_categoria_calcolo_tipo
	USING btree (cescat_calcolo_tipo_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);
CREATE INDEX siac_d_cespiti_categoria_calcolo_tipo_fk_ente_proprietario_id_idx ON siac_d_cespiti_categoria_calcolo_tipo
	USING btree (ente_proprietario_id);

--- TIPO BENE
CREATE TABLE IF NOT EXISTS siac_d_cespiti_bene_tipo (
	ces_bene_tipo_id SERIAL,
	ces_bene_tipo_code VARCHAR(200) NOT NULL,
	ces_bene_tipo_desc VARCHAR(500) NOT NULL,
	testo_scrittura_ammortamento VARCHAR(500),
	evento_ammortamento_id INTEGER,        --Evento di ammortamento
	evento_ammortamento_code VARCHAR(200), --Evento di ammortamento
	evento_ammortamento_desc VARCHAR(500), --Evento di ammortamento
	
	causale_ep_ammortamento_id INTEGER,        --causale di ammortamento
	causale_ep_ammortamento_code VARCHAR(200), --causale di ammortamento
	causale_ep_ammortamento_desc VARCHAR(500), --causale di ammortamento
	
	evento_incremento_id INTEGER,        --Evento di incremento valore
	evento_incremento_code VARCHAR(200), --Evento di incremento valore
	evento_incremento_desc VARCHAR(500), --Evento di incremento valore
	
	causale_ep_incremento_id INTEGER,        --causale di incremento valore
	causale_ep_incremento_code VARCHAR(200), --causale di incremento valore
	causale_ep_incremento_desc VARCHAR(500), --causale di incremento valore
	
	evento_decremento_id INTEGER,        --Evento di decremento valore
	evento_decremento_code VARCHAR(200), --Evento di decremento valore
	evento_decremento_desc VARCHAR(500), --Evento di decremento valore
	
	causale_ep_decremento_id INTEGER,        --causale di decremento valore
	causale_ep_decremento_code VARCHAR(200), --causale di decremento valore
	causale_ep_decremento_desc VARCHAR(500), --causale di decremento valore
	
	pdce_conto_ammortamento_id INTEGER,        --conto_ammortamento
	pdce_conto_ammortamento_code VARCHAR(200), --conto_ammortamento
	pdce_conto_ammortamento_desc VARCHAR(500), --conto_ammortamento
	
	pdce_conto_fondo_ammortamento_id INTEGER,        --Conto del fondo di ammortamento
	pdce_conto_fondo_ammortamento_code VARCHAR(200), --Conto del fondo di ammortamento
	pdce_conto_fondo_ammortamento_desc VARCHAR(500), --Conto del fondo di ammortamento
	
	pdce_conto_plusvalenza_id INTEGER,        --Conto plusvalenza da alienazione
	pdce_conto_plusvalenza_code VARCHAR(200), --Conto plusvalenza da alienazione
	pdce_conto_plusvalenza_desc VARCHAR(500), --Conto plusvalenza da alienazione
	
	pdce_conto_minusvalenza_id INTEGER,        --Conto di minusvalenza da alienazione
	pdce_conto_minusvalenza_code VARCHAR(200), --Conto di minusvalenza da alienazione
	pdce_conto_minusvalenza_desc VARCHAR(500), --Conto di minusvalenza da alienazione
	
	pdce_conto_incremento_id INTEGER,        --Conto di incremento valore
	pdce_conto_incremento_code VARCHAR(200), --Conto di incremento valore
	pdce_conto_incremento_desc VARCHAR(500), --Conto di incremento valore
	
	pdce_conto_decremento_id INTEGER,        --Conto di decremento valore
	pdce_conto_decremento_code VARCHAR(200), --Conto di decremento valore
	pdce_conto_decremento_desc VARCHAR(500), --Conto di decremento valore
	
	pdce_conto_alienazione_id INTEGER,        --Conto credito da alienazione
	pdce_conto_alienazione_code VARCHAR(200), --Conto credito da alienazione
	pdce_conto_alienazione_desc VARCHAR(500), --Conto credito da alienazione
	
	pdce_conto_donazione_id INTEGER,        --Conto donazione / rinvenimento
	pdce_conto_donazione_code VARCHAR(200), --Conto donazione / rinvenimento
	pdce_conto_donazione_desc VARCHAR(500), --Conto donazione / rinvenimento
	
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_cespiti_bene_tipo PRIMARY KEY(ces_bene_tipo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_cespiti_bene_tipo FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_evento_ammortamento_siac_d_cespiti_bene_tipo  FOREIGN KEY (evento_ammortamento_id)
		REFERENCES siac_d_evento (evento_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_evento_incremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (evento_incremento_id)
		REFERENCES siac_d_evento(evento_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_evento_decremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (evento_decremento_id)
		REFERENCES siac_d_evento(evento_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_causale_ammortamento_siac_d_cespiti_bene_tipo  FOREIGN KEY (causale_ep_ammortamento_id)
		REFERENCES siac_t_causale_ep(causale_ep_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_causale_incremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (causale_ep_incremento_id)
		REFERENCES siac_t_causale_ep(causale_ep_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_causale_decremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (causale_ep_decremento_id)
		REFERENCES siac_t_causale_ep(causale_ep_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_ammortamento_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_ammortamento_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_fondo_ammortamento_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_plusvalenza_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_plusvalenza_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_minusvalenza_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_minusvalenza_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_incremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_incremento_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_decremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_decremento_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_alienazione_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_alienazione_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_donazione_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_donazione_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_d_cespiti_bene_tipo_fk_ente_proprietario_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (ente_proprietario_id);
CREATE UNIQUE INDEX siac_d_cespiti_bene_tipo_fk_ces_bene_tipo_code ON siac_d_cespiti_bene_tipo
	USING btree (ces_bene_tipo_code,ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_evento_ammortamento_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (evento_ammortamento_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_causale_ep_ammortamento_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (causale_ep_ammortamento_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_evento_incremento_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (evento_incremento_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_causale_ep_incremento_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (causale_ep_incremento_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_evento_decremento_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (evento_decremento_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_causale_ep_decremento_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (causale_ep_decremento_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_pdce_conto_ammortamento_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (pdce_conto_ammortamento_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_pdce_conto_fondo_ammortamento_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (pdce_conto_fondo_ammortamento_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_pdce_conto_plusvalenza_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (pdce_conto_plusvalenza_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_pdce_conto_minusvalenza_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (pdce_conto_minusvalenza_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_pdce_conto_incremento_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (pdce_conto_incremento_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_pdce_conto_decremento_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (pdce_conto_decremento_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_pdce_conto_alienazione_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (pdce_conto_alienazione_id);
CREATE INDEX siac_d_cespiti_bene_tipo_fk_pdce_conto_donazione_id_idx ON siac_d_cespiti_bene_tipo
	USING btree (pdce_conto_donazione_id);

--- CLASSIFICAZIONE GIURIDICA
CREATE TABLE IF NOT EXISTS siac_d_cespiti_classificazione_giuridica (
	ces_class_giu_id SERIAL,
	ces_class_giu_code VARCHAR(200) NOT NULL,
	ces_class_giu_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_ces_class_giu_id PRIMARY KEY(ces_class_giu_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_cespiti_classificazione_giuridica FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);
CREATE INDEX siac_d_cespiti_classificazione_giuridica_fk_ente_proprietario_id_idx ON siac_d_cespiti_classificazione_giuridica
	USING btree (ente_proprietario_id);
CREATE UNIQUE INDEX siac_d_cespiti_classificazione_giuridica_fk_ces_class_giu_code ON siac_d_cespiti_classificazione_giuridica
	USING btree (ces_class_giu_code,ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);

-- STATO DISMISSIONI
CREATE TABLE IF NOT EXISTS siac_d_cespiti_dismissioni_stato (
	ces_dismissioni_stato_id SERIAL,
	ces_dismissioni_stato_code VARCHAR(200) NOT NULL,
	ces_dismissioni_stato_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_cespiti_dismissioni_stato PRIMARY KEY(ces_dismissioni_stato_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_cespiti_dismissioni_stato FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_d_cespiti_dismissioni_stato_fk_ente_proprietario_id_idx ON siac_d_cespiti_dismissioni_stato
	USING btree (ente_proprietario_id);
	
CREATE UNIQUE INDEX siac_d_cespiti_dismissioni_stato_fk_ces_var_stato_code ON siac_d_cespiti_dismissioni_stato
	USING btree (ces_dismissioni_stato_code,ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);

--STATO VARIAZIONI
CREATE TABLE IF NOT EXISTS siac_d_cespiti_variazione_stato (
	ces_var_stato_id SERIAL,
	ces_var_stato_code VARCHAR(200) NOT NULL,
	ces_var_stato_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_cespiti_variazione_stato PRIMARY KEY(ces_var_stato_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_cespiti_variazione_stato FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_d_cespiti_variazione_stato_fk_ente_proprietario_id_idx ON siac_d_cespiti_variazione_stato
	USING btree (ente_proprietario_id);
CREATE UNIQUE INDEX siac_d_cespiti_variazione_stato_fk_ces_var_stato_code ON siac_d_cespiti_variazione_stato
	USING btree (ces_var_stato_code,ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);
	
--STATO ACCETTAZIONE PRIMA NOTA PROVVISORIA (V2)
CREATE TABLE IF NOT EXISTS siac_d_pn_prov_accettazione_stato (
	pn_sta_acc_prov_id SERIAL,
	pn_sta_acc_prov_code VARCHAR(200) NOT NULL,
	pn_sta_acc_prov_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_pn_prov_accettazione_stato PRIMARY KEY(pn_sta_acc_prov_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_pn_prov_accettazione_stato FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_d_pn_prov_accettazione_stato_fk_ente_proprietario_id_idx ON siac_d_pn_prov_accettazione_stato
	USING btree (ente_proprietario_id);

--STATO ACCETTAZIONE PRIMA NOTA DEFINITIVA (V2)
CREATE TABLE IF NOT EXISTS siac_d_pn_def_accettazione_stato (
	pn_sta_acc_def_id SERIAL,
	pn_sta_acc_def_code VARCHAR(200) NOT NULL,
	pn_sta_acc_def_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_pn_def_accettazione_stato PRIMARY KEY(pn_sta_acc_def_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_pn_prov_accettazione_stato FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_d_pn_def_accettazione_stato_fk_ente_proprietario_id_idx ON siac_d_pn_def_accettazione_stato
	USING btree (ente_proprietario_id);
	
--CESPITI
--- DISMISSIONI
CREATE TABLE IF NOT EXISTS siac_t_cespiti_dismissioni (
	ces_dismissioni_id SERIAL,	
	ces_dismissioni_desc VARCHAR(500) NOT NULL,
	elenco_dismissioni_anno INTEGER NOT NULL,
	elenco_dismissioni_numero INTEGER  NOT NULL,	
	data_cessazione TIMESTAMP NOT NULL,
	ces_dismissioni_stato_id INTEGER NOT NULL,
	dismissioni_desc_stato VARCHAR(500) NOT NULL,
	evento_id INTEGER,
	causale_ep_id INTEGER  NOT NULL,
	attoamm_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	login_creazione VARCHAR(200) NOT NULL,
	login_modifica VARCHAR(200) NOT NULL,
	login_cancellazione VARCHAR(200),
	CONSTRAINT pk_siac_t_cespiti_dismissioni PRIMARY KEY(ces_dismissioni_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_dismissioni FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_atto_amm_siac_t_cespiti_dismissioni FOREIGN KEY (attoamm_id)
		REFERENCES siac_t_atto_amm(attoamm_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_evento_siac_t_cespiti_dismissioni FOREIGN KEY (evento_id)
		REFERENCES siac_d_evento(evento_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_cespiti_dismissioni_stato_siac_t_cespiti_dismissioni FOREIGN KEY (ces_dismissioni_stato_id)
		REFERENCES siac_d_cespiti_dismissioni_stato(ces_dismissioni_stato_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_causale_ep_siac_t_cespiti_dismissioni FOREIGN KEY (causale_ep_id)
		REFERENCES siac_t_causale_ep(causale_ep_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_dismissioni_fk_ente_proprietario_id_idx ON siac_t_cespiti_dismissioni
	USING btree (ente_proprietario_id);
CREATE UNIQUE INDEX siac_t_cespiti_dismissioni_fk_ces_dismissioni_code ON siac_t_cespiti_dismissioni
	USING btree (ces_dismissioni_code,ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);	
CREATE INDEX siac_t_cespiti_dismissioni_fk_ces_dismissioni_stato_id_idx ON siac_t_cespiti_dismissioni
	USING btree (ces_dismissioni_stato_id);

CREATE TABLE IF NOT EXISTS siac_t_cespiti_elenco_dismissioni_num (
	elenco_dismissioni_num_id SERIAL,
	elenco_dismissioni_anno INTEGER NOT NULL,
	elenco_dismissioni_numero INTEGER NOT NULL,
	validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine TIMESTAMP WITHOUT TIME ZONE,
	ente_proprietario_id INTEGER NOT NULL,
	data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_dismissioni_elenco_num PRIMARY KEY(elenco_dismissioni_num_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_dismissioni_elenco_num FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_elenco_dismissioni_num_fk_ente_proprietario_id_idx ON siac_t_cespiti_elenco_dismissioni_num
	USING btree (ente_proprietario_id);
	
--- CESPITI
CREATE TABLE IF NOT EXISTS siac_t_cespiti (
	ces_id SERIAL,
	ces_code VARCHAR(200) NOT NULL,
	ces_desc VARCHAR(500) NOT NULL,
	soggetto_beni_culturali boolean default false,
	num_inventario VARCHAR(10) NOT NULL,
	num_inventario_prefisso VARCHAR(25) NOT NULL,
	num_inventario_numero INTEGER NOT NULL,
	data_ingresso_inventario TIMESTAMP NOT NULL,
	data_cessazione TIMESTAMP,
	valore_iniziale NUMERIC NOT NULL,
	valore_attuale NUMERIC NOT NULL,
	descrizione_stato VARCHAR(200),
	ubicazione VARCHAR(2000),
	note VARCHAR(2000),
	flg_donazione_rinvenimento boolean default false,
	flg_stato_bene boolean default true,
	ces_dismissioni_id INTEGER,
	ces_class_giu_id INTEGER NOT NULL,
	ces_bene_tipo_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	login_creazione VARCHAR(200) NOT NULL,
	login_modifica VARCHAR(200) NOT NULL,
	login_cancellazione VARCHAR(200),
	CONSTRAINT pk_siac_t_cespiti PRIMARY KEY(ces_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_siac_d_cespiti_bene_tipo FOREIGN KEY (ces_bene_tipo_id)
		REFERENCES siac_d_cespiti_bene_tipo(ces_bene_tipo_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_siac_t_cespiti_dismissioni FOREIGN KEY (ces_dismissioni_id)
		REFERENCES siac_t_cespiti_dismissioni(ces_dismissioni_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_siac_d_cespiti_classificazione_giuridica FOREIGN KEY (ces_class_giu_id)
		REFERENCES siac_d_cespiti_classificazione_giuridica(ces_class_giu_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_fk_ente_proprietario_id_idx ON siac_t_cespiti
	USING btree (ente_proprietario_id);
CREATE UNIQUE INDEX siac_t_cespiti_fk_ces_code ON siac_t_cespiti
	USING btree (ces_code,ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);
CREATE INDEX siac_t_cespiti_fk_ces_bene_tipo_id_idx ON siac_t_cespiti
	USING btree (ces_bene_tipo_id);
CREATE INDEX siac_t_cespiti_fk_ces_dismissioni_id_idx ON siac_t_cespiti
	USING btree (ces_dismissioni_id);
CREATE INDEX siac_t_cespiti_fk_ces_class_giu_id_idx ON siac_t_cespiti
	USING btree (ces_class_giu_id);
	
CREATE TABLE IF NOT EXISTS siac_t_cespiti_num_inventario (
	num_inventario_id SERIAL,
	num_inventario_prefisso VARCHAR(25) NOT NULL,
	num_inventario_numero INTEGER NOT NULL,
	validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine TIMESTAMP WITHOUT TIME ZONE,
	ente_proprietario_id INTEGER NOT NULL,
	data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_num_inventario PRIMARY KEY(num_inventario_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_num_inventario FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_num_inventario_fk_ente_proprietario_id_idx ON siac_t_cespiti_num_inventario
	USING btree (ente_proprietario_id);
--VARIAZIONI

CREATE TABLE IF NOT EXISTS siac_t_cespiti_variazione (
	ces_var_id SERIAL,
	ces_var_desc VARCHAR(500) NOT NULL,
	ces_var_anno VARCHAR(4) NOT NULL,
	ces_var_data TIMESTAMP NOT NULL,
	ces_var_importo NUMERIC not null,
	flg_tipo_variazione_incr boolean not null,
	ces_var_stato_id INTEGER NOT NULL,
	ces_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_variazione PRIMARY KEY(ces_var_id),
	CONSTRAINT siac_t_cespiti_variazione_siac_t_cespiti FOREIGN KEY (ces_id)
		REFERENCES siac_t_cespiti(ces_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_variazione_siac_d_cespiti_variazione_stato FOREIGN KEY (ces_var_stato_id)
		REFERENCES siac_d_cespiti_variazione_stato(ces_var_stato_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_variazione_siac_t_ente_proprietario FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_variazione_fk_ente_proprietario_id_idx ON siac_t_cespiti_variazione
	USING btree (ente_proprietario_id);
CREATE INDEX siac_t_cespiti_variazione_fk_ces_var_stato_id_idx ON siac_t_cespiti_variazione
	USING btree (ces_var_stato_id);

--AMMORTAMENTI
CREATE TABLE IF NOT EXISTS siac_t_cespiti_ammortamento (
	ces_amm_id SERIAL,
	ces_id INTEGER NOT NULL,
	ces_amm_ultimo_anno_reg INTEGER,
	ces_amm_importo_tot_reg NUMERIC,
	ces_amm_completo boolean default false,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_ammortamento PRIMARY KEY(ces_amm_id),
	CONSTRAINT siac_t_cespiti_siac_t_cespiti_ammortamento FOREIGN KEY (ces_id)
		REFERENCES siac_t_cespiti(ces_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_ammortamento FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_ammortamento_fk_ente_proprietario_id_idx ON siac_t_cespiti_ammortamento
	USING btree (ente_proprietario_id);
CREATE INDEX siac_t_cespiti_ammortamento_fk_ces_id_idx ON siac_t_cespiti_ammortamento
	USING btree (ces_id);

CREATE TABLE IF NOT EXISTS siac_t_cespiti_ammortamento_dett (
	ces_amm_dett_id SERIAL,
	ces_amm_id INTEGER NOT NULL,
	ces_amm_dett_data TIMESTAMP NOT NULL,
	ces_amm_dett_anno INTEGER,
	ces_amm_dett_importo NUMERIC,
	pnota_id INTEGER,
	num_reg_def_ammortamento VARCHAR(200),
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_ammortamento_dett PRIMARY KEY(ces_amm_dett_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_ammortamento_dett FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_ammortamento_siac_t_cespiti_ammortamento_dett FOREIGN KEY (ces_amm_id)
		REFERENCES siac_t_cespiti_ammortamento(ces_amm_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_ammortamento_dett_siac_t_prima_nota FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_ammortamento_dett_fk_ente_proprietario_id_idx ON siac_t_cespiti_ammortamento_dett
	USING btree (ente_proprietario_id);
CREATE INDEX siac_t_cespiti_ammortamento_dett_fk_ces_amm_id_idx ON siac_t_cespiti_ammortamento_dett
	USING btree (ces_amm_id);
CREATE INDEX siac_t_cespiti_ammortamento_dett_fk_pnota_id_idx ON siac_t_cespiti_ammortamento_dett
	USING btree (pnota_id);



-------------
--RELAZIONE
--------------
--- STORICIZZAZIONE
CREATE TABLE IF NOT EXISTS siac_r_cespiti_categoria_aliquota_calcolo_tipo (
	cescat_aliquota_calcolo_tipo_id SERIAL,
	cescat_id INTEGER,
	cescat_calcolo_tipo_id INTEGER,
	aliquota_annua NUMERIC,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_cespiti_categoria_aliquota_calcolo_tipo PRIMARY KEY(cescat_aliquota_calcolo_tipo_id),
	CONSTRAINT siac_d_cespiti_categoria_siac_r_cespiti_categoria_aliquota_calcolo_tipo FOREIGN KEY (cescat_id)
		REFERENCES siac.siac_d_cespiti_categoria(cescat_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_cespiti_categoria_calcolo_tipo_siac_r_cespiti_categoria_aliquota_calcolo_tipo FOREIGN KEY (cescat_calcolo_tipo_id)
		REFERENCES siac.siac_d_cespiti_categoria_calcolo_tipo(cescat_calcolo_tipo_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_categoria_aliquota_calcolo_tipo FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_r_cespiti_categoria_aliquota_calcolo_tipo_fk_cescat_calcolo_tipo_id_idx ON siac.siac_r_cespiti_categoria_aliquota_calcolo_tipo
	USING btree (cescat_calcolo_tipo_id);
	
CREATE INDEX siac_r_cespiti_categoria_aliquota_calcolo_tipo_fk_cescat_id_idx ON siac.siac_r_cespiti_categoria_aliquota_calcolo_tipo
	USING btree (cescat_id);
	
CREATE INDEX siac_r_cespiti_categoria_aliquota_calcolo_tipo_fk_ente_proprietario_id_idx ON siac_r_cespiti_categoria_aliquota_calcolo_tipo
	USING btree (ente_proprietario_id);

CREATE TABLE IF NOT EXISTS siac_r_cespiti_bene_tipo_conto_patr_cat (
	ces_bene_tipo_conto_patr_cat_id SERIAL,
	ces_bene_tipo_id INTEGER,
	cescat_id INTEGER NOT NULL,
	pdce_conto_patrimoniale_id INTEGER,
	pdce_conto_patrimoniale_code VARCHAR(200),
	pdce_conto_patrimoniale_desc VARCHAR(500),
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP WITHOUT TIME ZONE,
	data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_cespiti_bene_tipo_conto_patr_cat PRIMARY KEY(ces_bene_tipo_conto_patr_cat_id),
	CONSTRAINT siac_d_cespiti_bene_tipo_siac_r_cespiti_bene_tipo_conto_patr_ca FOREIGN KEY (ces_bene_tipo_id)
	    REFERENCES siac.siac_d_cespiti_bene_tipo(ces_bene_tipo_id)
	    ON DELETE NO ACTION
	    ON UPDATE NO ACTION
	    NOT DEFERRABLE,
	  CONSTRAINT siac_d_cespiti_categoria_siac_r_cespiti_bene_tipo_conto_patr_ca FOREIGN KEY (cescat_id)
	    REFERENCES siac.siac_d_cespiti_categoria(cescat_id)
	    ON DELETE NO ACTION
	    ON UPDATE NO ACTION
	    NOT DEFERRABLE,
	  CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_bene_tipo_conto_patr_ca FOREIGN KEY (ente_proprietario_id)
	    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
	    ON DELETE NO ACTION
	    ON UPDATE NO ACTION
	    NOT DEFERRABLE,
	  CONSTRAINT siac_t_pdce_conto_patrimoniale_siac_r_cespiti_bene_tipo_conto_p FOREIGN KEY (pdce_conto_patrimoniale_id)
	    REFERENCES siac.siac_t_pdce_conto(pdce_conto_id)
	    ON DELETE NO ACTION
	    ON UPDATE NO ACTION
	    NOT DEFERRABLE
);

CREATE INDEX siac_r_cespiti_bene_tipo_conto_patr_cat_fk_pdce_conto_patrimoniale_id_idx ON siac.siac_r_cespiti_bene_tipo_conto_patr_cat
	USING btree (pdce_conto_patrimoniale_id);  
CREATE INDEX siac_r_cespiti_bene_tipo_conto_patr_cat_fk_ces_bene_tipo_id_idx ON siac.siac_r_cespiti_bene_tipo_conto_patr_cat
	USING btree (ces_bene_tipo_id);
CREATE INDEX siac_r_cespiti_bene_tipo_conto_patr_cat_fk_cescat_id_idx ON siac.siac_r_cespiti_bene_tipo_conto_patr_cat
	USING btree (cescat_id);
CREATE INDEX siac_r_cespiti_bene_tipo_conto_patr_cat_fk_ente_proprietario_id_idx ON siac.siac_r_cespiti_bene_tipo_conto_patr_cat
	USING btree (ente_proprietario_id);

--LEGAMI STATI ACCETTAZIONE PRIME NOTE (V2)
CREATE TABLE IF NOT EXISTS siac_r_pn_def_accettazione_stato (
	pn_r_sta_acc_def_id SERIAL,
	pn_sta_acc_def_id INTEGER   NOT NULL,
	pnota_id INTEGER   NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_pn_def_accettazione_stato PRIMARY KEY(pn_r_sta_acc_def_id),
	CONSTRAINT siac_t_prima_nota_siac_r_pn_def_accettazione_stato FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_pn_def_accettazione_stato_siac_r_pn_def_accettazione_stato FOREIGN KEY (pn_sta_acc_def_id)
		REFERENCES siac_d_pn_def_accettazione_stato(pn_sta_acc_def_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_r_pn_stato_acc_def_fk_ente_proprietario_id_idx ON siac_d_pn_def_accettazione_stato
	USING btree (ente_proprietario_id);
CREATE UNIQUE INDEX siac_r_pn_stato_acc_def_fk_pnota_id ON siac_r_pn_def_accettazione_stato
	USING btree (pnota_id,pn_sta_acc_def_id,ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);


CREATE TABLE IF NOT EXISTS siac_r_pn_prov_accettazione_stato (
	pn_r_sta_acc_prov_id SERIAL,
	pn_sta_acc_prov_id INTEGER   NOT NULL,
	pnota_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_pn_prov_accettazione_stato PRIMARY KEY(pn_r_sta_acc_prov_id),
	CONSTRAINT siac_t_prima_nota_siac_r_pn_prov_accettazione_stato FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_pn_prov_accettazione_stato_siac_r_pn_prov_accettazione_stato FOREIGN KEY (pn_sta_acc_prov_id)
		REFERENCES siac_d_pn_prov_accettazione_stato(pn_sta_acc_prov_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_r_pn_stato_acc_prov_fk_ente_proprietario_id_idx ON siac_r_pn_prov_accettazione_stato
	USING btree (ente_proprietario_id);
CREATE UNIQUE INDEX siac_r_pn_stato_acc_prov_fk_pnota_id ON siac_r_pn_prov_accettazione_stato
	USING btree (pnota_id,pn_sta_acc_prov_id,ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);

CREATE TABLE IF NOT EXISTS siac_r_cespiti_prima_nota (
	ces_pn_id SERIAL,
	ces_id INTEGER NOT NULL,
	pnota_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_cespiti_prima_nota PRIMARY KEY(ces_pn_id),
	CONSTRAINT siac_t_prima_nota_siac_r_cespiti_prima_nota FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_pn_prov_accettazione_stato_siac_t_cespite FOREIGN KEY (ces_id)
		REFERENCES siac_t_cespiti(ces_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_prima_nota FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);
CREATE INDEX siac_r_cespiti_prima_nota_fk_ente_proprietario_id_idx ON siac_r_cespiti_prima_nota
	USING btree (ente_proprietario_id);
CREATE UNIQUE INDEX siac_r_cespiti_prima_nota_fk_pnota_id ON siac_r_cespiti_prima_nota
	USING btree (pnota_id,ces_id,ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);


CREATE TABLE IF NOT EXISTS siac_r_cespiti_variazione_prima_nota (
	ces_var_pn_id SERIAL,
	ces_var_id INTEGER NOT NULL,
	pnota_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_cespiti_variazione_prima_nota PRIMARY KEY(ces_var_pn_id),
	CONSTRAINT siac_t_prima_nota_siac_r_cespite_variazione_prima_nota FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespite_variazione_siac_r_cespite_variazione_prima_nota FOREIGN KEY (ces_var_id)
		REFERENCES siac_t_cespiti_variazione(ces_var_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_variazione_prima_nota FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_r_cespiti_variazione_prima_nota_fk_ente_proprietario_id_idx ON siac_r_cespiti_variazione_prima_nota
	USING btree (ente_proprietario_id);
CREATE UNIQUE INDEX siac_r_cespiti_variazione_prima_nota_fk_pnota_id ON siac_r_cespiti_variazione_prima_nota
	USING btree (pnota_id,ces_var_id,ente_proprietario_id)
	WHERE (data_cancellazione IS NULL);

	
--LEGAME PNOTA-DISMISSIONI
CREATE TABLE IF NOT EXISTS siac.siac_r_cespiti_dismissioni_prima_nota (
  ces_dismissioni_pn_id SERIAL,
  ces_dismissioni_id INTEGER NOT NULL,
  ces_amm_dett_id INTEGER NOT NULL,
  pnota_id INTEGER NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_cespiti_dismissioni_prima_nota PRIMARY KEY(ces_dismissioni_pn_id),
  CONSTRAINT siac_t_cespiti_ammortamento_dett_siac_r_cespiti_dismissioni_pri FOREIGN KEY (ces_amm_dett_id)
    REFERENCES siac.siac_t_cespiti_ammortamento_dett(ces_amm_dett_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_cespiti_dismissione_siac_r_cespite_dismissione_prima_not FOREIGN KEY (ces_dismissioni_id)
    REFERENCES siac.siac_t_cespiti_dismissioni(ces_dismissioni_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_dismissioni_prima_nota FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prima_nota_siac_r_cespite_dismissioni_prima_nota FOREIGN KEY (pnota_id)
    REFERENCES siac.siac_t_prima_nota(pnota_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_r_cespiti_dismissioni_prima_nota_fk_ente_proprietario_id_i ON siac.siac_r_cespiti_dismissioni_prima_nota
  USING btree (ente_proprietario_id);

CREATE UNIQUE INDEX siac_r_cespiti_dismissioni_prima_nota_idx ON siac.siac_r_cespiti_dismissioni_prima_nota
  USING btree (pnota_id, ces_dismissioni_id, ces_amm_dett_id, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

---------------------------------
--- ELABORAZIONI	
---------------------------------

CREATE IF NOT EXISTS TABLE siac.siac_t_cespiti_elab_ammortamenti (
  elab_id SERIAL,
  anno INTEGER NOT NULL,
  stato_elaborazione VARCHAR(200),
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_t_cespiti_elab_ammortamenti PRIMARY KEY(elab_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_elab_ammortamenti FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_elab_ammortamenti_fk_ente_proprietario_id_idx ON siac.siac_t_cespiti_elab_ammortamenti
  USING btree (ente_proprietario_id);

CREATE IF NOT EXISTS TABLE siac.siac_t_cespiti_elab_ammortamenti_dett (
  elab_dett_id SERIAL,
  elab_id INTEGER NOT NULL,
  pdce_conto_id INTEGER,
  pdce_conto_code VARCHAR(200),
  pdce_conto_desc VARCHAR(500),
  elab_det_importo NUMERIC NOT NULL,
  elab_det_segno CHAR(40),
  numero_cespiti INTEGER NOT NULL,
  pnota_id INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_t_elaborazione_ammortamenti_dett PRIMARY KEY(elab_dett_id),
  CONSTRAINT siac_d_cespiti_bene_tipo_siac_t_cespiti_elab_ammortamenti_dett FOREIGN KEY (pdce_conto_id)
    REFERENCES siac.siac_t_pdce_conto(pdce_conto_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_cespiti_elab_ammortamenti_siac_t_cespiti_elab_ammortamen FOREIGN KEY (elab_id)
    REFERENCES siac.siac_t_cespiti_elab_ammortamenti(elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_elab_ammortamenti_dett FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_elab_amm_dett_fk_elab_id_idx ON siac.siac_t_cespiti_elab_ammortamenti_dett
  USING btree (elab_id);

CREATE INDEX siac_t_cespiti_elab_amm_dett_fk_ente_proprietario_id_idx ON siac.siac_t_cespiti_elab_ammortamenti_dett
  USING btree (ente_proprietario_id);

CREATE INDEX siac_t_cespiti_elab_amm_dett_fk_pnota_id_idx ON siac.siac_t_cespiti_elab_ammortamenti_dett
  USING btree (pnota_id);
	
CREATE TABLE siac.siac_r_cespiti_cespiti_elab_ammortamenti (
  ces_elab_dett_id SERIAL,
  ces_id INTEGER NOT NULL,
  elab_dett_id_dare INTEGER NOT NULL,
  elab_dett_id_avere INTEGER NOT NULL,
  pnota_id INTEGER,
  elab_id INTEGER NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ces_amm_dett_id INTEGER,
  CONSTRAINT pk_siac_r_cespiti_cespiti_elab_ammortamenti PRIMARY KEY(ces_elab_dett_id),
  CONSTRAINT siac_t_cespiti_ammortamento_dett_siac_r_cespiti_cespiti_elab_am FOREIGN KEY (ces_amm_dett_id)
    REFERENCES siac.siac_t_cespiti_ammortamento_dett(ces_amm_dett_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_cespiti_elab_ammortamenti_dett_avere_siac_r_cespiti_cesp FOREIGN KEY (elab_dett_id_avere)
    REFERENCES siac.siac_t_cespiti_elab_ammortamenti_dett(elab_dett_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_cespiti_elab_ammortamenti_dett_dare_siac_r_cespiti_cespi FOREIGN KEY (elab_dett_id_dare)
    REFERENCES siac.siac_t_cespiti_elab_ammortamenti_dett(elab_dett_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_cespiti_siac_r_cespiti_cespiti_elab_ammortamenti FOREIGN KEY (ces_id)
    REFERENCES siac.siac_t_cespiti(ces_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_cespiti_elab_ammortamen FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prima_nota_siac_r_cespiti_cespiti_elab_ammortamenti FOREIGN KEY (pnota_id)
    REFERENCES siac.siac_t_prima_nota(pnota_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_r_cespiti_cespiti_elab_ammortamenti_fk_ces_id_idx ON siac.siac_r_cespiti_cespiti_elab_ammortamenti
  USING btree (ces_id);

CREATE INDEX siac_r_cespiti_cespiti_elab_ammortamenti_fk_cescat_calcolo_tipo ON siac.siac_r_cespiti_cespiti_elab_ammortamenti
  USING btree (ente_proprietario_id);

CREATE INDEX siac_r_cespiti_cespiti_elab_ammortamenti_fk_dett_dare_avere_idx ON siac.siac_r_cespiti_cespiti_elab_ammortamenti
  USING btree (elab_dett_id_dare, elab_dett_id_avere);

CREATE INDEX siac_r_cespiti_cespiti_elab_ammortamenti_fk_dettagli ON siac.siac_r_cespiti_cespiti_elab_ammortamenti
  USING btree (ces_id, elab_dett_id_dare, elab_dett_id_avere, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX siac_r_cespiti_cespiti_elab_ammortamenti_fk_siac_t_prima_nota_i ON siac.siac_r_cespiti_cespiti_elab_ammortamenti
  USING btree (pnota_id);

CREATE TABLE IF NOT EXISTS siac.siac_r_cespiti_mov_ep_det(
  ces_movep_det_id SERIAL,
  ces_id INTEGER NOT NULL,
  movep_det_id INTEGER NOT NULL,
  pnota_id INTEGER, --valutare se tenere
  ente_proprietario_id INTEGER NOT NULL,
  ces_contestuale boolean default false,
  importo_su_prima_nota NUMERIC NOT NULL,
  pnota_alienazione_id INTEGER, --valutare se tenere
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_cespiti_mov_ep_det PRIMARY KEY(ces_movep_det_id),
  CONSTRAINT siac_t_cespiti_siac_r_cespiti_mov_ep_det FOREIGN KEY (ces_id)
    REFERENCES siac.siac_t_cespiti(ces_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_mov_ep_det_siac_r_cespiti_mov_ep_det FOREIGN KEY (movep_det_id)
    REFERENCES siac.siac_t_mov_ep_det(movep_det_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prima_nota_siac_r_cespiti_mov_ep_det FOREIGN KEY (pnota_id)
    REFERENCES siac.siac_t_prima_nota(pnota_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
    CONSTRAINT siac_t_prima_nota_siac_r_cespiti_mov_ep_det FOREIGN KEY (pnota_alienazione_id)
    REFERENCES siac.siac_t_prima_nota(pnota_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_mov_ep_det FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE  
);

CREATE INDEX siac_r_cespiti_mov_ep_det_fk_ces_id_idx ON siac.siac_r_cespiti_mov_ep_det
  USING btree (ces_id, movep_det_id,ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX siac_r_cespiti_mov_ep_det_fk_ente_proprietario_id_idx ON siac.siac_r_cespiti_mov_ep_det
  USING btree (ente_proprietario_id);