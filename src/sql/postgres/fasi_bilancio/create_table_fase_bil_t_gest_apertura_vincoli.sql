/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table fase_bil_t_gest_apertura_vincoli;


CREATE TABLE fase_bil_t_gest_apertura_vincoli
(
 fase_bil_gest_ape_vinc_id SERIAL,
 movgest_ts_r_id integer null,
 movgest_ts_a_id integer null,
 movgest_ts_b_id integer null,
 importo_vinc    numeric null,
 bil_id          integer null,
 fl_elab         char not null default 'N',
 fase_bil_elab_id       integer not null,
 movgest_orig_ts_a_id   integer not null,
 movgest_orig_ts_b_id   integer not null,
 movgest_orig_ts_r_id   integer not null,
 bil_orig_id            integer not null,
 importo_orig_vinc      numeric null,
 importo_orig_pag_vinc  numeric null,
 scarto_code            varchar(50),
 scarto_desc            varchar(500),
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione  TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica   TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_fase_bil_t_gest_ape_vinc PRIMARY KEY(fase_bil_gest_ape_vinc_id),
 CONSTRAINT siac_r_movgest_ts_id_fase_bil_t_gest_ape_vinc FOREIGN KEY (movgest_ts_r_id)
    REFERENCES siac_r_movgest_ts(movgest_ts_r_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_r_movgest_ts_id_fase_bil_t_gest_ape_vinc1 FOREIGN KEY (movgest_orig_ts_r_id)
    REFERENCES siac_r_movgest_ts(movgest_ts_r_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_vinc_a FOREIGN KEY (movgest_ts_a_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_vinc_b FOREIGN KEY (movgest_ts_b_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ente_proprietario_fase_bil_t_gest_ape_vinc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_vinc FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_gest_ape_vinc FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_vinc_a1 FOREIGN KEY (movgest_orig_ts_a_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_id_fase_bil_t_gest_ape_vinc_b1 FOREIGN KEY (movgest_orig_ts_b_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_id_fase_bil_t_gest_ape_vinc1 FOREIGN KEY (bil_orig_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_bil_t_gest_apertura_vincoli
IS 'Apertura nuovo bilancio gestione - ribaltamento vincoli movimenti';



comment on column fase_bil_t_gest_apertura_vincoli.movgest_ts_a_id
is 'Identificativo accertamento  su bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_vincoli.movgest_ts_b_id
is 'Identificativo impegno  su bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_vincoli.bil_id
is 'Identificativo di bilancio di gestione corrente.';

comment on column fase_bil_t_gest_apertura_vincoli.movgest_orig_ts_a_id
is 'Identificativo accertamento su bilancio di gestione origine [precedente].';

comment on column fase_bil_t_gest_apertura_vincoli.movgest_orig_ts_b_id
is 'Identificativo impegno su bilancio di gestione origine [precedente].';


comment on column fase_bil_t_gest_apertura_vincoli.fl_elab
is 'Flag elaborazione [N: non elaborato;S: elaborato correttamente;X: scartato]';