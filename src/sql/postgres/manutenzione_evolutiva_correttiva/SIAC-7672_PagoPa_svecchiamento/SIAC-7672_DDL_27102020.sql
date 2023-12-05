/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
--svecchia_pagopa_t_parametri

drop table if exists siac.pagopa_d_elaborazione_svecchia_tipo;
CREATE TABLE siac.pagopa_d_elaborazione_svecchia_tipo
(
  pagopa_elab_svecchia_tipo_id SERIAL,
  pagopa_elab_svecchia_tipo_code VARCHAR(50) NOT NULL,
  pagopa_elab_svecchia_tipo_desc VARCHAR(200) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  pagopa_elab_svecchia_tipo_fl_attivo boolean default false not null,
  pagopa_elab_svecchia_tipo_fl_back boolean default true not null,
  pagopa_elab_svecchia_delta_giorni integer,
  CONSTRAINT pk_pagopa_d_elaborazione_svecchia_tipo PRIMARY KEY(pagopa_elab_svecchia_tipo_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_d_elaborazione_svecchia_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE siac.pagopa_d_elaborazione_svecchia_tipo
IS 'Tipologie di svecchiamenti PAGOPA.';

alter table siac.pagopa_d_elaborazione_svecchia_tipo owner to siac;


drop table if exists siac.pagopa_t_elaborazione_svecchia;
CREATE TABLE siac.pagopa_t_elaborazione_svecchia
(
  pagopa_elab_svecchia_id SERIAL,
  pagopa_elab_svecchia_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_elab_svecchia_note VARCHAR(1500) NOT NULL,
  pagopa_elab_svecchia_tipo_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_elaborazione_svecchia PRIMARY KEY(pagopa_elab_svecchia_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elaborazione_svecchia FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_elaborazione_svecchia_pagopa_t_elaborazione_svecchia FOREIGN KEY (pagopa_elab_svecchia_tipo_id)
    REFERENCES siac.pagopa_d_elaborazione_svecchia_tipo(pagopa_elab_svecchia_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE siac.pagopa_t_elaborazione_svecchia
IS 'Elaborazioni di svecchiamento PAGOPA.';

alter table siac.pagopa_t_elaborazione_svecchia owner to siac;


insert into pagopa_d_elaborazione_svecchia_tipo
(
  pagopa_elab_svecchia_tipo_code,
  pagopa_elab_svecchia_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  pagopa_elab_svecchia_tipo_fl_attivo,
  pagopa_elab_svecchia_tipo_fl_back
)
select
  'PUNTUALE',
  'SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE',
   now(),
   ente.ente_proprietario_id,
   'SIAC-7672',
   false,
   true

from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists
(
select  1
from pagopa_d_elaborazione_svecchia_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.pagopa_elab_svecchia_tipo_code ='PUNTUALE'
);

insert into pagopa_d_elaborazione_svecchia_tipo
(
  pagopa_elab_svecchia_tipo_code,
  pagopa_elab_svecchia_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  pagopa_elab_svecchia_tipo_fl_attivo,
  pagopa_elab_svecchia_tipo_fl_back,
  pagopa_elab_svecchia_delta_giorni
)
select
  'PERIODICO',
  'SVECCHIAMENTO PERIODICO ELAB. CONCLUSE CON SUCCESSO',
   now(),
   ente.ente_proprietario_id,
   'SIAC-7672',
   false,
   true,
   30
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists
(
select  1
from pagopa_d_elaborazione_svecchia_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.pagopa_elab_svecchia_tipo_code ='PERIODICO'
);

select * from pagopa_d_elaborazione_svecchia_tipo
--pagopa_t_riconciliazione_doc
--pagopa_t_elaborazione_flusso
--pagopa_r_elaborazione_file
--pagopa_t_elaborazione
drop table if exists siac.pagopa_t_bck_riconciliazione_doc;
create table siac.pagopa_t_bck_riconciliazione_doc
(
  pagopa_bck_ric_doc_id serial,
  pagopa_ric_doc_id integer,
  pagopa_ric_doc_data TIMESTAMP,
  pagopa_ric_doc_voce_code VARCHAR,
  pagopa_ric_doc_voce_desc VARCHAR,
  pagopa_ric_doc_voce_tematica VARCHAR,
  pagopa_ric_doc_sottovoce_code VARCHAR,
  pagopa_ric_doc_sottovoce_desc VARCHAR,
  pagopa_ric_doc_sottovoce_importo NUMERIC,
  pagopa_ric_doc_anno_esercizio INTEGER,
  pagopa_ric_doc_anno_accertamento INTEGER,
  pagopa_ric_doc_num_accertamento INTEGER,
  pagopa_ric_doc_num_capitolo INTEGER,
  pagopa_ric_doc_num_articolo INTEGER,
  pagopa_ric_doc_pdc_v_fin VARCHAR,
  pagopa_ric_doc_titolo VARCHAR,
  pagopa_ric_doc_tipologia VARCHAR,
  pagopa_ric_doc_categoria VARCHAR,
  pagopa_ric_doc_codice_benef VARCHAR,
  pagopa_ric_doc_str_amm VARCHAR,
  pagopa_ric_doc_subdoc_id INTEGER,
  pagopa_ric_doc_provc_id INTEGER,
  pagopa_ric_doc_movgest_ts_id INTEGER,
  pagopa_ric_doc_stato_elab VARCHAR,
  pagopa_ric_errore_id INTEGER,
  pagopa_ric_id INTEGER,
  pagopa_elab_flusso_id INTEGER,
  file_pagopa_id INTEGER NOT NULL,
  pagopa_elab_svecchia_id integer not null,
  bck_validita_inizio TIMESTAMP,
  bck_validita_fine TIMESTAMP,
  bck_data_creazione TIMESTAMP,
  bck_data_modifica TIMESTAMP,
  bck_data_cancellazione TIMESTAMP,
  bck_login_operazione VARCHAR(200),
  pagopa_ric_doc_ragsoc_benef VARCHAR,
  pagopa_ric_doc_nome_benef VARCHAR,
  pagopa_ric_doc_cognome_benef VARCHAR,
  pagopa_ric_doc_codfisc_benef VARCHAR,
  pagopa_ric_doc_soggetto_id INTEGER,
  pagopa_ric_doc_flag_dett BOOLEAN,
  pagopa_ric_doc_flag_con_dett BOOLEAN ,
  pagopa_ric_doc_tipo_code VARCHAR,
  pagopa_ric_doc_tipo_id INTEGER,
  pagopa_ric_det_id INTEGER,
  pagopa_ric_doc_iuv VARCHAR(100),
  pagopa_ric_doc_data_operazione TIMESTAMP,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine   TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id integer not null,
  CONSTRAINT pk_pagopa_bck_pagopa_t_riconciliazione_doc PRIMARY KEY(pagopa_bck_ric_doc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_pagopa_t_riconc_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT pagopa_t_elab_svecchia_pagopa_bck_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_elab_svecchia_id)
    REFERENCES siac.pagopa_t_elaborazione_svecchia(pagopa_elab_svecchia_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

drop table if exists siac.pagopa_t_bck_elaborazione_flusso;
create table siac.pagopa_t_bck_elaborazione_flusso
(
  pagopa_bck_elab_flusso_id serial,
  pagopa_elab_flusso_id integer,
  pagopa_elab_flusso_data TIMESTAMP,
  pagopa_elab_flusso_stato_id INTEGER,
  pagopa_elab_flusso_note VARCHAR(750),
  pagopa_elab_ric_flusso_id VARCHAR,
  pagopa_elab_flusso_nome_mittente VARCHAR,
  pagopa_elab_ric_flusso_data VARCHAR,
  pagopa_elab_flusso_tot_pagam NUMERIC,
  pagopa_elab_flusso_anno_esercizio INTEGER,
  pagopa_elab_flusso_anno_provvisorio INTEGER,
  pagopa_elab_flusso_num_provvisorio INTEGER,
  pagopa_elab_flusso_provc_id INTEGER,
  pagopa_elab_id INTEGER,
  pagopa_elab_svecchia_id integer,
  bck_validita_inizio TIMESTAMP,
  bck_validita_fine TIMESTAMP,
  bck_data_creazione TIMESTAMP,
  bck_data_modifica TIMESTAMP,
  bck_data_cancellazione TIMESTAMP,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_pagopa_t_elaborazione_flusso PRIMARY KEY(pagopa_bck_elab_flusso_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_pagopa_t_elab_flusso FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elab_svecchia_pagopa_bck_pagopa_t_elaborazione_flusso FOREIGN KEY (pagopa_elab_svecchia_id)
    REFERENCES siac.pagopa_t_elaborazione_svecchia(pagopa_elab_svecchia_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

drop table if exists siac.pagopa_r_bck_elaborazione_file;
create table siac.pagopa_r_bck_elaborazione_file
(
  pagopa_bck_r_elab_id serial,
  pagopa_r_elab_id integer,
  pagopa_elab_id INTEGER,
  file_pagopa_id INTEGER,
  bck_validita_inizio TIMESTAMP,
  bck_validita_fine TIMESTAMP,
  bck_data_creazione TIMESTAMP,
  bck_data_modifica TIMESTAMP,
  bck_data_cancellazione TIMESTAMP,
  bck_login_operazione VARCHAR(200),
  pagopa_elab_svecchia_id integer,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER,
  CONSTRAINT pk_pagopa_bck_pagopa_r_elaborazione_file PRIMARY KEY(pagopa_bck_r_elab_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_pagopa_r_elaborazione_file FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT pagopa_t_elab_svecchia_pagopa_bck_r_elaborazione_file FOREIGN KEY (pagopa_elab_svecchia_id)
    REFERENCES siac.pagopa_t_elaborazione_svecchia(pagopa_elab_svecchia_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

drop table if exists siac.pagopa_t_bck_elaborazione;
create table siac.pagopa_t_bck_elaborazione
(
  pagopa_bck_elab_id Serial,
  pagopa_elab_id integer,
  pagopa_elab_data TIMESTAMP,
  pagopa_elab_stato_id INTEGER,
  pagopa_elab_note VARCHAR(1500),
  pagopa_elab_file_id VARCHAR(250),
  pagopa_elab_file_ora VARCHAR(250),
  pagopa_elab_file_ente VARCHAR(250),
  pagopa_elab_file_fruitore VARCHAR(250),
  file_pagopa_id INTEGER,
  pagopa_elab_errore_id INTEGER,
  pagopa_elab_svecchia_id integer,
  bck_validita_inizio TIMESTAMP,
  bck_validita_fine TIMESTAMP,
  bck_data_creazione TIMESTAMP,
  bck_data_modifica TIMESTAMP,
  bck_data_cancellazione TIMESTAMP,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
CONSTRAINT pk_pagopa_bck_pagopa_t_elaborazione PRIMARY KEY(pagopa_bck_elab_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_pagopa_t_elaborazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT pagopa_t_elab_svecchia_pagopa_bck_t_elaborazione FOREIGN KEY (pagopa_elab_svecchia_id)
    REFERENCES siac.pagopa_t_elaborazione_svecchia(pagopa_elab_svecchia_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE TABLE IF NOT EXISTS siac.siac_t_bck_file_pagopa (
	file_bck_pagopa_id serial NOT NULL,
	pagopa_elab_svecchia_id int4 NULL,
	file_pagopa_id int4 NULL,
	file_pagopa_size numeric NOT NULL,
	file_pagopa bytea NULL,
	file_pagopa_code varchar NOT NULL,
	file_pagopa_note varchar NULL,
	file_pagopa_anno int4 NOT NULL,
	file_pagopa_stato_id int4 NOT NULL,
	file_pagopa_errore_id int4 NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	file_pagopa_id_psp varchar NULL,
	file_pagopa_id_flusso varchar null
   );	
   

CREATE TABLE IF NOT EXISTS siac.pagopa_t_bck_riconciliazione (
	pagopa_ric_bck_ric_id serial NOT NULL,
	pagopa_elab_svecchia_id int4 NULL,
	pagopa_ric_id int4 NOT NULL,
	pagopa_ric_data timestamp NOT NULL DEFAULT now(),
	pagopa_ric_file_id varchar NULL, 
	pagopa_ric_file_ora timestamp NULL, 
	pagopa_ric_file_ente varchar NULL, 
	pagopa_ric_file_fruitore varchar NULL, 
	pagopa_ric_file_num_flussi int4 NULL, 
	pagopa_ric_file_tot_flussi numeric NULL, 
	pagopa_ric_flusso_id varchar NULL, 
	pagopa_ric_flusso_nome_mittente varchar NULL,
	pagopa_ric_flusso_data timestamp NULL,
	pagopa_ric_flusso_tot_pagam numeric NULL,
	pagopa_ric_flusso_anno_esercizio int4 NULL, 
	pagopa_ric_flusso_anno_provvisorio int4 NULL, 
	pagopa_ric_flusso_num_provvisorio int4 NULL,
	pagopa_ric_flusso_voce_code varchar NULL, 
	pagopa_ric_flusso_voce_desc varchar NULL,
	pagopa_ric_flusso_tematica varchar NULL,
	pagopa_ric_flusso_sottovoce_code varchar NULL, 
	pagopa_ric_flusso_sottovoce_desc varchar NULL,
	pagopa_ric_flusso_sottovoce_importo numeric NULL, 
	pagopa_ric_flusso_anno_accertamento int4 NULL, 
	pagopa_ric_flusso_num_accertamento int4 NULL, 
	pagopa_ric_flusso_num_capitolo int4 NULL,
	pagopa_ric_flusso_num_articolo int4 NULL,
	pagopa_ric_flusso_pdc_v_fin varchar NULL,
	pagopa_ric_flusso_titolo varchar NULL,
	pagopa_ric_flusso_tipologia varchar NULL,
	pagopa_ric_flusso_categoria varchar NULL,
	pagopa_ric_flusso_codice_benef varchar NULL,
	pagopa_ric_flusso_str_amm varchar NULL,
	file_pagopa_id int4 NOT NULL, 
	pagopa_ric_flusso_stato_elab varchar NOT NULL DEFAULT 'N'::character varying,
	pagopa_ric_errore_id int4 NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	pagopa_ric_flusso_ragsoc_benef varchar NULL,
	pagopa_ric_flusso_nome_benef varchar NULL,
	pagopa_ric_flusso_cognome_benef varchar NULL,
	pagopa_ric_flusso_codfisc_benef varchar null
	);
	
	

CREATE TABLE IF NOT EXISTS siac.pagopa_t_bck_riconciliazione_det (
	pagopa_ric_bck_det_id serial NOT NULL,
	pagopa_elab_svecchia_id int4 NULL,
	pagopa_ric_det_id int4 NOT NULL,
	pagopa_det_anag_cognome varchar NULL,
	pagopa_det_anag_nome varchar NULL,
	pagopa_det_anag_ragione_sociale varchar NULL,
	pagopa_det_anag_codice_fiscale varchar NULL,
	pagopa_det_anag_indirizzo varchar NULL,
	pagopa_det_anag_civico varchar NULL,
	pagopa_det_anag_cap varchar(5) NULL,
	pagopa_det_anag_localita varchar NULL,
	pagopa_det_anag_provincia varchar NULL,
	pagopa_det_anag_nazione varchar NULL,
	pagopa_det_anag_email varchar NULL,
	pagopa_det_causale_versamento_desc varchar NULL,
	pagopa_det_causale varchar NULL,
	pagopa_det_data_pagamento timestamp NULL,
	pagopa_det_esito_pagamento varchar NULL,
	pagopa_det_importo_versamento numeric NULL,
	pagopa_det_indice_versamento int4 NULL,
	pagopa_det_transaction_id varchar NULL,
	pagopa_det_versamento_id varchar NULL,
	pagopa_det_riscossione_id varchar NULL,
	pagopa_ric_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT null
	);
	
	
	
CREATE TABLE IF NOT EXISTS siac.pagopa_t_bck_elaborazione_log (
	pagopa_elab_bck_log_id serial NOT NULL,
	pagopa_elab_svecchia_id int4 NULL,
	pagopa_elab_log_id int4 NOT NULL,
	pagopa_elab_id int4 NULL,
	pagopa_elab_file_id int4 NULL,
	pagopa_elab_log_operazione varchar(2500) NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	ente_proprietario_id int4 NOT NULL,
	login_operazione varchar(200) NOT null
	);

alter table siac.pagopa_t_bck_riconciliazione_doc owner to siac;
alter table siac.pagopa_t_bck_elaborazione_flusso owner to siac;
alter table siac.pagopa_r_bck_elaborazione_file owner to siac;
alter table siac.pagopa_t_bck_elaborazione owner to siac;
alter table siac.siac_t_bck_file_pagopa owner to siac;
alter table siac.pagopa_t_bck_riconciliazione owner to siac;
alter table siac.pagopa_t_bck_riconciliazione_det owner to siac;
alter table siac.pagopa_t_bck_elaborazione_log owner to siac;
