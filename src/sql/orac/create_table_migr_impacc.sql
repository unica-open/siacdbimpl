/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- tabelle stage ORACLE

drop table migr_impegno cascade constraints;
drop table migr_accertamento cascade constraints;
drop table migr_impegno_accertamento cascade constraints;
drop table migr_classif_impacc cascade constraints;
drop table migr_impegno_scarto cascade constraints;
drop table migr_accertamento_scarto cascade constraints;

-- DAVIDE - 09.03.016 aggiunta per modifiche Impegni / Accertamenti
drop table migr_impegno_modifica cascade constraints;
drop table migr_accertamento_mod cascade constraints;
drop table migr_impegno_modscarto cascade constraints;
drop table migr_accertamento_modsc cascade constraints;

-- tabelle da non cancellare, eventualmente creare per la compilazione del plsql
--drop table TABPROVVED_ENTI cascade constraints;
--drop table DELIBERE cascade constraints;
--drop table IMPEGNO_COGE cascade constraints;
--drop table ACCERTAMENTO_COGE cascade constraints;
--drop table determine cascade constraints;
--drop table IMPEGNO_ACCERTAMENTI cascade constraints;

create table migr_impegno
(
 impegno_id              number(10)  not null,
 tipo_movimento          varchar2(1) not null,
 anno_esercizio          varchar2(4) not null,
 anno_impegno            varchar2(4) not null,
 numero_impegno          number(10)  default 0 null,
 numero_subimpegno       number(10)  default 0 null,
 pluriennale             varchar2(1)   null,
 capo_riacc              varchar2(1)   null,
 numero_capitolo         number(10)    null,
 numero_articolo         number(10)    null,
 numero_ueb              varchar2 (50)    null,
 data_emissione          varchar2 (10) null,
 data_scadenza           varchar2 (10) null,
 stato_operativo         varchar2(1)   not null,
 importo_iniziale        NUMBER(15,2)  default 0 not null,
 importo_attuale         NUMBER(15,2)  default 0 not null,
 descrizione             varchar2(500)  null,
 anno_capitolo_orig      varchar2(4)   null,
 numero_capitolo_orig    number(10)    null,
 numero_articolo_orig    number(10)    null,
 numero_ueb_orig         varchar2 (50)    null,
 anno_provvedimento      varchar2(4)   null,
 numero_provvedimento    number(10)    null,
 tipo_provvedimento      varchar2(20) null,
 sac_provvedimento       varchar2(20)   null,
 oggetto_provvedimento   varchar2(500) null,
 note_provvedimento      varchar2(500) null,
 stato_provvedimento     varchar2(50)  null,
 soggetto_determinato    varchar2(1)   default 'N' not null,
 codice_soggetto         number(10)    null,
 classe_soggetto         VARCHAR2(250) null,
 nota                    VARCHAR2(250) null,
 cup                     varchar2(15)  null,
 cig                     varchar2(10)  null,
 tipo_impegno            varchar2(15)  null,
 anno_impegno_plur       varchar2(4)   null,
 numero_impegno_plur     number(10)    null,
 anno_impegno_riacc      varchar2(4)   null,
 numero_impegno_riacc    number(10)    null,
 opera                   VARCHAR2(50)  null,
 cod_interv_class        VARCHAR2(50)  null,
 pdc_finanziario         VARCHAR2(50)  null,
 missione                VARCHAR2(50)  null,
 programma               VARCHAR2(50)  null,
 cofog                   VARCHAR2(50)  null,
 transazione_ue_spesa    VARCHAR2(50)  null,
 siope_spesa             VARCHAR2(50)  null,
 spesa_ricorrente        VARCHAR2(50)  null,
 perimetro_sanitario_spesa VARCHAR2(50) null,
 politiche_regionali_unitarie	VARCHAR2(50) null,
 pdc_economico_patr	          VARCHAR2(50) null,
 CLASSIFICATORE_1	            varchar2(250) null,
 CLASSIFICATORE_2	            varchar2(250) null,
 CLASSIFICATORE_3	            varchar2(250) null,
 CLASSIFICATORE_4	            varchar2(250) null,
 CLASSIFICATORE_5	            varchar2(250) null,
 ente_proprietario_id number(10) not null
 , parere_finanziario number(1) default 0
-- ,visto_ragioneria varchar2(1)   default 'N' not null
)
tablespace &1;

