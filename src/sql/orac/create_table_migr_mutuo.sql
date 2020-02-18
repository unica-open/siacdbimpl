/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table migr_mutuo cascade constraint;
drop table migr_voce_mutuo cascade constraint;
drop table migr_mutuo_scarto cascade constraint;
drop table migr_voce_mutuo_scarto cascade constraint;

CREATE TABLE MIGR_MUTUO
(mutuo_id number(10) not null,
 codice_mutuo varchar2(200) not null,
 descrizione varchar2(500),
 tipo_mutuo varchar2(10) not null,
 importo_iniziale number(15,2) not null,
 importo_attuale number(15,2) not null,
 durata varchar2(2) not null,
 numero_registrazione varchar2(15),
 data_inizio varchar2(10) not null,
 data_fine varchar2(10) not null,
 stato_operativo varchar2(1) not null,
 codice_soggetto number(6),
 anno_provvedimento varchar2(4),
 numero_provvedimento number(10),
 tipo_provvedimento varchar2(20),
 sac_provvedimento     varchar2(20)   null,
 oggetto_provvedimento varchar2(500),
 note_provvedimento varchar2(500),
 stato_provvedimento varchar2(50),
 note varchar2(250),
 ente_proprietario_id number(10) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins date default sysdate not null
)
tablespace &1;

comment on table MIGR_MUTUO
  is 'migrazione mutui - anagrafica principale';
    
create index XIFMIGR_MUTUO_NR on MIGR_MUTUO (codice_mutuo)
tablespace &2;

alter table MIGR_MUTUO
  add constraint XPKMIGR_MUTUO primary key (mutuo_id)
  using index 
  tablespace &2;

CREATE TABLE MIGR_VOCE_MUTUO
(voce_mutuo_id number(10) not null,
 codice_voce_mutuo varchar2(200),
 nro_mutuo varchar2 (5),
 descrizione varchar2(500),
 importo_iniziale number(15,2) not null,
 importo_attuale number(15,2) not null,
 tipo_voce_mutuo varchar2(10) not null,
 anno_impegno   varchar2(4) not null,
 numero_impegno number(10)  default 0 null,
 anno_esercizio varchar2(4) not null,
 ente_proprietario_id number(10) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins date default sysdate not null
)
tablespace &1;

comment on table MIGR_VOCE_MUTUO
  is 'migrazione mutui - anagrafica anagrafica voce di mutuo';


alter table MIGR_VOCE_MUTUO
  add constraint XPKMIGR_VOCE_MUTUO primary key (voce_mutuo_id)
  using index 
  tablespace &2;

create index XIFMIGR_VOCE_MUTUO_ID on MIGR_VOCE_MUTUO (nro_mutuo,numero_impegno,anno_impegno,anno_esercizio)
tablespace &2;

create table migr_mutuo_scarto 
(
 mutuo_scarto_id	    number(10)    not null,
 codice_mutuo           varchar2(200) ,
 motivo_scarto          varchar2(2500) not null,
 ente_proprietario_id   number(10)    not null,
 data_ins               date default sysdate not null
)
tablespace &1; 

comment on table migr_mutuo_scarto
  is 'tracciatura scarti migrazione mutui';

alter table migr_mutuo_scarto
  add constraint XPKMIGR_MUTUO_SCARTO primary key (mutuo_scarto_id)
  using index 
  tablespace &2;

create table migr_voce_mutuo_scarto 
(
 voce_mutuo_scarto_id	number(10)    not null,
 nro_mutuo           varchar2(5) ,
 numero_impegno     number(10),
 anno_impegno   		varchar2(4),
 anno_esercizio 		varchar2(4),
 motivo_scarto          varchar2(2500) not null,
 ente_proprietario_id   number(10)    not null,
 data_ins               date default sysdate not null
)
tablespace &1; 

comment on table migr_voce_mutuo_scarto
  is 'tracciatura scarti migrazione voci mutuo';

alter table migr_voce_mutuo_scarto
  add constraint XPKMIGR_VOCE_MUTUO_SCARTO primary key (voce_mutuo_scarto_id)
  using index 
  tablespace &2;
  
create index XIFMIGR_VOCE_MUTUO_SCARTO_IMP on migr_voce_mutuo_scarto (numero_impegno,anno_impegno,anno_esercizio)
tablespace &2;
