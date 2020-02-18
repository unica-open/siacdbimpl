/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table fase_bil_t_gest_apertura_liq;
drop table fase_bil_t_gest_apertura_liq_imp;

CREATE TABLE fase_bil_t_gest_apertura_liq
(
 fase_bil_gest_ape_liq_id SERIAL,
 liq_id        integer null,
 movgest_id    integer null,
 movgest_ts_id integer null,
 elem_id       integer null,
 bil_id        integer null,
 liq_importo   numeric not null default 0,
 fl_elab       char not null default 'N',
 fase_bil_elab_id     integer not null,
 liq_orig_id          integer not null,
 liq_orig_importo   numeric not null default 0,
 liq_orig_pagato    numeric not null default 0,
 movgest_ts_tipo       varchar(10)  null,
 movgest_orig_id      integer  null,
 movgest_orig_ts_id   integer  null,
 elem_orig_id         integer  null,
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
 CONSTRAINT pk_fase_bil_t_gest_ape_liq PRIMARY KEY(fase_bil_gest_ape_liq_id),
 CONSTRAINT siac_t_liquidazione_id_fase_bil_t_gest_ape_liq FOREIGN KEY (liq_id)
    REFERENCES siac_t_liquidazione(liq_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_id_fase_bil_t_gest_ape_liq FOREIGN KEY (movgest_id)
    REFERENCES siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_liq FOREIGN KEY (movgest_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_gest_ape_liq FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_liq FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_liq_id FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_gest_ape_liq FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_liquidazione_id_fase_bil_t_gest_ape_liq1 FOREIGN KEY (liq_orig_id)
    REFERENCES siac_t_liquidazione(liq_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_id_fase_bil_t_gest_ape_liq1 FOREIGN KEY (movgest_orig_id)
    REFERENCES siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_liq1 FOREIGN KEY (movgest_orig_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_liq1 FOREIGN KEY (bil_orig_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_liq_id1 FOREIGN KEY (elem_orig_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_gest_apertura_liq
IS 'Apertura nuovo bilancio gestione - ribaltamento liquidazioni residue';


comment on column fase_bil_t_gest_apertura_liq.elem_id
is 'Identificativo elemento di bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_liq.liq_id
is 'Identificativo liquidazione testata su bilancio di gestione corrente.';


comment on column fase_bil_t_gest_apertura_liq.movgest_id
is 'Identificativo movimento di gestione testata su bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_liq.movgest_ts_id
is 'Identificativo movimento di gestione dettaglio su bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_liq.bil_id
is 'Identificativo di bilancio di gestione corrente.';


comment on column fase_bil_t_gest_apertura_liq.liq_orig_id
is 'Identificativo liquidazione origine [precedente].';


comment on column fase_bil_t_gest_apertura_liq.elem_orig_id
is 'Identificativo elemento di bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_liq.movgest_orig_id
is 'Identificativo movimento di gestione testata su bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_liq.movgest_orig_ts_id
is 'Identificativo movimento di gestione dettaglio su bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_liq.bil_orig_id
is 'Identificativo di bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_liq.fl_elab
is 'Flag elaborazione [N: non elaborato;S: elaborato correttamente;X: scartato]';


CREATE TABLE fase_bil_t_gest_apertura_liq_imp
(
 fase_bil_gest_ape_liq_imp_id SERIAL,
 movgest_id    integer null,
 movgest_ts_id integer null,
 elem_id       integer null,
 bil_id        integer null,
 imp_importo   numeric not null default 0,
 fl_elab       char not null default 'N',
 fase_bil_elab_id     integer not null,
 movgest_ts_tipo       varchar(10)  null,
 movgest_orig_id      integer  null,
 movgest_orig_ts_id   integer  null,
 imp_orig_importo   numeric not null default 0,
 elem_orig_id         integer  null,
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
 CONSTRAINT pk_fase_bil_t_gest_ape_liq_imp PRIMARY KEY(fase_bil_gest_ape_liq_imp_id),
 CONSTRAINT siac_t_movgest_id_fase_bil_t_gest_ape_liq_imp FOREIGN KEY (movgest_id)
    REFERENCES siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_liq_imp FOREIGN KEY (movgest_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_gest_ape_liq_imp FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_liq_imp FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_liq_imp_el FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_gest_ape_liq_imp FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_id_fase_bil_t_gest_ape_imp1 FOREIGN KEY (movgest_orig_id)
    REFERENCES siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_imp1 FOREIGN KEY (movgest_orig_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_imp1 FOREIGN KEY (bil_orig_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_liq_imp2 FOREIGN KEY (elem_orig_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_gest_apertura_liq_imp
IS 'Apertura nuovo bilancio gestione - ribaltamento impegni res per liquidazioni residue';


comment on column fase_bil_t_gest_apertura_liq_imp.elem_id
is 'Identificativo elemento di bilancio di gestione corrente.';


comment on column fase_bil_t_gest_apertura_liq_imp.movgest_id
is 'Identificativo movimento di gestione testata su bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_liq_imp.movgest_ts_id
is 'Identificativo movimento di gestione dettaglio su bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_liq_imp.bil_id
is 'Identificativo di bilancio di gestione corrente.';




comment on column fase_bil_t_gest_apertura_liq_imp.elem_orig_id
is 'Identificativo elemento di bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_liq_imp.movgest_orig_id
is 'Identificativo movimento di gestione testata su bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_liq_imp.movgest_orig_ts_id
is 'Identificativo movimento di gestione dettaglio su bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_liq_imp.bil_orig_id
is 'Identificativo di bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_liq_imp.fl_elab
is 'Flag elaborazione [N: non elaborato;S: elaborato correttamente;X: scartato]';