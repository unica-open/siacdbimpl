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
codEsito varchar(10):=null;
mod_rec record;
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

-- 17.04.2020 Sofia jira siac-7491
codResult :=null;
select 1 into codResult
from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta,
     siac_t_movgest_ts_det_mod dmod,siac_t_movgest_ts ts,siac_t_movgest mov,
     siac_r_bil_fase_operativa rfase,siac_d_fase_operativa fase
where ra.attoamm_id=attoamm_id_in
and   st.mod_id=ra.mod_id
and   sta.mod_stato_id=st.mod_stato_id
and   sta.mod_stato_code<>'A'
and   dmod.mod_stato_r_id=st.mod_stato_r_id
and   ts.movgest_ts_id=dmod.movgest_ts_id
and   mov.movgest_id=ts.movgest_id
and   rfase.bil_id=mov.bil_Id
and   fase.fase_operativa_id=rfase.fase_operativa_id
and   fase.fase_operativa_code not in ('O','C')
and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
and   test_data between dmod.validita_inizio and coalesce(dmod.validita_fine,test_data)
and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
and   test_data between mov.validita_inizio and coalesce(mov.validita_fine,test_data)
and   test_data between rfase.validita_inizio and coalesce(rfase.validita_fine,test_data)
and   st.data_cancellazione is null
and   ra.data_cancellazione is null
and   dmod.data_cancellazione is null
and   ts.data_cancellazione is null
and   mov.data_cancellazione is null
and   rfase.data_cancellazione is null
limit 1;
raise notice 'esiste mov. modifica da annullare %',codResult;
if codResult is not null then
    codResult:=null;
	update siac_t_movgest_Ts_Det ts_det
    set    movgest_ts_Det_importo=ts_Det.movgest_ts_det_importo-dmod.movgest_ts_det_importo,
           data_modifica=clock_timestamp(),
           login_operazione=ts_det.login_operazione||' - '||login_oper
    from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta,
         siac_t_movgest_ts_det_mod dmod,siac_t_movgest_ts ts,siac_t_movgest mov,
         siac_r_bil_fase_operativa rfase,siac_d_fase_operativa fase
    where ra.attoamm_id=attoamm_id_in
    and   st.mod_id=ra.mod_id
    and   sta.mod_stato_id=st.mod_stato_id
    and   sta.mod_stato_code<>'A'
    and   dmod.mod_stato_r_id=st.mod_stato_r_id
    and   ts.movgest_ts_id=dmod.movgest_ts_id
    and   mov.movgest_id=ts.movgest_id
    and   rfase.bil_id=mov.bil_Id
    and   fase.fase_operativa_id=rfase.fase_operativa_id
    and   fase.fase_operativa_code not in ('O','C')
    and   ts_det.movgest_ts_id=ts.movgest_ts_id
    and   ts_det.movgest_ts_det_tipo_id=dmod.movgest_ts_Det_tipo_id
    and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   test_data between dmod.validita_inizio and coalesce(dmod.validita_fine,test_data)
    and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
    and   test_data between ts_det.validita_inizio and coalesce(ts_det.validita_fine,test_data)
    and   test_data between mov.validita_inizio and coalesce(mov.validita_fine,test_data)
    and   test_data between rfase.validita_inizio and coalesce(rfase.validita_fine,test_data)
    and   st.data_cancellazione is null
    and   ra.data_cancellazione is null
    and   dmod.data_cancellazione is null
    and   ts.data_cancellazione is null
    and   ts_det.data_cancellazione is null
    and   mov.data_cancellazione is null
    and   rfase.data_cancellazione is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice 'esiste mov. modifica da annullare - det importi aggiornati= %',codResult;

    -- adeguamento vincoli
    /*select
       fnc_siac_riaccertamento
       (
        ra.mod_id,
        login_oper,
        'ANNULLA'
       ) into codEsito
    from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta
    where ra.attoamm_id=attoamm_id_in
    and   st.mod_id=ra.mod_id
    and   sta.mod_stato_id=st.mod_stato_id
    and   sta.mod_stato_code<>'A'
    and   exists
    (
    select 1
    from siac_t_movgest_ts_det_mod dmod,siac_t_movgest_ts ts,siac_t_movgest mov,
         siac_r_bil_fase_operativa rfase,siac_d_fase_operativa fase
    where dmod.mod_stato_r_id=st.mod_stato_r_id
    and   ts.movgest_ts_id=dmod.movgest_ts_id
    and   mov.movgest_id=ts.movgest_id
    and   rfase.bil_id=mov.bil_Id
    and   fase.fase_operativa_id=rfase.fase_operativa_id
    and   fase.fase_operativa_code not in ('O','C')
    and   test_data between dmod.validita_inizio and coalesce(dmod.validita_fine,test_data)
    and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
    and   test_data between mov.validita_inizio and coalesce(mov.validita_fine,test_data)
    and   test_data between rfase.validita_inizio and coalesce(rfase.validita_fine,test_data)
    and   dmod.data_cancellazione is null
    and   ts.data_cancellazione is null
    and   mov.data_cancellazione is null
    and   rfase.data_cancellazione is null
    )
    and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   st.data_cancellazione is null
    and   ra.data_cancellazione is null;*/

    raise notice 'esiste mov. modifica da annullare - esec fnc_siac_riaccertamento - inizio ';
    for mod_rec in
    (select ra.mod_id
    from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta
    where ra.attoamm_id=attoamm_id_in
    and   st.mod_id=ra.mod_id
    and   sta.mod_stato_id=st.mod_stato_id
    and   sta.mod_stato_code<>'A'
    and   exists
    (
    select 1
    from siac_t_movgest_ts_det_mod dmod,siac_t_movgest_ts ts,siac_t_movgest mov,
         siac_r_bil_fase_operativa rfase,siac_d_fase_operativa fase
    where dmod.mod_stato_r_id=st.mod_stato_r_id
    and   ts.movgest_ts_id=dmod.movgest_ts_id
    and   mov.movgest_id=ts.movgest_id
    and   rfase.bil_id=mov.bil_Id
    and   fase.fase_operativa_id=rfase.fase_operativa_id
    and   fase.fase_operativa_code not in ('O','C')
    and   test_data between dmod.validita_inizio and coalesce(dmod.validita_fine,test_data)
    and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
    and   test_data between mov.validita_inizio and coalesce(mov.validita_fine,test_data)
    and   test_data between rfase.validita_inizio and coalesce(rfase.validita_fine,test_data)
    and   dmod.data_cancellazione is null
    and   ts.data_cancellazione is null
    and   mov.data_cancellazione is null
    and   rfase.data_cancellazione is null
    )
    and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   st.data_cancellazione is null
    and   ra.data_cancellazione is null )
    loop
       codEsito:=null;
       select
       fnc_siac_riaccertamento
       (
        mod_rec.mod_id,
        login_oper,
        'ANNULLA'
       ) into codEsito;
       raise notice 'esiste mov. modifica da annullare - esec fnc_siac_riaccertamento codEsito=%',codEsito;
   end loop;
   raise notice 'esiste mov. modifica da annullare - esec fnc_siac_riaccertamento - fine ';


    -- modifica dello stato delle modifiche
    codResult:=null;
	update siac_r_modifica_stato st
    set    mod_stato_id=statoA.mod_stato_id,
           data_modifica=clock_timestamp(),
           login_operazione=st.login_operazione||' - '||login_oper
    from siac_t_modifica  ra,  siac_d_modifica_stato sta,
         siac_t_movgest_ts_det_mod dmod,siac_t_movgest_ts ts,siac_t_movgest mov,
         siac_r_bil_fase_operativa rfase,siac_d_fase_operativa fase,
         siac_d_modifica_stato statoA
    where ra.attoamm_id=attoamm_id_in
    and   st.mod_id=ra.mod_id
    and   sta.mod_stato_id=st.mod_stato_id
    and   sta.mod_stato_code<>'A'
    and   dmod.mod_stato_r_id=st.mod_stato_r_id
    and   ts.movgest_ts_id=dmod.movgest_ts_id
    and   mov.movgest_id=ts.movgest_id
    and   rfase.bil_id=mov.bil_Id
    and   fase.fase_operativa_id=rfase.fase_operativa_id
    and   fase.fase_operativa_code not in ('O','C')
    and   statoA.ente_proprietario_id=sta.ente_proprietario_id
    and   statoA.mod_stato_Code='A'
    and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   test_data between dmod.validita_inizio and coalesce(dmod.validita_fine,test_data)
    and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
    and   test_data between mov.validita_inizio and coalesce(mov.validita_fine,test_data)
    and   test_data between rfase.validita_inizio and coalesce(rfase.validita_fine,test_data)
    and   st.data_cancellazione is null
    and   ra.data_cancellazione is null
    and   dmod.data_cancellazione is null
    and   ts.data_cancellazione is null
    and   mov.data_cancellazione is null
    and   rfase.data_cancellazione is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice 'esiste mov. modifica da annullare - mod stati aggiornati= %',codResult;
end if;
-- 17.04.2020 Sofia jira siac-7491


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