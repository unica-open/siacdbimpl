/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿/* DROP DA COMMENTARE SE LO SCRIPT VIENE ESEGUITO LA PRIMA VOLTA SU UN DB */

drop table fase_gen_t_elaborazione_fineanno_saldi;
drop table fase_gen_t_elaborazione_fineanno_det;
drop table fase_gen_t_elaborazione_fineanno_log;
drop table fase_gen_t_elaborazione_fineanno;
drop table fase_gen_d_elaborazione_fineanno_tipo_det;
drop table fase_gen_d_elaborazione_fineanno_tipo;

/* CREAZIONE DELLE TABELLE */

CREATE TABLE fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_id SERIAL,
  fase_gen_elab_tipo_code VARCHAR(50) NOT NULL,
  fase_gen_elab_tipo_desc VARCHAR(200) NOT NULL,
  causale_ep_id    integer  null,
  pdce_conto_ep_id integer  null,
  ordine           integer  not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_fase_gen_d_elab_fineanno_tipo PRIMARY KEY(fase_gen_elab_tipo_id),
  CONSTRAINT siac_t_causale_ep_fase_gen_d_elab_fineanno_tipo FOREIGN KEY (causale_ep_id)
    REFERENCES siac_t_causale_ep(causale_ep_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_pdce_conto_fase_gen_d_elab_fineanno_tipo FOREIGN KEY (pdce_conto_ep_id)
    REFERENCES siac_t_pdce_conto(pdce_conto_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_fase_gen_d_elab_fineanno_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_gen_d_elaborazione_fineanno_tipo
IS 'Tipologie di elaborazioni su chiusure/aperture GEN-fine anno.';


CREATE TABLE fase_gen_d_elaborazione_fineanno_tipo_det
(
  fase_gen_elab_tipo_det_id   serial,
  fase_gen_elab_tipo_id       integer not null,
  pdce_conto_id               integer not null,
  pdce_conto_segno	          varchar(10) not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_fase_gen_d_elaborazione_fineanno_tipo_det PRIMARY KEY(fase_gen_elab_tipo_det_id),
  CONSTRAINT siac_t_ente_proprietario_fase_gen_d_elaborazione_fineanno_tipo_det FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_pdce_conto_fase_gen_d_elaborazione_fineanno_tipo_det FOREIGN KEY (pdce_conto_id)
    REFERENCES siac_t_pdce_conto(pdce_conto_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT fase_gen_d_elaborazione_fineanno_tipo_fase_gen_d_elaborazione_fineanno_tipo_det FOREIGN KEY (fase_gen_elab_tipo_id)
    REFERENCES fase_gen_d_elaborazione_fineanno_tipo(fase_gen_elab_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_gen_d_elaborazione_fineanno_tipo_det
IS 'Tipologie di elaborazioni su chiusure/aperture GEN-fine anno. Dettagli configurazione.';


CREATE TABLE fase_gen_t_elaborazione_fineanno
(
  fase_gen_elab_id serial,
  fase_gen_elab_esito VARCHAR(100) NOT NULL,
  fase_gen_elab_esito_msg VARCHAR(500) NOT NULL,
  bil_id      integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_fase_gen_t_elaborazione_fineanno PRIMARY KEY(fase_gen_elab_id),
  CONSTRAINT siac_t_ente_proprietario_fase_gen_t_elab_fineanno FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_fase_gen_t_elab_fineanno FOREIGN KEY (bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_gen_t_elaborazione_fineanno
IS 'Elaborazioni chiusure/aperture GEN fine anno.';


CREATE TABLE fase_gen_t_elaborazione_fineanno_log (
  fase_gen_elab_log_id SERIAL,
  fase_gen_elab_id INTEGER NOT NULL,
  fase_gen_elab_log_operazione VARCHAR(1000) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_fase_gen_t_elaborazione_fineanno_log PRIMARY KEY(fase_gen_elab_log_id),
  CONSTRAINT fase_gen_t_elaborazione_fineanno_fase_gen_t_elaborazione_fineanno_log FOREIGN KEY (fase_gen_elab_id)
    REFERENCES fase_gen_t_elaborazione_fineanno(fase_gen_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_fase_gen_t_elaborazione_fineanno_log FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_gen_t_elaborazione_fineanno_log
IS 'Elaborazioni GEN fine anno - LOG.';




CREATE TABLE fase_gen_t_elaborazione_fineanno_det
(
  fase_gen_elab_det_id serial,
  fase_gen_elab_id integer not null,
  fase_gen_elab_tipo_id INTEGER NOT NULL,
  fase_gen_det_elab_esito VARCHAR(100) NOT NULL,
  fase_gen_det_elab_esito_msg VARCHAR(500) NOT NULL,
  pnota_id   integer null,
  movep_id   integer null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_fase_gen_t_elaborazione_fineanno_det PRIMARY KEY(fase_gen_elab_det_id),
  CONSTRAINT fase_gen_d_elab_fineanno_tipo_fase_gen_t_elab_fineanno_det FOREIGN KEY (fase_gen_elab_tipo_id)
    REFERENCES fase_gen_d_elaborazione_fineanno_tipo(fase_gen_elab_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_fase_gen_t_elab_fineanno_det FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT fase_gen_t_elab_fineanno_fase_gen_t_elab_fineanno_det FOREIGN KEY (fase_gen_elab_id)
    REFERENCES fase_gen_t_elaborazione_fineanno(fase_gen_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prima_nota_fase_gen_t_elab_fineanno_det FOREIGN KEY (pnota_id)
    REFERENCES siac_t_prima_nota(pnota_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_movep_fase_gen_t_elab_fineanno_det FOREIGN KEY (movep_id)
    REFERENCES siac_t_mov_ep(movep_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_gen_t_elaborazione_fineanno_det
IS 'Elaborazioni-dettaglio chiusure/aperture GEN fine anno.';


CREATE TABLE fase_gen_t_elaborazione_fineanno_saldi
(
  fase_gen_elab_saldi_id serial,
  fase_gen_elab_det_id integer not null,
  pdce_conto_id         integer not null,
  pdce_conto_segno	    varchar(10) not null,
  pdce_conto_dare       numeric default 0 not null,
  pdce_conto_avere      numeric default 0 not null,
  pdce_conto_saldo_errato boolean default false not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_fase_gen_t_elaborazione_fineanno_saldi PRIMARY KEY(fase_gen_elab_saldi_id),
  CONSTRAINT fase_gen_t_elab_fineanno_det_fase_gen_t_elab_fineanno_saldi FOREIGN KEY (fase_gen_elab_det_id)
    REFERENCES fase_gen_t_elaborazione_fineanno_det(fase_gen_elab_det_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_fase_gen_t_elab_fineanno_saldi FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_pdce_conto_fase_gen_t_elab_fineanno_saldi FOREIGN KEY (pdce_conto_id)
    REFERENCES siac_t_pdce_conto(pdce_conto_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE fase_gen_t_elaborazione_fineanno_saldi
IS 'Elaborazioni- chiusure/aperture GEN fine anno- calcolo saldi conti.';



