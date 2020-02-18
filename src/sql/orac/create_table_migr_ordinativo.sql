/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- tabelle stage ORACLE
-- creare su tbl medium per enti maggiori (coto, regp, pvto)
--BIL_REG_MEDIUM_TBL
--BIL_REG_MEDIUM_IDX

drop table migr_ordinativo_spesa cascade constraints;
drop table migr_ordinativo_spesa_scarto cascade constraints;

drop table migr_ordinativo_spesa_ts cascade constraints;
drop table migr_ordinativo_spe_ts_scarto cascade constraints;

create table migr_ordinativo_spesa ( 
  ordinativo_id   			  number(10)    NOT NULL,
  anno_esercizio  			  number(4)     NOT NULL,
  numero_ordinativo  		  number(10)    NOT NULL, 
  numero_capitolo  			  number(10)    default 0 NOT NULL , 
  numero_articolo         number(10)    default 0 NOT NULL, 
  numero_ueb              VARCHAR2(50)  default 1 NOT NULL  ,  
  descrizione             VARCHAR2(500) NOT NULL,   
  data_emissione          VARCHAR2(10)  NOT NULL, 
  data_annullamento       VARCHAR2(10),    
  data_riduzione          VARCHAR2(10),    
  data_scadenza           VARCHAR2(10),    
  data_spostamento        VARCHAR2(10),    
  data_trasmissione       VARCHAR2(10),    
  stato_operativo         VARCHAR2(1)  NOT NULL,
  codice_distinta         VARCHAR2(10),
  codice_bollo            VARCHAR2(10) NOT NULL,
  codice_commissione      VARCHAR2(10) NOT NULL, 
  codice_conto_corrente   VARCHAR2(10) NOT NULL,
  codice_soggetto         number(10)   NOT NULL,
  codice_modpag           number(10)   NOT NULL,
  anno_provvedimento      number(4),
  numero_provvedimento    number(10),
  tipo_provvedimento      VARCHAR2(20),    
  sac_provvedimento       VARCHAR2(20),    
  oggetto_provvedimento   VARCHAR2(500),      
  note_provvedimento      VARCHAR2(500),      
  stato_provvedimento     VARCHAR2(50),    
  flag_allegato_cart      VARCHAR2(10),   
  note_tesoriere          VARCHAR2(10),
  comunicazioni_tes        VARCHAR2(500),  
  cup                     VARCHAR2(50),      
  cig                     VARCHAR2(50),      
  firma_ord_data          VARCHAR2(10),    
  firma_ord               VARCHAR2(500) ,     
  quietanza_numero        VARCHAR2(10),     
  quietanza_data          VARCHAR2(10), 
  quietanza_importo       number(15,2),    
  quietanza_codice_cro    VARCHAR2(50),    
  storno_quiet_numero     number(10),   
  storno_quiet_data       VARCHAR2(10), 
  storno_quiet_importo    number(15,2),  
  cast_competenza         number(15,2) default 0 NOT NULL ,  
  cast_cassa              number(15,2) default 0 NOT NULL ,  
  cast_emessi             number(15,2) default 0 NOT NULL ,  
  utente_creazione        VARCHAR2(50) NOT NULL,   
  utente_modifica         VARCHAR2(50),   
  classificatore_1        VARCHAR2(250),
  classificatore_2        VARCHAR2(250),
  classificatore_3        VARCHAR2(250),
  pdc_finanziario         VARCHAR2(50),  
  transazione_ue_spesa    VARCHAR2(50),    
  spesa_ricorrente        VARCHAR2(50),  
  perimetro_sanitario_spesa    VARCHAR2(50),     
  politiche_regionali_unitarie VARCHAR2(50),     
  pdc_economico_patr           VARCHAR2(50),                 
  cofog                        VARCHAR2(50),
  siope_spesa                  VARCHAR2(50),
  ente_proprietario_id         number(10) not null,
  fl_scarto                  varchar2(1) default 'N' not null,
  fl_migrato                  varchar2(1) default 'N' not null,
  data_ins                    date default sysdate not null
)tablespace &1;


