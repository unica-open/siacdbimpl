/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE MIGR_DOC_SPESA ADD tipo_fonte varchar2(10);
ALTER TABLE MIGR_DOCQUO_SPESA ADD tipo_fonte varchar2(10);
ALTER TABLE MIGR_DOC_ENTRATA ADD tipo_fonte varchar2(10);
ALTER TABLE MIGR_DOCQUO_ENTRATA ADD tipo_fonte varchar2(10);

create  index XFIMIGR_DOCQUO_SPESA_KEY2 on migr_docquo_spesa (tipo_fonte,anno,numero,codice_soggetto,frazione)
tablespace &2;

ALTER TABLE MIGR_DOC_SPESA ADD tipoRif	varchar2(10);
ALTER TABLE MIGR_DOC_SPESA ADD annoRif	varchar2(4);
ALTER TABLE MIGR_DOC_SPESA ADD numeroRif	varchar2(20);

comment on column migr_doc_spesa.tipoRif
  is 'tipo documento di riferimento';

comment on column migr_doc_spesa.annoRif
  is 'anno documento di riferimento';

comment on column migr_doc_spesa.numeroRif
  is 'numero documento di riferimento';

create  index XFIMIGR_DOC_SPESA_KEYDOCRIF on migr_doc_spesa (tipoRif,annoRif,numeroRif,codice_soggetto)
tablespace &2;

ALTER TABLE MIGR_DOC_ENTRATA ADD tipoRif	varchar2(10);
ALTER TABLE MIGR_DOC_ENTRATA ADD annoRif	varchar2(4);
ALTER TABLE MIGR_DOC_ENTRATA ADD numeroRif	varchar2(20);

comment on column migr_doc_entrata.tipoRif
  is 'tipo documento di riferimento';

comment on column migr_doc_entrata.annoRif
  is 'anno documento di riferimento';

comment on column migr_doc_entrata.numeroRif
  is 'numero documento di riferimento';

create  index XFIMIGR_DOC_ENTRATA_KEYDOCRIF on MIGR_DOC_ENTRATA (tipoRif,annoRif,numeroRif,codice_soggetto)
tablespace &2;

-- alter eseguita anche per coto
alter table migr_atto_allegato add numero_titolario varchar2(500);
alter table migr_atto_allegato add anno_titolario varchar2(4);
alter table migr_atto_allegato add versione number(3);
alter table migr_atto_allegato add fl_scarto varchar2(1);
update migr_atto_allegato set fl_scarto = 'N';
ALTER TABLE migr_atto_allegato MODIFY(fl_scarto DEFAULT 'N');

--create  index XFIMIGR_ATTO_ALLEGATO_PROV on migr_atto_allegato (anno_provvedimento,numero_provvedimento,tipo_provvedimento,sac_provvedimento,ente_proprietario_id)
create  index XFIMIGR_ATTO_ALLEGATO_PROV on migr_atto_allegato (anno_provvedimento,numero_provvedimento,tipo_provvedimento,sac_provvedimento)
tablespace &2;

--08.09.2015 indice creato per migrazione elenco doc allegati

create index XIFMIGR_DOCQUO_SPESA_LIQ on MIGR_DOCQUO_SPESA (anno_esercizio, numero_liquidazione, ente_proprietario_id)
  tablespace &2;
        
alter table migr_elenco_doc_allegati add migr_tipo_elenco number(1);

ALTER TABLE migr_docquo_spesa MODIFY(elenco_doc_id DEFAULT 0);

ALTER TABLE migr_doc_spesa add fl_fittizio varchar2(1);
ALTER TABLE migr_doc_spesa MODIFY(fl_fittizio DEFAULT 'N');
ALTER TABLE migr_doc_spesa add atto_allegato_id number(10);
ALTER TABLE migr_doc_spesa add elenco_doc_id number(10) null;

 -- aumentato il numero da 20 a 50 per ospitare il nr del doc fittizio (migrazione allegato atto)
ALTER TABLE migr_doc_spesa modify (numero varchar2(50));
ALTER TABLE migr_docquo_spesa modify (numero varchar2(50));

-- indice che serve per l'update dello stato dell'atto allegato in fase di migrazione (regp)
create index XFIMIGR_ELENCO_DOC_ATTO_ALL2 on migr_elenco_doc_allegati (atto_allegato_id,migr_tipo_elenco, ente_proprietario_id)
  tablespace &2;

alter table migr_atto_allegato add numero_elenco number(3);
update migr_atto_allegato set numero_elenco = '0' where numero_elenco is null;
ALTER TABLE migr_atto_allegato MODIFY(numero_elenco DEFAULT 0);

alter table migr_atto_allegato add fl_daelenco varchar2(1);
update migr_atto_allegato set fl_daelenco = 'N';
ALTER TABLE migr_atto_allegato MODIFY(fl_daelenco DEFAULT 'N');

--drop index XFIMIGR_ATTO_ALLEGATO_EL on migr_atto_allegato (anno_provvedimento,sac_provvedimento, numero_elenco)
--  tablespace &2;

