/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_create_indexes (
)
RETURNS TABLE (
  create_command varchar
) AS
$body$
DECLARE
fnc_rec record;
BEGIN

for fnc_rec in 
select i_command from bko_t_indexes_create_drop where i_operation='CREATE INDEX' order by i_order 
loop

create_command:=fnc_rec.i_command;
execute create_command;
return next;
end loop;
-- exception  --add exceptions
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
