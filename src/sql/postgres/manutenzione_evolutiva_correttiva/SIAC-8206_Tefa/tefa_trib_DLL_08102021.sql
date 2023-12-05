/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table siac.siac_t_tefa_trib_importi;
create table siac.siac_t_tefa_trib_importi
(
tefa_trib_id serial,
tefa_trib_tipo_record varchar(50),
tefa_trib_data_ripart varchar(50), -- timestamp
tefa_trib_progr_ripart varchar(250)	,
tefa_trib_provincia_code varchar(100),
tefa_trib_ente_code      varchar(100),
tefa_trib_data_bonifico varchar(50), -- timestamp
tefa_trib_progr_trasm  varchar(250),
tefa_trib_progr_delega varchar(250),
tefa_trib_progr_modello varchar(250) ,
tefa_trib_tipo_modello varchar(100)	,
tefa_trib_comune_code varchar(100),
tefa_trib_tributo_code varchar(100),
tefa_trib_valuta  varchar(50),
tefa_trib_importo_versato_deb numeric,
tefa_trib_importo_compensato_cred numeric,
tefa_trib_numero_immobili varchar(100),
tefa_trib_rateazione      varchar(100),
tefa_trib_anno_rif        varchar(50),
tefa_trib_anno_rif_str    varchar(50),
tefa_trib_file_id         integer  not null, -- dovrebbero essere del FK
tefa_nome_file            varchar(255) not null, 
validita_inizio  TIMESTAMP WITHOUT TIME ZONE  NOT NULL default now(),
validita_fine    TIMESTAMP WITHOUT TIME ZONE,
data_creazione   TIMESTAMP WITHOUT TIME ZONE NOT NULL default now(),
data_modifica    TIMESTAMP WITHOUT TIME ZONE,
data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
login_operazione varchar(250),
ente_proprietario_id integer not null,
CONSTRAINT pk_siac_t_tefa_trib PRIMARY KEY(tefa_trib_id),
CONSTRAINT siac_t_ente_proprietario_siac_t_tefa_trib_imp FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_t_file_siac_t_tefa_trib_imp FOREIGN KEY (tefa_trib_file_id)
    REFERENCES siac.siac_t_file(file_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
	
);

COMMENT ON COLUMN siac.siac_t_tefa_trib_importi.tefa_trib_file_id
IS 'Upload ID a raggruppamento caricamento n-files - ZIP in  siac_t_file.file_id ';

COMMENT ON COLUMN siac.siac_t_tefa_trib_importi.tefa_nome_file
IS 'Identificativo file - nome singolo file contenuto nello zip';

CREATE INDEX siac_t_tefa_trib_fk_ente_proprietario_id_idx ON siac.siac_t_tefa_trib_importi
  USING btree (ente_proprietario_id);

CREATE INDEX siac_t_tefa_trib_fk_upload_id_idx ON siac.siac_t_tefa_trib_importi
  USING btree (tefa_trib_file_id);




drop table siac.siac_d_tefa_trib_tipologia;
create table siac.siac_d_tefa_trib_tipologia
(
tefa_trib_tipologia_id serial,
tefa_trib_tipologia_code varchar(50),
tefa_trib_tipologia_desc varchar(250),
validita_inizio  TIMESTAMP WITHOUT TIME ZONE  NOT NULL default now(),
validita_fine    TIMESTAMP WITHOUT TIME ZONE,
data_creazione   TIMESTAMP WITHOUT TIME ZONE NOT NULL default now(),
data_modifica    TIMESTAMP WITHOUT TIME ZONE,
data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
login_operazione varchar(250),
ente_proprietario_id integer not null,
CONSTRAINT pk_siac_d_tefa_trib_tipo PRIMARY KEY(tefa_trib_tipologia_id),
CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_d_tefa_trib_tipologia_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_trib_tipologia
USING btree (ente_proprietario_id);


drop table siac.siac_d_tefa_trib_gruppo_tipo;
create table siac.siac_d_tefa_trib_gruppo_tipo
(
tefa_trib_gruppo_tipo_id serial,
tefa_trib_gruppo_tipo_code varchar(10),
tefa_trib_gruppo_tipo_desc varchar(50),
tefa_trib_gruppo_tipo_f1_id   integer,
tefa_trib_gruppo_tipo_f2_id   integer,
tefa_trib_gruppo_tipo_f3_id   integer,
validita_inizio  TIMESTAMP WITHOUT TIME ZONE  NOT NULL default now(),
validita_fine    TIMESTAMP WITHOUT TIME ZONE,
data_creazione   TIMESTAMP WITHOUT TIME ZONE NOT NULL default now(),
data_modifica    TIMESTAMP WITHOUT TIME ZONE,
data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
login_operazione varchar(250),
ente_proprietario_id integer not null,
CONSTRAINT pk_siac_d_tefa_trib_gruppo_tipo PRIMARY KEY(tefa_trib_gruppo_tipo_id),
CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib_gruppo_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_d_tefa_trib_gruppo_tipo_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_trib_gruppo_tipo
USING btree (ente_proprietario_id);

drop table siac.siac_d_tefa_trib_gruppo;
create table siac.siac_d_tefa_trib_gruppo
(
tefa_trib_gruppo_id serial,
tefa_trib_gruppo_code varchar(50),
tefa_trib_gruppo_desc varchar(250),
tefa_trib_gruppo_anno varchar(50),
tefa_trib_gruppo_f1_id   integer,
tefa_trib_gruppo_f2_id   integer,
tefa_trib_gruppo_f3_id   integer,
tefa_trib_tipologia_id integer not null,
tefa_trib_gruppo_tipo_id    integer not null,
validita_inizio  TIMESTAMP WITHOUT TIME ZONE  NOT NULL default now(),
validita_fine    TIMESTAMP WITHOUT TIME ZONE,
data_creazione   TIMESTAMP WITHOUT TIME ZONE NOT NULL default now(),
data_modifica    TIMESTAMP WITHOUT TIME ZONE,
data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
login_operazione varchar(250),
ente_proprietario_id integer not null,
CONSTRAINT pk_siac_d_tefa_trib_gruppo PRIMARY KEY(tefa_trib_gruppo_id),
CONSTRAINT siac_d_tefa_trib_gruppo_tipo_siac_d_tefa_trib_gruppo FOREIGN KEY (tefa_trib_gruppo_tipo_id)
    REFERENCES siac.siac_d_tefa_trib_gruppo_tipo(tefa_trib_gruppo_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_d_tefa_trib_tipoologia_siac_d_tefa_trib_gruppo FOREIGN KEY (tefa_trib_tipologia_id)
    REFERENCES siac.siac_d_tefa_trib_tipologia(tefa_trib_tipologia_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib_gruppo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_d_tefa_trib_gruppo_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_trib_gruppo
USING btree (ente_proprietario_id);
CREATE INDEX siac_d_tefa_trib_gruppo_fk_siac_d_tefa_trib_gruppo_tipo_idx ON siac.siac_d_tefa_trib_gruppo
USING btree (tefa_trib_gruppo_tipo_id);
CREATE INDEX siac_d_tefa_trib_gruppo_fk_siac_d_tefa_trib_gruppo_tipoogia_idx ON siac.siac_d_tefa_trib_gruppo
USING btree (tefa_trib_tipologia_id);


drop table siac.siac_d_tefa_tributo;
create table siac.siac_d_tefa_tributo
(
tefa_trib_id serial,
tefa_trib_code varchar(50),
tefa_trib_desc varchar(250),
tefa_trib_tipologia_id integer not null,
validita_inizio  TIMESTAMP WITHOUT TIME ZONE  NOT NULL default now(),
validita_fine    TIMESTAMP WITHOUT TIME ZONE,
data_creazione   TIMESTAMP WITHOUT TIME ZONE NOT NULL default now(),
data_modifica    TIMESTAMP WITHOUT TIME ZONE,
data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
login_operazione varchar(250),
ente_proprietario_id integer not null,
CONSTRAINT pk_siac_d_tefa_trib PRIMARY KEY(tefa_trib_id),
CONSTRAINT siac_d_tefa_trib_tipoologia_siac_d_tefa_tributo FOREIGN KEY (tefa_trib_tipologia_id)
    REFERENCES siac.siac_d_tefa_trib_tipologia(tefa_trib_tipologia_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE INDEX siac_d_tefa_tributo_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_tributo
USING btree (ente_proprietario_id);

CREATE INDEX siac_d_tefa_tributo_fk_siac_d_tefa_tipologia_idx ON siac.siac_d_tefa_tributo
USING btree (tefa_trib_tipologia_id);


drop table siac.siac_d_tefa_trib_comune;
create table siac.siac_d_tefa_trib_comune
(
tefa_trib_comune_id serial,
tefa_trib_comune_code varchar(50),
tefa_trib_comune_desc varchar(250),
tefa_trib_comune_cat_code varchar(50),
tefa_trib_comune_cat_desc varchar(250),
validita_inizio  TIMESTAMP WITHOUT TIME ZONE  NOT NULL default now(),
validita_fine    TIMESTAMP WITHOUT TIME ZONE,
data_creazione   TIMESTAMP WITHOUT TIME ZONE NOT NULL default now(),
data_modifica    TIMESTAMP WITHOUT TIME ZONE,
data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
login_operazione varchar(250),
ente_proprietario_id integer not null,
CONSTRAINT pk_siac_d_tefa_trib_comune PRIMARY KEY(tefa_trib_comune_id),
CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib_comune FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_d_tefa_trib_comune_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_trib_comune
USING btree (ente_proprietario_id);


drop table siac.siac_r_tefa_tributo_gruppo;
create table siac.siac_r_tefa_tributo_gruppo
(
tefa_trib_gruppo_r_id serial,
tefa_trib_id integer not null,
tefa_trib_gruppo_id integer not null,
validita_inizio  TIMESTAMP WITHOUT TIME ZONE  NOT NULL default now(),
validita_fine    TIMESTAMP WITHOUT TIME ZONE,
data_creazione   TIMESTAMP WITHOUT TIME ZONE NOT NULL default now(),
data_modifica    TIMESTAMP WITHOUT TIME ZONE,
data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
login_operazione varchar(250),
ente_proprietario_id integer not null,
CONSTRAINT pk_siac_r_tefa_trib_gruooi PRIMARY KEY(tefa_trib_gruppo_r_id),
CONSTRAINT siac_d_tefa_trib_siac_r_tefa_trib_gruppo FOREIGN KEY (tefa_trib_id)
    REFERENCES siac.siac_d_tefa_tributo(tefa_trib_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_d_tefa_trib_gruppo_siac_r_tefa_trib_gruppo FOREIGN KEY (tefa_trib_gruppo_id)
    REFERENCES siac.siac_d_tefa_trib_gruppo(tefa_trib_gruppo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_t_ente_proprietario_siac_r_tefa_trib_gruppo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


CREATE INDEX siac_r_tefa_trib_gruppo_fk_ente_proprietario_id_idx ON siac.siac_r_tefa_tributo_gruppo
USING btree (ente_proprietario_id);
CREATE INDEX siac_r_tefa_trib_gruppo_fk_siac_d_tefa_trib_idx ON siac.siac_r_tefa_tributo_gruppo
USING btree (tefa_trib_id);
CREATE INDEX siac_r_tefa_trib_gruppo_fk_siac_d_tefa_trib_gruppo_idx ON siac.siac_r_tefa_tributo_gruppo
USING btree (tefa_trib_gruppo_id);


create table siac.siac_t_tefa_trib_gruppo_upload
(
tefa_trib_gruppo_upload_id serial,
tefa_trib_file_id         integer  not null,
tefa_trib_gruppo_tipo_id integer,
tefa_trib_gruppo_id integer,
tefa_trib_gruppo_upload varchar(250),
validita_inizio  TIMESTAMP WITHOUT TIME ZONE  NOT NULL default now(),
validita_fine    TIMESTAMP WITHOUT TIME ZONE,
data_creazione   TIMESTAMP WITHOUT TIME ZONE NOT NULL default now(),
data_modifica    TIMESTAMP WITHOUT TIME ZONE,
data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
login_operazione varchar(250),
ente_proprietario_id integer not null,
CONSTRAINT pk_siac_t_tefa_trib_gruppo_upd PRIMARY KEY(tefa_trib_gruppo_upload_id),
CONSTRAINT siac_d_tefa_trib_gruppo_tipo_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (tefa_trib_gruppo_tipo_id)
    REFERENCES siac.siac_d_tefa_trib_gruppo_tipo(tefa_trib_gruppo_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_d_tefa_trib_gruppo_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (tefa_trib_gruppo_id)
    REFERENCES siac.siac_d_tefa_trib_gruppo(tefa_trib_gruppo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_t_ente_proprietario_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_t_file_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (tefa_trib_file_id)
    REFERENCES siac.siac_t_file(file_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);

CREATE INDEX siac_t_tefa_trib_gruppo_upd_tefa_trib_upload_id_idx ON siac.siac_t_tefa_trib_gruppo_upload
USING btree (tefa_trib_file_id);

CREATE INDEX siac_t_tefa_trib_gruppo_upd_fk_tefa_trib_gruppo_idx ON siac.siac_t_tefa_trib_gruppo_upload
USING btree (tefa_trib_gruppo_id);

CREATE INDEX siac_t_tefa_trib_gruppo_upd_fk_tefa_trib_gruppo_tipo_idx ON siac.siac_t_tefa_trib_gruppo_upload
USING btree (tefa_trib_gruppo_tipo_id);


CREATE INDEX siac_t_tefa_trib_gruppo_upd_fk_ente_proprietario_id_idx ON siac.siac_t_tefa_trib_gruppo_upload
USING btree (ente_proprietario_id);


-- popolamento siac_t_tefa_trib_gruppo_upload - da passare al java come regola - inizio
delete from siac_t_tefa_trib_gruppo_upload;
insert into siac_t_tefa_trib_gruppo_upload
(
	tefa_trib_upload_id,
	tefa_trib_gruppo_tipo_id,
	tefa_trib_gruppo_upload,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select upd.num_upload,
       gruppo.tefa_trib_gruppo_tipo_id,
	   fnc_tefa_trib_raggruppamento( gruppo.tefa_trib_gruppo_tipo_id,null ,upd.num_upload),
       now(),
       'admin',
       gruppo.ente_proprietario_id
from siac_d_tefa_trib_gruppo_tipo gruppo,( select * from (( select 1 num_upload ) union (select 2 num_upload )) query ) upd
where gruppo.ente_proprietario_id=2
order by upd.num_upload;





insert into siac_t_tefa_trib_gruppo_upload
(
	tefa_trib_upload_id,
	tefa_trib_gruppo_id,
	tefa_trib_gruppo_upload,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select upd.num_upload,
       gruppo.tefa_trib_gruppo_id,
	   fnc_tefa_trib_raggruppamento( null,gruppo.tefa_trib_gruppo_id ,upd.num_upload),
       now(),
       'admin',
       gruppo.ente_proprietario_id
from siac_d_tefa_trib_gruppo gruppo,( select * from (( select 1 num_upload ) union (select 2 num_upload )) query ) upd
where gruppo.ente_proprietario_id=2
order by upd.num_upload;
-- popolamento siac_t_tefa_trib_gruppo_upload - da passare al java come regola - fine

-- aggiornamento campo tefa_trib_anno_rif_str - da passare al java come regola - inizio
update siac_t_tefa_trib_importi tefa
set    tefa_trib_anno_rif_str=
( case when tefa.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
          when tefa.tefa_trib_anno_rif::INTEGER=2020 then '=2020'
          when tefa.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end )
where tefa.ente_proprietario_id=2;
-- aggiornamento campo tefa_trib_anno_rif_str - da passare al java come regola - fine

-- se tefa.tefa_trib_anno_rif<=annoBilancio-2 --> tefa_trib_anno_rif_str='<='||annoBilancio-2
-- se tefa.tefa_trib_anno_rif=annoBilancio-1 --> tefa_trib_anno_rif_str='='||annoBilancio-1
-- se tefa.tefa_trib_anno_rif>=annoBilancio-1 --> tefa_trib_anno_rif_str='>='||annoBilancio

--- popolamento tabelle da DB

-- siac_d_tefa_trib_tipologia
-- siac_d_tefa_trib_gruppo_tipo
-- siac_d_tefa_trib_gruppo
-- siac_d_tefa_tributo
-- siac_d_tefa_trib_comune
-- siac_r_tefa_tributo_gruppo




insert into siac_t_tefa_trib_gruppo_upload
(
	tefa_trib_file_id,
	tefa_trib_gruppo_tipo_id,
	tefa_trib_gruppo_upload,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select <par_tefa_trib_file_id>,
       gruppo.tefa_trib_gruppo_tipo_id,
	   fnc_tefa_trib_raggruppamento( gruppo.tefa_trib_gruppo_tipo_id,null ,par_tefa_trib_file_id),
       now(),
       'admin',
       gruppo.ente_proprietario_id
from siac_d_tefa_trib_gruppo_tipo gruppo
where gruppo.ente_proprietario_id=2;

insert into siac_t_tefa_trib_gruppo_upload
(
	tefa_trib_file_id,
	tefa_trib_gruppo_id,
	tefa_trib_gruppo_upload,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select <par_tefa_trib_file_id>
       gruppo.tefa_trib_gruppo_id,
	   fnc_tefa_trib_raggruppamento( null,gruppo.tefa_trib_gruppo_id ,par_tefa_trib_file_id),
       now(),
       'admin',
       gruppo.ente_proprietario_id
from siac_d_tefa_trib_gruppo gruppo
where gruppo.ente_proprietario_id=2;