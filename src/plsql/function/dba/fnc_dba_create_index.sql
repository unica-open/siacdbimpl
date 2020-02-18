/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_dba_create_index (
  table_in text,
  index_in text,
  index_columns_in text,
  index_where_def_in text,
  index_unique_in boolean
)
RETURNS text AS
$body$
declare

query_var text;

query_to_exe text;
esito text;
begin

 query_var:= 'CREATE '
               ||(case when index_unique_in = true then 'UNIQUE '
                  else ' ' end)
               ||'INDEX '
               ||index_in|| ' ON ' || table_in || ' USING BTREE ( '||index_columns_in||' )'
               ||(case when coalesce(index_where_def_in,'')!='' then ' WHERE ( '||index_where_def_in||' );'
                  else ';' end);
-- raise notice 'query_var=%',query_var;

 select  query_var into query_to_exe
 where
 not exists
 (
  SELECT 1
  FROM pg_class pg
  WHERE pg.relname=index_in
  and   pg.relkind='i'
 );

 if query_to_exe is not null then
 	esito:='indice creato';
  	execute query_to_exe;

 else
	esito:='indice '||index_in||' già presente';
 end if;

 return esito;

exception
    when RAISE_EXCEPTION THEN
    esito:=substring(upper(SQLERRM) from 1 for 2500);
        return esito;
	when others  THEN
	esito:=' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
        return esito;


end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;