/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table fase_bil_t_prev_approva_simula;

CREATE TABLE fase_bil_t_prev_approva_simula
(
 fase_bil_prev_simula_id SERIAL,
 fase_bil_elab_id   integer not null,
 bil_id       integer not null,
 periodo_id   integer not null,
 elem_tipo    char(1) not null,
 elem_prev_id integer null,
 elem_gest_id integer null,
 elem_code    VARCHAR(200) NOT NULL,
 elem_code2   VARCHAR(200) NOT NULL,
 elem_code3   VARCHAR(200) DEFAULT '1'::character varying NOT NULL,
 stanziamento numeric default 0 not null,
 stanziamento_cassa numeric default 0 not null,
 tot_impacc   numeric default 0 not null,
 disponibile  numeric default 0 not null,
 tot_ordinativi     numeric default 0 not null,
 disponibile_cassa  numeric default 0 not null,
 programma         varchar(50),
 macroaggregato    varchar(50),
 categoria         varchar(50),
 piano_conti_fin   varchar(50),
 programma_gest         varchar(50),
 macroaggregato_gest    varchar(50),
 categoria_gest         varchar(50),
 piano_conti_fin_gest   varchar(50),
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_t_prev_approva_simula PRIMARY KEY(fase_bil_prev_simula_id),
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_prev_approva_simula FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_prev_approva_simula FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_approva_simula_prev_id FOREIGN KEY (elem_prev_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_prev_approva_simula_gest_id FOREIGN KEY (elem_gest_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_periodo_id_fase_bil_t_prev_approva_simula FOREIGN KEY (periodo_id)
    REFERENCES siac_t_periodo(periodo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_id_fase_bil_t_prev_approva_simula FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_prev_approva_simula
IS 'Approvazione bilancio previsione - simulazione per controllo disponibilita impegnato-accertato';


comment on column fase_bil_t_prev_approva_simula.elem_prev_id
is 'Identificativo elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_approva_simula.elem_gest_id
is 'Identificativo elemento di bilancio di gestione.';

comment on column fase_bil_t_prev_approva_simula.elem_code
is 'Identificativo logico elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_approva_simula.elem_code2
is 'Identificativo logico elemento di bilancio di previsione.';

comment on column fase_bil_t_prev_approva_simula.elem_code3
is 'Identificativo logico elemento di bilancio di previsione.';




CREATE UNIQUE INDEX idx_fase_bil_t_prev_approva_simula_1 ON fase_bil_t_prev_approva_simula
  USING btree (elem_prev_id , periodo_id,fase_bil_elab_id,validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE UNIQUE INDEX idx_fase_bil_t_prev_approva_simula_2 ON fase_bil_t_prev_approva_simula
  USING btree (elem_prev_id , periodo_id , validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

