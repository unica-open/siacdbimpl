/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 19.04.2016 Sofia - eseguito tutto in PROD-BILMULT
drop table mif_t_ordinativo_sbloccato;
drop table mif_t_ordinativo_sbloccato_log;
drop table mif_t_ordinativo_ritrasmesso;


create table mif_t_ordinativo_sbloccato
(
 mif_ord_sblocca_id serial,
 mif_ord_id         integer not null,
 mif_ord_tipo_id    integer not null,
 mif_ord_trasm_oil_data TIMESTAMP WITHOUT TIME ZONE,
 mif_ord_sblocca_elab_id integer not null,
 mif_ord_sbloccato boolean default false not null,
 validita_inizio    TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine      TIMESTAMP WITHOUT TIME ZONE,
 data_creazione            TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione        TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id      INTEGER NOT NULL,
 login_operazione          VARCHAR(200) NOT NULL,
 login_cancellazione       VARCHAR(200),
 CONSTRAINT pk_mif_t_ordinativo_sblocca PRIMARY KEY(mif_ord_sblocca_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_sblocca FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ordinativo_mif_t_ordinativo_sblocca FOREIGN KEY (mif_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_d_ordinativo_tipo_mif_t_ordinativo_sblocca FOREIGN KEY (mif_ord_tipo_id)
    REFERENCES siac_d_ordinativo_tipo(ord_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE  INDEX idx_mif_t_ordinativo_sblocca_1 ON mif_t_ordinativo_sbloccato
  USING btree (mif_ord_id, ente_proprietario_id);

CREATE  INDEX idx_mif_t_ordinativo_sblocca_2 ON mif_t_ordinativo_sbloccato
  USING btree (mif_ord_tipo_id, ente_proprietario_id);

CREATE  INDEX idx_mif_t_ordinativo_sblocca_3 ON mif_t_ordinativo_sbloccato
  USING btree (mif_ord_sblocca_elab_id, ente_proprietario_id);


COMMENT ON TABLE mif_t_ordinativo_sbloccato
IS 'Tracciatura dati ordinativi trasmessi da sbloccare per ritrasmissione.';

comment on column mif_t_ordinativo_sbloccato.mif_ord_sblocca_elab_id
is 'Identificativo di elaborazione di sblocco ordinativi : identifica un blocco di ordinativi da sbloccare';

CREATE TABLE mif_t_ordinativo_sbloccato_log
(
 mif_ord_log_id    serial,
 mif_ord_sblocca_elab_id integer not null,
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
 CONSTRAINT pk_mif_t_ordinativo_sblocca_log PRIMARY KEY(mif_ord_log_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_sblocca_log FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ordinativo_mif_t_ordinativo_sblocca_log FOREIGN KEY (mif_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_d_ordinativo_tipo_mif_t_ordinativo_sblocca_log FOREIGN KEY (mif_ord_tipo_id)
    REFERENCES siac_d_ordinativo_tipo(ord_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_sbloccato_log
IS 'Tracciatura dati ordinativi sbloccati per ritrasmissione - LOG.';


comment on column mif_t_ordinativo_sbloccato_log.mif_ord_sblocca_elab_id
is 'Identificativo di elaborazione di sblocco ordinativi : identifica un blocco di ordinativi sbloccati';

CREATE  INDEX idx_mif_t_ordinativo_sblocca_log_1 ON mif_t_ordinativo_sbloccato_log
  USING btree (mif_ord_id, ente_proprietario_id);

CREATE  INDEX idx_mif_t_ordinativo_sblocca_log_2 ON mif_t_ordinativo_sbloccato_log
  USING btree (mif_ord_tipo_id, ente_proprietario_id);


CREATE  INDEX idx_mif_t_ordinativo_sblocca_log_3 ON mif_t_ordinativo_sbloccato_log
  USING btree (mif_ord_sblocca_elab_id, ente_proprietario_id);

create table mif_t_ordinativo_ritrasmesso
(
 mif_ord_ritrasm_id serial,
 mif_ord_id         integer not null,
 mif_ord_tipo_id    integer not null,
 mif_ord_trasm_oil_data TIMESTAMP WITHOUT TIME ZONE,
 mif_ord_ritrasm_elab_id integer not null,
 validita_inizio    TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine      TIMESTAMP WITHOUT TIME ZONE,
 data_creazione            TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione        TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id      INTEGER NOT NULL,
 login_operazione          VARCHAR(200) NOT NULL,
 login_cancellazione       VARCHAR(200),
 CONSTRAINT pk_mif_t_ordinativo_ritrasm PRIMARY KEY(mif_ord_ritrasm_id),
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

CREATE  INDEX idx_mif_t_ordinativo_ritrasm_ord ON mif_t_ordinativo_ritrasmesso
  USING btree (mif_ord_id, ente_proprietario_id);

CREATE  INDEX idx_mif_t_ordinativo_ritrasm_tipo ON mif_t_ordinativo_ritrasmesso
  USING btree (mif_ord_tipo_id, ente_proprietario_id);

CREATE  INDEX idx_mif_t_ordinativo_ritrasm_elab ON mif_t_ordinativo_ritrasmesso
  USING btree (mif_ord_ritrasm_elab_id, ente_proprietario_id);


COMMENT ON TABLE mif_t_ordinativo_ritrasmesso
IS 'Tracciatura dati ordinativi da ritrasmettere.';

comment on column mif_t_ordinativo_ritrasmesso.mif_ord_ritrasm_elab_id
is 'Identificativo di elaborazione di ritrasmissione ordinativi : identifica un blocco di ordinativi da ritrasmettere.';


-- inserire per ogni ente  vedi scritp insert_mif_d_flusso_elaborato_tipo_SBLOCCA_RITRASM.sql
insert into mif_d_flusso_elaborato_tipo
(flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc, flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('SBLOCCA_MIF','ELABORAZIONI SBLOCCO DATI MIF MANDMIF-REVMIF','NO FLUSSO','2016-01-01','admin',13);

insert into mif_d_flusso_elaborato_tipo
(flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc, flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('RITRASM_MIF','ELABORAZIONI SBLOCCO DATI MIF MANDMIF-REVMIF','NO FLUSSO','2016-01-01','admin',13);

