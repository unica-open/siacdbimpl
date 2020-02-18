/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table fase_bil_t_prev_approva_str_elem_gest_nuovo;
drop table fase_bil_t_prev_approva_str_elem_gest_esiste;

drop table fase_bil_t_prev_apertura_str_elem_prev_nuovo;
drop table fase_bil_t_prev_apertura_str_elem_prev_esiste;

drop table bck_fase_bil_t_prev_approva_bil_elem;

drop table bck_fase_bil_t_prev_approva_bil_elem_stato;
drop table bck_fase_bil_t_prev_approva_bil_elem_attr;
drop table bck_fase_bil_t_prev_approva_bil_elem_class;
drop table bck_fase_bil_t_prev_approva_bil_elem_categ;
drop table bck_fase_bil_t_prev_approva_bil_elem_det;

drop table bck_fase_bil_t_prev_apertura_bil_elem;
drop table bck_fase_bil_t_prev_apertura_bil_elem_stato;
drop table bck_fase_bil_t_prev_apertura_bil_elem_attr;
drop table bck_fase_bil_t_prev_apertura_bil_elem_class;
drop table bck_fase_bil_t_prev_apertura_bil_elem_categ;
drop table bck_fase_bil_t_prev_apertura_bil_elem_det;


drop table fase_bil_t_elaborazione_log;
drop table fase_bil_t_elaborazione;
drop table fase_bil_d_elaborazione_tipo;

