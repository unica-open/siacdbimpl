/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.dba_t_delete_ente (
  d_order SERIAL,
  d_operation VARCHAR,
  d_command VARCHAR,
  d_table_name VARCHAR
) 
WITH (oids = false);
