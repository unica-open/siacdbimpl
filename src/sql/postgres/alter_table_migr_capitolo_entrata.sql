/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE migr_capitolo_entrata
  ALTER COLUMN numero_capitolo TYPE INTEGER;

-- Davide - 30.03.016  
alter table migr_capitolo_entrata add trasferimenti_comunitari varchar(1) default null;

-- DAVIDE - 22.08.2016 - aggiunti per COTO, PVTO
alter table migr_capitolo_entrata add entrata_ricorrente varchar(50);
