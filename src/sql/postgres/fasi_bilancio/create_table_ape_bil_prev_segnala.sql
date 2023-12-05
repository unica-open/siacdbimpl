/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table fase_bil_t_prev_apertura_segnala;

CREATE TABLE fase_bil_t_prev_apertura_segnala
(
 fase_bil_prev_ape_seg_id SERIAL,
 elem_id    integer not null,
 elem_code  VARCHAR(200) NOT NULL,
 elem_code2 VARCHAR(200) NOT NULL,
 elem_code3 VARCHAR(200) DEFAULT '1'::character varying NOT NULL,
 bil_id       integer not null,
 fase_bil_elab_id integer not null,
 segnala_codice  varchar(50) not null,
 segnala_desc    varchar (1500) not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_t_prev_ape_seg PRIMARY KEY(fase_bil_prev_ape_seg_id),
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_prev_ape_seg FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_fase_bil_t_prev_ape_seg FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_ape_seg FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_prev_ape_seg FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_prev_apertura_segnala
IS 'Apertura nuovo bilancio previsione da gestione anno precedente - segnalazione su capitoli';


comment on column fase_bil_t_prev_apertura_segnala.elem_id
is 'Identificativo elemento di bilancio di gestione eq anno precedente.';

comment on column fase_bil_t_prev_apertura_segnala.elem_code
is 'Identificativo logico elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_apertura_segnala.elem_code2
is 'Identificativo logico elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_apertura_segnala.elem_code3
is 'Identificativo logico elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_apertura_segnala.elem_id
is 'Identificativo elemento di bilancio di previsione.';


CREATE  INDEX idx_fase_bil_t_prev_ape_seg_1 ON fase_bil_t_prev_apertura_segnala
  USING btree (elem_code COLLATE pg_catalog."default", elem_code2 COLLATE pg_catalog."default", elem_code3 COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE  INDEX idx_fase_bil_t_prev_ape_seg_2 ON fase_bil_t_prev_apertura_segnala
  USING btree (elem_id ,  validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);