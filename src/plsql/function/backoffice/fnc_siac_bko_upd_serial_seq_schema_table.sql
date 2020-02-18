/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_upd_serial_seq_schema_table (v_schema_in varchar,v_table_in varchar)
RETURNS TABLE (upd_command varchar) 
AS
$body$
DECLARE
fnc_rec record;
n_upd_serial_seq integer:=0;
schema_in information_schema.schemata.schema_name%type;
table_in varchar;
cmd text;
BEGIN

begin
select schema_name into strict schema_in from information_schema.schemata
where schema_name=v_schema_in;
EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION 'wrong schemaname'; 
end;


if v_table_in is not null then
begin
select tablename into strict table_in  from pg_tables 
where tablename=v_table_in;
EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION 'wrong tablename'; 
end;
end if;

cmd := 'SELECT DISTINCT ''select setval(''::text || quote_literal(a.relname::text) || '',coalesce(max(''::text || quote_ident(c.attname::text) || ''),0)+1,false) from ''::text || quote_ident(d.relname::text) || '';''::text AS upd_serial_seq
FROM pg_class a, pg_depend b, pg_attribute c, pg_class d, pg_tables e, information_schema.sequences f
WHERE a.relkind = ''S''::"char" AND a.oid = b.objid AND b.refobjid = d.oid AND a.relname=f.sequence_name and
    b.refobjid = c.attrelid AND b.refobjsubid = c.attnum AND d.relname = e.tablename AND e.schemaname = '''||v_schema_in::name;

if v_table_in is not null then    
cmd:= cmd||''' and e.tablename='''||v_table_in||''''; 
else
cmd:= cmd||'''';
end if;    

for fnc_rec in EXECUTE cmd
loop
  upd_command:= fnc_rec.upd_serial_seq;
  n_upd_serial_seq:=n_upd_serial_seq+1;
  execute upd_command;
  return next;
end loop; 

if n_upd_serial_seq=0 then
	raise exception 'No sequence found to update';
end if;
return; 

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
;