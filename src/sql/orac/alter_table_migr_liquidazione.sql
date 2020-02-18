/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE MIGR_LIQUIDAZIONE ADD codice_progben varchar2(10);
ALTER TABLE MIGR_LIQUIDAZIONE ADD numero_liquidazione_orig number(10);
ALTER TABLE MIGR_LIQUIDAZIONE ADD anno_esercizio_orig varchar2(4);
ALTER TABLE MIGR_LIQUIDAZIONE ADD data_emissione_orig varchar2 (10);
ALTER TABLE MIGR_LIQUIDAZIONE ADD sede_id number(10);


--alter table MIGR_LIQUIDAZIONE rename column codice_progben to codice_modpag;
ALTER TABLE MIGR_LIQUIDAZIONE ADD codice_modpag_del	varchar2(10);
alter table MIGR_LIQUIDAZIONE_SCARTO add fl_migrato varchar2(1) default 'N' not null;

create index XIFMIGR_LIQUIDAZIONE_PKLOG on MIGR_LIQUIDAZIONE (numero_liquidazione, anno_esercizio)
  tablespace &2;

create index XIFMIGR_LIQUIDAZIONE_PKLOG2 on MIGR_LIQUIDAZIONE (numero_liquidazione, anno_esercizio, ente_proprietario_id)
  tablespace &2;

-- 08.09.15 indice creato per migrazione elenco doc allegati
create index XIFMIGR_LIQUIDAZIONE_PROV on MIGR_LIQUIDAZIONE (tipo_provvedimento, anno_provvedimento, numero_provvedimento, sac_provvedimento, ente_proprietario_id)
  tablespace &2;

-- 18.09.2015 nuovo campo numero_provvedimento_calcolato
alter table migr_liquidazione add numero_provvedimento_calcolato number(10) null;

-- 20.11.2015 aggiunto campo siope_spesa
alter table migr_liquidazione add siope_spesa VARCHAR2(50)  null;
