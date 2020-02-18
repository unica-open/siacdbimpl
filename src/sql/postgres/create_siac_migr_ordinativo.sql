/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop table if exists migr_ordinativo_entrata cascade;
drop table if exists migr_ordinativo_entrata_scarto cascade;
drop table if exists siac_r_migr_ordinativo_entrata_ordinativo cascade;


CREATE TABLE migr_ordinativo_entrata (
	migr_ordinativo_id serial ,
	ordinativo_id integer  NOT NULL,
	anno_esercizio integer  NOT NULL,
	numero_ordinativo integer  NOT NULL,
	numero_capitolo integer  NOT NULL DEFAULT 0,
	numero_articolo integer  NOT NULL DEFAULT 0,
	numero_ueb varchar(50) NOT NULL DEFAULT 1,
	descrizione varchar(500) NOT NULL,
	data_emissione varchar(10) NOT NULL,
	data_annullamento varchar(10),
	data_riduzione varchar(10),
	data_scadenza varchar(10),
	data_spostamento varchar(10),
	data_trasmissione varchar(10),
	stato_operativo varchar(1) NOT NULL,
	codice_distinta varchar(10),
	codice_bollo varchar(10) NOT NULL,
	--codice_commissione varchar(10) NOT NULL,
	codice_conto_corrente varchar(10) NOT NULL,
	codice_soggetto integer  NOT NULL,
	anno_provvedimento integer ,
	numero_provvedimento integer  ,
	tipo_provvedimento varchar(20),
	sac_provvedimento varchar(20),
	oggetto_provvedimento varchar(500),
	note_provvedimento varchar(500),
	stato_provvedimento varchar(50),
	flag_allegato_cart  varchar(10),
	note_tesoriere varchar(10) ,
	comunicazioni_tes varchar(500),
	firma_ord_data varchar(10),
	firma_ord varchar(500),
	quietanza_numero integer ,
	quietanza_data varchar(10),
	quietanza_importo numeric,
	storno_quiet_numero integer ,
	storno_quiet_data varchar(10),
	storno_quiet_importo numeric,
	cast_competenza numeric NOT NULL DEFAULT 0,
	cast_cassa numeric NOT NULL DEFAULT 0,
	cast_emessi numeric NOT NULL DEFAULT 0,
	utente_creazione varchar(50) NOT NULL,
	utente_modifica varchar(50),
	classificatore_1	varchar(250),
    classificatore_2	varchar(250),
    classificatore_3	varchar(250),
    --classificatore_4	varchar(250),	
    --classificatore_5	varchar(250),	
	pdc_finanziario varchar(50),
	transazione_ue_entrata varchar(50),
	entrata_ricorrente varchar(50),
	perimetro_sanitario_entrata varchar(50),
	pdc_economico_patr varchar(50),
	siope_entrata varchar(50),
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_ordinativo_entrata PRIMARY KEY (migr_ordinativo_id)
);


CREATE TABLE migr_ordinativo_entrata_scarto (
	migr_ordinativo_scarto_id serial ,
	migr_ordinativo_id integer  NOT NULL,
	numero_ordinativo integer  NOT NULL,
	anno_esercizio varchar(4) NOT NULL,
	motivo_scarto varchar(2500) NOT NULL,
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_ordinativo_entrata_scarto PRIMARY KEY (migr_ordinativo_scarto_id)
);


CREATE TABLE siac_r_migr_ordinativo_entrata_ordinativo (
	migr_rel_id serial ,
	migr_ordinativo_id integer  NOT NULL,
	ord_id integer  NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	ente_proprietario_id integer  NOT NULL,
	CONSTRAINT pk_siac_r_migr_ordinativo_entrata_ordinativo PRIMARY KEY (migr_rel_id),
	CONSTRAINT siac_t_ente_proprietario_r_migr_ordinativo_entrata_ordinativo FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);


---------------------------------------------------------------------------------------

drop table if exists migr_ordinativo_entrata_ts cascade;
drop table if exists migr_ordinativo_entrata_ts_scarto cascade;
drop table if exists siac_r_migr_ordinativo_ts_entrata_ordinativo cascade;

