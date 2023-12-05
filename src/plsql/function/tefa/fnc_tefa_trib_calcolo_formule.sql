/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_tefa_trib_calcolo_formule(p_tefa_trib_formula_id integer, p_tefa_trib_importo numeric);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_calcolo_formule(p_tefa_trib_formula_id integer, p_tefa_trib_importo numeric)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE

tefa_trib_importo numeric:=0;

BEGIN


case coalesce(p_tefa_trib_formula_id,0)
  when 1 then  -- ARROTONDA((C/100)*5/105;5)
--    tefa_trib_importo:=round((p_tefa_trib_importo/100)*5/105,5);
    tefa_trib_importo:=round((p_tefa_trib_importo)*5/105,5);
  when 2 then  -- ARROTONDA((C/100);5)
--    tefa_trib_importo:=round((p_tefa_trib_importo/100),5);
    tefa_trib_importo:=round((p_tefa_trib_importo),5);
  when 3 then  -- ARROTONDA(H*0,3/100;5)
--    tefa_trib_importo:=round((p_tefa_trib_importo*0.3/100),5);
    tefa_trib_importo:=round((p_tefa_trib_importo/100*0.3),5);   
  else   tefa_trib_importo:=null;
end case;

return tefa_trib_importo;


exception
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return tefa_trib_importo;
END;
$function$
;
