/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table fase_bil_t_gest_apertura_provv;
drop table bck_fase_bil_t_gest_apertura_provv_bil_elem;
drop table bck_fase_bil_t_gest_apertura_provv_bil_elem_class;
drop table bck_fase_bil_t_gest_apertura_provv_bil_elem_stato;
drop table bck_fase_bil_t_gest_apertura_provv_bil_elem_attr;
drop table bck_fase_bil_t_gest_apertura_provv_bil_elem_categ;
drop table bck_fase_bil_t_gest_apertura_provv_bil_elem_det;

CREATE TABLE fase_bil_t_gest_apertura_provv
(
 fase_bil_gest_ape_prov_id SERIAL,
 elem_id    integer  null,
 elem_code  VARCHAR(200) NOT NULL,
 elem_code2 VARCHAR(200) NOT NULL,
 elem_code3 VARCHAR(200) DEFAULT '1'::character varying NOT NULL,
 elem_prov_id integer null,
 elem_prov_new_id integer null,
 bil_id       integer not null,
 fase_bil_elab_id integer not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_t_gest_ape_provv PRIMARY KEY(fase_bil_gest_ape_prov_id),
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_gest_ape_prov FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_prov FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_prov_prec_id FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_prov_prov_id1 FOREIGN KEY (elem_prov_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_prov_prov_id2 FOREIGN KEY (elem_prov_new_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_gest_ape_prov FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_gest_apertura_provv
IS 'Apertura nuovo bilancio gestione provvisorio da gestione anno precedente - strutture per nuovi capitoli di gestione';


comment on column fase_bil_t_gest_apertura_provv.elem_id
is 'Identificativo elemento di bilancio di gestione eq anno precedente.';

comment on column fase_bil_t_gest_apertura_provv.elem_code
is 'Identificativo logico elemento di bilancio di gestione eq anno precedente.';

comment on column fase_bil_t_gest_apertura_provv.elem_code2
is 'Identificativo logico elemento di bilancio di gestione eq anno precedente.';

comment on column fase_bil_t_gest_apertura_provv.elem_code3
is 'Identificativo logico elemento di bilancio di gestione eq anno precedente.';

comment on column fase_bil_t_gest_apertura_provv.elem_prov_new_id
is 'Identificativo elemento di bilancio di gestione equivalente nuovo.';

comment on column fase_bil_t_gest_apertura_provv.elem_prov_id
is 'Identificativo elemento di bilancio di gestione equivalente esistente.';


CREATE UNIQUE INDEX idx_fase_bil_t_gest_ape_prov_1 ON fase_bil_t_gest_apertura_provv
  USING btree (elem_code COLLATE pg_catalog."default", elem_code2 COLLATE pg_catalog."default", elem_code3 COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE UNIQUE INDEX idx_fase_bil_t_gest_ape_prov_2 ON fase_bil_t_gest_apertura_provv
  USING btree (elem_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE UNIQUE INDEX idx_fase_bil_t_gest_ape_prov_3 ON fase_bil_t_gest_apertura_provv
  USING btree (elem_prov_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE UNIQUE INDEX idx_fase_bil_t_gest_ape_prov_4 ON fase_bil_t_gest_apertura_provv
  USING btree (elem_prov_new_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE TABLE  bck_fase_bil_t_gest_apertura_provv_bil_elem
(
 bck_fase_bil_gest_prov_ape_id SERIAL,
 elem_id integer not null,
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
 CONSTRAINT pk_bck_fase_bil_t_prov_ape_bil_elem PRIMARY KEY(bck_fase_bil_gest_prov_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prov_ape_ente FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_elem1 FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_elem2 FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prov_ape_fase FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_gest_apertura_provv_bil_elem
IS 'Apertura bilancio gestione provvisorio - bck struttura gestione corrente sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem.elem_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';
comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem.elem_bck_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';




CREATE TABLE  bck_fase_bil_t_gest_apertura_provv_bil_elem_class
(
 bck_fase_bil_gest_prov_ape_id SERIAL,
 elem_id integer not null,
 elem_bck_id  integer not null ,
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
 CONSTRAINT pk_bck_fase_bil_t_prov_ape_bil_elem_c PRIMARY KEY(bck_fase_bil_gest_prov_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prov_ape_ente1 FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_elem2 FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_elem3 FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prov_ape_fase1 FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_gest_apertura_provv_bil_elem_class
IS 'Apertura bilancio gestione provvisorio - bck struttura gestione corrente [siac_r_bil_elem_stato] sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem_class.elem_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';
comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem_class.elem_bck_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';

CREATE TABLE  bck_fase_bil_t_gest_apertura_provv_bil_elem_stato
(
 bck_fase_bil_gest_prov_ape_id SERIAL,
 elem_id integer not null,
 elem_bck_id  integer not null ,
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
 CONSTRAINT pk_bck_fase_bil_t_prov_ape_bil_elem_st PRIMARY KEY(bck_fase_bil_gest_prov_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prov_ape_ente4 FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_elem5 FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_elem6 FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prov_ape_fase1 FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_gest_apertura_provv_bil_elem_stato
IS 'Apertura bilancio gestione provvisorio - bck struttura gestione corrente [siac_r_bil_elem_stato] sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem_class.elem_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';
comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem_class.elem_bck_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';

CREATE TABLE  bck_fase_bil_t_gest_apertura_provv_bil_elem_attr
(
 bck_fase_bil_gest_prov_ape_id SERIAL,
 elem_id integer not null,
 elem_bck_id  integer not null ,
 elem_bck_attr_id integer,
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
 CONSTRAINT pk_bck_fase_bil_t_prov_ape_bil_elem_attr PRIMARY KEY(bck_fase_bil_gest_prov_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prov_ape_ente7 FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_elem8 FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_elem9 FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prov_ape_fase2 FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_gest_apertura_provv_bil_elem_attr
IS 'Apertura bilancio gestione provvisorio - bck struttura gestione corrente [siac_r_bil_elem_attr] sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem_attr.elem_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';
comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem_attr.elem_bck_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';



CREATE TABLE  bck_fase_bil_t_gest_apertura_provv_bil_elem_categ
(
 bck_fase_bil_gest_prov_ape_id SERIAL,
 elem_id integer not null,
 elem_bck_id  integer not null ,
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
 CONSTRAINT pk_bck_fase_bil_t_prov_ape_bil_elem_categ PRIMARY KEY(bck_fase_bil_gest_prov_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prov_ape_ente9 FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_elem10 FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_elem11 FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prov_ape_fase3 FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_gest_apertura_provv_bil_elem_categ
IS 'Apertura bilancio gestione provvisorio - bck struttura gestione corrente [siac_r_bil_elem_categoria] sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem_categ.elem_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';
comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem_categ.elem_bck_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';



CREATE TABLE  bck_fase_bil_t_gest_apertura_provv_bil_elem_det
(
 bck_fase_bil_gest_prov_ape_id SERIAL,
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
 CONSTRAINT pk_bck_fase_bil_t_prov_ape_bil_elem_det PRIMARY KEY(bck_fase_bil_gest_prov_ape_id),
 CONSTRAINT siac_t_ente_proprietario_bck_fase_bil_t_prov_ape_d_ente1 FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_d_elem FOREIGN KEY (elem_bck_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_bck_fase_bil_t_prov_ape_d_elemd FOREIGN KEY (elem_bck_det_id)
    REFERENCES siac_t_bil_elem_det(elem_det_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_bck_fase_bil_t_prov_ape_d_fase1 FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)WITH (oids = false);


COMMENT ON TABLE bck_fase_bil_t_gest_apertura_provv_bil_elem_det
IS 'Apertura bilancio gestione provvisorio - bck struttura gestione corrente [siac_t_bil_elem_det] sovrascritta da gestione anno precedente';


comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem_det.elem_bck_id
is 'Identificativo elemento di bilancio di gestione anno corrente.';
comment on column bck_fase_bil_t_gest_apertura_provv_bil_elem_det.elem_bck_det_id
is 'Identificativo dettaglio elemento di bilancio di gestione anno corrente.';