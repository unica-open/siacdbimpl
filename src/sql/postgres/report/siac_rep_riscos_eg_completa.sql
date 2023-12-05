/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_riscos_eg_completa (
  elem_id INTEGER,
  riscossioni NUMERIC,
  stato VARCHAR,
  anno_competenza INTEGER,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);