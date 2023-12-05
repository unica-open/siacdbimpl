/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


drop view if exists siac.siac_v_dwh_mutuo;
drop view if exists siac.siac_v_dwh_mutuo_movgest_ts;
drop view if exists siac.siac_v_dwh_mutuo_programma;
drop view if exists siac.siac_v_dwh_mutuo_rata;
drop view if exists siac.siac_v_dwh_mutuo_variazione;
drop view if exists siac.siac_v_dwh_storico_mutuo;

--DROP TABLE if exists siac.siac_t_mutuo_num;
CREATE TABLE if not exists siac.siac_t_mutuo_num (
	mutuo_num_id serial4 NOT NULL,
	mutuo_numero int4 NOT NULL,
--
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_t_mutuo_num PRIMARY KEY (mutuo_num_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_mutuo_num 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);
DROP INDEX IF EXISTS idx_siac_t_mutuo_num;
CREATE INDEX idx_siac_t_mutuo_num ON siac.siac_t_mutuo_num (ente_proprietario_id, mutuo_numero);



--DROP TABLE if exists siac.siac_d_mutuo_stato CASCADE;
CREATE TABLE if not exists siac.siac_d_mutuo_stato (
	mutuo_stato_id serial4 NOT NULL,
	mutuo_stato_code varchar(200) NOT NULL,
	mutuo_stato_desc varchar(500) NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_mutuo_stato PRIMARY KEY (mutuo_stato_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_mutuo_stato 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);



--DROP TABLE if exists siac.siac_d_mutuo_periodo_rimborso CASCADE;
CREATE TABLE if not exists siac.siac_d_mutuo_periodo_rimborso (
	mutuo_periodo_rimborso_id serial4 NOT NULL,
	mutuo_periodo_rimborso_code varchar(200) NOT NULL,
	mutuo_periodo_rimborso_desc varchar(500) NULL,
	mutuo_periodo_numero_mesi int4 NULL,	
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_mutuo_periodo_rimborso PRIMARY KEY (mutuo_periodo_rimborso_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_mutuo_stato 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);

--DROP TABLE if exists siac.siac_d_mutuo_variazione_tipo CASCADE;
CREATE TABLE if not exists siac.siac_d_mutuo_variazione_tipo (
	mutuo_variazione_tipo_id serial4 NOT NULL,
	mutuo_variazione_tipo_code varchar(200) NOT NULL,
	mutuo_variazione_tipo_desc varchar(500) NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_mutuo_variazione_tipo PRIMARY KEY (mutuo_variazione_tipo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_mutuo_variazione_tipo 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);


--DROP TABLE if exists siac.siac_d_mutuo_tipo_tasso CASCADE;
CREATE TABLE if not exists siac.siac_d_mutuo_tipo_tasso (
	mutuo_tipo_tasso_id serial4 NOT NULL,
	mutuo_tipo_tasso_code varchar(200) NOT NULL,
	mutuo_tipo_tasso_desc varchar(500) NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_mutuo_tipo_tasso PRIMARY KEY (mutuo_tipo_tasso_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_mutuo_stato 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);




--DROP TABLE if exists siac.siac_t_mutuo CASCADE;
CREATE TABLE if not exists siac.siac_t_mutuo (
	mutuo_id serial4 NOT NULL,
	mutuo_numero int4 NOT NULL,
	mutuo_oggetto varchar(500) NULL,
	mutuo_stato_id int4 NOT NULL,
	mutuo_tipo_tasso_id int4 NOT NULL,
	mutuo_data_atto timestamp NULL,
	mutuo_soggetto_id int4 NULL,
	mutuo_somma_iniziale numeric NULL,
	mutuo_somma_effettiva numeric NULL,
	mutuo_tasso numeric NULL,	
	mutuo_tasso_euribor numeric NULL,	
	mutuo_tasso_spread numeric NULL,	
	mutuo_durata_anni int4 NULL,	
	mutuo_anno_inizio int4 NULL,	
	mutuo_anno_fine int4 NULL,	
	mutuo_periodo_rimborso_id int4 NULL,
	mutuo_data_scadenza_prima_rata timestamp NULL,
	mutuo_annualita numeric NULL,
	mutuo_preammortamento numeric NULL,
	mutuo_contotes_id int4 NULL,
	mutuo_attoamm_id int4 NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200),
	CONSTRAINT pk_siac_t_mutuo PRIMARY KEY (mutuo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_mutuo 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_soggetto_siac_t_mutuo 
		FOREIGN KEY (mutuo_soggetto_id) REFERENCES siac.siac_t_soggetto(soggetto_id),
	CONSTRAINT siac_d_mutuo_stato_siac_t_mutuo 
		FOREIGN KEY (mutuo_stato_id) REFERENCES siac.siac_d_mutuo_stato(mutuo_stato_id),
	CONSTRAINT siac_d_mutuo_periodo_rimborso_siac_t_mutuo 
		FOREIGN KEY (mutuo_periodo_rimborso_id) REFERENCES siac.siac_d_mutuo_periodo_rimborso(mutuo_periodo_rimborso_id),
	CONSTRAINT siac_d_mutuo_tipo_tasso_siac_t_mutuo 
		FOREIGN KEY (mutuo_tipo_tasso_id) REFERENCES siac.siac_d_mutuo_tipo_tasso(mutuo_tipo_tasso_id),
	CONSTRAINT siac_d_contotesoreria_siac_t_mutuo 
		FOREIGN KEY (mutuo_contotes_id) REFERENCES siac.siac_d_contotesoreria(contotes_id),
	CONSTRAINT siac_t_atto_amm_siac_t_mutuo 
		FOREIGN KEY (mutuo_attoamm_id) REFERENCES siac.siac_t_atto_amm(attoamm_id)

		
);


--DROP TABLE if exists siac.siac_s_mutuo_storico CASCADE;
CREATE TABLE if not exists siac.siac_s_mutuo_storico (
	mutuo_storico_id serial4 NOT NULL,
	mutuo_id int4 NOT NULL,
	mutuo_numero int4 NOT NULL,
	mutuo_oggetto varchar(500) NULL,
	mutuo_stato_id int4 NOT NULL,
	mutuo_tipo_tasso_id int4 NOT NULL,
	mutuo_data_atto timestamp NULL,
	mutuo_soggetto_id int4 NULL,
	mutuo_somma_iniziale numeric NULL,
	mutuo_somma_effettiva numeric NULL,
	mutuo_tasso numeric NULL,	
	mutuo_tasso_euribor numeric NULL,	
	mutuo_tasso_spread numeric NULL,	
	mutuo_durata_anni int4 NULL,	
	mutuo_anno_inizio int4 NULL,	
	mutuo_anno_fine int4 NULL,	
	mutuo_periodo_rimborso_id int4 NULL,
	mutuo_data_scadenza_prima_rata timestamp NULL,
	mutuo_annualita numeric NULL,
	mutuo_preammortamento numeric NULL,
	mutuo_contotes_id int4 NULL,
	mutuo_attoamm_id int4 NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200),
	CONSTRAINT pk_siac_s_mutuo_storico PRIMARY KEY (mutuo_storico_id),
	CONSTRAINT siac_t_ente_proprietario_siac_s_mutuo_storico 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_s_mutuo_storico 
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id),
	CONSTRAINT siac_t_soggetto_siac_s_mutuo_storico  
		FOREIGN KEY (mutuo_soggetto_id) REFERENCES siac.siac_t_soggetto(soggetto_id),
	CONSTRAINT siac_d_mutuo_stato_siac_s_mutuo_storico  
		FOREIGN KEY (mutuo_stato_id) REFERENCES siac.siac_d_mutuo_stato(mutuo_stato_id),
	CONSTRAINT siac_d_mutuo_periodo_rimborso_siac_s_mutuo_storico  
		FOREIGN KEY (mutuo_periodo_rimborso_id) REFERENCES siac.siac_d_mutuo_periodo_rimborso(mutuo_periodo_rimborso_id),
	CONSTRAINT siac_d_mutuo_tipo_tasso_siac_s_mutuo_storico 
		FOREIGN KEY (mutuo_tipo_tasso_id) REFERENCES siac.siac_d_mutuo_tipo_tasso(mutuo_tipo_tasso_id),
	CONSTRAINT siac_d_contotesoreria_siac_s_mutuo_storico 
		FOREIGN KEY (mutuo_contotes_id) REFERENCES siac.siac_d_contotesoreria(contotes_id),
	CONSTRAINT siac_t_atto_amm_siac_s_mutuo_storico 
		FOREIGN KEY (mutuo_attoamm_id) REFERENCES siac.siac_t_atto_amm(attoamm_id)
);


--DROP TABLE if exists siac.siac_t_mutuo_variazione CASCADE;
CREATE TABLE if not exists siac.siac_t_mutuo_variazione (
	mutuo_variazione_id serial4 NOT NULL,
	mutuo_id int4 NOT NULL,
	mutuo_variazione_tipo_id int4 NOT NULL,
	mutuo_variazione_anno int4 NULL,
	mutuo_variazione_num_rata int4 NULL,
	mutuo_variazione_anno_fine_piano_ammortamento int4 NULL,
	mutuo_variazione_num_rata_finale int4 NULL,
	mutuo_variazione_importo_rata numeric NULL,
	mutuo_variazione_tasso_euribor numeric NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200) NULL,
	CONSTRAINT pk_siac_t_mutuo_variazione PRIMARY KEY (mutuo_variazione_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_mutuo_variazione 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_t_mutuo_variazione 
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id),
	CONSTRAINT siac_d_mutuo_variazione_tipo_siac_t_mutuo_variazione 
		FOREIGN KEY (mutuo_variazione_tipo_id) REFERENCES siac.siac_d_mutuo_variazione_tipo(mutuo_variazione_tipo_id)

);

DROP TABLE if exists siac.siac_t_mutuo_piano_ammortamento CASCADE;

--DROP TABLE if exists siac.siac_t_mutuo_rata CASCADE;
CREATE TABLE if not exists siac.siac_t_mutuo_rata (
	mutuo_rata_id serial4 NOT NULL,
	mutuo_id int4 NOT NULL,
	mutuo_rata_anno int4 NOT NULL,
	mutuo_rata_num_rata_piano int4 NOT NULL,
	mutuo_rata_num_rata_anno int4 NOT NULL,
	mutuo_rata_data_scadenza date NOT NULL,
	mutuo_rata_importo numeric NULL,
	mutuo_rata_importo_quota_interessi numeric NULL,
	mutuo_rata_importo_quota_capitale numeric NULL,
	mutuo_rata_importo_quota_oneri numeric NULL,
	mutuo_rata_debito_residuo numeric NOT NULL,
	mutuo_rata_debito_iniziale numeric NOT null,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200) NULL,
	CONSTRAINT pk_siac_t_mutuo_rata PRIMARY KEY (mutuo_rata_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_mutuo_rata
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_t_mutuo_rata 
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id)
);



--DROP TABLE if exists siac.siac_r_mutuo_movgest_ts CASCADE;
CREATE TABLE if not exists siac.siac_r_mutuo_movgest_ts (
	mutuo_movgest_ts_id serial4 NOT NULL,
	mutuo_id int4 NOT NULL,
	movgest_ts_id int4 NOT NULL,
	mutuo_movgest_ts_importo_iniziale numeric NULL,
	mutuo_movgest_ts_importo_finale numeric NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200) NULL,
	CONSTRAINT pk_siac_r_mutuo_movgest_ts PRIMARY KEY (mutuo_movgest_ts_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_mutuo_movgest_ts 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_r_mutuo_movgest_ts 
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id),
	CONSTRAINT siac_t_movgest_ts_siac_r_mutuo_movgest_ts 
		FOREIGN KEY (movgest_ts_id) REFERENCES siac.siac_t_movgest_ts(movgest_ts_id)
);


