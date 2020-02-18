/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_dba_add_column_params (
  table_in text,
  field_in text,
  data_type_in text
)
RETURNS text AS
$body$
declare
 
query_in text;
esito text;
begin
 
 select  'ALTER TABLE ' ||table_in|| ' ADD COLUMN ' || field_in || ' ' || data_type_in ||';' into query_in
 where 
 not exists 
 (
 SELECT 1 
 FROM information_schema.columns
 WHERE table_name = table_in
 AND column_name = field_in
 );
 if query_in is not null then
 esito:='colonna creata';
 	execute query_in;
else 
esito:='colonna già presente';
 end if;
 
 return esito;

end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;