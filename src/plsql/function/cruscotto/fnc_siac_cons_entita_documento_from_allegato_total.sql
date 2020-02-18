/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_documento_from_allegato_total (
  _uid_allegato integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT COALESCE(COUNT(*),0)
	INTO total
	FROM
		siac_t_atto_amm a,
		siac_r_subdoc_atto_amm b,
		siac_t_subdoc c,
		siac_t_doc d,
		siac_d_doc_tipo e,
		siac_r_doc_stato f,
		siac_d_doc_stato g,
		siac_t_atto_allegato h
	WHERE a.attoamm_id=b.attoamm_id
	AND c.subdoc_id=b.subdoc_id
	AND d.doc_id=c.doc_id
	AND e.doc_tipo_id=d.doc_tipo_id
	AND now() BETWEEN b.validita_inizio AND COALESCE(b.validita_fine,now())
	AND f.doc_id=d.doc_id
	AND f.doc_stato_id=g.doc_stato_id
	AND now() BETWEEN f.validita_inizio AND COALESCE(f.validita_fine,now())
	AND h.attoamm_id=a.attoamm_id
	AND h.attoal_id=_uid_allegato
	AND a.data_cancellazione IS NULL
	AND b.data_cancellazione IS NULL
	AND c.data_cancellazione IS NULL
	AND d.data_cancellazione IS NULL
	AND e.data_cancellazione IS NULL
	AND f.data_cancellazione IS NULL
	AND g.data_cancellazione IS NULL
	AND h.data_cancellazione IS NULL;
	
	RETURN total;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;