--DROP TABLE if exists siac.siac_r_mutuo_programma CASCADE;
CREATE TABLE if not exists siac.siac_r_mutuo_programma (
	mutuo_programma_id serial4 NOT NULL,
	mutuo_id int4 NOT NULL,
	programma_id int4 NOT NULL,
	mutuo_programma_importo_iniziale numeric NULL,
	mutuo_programma_importo_finale numeric NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200) NULL,
	CONSTRAINT pk_siac_r_mutuo_programma PRIMARY KEY (mutuo_programma_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_mutuo_programma 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_r_mutuo_programma 
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id),
	CONSTRAINT siac_t_programma_siac_r_mutuo_programma
		FOREIGN KEY (programma_id) REFERENCES siac.siac_t_programma(programma_id)
);

alter table siac.siac_t_mutuo add column if not exists 	mutuo_data_inizio_piano_ammortamento date NULL;
alter table siac.siac_t_mutuo add column if not exists 	mutuo_data_scadenza_ultima_rata date NULL;
alter table siac.siac_s_mutuo_storico add column if not exists 	mutuo_data_inizio_piano_ammortamento date NULL;
alter table siac.siac_s_mutuo_storico add column if not exists 	mutuo_data_scadenza_ultima_rata date NULL;

alter table siac.siac_t_mutuo alter column mutuo_data_scadenza_prima_rata  type date;
alter table siac.siac_t_mutuo alter column mutuo_data_atto  type date;
alter table siac.siac_s_mutuo_storico alter column mutuo_data_scadenza_prima_rata type date;
alter table siac.siac_s_mutuo_storico alter column mutuo_data_atto type date;

