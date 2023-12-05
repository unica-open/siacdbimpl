/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create table MIGR_ELABORAZIONE
(
  migr_elab_id         NUMBER(10) not null,
  migr_tipo            VARCHAR2(50),
  migr_tipo_elab       VARCHAR2(50),
  esito                VARCHAR2(2),
  messaggio_esito      VARCHAR2(1500) not null,
  data_creazione       DATE default sysdate not null,
  ente_proprietario_id NUMBER(10) not null
);
-- creare sequence
create sequence MIGR_MIGR_ELAB_ID_SEQ
minvalue 1
maxvalue 999999999999999999999999999
start with 1881
increment by 1
cache 20;
