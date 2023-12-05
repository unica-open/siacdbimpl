/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- Drop table


DROP TABLE siac.pagopa_t_iqs2_riconciliazione;
DROP TABLE siac.siac_t_file_pagopa_iqs2;
DROP TABLE siac.pagopa_d_iqs2_riconciliazione_errore;
DROP TABLE siac.siac_d_file_pagopa_iqs2_stato;
DROP TABLE siac.pagopa_r_iqs2_configura_sac;


-- siac.siac_d_file_pagopa_iqs2_stato definition

-- DROP TABLE siac.siac_d_file_pagopa_iqs2_stato;
CREATE TABLE siac.siac_d_file_pagopa_iqs2_stato (
	file_pagopa_iqs2_stato_id serial4 NOT NULL,
	file_pagopa_iqs2_stato_code varchar(200) NOT NULL,
	file_pagopa_iqs2_stato_desc varchar(500) NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_file_pagopa_iqs2_stato PRIMARY KEY (file_pagopa_iqs2_stato_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_file_pagopa_iqs2_stato FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE UNIQUE INDEX idx_siac_d_file_pagopa_iqs2_stato_1 ON siac.siac_d_file_pagopa_iqs2_stato USING btree (file_pagopa_iqs2_stato_code, validita_inizio, ente_proprietario_id) WHERE (data_cancellazione IS NULL);
CREATE INDEX siac_d_file_iqs2_pagopa_stato_fk_ente_proprietario_id_idx ON siac.siac_d_file_pagopa_iqs2_stato USING btree (ente_proprietario_id);

alter table siac.siac_d_file_pagopa_iqs2_stato owner to siac;



-- siac.pagopa_d_iqs2_riconciliazione_errore definition

-- Drop table

-- DROP TABLE siac.pagopa_d_iqs2_riconciliazione_errore;

CREATE TABLE siac.pagopa_d_iqs2_riconciliazione_errore (
	pagopa_iqs2_ric_errore_id serial4 NOT NULL,
	pagopa_iqs2_ric_errore_code varchar(200) NOT NULL,
	pagopa_iqs2_ric_errore_desc varchar(500) NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_pagopa_d_iqs2_ric_errore PRIMARY KEY (pagopa_iqs2_ric_errore_id),
	CONSTRAINT siac_t_ente_proprietario_pagopa_d_iqs2_ric_errore FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE UNIQUE INDEX idx_pagopa_d_iqs2_ric_errore_1 ON siac.pagopa_d_iqs2_riconciliazione_errore USING btree (pagopa_iqs2_ric_errore_code, validita_inizio, ente_proprietario_id) WHERE (data_cancellazione IS NULL);
CREATE INDEX pagopa_d_iqs2_ric_errore_stato_fk_ente_proprietario_id_idx ON siac.pagopa_d_iqs2_riconciliazione_errore USING btree (ente_proprietario_id);

alter table siac.pagopa_d_iqs2_riconciliazione_errore owner to siac;


      
-- siac.pagopa_r_iqs2_configura_sac definition

-- Drop table

-- DROP TABLE siac.pagopa_r_iqs2_configura_sac;

CREATE TABLE siac.pagopa_r_iqs2_configura_sac 
(
  	pagopa_iqs2_conf_sac_id serial4 NOT NULL,
	pagopa_iqs2_conf_sac_code varchar(200) NOT NULL,
	classif_id integer not null,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_pagopa_r_iqs2_conf_sac PRIMARY KEY (pagopa_iqs2_conf_sac_id),
	CONSTRAINT siac_t_class_pagopa_r_iqs2_conf_sac FOREIGN KEY (classif_id) REFERENCES siac.siac_t_class(classif_id),
	CONSTRAINT siac_t_ente_proprietario_pagopa_r_iqs2_conf_sac FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX pagopa_r_iqs2_conf_sac_fk_ente_proprietario_id_idx ON siac.pagopa_r_iqs2_configura_sac USING btree (ente_proprietario_id);
create UNIQUE INDEX pagopa_r_iqs2_conf_sac_fk_conf_sac_code_idx ON siac.pagopa_r_iqs2_configura_sac USING btree (pagopa_iqs2_conf_sac_id,ente_proprietario_id);
CREATE INDEX pagopa_r_iqs2_conf_sac_fk_classif_id_idx ON siac.pagopa_r_iqs2_configura_sac USING btree (classif_id);

alter table siac.pagopa_r_iqs2_configura_sac owner to siac;

-- siac.siac_t_file_pagopa_iqs2 definition

-- Drop table

-- DROP TABLE siac.siac_t_file_pagopa_iqs2;

CREATE TABLE siac.siac_t_file_pagopa_iqs2 (
	file_pagopa_iqs2_id serial4 NOT NULL,
	file_pagopa_iqs2_size int4 NOT NULL,
	file_pagopa_iqs2_note varchar NULL,
	file_pagopa_iqs2_nome_file varchar NOT NULL,
	file_pagopa_iqs2_anno int4 NOT NULL,
	file_pagopa_iqs2_stato_id int4 NOT NULL,
	file_pagopa_iqs2_errore_id int4 NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_t_file_pagopa_iqs2 PRIMARY KEY (file_pagopa_iqs2_id),
	CONSTRAINT pagopa_d_iqs2_riconciliazione_errore_siac_t_file_pagopa_iqs2 FOREIGN KEY (file_pagopa_iqs2_errore_id) REFERENCES siac.pagopa_d_iqs2_riconciliazione_errore(pagopa_iqs2_ric_errore_id),
	CONSTRAINT siac_d_file_pagopa_iqs2_stato_siac_t_file_pagopa_iqs2 FOREIGN KEY (file_pagopa_iqs2_stato_id) REFERENCES siac.siac_d_file_pagopa_iqs2_stato(file_pagopa_iqs2_stato_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_file_pagopa_iqs2 FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX siac_t_file_pagopa_iqs2_anno_idx ON siac.siac_t_file_pagopa_iqs2 USING btree (file_pagopa_iqs2_anno);
CREATE INDEX siac_t_file_pagopa_iqs2_fk_ente_proprietario_id_idx ON siac.siac_t_file_pagopa_iqs2 USING btree (ente_proprietario_id);
CREATE INDEX siac_t_file_pagopa_iqs2_fk_file_pagopa_stato_id_idx ON siac.siac_t_file_pagopa_iqs2 USING btree (file_pagopa_iqs2_stato_id);

alter table siac.siac_t_file_pagopa_iqs2 owner to siac;

-- siac.pagopa_t_iqs2_riconciliazione definition

-- Drop table

-- DROP TABLE siac.pagopa_t_iqs2_riconciliazione;

CREATE TABLE siac.pagopa_t_iqs2_riconciliazione (
	pagopa_iqs2_ric_id serial4 NOT NULL,
	pagopa_iqs2_ric_data timestamp NOT NULL DEFAULT now(),
	pagopa_iqs2_ric_codice_sia	varchar null,
    pagopa_iqs2_ric_progr	 integer null,
    pagopa_iqs2_ric_cf_pa_benef	varchar null,
    pagopa_iqs2_ric_cf_pa_titolare	varchar null,
    pagopa_iqs2_ric_num_avviso	varchar null,
    pagopa_iqs2_ric_indice_avviso	varchar null,
    pagopa_iqs2_ric_id_psp	varchar null,
    pagopa_iqs2_ric_codice_trans	varchar null,
    pagopa_iqs2_ric_tipo_op	varchar null,
    pagopa_iqs2_ric_tipo_info	varchar null,
    pagopa_iqs2_ric_causale	varchar null,
    pagopa_iqs2_ric_importo_tot	numeric null,
    pagopa_iqs2_ric_cf_debitore	varchar null,
    pagopa_iqs2_ric_nome_debitore	varchar null,
    pagopa_iqs2_ric_nome_pa_titolare	varchar null,
    pagopa_iqs2_ric_desc_psp	varchar null,
    pagopa_iqs2_ric_data_pagamento	timestamp null,
    pagopa_iqs2_ric_data_psp	timestamp null,
    pagopa_iqs2_ric_data_riv	timestamp null,
    pagopa_iqs2_ric_importo_qt	numeric null,
    pagopa_iqs2_ric_causale_qt	varchar null,
    pagopa_iqs2_ric_tassonomia_qt		varchar null,
    pagopa_iqs2_ric_iban_qt		varchar null,
    pagopa_iqs2_ric_flusso_id_riv		varchar null,
    pagopa_iqs2_ric_data_riconc	timestamp null,
    pagopa_iqs2_ric_anno_eserc	integer null,
    pagopa_iqs2_ric_num_prov	integer null,
    pagopa_iqs2_ric_anno_accertamento	integer null,
    pagopa_iqs2_ric_num_accertamento	integer null,
    pagopa_iqs2_ric_associa_sac varchar null,
    pagopa_iqs2_ric_fl_elab_upload boolean NOT NULL DEFAULT FALSE,
    pagopa_iqs2_ric_stato_elab varchar NOT NULL DEFAULT 'N'::character varying,
	pagopa_iqs2_ric_errore_id integer NULL,
    file_pagopa_iqs2_id integer not null,
    login_operazione varchar(200) NOT null,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	pagopa_iqs2_ric_fl_elab_upload bool NOT NULL DEFAULT false,
	CONSTRAINT pk_pagopa_t_iqs2_riconciliazione PRIMARY KEY (pagopa_iqs2_ric_id),
	CONSTRAINT pagopa_d_iqs2_ric_err_pagopa_t_iqs2_riconciliazione FOREIGN KEY (pagopa_iqs2_ric_errore_id) REFERENCES siac.pagopa_d_iqs2_riconciliazione_errore(pagopa_iqs2_ric_errore_id),
	CONSTRAINT siac_t_ente_proprietario_pagopa_t_iqs2_riconciliazione FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_file_pagopa_iqs2_pagopa_t_iqs2_riconciliazione FOREIGN KEY (file_pagopa_iqs2_id) REFERENCES siac.siac_t_file_pagopa_iqs2(file_pagopa_iqs2_id)
);
CREATE INDEX pagopa_t_iqs2_riconciliazione_accertamento_idx ON siac.pagopa_t_iqs2_riconciliazione USING btree (pagopa_iqs2_ric_anno_eserc, pagopa_iqs2_ric_anno_accertamento, pagopa_iqs2_ric_num_accertamento, file_pagopa_iqs2_id);
CREATE INDEX pagopa_t_iqs2_riconciliazione_fk_ente_proprietario_id_idx ON siac.pagopa_t_iqs2_riconciliazione USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_iqs2_riconciliazione_fk_file_pagopa_iqs2_id_idx ON siac.pagopa_t_iqs2_riconciliazione USING btree (file_pagopa_iqs2_id);
CREATE INDEX pagopa_t_iqs2_riconciliazione_provvisorio_idx ON siac.pagopa_t_iqs2_riconciliazione USING btree (pagopa_iqs2_ric_anno_eserc, pagopa_iqs2_ric_num_prov, file_pagopa_iqs2_id);
CREATE INDEX pagopa_t_iqs2_riconciliazione_ric_errore_id_idx ON siac.pagopa_t_iqs2_riconciliazione USING btree (pagopa_iqs2_ric_errore_id);

alter table siac.pagopa_t_iqs2_riconciliazione owner to siac;