/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.bko_t_versione_software_db (
  vs_id SERIAL,
  vs_db VARCHAR(200),
  vs_versione_software VARCHAR(200),
  vs_data_inizio TIMESTAMP WITHOUT TIME ZONE,
  vs_data_fine TIMESTAMP WITHOUT TIME ZONE,
  CONSTRAINT pk_bko_t_versione_software_db PRIMARY KEY(vs_id)
) 
WITH (oids = false);