comment on table migr_impegno
  is 'migrazione impegni - subimpegni';
  
comment on column migr_impegno.tipo_movimento
  is 'I-impegno S-subimpegno';

 
alter table migr_impegno
  add constraint XPKMIGR_IMPEGNO primary key (impegno_id)
  using index 
  tablespace &2;

create index XIFMIGR_IMPEGNO_NR on MIGR_IMPEGNO (numero_impegno,anno_impegno,anno_esercizio)
tablespace &2;

create index XIFMIGR_IMPEGNO_IMP on MIGR_IMPEGNO (NUMERO_IMPEGNO, NUMERO_SUBIMPEGNO, ANNO_IMPEGNO, ANNO_ESERCIZIO)
  tablespace &2;

create table migr_accertamento
(
 accertamento_id      	number(10)  not null,
 tipo_movimento	        varchar2(1) not null,
 anno_esercizio	        varchar2(4) not null,
 anno_accertamento	    varchar2(4) not null,
 numero_accertamento	  number(10)  default 0 null,
 numero_subaccertamento	number(10)  default 0 null,
 pluriennale	          varchar2(1) null,
 capo_riacc	            varchar2(1) null,
 numero_capitolo	      number(10)  null,
 numero_articolo	      number(10)  null,
 numero_ueb	            varchar2 (50)  null,
 data_emissione	        varchar2 (10) null,
 data_scadenza	        varchar2 (10) null,
 stato_operativo	      varchar2(1)   not null,
 importo_iniziale	      NUMBER(15,2)  default 0 not null,
 importo_attuale	      NUMBER(15,2)  default 0 not null,
 descrizione	          varchar2(500)  null,
 anno_capitolo_orig	    varchar2(4)   null,
 numero_capitolo_orig	  number(10)    null,
 numero_articolo_orig	  number(10)    null,
 numero_ueb_orig	      varchar2 (50)    null,
 anno_provvedimento	    varchar2(4)   null,
 numero_provvedimento	  number(10)    null,
 tipo_provvedimento	    varchar2(20) null,
 sac_provvedimento varchar2(20)  null,
 oggetto_provvedimento	 varchar2(500) null,
 note_provvedimento	     varchar2(500) null,
 stato_provvedimento	   varchar2(50)  null,
 soggetto_determinato	   varchar2(1)  default 'N' not null,
 codice_soggetto	       number(10)    null,
 classe_soggetto	       VARCHAR2(250) null,
 nota	                        VARCHAR2(150) null,
 automatico	                  varchar2(1) default 'N' not null,
 anno_accertamento_plur	      varchar2(4) null,
 numero_accertamento_plur	    number(10) null,
 anno_accertamento_riacc	    varchar2(4) null,
 numero_accertamento_riacc    number(10) null,
 opera 	                      VARCHAR2(50) null,
 pdc_finanziario	            VARCHAR2(50) null,
 transazione_ue_entrata	      VARCHAR2(50) null,
 siope_entrata	              VARCHAR2(50) null,
 entrata_ricorrente	          VARCHAR2(50) null,
 perimetro_sanitario_entrata	VARCHAR2(50) null,
 pdc_economico_patr	          VARCHAR2(50) null,
 CLASSIFICATORE_1	            varchar2(250)  null,
 CLASSIFICATORE_2	            varchar2(250)  null,
 CLASSIFICATORE_3	            varchar2(250)  null,
 CLASSIFICATORE_4	            varchar2(250)  null,
 CLASSIFICATORE_5	            varchar2(250)  null,
 ente_proprietario_id         number(10)     not null
 , parere_finanziario         number(1) default 0
)
tablespace &1;

comment on table migr_accertamento
  is 'migrazione accertamenti - subaccertamenti';
  
comment on column migr_accertamento.tipo_movimento
  is 'A-accertamento S-subaccertamento';

 
