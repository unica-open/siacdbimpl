/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_elenco_from_provvedimento_total (
  _uid_provvedimento integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT 
	coalesce(count(*),0) into total
    from siac_t_atto_amm a, siac_d_atto_amm_tipo b,siac_r_atto_amm_stato c,
    siac_d_atto_amm_stato d, siac_t_atto_allegato e,siac_r_atto_allegato_stato l,
    siac_d_atto_allegato_stato m,
    siac_r_atto_allegato_elenco_doc n, siac_t_elenco_doc o,
    siac_r_elenco_doc_stato p,
    siac_d_elenco_doc_stato q
    where 
    b.attoamm_tipo_id=a.attoamm_tipo_id
    and c.attoamm_id=a.attoamm_id
    and d.attoamm_stato_id=c.attoamm_stato_id
    and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
    and a.attoamm_id=_uid_provvedimento
    and e.attoamm_id=a.attoamm_id
    and l.attoal_id=e.attoal_id
    and m.attoal_stato_id=l.attoal_stato_id
    and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now())
    and e.attoal_id=n.attoal_id
    and o.eldoc_id=n.eldoc_id
    and now() BETWEEN n.validita_inizio and COALESCE(n.validita_fine,now())
    and p.eldoc_id=o.eldoc_id
    and p.eldoc_stato_id=q.eldoc_stato_id
    and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
    and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
    and l.data_cancellazione is null
    and m.data_cancellazione is null
    and p.data_cancellazione is null
    and q.data_cancellazione is null;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;