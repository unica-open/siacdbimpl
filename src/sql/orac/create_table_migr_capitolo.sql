/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- tabelle stage ORACLE

-- 12.10.2015 Nota PVTO: creare la migr_capitolo_uscita e la migr_capitolo_entrata usando BILANCIO_MEDIUM_TBL e BILANCIO_MEDIUM_IDX (le altre potrebbero stare sullo small)

drop table migr_capitolo_uscita cascade constraints;
drop table migr_capitolo_entrata cascade constraints;

drop table migr_attilegge_uscita cascade constraints;
drop table migr_attilegge_entrata cascade constraints;

drop table migr_vincolo_capitolo cascade constraints;
drop table migr_classif_capitolo cascade constraints;


drop table migr_capitolo_eccezione cascade constraints;

-- non droppare le tabelle di seguito 
--drop table TABPROVVED cascade constraints;
--drop table ATTI_LEGGE cascade constraints;
--drop table TABPROVVED_ENTI cascade constraints;
--drop table ATTI_ENTI cascade constraints;


create table migr_capitolo_uscita
(
 capusc_id	      number(10) not null,
 tipo_capitolo	  varchar2(10) not null,
 anno_esercizio	  varchar2(4) not null,
 numero_capitolo	number(6) not null,
 numero_articolo	number(6) not null,
 numero_ueb	      varchar(50) not null,
 descrizione	    varchar2(600) not null,
 descrizione_articolo	    varchar2(600) null,
 titolo	varchar2(10)  null,
 macroaggregato	varchar2(10)  null,
 missione	varchar2(10)  null,
 programma	varchar2(10)  null,
 pdc_fin_quarto	varchar2(30) null,
 pdc_fin_quinto	varchar2(30) null,
 cofog	varchar2(20)  null,
 note	varchar2(150) null,
 flag_rilevante_iva	varchar2(1) default 'N' not null,
 flag_per_memoria	varchar2(1) default 'N' not null,
 tipo_finanziamento	varchar2(250) null,
 tipo_vincolo	varchar2(250) null,
 tipo_fondo	varchar2(250) null,
 siope_livello_1	varchar2(50) null,
 siope_livello_2	varchar2(50) null,
 siope_livello_3	varchar2(50) null,
 classificatore_1	varchar2(250) null,
 classificatore_2	varchar2(250) null,
 classificatore_3	varchar2(250) null,
 classificatore_4	varchar2(250) null,
 classificatore_5	varchar2(250) null,
 classificatore_6	varchar2(250) null,
 classificatore_7	varchar2(250) null,
 classificatore_8	varchar2(250) null,
 classificatore_9	varchar2(250) null,
 classificatore_10	varchar2(250) null,
 classificatore_11	varchar2(250) null,
 classificatore_12	varchar2(250) null,
 classificatore_13	varchar2(250) null,
 classificatore_14	varchar2(250) null,
 classificatore_15	varchar2(250) null,
 centro_resp	varchar2(10)  null,
 cdc	varchar2(10)  null,
 classe_capitolo varchar2(10) default 'STD' not null,
 flag_impegnabile varchar2(1) default 'S' not null,
 stanziamento_iniziale	NUMBER(15,2) default 0 not null,
 stanziamento_iniziale_res	NUMBER(15,2) default 0 not null,
 stanziamento_iniziale_cassa	NUMBER(15,2) default 0 not null,
 stanziamento	NUMBER(15,2) default 0 not null,
 stanziamento_res	NUMBER(15,2) default 0 not null,
 stanziamento_cassa	NUMBER(15,2) default 0 not null,
 stanziamento_iniziale_anno2	NUMBER(15,2) default 0 not null,
 stanziamento_anno2	NUMBER(15,2) default 0 not null,
 stanziamento_iniziale_anno3	NUMBER(15,2) default 0 not null,
 stanziamento_anno3	NUMBER(15,2) default 0 not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins   date default sysdate not null,
 ente_proprietario_id number(10) not null,
 dicuiimpegnato_anno1 NUMBER(15,2) default 0 not null,
 dicuiimpegnato_anno2 NUMBER(15,2) default 0 not null,
 dicuiimpegnato_anno3 NUMBER(15,2) default 0 not null,
 trasferimenti_comunitari VARCHAR2(1) default null,
 funzioni_delegate VARCHAR2(1) default null,
 spesa_ricorrente  VARCHAR2(50) null                  -- DAVIDE - 22.08.2016 - aggiunto per COTO, PVTO
 ) tablespace &1;

