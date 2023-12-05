/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.bko_t_report_importi (
  rep_codice VARCHAR(200),
  rep_desc VARCHAR(500),
  repimp_codice VARCHAR(200),
  repimp_desc VARCHAR(500),
  repimp_importo INTEGER,
  repimp_modificabile CHAR(1),
  repimp_progr_riga INTEGER
) 
WITH (oids = false);