/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_impegni_riga (
  elem_id INTEGER,
  impegnato_anno NUMERIC,
  impegnato_anno1 NUMERIC,
  impegnato_anno2 NUMERIC,
  ente_proprietario INTEGER,
  utente VARCHAR
) 
WITH (oids = false);