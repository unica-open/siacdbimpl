/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_configura_report_anno_all_enti (
  p_anno_bil varchar
)
RETURNS void AS
$body$
DECLARE

rec record;

begin

for rec in 
select * from
siac_t_ente_proprietario
loop

perform fnc_siac_bko_configura_report_ente(rec.ente_proprietario_id,p_anno_bil);

end loop;

exception
when no_data_found THEN
raise notice 'nessun dato trovato';
when others  THEN
 raise notice 'errore : %  - stato: % ', SQLERRM, SQLSTATE;
--raise notice 'altro errore';
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;