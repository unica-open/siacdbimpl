/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE MIGR_SOGGETTO MODIFY PARTITA_IVA varchar2(50);
ALTER TABLE MIGR_MODPAG add  codice_modpag_del	varchar2(10);

-- 17.09.2015 creato per migrazione atti allegati
create  index XFIMIGR_SOGGETTO_SOGENTE on migr_soggetto (ente_proprietario_id,codice_soggetto)
tablespace &2;

-- 12.10.2015 dani tolto vincolo not null su sede secondaria ( per pvto che ha sedi senza via)
alter table migr_sede_secondaria modify (via null);