alter table migr_accertamento
  add constraint XPKMIGR_ACCERTAMENTO primary key (accertamento_id)
  using index 
  tablespace &2;
  

create table migr_impegno_accertamento 
(
 vincolo_impacc_id	     number(10) not null,
 anno_impegno	           varchar2(4) not null,
 numero_impegno	         number(10) not null,
 anno_accertamento	     varchar2(4) not null,
 numero_accertamento	   number(10) not null,
 importo	               NUMBER(15,2) default 0 not null,
 ente_proprietario_id    number(10)     not null
)
tablespace &1;

comment on table migr_impegno_accertamento
  is 'migrazione vincoli impegno-accertamenti';

alter table migr_impegno_accertamento
  add constraint XPKMIGR_IMPACC primary key (vincolo_impacc_id)
  using index 
  tablespace &2;
  
create table migr_classif_impacc 
(
 classif_tipo_id	     number(10)    not null,
 tipo                  varchar2(1)   not null,
 codice	               varchar2(100) not null,
 descrizione	         varchar2(500) not null,
 ente_proprietario_id  number(10)    not null
)
tablespace &1; 

comment on table migr_classif_impacc
  is 'migrazione attribuzione descrizioni ai classificatori';

alter table migr_classif_impacc
  add constraint XPKMIGR_CLASSIF_IMPACC primary key (classif_tipo_id)
  using index 
  tablespace &2;

create table migr_impegno_scarto 
(
 impegno_scarto_id	   number(10)    not null,
 anno_esercizio        varchar2(4)   not null,
 anno_impegno          varchar2(4)   not null,
 numero_impegno        number(10)    not null,
 numero_subimpegno     number(10)    default 0 not null,
 motivo_scarto         varchar2(2500) not null,
 ente_proprietario_id  number(10)    not null,
 data_ins              date default sysdate not null
)
tablespace &1; 

comment on table migr_impegno_scarto
  is 'tracciatura scarti migrazione impegni';

alter table migr_impegno_scarto
  add constraint XPKMIGR_IMPEGNO_SCARTO primary key (impegno_scarto_id)
  using index 
  tablespace &2;
  
create table migr_accertamento_scarto 
(
 accertamento_scarto_id	    number(10)    not null,
 anno_esercizio         varchar2(4)   not null,
 anno_accertamento      varchar2(4)   not null,
 numero_accertamento    number(10)    not null,
 numero_subaccertamento number(10)    default 0 not null,
 motivo_scarto          varchar2(2500) not null,
 ente_proprietario_id   number(10)    not null,
 data_ins               date default sysdate not null
)
tablespace &1; 

comment on table migr_accertamento_scarto
  is 'tracciatura scarti migrazione accertamenti';

alter table migr_accertamento_scarto
  add constraint XPKMIGR_ACCERTAMENTO_SCARTO primary key (accertamento_scarto_id)
  using index 
  tablespace &2;
  
alter table migr_impegno add fl_migrato varchar2(1) default 'N' not null;  
alter table migr_accertamento add fl_migrato varchar2(1) default 'N' not null;  
alter table migr_impegno_accertamento add fl_migrato varchar2(1) default 'N' not null;  
alter table migr_classif_impacc add fl_migrato varchar2(1) default 'N' not null;  

alter table migr_impegno add  data_ins date default sysdate not null;
alter table migr_accertamento add  data_ins date default sysdate not null;
alter table migr_impegno_accertamento add  data_ins date default sysdate not null;
alter table migr_classif_impacc add  data_ins date default sysdate not null;





-----------------------------
-- Tabelle necessarie per la compilazione del plSql

-- RegPGiunta
-- PROVINCIA oggetto già presente
create table TABPROVVED_ENTI
(
  codprov             VARCHAR2(2) not null,
  t_tipologia_atto_id NUMBER(10) not null,
  anno_avvio          VARCHAR2(4) not null,
  ente                VARCHAR2(50) not null
)
tablespace &1;