alter table siac.siac_t_mutuo_rata add column if not exists mutuo_rata_debito_iniziale numeric NULL;

create table if not exists siac_bko_t_mutuo (
	bko_mutuo_id serial4 NOT NULL,
	bko_mutuo_numero int4 NOT NULL,
	bko_mutuo_tipo_tasso varchar(1) NOT NULL,
	bko_mutuo_istituto_codice varchar(10) NULL,
	bko_mutuo_istituto varchar(500) NULL,
	bko_mutuo_somma_mutuata numeric NULL,
	bko_mutuo_oggetto varchar(500) NULL,
	bko_mutuo_documento_anno int4 NULL,
	bko_mutuo_documento_numero int4 NULL,
	bko_mutuo_tasso numeric NULL,
	bko_mutuo_tasso_euribor numeric NULL,	
	bko_mutuo_tasso_spread numeric NULL,
	bko_mutuo_durata_anni int4 NULL,
	bko_mutuo_anno_inizio int4 NULL,
	bko_mutuo_anno_fine int4 NULL,
	bko_mutuo_importo_oneri numeric NULL,	
	bko_mutuo_periodo_rimborso int4 NULL,
	bko_mutuo_scadenza_giorono int4 NULL,
	bko_mutuo_scadenza_mese int4 NULL,
	bko_mutuo_numero_rate_anno int4 NULL,
	bko_mutuo_data_atto date NULL
);

create table if not exists siac_bko_t_mutuo_rata (
	bko_mutuo_rata_id serial4 NOT NULL,
	bko_mutuo_numero int4 NOT NULL,
	bko_mutuo_rata_anno int4 NOT NULL,
	bko_mutuo_rata_num_rata int4 NOT NULL,
	bko_mutuo_rata_importo_quota_interessi numeric NULL,
	bko_mutuo_rata_importo_quota_capitale numeric NULL,
	bko_mutuo_rata_importo_quota_oneri numeric NULL,
	bko_mutuo_rata_debito_residuo numeric NULL,
	bko_mutuo_rata_debito_iniziale numeric null
);