comment on table migr_ordinativo_spesa
  is 'migrazione ordinativi di spesa';

alter table migr_ordinativo_spesa
  add constraint XPKMIGR_ordinativo_spesa primary key (ordinativo_id)
  using index 
  tablespace &2;
  
create unique index xifmigr_ordinativo_spesa_pklog on migr_ordinativo_spesa (numero_ordinativo, anno_esercizio,ente_proprietario_id)
 tablespace &2;
 
create table migr_ordinativo_spesa_ts ( 
  ordinativo_ts_id      number(10)    NOT NULL,
  ordinativo_id   			number(10)    NOT NULL,
  anno_esercizio  			number(4)     NOT NULL,
  numero_ordinativo  		number(10)    NOT NULL,
  quota_ordinativo  		number(10)    NOT NULL,
  anno_impegno          number(4) default 0 NOT NULL, 
  numero_impegno        number(6) default 0 NOT NULL,
  numero_subimpegno     number(6) default 0 NOT NULL,  
  numero_liquidazione   number(6) NOT NULL,   
  data_scadenza         varchar2(10),
  descrizione           varchar2(500) not null,
  importo_iniziale      number(15,2) default 0 NOT NULL, 
  importo_attuale       number(15,2) default 0 NOT NULL, 
  anno_documento        number(4),
  numero_documento      varchar2(20),
  tipo_documento        varchar2(10),
  cod_soggetto_documento number(10),
  frazione_documento     number(5),
  anno_nota_cred         number(4),
  numero_nota_cred       varchar2(20),
  cod_sogg_nota_cred     number(10),
  frazione_nota_cred     number(5),
  importo_nota_cred      number(15,2),
  ente_proprietario_id   number(10) not null,
  fl_scarto                  varchar2(1) default 'N' not null,
  fl_migrato             varchar2(1) default 'N' not null,
  data_ins               date default sysdate not null
)tablespace &1;

 
comment on table migr_ordinativo_spesa_ts
  is 'migrazione ordinativi di spesa - quote';

alter table migr_ordinativo_spesa_ts
  add constraint XPKMIGR_ordinativo_spesa_ts primary key (ordinativo_ts_id)
  using index 
  tablespace &2;
  
/*create unique index xifmigr_ord_spe_ts_pklog on migr_ordinativo_spesa_ts (quota_ordinativo,numero_ordinativo, anno_esercizio,ente_proprietario_id)
 tablespace &2;*/
 
 create  index xifmigr_ord_spe_ts_pklog on migr_ordinativo_spesa_ts (numero_ordinativo, anno_esercizio,ente_proprietario_id)
 tablespace &2;


 create  index xifmigr_ord_spe_ts_ord_id on migr_ordinativo_spesa_ts (ordinativo_id,ente_proprietario_id)
 tablespace &2;

 
create index xifmigr_ord_spe_ts_liq on migr_ordinativo_spesa_ts (numero_liquidazione, anno_esercizio,ente_proprietario_id)
 tablespace &2;

create index xifmigr_ord_spe_ts_mov on migr_ordinativo_spesa_ts (numero_subimpegno,numero_impegno, anno_impegno, anno_esercizio,ente_proprietario_id)
 tablespace &2;


create table migr_ordinativo_spesa_scarto 
(
 ordinativo_scarto_id  number(10)     not null,
 numero_ordinativo     number(10)     not null,
 anno_esercizio        varchar2(4)    not null,
 tipo_scarto           varchar2(50)   ,
 motivo_scarto         varchar2(2500) not null,
 fl_migrato            varchar2(1)    default 'N' not null,
 ente_proprietario_id  number(10)     not null,
 data_ins              date default sysdate not null
)
tablespace &1; 

