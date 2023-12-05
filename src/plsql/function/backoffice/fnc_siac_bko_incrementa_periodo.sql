/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_incrementa_periodo (
  ente_proprietario integer
)
RETURNS void AS
$body$
DECLARE

max_anno integer;
delta_anni integer;
anno_aggiornamento integer;
risultato varchar;
anno_aggiornamento_v varchar;

begin 

delta_anni:=20;


select max(anno::integer) into max_anno from siac_t_periodo where
ente_proprietario_id =ente_proprietario;

anno_aggiornamento:=max_anno+1;

for anno_aggiornamento in max_anno+1 .. max_anno+delta_anni loop

anno_aggiornamento_v:=anno_aggiornamento::varchar;

INSERT INTO 
  siac.siac_t_periodo
(
  periodo_code,
  periodo_desc,
  data_inizio,
  data_fine,
  validita_inizio,
  validita_fine,
  periodo_tipo_id,
  anno,
  ente_proprietario_id,
  login_operazione
)
select 
substr(periodo_code,1,length(periodo_code)-4)||anno_aggiornamento_v,
substr(periodo_desc,1,length(periodo_code)-4)||anno_aggiornamento_v,
to_timestamp(substr(to_char(data_inizio,'dd/mm/yyyy'),1,length(to_char(data_inizio,'dd/mm/yyyy'))-4)||anno_aggiornamento_v,'dd/mm/yyyy'),
to_timestamp(substr(to_char(data_fine,'dd/mm/yyyy'),1,length(to_char(data_fine,'dd/mm/yyyy'))-4)||anno_aggiornamento_v,'dd/mm/yyyy'),validita_inizio,
validita_fine,
periodo_tipo_id,
anno_aggiornamento_v,
ente_proprietario_id,
'admin aggiornamento anno'
from siac_t_periodo where anno=max_anno::varchar and 
ente_proprietario_id=ente_proprietario;

anno_aggiornamento:=anno_aggiornamento+1;

end loop;

update siac_t_periodo set data_fine = subquery.data_fine_new from (
 select 
a.periodo_id,
(a.data_inizio + interval '1 month') - interval '1 day' data_fine_new
 From siac_T_periodo a, siac_d_periodo_tipo
b where
b.periodo_tipo_id=a.periodo_tipo_id
and a.data_cancellazione is null 
and b.periodo_tipo_code like 'M%' and 
now()  BETWEEN a.validita_inizio and coalesce (a.validita_fine, now())
and a.ente_proprietario_id=ente_proprietario
and 
 a.data_fine <> (a.data_inizio + interval '1 month') - interval '1 day'
 ) as subquery
 where 
 subquery.periodo_id=siac_t_periodo.periodo_id;

exception
    when no_data_found THEN
        raise notice 'nessun valore trovato' ;
        return;
        when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',' altro errore',SQLSTATE,SQLERRM;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;