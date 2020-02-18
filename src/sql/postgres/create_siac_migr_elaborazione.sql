/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--- log elaborazioni
drop table if exists siac_t_migr_elaborazione;

create table siac_t_migr_elaborazione
(
    migr_elab_id       serial,
    migr_tipo          varchar(20) not null,
    migr_tipo_elab     varchar(20) not null,
    esito	           varchar(2)  not null,
    messaggio_esito    varchar(1500) not null,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    ente_proprietario_id       INTEGER NOT NULL,
    CONSTRAINT pk_siac_t_migr_elaborazione PRIMARY KEY(migr_elab_id),
    CONSTRAINT siac_t_ente_proprietario_siac_t_migr_elaborazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);