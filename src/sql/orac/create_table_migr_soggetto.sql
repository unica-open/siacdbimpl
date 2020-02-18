/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- tabelle stage ORACLE

drop table migr_soggetto cascade constraint;
drop table migr_soggetto_classe cascade constraint;
drop table migr_indirizzo_secondario cascade constraint;
drop table migr_recapito_soggetto cascade constraint;
drop table migr_sede_secondaria cascade constraint;
drop table migr_modpag cascade constraint;
drop table migr_relaz_soggetto cascade constraint;
drop table migr_mod_accredito;

drop table migr_classe cascade constraint;
drop table migr_soggetto_temp cascade constraint;
drop table migr_delegati cascade constraint;
drop table MIGR_SOGGETTO_SCARTO cascade constraints;

create table migr_soggetto
(
 soggetto_id  number(10) not null,
 delegato_id  number(10) default 0 not null,
 codice_soggetto   number(10),
 codice_progdel_del number(10),
 codice_progben_del number(10),
 fl_genera_codice varchar2(1) default 'N' not null,
 tipo_soggetto  VARCHAR2(3) not null,
 forma_giuridica  varchar2(150)  null,
 ragione_sociale  VARCHAR2(150) not null,
 codice_fiscale  VARCHAR2(16),
 partita_iva  VARCHAR2(50),
 codice_fiscale_estero  VARCHAR2(50),
 cognome  VARCHAR2(150),
 nome  VARCHAR2(150),
 sesso  varchar2(2),
 data_nascita  varchar2 (10),
 comune_nascita  VARCHAR2(150),
 provincia_nascita  VARCHAR2(150),
 nazione_nascita  VARCHAR2(150),
 indirizzo_principale  varchar2(1) default 'N' not null,
 tipo_indirizzo  varchar2(200),
 tipo_via  VARCHAR2(200),
 via  VARCHAR2(500),
 numero_civico  VARCHAR2(7),
 interno  VARCHAR2(10),
 frazione  VARCHAR2(150),
 cap  VARCHAR2(5),
 comune  VARCHAR2(150),
 prov  VARCHAR2(150),
 nazione  VARCHAR2(150),
 avviso  varchar2(1) default 'N' not null,
 tel1             VARCHAR2(15),
 tel2  VARCHAR2(15),
 fax  VARCHAR2(15),
 sito_www  VARCHAR2(150),
 email  VARCHAR2(150),
 contatto_generico  VARCHAR2(250),
 stato_soggetto  varchar2(20) not null,
 note  VARCHAR2(1000),
 generico	VARCHAR2(1) default 'N' not null,
 classif varchar2(200),
 matricola_hr_spi varchar2(7),
 ente_proprietario_id number(10) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins date default sysdate not null
)
tablespace &1;

comment on table migr_soggetto
  is 'migrazione soggetti - anagrafica principale';
  
comment on column migr_soggetto.codice_soggetto
  is 'codice soggetto in archivio di provenienza es. codben';

comment on column migr_soggetto.tipo_soggetto  
 is 'tipo soggeto relativo alla sua natura giuridica-valori ammessi   PF=Persona Fisica,PFI=Persona Fisica con Piva,PGI=Persona Giuridica,PG=Persona Giuridica senza Piva';
 
alter table migr_soggetto
  add constraint XPKMIGR_SOGGETTO primary key (soggetto_id)
  using index 
  tablespace &2;


  
create  index XFIMIGR_SOGG_CODSOG on migr_soggetto (codice_soggetto)
tablespace &2;

create index XFIMIGR_SOGG_DELEGATOID on migr_soggetto (delegato_id)
tablespace &2;

create  index XFIMIGR_SOGGETTO_SOGENTE on migr_soggetto (ente_proprietario_id,codice_soggetto)
tablespace &2;


create table migr_soggetto_classe
(
 soggetto_classe_id number (10) not null,
 soggetto_id  number(10) not null,
 classe_soggetto	VARCHAR2(200) not null,
 ente_proprietario_id number(10) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins date default sysdate not null
)  
tablespace &1;

comment on table migr_soggetto_classe
  is 'migrazione soggetti - associazione tra soggetti e classificazioni';


alter table migr_soggetto_classe
  add constraint XPKMIGR_SOGGETTO_CLASSE primary key (soggetto_classe_id)
  using index 
  tablespace &2;