comment on table migr_capitolo_uscita
  is 'migrazione capitoli uscita';
  

 
alter table migr_capitolo_uscita
  add constraint XPKMIGR_CAPUSC primary key (capusc_id)
  using index 
  tablespace &2;

create index XIFMIGR_CAPUSC_LOG on migr_capitolo_uscita (numero_capitolo,numero_articolo,anno_esercizio,tipo_capitolo)
tablespace &2;

create index XIFMIGR_CAPUSC_ANNO on migr_capitolo_uscita (anno_esercizio,tipo_capitolo)
tablespace &2;

create table MIGR_CAPITOLO_ENTRATA
(
  capent_id                   NUMBER(10) not null,
  tipo_capitolo               VARCHAR2(10) not null,
  anno_esercizio              VARCHAR2(4) not null,
  numero_capitolo             NUMBER(6) not null,
  numero_articolo             NUMBER(6) not null,
  numero_ueb                  varchar2(50) not null,
  descrizione                 VARCHAR2(600) not null,
  descrizione_articolo        VARCHAR2(600) null,
  titolo                      VARCHAR2(10)  null,
  tipologia                   VARCHAR2(10)  null,
  categoria                   VARCHAR2(10)  null,
  pdc_fin_quarto              VARCHAR2(30),
  pdc_fin_quinto              VARCHAR2(30),
  note                        VARCHAR2(150),
  flag_rilevante_iva	varchar2(1) default 'N' not null,
  flag_per_memoria	varchar2(1) default 'N' not null,  
  tipo_finanziamento          VARCHAR2(250),
  tipo_vincolo                VARCHAR2(250),
  tipo_fondo                  VARCHAR2(250),
  siope_livello_1             VARCHAR2(50),
  siope_livello_2             VARCHAR2(50),
  siope_livello_3             VARCHAR2(50),
  classificatore_1            VARCHAR2(250),
  classificatore_2            VARCHAR2(250),
  classificatore_3            VARCHAR2(250),
  classificatore_4            VARCHAR2(250),
  classificatore_5            VARCHAR2(250),
  classificatore_6            VARCHAR2(250),
  classificatore_7            VARCHAR2(250),
  classificatore_8            VARCHAR2(250),
  classificatore_9            VARCHAR2(250),
  classificatore_10           VARCHAR2(250),
  classificatore_11           VARCHAR2(250),
  classificatore_12           VARCHAR2(250),
  classificatore_13           VARCHAR2(250),
  classificatore_14           VARCHAR2(250),
  classificatore_15           VARCHAR2(250),
  centro_resp                 VARCHAR2(10)  null,
  cdc                         VARCHAR2(10),
  classe_capitolo varchar2(10) default 'STD' not null,
  flag_accertabile varchar2(1) default 'S' not null,
  stanziamento_iniziale       NUMBER(15,2) default 0 not null,
  stanziamento_iniziale_res   NUMBER(15,2) default 0 not null,
  stanziamento_iniziale_cassa NUMBER(15,2) default 0 not null,
  stanziamento                NUMBER(15,2) default 0 not null,
  stanziamento_res            NUMBER(15,2) default 0 not null,
  stanziamento_cassa          NUMBER(15,2) default 0 not null,
  stanziamento_iniziale_anno2 NUMBER(15,2) default 0 not null,
  stanziamento_anno2 NUMBER(15,2) default 0 not null,
  stanziamento_iniziale_anno3 NUMBER(15,2) default 0 not null,
  stanziamento_anno3 NUMBER(15,2) default 0 not null,  
  fl_migrato                  VARCHAR2(1) default 'N' not null,
  data_ins                    DATE default sysdate not null,
  ente_proprietario_id        NUMBER(10) not null,
  trasferimenti_comunitari    VARCHAR2(1) default null,
  entrata_ricorrente	      VARCHAR2(50) null          -- DAVIDE - 22.08.2016 - aggiunto per COTO, PVTO
)
tablespace &1;

