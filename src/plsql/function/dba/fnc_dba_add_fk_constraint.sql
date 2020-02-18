/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_dba_add_fk_constraint (
  table_in text,
  constraint_in text,
  column_in text,
  table_ref text,
  column_ref text
)
RETURNS text AS
$body$
declare

query_in text;
esito text;
begin

 select  'ALTER TABLE ' || table_in || ' ADD CONSTRAINT ' || constraint_in || ' FOREIGN KEY (' || column_in ||') ' ||
		 ' REFERENCES ' || table_ref || '(' || column_ref || ') ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE'
		 into query_in
 where
 not exists
 (
 SELECT 1
	FROM information_schema.table_constraints tc
	WHERE tc.constraint_schema='siac'
	AND tc.table_schema='siac'
	AND tc.constraint_type='FOREIGN KEY'
	AND tc.table_name=table_in
	AND tc.constraint_name=constraint_in
 );

 if query_in is not null then
 	esito:='fk constraint creato';
  	execute query_in;

 else
	esito:='fk constraint già presente';
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