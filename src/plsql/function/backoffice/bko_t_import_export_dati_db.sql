/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.bko_t_import_export_dati_db (
  ie_id SERIAL,
  ie_db_origine VARCHAR(200),
  ie_db_destinazione VARCHAR(200),
  ie_data_export TIMESTAMP WITHOUT TIME ZONE,
  ie_data_import TIMESTAMP WITHOUT TIME ZONE,
  ie_struttura BOOLEAN DEFAULT true,
  ie_dati BOOLEAN DEFAULT true,
  CONSTRAINT pk_bko_t_import_export_dati_db PRIMARY KEY(ie_id)
) 
WITH (oids = false);
