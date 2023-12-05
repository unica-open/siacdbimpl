/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
op table mif_t_ordinativo_ritrasmetti
drop table mif_t_ordinativo_ritrasmetti_log

create table mif_t_ordinativo_ritrasmetti
(
 mif_ord_ritr_id serial,
 mif_ord_id integer not null,
 mif_ord_tipo_id integer not null,
 data_creazione            TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione        TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id      INTEGER NOT NULL,
 login_operazione          VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_ritrasmetti PRIMARY KEY(mif_ord_ritr_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_ritrasm FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ordinativo_mif_t_ordinativo_ritrasm FOREIGN KEY (mif_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_d_ordinativo_tipo_mif_t_ordinativo_ritrasm FOREIGN KEY (mif_ord_tipo_id)
    REFERENCES siac_d_ordinativo_tipo(ord_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE  INDEX idx_mif_t_ordinativo_ritrasm_1 ON mif_t_ordinativo_ritrasmetti
  USING btree (mif_ord_id, ente_proprietario_id);

CREATE  INDEX idx_mif_t_ordinativo_ritrasm_2 ON mif_t_ordinativo_ritrasmetti
  USING btree (mif_ord_tipo_id, ente_proprietario_id);

COMMENT ON TABLE mif_t_ordinativo_ritrasmetti
IS 'Tracciatura dati ordinativi sbloccati per ritrasmissione.';

CREATE TABLE mif_t_ordinativo_ritrasmetti_log
(
 mif_ord_log_id    serial,
 mif_ord_id        integer not null,
 mif_ord_anno      integer not null,
 mif_ord_numero    integer not null,
 mif_ord_tipo_id   integer not null,
 mif_ord_trasm_oil_data    TIMESTAMP WITHOUT TIME ZONE,
 mif_ord_emissione_data    TIMESTAMP WITHOUT TIME ZONE,
 mif_ord_inizio_st_ins     TIMESTAMP WITHOUT TIME ZONE,
 mif_ord_fine_st_ins       TIMESTAMP WITHOUT TIME ZONE,
 mif_ord_inizio_st_tr      TIMESTAMP WITHOUT TIME ZONE,
 mif_ord_fine_st_tr        TIMESTAMP WITHOUT TIME ZONE,
 mif_ord_inizio_st_ann     TIMESTAMP WITHOUT TIME ZONE,
 mif_ord_fine_st_ann       TIMESTAMP WITHOUT TIME ZONE,
 validita_inizio           TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine             TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione            TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica             TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione        TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id      INTEGER NOT NULL,
 login_operazione          VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_ritrasm_log PRIMARY KEY(mif_ord_log_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_ritrasm_log FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ordinativo_mif_t_ordinativo_ritrasm_log FOREIGN KEY (mif_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_d_ordinativo_tipo_mif_t_ordinativo_ritrasm_log FOREIGN KEY (mif_ord_tipo_id)
    REFERENCES siac_d_ordinativo_tipo(ord_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_ritrasmetti_log
IS 'Tracciatura dati ordinativi sbloccati per ritrasmissione - LOG.';


CREATE  INDEX idx_mif_t_ordinativo_ritr_log_1 ON mif_t_ordinativo_ritrasmetti_log
  USING btree (mif_ord_id, ente_proprietario_id);

CREATE  INDEX idx_mif_t_ordinativo_ritr_log_2 ON mif_t_ordinativo_ritrasmetti_log
  USING btree (mif_ord_tipo_id, ente_proprietario_id);
