/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.bko_script_salva (
  p_path text,
  p_filename varchar,
  p_sw varchar,
  p_lotto varchar,
  out p_result bytea
)
RETURNS bytea AS
$body$
declare

result_to_ins bytea;
begin
result_to_ins:=bko_bytea_import(p_path);
insert into bko_script_db_files(script_file , script_file_name , lotto  , versione_sw_appartenenza) VALUES
  (result_to_ins, p_filename, p_lotto, p_sw); 
 p_result:=result_to_ins;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