comment on table migr_ordinativo_spesa_scarto
  is 'tracciatura scarti migrazione ordinativo spesa';

alter table migr_ordinativo_spesa_scarto
  add constraint XPKMIGR_ORD_SPESA_SCARTO primary key (ordinativo_scarto_id)
  using index 
  tablespace &2;


create index XIFMIGR_ORDSPE_SCA_PKLOGICA on migr_ordinativo_spesa_scarto (numero_ordinativo,anno_esercizio)
tablespace &2;


create table migr_ordinativo_spe_ts_scarto 
(
 ordinativo_ts_scarto_id  number(10)     not null,
 numero_ordinativo  	  	number(10)    NOT NULL,
 quota_ordinativo         number(10)     not null,
 anno_esercizio           varchar2(4)    not null,
 tipo_scarto              varchar2(50) ,
 motivo_scarto            varchar2(2500) not null,
 fl_migrato               varchar2(1)    default 'N' not null,
 ente_proprietario_id     number(10)     not null,
 data_ins                 date default sysdate not null
)
tablespace &1; 

comment on table migr_ordinativo_spe_ts_scarto
  is 'tracciatura scarti migrazione ordinativo spesa quote';

alter table migr_ordinativo_spe_ts_scarto
  add constraint XPKMIGR_ORD_SPESA_TS_SCARTO primary key (ordinativo_ts_scarto_id)
  using index 
  tablespace &2;


create index XIFMIGR_ORDSPE_TS_SCA_PKLOGICA on migr_ordinativo_spe_ts_scarto (quota_ordinativo,numero_ordinativo,anno_esercizio)
tablespace &2;


-----------------------------------------------------------------------------------------------------------------------
drop table migr_ordinativo_entrata cascade constraints;
drop table migr_ordinativo_entrata_scarto cascade constraints;

drop table migr_ordinativo_entrata_ts cascade constraints;
drop table migr_ordinativo_ent_ts_scarto cascade constraints;


create table migr_ordinativo_entrata(  
  ordinativo_id          NUMBER(10)     NOT NULL,
  anno_esercizio         NUMBER(4)      NOT NULL,  
  numero_ordinativo      NUMBER(10)     NOT NULL,  
  numero_capitolo        NUMBER(10)     default 0  NOT NULL,  
  numero_articolo        NUMBER(10)     default 0  NOT NULL,  
  numero_ueb             VARCHAR2(50)   default 1  NOT NULL,  
  descrizione            VARCHAR2(500)  NOT NULL,    
  data_emissione         VARCHAR2(10)   NOT NULL,
  data_annullamento      VARCHAR2(10),    
  data_riduzione         VARCHAR2(10),    
  data_scadenza          VARCHAR2(10),  
  data_spostamento       VARCHAR2(10),    
  data_trasmissione      VARCHAR2(10),    
  stato_operativo        VARCHAR2(1)   NOT NULL,
  codice_distinta        VARCHAR2(10),
  codice_bollo           VARCHAR2(10)     NOT NULL,
  codice_conto_corrente  VARCHAR2(10)     NOT NULL,
  codice_soggetto        NUMBER(10)       NOT NULL,  
  anno_provvedimento     NUMBER(4),      
  numero_provvedimento   NUMBER(10),  
  tipo_provvedimento     VARCHAR2(20),    
  sac_provvedimento      VARCHAR2(20),    
  oggetto_provvedimento  VARCHAR2(500),      
  note_provvedimento     VARCHAR2(500),      
  stato_provvedimento    VARCHAR2(50),    
  flag_allegato_cart     VARCHAR2(10),
  note_tesoriere         VARCHAR2(10),  
  comunicazioni_tes      VARCHAR2(500),      
  firma_ord_data        VARCHAR2(10),    
  firma_ord             VARCHAR2(500),      
  quietanza_numero      NUMBER(10),      
  quietanza_data        VARCHAR2(10),    
  quietanza_importo     NUMBER(15,2),      
  storno_quiet_numero   NUMBER(10),      
  storno_quiet_data     VARCHAR2(10),    
  storno_quiet_importo  NUMBER(15,2),       
  cast_competenza       NUMBER(15,2) default 0  NOT NULL,  
  cast_cassa            NUMBER(15,2) default 0  NOT NULL,  
  cast_emessi           NUMBER(15,2) default 0  NOT NULL,  
  utente_creazione      VARCHAR2(50) NOT NULL,  
  utente_modifica       VARCHAR2(50),  
  classificatore_1      VARCHAR2(250),
  classificatore_2      VARCHAR2(250),
  classificatore_3      VARCHAR2(250),
  pdc_finanziario       VARCHAR2(50),    
  transazione_ue_entrata VARCHAR2(50),    
  entrata_ricorrente     VARCHAR2(50),      
  perimetro_sanitario_entrata  VARCHAR2(50),      
  pdc_economico_patr           VARCHAR2(50),      
  siope_entrata                VARCHAR2(50),      
  fl_migrato                   varchar2(1)    default 'N' not null,
  fl_scarto                  varchar2(1) default 'N' not null,
  ente_proprietario_id         number(10)     not null,
  data_ins                     date default sysdate not null
 )tablespace &1;

