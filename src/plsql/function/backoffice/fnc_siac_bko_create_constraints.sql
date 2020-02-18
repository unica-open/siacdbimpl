/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_create_constraints (
)
RETURNS TABLE (
  create_command varchar
) AS
$body$
DECLARE
fnc_rec record;
BEGIN
for fnc_rec in 
select c_command from bko_t_constraints_create_drop where c_operation='ADD CONSTRAINT' order by c_order 
loop

create_command:= fnc_rec.c_command;
execute create_command;
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
