/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_dba_add_check_constraint (
  table_in text,
  constraint_in text,
  check_definition text
)
RETURNS text AS
$body$
declare
 
query_in text;
esito text;
begin
 
 select  'ALTER TABLE ' ||table_in|| ' ADD CONSTRAINT ' || constraint_in || ' CHECK (' || check_definition ||');' into query_in
 where 
 not exists 
 (
 SELECT 1
FROM information_schema.check_constraints 
WHERE constraint_name=constraint_in
 );

 if query_in is not null then
 	esito:='check contraint creato';
  	execute query_in;
    
 else 
	esito:='check contraint già presente';
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