comment on table migr_ordinativo_entrata
  is 'migrazione ordinativo entrata';

alter table migr_ordinativo_entrata
  add constraint XPKMIGR_ordinativo_entrata primary key (ordinativo_id)
  using index 
  tablespace &2;
 
create unique index xifmigr_ordinativo_ent_pklog on migr_ordinativo_entrata (numero_ordinativo, anno_esercizio,ente_proprietario_id)
 tablespace &2;
 
create table migr_ordinativo_entrata_ts ( 
  ordinativo_ts_id      number(10)    NOT NULL,
  ordinativo_id   			number(10)    NOT NULL,
  anno_esercizio  			number(4)     NOT NULL,
  numero_ordinativo  		number(10)    NOT NULL,
  quota_ordinativo  		number(10)    NOT NULL,
  anno_accertamento     NUMBER(4)     default 0  NOT NULL,
  numero_accertamento   NUMBER(6)     default 0  NOT NULL,
  numero_subaccertamento NUMBER(6)    default 0  NOT NULL,  
  data_scadenza          varchar2(10),
  descrizione            varchar2(500) not null,
  importo_iniziale      number(15,2) default 0 NOT NULL, 
  importo_attuale       number(15,2) default 0 NOT NULL, 
  anno_documento        number(4),
  numero_documento      varchar2(20),
  tipo_documento        varchar2(10),
  cod_soggetto_documento number(10),
  frazione_documento     number(5),
  ente_proprietario_id   number(10) not null,
  fl_scarto                  varchar2(1) default 'N' not null,
  fl_migrato             varchar2(1) default 'N' not null,
  data_ins               date default sysdate not null
)tablespace &1;

comment on table migr_ordinativo_entrata_ts
  is 'migrazione ordinativi di entrata - quote';

alter table migr_ordinativo_entrata_ts
  add constraint XPKMIGR_ordinativo_entrata_ts primary key (ordinativo_ts_id)
  using index 
  tablespace &2;
  
/*create unique index xifmigr_ord_ent_ts_pklog on migr_ordinativo_entrata_ts (quota_ordinativo,numero_ordinativo, anno_esercizio,ente_proprietario_id)
 tablespace &2;*/


create  index xifmigr_ord_ent_ts_pklog on migr_ordinativo_entrata_ts (numero_ordinativo, anno_esercizio,ente_proprietario_id)
 tablespace &2;


 create  index xifmigr_ord_ent_ts_ord_id on migr_ordinativo_entrata_ts (ordinativo_id,ente_proprietario_id)
 tablespace &2;
 
