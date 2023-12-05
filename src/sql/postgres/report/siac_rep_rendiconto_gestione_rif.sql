/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_rendiconto_gestione_rif (
  report VARCHAR(200),
  codice_report VARCHAR(200),
  codice_bilancio VARCHAR(200),
  rif_art_2424_cc VARCHAR(50),
  rif_dm_26_4_95 VARCHAR(50),
  classif_id INTEGER
) 
WITH (oids = false);