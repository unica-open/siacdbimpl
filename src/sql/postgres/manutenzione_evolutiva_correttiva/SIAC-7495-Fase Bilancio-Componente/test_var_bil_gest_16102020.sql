/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


select *
from fase_bil_d_elaborazione_tipo tipo
where tipo.ente_proprietario_id=2

insert into fase_bil_d_elaborazione_tipo
(
  fase_bil_elab_tipo_code,
  fase_bil_elab_tipo_desc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select
'APE_VAR_GEST',
'Variazioni di bilancio - gestione',
now(),
'SIAC-7495',
ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id =2
and   not exists
(
select 1
from fase_bil_d_elaborazione_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.fase_bil_elab_tipo_code='APE_VAR_GEST'
);

drop table if exists siac.fase_bil_t_variazione_gest
CREATE TABLE siac.fase_bil_t_variazione_gest
 (
  fase_bil_var_gest_id SERIAL,
  fase_bil_elab_id INTEGER NOT NULL,
  variazione_id    integer not null,
  bil_id INTEGER NOT NULL,
  variazione_stato_id integer not null,
  variazione_stato_tipo_id integer not null,
  variazione_stato_new_id integer,
  variazione_stato_tipo_new_id integer,
  fl_cambia_stato boolean,
  fl_applica_var boolean,
  fl_elab VARCHAR DEFAULT 'N'::character varying NOT NULL,
  scarto_code VARCHAR,
  scarto_desc VARCHAR,
  data_creazione TIMESTAMP WITHOUT TIME ZONE default now(),
  data_modifica TIMESTAMP WITHOUT TIME ZONE,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR,
  ente_proprietario_id INTEGER,
  CONSTRAINT pk_fase_bil_t_var_gest PRIMARY KEY(fase_bil_var_gest_id),
  CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_var_gest FOREIGN KEY (fase_bil_elab_id)
    REFERENCES siac.fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_fase_bil_t_var_gest FOREIGN KEY (bil_id)
    REFERENCES siac.siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_var_fase_bil_t_var_gest FOREIGN KEY (variazione_id)
    REFERENCES siac.siac_t_variazione(variazione_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_fase_bil_t_var_gest FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

alter table siac.fase_bil_t_variazione_gest owner to siac;