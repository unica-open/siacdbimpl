/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace VIEW siac_v_bko_view_locks_activity as
select 
pl.locktype,
pl.database,
pl.relation,
pl.page,
pl.tuple,
pl.virtualxid,
pl.transactionid,
pl.classid,
pl.objid,
pl.objsubid,
pl.virtualtransaction,
pl.mode,
pl.granted,
pl.fastpath,
psa.* from (
SELECT /*locktype, relation::regclass, mode, transactionid AS tid,
virtualtransaction AS vtid, pid, granted*/
l.*
FROM pg_catalog.pg_locks l LEFT JOIN pg_catalog.pg_database db
ON db.oid = l.database WHERE (db.datname = 'TSTBIL1' OR db.datname IS NULL)
AND NOT pid = pg_backend_pid()
) pl LEFT JOIN pg_stat_activity psa
    ON pl.pid = psa.pid;
;