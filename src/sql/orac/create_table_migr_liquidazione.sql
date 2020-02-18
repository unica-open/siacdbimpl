/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- tabelle stage ORACLE
-- creare su tbl medium per enti maggiori (coto, regp, pvto)
drop table migr_liquidazione cascade constraints;
drop table migr_liquidazione_scarto cascade constraints;

create table migr_liquidazione
(
 liquidazione_id         number(10)  not null,
 numero_liquidazione     number(10)  not null,
 anno_esercizio          varchar2(4) not null,
 data_emissione          varchar2 (10) not null,
 numero_liquidazione_orig number(10)  not null,
 anno_esercizio_orig     varchar2(4) not null,
 data_emissione_orig     varchar2 (10) not null,
 descrizione             varchar2(500) not null,
 importo                 NUMBER(15,2)  default 0 not null,
 codice_soggetto         number(10)    not null,
 sede_id                 number(10), -- chiave tabella migr_sede_secondaria
 codice_progben 		     varchar2(10),
 codice_modpag_del	     varchar2(10),
 stato_operativo         varchar2(1)   not null,
 anno_provvedimento      varchar2(4)   not null,
 numero_provvedimento_calcolato number(10) null,
 numero_provvedimento    number(10)    null,
 tipo_provvedimento      varchar2(20) null,
 sac_provvedimento       varchar2(20)   null,
 oggetto_provvedimento   varchar2(500) null,
 note_provvedimento      varchar2(500) null,
 stato_provvedimento     varchar2(50)  null,
 numero_impegno          number(10)  default 0 null,
 anno_impegno            varchar2(4) not null,
 numero_subimpegno       number(10)  default 0 null,
 numero_mutuo 			     varchar2(200) null,
 cofog                   VARCHAR2(50)  null,
 pdc_finanziario         VARCHAR2(50)  null,
 ente_proprietario_id number(10) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins date default sysdate not null,
 -- 20.11.2015 aggiunto campo siope_spesa
 siope_spesa             VARCHAR2(50)  null
/*saranno da aggiungerre gli attributi della transazione elementare ovvero:
 missione                VARCHAR2(50)  null,
 programma               VARCHAR2(50)  null,
 transazione_ue_spesa    VARCHAR2(50)  null,
 spesa_ricorrente        VARCHAR2(50)  null,
 perimetro_sanitario_spesa VARCHAR2(50) null,
 politiche_regionali_unitarie VARCHAR2(50) null,
 pdc_economico_patr           VARCHAR2(50) null,
*/
)tablespace &1;

comment on table migr_liquidazione
  is 'migrazione liquidazioni';

alter table migr_liquidazione
  add constraint XPKMIGR_LIQUIDAZIONE primary key (liquidazione_id)
  using index 
  tablespace &2;
/*
create index XIFMIGR_IMPEGNO_NR on MIGR_IMPEGNO (numero_impegno,anno_impegno,anno_esercizio)
tablespace &2;*/
create index XIFMIGR_LIQUIDAZIONE_PKLOG on MIGR_LIQUIDAZIONE (numero_liquidazione, anno_esercizio)
  tablespace &2;
  
create index XIFMIGR_LIQUIDAZIONE_PKLOG2 on MIGR_LIQUIDAZIONE (numero_liquidazione, anno_esercizio, ente_proprietario_id)
  tablespace &2;
  
create index XIFMIGR_LIQUIDAZIONE_PROV on MIGR_LIQUIDAZIONE (tipo_provvedimento, anno_provvedimento, numero_provvedimento, sac_provvedimento, ente_proprietario_id)
  tablespace &2;

create table migr_liquidazione_scarto 
(
 liquidazione_scarto_id	number(10)    not null,
 numero_liquidazione    number(10)  not null,
 anno_esercizio         varchar2(4) not null,
 motivo_scarto          varchar2(2500) not null,
 fl_migrato 			varchar2(1) default 'N' not null,
 ente_proprietario_id   number(10)    not null,
 data_ins               date default sysdate not null
)
tablespace &1; 

comment on table migr_liquidazione_scarto
  is 'tracciatura scarti migrazione liquidazioni';

alter table migr_liquidazione_scarto
  add constraint XPKMIGR_LIQUIDAZIONE_SCARTO primary key (liquidazione_scarto_id)
  using index 
  tablespace &2;


create index XIFMIGR_LIQ_SCARTO_PKLOGICA on migr_liquidazione_scarto (numero_liquidazione,anno_esercizio)
tablespace &2;

--20.05.2015
--REGIONE: creazione indici necessari alla query gerarchica.
--CREATE INDEX idx_nliq_nliqPrec_anno ON liquidazioni (nliq,nliq_prec,anno_esercizio); 
--CREATE INDEX i_liquidazioni_nliqprec ON liquidazioni (nliq_prec); 
