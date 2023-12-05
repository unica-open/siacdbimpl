/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace view siac_v_bko_create_index_fk_script as
  with aa AS(  
       SELECT   distinct
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM
    information_schema.table_constraints tc,
    information_schema.key_column_usage kcu, 
    information_schema.constraint_column_usage ccu ,
    pg_tables pt
WHERE 
tc.constraint_name = kcu.constraint_name
and 
 ccu.constraint_name = tc.constraint_name
 and 
 pt.tablename=tc.table_name
 and constraint_type = 'FOREIGN KEY'
 and pt.schemaname ='siac'
 and (pt.tablename like 'siac_d_%'
or pt.tablename like 'siac_r_%'
or pt.tablename like 'siac_t_%')
)
  select 
'CREATE INDEX '||aa.table_name||aa.column_name||'idx on '||aa.table_name||' using btree ("'||aa.column_name||'");'
from aa
order by aa.table_name;