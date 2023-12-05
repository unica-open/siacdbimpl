/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_atto_amm_aggiorna_parere_fin(integer, boolean, varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_atto_amm_aggiorna_parere_fin (
  attoamm_id_in integer,
  parere_finanziario_in boolean,
  login_operazione_in varchar
)
RETURNS text
AS $function$

DECLARE

login_oper varchar;
valid_fine timestamp;
valid_inizio timestamp;
data_oper timestamp;

begin

data_oper:=now();
valid_fine:=now();
valid_inizio:=now()+ interval '1 second';

update siac_t_movgest 
	set parere_finanziario=parere_finanziario_in, parere_finanziario_data_modifica=valid_inizio, 
	parere_finanziario_login_operazione=login_operazione_in
    where  movgest_id in ( 
    select distinct mg.movgest_id
    from siac_t_atto_amm aa,
    siac_r_movgest_ts_atto_amm mga,
    siac_t_movgest_ts ts, siac_t_movgest mg, siac_r_movgest_ts_stato tss, siac_d_movgest_stato mgs,
    siac_t_bil b, siac_d_fase_operativa fo, siac_r_bil_fase_operativa bfo, siac_d_movgest_tipo mt, siac_d_movgest_ts_tipo tt
    where mga.attoamm_id=aa.attoamm_id
    and ts.movgest_ts_id=mga.movgest_ts_id
    and mg.movgest_id=ts.movgest_id
    and tss.movgest_ts_id=ts.movgest_ts_id
    and mgs.movgest_stato_id=tss.movgest_stato_id
    and mgs.movgest_stato_code<>'A'
    and b.bil_id=mg.bil_id
    and bfo.fase_operativa_id=fo.fase_operativa_id
    and bfo.bil_id=b.bil_id
    and aa.attoamm_id=attoamm_id_in
    and mt.movgest_tipo_id=mg.movgest_tipo_id
    and tt.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and now() between tss.validita_inizio and COALESCE(tss.validita_fine,now())
    and aa.data_cancellazione is null
    and mga.data_cancellazione is null
    and ts.data_cancellazione is null
    and mg.data_cancellazione is null
    and tss.data_cancellazione is null
    and mgs.data_cancellazione is null
    and b.data_cancellazione is null
    and fo.data_cancellazione is null
    and bfo.data_cancellazione is null
    and mt.data_cancellazione is null
    and tt.data_cancellazione is null
    );
 
    return '';
  
exception
     when others  THEN
         RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
        return 'ERR: ' || SQLERRM;
        --return esito;
END;
$function$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
;