/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_impegni_residui (
  elem_id INTEGER,
  periodo_anno VARCHAR(4),
  ente_proprietario INTEGER,
  utente VARCHAR,
  importo NUMERIC
) 
WITH (oids = false);