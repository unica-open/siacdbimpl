/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.dba_constraints_create_drop (
  c_order SERIAL,
  c_operation VARCHAR,
  c_command VARCHAR,
  c_type VARCHAR,
  c_name VARCHAR,
  c_table_name VARCHAR
) 
WITH (oids = false);
