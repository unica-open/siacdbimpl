/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_documento_from_capitolospesa (
  _uid_capitolo integer,
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
			td.doc_id uid,
			td.doc_anno,
			td.doc_numero,
			td.doc_desc,
			td.doc_importo,
			ts.subdoc_importo,
			td.doc_data_emissione,
			ddt.doc_tipo_code,
			ddt.doc_tipo_desc,
			dds.doc_stato_code,
			dds.doc_stato_desc,
			ts.subdoc_pagato_cec::VARCHAR,
			ts.subdoc_data_pagamento_cec,
			ts.subdoc_numero
		FROM siac_t_bil_elem tbe
		JOIN siac_r_movgest_bil_elem rmbe ON rmbe.elem_id = tbe.elem_id
		JOIN siac_t_movgest tm ON tm.movgest_id = rmbe.movgest_id
		JOIN siac_t_movgest_ts tmt ON tmt.movgest_id = tm.movgest_id
		JOIN siac_r_subdoc_movgest_ts rsmt ON rsmt.movgest_ts_id = tmt.movgest_ts_id
		JOIN siac_t_subdoc ts ON ts.subdoc_id = rsmt.subdoc_id
		JOIN siac_t_doc td ON td.doc_id = ts.doc_id
		JOIN siac_d_doc_tipo ddt ON (ddt.doc_tipo_id=td.doc_tipo_id)
		JOIN siac_r_doc_stato rds ON (rds.doc_id=td.doc_id)
		JOIN siac_d_doc_stato dds ON (dds.doc_stato_id=rds.doc_stato_id)
		WHERE tbe.elem_id = _uid_capitolo
		AND now() BETWEEN rmbe.validita_inizio AND COALESCE(rmbe.validita_fine,now())
		AND now() BETWEEN rsmt.validita_inizio AND COALESCE(rsmt.validita_fine,now())
		AND now() BETWEEN rds.validita_inizio AND COALESCE(rds.validita_fine,now())
		AND tbe.data_cancellazione IS NULL
		AND rmbe.data_cancellazione IS NULL
		AND tm.data_cancellazione IS NULL
		AND tmt.data_cancellazione IS NULL
		AND rsmt.data_cancellazione IS NULL
		AND ts.data_cancellazione IS NULL
		AND td.data_cancellazione IS NULL
		AND ddt.data_cancellazione IS NULL
		AND rds.data_cancellazione IS NULL
		AND dds.data_cancellazione IS NULL
	),
	sogg AS (
		SELECT
			rds.doc_id,
			ts.soggetto_code,
			ts.soggetto_desc
		FROM siac_r_doc_sog rds
		JOIN siac_t_soggetto ts ON (rds.soggetto_id = ts.soggetto_id)
		WHERE now() BETWEEN rds.validita_inizio AND COALESCE(rds.validita_fine,now())
		AND rds.data_cancellazione IS NULL
		AND ts.data_cancellazione IS NULL
	)
	SELECT
		doc.*,
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