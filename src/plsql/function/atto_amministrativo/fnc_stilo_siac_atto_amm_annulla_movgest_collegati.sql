/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_stilo_siac_atto_amm_annulla_movgest_collegati
(
  attoamm_id_in integer,
  login_operazione_in varchar
)
RETURNS boolean AS
$body$
DECLARE

test_data timestamp:=null;
codResult integer:=null;

login_oper VARCHAR:=null;
esito boolean:=true;

begin

test_data:=now();

login_oper:= login_operazione_in||' - '||'stilo_annulla_movgest_coll';

select 1 into codResult
from siac_r_movgest_ts_atto_amm ratto, siac_t_movgest_ts ts,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
where ratto.attoamm_id=attoamm_id_in
and   ts.movgest_ts_id=ratto.movgest_ts_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code not in ('A','N','D')
and   test_data between ratto.validita_inizio and coalesce(ratto.validita_fine,test_data)
and   test_data between rs.validita_inizio and coalesce(rs.validita_fine,test_data)
and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
and   rs.data_cancellazione is null
and   ts.data_cancellazione is null
and   ratto.data_cancellazione is null limit 1;
raise notice 'esiste mov. da annullare %',codResult;

if codResult is not null then
	codResult:=null;
	insert into siac_r_movgest_ts_stato
    (
    	movgest_ts_id,
        movgest_stato_id,
        login_operazione,
        validita_inizio,
        ente_proprietario_id
    )
    select ts.movgest_ts_id,
           statoA.movgest_stato_id,
           login_oper,
           clock_timestamp(),
           stato.ente_proprietario_id
    from siac_r_movgest_ts_atto_amm ratto, siac_t_movgest_ts ts,
	     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_stato statoA
	where ratto.attoamm_id=attoamm_id_in
	and   ts.movgest_ts_id=ratto.movgest_ts_id
	and   rs.movgest_ts_id=ts.movgest_ts_id
	and   stato.movgest_stato_id=rs.movgest_stato_id
	and   stato.movgest_stato_code not in ('A','N','D')
    and   statoA.ente_proprietario_id=stato.ente_proprietario_id
    and   statoA.movgest_stato_code='A'
	and   test_data between ratto.validita_inizio and coalesce(ratto.validita_fine,test_data)
	and   test_data between rs.validita_inizio and coalesce(rs.validita_fine,test_data)
	and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
	and   rs.data_cancellazione is null
	and   ts.data_cancellazione is null
	and   ratto.data_cancellazione is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;

    if codResult is not null then

      codResult:=null;
      update siac_r_movgest_ts_stato rs
      set    data_cancellazione=clock_timestamp(),
             validita_fine=clock_timestamp(),
             login_operazione=rs.login_operazione||' - '||login_oper
      from siac_r_movgest_ts_atto_amm ratto, siac_t_movgest_ts ts,
           siac_d_movgest_stato stato
      where ratto.attoamm_id=attoamm_id_in
      and   ts.movgest_ts_id=ratto.movgest_ts_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code not in ('A','N','D')
      and   test_data between ratto.validita_inizio and coalesce(ratto.validita_fine,test_data)
      and   test_data between rs.validita_inizio and coalesce(rs.validita_fine,test_data)
      and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
      and   rs.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   ratto.data_cancellazione is null;
      GET DIAGNOSTICS codResult = ROW_COUNT;

    end if;

end if;


return esito;

exception
     when others  THEN
         RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;