create table migr_ordinativo_entrata_ts	(
	migr_ordinativo_entrata_ts_id serial ,
    ordinativo_ts_id				integer not null,
	ordinativo_id					integer not null,
	anno_esercizio					integer not null,
	numero_ordinativo				integer not null,
	quota_ordinativo    			integer not null,
	anno_accertamento				integer not null,
	numero_accertamento				integer not null,
	numero_subaccertamento			integer not null,	
	data_scadenza					varchar	(10),	
	descrizione						varchar	(500)	not null,
	importo_iniziale				numeric	DEFAULT 0,
	importo_attuale					numeric	DEFAULT 0,
	anno_documento					integer	,	
	numero_documento				varchar(20),	
	tipo_documento					varchar(10),	
	cod_soggetto_documento			integer ,
	frazione_documento 				integer,
	ente_proprietario_id 			integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	
	CONSTRAINT pk_migr_ordinativo_entrata_ts PRIMARY KEY (migr_ordinativo_entrata_ts_id)
);


CREATE TABLE migr_ordinativo_entrata_ts_scarto (
	migr_ordinativo_entrata_ts_scarto_id 	serial ,
	migr_ordinativo_entrata_ts_id 			integer  NOT NULL,
	numero_ordinativo 						integer  NOT NULL,
	anno_esercizio 							varchar(4) NOT NULL,
	motivo_scarto 							varchar(2500) NOT NULL,
	ente_proprietario_id 					integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_ordinativo_entrata_ts_scarto PRIMARY KEY (migr_ordinativo_entrata_ts_scarto_id)
);


CREATE TABLE siac_r_migr_ordinativo_ts_entrata_ordinativo (
	migr_rel_id serial ,
	migr_ordinativo_entrata_ts_id integer  NOT NULL,
	ord_ts_id integer  NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	ente_proprietario_id integer  NOT NULL,
	CONSTRAINT pk_siac_r_migr_ordinativo_ts_entrata_ordinativo_ts PRIMARY KEY (migr_rel_id),
	CONSTRAINT siac_t_ente_proprietario_r_migr_ordinativo_ts_entrata_ordinativo FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);






-----------------------------------------------------------------------------------------

drop table if exists migr_ordinativo_spesa cascade;
drop table if exists migr_ordinativo_spesa_scarto cascade;
drop table if exists siac_r_migr_ordinativo_spesa_ordinativo cascade;

CREATE TABLE migr_ordinativo_spesa (
	migr_ordinativo_id serial ,
	ordinativo_id integer ,
	anno_esercizio integer ,
	numero_ordinativo integer ,
	numero_capitolo integer  NOT NULL DEFAULT 0,
	numero_articolo integer  NOT NULL DEFAULT 0,
	numero_ueb varchar(50) NOT NULL DEFAULT 1,
	descrizione varchar(500) NOT NULL,
	data_emissione varchar(10) NOT NULL,
	data_annullamento varchar(10),
	data_riduzione varchar(10),
	data_scadenza varchar(10),
	data_spostamento varchar(10),
	data_trasmissione varchar(10),
	stato_operativo varchar(1) NOT NULL,
	codice_distinta varchar(10),
	codice_bollo varchar(10) NOT NULL,
	codice_commissione varchar(10) NOT NULL,
	codice_conto_corrente varchar(10) NOT NULL,
	codice_soggetto integer  NOT NULL,
	codice_modpag integer  NOT NULL,
	anno_provvedimento integer  ,
	numero_provvedimento integer  ,
	tipo_provvedimento varchar(20),
	sac_provvedimento varchar(20),
	oggetto_provvedimento varchar(500),
	note_provvedimento varchar(500),
	stato_provvedimento varchar(50),
	flag_allegato_cart varchar(10),
	note_tesoriere varchar(10),	
	
	comunicazioni_tes varchar(500),
	cup varchar(50),
	cig varchar(50),
	firma_ord_data varchar(10),
	firma_ord varchar(500),
	quietanza_numero varchar(10),
	quietanza_data varchar(10),
	quietanza_importo numeric,
	quietanza_codice_cro varchar(50),
	storno_quiet_numero integer ,
	storno_quiet_data varchar(10),
	storno_quiet_importo numeric,
	cast_competenza numeric NOT NULL DEFAULT 0,
	cast_cassa numeric NOT NULL DEFAULT 0,
	cast_emessi numeric NOT NULL DEFAULT 0,
	utente_creazione varchar(50) NOT NULL,
	utente_modifica varchar(50),
	classificatore_1	varchar(250),
    classificatore_2	varchar(250),
    classificatore_3	varchar(250),
    --classificatore_4	varchar(250),	
	pdc_finanziario varchar(50),
	transazione_ue_spesa varchar(50),
	spesa_ricorrente varchar(50),
	perimetro_sanitario_spesa varchar(50),
	politiche_regionali_unitarie varchar(50),
	pdc_economico_patr varchar(50),	
	cofog	 varchar(50),
	siope_spesa	 varchar(50),		  
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_ordinativo_spesa PRIMARY KEY (migr_ordinativo_id)
);