--alter table migr_soggetto_classe
--  add constraint XIFMIGR_SOGGETTO_CLASSE_SOGG foreign key (soggetto_id)
--  references migr_soggetto (soggetto_id);


create table migr_indirizzo_secondario
(  
  indirizzo_id	number(10) not null,
  soggetto_id	number(10) not null,
  codice_indirizzo	number(10) null,
  indirizzo_principale	varchar2(1) default 'N' not null,
  tipo_indirizzo	varchar2(200) not null,
  tipo_via	VARCHAR2(200)  null,
  via	VARCHAR2(500) null,
  numero_civico	VARCHAR2(7),
  interno	VARCHAR2(10),
  frazione	VARCHAR2(150),
  cap	VARCHAR2(5),
  comune	VARCHAR2(150),
  prov	VARCHAR2(150),
  nazione	VARCHAR2(150),
  avviso	varchar2(1) default 'N' not null,
  ente_proprietario_id number(10) not null,
  fl_migrato varchar2(1) default 'N' not null,
  data_ins date default sysdate not null
)  
tablespace &1;

comment on table migr_indirizzo_secondario
  is 'migrazione soggetti - indirizzi secondari';

comment on column migr_indirizzo_secondario.codice_indirizzo 
  is 'codice indirizzo in archivio provenienza es.cod_indir';
 
alter table migr_indirizzo_secondario
  add constraint XPKMIGR_INDIRIZZO_SEC primary key (indirizzo_id)
  using index 
  tablespace &2;

--alter table migr_indirizzo_secondario
--  add constraint XIFMIGR_INDIRIZZO_SEC_SOGG foreign key (soggetto_id)
--  references migr_soggetto (soggetto_id);

create table migr_recapito_soggetto
(
 recapito_id	number(10) not null,
 soggetto_id	number(10) not null,
 indirizzo_id	number(10) null,
 tipo_recapito	varchar2(20) not null,
 recapito 	VARCHAR2(150) not null,
 avviso	varchar2(1) default 'N' not null,
 ente_proprietario_id number(10) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins date default sysdate not null
)
tablespace &1;

comment on table migr_recapito_soggetto
  is 'migrazione soggetti - recapiti del soggetto derivanti da indirizzi alternativi da imputare al soggetto';

alter table migr_recapito_soggetto
  add constraint XPKMIGR_RECAPITO_SOGG primary key (recapito_id)
  using index 
  tablespace &2;

--alter table migr_recapito_soggetto
 -- add constraint XIFMIGR_RECAPITO_SOGG_SOGG foreign key (soggetto_id)
 -- references migr_soggetto (soggetto_id);
  
--alter table migr_recapito_soggetto
--  add constraint XIFMIGR_RECAPITO_SOGG_IND foreign key (indirizzo_id)
--  references migr_indirizzo_secondario (indirizzo_id);
  

create table migr_sede_secondaria
(
 sede_id	number(10) not null,
 soggetto_id	number(10) not null,
 codice_sede   number(10),
 codice_indirizzo	number(10) null,
 codice_modpag	varchar2(10) null,
 ragione_sociale	VARCHAR2(150) not null,
 tel1           	VARCHAR2(100),
 tel2	VARCHAR2(100),
 fax	VARCHAR2(100),
 sito_www	VARCHAR2(150),
 email	VARCHAR2(150),
 contatto_generico	VARCHAR2(250),
 note	VARCHAR2(500),
 tipo_relazione	VARCHAR2(50) not null,
 tipo_indirizzo	VARCHAR2(200) not null,
 indirizzo_principale	varchar2(1) default 'N' not null,
 tipo_via	VARCHAR2(200)  null,
 via	VARCHAR2(500) null, -- 12.10.2015 tolto vincolo not null
 numero_civico	VARCHAR2(7),
 interno	VARCHAR2(10),
 frazione	VARCHAR2(150),
 cap	varchar2(5),
 comune	varchar2(150),
 prov	varchar2(150),
 nazione	VARCHAR2(150),
 avviso	varchar2(1) default 'N' not null,
 ente_proprietario_id number(10) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins date default sysdate not null
)
tablespace &1;

