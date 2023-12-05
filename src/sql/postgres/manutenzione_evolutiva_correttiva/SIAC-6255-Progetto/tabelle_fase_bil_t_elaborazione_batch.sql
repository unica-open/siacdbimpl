/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table if exists fase_bil_t_programmi;
drop table if exists fase_bil_t_cronop;


CREATE TABLE fase_bil_t_programmi
(
  fase_bil_programma_id SERIAL,
  fase_bil_elab_id INTEGER NOT NULL,
  fase_bil_programma_ape_tipo varchar not null,
  programma_id integer not null,
  programma_tipo_id integer not null,
  bil_id INTEGER NOT NULL,
  programma_new_id integer NULL,
  fl_elab VARCHAR not null default 'N',
  scarto_code VARCHAR,
  scarto_desc VARCHAR,
  data_creazione TIMESTAMP WITHOUT TIME ZONE,
  data_modifica  TIMESTAMP WITHOUT TIME ZONE,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR,
  ente_proprietario_id INTEGER,
  CONSTRAINT pk_fase_bil_t_programmi PRIMARY KEY(fase_bil_programma_id),
  CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_progr FOREIGN KEY  (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_programma_fase_bil_t_programmi FOREIGN KEY (programma_id)
    REFERENCES siac_t_programma(programma_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_programma_tipo_fase_bil_t_programmi FOREIGN KEY (programma_tipo_id)
    REFERENCES siac_d_programma_tipo(programma_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_fase_bil_t_programmi FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_fase_bil_t_programmi FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE TABLE fase_bil_t_cronop
(
  fase_bil_cronop_id SERIAL,
  fase_bil_elab_id INTEGER NOT NULL,
  fase_bil_cronop_ape_tipo varchar not null,
  cronop_id    integer not null,
  programma_id integer not null,
  bil_id INTEGER NOT NULL,
  cronop_new_id integer NULL,
  fl_elab VARCHAR not null default 'N',
  scarto_code VARCHAR,
  scarto_desc VARCHAR,
  data_creazione TIMESTAMP WITHOUT TIME ZONE,
  data_modifica  TIMESTAMP WITHOUT TIME ZONE,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR,
  ente_proprietario_id INTEGER,
  CONSTRAINT pk_fase_bil_t_cronp PRIMARY KEY(fase_bil_cronop_id),
  CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_cronop FOREIGN KEY  (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_cronp_fase_bil_t_cronop FOREIGN KEY (cronop_id)
    REFERENCES siac_t_cronop(cronop_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_programma_fase_bil_t_cronop FOREIGN KEY (programma_id)
    REFERENCES siac_t_programma(programma_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_fase_bil_t_cronop FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_fase_bil_t_cronop FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


insert into fase_bil_d_elaborazione_tipo
(
  fase_bil_elab_tipo_code,
  fase_bil_elab_tipo_desc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select
'APE_GEST_PROGRAMMI',
'APERTURA BILANCIO : RIBALTAMENTO PROGRAMMI-CRONOP',
now(),
'siac-6255',
ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from fase_bil_d_elaborazione_tipo  tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.fase_bil_elab_tipo_code='APE_GEST_PROGRAMMI');