CREATE TABLE migr_ordinativo_spesa_scarto (
	migr_ordinativo_scarto_id serial ,
	migr_ordinativo_id integer  NOT NULL,
	numero_ordinativo integer  NOT NULL,
	anno_esercizio varchar(4) NOT NULL,
	motivo_scarto varchar(2500) NOT NULL,
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_ordinativo_spesa_scarto PRIMARY KEY (migr_ordinativo_scarto_id)
);


CREATE TABLE siac_r_migr_ordinativo_spesa_ordinativo (
	migr_rel_id serial ,
	migr_ordinativo_id integer  NOT NULL,
	ord_id integer  NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	ente_proprietario_id integer  NOT NULL,
	
	
	CONSTRAINT pk_siac_r_migr_ordinativo_spesa_ordinativo PRIMARY KEY (migr_rel_id),
	CONSTRAINT siac_t_ente_proprietario_r_migr_ordinativo_spesa_ordinativo FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);

-------------------------------------------------------------------------------------------

drop table if exists migr_ordinativo_spesa_ts cascade;
drop table if exists migr_ordinativo_spesa_ts_scarto cascade;
drop table if exists siac_r_migr_ordinativo_ts_spesa_ordinativo cascade;

create table migr_ordinativo_spesa_ts	(
	migr_ordinativo_spesa_ts_id serial ,
    ordinativo_ts_id	integer not null,
	ordinativo_id		integer not null,
	anno_esercizio		integer not null,
	numero_ordinativo	integer not null,
	quota_ordinativo    integer not null,
	anno_impegno        integer not null,
	numero_impegno		integer not null,
	numero_subimpegno	integer not null,
	data_scadenza		varchar	(10),	
	descrizione			varchar	(500)	not null,
	numero_liquidazione	integer not null,
	importo_iniziale	numeric	DEFAULT 0,
	importo_attuale		numeric	DEFAULT 0,
	anno_documento		integer	,	
	numero_documento	varchar(20),	
	tipo_documento		varchar(10),	
	cod_soggetto_documento	integer ,
	frazione_documento      integer	,	
	anno_nota_cred         integer,
	  numero_nota_cred       varchar(20),
	  cod_sogg_nota_cred     integer,
	  frazione_nota_cred    integer,
	  importo_nota_cred      numeric,  
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	
	CONSTRAINT pk_migr_ordinativo_spesa_ts PRIMARY KEY (migr_ordinativo_spesa_ts_id)
);


CREATE TABLE migr_ordinativo_spesa_ts_scarto (
	migr_ordinativo_spesa_ts_scarto_id serial ,
	ordinativo_scarto_ts_id integer  NOT NULL,
	numero_ordinativo integer  NOT NULL,
	anno_esercizio varchar(4) NOT NULL,
	motivo_scarto varchar(2500) NOT NULL,
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_ordinativo_spesa_ts_scarto PRIMARY KEY (migr_ordinativo_spesa_ts_scarto_id)
);


CREATE TABLE siac_r_migr_ordinativo_ts_spesa_ordinativo (
	migr_rel_id serial ,
	migr_ordinativo_ts_id integer  NOT NULL,
	ord_ts_id integer  NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	ente_proprietario_id integer  NOT NULL,
	CONSTRAINT pk_siac_r_migr_ordinativo_ts_spesa_ordinativo_ts PRIMARY KEY (migr_rel_id),
	CONSTRAINT siac_t_ente_proprietario_r_migr_ordinativo_ts_spesa_ordinativo FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);





--------------------------------------------------------------------------------------------

drop table if exists migr_provv_cassa cascade;
drop table if exists migr_provv_cassa_scarto cascade;
drop table if exists siac_r_migr_prov_cassa_prov_cassa cascade;

CREATE TABLE migr_provv_cassa (
	migr_provvisorio_id serial ,
	provvisorio_id integer  NOT NULL,
	tipo_eu varchar(1) NOT NULL,
	anno_provvisorio integer  NOT NULL,
	numero_provvisorio integer  NOT NULL,
	causale varchar(500),
	sub_causale varchar(500),
	data_emissione varchar(10) NOT NULL,
	importo numeric NOT NULL DEFAULT 0,
	denominazione_soggetto varchar(500),
	data_annullamento varchar(10),
	data_regolarizzazione varchar(10),
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_provv_cassa PRIMARY KEY (migr_provvisorio_id)
);


