/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_tit_mac_riga (
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