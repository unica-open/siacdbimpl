/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿DROP FUNCTION IF EXISTS siac.fnc_siac_importo_residuo_spesa_collegata(p_det_mod_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_importo_residuo_spesa_collegata(p_det_mod_id integer)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_importo_residuo numeric := null;
    v_importo_collegato numeric := null;
    v_importo_modifica numeric := null;
    v_result integer := null;
   	v_messaggiorisultato varchar;
BEGIN

	--ottengo la somma degli importi delle modifiche sulla R associate alla modifica se presenti
	select SUM(srmtdm.movgest_ts_det_mod_importo)
	from siac_r_movgest_ts_det_mod srmtdm 
	join siac_t_movgest_ts_det_mod stmtdm on srmtdm.movgest_ts_det_mod_spesa_id = stmtdm.movgest_ts_det_mod_id 
	join siac_r_modifica_stato srms on stmtdm.mod_stato_r_id = srms.mod_stato_r_id
	join siac_t_modifica stm on stm.mod_id = srms.mod_id
	where stm.mod_id = p_det_mod_id 
	and srmtdm.data_cancellazione is null 
	and srms.data_cancellazione is null into v_importo_collegato;

	--calcolo l'importo del dettaglio modifica
	select ABS(stmtdm.movgest_ts_det_importo) 
	from siac_t_movgest_ts_det_mod stmtdm
	join siac_r_modifica_stato srms on stmtdm.mod_stato_r_id = srms.mod_stato_r_id
	join siac_t_modifica stm on stm.mod_id = srms.mod_id
	where stm.mod_id = p_det_mod_id 
	and stmtdm.data_cancellazione is null 
	and srms.data_cancellazione is null into v_importo_modifica;

	-- se il residuo e' presente ed e' minore o uguale a 0 
	if v_importo_collegato <= 0 then
		v_importo_collegato := 0;
	-- se nullo assumo il valore nel vecchio importo del dettaglio modifica
  	elseif v_importo_collegato is null and v_importo_modifica is not null
  		then
  		v_importo_residuo := v_importo_modifica;
  	-- se ho l'importo della R ed e' maggiore di 0
  	elseif v_importo_collegato is not null and v_importo_collegato > 0 and v_importo_modifica is not null 
  		then
  		v_importo_residuo := v_importo_modifica - v_importo_collegato;
  	end if;
	
  	-- probabili dati sporchi, probabilmente manca l'importo della modifica
  	if v_importo_residuo is null then
  		v_messaggiorisultato = ' Nessun importo residuo trovato per la modifica con uid: ' || p_det_mod_id || ' .';
  		raise notice '[fnc_siac_importo_residuo_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
  		v_importo_residuo := 0;
  	end if;
  
--  v_messaggiorisultato := ' importo residuo trovato per la modifica con uid: ' || p_det_mod_id || ', importo residuo: ' || v_importo_residuo;
--	raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
  	
  	return v_importo_residuo;

END;
$function$
;
