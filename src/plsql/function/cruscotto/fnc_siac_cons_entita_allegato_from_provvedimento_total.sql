/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_allegato_from_provvedimento_total (
  _uid_provvedimento integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	select 
    coalesce(count(*),0) into total
    from siac_t_atto_amm a, siac_d_atto_amm_tipo b,siac_r_atto_amm_stato c,
    siac_d_atto_amm_stato d, siac_t_atto_allegato e,siac_r_atto_allegato_stato l,
    siac_d_atto_allegato_stato m
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
    and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
    and l.data_cancellazione is null
    and m.data_cancellazione is null;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;