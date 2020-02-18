/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_documento_from_provvedimento (
  _uid_provvedimento integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  doc_anno integer,
  doc_numero varchar,
  doc_desc varchar,
  doc_importo numeric,
  subdoc_importo numeric,
  doc_data_emissione timestamp,
  doc_tipo_code varchar,
  doc_tipo_desc varchar,
  doc_stato_code varchar,
  doc_stato_desc varchar,
  subdoc_pagato_cec varchar,
  subdoc_data_pagamento_cec timestamp,
  subdoc_numero integer,
  soggetto_code varchar,
  soggetto_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	_test VARCHAR := 'test';
BEGIN

	RETURN QUERY
	WITH doc AS (
		SELECT
			d.doc_id uid,
			d.doc_anno,
			d.doc_numero,
			d.doc_desc, 
			d.doc_importo,
			c.subdoc_importo,
			d.doc_data_emissione,
			e.doc_tipo_code,
			e.doc_tipo_desc, 
			g.doc_stato_code,
			g.doc_stato_desc,
			c.subdoc_pagato_cec::VARCHAR subdoc_pagato_cec,
			c.subdoc_data_pagamento_cec,
			c.subdoc_numero
		FROM siac_t_atto_amm a,
			siac_r_subdoc_atto_amm b,
			siac_t_subdoc c,
			siac_t_doc d,
			siac_d_doc_tipo e,
			siac_r_doc_stato f,
			siac_d_doc_stato g
		WHERE a.attoamm_id=_uid_provvedimento
		AND a.attoamm_id=b.attoamm_id
		AND c.subdoc_id=b.subdoc_id
		AND d.doc_id=c.doc_id
		AND e.doc_tipo_id=d.doc_tipo_id
		AND now() BETWEEN b.validita_inizio AND COALESCE(b.validita_fine,now())
		AND f.doc_id=d.doc_id
		AND f.doc_stato_id=g.doc_stato_id
		AND now() BETWEEN f.validita_inizio AND COALESCE(f.validita_fine,now())
		AND a.data_cancellazione IS NULL
		AND b.data_cancellazione IS NULL
		AND c.data_cancellazione IS NULL
		AND d.data_cancellazione IS NULL
		AND e.data_cancellazione IS NULL
		AND f.data_cancellazione IS NULL
		AND g.data_cancellazione IS NULL
	),
	sogg AS (
		SELECT
			h.doc_id,
			i.soggetto_code,
			i.soggetto_desc
		FROM siac_r_doc_sog h,
			siac_t_soggetto i
		WHERE h.soggetto_id = i.soggetto_id
		AND now() BETWEEN h.validita_inizio AND COALESCE(h.validita_fine,now())
		AND h.data_cancellazione IS NULL
		AND i.data_cancellazione IS NULL
	)
	SELECT
		doc.uid,
		doc.doc_anno,
		doc.doc_numero,
		doc.doc_desc,
		doc.doc_importo,
		doc.subdoc_importo,
		doc.doc_data_emissione,
		doc.doc_tipo_code,
		doc.doc_tipo_desc,
		doc.doc_stato_code,
		doc.doc_stato_desc,
		doc.subdoc_pagato_cec,
		doc.subdoc_data_pagamento_cec,
		doc.subdoc_numero,
		sogg.soggetto_code,
		sogg.soggetto_desc
	FROM doc
	LEFT OUTER JOIN sogg ON doc.uid=sogg.doc_id
	ORDER BY 2,3, doc.subdoc_numero
	LIMIT _limit
	OFFSET _offset;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;