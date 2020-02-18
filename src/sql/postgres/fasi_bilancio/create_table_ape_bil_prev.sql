/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table fase_bil_t_prev_apertura_str_elem_prev_nuovo;
drop table fase_bil_t_prev_apertura_str_elem_prev_esiste;
drop table bck_fase_bil_t_prev_apertura_bil_elem;
drop table bck_fase_bil_t_prev_apertura_bil_elem_stato;
drop table bck_fase_bil_t_prev_apertura_bil_elem_attr;
drop table bck_fase_bil_t_prev_apertura_bil_elem_class;
drop table bck_fase_bil_t_prev_apertura_bil_elem_categ;
drop table bck_fase_bil_t_prev_apertura_bil_elem_det;



CREATE TABLE fase_bil_t_prev_apertura_str_elem_prev_nuovo
(
 fase_bil_prev_str_nuovo_id SERIAL,
 elem_id    integer not null,
 elem_code  VARCHAR(200) NOT NULL,
 elem_code2 VARCHAR(200) NOT NULL,
 elem_code3 VARCHAR(200) DEFAULT '1'::character varying NOT NULL,
 elem_prev_id integer null,
 bil_id       integer not null,
 fase_bil_elab_id integer not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_t_prev_ape_str_n PRIMARY KEY(fase_bil_prev_str_nuovo_id),
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_prev_ape_str_n_p FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_prev_ape_str_n_p FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_ape_str_prev_n_p FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_ape_str_prev_n_g FOREIGN KEY (elem_prev_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_prev_ape_str_n_p FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_prev_apertura_str_elem_prev_nuovo
IS 'Apertura nuovo bilancio previsione da gestione anno precedente - strutture per nuovi capitoli di previsione';


comment on column fase_bil_t_prev_apertura_str_elem_prev_nuovo.elem_id
is 'Identificativo elemento di bilancio di gestione eq anno precedente.';

comment on column fase_bil_t_prev_apertura_str_elem_prev_nuovo.elem_code
is 'Identificativo logico elemento di bilancio di gestione eq anno precedente.';

comment on column fase_bil_t_prev_apertura_str_elem_prev_nuovo.elem_code2
is 'Identificativo logico elemento di bilancio di gestione eq anno precedente.';

comment on column fase_bil_t_prev_apertura_str_elem_prev_nuovo.elem_code3
is 'Identificativo logico elemento di bilancio di gestione eq anno precedente.';

comment on column fase_bil_t_prev_apertura_str_elem_prev_nuovo.elem_prev_id
is 'Identificativo elemento di bilancio di previsione equivalente nuovo.';


CREATE UNIQUE INDEX idx_fase_bil_t_prev_ape_str_nuovo_1 ON fase_bil_t_prev_apertura_str_elem_prev_nuovo
  USING btree (elem_code COLLATE pg_catalog."default", elem_code2 COLLATE pg_catalog."default", elem_code3 COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE UNIQUE INDEX idx_fase_bil_t_prev_ape_str_nuovo_2 ON fase_bil_t_prev_apertura_str_elem_prev_nuovo
  USING btree (elem_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE UNIQUE INDEX idx_fase_bil_t_prev_ape_str_nuovo_3 ON fase_bil_t_prev_apertura_str_elem_prev_nuovo
  USING btree (elem_prev_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE TABLE fase_bil_t_prev_apertura_str_elem_prev_esiste
(
 fase_bil_prev_str_esiste_id SERIAL,
 elem_prev_id integer null,
 elem_gest_id integer null,
 elem_code  VARCHAR(200) NOT NULL,
 elem_code2 VARCHAR(200) NOT NULL,
 elem_code3 VARCHAR(200) DEFAULT '1'::character varying NOT NULL,
 bil_id     integer not null,
 fase_bil_elab_id integer not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_t_prev_ape_str_e PRIMARY KEY(fase_bil_prev_str_esiste_id),
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_prev_ape_str_e FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_prev_ape_str_e FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_ape_str_prev_e_p FOREIGN KEY (elem_prev_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_ape_str_prev_e_g FOREIGN KEY (elem_gest_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_prev_ape_str_e FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_prev_apertura_str_elem_prev_esiste
IS 'Apertura bilancio previsione - strutture per capitoli previsione esistente con equivalente in gestione anno precedente';


comment on column fase_bil_t_prev_apertura_str_elem_prev_esiste.elem_prev_id
is 'Identificativo elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_apertura_str_elem_prev_esiste.elem_code
is 'Identificativo logico elemento di bilancio di previsione-gestione.';

comment on column fase_bil_t_prev_apertura_str_elem_prev_esiste.elem_code2
is 'Identificativo logico elemento di bilancio di previsione-gestione.';

comment on column fase_bil_t_prev_apertura_str_elem_prev_esiste.elem_code3
is 'Identificativo logico elemento di bilancio di previsione-gestione.';

comment on column fase_bil_t_prev_apertura_str_elem_prev_esiste.elem_gest_id
is 'Identificativo elemento di bilancio di gestione equivalente esistente.';



CREATE UNIQUE INDEX idx_fase_bil_t_prev_ape_str_esiste_1 ON fase_bil_t_prev_apertura_str_elem_prev_esiste
  USING btree (elem_code COLLATE pg_catalog."default", elem_code2 COLLATE pg_catalog."default", elem_code3 COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE UNIQUE INDEX idx_fase_bil_t_prev_ape_str_esiste_2 ON fase_bil_t_prev_apertura_str_elem_prev_esiste
  USING btree (elem_prev_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE UNIQUE INDEX idx_fase_bil_t_prev_ape_str_esiste_3 ON fase_bil_t_prev_apertura_str_elem_prev_esiste
  USING btree (elem_gest_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE TABLE  bck_fase_bil_t_prev_apertura_bil_elem
(
 bck_fase_bil_prev_ape_id SERIAL,
 elem_gest_id integer not null,
 elem_bck_id  integer not null ,
 elem_bck_code   VARCHAR(200) NOT NULL,
 elem_bck_code2  VARCHAR(200) NOT NULL,
 elem_bck_code3  VARCHAR(200) DEFAULT '1'::character varying NOT NULL,
 elem_bck_desc   VARCHAR NOT NULL,
 elem_bck_desc2  VARCHAR NULL,
 elem_bck_bil_id integer not null ,
 elem_bck_id_padre integer null,
 elem_bck_tipo_id  integer not null ,
 elem_bck_livello integer not null,
 elem_bck_ordine VARCHAR(200) NOT NULL,
 elem_bck_data_creazione TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
 elem_bck_login_operazione VARCHAR(200) NOT NULL,
 elem_bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_validita_fine   TIMESTAMP WITHOUT TIME ZONE,
 fase_bil_elab_id integer not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_bck_fase_bil_t_prev_ape_bil_elem PRIMARY KEY(bck_fase_bil_prev_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_ape_be FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_ape_be_p FOREIGN KEY (elem_gest_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_ape_be_g FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prev_ape_be_g FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_apertura_bil_elem
IS 'Apertura bilancio previsione - bck struttura previsione equivalente sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_prev_apertura_bil_elem.elem_gest_id
is 'Identificativo elemento di bilancio di gestione anno precednete.';
comment on column bck_fase_bil_t_prev_apertura_bil_elem.elem_bck_id
is 'Identificativo elemento di bilancio di previsione.';

CREATE TABLE  bck_fase_bil_t_prev_apertura_bil_elem_stato
(
 bck_fase_bil_prev_ape_id SERIAL,
 elem_bck_id integer not null,
 elem_bck_stato_id  integer not null ,
 elem_bck_data_creazione TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
 elem_bck_login_operazione VARCHAR(200) NOT NULL,
 elem_bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_validita_fine   TIMESTAMP WITHOUT TIME ZONE,
 fase_bil_elab_id integer not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_bck_fase_bil_t_prev_ape_bil_elem_s PRIMARY KEY(bck_fase_bil_prev_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_ape_se FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_ape_se_g FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prev_ape_se_f FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_apertura_bil_elem_stato
IS 'Apertura bilancio previsione - bck struttura stato previsione equivalente sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_prev_apertura_bil_elem_stato.elem_bck_id
is 'Identificativo elemento di bilancio di previsione.';

CREATE TABLE  bck_fase_bil_t_prev_apertura_bil_elem_attr
(
 bck_fase_bil_prev_ape_id SERIAL,
 elem_bck_id integer not null,
 elem_bck_attr_id  integer not null ,
 elem_bck_tabella_id integer,
 elem_bck_boolean  char,
 elem_bck_percentuale numeric,
 elem_bck_testo varchar(500),
 elem_bck_numerico numeric,
 elem_bck_data_creazione TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
 elem_bck_login_operazione VARCHAR(200) NOT NULL,
 elem_bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_validita_fine   TIMESTAMP WITHOUT TIME ZONE,
 fase_bil_elab_id integer not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_bck_fase_bil_t_prev_ape_bil_elem_at PRIMARY KEY(bck_fase_bil_prev_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_ape_ae FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_ape_at_g FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_at_at FOREIGN KEY (elem_bck_attr_id)
    REFERENCES siac_t_attr(attr_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prev_ape_at_f FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_apertura_bil_elem_attr
IS 'Apertura bilancio previsione - bck struttura attributi previsione equivalente sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_prev_apertura_bil_elem_attr.elem_bck_id
is 'Identificativo elemento di bilancio di previsione.';

CREATE TABLE  bck_fase_bil_t_prev_apertura_bil_elem_class
(
 bck_fase_bil_prev_ape_id SERIAL,
 elem_bck_id integer not null,
 elem_bck_classif_id  integer not null ,
 elem_bck_data_creazione TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
 elem_bck_login_operazione VARCHAR(200) NOT NULL,
 elem_bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_validita_fine   TIMESTAMP WITHOUT TIME ZONE,
 fase_bil_elab_id integer not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_bck_fase_bil_t_prev_ape_bil_elem_cl PRIMARY KEY(bck_fase_bil_prev_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_ape_cl_e FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_ape_cl_g FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_cl_cl FOREIGN KEY (elem_bck_classif_id)
    REFERENCES siac_t_class(classif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prev_ape_cl_f FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_apertura_bil_elem_class
IS 'Apertura bilancio previsione - bck struttura classificatori previsione equivalente sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_prev_apertura_bil_elem_class.elem_bck_id
is 'Identificativo elemento di bilancio di previsione.';


CREATE TABLE  bck_fase_bil_t_prev_apertura_bil_elem_categ
(
 bck_fase_bil_prev_ape_id SERIAL,
 elem_bck_id integer not null,
 elem_bck_cat_id integer,
 elem_bck_data_creazione TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
 elem_bck_login_operazione VARCHAR(200) NOT NULL,
 elem_bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_validita_fine   TIMESTAMP WITHOUT TIME ZONE,
 fase_bil_elab_id integer not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_bck_fase_bil_t_prev_ape_bil_elem_cat PRIMARY KEY(bck_fase_bil_prev_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_ape_cat_e FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_ape_cat_g FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_cat_cat FOREIGN KEY (elem_bck_cat_id)
    REFERENCES siac_d_bil_elem_categoria(elem_cat_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prev_ape_cat_f FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_apertura_bil_elem_categ
IS 'Apertura bilancio previsione - bck struttura categorie previsione equivalente sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_prev_apertura_bil_elem_categ.elem_bck_id
is 'Identificativo elemento di bilancio di previsione.';


CREATE TABLE  bck_fase_bil_t_prev_apertura_bil_elem_det
(
 bck_fase_bil_prev_ape_id SERIAL,
 elem_bck_id  integer not null ,
 elem_bck_det_id integer not null ,
 elem_bck_det_importo NUMERIC,
 elem_bck_det_flag VARCHAR(1),
 elem_bck_det_tipo_id INTEGER NOT NULL,
 elem_bck_periodo_id INTEGER NOT NULL,
 elem_bck_data_creazione TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
 elem_bck_login_operazione VARCHAR(200) NOT NULL,
 elem_bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 elem_bck_validita_fine   TIMESTAMP WITHOUT TIME ZONE,
 fase_bil_elab_id integer not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_bck_fase_bil_t_prev_apertura_bil_elem_det PRIMARY KEY(bck_fase_bil_prev_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_apertura_de FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_apertura_de FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_apertura_de_elemd FOREIGN KEY (elem_bck_det_id)
    REFERENCES siac_t_bil_elem_det(elem_det_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_apertura_de_fase FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_apertura_bil_elem_det
IS 'Apertura bilancio previsione - bck dettagli importo previsione equivalente sovrascritta da gestione anno precedente';

comment on column bck_fase_bil_t_prev_apertura_bil_elem_det.elem_bck_id
is 'Identificativo elemento di bilancio di previsione anno corrente.';

comment on column bck_fase_bil_t_prev_apertura_bil_elem_det.elem_bck_det_id
is 'Identificativo dettaglio elemento di bilancio di previsione anno corrente.';