comment on table migr_sede_secondaria
  is 'migrazione soggetti - sedi secondarie - derivanti da sedi secondarie o indirizzi alternativi con dignita'' di essere sede secondaria';

comment on column migr_sede_secondaria.codice_indirizzo
 is 'codice indirizzo in archivio provenienza es.cod_indir - da indicare se la sede proviene da indirizzo alternativo non registrato come indirizzo secondario ';

alter table migr_sede_secondaria
  add constraint XPKMIGR_SEDE_SECONDARIA primary key (sede_id)
  using index 
  tablespace &2;

--alter table migr_sede_secondaria
--  add constraint XIFMIGR_SEDE_SECONDARIA_SOGG foreign key (soggetto_id)
--  references migr_soggetto (soggetto_id);

create index XFI_SEDE_SEC_SOG_PROG on migr_sede_secondaria (soggetto_id,codice_modpag)
tablespace &2;

create table migr_modpag
(
 modpag_id	number(10) not null,
 soggetto_id	number(10) not null,
 sede_id	number(10),
 codice_modpag	varchar2(10),
 codice_modpag_del	varchar2(10),
 delegato_id	  number(10) default 0 not null,
 fl_genera_codice varchar2(1) default 'N' not null,
 cessione	varchar2(3),
 sede_secondaria	varchar2(1) default 'N' not null,
 codice_accredito	VARCHAR2(6) not null,
 iban	VARCHAR2(34),
 bic	VARCHAR2(11),
 abi    VARCHAR2(200),
 cab    VARCHAR2(200),
 conto_corrente	VARCHAR2(15),
 conto_corrente_intest VARCHAR2(500),
 quietanzante	VARCHAR2(500),
 codice_fiscale_quiet	VARCHAR2(16),
 codice_fiscale_del VARCHAR2(16),
 data_nascita_qdel VARCHAR2(10),
 luogo_nascita_qdel	  varchar2(150),
 stato_nascita_qdel	  varchar2(150),
 stato_modpag	VARCHAR2(20) not null,
 note	VARCHAR2(1000),
 email	VARCHAR2(150),
 ente_proprietario_id number(10) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins date default sysdate not null
)
tablespace &1;

comment on table migr_modpag
  is 'migrazione soggetti - modalita'' di pagamento soggetto';

comment on column migr_modpag.codice_modpag
 is 'codice modalita'' di pagamento in archivio provenienza es.progben';

comment on column migr_modpag.sede_id
 is 'identificativo di riferimento in migr_sede_secondaria -  da indicare se la modalita'' di pagamento e'' da associare alla sede';


alter table migr_modpag
  add constraint XPKMIGR_MODPAG primary key (modpag_id)
  using index 
  tablespace &2;

--alter table migr_modpag
--  add constraint XIFMIGR_MODPAG_SOGG foreign key (soggetto_id)
--  references migr_soggetto (soggetto_id);

--alter table migr_modpag
--  add constraint XIFMIGR_MODPAG_SEDE_SEC foreign key (sede_id)
--  references migr_sede_secondaria (sede_id);

create index XFI_MDP_SOG_PROG on migr_modpag (soggetto_id,codice_modpag)
tablespace &2;

create index XFI_MDP_DELEGATO_ID on migr_modpag (delegato_id)
tablespace &2;
  
create table migr_relaz_soggetto
(
 relaz_id	number(10) not null,
 tipo_relazione	VARCHAR2(200) not null,
 soggetto_id_da	number(10) not null,
 modpag_id_da	number(10),
 soggetto_id_a	number(10) not null,
 modpag_id_a	number(10),
 ente_proprietario_id number(10) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins date default sysdate not null
)
tablespace &1;

comment on table migr_relaz_soggetto
  is 'migrazione soggetti - relazione soggetti es. cessione del credito';
  
alter table migr_relaz_soggetto
  add constraint XPKMIGR_RELAZ_SOGGETTO primary key (relaz_id)
  using index 
  tablespace &2;

--alter table migr_relaz_soggetto
--  add constraint XIFMIGR_RELAZ_SOGGETTO_SOGG_DA foreign key (soggetto_id_da)
--  references migr_soggetto (soggetto_id);

--alter table migr_relaz_soggetto
--  add constraint XIFMIGR_RELAZ_SOGGETTO_SOGG_A foreign key (soggetto_id_a)
--  references migr_soggetto (soggetto_id);