CREATE TABLE fase_bil_d_elaborazione_tipo
(
 fase_bil_elab_tipo_id    SERIAL,
 fase_bil_elab_tipo_code  VARCHAR(50) NOT NULL,
 fase_bil_elab_tipo_desc  VARCHAR(200) NOT NULL,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_d_elaborazione_tipo PRIMARY KEY(fase_bil_elab_tipo_id),
 CONSTRAINT siac_t_ente_proprietario_fase_bil_d_elaborazione_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_d_elaborazione_tipo
IS 'Tipologie di elaborazioni su fase di bilancio.';


CREATE TABLE fase_bil_t_elaborazione
(
 fase_bil_elab_id    SERIAL,
 fase_bil_elab_tipo_id integer not null,
 fase_bil_elab_esito   VARCHAR(100) NOT NULL,
 fase_bil_elab_esito_msg   VARCHAR(500) NOT NULL,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_t_elaborazione PRIMARY KEY(fase_bil_elab_id),
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_elaborazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_d_elaborazione_tipo_fase_bil_t_elaborazione FOREIGN KEY (fase_bil_elab_tipo_id)
    REFERENCES fase_bil_d_elaborazione_tipo(fase_bil_elab_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_elaborazione
IS 'Elaborazioni fase di bilancio.';


CREATE TABLE fase_bil_t_elaborazione_log
(
 fase_bil_elab_log_id            SERIAL,
 fase_bil_elab_id                integer not null,
 fase_bil_elab_log_operazione    VARCHAR(1000) NOT NULL,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_t_elaborazione_log PRIMARY KEY(fase_bil_elab_log_id),
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_elaborazione_log FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_elaborazione_log FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_elaborazione_log
IS 'Elaborazioni fase di bilancio - LOG.';

CREATE TABLE fase_bil_t_prev_approva_str_elem_gest_nuovo
(
 fase_bil_prev_str_nuovo_id SERIAL,
 elem_id    integer not null,
 elem_code  VARCHAR(200) NOT NULL,
 elem_code2 VARCHAR(200) NOT NULL,
 elem_code3 VARCHAR(200) DEFAULT '1'::character varying NOT NULL,
 elem_gest_id integer null,
 bil_id       integer not null,
 fase_bil_elab_id integer not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_t_prev_approva_str_n PRIMARY KEY(fase_bil_prev_str_nuovo_id),
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_prev_approva_str_n_p FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_prev_approva_str_n_p FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_approva_str_prev_n_p FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_approva_str_prev_n_g FOREIGN KEY (elem_gest_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_prev_approva_str_n_p FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_prev_approva_str_elem_gest_nuovo
IS 'Approvazione bilancio previsione - strutture per nuovi capitoli senza equivalente in gestione';


comment on column fase_bil_t_prev_approva_str_elem_gest_nuovo.elem_id
is 'Identificativo elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_approva_str_elem_gest_nuovo.elem_code
is 'Identificativo logico elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_approva_str_elem_gest_nuovo.elem_code2
is 'Identificativo logico elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_approva_str_elem_gest_nuovo.elem_code3
is 'Identificativo logico elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_approva_str_elem_gest_nuovo.elem_gest_id
is 'Identificativo elemento di bilancio di gestione equivalente nuovo.';


CREATE UNIQUE INDEX idx_fase_bil_t_prev_approva_str_nuovo_1 ON fase_bil_t_prev_approva_str_elem_gest_nuovo
  USING btree (elem_code COLLATE pg_catalog."default", elem_code2 COLLATE pg_catalog."default", elem_code3 COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE UNIQUE INDEX idx_fase_bil_t_prev_approva_str_nuovo_2 ON fase_bil_t_prev_approva_str_elem_gest_nuovo
  USING btree (elem_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE UNIQUE INDEX idx_fase_bil_t_prev_approva_str_nuovo_3 ON fase_bil_t_prev_approva_str_elem_gest_nuovo
  USING btree (elem_gest_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE TABLE fase_bil_t_prev_approva_str_elem_gest_esiste
(
 fase_bil_prev_str_esiste_id SERIAL,
-- elem_prev_id integer not null,
 elem_prev_id integer null, -- dani 22.02.2016
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
 CONSTRAINT pk_fase_bil_t_prev_approva_str_e PRIMARY KEY(fase_bil_prev_str_esiste_id),
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_prev_approva_str_e FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_prev_approva_str_e FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_approva_str_prev_e_p FOREIGN KEY (elem_prev_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_approva_str_prev_e_g FOREIGN KEY (elem_gest_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_prev_approva_str_e FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_prev_approva_str_elem_gest_esiste
IS 'Approvazione bilancio previsione - strutture per nuovi capitoli con equivalente in gestione';


comment on column fase_bil_t_prev_approva_str_elem_gest_esiste.elem_prev_id
is 'Identificativo elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_approva_str_elem_gest_esiste.elem_code
is 'Identificativo logico elemento di bilancio di previsione-gestione.';

comment on column fase_bil_t_prev_approva_str_elem_gest_esiste.elem_code2
is 'Identificativo logico elemento di bilancio di previsione-gestione.';

comment on column fase_bil_t_prev_approva_str_elem_gest_esiste.elem_code3
is 'Identificativo logico elemento di bilancio di previsione-gestione.';

comment on column fase_bil_t_prev_approva_str_elem_gest_esiste.elem_gest_id
is 'Identificativo elemento di bilancio di gestione equivalente esistente.';



CREATE UNIQUE INDEX idx_fase_bil_t_prev_approva_str_esiste_1 ON fase_bil_t_prev_approva_str_elem_gest_esiste
  USING btree (elem_code COLLATE pg_catalog."default", elem_code2 COLLATE pg_catalog."default", elem_code3 COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE UNIQUE INDEX idx_fase_bil_t_prev_approva_str_esiste_2 ON fase_bil_t_prev_approva_str_elem_gest_esiste
  USING btree (elem_prev_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE UNIQUE INDEX idx_fase_bil_t_prev_approva_str_esiste_3 ON fase_bil_t_prev_approva_str_elem_gest_esiste
  USING btree (elem_gest_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE TABLE  bck_fase_bil_t_prev_approva_bil_elem
(
 bck_fase_bil_prev_approva_id SERIAL,
 elem_prev_id integer not null,
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
 CONSTRAINT pk_bck_fase_bil_t_prev_approva_bil_elem PRIMARY KEY(bck_fase_bil_prev_approva_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_approva_be FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_be_p FOREIGN KEY (elem_prev_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_be_g FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prev_approva_be_g FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_approva_bil_elem
IS 'Approvazione bilancio previsione - bck struttura gestione equivalente sovrascritta da previsione';


comment on column bck_fase_bil_t_prev_approva_bil_elem.elem_prev_id
is 'Identificativo elemento di bilancio di previsione.';
comment on column bck_fase_bil_t_prev_approva_bil_elem.elem_bck_id
is 'Identificativo elemento di bilancio di gestione.';



CREATE TABLE  bck_fase_bil_t_prev_approva_bil_elem_stato
(
 bck_fase_bil_prev_approva_id SERIAL,
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
 CONSTRAINT pk_bck_fase_bil_t_prev_approva_bil_elem_s PRIMARY KEY(bck_fase_bil_prev_approva_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_approva_st FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_be_s FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prev_approva_be_s FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_approva_bil_elem_stato
IS 'Approvazione bilancio previsione - bck struttura gestione equivalente sovrascritta da previsione - per siac_r_bil_elem_stato';


comment on column bck_fase_bil_t_prev_approva_bil_elem_stato.elem_bck_id
is 'Identificativo elemento di bilancio di gestione.';

CREATE TABLE  bck_fase_bil_t_prev_approva_bil_elem_attr
(
 bck_fase_bil_prev_approva_id SERIAL,
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
 CONSTRAINT pk_bck_fase_bil_t_prev_approva_bil_elem_a PRIMARY KEY(bck_fase_bil_prev_approva_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_approva_at FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_be_a FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_be_at FOREIGN KEY (elem_bck_attr_id)
    REFERENCES siac_t_attr(attr_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prev_approva_be_a FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_approva_bil_elem_attr
IS 'Approvazione bilancio previsione - bck struttura gestione equivalente sovrascritta da previsione - per siac_r_bil_elem_attr';


comment on column bck_fase_bil_t_prev_approva_bil_elem_attr.elem_bck_id
is 'Identificativo elemento di bilancio di gestione.';

CREATE TABLE  bck_fase_bil_t_prev_approva_bil_elem_class
(
 bck_fase_bil_prev_approva_id SERIAL,
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
 CONSTRAINT pk_bck_fase_bil_t_prev_approva_bil_elem_c PRIMARY KEY(bck_fase_bil_prev_approva_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_approva_c FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_be_c FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_be_cl FOREIGN KEY (elem_bck_classif_id)
    REFERENCES siac_t_class(classif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prev_approva_be_c FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_approva_bil_elem_class
IS 'Approvazione bilancio previsione - bck struttura gestione equivalente sovrascritta da previsione - per siac_r_bil_elem_class';


comment on column bck_fase_bil_t_prev_approva_bil_elem_class.elem_bck_id
is 'Identificativo elemento di bilancio di gestione.';

CREATE TABLE  bck_fase_bil_t_prev_approva_bil_elem_categ
(
 bck_fase_bil_prev_approva_id SERIAL,
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
 CONSTRAINT pk_bck_fase_bil_t_prev_approva_bil_elem_ca PRIMARY KEY(bck_fase_bil_prev_approva_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_approva_ca FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_be_ca FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_be_cat FOREIGN KEY (elem_bck_cat_id)
    REFERENCES siac_d_bil_elem_categoria(elem_cat_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prev_approva_be_c FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_approva_bil_elem_categ
IS 'Approvazione bilancio previsione - bck struttura gestione equivalente sovrascritta da previsione - per siac_r_bil_elem_categoria';


comment on column bck_fase_bil_t_prev_approva_bil_elem_categ.elem_bck_id
is 'Identificativo elemento di bilancio di gestione.';



CREATE TABLE  bck_fase_bil_t_prev_approva_bil_elem_det
(
 bck_fase_bil_prev_approva_id SERIAL,
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
 CONSTRAINT pk_bck_fase_bil_t_prev_approva_bil_elem_det PRIMARY KEY(bck_fase_bil_prev_approva_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prev_approva_de FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_de FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_de_elemd FOREIGN KEY (elem_bck_det_id)
    REFERENCES siac_t_bil_elem_det(elem_det_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prev_approva_de_fase FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_prev_approva_bil_elem_det
IS 'Approvazione bilancio previsione - bck dettagli importo gestione equivalente sovrascritta da previsione - per siac_t_bil_elem_det';


comment on column bck_fase_bil_t_prev_approva_bil_elem_det.elem_bck_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';
comment on column bck_fase_bil_t_prev_approva_bil_elem_det.elem_bck_det_id
is 'Identificativo dettaglio elemento di bilancio di gestione anno corrente.';

alter table fase_bil_t_prev_approva_str_elem_gest_esiste alter column elem_prev_id drop not null;
