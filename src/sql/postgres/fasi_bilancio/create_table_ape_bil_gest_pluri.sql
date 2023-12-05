/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
CREATE TABLE fase_bil_t_gest_apertura_pluri
(
 fase_bil_gest_ape_pluri_id SERIAL,
 movgest_id    integer null,
 movgest_ts_id integer null,
 elem_id       integer null,
 bil_id        integer null,
 movgest_tipo  varchar(10) null,
 fl_elab       char not null default 'N',
 fase_bil_elab_id     integer not null,
 movgest_orig_id      integer not null,
 movgest_orig_ts_id   integer not null,
 elem_orig_id         integer not null,
 bil_orig_id          integer not null,
 scarto_code        varchar(50),
 scarto_desc          varchar(500),
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_t_gest_ape_pluri PRIMARY KEY(fase_bil_gest_ape_pluri_id),
 CONSTRAINT siac_t_movgest_id_fase_bil_t_gest_ape_pluri FOREIGN KEY (movgest_id)
    REFERENCES siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_pluri FOREIGN KEY (movgest_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_gest_ape_pluri FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_pluri FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_pluri_id FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_gest_ape_pluri FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_id_fase_bil_t_gest_ape_pluri1 FOREIGN KEY (movgest_orig_id)
    REFERENCES siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_pluri1 FOREIGN KEY (movgest_orig_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_pluri1 FOREIGN KEY (bil_orig_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_pluri_id1 FOREIGN KEY (elem_orig_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_gest_apertura_pluri
IS 'Apertura nuovo bilancio gestione - ribaltamento movimenti pluriennali';


comment on column fase_bil_t_gest_apertura_pluri.elem_id
is 'Identificativo elemento di bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_pluri.movgest_id
is 'Identificativo movimento di gestione testata su bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_pluri.movgest_ts_id
is 'Identificativo movimento di gestione dettaglio su bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_pluri.bil_id
is 'Identificativo di bilancio di gestione corrente.';



comment on column fase_bil_t_gest_apertura_pluri.elem_orig_id
is 'Identificativo elemento di bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_pluri.movgest_orig_id
is 'Identificativo movimento di gestione testata su bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_pluri.movgest_orig_ts_id
is 'Identificativo movimento di gestione dettaglio su bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_pluri.bil_orig_id
is 'Identificativo di bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_pluri.fl_elab
is 'Flag elaborazione [N: non elaborato;S: elaborato correttamente;X: scartato]';

comment on column fase_bil_t_gest_apertura_pluri.movgest_tipo
is 'Tipo movimento [IMP,SIM,ACC,SAC].';