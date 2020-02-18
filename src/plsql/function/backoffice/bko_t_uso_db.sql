/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.bko_t_uso_db (
  u_id SERIAL,
  u_db VARCHAR(200),
  u_db_uso VARCHAR(200),
  CONSTRAINT pk_bko_t_uso_db PRIMARY KEY(u_id)
) 
WITH (oids = false);
