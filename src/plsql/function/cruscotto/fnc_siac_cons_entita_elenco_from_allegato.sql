/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_elenco_from_allegato (
  _uid_allegato integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  eldoc_anno integer,
  eldoc_numero integer,
  eldoc_stato_desc varchar,
  eldoc_data_trasmissione timestamp,
  eldoc_sysesterno_anno integer,
  eldoc_sysesterno_numero varchar,
  eldoc_totale_quoteentrate numeric,
  eldoc_totale_quotespese numeric,
  eldoc_totale_differenza numeric
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	_stringaTest varchar := 'test';
BEGIN

	RETURN QUERY
	select 
a.eldoc_id as uid,
a.eldoc_anno,
a.eldoc_numero,
e.eldoc_stato_desc,
a.eldoc_data_trasmissione,
a.eldoc_sysesterno_anno,
a.eldoc_sysesterno_numero,
a.eldoc_tot_quoteentrate,
a.eldoc_tot_quotespese,
a.eldoc_tot_quoteentrate-a.eldoc_tot_quotespese as eldoc_totale_differenza
 from siac_t_elenco_doc a,siac_r_atto_allegato_elenco_doc b,siac_t_atto_allegato c,siac_r_elenco_doc_stato d
 ,siac_d_elenco_doc_stato e
where a.eldoc_id=b.eldoc_id
and c.attoal_id=b.attoal_id
and d.eldoc_id=a.eldoc_id
and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
and e.eldoc_stato_id=d.eldoc_stato_id
and c.attoal_id=_uid_allegato
order by 2,3
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;