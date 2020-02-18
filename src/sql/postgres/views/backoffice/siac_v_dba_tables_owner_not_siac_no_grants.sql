/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace view siac_v_dba_tables_owner_not_siac_no_grants as
select a.tablename, a.tableowner from pg_tables a where a.tableowner='siac_rw' and not exists (
select /*usename, relname as tabella,
       case relkind when 'r' then 'TABLE' when 'v' then 'VIEW' end as relation_type,
       priv*/
       1
from pg_class join pg_namespace on pg_namespace.oid = pg_class.relnamespace,
     pg_user,
     (values('SELECT', 1),('INSERT', 2),('UPDATE', 3),('DELETE', 4)) privs(priv, privorder)
where relkind in ('r', 'v')
      and has_table_privilege(pg_user.usesysid, pg_class.oid, priv)
      and not (nspname ~ '^pg_' or nspname = 'information_schema')
      and usename='siac'
      and relname=a.tablename)