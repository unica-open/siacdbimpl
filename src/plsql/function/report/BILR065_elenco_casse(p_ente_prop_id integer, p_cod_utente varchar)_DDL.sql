/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR065_elenco_casse" (
  p_ente_prop_id integer,
  p_cod_utente varchar
)
RETURNS TABLE (
  cassaecon_id integer,
  cassaecon_code varchar,
  cassaecon_desc varchar
) AS
$body$
DECLARE
elenco_casse record;

BEGIN
	cassaecon_code='';
    cassaecon_desc='';
    cassaecon_id=0;
    
    
	
for elenco_casse in
select  cassa_econ.cassaecon_id					cassaecon_id,
		cassa_econ.cassaecon_code				cassaecon_code,
		cassa_econ.cassaecon_desc				cassaecon_desc       
from 	siac_t_cassa_econ					cassa_econ
		
where 	cassa_econ.ente_proprietario_id=p_ente_prop_id
		and cassa_econ.data_cancellazione is NULL
ORDER BY cassaecon_code
	loop
	
    cassaecon_code=elenco_casse.cassaecon_code;
    cassaecon_desc=elenco_casse.cassaecon_desc;
    cassaecon_id=elenco_casse.cassaecon_id;
    
    return next;
    
    cassaecon_code='';
    cassaecon_desc='';
    cassaecon_id=0;
    
    end loop;

exception
	when no_data_found THEN
		raise notice 'casse non trovate' ;
		--return next;
	when others  THEN
		raise notice 'errore nella lettura delle casse ';
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;