comment on table migr_capitolo_entrata
  is 'migrazione capitoli entrata - entrata';
  
 
alter table migr_capitolo_entrata
  add constraint XPKMIGR_CAPENT primary key (capent_id)
  using index 
  tablespace &2;
  
create table migr_attilegge_uscita 
(
 attilegge_uscita_id	number(10) not null,
 tipo_capitolo	varchar2(10) not null,
 anno_esercizio	varchar2(4) not null,
 numero_capitolo	number(6) not null,
 numero_articolo	number(3) not null,
 anno_legge	VARCHAR2(4) not null,
 tipo_legge	VARCHAR2(2) not null,
 nro_legge 	 VARCHAR2(10) not null,
 articolo	VARCHAR2(4) not null,
 comma	VARCHAR2(4) not null,
 punto	VARCHAR2(2) not null,
 gerarchia	VARCHAR2(2) null,
 inizio_finanz	varchar2(10) null,
 fine_finanz 	varchar2(10) null,
 descrizione	VARCHAR2(150) null,
 fl_migrato varchar2(1) default 'N'  not null,
 data_ins   date default sysdate not null,
 ente_proprietario_id  number(10)    not null
)
tablespace &1; 

comment on table migr_attilegge_uscita
  is 'capitolo uscita - atti di legge';

alter table migr_attilegge_uscita
  add constraint XPKMIGR_ATTILEGGE_CAPUSC primary key (attilegge_uscita_id)
  using index 
  tablespace &2;


create table migr_attilegge_entrata 
(
 attilegge_entrata_id	number(10) not null,
 tipo_capitolo	varchar2(10) not null,
 anno_esercizio	varchar2(4) not null,
 numero_capitolo	number(6) not null,
 numero_articolo	number(3) not null,
 anno_legge	VARCHAR2(4) not null,
 tipo_legge	VARCHAR2(2) not null,
 nro_legge 	 VARCHAR2(10) not null,
 articolo	VARCHAR2(4) not null,
 comma	VARCHAR2(4) not null,
 punto	VARCHAR2(2) not null,
 gerarchia	VARCHAR2(2) null,
 inizio_finanz	varchar2(10) null,
 fine_finanz 	varchar2(10) null,
 descrizione	VARCHAR2(150) null,
 fl_migrato varchar2(1) default 'N'  not null,
 data_ins   date default sysdate not null,
 ente_proprietario_id  number(10)    not null
)
tablespace &1; 

comment on table migr_attilegge_entrata
  is 'capitolo entrata - atti di legge';

alter table migr_attilegge_entrata
  add constraint XPKMIGR_ATTILEGGE_CAPENT primary key (attilegge_entrata_id)
  using index 
  tablespace &2;
  
    
create table migr_vincolo_capitolo
(
 vincolo_id     number(10) not null, 
 vincolo_cap_id	number(10) not null,
 tipo_vincolo_bil	varchar2(100) not null,
 tipo_vincolo	varchar2(100) not null,
 anno_esercizio	varchar2(4) not null,
 numero_capitolo_u	number(6) not null,
 numero_articolo_u	number(3) not null,
 numero_capitolo_e	number(6) not null,
 numero_articolo_e	number(3) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins               date default sysdate not null,
 ente_proprietario_id   number(10)    not null
) tablespace &1; 

comment on table migr_vincolo_capitolo
  is 'vincolo - capitolo';

alter table migr_vincolo_capitolo
  add constraint XPKMIGR_VINCOLO_CAP primary key (vincolo_id,vincolo_cap_id)
  using index 
  tablespace &2;
  
create table migr_classif_capitolo
(
 classif_tipo_id	number(10) not null,
 tipo_capitolo	varchar2(10) not null,
 codice	varchar2(100) not null,
 descrizione	varchar2(250) not null,
 fl_migrato   varchar2(1) default 'N' not null,
 data_ins     date default sysdate not null,
 ente_proprietario_id   number(10)    not null
) 
tablespace &1; 

comment on table migr_classif_capitolo
  is 'descrizioni dei classificatori capitolo';

