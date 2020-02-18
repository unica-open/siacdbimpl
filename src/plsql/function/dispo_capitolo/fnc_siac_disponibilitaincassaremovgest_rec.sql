/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaincassaremovgest_rec (
  movgest_ts_id_in varchar
)
RETURNS TABLE (
  val1 integer,
  val2 numeric
) AS
$body$
DECLARE

enteRec record;
RTN_MESSAGGIO varchar(1000):='';
sql_query varchar;


BEGIN
--sql_query:='SELECT movgest_ts_id, 1000 as val2
 --from siac_t_movgest_ts where movgest_ts_id in('||movgest_ts_id_in||')';


sql_query:='SELECT movgest_ts_id, fnc_siac_disponibilitaincassaremovgest(movgest_ts_id) as val2
 from siac_t_movgest_ts where movgest_ts_id in('||movgest_ts_id_in||')';

for enteRec in
EXECUTE sql_query
loop
val1:=enteRec.movgest_ts_id;
val2:=enteRec.val2;
RETURN NEXT;
--ente_prop_id:=0;
--entecode:='';
--ente_desc:='';
end loop;
raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
    RTN_MESSAGGIO:='altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;