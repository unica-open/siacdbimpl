/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_cap_ep_imp (
  elem_id INTEGER,
  periodo_anno VARCHAR(4),
  tipo_imp VARCHAR,
  ente_proprietario INTEGER,
  utente VARCHAR,
  importo NUMERIC
) 
WITH (oids = false);

CREATE INDEX siac_rep_cap_ep_imp_idx ON siac.siac_rep_cap_ep_imp
  USING btree (elem_id);