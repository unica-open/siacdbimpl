/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_mis_pro_tit_mac_riga (
  missione_tipo_desc VARCHAR(500),
  missione_id INTEGER,
  missione_code VARCHAR(200),
  missione_desc VARCHAR(500),
  programma_tipo_desc VARCHAR(500),
  programma_id INTEGER,
  programma_code VARCHAR(200),
  programma_desc VARCHAR(500),
  titusc_tipo_desc VARCHAR(500),
  titusc_id INTEGER,
  titusc_code VARCHAR(200),
  titusc_desc VARCHAR(500),
  macroag_tipo_desc VARCHAR(500),
  macroag_id INTEGER,
  macroag_code VARCHAR(200),
  macroag_desc VARCHAR(500),
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);