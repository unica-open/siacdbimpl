/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_tables_fk_dependent (
  schema_name varchar,
  tab_name varchar
)
RETURNS TABLE (
  tab_name_out varchar
) AS
$body$
DECLARE
rec record;
BEGIN

for rec in 
 SELECT tc.table_name AS table_fk
  FROM information_schema.constraint_column_usage cu,
       pg_class c,
       pg_attribute a,
       pg_class c2,
       pg_attribute a2,
       information_schema.table_constraints tc,
       information_schema.referential_constraints rc,
       information_schema.table_constraints tc2,
       information_schema.constraint_column_usage cu2
  WHERE c.relname = tc.table_name::name AND
        a.attname = cu.column_name::name AND
        tc.constraint_name::text = cu.constraint_name::text AND
        a.attnum > 0 AND
        a.attrelid = c.oid AND
        c2.relname = tc2.table_name::name AND
        a2.attname = cu2.column_name::name AND
        tc2.constraint_name::text = cu2.constraint_name::text AND
        a2.attnum > 0 AND
        a2.attrelid = c2.oid AND
        rc.constraint_name::text = tc.constraint_name::text AND
        tc2.constraint_name::text = rc.unique_constraint_name::text AND
        tc.table_schema::text = schema_name::text AND
        tc.constraint_type::text = 'FOREIGN KEY'::text
        and tc2.table_name=tab_name::text
        order by 1
        loop
        
 tab_name_out:=rec.table_fk;      
return next;

        end loop;      

exception
when no_data_found THEN
raise notice 'nessun dato trovato';
when others  THEN
 raise notice 'errore : %  - stato: % ', SQLERRM, SQLSTATE;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;