---- COTO : oggetto già presente
---- PROVINCIA oggetto già presente
create table ATTI_ENTI
(
  ente                VARCHAR2(50) not null,
  t_tipologia_atto_id NUMBER(10) not null,
  numero_definitivo   NUMBER(10) not null,
  oggetto             VARCHAR2(420),
  data_atto           date

)
tablespace &1;

-- Enti diversi da RegPGiunta
-- Create table
-- COTO : oggetto già presente
create table DELIBERE
(
  anno                     NUMBER(4) not null,
  nro_provv                NUMBER(5) not null,
  nro_def                  NUMBER(5) not null,
  oggetto                  VARCHAR2(420),
  esito_giunta             VARCHAR2(2)
)
tablespace &1;

create table IMPEGNO_COGE
(
  anno_esercizio VARCHAR2(4) not null,
  annoimp        VARCHAR2(4) not null,
  nimp           NUMBER(6) not null,
  fl_coge        VARCHAR2(1) not null,
  dt_ins         DATE not null,
  ute_ins        VARCHAR2(11) not null,
  dt_agg         DATE,
  ute_agg        VARCHAR2(11)
)
tablespace &1;

-- Create table
create table ACCERTAMENTO_COGE
(
  anno_esercizio VARCHAR2(4) not null,
  annoacc        VARCHAR2(4) not null,
  nacc           NUMBER(6) not null,
  fl_coge        VARCHAR2(1) not null,
  dt_ins         DATE not null,
  ute_ins        VARCHAR2(11) not null,
  dt_agg         DATE,
  ute_agg        VARCHAR2(11)
)
tablespace &1;

create table determine
(
   anno                     NUMBER(4) not null,
   num_determ               NUMBER(5) not null,
   direzione                VARCHAR2(5) not null,
   oggetto                  VARCHAR2(420),
   cod_dir                  VARCHAR2(5)
 )
 tablespace &1;


-- Create table
create table IMPEGNO_ACCERTAMENTI
(
  annoimp   VARCHAR2(4) not null,
  nimp      NUMBER(6) not null,
  annoacc   VARCHAR2(4) not null,
  nacc      NUMBER(6) not null,
  importo   NUMBER(15,2) not null,
  fl_valido VARCHAR2(1) not null,
  ute_ins   VARCHAR2(20) not null,
  data_ins  DATE not null,
  ute_agg   VARCHAR2(20),
  data_agg  DATE
)
tablespace &1;

-- DAVIDE - 09.03.016 - aggiunte per modifiche Impegni / Accertamenti
create table migr_impegno_modifica
(
 impegno_mod_id          number(10)    not null,
 tipo_movimento          varchar2(1)   not null,
 anno_esercizio          varchar2(4)     not null,
 anno_impegno            varchar2(4)   not null,
 numero_impegno          number(10)    default 0 null,
 numero_subimpegno       number(10)    default 0 null,
 numero_modifica         number(10)    default 0 null,
 tipo_modifica           varchar2(10)  not null,
 descrizione             varchar2(500) not null,
 anno_provvedimento      varchar2(4)     null,
 numero_provvedimento    number(10)    null,
 tipo_provvedimento      varchar2(20)  null,
 sac_provvedimento       varchar2(20)  null,
 oggetto_provvedimento   varchar2(500) null,
 note_provvedimento      varchar2(500) null,
 stato_provvedimento     varchar2(50)  null,
 importo                 number(15,2)  default 0 not null,
 stato_operativo         varchar2(1)   not null,
 data_modifica           varchar2 (10) not null,
 ente_proprietario_id    number(10) not null,
 fl_migrato              varchar2(1) default 'N' not null
)
tablespace &1;

comment on table migr_impegno_modifica
  is 'migrazione modifiche impegni - subimpegni';
  
comment on column migr_impegno_modifica.tipo_movimento
  is 'I-impegno S-subimpegno';
  
comment on column migr_impegno_modifica.tipo_modifica
  is 'ECON-Economie RIU-Riutilizzo RIAC-Riaccertamento ALT-Altro';
 
alter table migr_impegno_modifica
  add constraint XPKMIGR_IMPEGNO_MODIFICA primary key (impegno_mod_id)
  using index 
  tablespace &2;

