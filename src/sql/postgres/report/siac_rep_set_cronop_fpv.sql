/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_set_cronop_fpv (
  set_code VARCHAR,
  descr_set VARCHAR,
  set_id INTEGER,
  cronop_id INTEGER,
  programma_id INTEGER,
  id_r_set_cronop INTEGER,
  gestione_flag BOOLEAN,
  programma_codice VARCHAR,
  programma_descrizione VARCHAR,
  cronop_codice VARCHAR,
  cronop_descrizione VARCHAR,
  ente INTEGER,
  utente VARCHAR
) 
WITH (oids = false);