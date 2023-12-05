/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS siac.fnc_siac_importo_max_coll_spesa_collegata(p_det_mod_id integer, p_importo_residuo numeric);
DROP FUNCTION IF EXISTS siac.fnc_siac_importo_max_coll_spesa_collegata(p_det_mod_id integer,  p_movgest_id integer, p_importo_residuo numeric);

CREATE OR REPLACE FUNCTION siac.fnc_siac_importo_max_coll_spesa_collegata(p_det_mod_id integer, p_movgest_id integer, p_importo_residuo numeric)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_importo_vincolo numeric:= null;
    v_importo_residuo numeric:= null;
    v_importo_massimo_collegabile numeric:=null;
   	v_messaggiorisultato varchar;
begin
	
	v_importo_residuo := p_importo_residuo;
	
	--calcolo l'importo del vincolo
	select ABS(srmt.movgest_ts_importo) 
	from siac_r_movgest_ts srmt 
	join siac_t_movgest_ts stmt on srmt.movgest_ts_b_id = stmt.movgest_ts_id
	--SIAC-8304
	join siac_t_movgest_ts tmta on tmta.movgest_ts_id = srmt.movgest_ts_a_id
	join siac_d_movgest_ts_tipo tipoa on tipoa.movgest_ts_tipo_id = tmta.movgest_ts_tipo_id
	join siac_t_movgest_ts_det_mod stmtdm on stmt.movgest_ts_id = stmtdm.movgest_ts_id 
	join siac_r_modifica_stato srms on stmtdm.mod_stato_r_id = srms.mod_stato_r_id
	join siac_t_modifica stm on stm.mod_id = srms.mod_id
	where stm.mod_id = p_det_mod_id 
	and srmt.data_cancellazione is null 
	and srms.data_cancellazione is null 
	--SIAC-8304
	and tmta.data_cancellazione is null
	and tipoa.movgest_ts_tipo_code = 'T'
	and tmta.movgest_id = p_movgest_id
	into v_importo_vincolo;

--	v_messaggiorisultato := ' importo vincolo trovato per la modifica con uid: ' || p_det_mod_id || ' importo vincolo: ' || v_importo_vincolo;
--	raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;

	if v_importo_residuo <= v_importo_vincolo then
		v_importo_massimo_collegabile := v_importo_residuo;
  	else
  		v_importo_massimo_collegabile := v_importo_vincolo;
  	end if;
  
-- 	v_messaggiorisultato := ' importo massimo collegabile per la modifica con uid: ' || p_det_mod_id || ' importo massimo collegabile: ' || v_importo_massimo_collegabile;
--	raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
	
  	if v_importo_massimo_collegabile is null then
  		v_messaggiorisultato := ' Nessun importo massimo collegabile trovato per la modifica con uid: ' || p_det_mod_id;
  		raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
  		v_importo_massimo_collegabile := 0;
  	end if;
  	
  	return v_importo_massimo_collegabile;
  
END;
$function$
;