CREATE TABLE migr_provv_cassa_scarto (
	migr_provvisorio_scarto_id serial ,
	migr_provvisorio_id integer  NOT NULL,
	numero_provvisorio integer  NOT NULL,
	anno_esercizio varchar(4) NOT NULL,
	motivo_scarto varchar(2500) NOT NULL,
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_provv_cassa_scarto PRIMARY KEY (migr_provvisorio_scarto_id)
);


CREATE TABLE siac_r_migr_prov_cassa_prov_cassa (
	migr_rel_id serial ,
	migr_provvisorio_id integer  NOT NULL,
	provc_id integer  NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	ente_proprietario_id integer  NOT NULL,
	CONSTRAINT pk_siac_r_migr_prov_cassa_prov_cassa PRIMARY KEY (migr_rel_id),
	CONSTRAINT siac_t_ente_proprietario_r_siac_r_migr_prov_cassa_prov_cassa FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);


--------------------------------------------------------------------------------------------------------------

drop table if exists migr_provv_cassa_ordinativo cascade;
drop table if exists migr_provv_cassa_ordinativo_scarto cascade;
drop table if exists siac_r_migr_prov_cassa_ordinativo_siac_r_ordinativo_prov_cassa cascade;

CREATE TABLE migr_provv_cassa_ordinativo (
	migr_provvisorio_ord_id serial ,
	provvisorio_id integer  NOT NULL,
	tipo_eu varchar(1) NOT NULL,
	ordinativo_id integer  NOT NULL,
	ord_numero	integer  NOT NULL,
	anno_esercizio	integer  NOT NULL,
	anno_provvisorio	integer  NOT NULL,
	numero_provvisorio	integer  NOT NULL,
	importo numeric NOT NULL DEFAULT 0,
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_provv_cassa_ordinativo PRIMARY KEY (migr_provvisorio_ord_id)
);






CREATE TABLE migr_provv_cassa_ordinativo_scarto (
	migr_provvisorio_ordinativo_scarto_id serial ,
	migr_provvisorio_ord_id integer  NOT NULL,
	anno_esercizio	      integer  NOT NULL,
    ordinativo_id         integer  NOT NULL,
	provvisorio_id        integer  NOT NULL,
	tipo_eu               varchar(1)    not null,
	motivo_scarto varchar(2500) NOT NULL,
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_provv_cassa_ordinativo_scarto PRIMARY KEY (migr_provvisorio_ordinativo_scarto_id)
);


CREATE TABLE siac_r_migr_prov_cassa_ordinativo_siac_r_ordinativo_prov_cassa (
	migr_rel_id serial ,
	migr_provvisorio_ord_id integer  NOT NULL,
	ord_provc_id integer  NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	ente_proprietario_id integer  NOT NULL,
	CONSTRAINT pk_siac_r_migr_prov_cassa_ordinativo_siac_r_ordinativo_prov_cas PRIMARY KEY (migr_rel_id),
	CONSTRAINT siac_t_ente_proprietario_r_migr_prov_cassa_ordinativo_siac_r_or FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);


-------------------------------------------------------------------------------------------------

drop table if exists migr_ordinativo_relaz cascade;
drop table if exists siac_r_migr_ordinativo_relaz_siac_r_ordinativo cascade;

CREATE TABLE migr_ordinativo_relaz (
	migr_ordinativo_relaz_id serial ,
	ordinativo_id_da integer  NOT NULL,
	tipo_ord_da varchar(1) NOT NULL,
	ordinativo_id_a varchar(10) NOT NULL,
	tipo_ord_a varchar(1) NOT NULL,
	tipo_relaz varchar(50) NOT NULL,
	numero_da integer  NOT NULL,
	anno_esercizio_da integer  NOT NULL,
	numero_a integer  NOT NULL,
	anno_esercizio_a integer  NOT NULL,
	ente_proprietario_id integer  NOT NULL,
	fl_elab bpchar(1) NOT NULL DEFAULT 'N'::bpchar,
	data_creazione timestamp NOT NULL DEFAULT now(),
	CONSTRAINT pk_migr_ordinativo_relaz PRIMARY KEY (migr_ordinativo_relaz_id)
);



--MANCA LA SCARTO

CREATE TABLE siac_r_migr_ordinativo_relaz_siac_r_ordinativo (
	migr_rel_id serial ,
	migr_ordinativo_relaz_id integer  NOT NULL,
	ord_id integer  NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	ente_proprietario_id integer  NOT NULL,
	CONSTRAINT pk_siac_r_migr_ordinativo_relaz_siac_r_ordinativo PRIMARY KEY (migr_rel_id),
	CONSTRAINT siac_t_ente_proprietario_r_siac_r_migr_ordinativo_relaz_siac_r_ FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);