create index xifmigr_ord_ent_ts_mov on migr_ordinativo_entrata_ts (numero_subaccertamento,numero_accertamento, anno_accertamento, anno_esercizio,ente_proprietario_id)
 tablespace &2;
 

 
create table migr_ordinativo_entrata_scarto 
(
 ordinativo_scarto_id  number(10)     not null,
 numero_ordinativo     number(10)     not null,
 anno_esercizio        varchar2(4)    not null,
 tipo_scarto           varchar2(50),
 motivo_scarto         varchar2(2500) not null,
 fl_migrato            varchar2(1)    default 'N' not null,
 ente_proprietario_id   number(10)     not null,
 data_ins               date default sysdate not null
)
tablespace &1; 

comment on table migr_ordinativo_entrata_scarto
  is 'tracciatura scarti ordinativo entrata';

alter table migr_ordinativo_entrata_scarto
  add constraint XPKMIGR_ORD_ENTRATA_SCARTO primary key (ordinativo_scarto_id)
  using index 
 tablespace &2;


 
create table migr_ordinativo_ent_ts_scarto 
(
 ordinativo_ts_scarto_id  number(10)     not null,
 numero_ordinativo  	  	number(10)    NOT NULL,
 quota_ordinativo         number(10)     not null,
 anno_esercizio           varchar2(4)    not null,
 tipo_scarto              varchar2(50),
 motivo_scarto            varchar2(2500) not null,
 fl_migrato               varchar2(1)    default 'N' not null,
 ente_proprietario_id     number(10)     not null,
 data_ins                 date default sysdate not null
)
tablespace &1; 

comment on table migr_ordinativo_ent_ts_scarto
  is 'tracciatura scarti migrazione ordinativo entrata quote';

alter table migr_ordinativo_ent_ts_scarto
  add constraint XPKMIGR_ORD_ENTRATA_TS_SCARTO primary key (ordinativo_ts_scarto_id)
  using index 
  tablespace &2;


create index XIFMIGR_ORDENT_TS_SCA_PKLOGICA on migr_ordinativo_ent_ts_scarto (quota_ordinativo,numero_ordinativo,anno_esercizio)
tablespace &2;
  
  
  --------------------------------------------------------------------------------------
    
drop table migr_provv_cassa cascade constraints;
drop table migr_provv_cassa_scarto cascade constraints;

create table migr_provv_cassa  (
    provvisorio_id               NUMBER(10) NOT NULL,
    tipo_eu                      VARCHAR2(1) NOT NULL,
    anno_provvisorio             NUMBER(4) NOT NULL,
    numero_provvisorio           NUMBER (10) NOT NULL,
    causale                      VARCHAR2(500) ,
    sub_causale                  VARCHAR2(500),
    data_emissione               VARCHAR2(10) NOT NULL,
    importo                      NUMBER(15,2) DEFAULT 0 NOT NULL ,
    denominazione_soggetto       VARCHAR2(500) ,
    data_annullamento            VARCHAR2(10) ,
    data_regolarizzazione        VARCHAR2(10) ,
    ente_proprietario_id number(10) not null,
    fl_scarto                  varchar2(1) default 'N' not null,
    fl_migrato varchar2(1) default 'N' not null,
    data_ins date default sysdate not null
)tablespace &1;

comment on table migr_provv_cassa
  is 'migrazione provvisori di cassa';

alter table migr_provv_cassa
  add constraint XPKMIGR_provv_cassa primary key (provvisorio_id)
  using index 
  tablespace &2;
 
create table migr_provv_cassa_scarto 
(
 provvisorio_scarto_id  number(10)     not null,
 tipo_eu                VARCHAR2(1) NOT NULL,
 numero_provvisorio     number(10)     not null,
 anno_esercizio         varchar2(4)    not null,
 motivo_scarto          varchar2(2500) not null,
 fl_migrato             varchar2(1)    default 'N' not null,
 ente_proprietario_id   number(10)     not null,
 data_ins               date default sysdate not null
)
tablespace &1; 

