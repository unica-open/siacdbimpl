/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_prog_cronop (
  id_programma INTEGER,
  id_cronoprogramma INTEGER,
  anno_del_bilancio VARCHAR(4),
  utente VARCHAR
) 
WITH (oids = false);