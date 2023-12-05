/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿DROP FUNCTION IF EXISTS siac.fnc_siac_importi_modifica_spesa_collegata_set(p_mod_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_importi_modifica_spesa_collegata_set(p_mod_id integer, p_movgest_id integer)
 RETURNS SETOF numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
   	v_importo_residuo numeric := null;
   	v_importo_max_collegabile numeric := null;
   	v_messaggiorisultato varchar := null;
BEGIN

	SELECT * FROM fnc_siac_importo_residuo_spesa_collegata(p_mod_id) INTO v_importo_residuo;

	SELECT * FROM fnc_siac_importo_max_coll_spesa_collegata(p_mod_id, p_movgest_id, v_importo_residuo) INTO v_importo_max_collegabile;
	
	v_messaggiorisultato := ' importo residuo : ' || v_importo_residuo || ', importo massimo collegabile: ' || v_importo_max_collegabile || '';
	RAISE NOTICE '[fnc_siac_importo_residuo_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
	
	-- return numeric[] => [0] => v_importo_residuo, [1] => v_importo_max_collegabile
    RETURN query values (v_importo_residuo), (v_importo_max_collegabile);
    
END;
$function$
;
