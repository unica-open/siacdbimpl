/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
alter table migr_capitolo_uscita add  cofog	varchar2(20)  null;
alter table migr_capitolo_eccezione add  ente_proprietario_id	number(10);

alter table migr_capitolo_uscita add dicuiimpegnato_anno1 NUMBER(15,2) default 0 not null;
alter table migr_capitolo_uscita add dicuiimpegnato_anno2 NUMBER(15,2) default 0 not null;
alter table migr_capitolo_uscita add dicuiimpegnato_anno3 NUMBER(15,2) default 0 not null;

-- Davide 30.12.015 : modifica PK su migr_capitolo_eccezione
update migr_capitolo_eccezione
  set ente_proprietario_id=&p_ente;
  
  commit;

ALTER TABLE migr_capitolo_eccezione MODIFY ente_proprietario_id number(10) not null;

ALTER TABLE migr_capitolo_eccezione
DROP CONSTRAINT XPKMIGR_CAPITOLO_ECC;

alter table migr_capitolo_eccezione
  add constraint XPKMIGR_CAPITOLO_ECC primary key (numero_capitolo,numero_articolo,numero_ueb,tipo_capitolo,eu,anno_esercizio,ente_proprietario_id)
  using index 
  tablespace &2;
  
-- Davide 30.03.2016 - aggiunta campi bilancio Previsione
alter table migr_capitolo_uscita add trasferimenti_comunitari varchar2(1) default null;
alter table migr_capitolo_uscita add funzioni_delegate varchar2(1) default null;
alter table migr_capitolo_entrata add trasferimenti_comunitari varchar2(1) default null;

-- DAVIDE 22.08.2016 - aggiunti campi per COTO, PVTO
alter table migr_capitolo_uscita  add  spesa_ricorrente	  varchar2(50)  null;
alter table migr_capitolo_entrata add  entrata_ricorrente varchar2(50)  null;

-- DAVIDE - 17.11.2016 - distinzione tra fondi spese correnti e conto capitale 
alter table migr_capitolo_eccezione modify classe_capitolo	varchar2(10);
