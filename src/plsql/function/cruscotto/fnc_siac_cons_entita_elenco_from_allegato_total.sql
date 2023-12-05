/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_elenco_from_allegato_total (
  _uid_allegato integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT 
	coalesce(count(*),0) into total
 from siac_t_elenco_doc a,siac_r_atto_allegato_elenco_doc b,siac_t_atto_allegato c,siac_r_elenco_doc_stato d
 ,siac_d_elenco_doc_stato e
where a.eldoc_id=b.eldoc_id
and c.attoal_id=b.attoal_id
and d.eldoc_id=a.eldoc_id
and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and e.eldoc_stato_id=d.eldoc_stato_id
and c.attoal_id=_uid_allegato;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;