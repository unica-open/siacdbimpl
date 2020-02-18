/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_accertamenti_completa (
  elem_id INTEGER,
  accertamenti NUMERIC,
  stato VARCHAR,
  anno_competenza INTEGER,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);