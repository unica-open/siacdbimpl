/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE migr_elaborazione (
  migr_elab_id number(10) not null,
  migr_tipo VARCHAR2(50),
  migr_tipo_elab VARCHAR2(50),
  esito VARCHAR(2),
  messaggio_esito VARCHAR(1500) NOT NULL,
  data_creazione date default sysdate not null,
  ente_proprietario_id number(10) not null
) 
tablespace &1;

alter table migr_elaborazione
  add constraint XPKMIGR_ELABORAZIONE primary key (migr_elab_id)
  using index 
  tablespace &2;
  
create sequence migr_migr_elab_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;


Alter table migr_elaborazione modify migr_tipo VARCHAR2(50);
Alter table migr_elaborazione modify migr_tipo_elab VARCHAR2(50);
