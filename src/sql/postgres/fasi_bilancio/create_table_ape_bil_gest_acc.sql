/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table fase_bil_t_gest_apertura_acc;

CREATE TABLE fase_bil_t_gest_apertura_acc
(
 fase_bil_gest_ape_acc_id SERIAL,
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
 CONSTRAINT pk_fase_bil_t_gest_ape_acc PRIMARY KEY(fase_bil_gest_ape_acc_id),
 CONSTRAINT siac_t_movgest_id_fase_bil_t_gest_ape_acc FOREIGN KEY (movgest_id)
    REFERENCES siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_acc FOREIGN KEY (movgest_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_gest_ape_acc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_acc FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_acc_el FOREIGN KEY (elem_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_gest_ape_acc FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_id_fase_bil_t_gest_ape_acc1 FOREIGN KEY (movgest_orig_id)
    REFERENCES siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_acc1 FOREIGN KEY (movgest_orig_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_acc1 FOREIGN KEY (bil_orig_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_elem_fase_bil_t_gest_ape_acc_imp2 FOREIGN KEY (elem_orig_id)
    REFERENCES siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_gest_apertura_acc
IS 'Apertura nuovo bilancio gestione - ribaltamento accertamenti residui.';


comment on column fase_bil_t_gest_apertura_acc.elem_id
is 'Identificativo elemento di bilancio di gestione corrente.';


comment on column fase_bil_t_gest_apertura_acc.movgest_id
is 'Identificativo movimento di gestione testata su bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_acc.movgest_ts_id
is 'Identificativo movimento di gestione dettaglio su bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_acc.bil_id
is 'Identificativo di bilancio di gestione corrente.';




