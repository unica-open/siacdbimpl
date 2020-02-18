/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_var_entrate (
  elem_id INTEGER,
  importo NUMERIC,
  tipologia VARCHAR,
  utente VARCHAR,
  ente_proprietario INTEGER,
  periodo_anno VARCHAR(4)
) 
WITH (oids = false);