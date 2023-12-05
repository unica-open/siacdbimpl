/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR264_verifica_parametri" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  display_error varchar
) AS
$body$
DECLARE

strApp varchar;
intApp integer;

BEGIN


/* 
  30/05/2023 - Procedura nata per il report BILR264 per la SIAC-8857.
 Serve solo per effettuare il controllo di corrrettezza del parametro p_ele_variazioni e restituire un eventuale errore.
 Questo perche' nel report i dati di spesa ed entrata sono uniti e testare l'eventuale proveniente da queste procedure
 non era possibile.

*/


display_error:='';

-- Verifico che il parametro con l'elenco delle variazioni abbia solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;

return next;
 
raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR264_verifica_parametri" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar)
  OWNER TO siac;