--create index XFIMIGR_ATTO_ALLEGATO_EL on migr_atto_allegato (anno_provvedimento,sac_provvedimento, numero_elenco)
--  tablespace &2;

-- 17.09
create  index XFIMIGR_DOC_SPESA_ENTE on migr_doc_spesa (ente_proprietario_id,fl_fittizio)
tablespace &2;

create  index XFIMIGR_SOGGETTO_SOGENTE on migr_soggetto (ente_proprietario_id,codice_soggetto)
tablespace &2;

-- 18.09.2015
-- alter eseguita anche per coto
alter table migr_atto_allegato add numero_provvedimento_calcolato varchar2(20);

-- 22.09.2015
-- aggiunti per procedura migrazione_atto_allegato
--create index XFIMIGR_ATTO_ALLEGATO_FL on migr_atto_allegato (Fl_Migrato,Fl_Scarto, fl_daelenco)
--  tablespace &2;
create index XFIMIGR_ATTO_ALLEGATO_FL2 on migr_atto_allegato (ente_proprietario_id,Fl_Migrato,Fl_Scarto, fl_daelenco)
  tablespace &2;
create index XIFMIGR_DOC_SPESA_ATTO on MIGR_DOC_SPESA (atto_allegato_id, elenco_doc_id)
  tablespace &2;

-- 25.09.2015
-- alter eseguita anche per coto
alter table migr_doc_spesa add collegato_cec varchar2(1);
update migr_doc_spesa set collegato_cec = 'N';
ALTER TABLE migr_doc_spesa MODIFY(collegato_cec DEFAULT 'N');
alter table migr_docquo_spesa add importo_splitreverse	number(15,2);
update migr_docquo_spesa set importo_splitreverse = 0;
alter table migr_docquo_spesa add tipo_iva_splitreverse	varchar2(10);
alter table migr_docquo_spesa add data_pagamento_cec	varchar2(10);

-- 14.10.2015
alter table migr_atto_allegato add data_completamento varchar2(10);
alter table migr_atti_liquid_temp add data_complet DATE;

-- 29.10.2015
-- Aggiunti durante lo sviluppo per pvto
alter table migr_doc_spesa add codice_soggetto_fonte number(10);
alter table migr_doc_spesa add sede_id number(10);
alter table migr_docquo_spesa add codice_soggetto_fonte number(10);
alter table migr_docquo_spesa add sede_id number(10);

--10.11.2015
alter table migr_doc_spesa add anno_registro_fatt varchar2(4);
alter table migr_doc_entrata add anno_registro_fatt varchar2(4);

--30.11.2015
alter table migr_docquo_spesa_iva add fl_scarto varchar2(1);
update migr_docquo_spesa_iva set fl_scarto = 'N';
ALTER TABLE migr_docquo_spesa_iva MODIFY(fl_scarto DEFAULT 'N');
-- creata tabella migr_docquospesaivaaliq_scarto
-- creata sequence migr_quoivaaliqscarto_id_seq
-- creata tabella migr_sezionale_mapping

--03.12.2015
alter table migr_atto_allegato add settore varchar2(50);
alter table migr_doc_spesa add anno_repertorio varchar2(4);
alter table migr_doc_entrata add anno_repertorio varchar2(4);
alter table migr_atti_liquid_temp modify (settore varchar2(50));

--09.12.2015
alter table migr_doc_spesa modify (DATA_SCANDENZA_NEW varchar2(19));
alter table migr_doc_spesa modify (data_ricezione varchar2(19));
alter table migr_doc_spesa modify (data_repertorio varchar2(19));
alter table migr_doc_spesa modify (data_sospensione varchar2(19));
alter table migr_doc_spesa modify (data_riattivazione varchar2(19));

alter table migr_docquo_spesa modify (data_scadenza_new varchar2(19));
alter table migr_docquo_spesa modify (data_riattivazione varchar2(19));
alter table migr_docquo_spesa modify (data_sospensione varchar2(19));
alter table migr_docquo_spesa modify (data_certif_crediti varchar2(19));

alter table migr_doc_entrata modify (data_repertorio varchar2(19));

--29.12.2015
alter table migr_docquo_spesa modify (flag_manuale null);
alter table migr_docquo_spesa modify flag_manuale default null;
alter table migr_docquo_entrata modify (flag_manuale null);
alter table migr_docquo_entrata modify flag_manuale default null;

--01.02.2016
alter table migr_docquo_spesa modify (importo_splitreverse null);
alter table migr_docquo_spesa modify  importo_splitreverse default NULL;

--05.12.2016
alter table migr_docquo_spesa add codice_pcc     VARCHAR2(10);
alter table migr_docquo_spesa add codice_ufficio VARCHAR2(10);

--03.01.2017
alter table migr_atto_allegato add attoal_flag_ritenute VARCHAR2(1) DEFAULT 'N' NOT NULL;
