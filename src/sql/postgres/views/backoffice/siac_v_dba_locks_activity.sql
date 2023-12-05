/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dba_locks_activity AS
SELECT pl.*, psa.*
FROM (
  SELECT l.*
  FROM pg_locks l
  LEFT JOIN pg_database db ON db.oid = l.database
  WHERE (db.datname = current_database()::name OR db.datname IS NULL)
  AND NOT l.pid = pg_backend_pid()
) pl
LEFT JOIN pg_stat_activity psa ON pl.pid = psa.pid;