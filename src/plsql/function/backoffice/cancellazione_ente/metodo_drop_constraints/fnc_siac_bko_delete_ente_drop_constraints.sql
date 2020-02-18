/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_delete_ente_drop_constraints (
  ente_id integer
)
RETURNS TABLE (
  create_command varchar
) AS
$body$
DECLARE
fnc_rec record;
BEGIN

--begin

delete from dba_t_delete_ente;


INSERT INTO 
  siac.dba_t_delete_ente
(
  d_operation,
  d_command,
  d_table_name
)
select 'DELETE', 'delete from '||a.tablename||' where ente_proprietario_id='||
ente_id||';', a.tablename
 from information_schema.columns b, pg_tables a where b.table_name=a.tablename and
b.table_schema=a.schemaname
and b.column_name='ente_proprietario_id'
and a.schemaname='siac'
order by a.tablename;

perform * from siac.fnc_dba_drop_constraints_fk();

for fnc_rec in 
select d_command from dba_t_delete_ente where d_operation='DELETE' order by d_order 
loop

create_command:= fnc_rec.d_command;
execute create_command;
return next;
end loop;



--commit;

/*exception when others THEN
		raise notice 'ERRORE DB';
return;
end;*/

--fin a correzione baco
delete from siac_t_parametro_azione_richiesta a 
where not exists (select 1 from siac_t_azione_richiesta b where b.azione_richiesta_id=a.azione_richiesta_id);


perform * from siac.fnc_dba_create_constraints();

--exception

/*exception when others THEN
		raise notice 'ERRORE DB';
return;*/

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;