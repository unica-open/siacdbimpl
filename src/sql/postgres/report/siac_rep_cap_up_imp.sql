/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_cap_up_imp (
  elem_id INTEGER,
  periodo_anno VARCHAR(4),
  tipo_imp VARCHAR,
  ente_proprietario INTEGER,
  utente VARCHAR,
  importo NUMERIC,
  tipo_capitolo VARCHAR
) 
WITH (oids = false);

CREATE INDEX siac_rep_cap_up_imp_idx ON siac.siac_rep_cap_up_imp
  USING btree (elem_id);