comment on table migr_provv_cassa_scarto
  is 'tracciatura scarti migrazione provv cassa';

alter table migr_provv_cassa_scarto
  add constraint XPKMIGR_PROVV_CASSA_SCARTO primary key (provvisorio_scarto_id)
  using index 
  tablespace &2;


create index XIFMIGR_PROVVCASSA_SCA_PK on migr_provv_cassa_scarto (tipo_eu,numero_provvisorio,anno_esercizio)
tablespace &2;
 
-----------------------------------------------------------------------------------------------------

drop table migr_provv_cassa_ordinativo cascade constraints;
drop table migr_provv_cassa_ord_scarto cascade constraints;

create table migr_provv_cassa_ordinativo(
    provvisorio_id  NUMBER(10) NOT NULL,
  	tipo_eu  VARCHAR2(1) NOT NULL,
  	ordinativo_id  NUMBER(10) NOT NULL,
  	
  	ord_numero	 NUMBER(10) NOT NULL,
	anno_esercizio	 NUMBER(4) NOT NULL,
	anno_provvisorio	 NUMBER(4) NOT NULL,
	numero_provvisorio	 NUMBER(10) NOT NULL,
	
  	importo  NUMBER(15,2) default 0 NOT NULL,
   	ente_proprietario_id   number(10)     not null,
   	fl_scarto                  varchar2(1) default 'N' not null,
    fl_migrato varchar2(1) default 'N' not null,
   	data_ins               date default sysdate not null
)tablespace &1;

comment on table migr_provv_cassa_ordinativo
  is 'migrazione provvisori di cassa ordinativo';

alter table migr_provv_cassa_ordinativo
  add constraint XPKMIGR_provv_cassa_ordinativo primary key (provvisorio_id)
  using index 
  tablespace &2;
  
  

create table migr_provv_cassa_ord_scarto 
(
 provvisorio_scarto_id  number(10)     not null, 
 anno_esercizio	        number(4)      not null,
 ordinativo_id          number(10)     not null,
 provvisorio_id         number(10)     not null,
 tipo_eu                varchar2(1)    not null,
 motivo_scarto          varchar2(2500) not null,
 fl_migrato             varchar2(1)    default 'N' not null,
 ente_proprietario_id   number(10)     not null,
 data_ins               date default sysdate not null
)
tablespace &1; 

comment on table migr_provv_cassa_ord_scarto
  is 'migrazione scarti provvisori di cassa ordinativo';

alter table migr_provv_cassa_ord_scarto
  add constraint XPKMIGR_PROVV_CASSAORD_SCA primary key (provvisorio_scarto_id)
  using index 
  tablespace &2;
  
  -----------------------------------------------------
    
  drop table migr_ordinativo_relaz cascade constraints;

create table   migr_ordinativo_relaz(
    ordinativo_id_da  NUMBER(10)  NOT NULL,
  	tipo_ord_da  VARCHAR2(1)  NOT NULL,
  	ordinativo_id_a  VARCHAR2(10)  NOT NULL,
  	tipo_ord_a  VARCHAR2(1)  NOT NULL,
  	tipo_relaz  VARCHAR2(50)  NOT NULL,
  	numero_da NUMBER(10)  NOT NULL,
  	anno_esercizio_da NUMBER(4)  NOT NULL,
  	numero_a NUMBER(10)  NOT NULL,
  	anno_esercizio_a NUMBER(4)  NOT NULL,
  	fl_scarto                  varchar2(1) default 'N' not null,
    fl_migrato varchar2(1) default 'N' not null,
   	ente_proprietario_id   number(10)     not null,
   	data_ins               date default sysdate not null
)tablespace &1;

comment on table migr_ordinativo_relaz
  is 'migrazione ordinativo rel';

alter table migr_ordinativo_relaz
  add constraint XPKMIGR_ordinativo_relaz primary key (ordinativo_id_da)
  using index 
  tablespace &2;
  
  
