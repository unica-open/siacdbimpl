/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_drop_indexes (
)
RETURNS TABLE (
  drop_command varchar
) AS
$body$
DECLARE
fnc_rec record;
BEGIN

delete from bko_t_indexes_create_drop ;

insert into bko_t_indexes_create_drop  (i_operation,i_command, i_name,i_table_name)
select 'CREATE INDEX', replace(ii.indexdef,' '||class_table.relname||' ', ' '||ii.schemaname||'.'||class_table.relname||' '), class_index.relname,class_table.relname
from pg_index i, pg_class class_index,pg_class class_table, pg_indexes ii
where class_index.oid=i.indexrelid and class_table.oid=i.indrelid and ii.indexname=class_index.relname 
and i.indisprimary is FALSE  --indexes <> PK indexes
--and class_table.relname like 'a%';  --uncomment to add conditions on tables names
and ii.schemaname='siac' -- uncomment to filter schema
;

insert into bko_t_indexes_create_drop (i_operation,i_command, i_name,i_table_name)
select 'DROP INDEX','DROP INDEX '||class_index.relname ,class_index.relname,class_table.relname
from pg_index i, pg_class class_index,pg_class class_table, pg_indexes ii
where class_index.oid=i.indexrelid and class_table.oid=i.indrelid and ii.indexname=class_index.relname 
and i.indisprimary is FALSE  --indexes <> PK indexes
--and class_table.relname like 'a%';  --uncomment to add conditions on tables names
and ii.schemaname='siac' -- uncomment to filter schema
;

for fnc_rec in 
select i_command from bko_t_indexes_create_drop where i_operation='DROP INDEX' order by i_order 
loop
drop_command:= fnc_rec.i_command;
execute drop_command;
return next; --displays the executed code
end loop;

-- exception  --add exceptions
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