create index XIFMIGR_IMPEGNO_MODIFICA_NR on MIGR_IMPEGNO_MODIFICA (numero_modifica,anno_esercizio)
tablespace &2;

create index XIFMIGR_IMPEGNO_MODIFICA_IMP on MIGR_IMPEGNO_MODIFICA (NUMERO_IMPEGNO, NUMERO_SUBIMPEGNO, ANNO_IMPEGNO, ANNO_ESERCIZIO)
  tablespace &2;

create table migr_accertamento_mod
(
 accertamento_mod_id     number(10)    not null,
 tipo_movimento          varchar2(1)   not null,
 anno_esercizio          varchar2(4)     not null,
 anno_accertamento       varchar2(4)   not null,
 numero_accertamento     number(10)    default 0 null,
 numero_subaccertamento  number(10)    default 0 null,
 numero_modifica         number(10)    default 0 null,
 tipo_modifica           varchar2(10)  not null,
 descrizione             varchar2(500) not null,
 anno_provvedimento      varchar2(4)     null,
 numero_provvedimento    number(10)    null,
 tipo_provvedimento      varchar2(20)  null,
 sac_provvedimento       varchar2(20)  null,
 oggetto_provvedimento   varchar2(500) null,
 note_provvedimento      varchar2(500) null,
 stato_provvedimento     varchar2(50)  null,
 importo                 number(15,2)  default 0 not null,
 stato_operativo         varchar2(1)   not null,
 data_modifica           varchar2 (10) not null,
 ente_proprietario_id    number(10) not null,
 fl_migrato              varchar2(1)  default 'N' not null
)
tablespace &1;

comment on table migr_accertamento_mod
  is 'migrazione modifiche accertamenti - subaccertamenti';
  
comment on column migr_accertamento_mod.tipo_movimento
  is 'A-accertamento S-subaccertamento';
  
comment on column migr_accertamento_mod.tipo_modifica
  is 'ECON-Economie RIU-Riutilizzo RIAC-Riaccertamento ALT-Altro';
 
alter table migr_accertamento_mod
  add constraint XPKMIGR_ACCERTAMENTO_MOD primary key (accertamento_mod_id)
  using index 
  tablespace &2;

create index XIFMIGR_ACCERTAMENTO_MOD_NR on MIGR_ACCERTAMENTO_MOD (numero_modifica,anno_esercizio)
tablespace &2;

create index XIFMIGR_ACCERTAMENTO_MOD_IMP on MIGR_ACCERTAMENTO_MOD (NUMERO_ACCERTAMENTO, NUMERO_SUBACCERTAMENTO, ANNO_ACCERTAMENTO, ANNO_ESERCIZIO)
  tablespace &2;
  
create table migr_impegno_modscarto 
(
 impegno_modscarto_id  number(10)    not null,
 anno_esercizio        varchar2(4)   not null,
 anno_modifica     varchar2(4)   not null,
 numero_modifica       number(10)    not null,
 motivo_scarto         varchar2(2500) not null,
 ente_proprietario_id  number(10)    not null,
 data_ins              date default sysdate not null
)
tablespace &1; 

comment on table migr_impegno_modscarto
  is 'tracciatura scarti migrazione modifiche impegni';

alter table migr_impegno_modscarto
  add constraint XPKMIGR_IMPEGNO_MODSCARTO primary key (impegno_modscarto_id)
  using index 
  tablespace &2;
  
create table migr_accertamento_modsc
(
 accertamento_modscarto_id  number(10)    not null,
 anno_esercizio         varchar2(4)   not null,
 anno_modifica          varchar2(4)   not null,
 numero_modifica        number(10)    not null,
 motivo_scarto          varchar2(2500) not null,
 ente_proprietario_id   number(10)    not null,
 data_ins               date default sysdate not null
)
tablespace &1; 

comment on table migr_accertamento_modsc
  is 'tracciatura scarti migrazione modifiche accertamenti';

alter table migr_accertamento_modsc
  add constraint XPKMIGR_ACCERTAMENTO_MODSC primary key (accertamento_modscarto_id)
  using index 
  tablespace &2;
