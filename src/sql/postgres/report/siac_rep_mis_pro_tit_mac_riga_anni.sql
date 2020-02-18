/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_mis_pro_tit_mac_riga_anni (
  missione_tipo_desc VARCHAR(500),
  missione_id INTEGER,
  missione_code VARCHAR(200),
  missione_desc VARCHAR(500),
  missione_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  missione_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  programma_tipo_desc VARCHAR(500),
  programma_id INTEGER,
  programma_code VARCHAR(200),
  programma_desc VARCHAR(500),
  programma_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  programma_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  titusc_tipo_desc VARCHAR(500),
  titusc_id INTEGER,
  titusc_code VARCHAR(200),
  titusc_desc VARCHAR(500),
  titusc_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  titusc_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  macroag_tipo_desc VARCHAR(500),
  macroag_id INTEGER,
  macroag_code VARCHAR(200),
  macroag_desc VARCHAR(500),
  macroag_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  macroag_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);