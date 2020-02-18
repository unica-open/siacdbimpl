/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.bko_t_indexes_create_drop (
  i_order SERIAL,
  i_operation VARCHAR,
  i_command VARCHAR,
  i_name VARCHAR,
  i_table_name VARCHAR
) 
WITH (oids = false);