----alter table migr_relaz_soggetto
--  add constraint XIFMIGR_RELAZ_SOGGETTO_MDP_DA foreign key (modpag_id_da)
--  references migr_modpag (modpag_id);

--alter table migr_relaz_soggetto
--  add constraint XIFMIGR_RELAZ_SOGGETTO_MDP_A foreign key (modpag_id_a)
--  references migr_modpag (modpag_id);

  
create table migr_mod_accredito
(
 accredito_id	number(3) not null,
 codice	        varchar2(10) not null,
 descri	        varchar2(150) not null,
 tipo_accredito varchar2(10) not null,
 priorita       number(2) default 0 not null,
 decodificaOIL  varchar2(150),
 ente_proprietario_id number(10) not null,
 fl_migrato varchar2(1) default 'N' not null,
 data_ins date default sysdate not null
)
tablespace &1;

comment on table migr_mod_accredito
  is 'migrazione soggetti - codifiche modalità di accredito con attribuzione della tipologia';
  
alter table migr_mod_accredito
  add constraint XPKMIGR_MOD_ACCREDITO primary key (accredito_id)
  using index 
  tablespace &2;
  

create table migr_classe
(
 classe_id	          number(10) not null,
 classe_code	        varchar2(100) not null,
 classe_desc	        varchar2(200) not null,
 codice_soggetto	    number(10) null,
 note_soggetto	      varchar2(200) null,
 ente_proprietario_id number(10) not null,
 fl_migrato           varchar2(1) default 'N' not null,
 data_ins date default sysdate not null
)
tablespace &1;

comment on table migr_classe
  is 'migrazione classi soggetto - soggetti che in contabilia generano classi anziche'' anagrafiche o classi in generale';
  
alter table migr_classe
  add constraint XPKMIGR_CLASSE primary key (classe_id)
  using index 
  tablespace &2;


create table migr_soggetto_temp
(codice_soggetto        number(10) not null,
 motivo                 varchar2(3) not null,
 ente_proprietario_id   number(10) not null,
 data_creazione         date default sysdate not null
)
tablespace &1;

comment on table migr_soggetto_temp
  is 'migrazione soggetti - appoggio soggetti da migrare';
  
alter table migr_soggetto_temp
  add constraint XPKMIGR_SOGGETTO_TEMP primary key (codice_soggetto)
  using index 
  tablespace &2;


create table migr_delegati
(
  delegato_id number(10) not null,
  codben      number(6) not null,
  progdel     number(6) not null,
  progben     number(6) not null,
  tipo        varchar2(5) not null,
  fl_quiet    varchar2(1) not null,
  fl_intest   varchar2(1) not null,
  tipo_relazione varchar2(50) null,
  ente_proprietario_id number(10) not null,
  fl_migrato varchar2(1) default 'N' not null,
  data_ins date default sysdate not null
)
tablespace &1;   

comment on table migr_delegati
  is 'migrazione delegati soggetti - appoggio delegati da migrare';
  
alter table migr_delegati
  add constraint XPKMIGR_DELEGATI primary key (delegato_id)
  using index 
  tablespace &2;


create index XFI_MIGR_DELEGATI_DEL on migr_delegati (codben,progben)
tablespace &2;

create index XFI_MIGR_DELEGATI_DELD on migr_delegati (codben,progdel)
tablespace &2;


create table MIGR_SOGGETTO_SCARTO
(
  soggetto_scarto_id    NUMBER(10) not null,
  codice_soggetto       NUMBER(6) not null,
  motivo_scarto        VARCHAR2(2500) not null,
  ente_proprietario_id NUMBER(10) not null,
  data_ins             DATE default sysdate not null
)
tablespace &1;

comment on table MIGR_SOGGETTO_SCARTO
  is 'tracciatura scarti migrazione soggetti';
 
alter table MIGR_SOGGETTO_SCARTO
  add constraint XPKMIGR_SOGGETTO_SCARTO primary key (soggetto_scarto_id)
  using index 
  tablespace &2;



create table TABACCRE_MODPAG_TES
(
  codaccre     VARCHAR2(2) not null,
  codaccre_tes VARCHAR2(2) not null,
  descri       VARCHAR2(100) not null
)
tablespace &1;

