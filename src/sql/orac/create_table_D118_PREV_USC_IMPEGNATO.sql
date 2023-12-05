/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Create table
drop table D118_PREV_USC_IMPEGNATO;

create table D118_PREV_USC_IMPEGNATO
(
  anno_creazione      VARCHAR2(4) not null,
  anno_esercizio      VARCHAR2(4) not null,
  nro_capitolo        NUMBER(6) not null,
  nro_articolo        NUMBER(3) not null,
  numero_ueb          varchar(20) default 1 not null,
  gia_impegnato_anno1 NUMBER(16,2) not null,
  gia_impegnato_anno2 NUMBER(16,2) not null,
  gia_impegnato_anno3 NUMBER(16,2) not null,
  ente_proprietario_id number(3) not null
)
tablespace &1;

-- Create/Recreate primary, unique and foreign key constraints 
alter table D118_PREV_USC_IMPEGNATO
  add constraint XPKD118_PREV_USC_IMPEGNATO primary key (ANNO_CREAZIONE, ANNO_ESERCIZIO, NRO_CAPITOLO, NRO_ARTICOLO,numero_ueb,ente_proprietario_id)
  using index 
  tablespace &2;
  
  


  
  
  