alter table migr_classif_capitolo
  add constraint XPKMIGR_CLASSIF_CAP primary key (classif_tipo_id)
  using index 
  tablespace &2;
  
create table TABPROVVED
(
  codprov VARCHAR2(2) not null,
  descri  VARCHAR2(150) not null,
  organo  VARCHAR2(1) not null,
  tipolp  VARCHAR2(5)
)
tablespace &1;

create table TABPROVVED_ENTI
(
  codprov             VARCHAR2(2) not null,
  t_tipologia_atto_id NUMBER(10) not null,
  anno_avvio          VARCHAR2(4) not null,
  ente                VARCHAR2(50) not null
)
tablespace &1;

alter table TABPROVVED_ENTI
  add constraint PK_TABPROVVED_ENTI primary key (CODPROV)
  using index 
  tablespace &2;
  
  
create table ATTI_ENTI
(
  t_atto_id                 NUMBER(10) not null,
  t_tipologia_atto_id       NUMBER(10),
  t_testo_id                NUMBER(10),
  t_testo_omissis_id        NUMBER(10),
  oggetto                   VARCHAR2(1000) not null,
  data_creazione            DATE not null,
  data_atto                 DATE,
  numero_provvisorio        NUMBER(10) not null,
  numero_definitivo         NUMBER(10),
  periodo_riferimento       VARCHAR2(25),
  privacy                   NUMBER(1) default 0 not null,
  stato                     NUMBER(1) default 0 not null,
  codice_struttura          VARCHAR2(200),
  ente                      VARCHAR2(50) default 'NA' not null,
  cc_version                NUMBER(10) default 0 not null,
  indici_classif            NUMBER(1),
  tipostruttura             NUMBER(1),
  note                      VARCHAR2(250),
  data_esecutivita          DATE,
  dati_bilancio             NUMBER(1),
  check_proponi_commissione NUMBER(1),
  iscrizione2odg            NUMBER(1),
  modello_stampa_id         NUMBER(10)
)
tablespace &1;

alter table ATTI_ENTI
  add constraint TC_T_ATTO unique (T_TIPOLOGIA_ATTO_ID, PERIODO_RIFERIMENTO, NUMERO_DEFINITIVO)
  using index tablespace &2;
  
alter table ATTI_ENTI
  add constraint TC1_T_ATTO unique (T_TIPOLOGIA_ATTO_ID, PERIODO_RIFERIMENTO, NUMERO_DEFINITIVO, NUMERO_PROVVISORIO)
  using index 
  tablespace &2;
  
create table ATTI_LEGGE
(
  anno_esercizio VARCHAR2(4) not null,
  eu             VARCHAR2(1) not null,
  nro_capitolo   NUMBER not null,
  nro_articolo   NUMBER(3) not null,
  anno_legge     VARCHAR2(4) not null,
  tipo_legge     VARCHAR2(2) not null,
  nro_legge      VARCHAR2(10) not null, 
  articolo       VARCHAR2(4) not null,
  comma          VARCHAR2(4) not null,
  punto          VARCHAR2(2) not null,
  gerarchia      VARCHAR2(2),
  iniz_finanz    DATE,
  fine_finanz    DATE,
  descri         VARCHAR2(150)
)
tablespace &1;


  
create table migr_capitolo_eccezione
(
  tipo_capitolo               VARCHAR2(10) not null,
  eu                          VARCHAR2(1) not null,
  anno_esercizio              VARCHAR2(4) not null,
  numero_capitolo             NUMBER(6) not null,
  numero_articolo             NUMBER(6) default 0 not null,
  numero_ueb                  varchar2(50) default '1' not null,
  flag_impegnabile            varchar2(1) default 'N' not null,
  --classe_capitolo             varchar2(3) not null,  DAVIDE - 17.11.2016 - distinzione tra fondi spese correnti e conto capitale
  classe_capitolo             varchar2(10) not null, 
  ente_proprietario_id        number(10) not null
)  
tablespace &1;

alter table migr_capitolo_eccezione
  add constraint XPKMIGR_CAPITOLO_ECC primary key (numero_capitolo,numero_articolo,numero_ueb,tipo_capitolo,eu,anno_esercizio,ente_proprietario_id)
  using index 
  tablespace &2;

