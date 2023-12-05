/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_dba_drop_constraints_fk (
)
RETURNS TABLE (
  drop_command varchar
) AS
$body$
DECLARE
fnc_rec record;
BEGIN

delete from dba_constraints_create_drop;

insert into dba_constraints_create_drop (c_operation,c_command,c_type,c_name,c_table_name)
SELECT 
'ADD CONSTRAINT',
'ALTER TABLE '||nspname||'.'||relname||' ADD CONSTRAINT "'||conname||'"  '||
   pg_get_constraintdef(c.oid)||';',
   c.contype,c.conname,cl.relname
 FROM pg_constraint c
 , pg_class cl, pg_namespace n
 where c.conrelid=cl.oid
 and  n.oid=cl.relnamespace
 and c.contype in ('f') -- fk pk
 ORDER BY CASE WHEN c.contype='p' THEN 0 ELSE 1 END,c.contype DESC,n.nspname,cl.relname,c.conname ;
 
 insert into dba_constraints_create_drop (c_operation,c_command,c_type,c_name,c_table_name)
  SELECT 
'DROP CONSTRAINT',
'ALTER TABLE '||n.nspname||'.'||cl.relname||' DROP CONSTRAINT "'||c.conname||'";',
c.contype,c.conname,cl.relname
 FROM pg_constraint c, pg_class cl, pg_namespace n  where  c.conrelid=cl.oid 
 and n.oid=cl.relnamespace 
 and c.contype in ('f') -- fk pk
 ORDER BY CASE WHEN c.contype='f' THEN 0 ELSE 1 END,c.contype,n.nspname,cl.relname,c.conname;
 
for fnc_rec in 
select c_command from dba_constraints_create_drop where c_operation='DROP CONSTRAINT' order by c_order 
loop
  drop_command:= fnc_rec.c_command;
  execute drop_command;
  return next;
end loop;

--exception
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;