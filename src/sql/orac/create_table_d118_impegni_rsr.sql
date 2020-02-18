/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Create table
create table D118_IMPEGNI_RSR
(
  anno_esercizio      VARCHAR2(4) not null,
  annoimp             VARCHAR2(4) not null,
  nimp                NUMBER(6) not null,
  anno_esercizio_orig VARCHAR2(4) not null,
  annoimp_orig        VARCHAR2(4) not null,
  nimp_orig           NUMBER(6) not null
)
tablespace &1
  pctfree 10
  pctused 40
  initrans 1
  maxtrans 255
  storage
  (
    initial 128K
    next 64K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
-- Create/Recreate indexes 
create index I_NEW_IMPEGNI_RSR on D118_IMPEGNI_RSR (ANNO_ESERCIZIO_ORIG, ANNOIMP_ORIG, NIMP_ORIG)
  tablespace &2
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 400K
    next 64K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table D118_IMPEGNI_RSR
  add constraint XPKD118_IMPEGNI_RSR primary key (ANNO_ESERCIZIO, ANNOIMP, NIMP)
  using index 
  tablespace &2
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 400K
    next 64K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
