/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table migr_provvedimento cascade constraints;
drop table migr_provvedimento_scarto cascade constraints;

create table migr_provvedimento
(
 provvedimento_id        number(10)  not null,
 anno_provvedimento      varchar2(4) not null,
 numero_provvedimento    number(10)  not null,
 tipo_provvedimento      varchar2(20)not null,
 sac_provvedimento       varchar2(20)   null,
 oggetto_provvedimento   varchar2(500) null,
 note_provvedimento      varchar2(500) null,
 stato_provvedimento     varchar2(50) not null,
 fl_migrato              varchar2(1) default 'N' not null,
 data_ins                date default sysdate not null,
 ente_proprietario_id number(10) not null
)
tablespace &1;

comment on table migr_provvedimento
  is 'migrazione provvedimenti';
  
alter table migr_provvedimento
  add constraint XPKMIGR_PROVVEDIMENTO primary key (provvedimento_id)
  using index 
  tablespace &2;

--create index XIFMIGR_PROVVEDIMENTO_NR on MIGR_PROVVEDIMENTO (anno_provvedimento,numero_provvedimento)
--tablespace &2;

create table migr_provvedimento_scarto 
(
 provvedimento_scarto_id	number(10)    not null,
 anno_provvedimento       varchar2(4)   not null,
 numero_provvedimento     varchar2(4)   not null,
 tipo_provvedimento       varchar2(20)  not null,
 sac_provvedimento        number(10)    not null,
 motivo_scarto         varchar2(2500) not null,
 ente_proprietario_id  number(10)    not null,
 data_ins              date default sysdate not null
)
tablespace &1; 

comment on table migr_provvedimento_scarto
  is 'tracciatura scarti migrazione provvedimenti';

alter table migr_provvedimento_scarto
  add constraint XPKMIGR_PROVVEDIMENTO_SCARTO primary key (provvedimento_scarto_id)
  using index 
  tablespace &2;
