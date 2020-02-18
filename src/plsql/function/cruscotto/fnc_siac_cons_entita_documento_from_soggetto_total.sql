/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_documento_from_soggetto_total (
  _uid_soggetto integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT COALESCE(COUNT(*),0)
	INTO total
	FROM (
		SELECT 
			td.doc_id uid,
			td.doc_anno,
			td.doc_numero,
			td.doc_desc,
			td.doc_importo,
			td.doc_data_emissione,
			ddt.doc_tipo_code,
			ddt.doc_tipo_desc,
			dds.doc_stato_code,
			dds.doc_stato_desc,
			ts.subdoc_pagato_cec::VARCHAR,
			ts.subdoc_data_pagamento_cec,
			ts.subdoc_numero,
			tsogg.soggetto_code,
			tsogg.soggetto_desc
		FROM siac_t_soggetto tsogg
		JOIN siac_r_doc_sog rdsogg ON rdsogg.soggetto_id = tsogg.soggetto_id
		JOIN siac_t_doc td ON td.doc_id = rdsogg.doc_id
		JOIN siac_t_subdoc ts ON ts.doc_id = td.doc_id
		JOIN siac_d_doc_tipo ddt ON (ddt.doc_tipo_id=td.doc_tipo_id)
		JOIN siac_r_doc_stato rds ON (rds.doc_id=td.doc_id)
		JOIN siac_d_doc_stato dds ON (dds.doc_stato_id=rds.doc_stato_id)
		WHERE tsogg.soggetto_id = _uid_soggetto
		AND now() BETWEEN rdsogg.validita_inizio AND COALESCE(rdsogg.validita_fine,now())
		AND now() BETWEEN rds.validita_inizio AND COALESCE(rds.validita_fine,now())
		AND tsogg.data_cancellazione IS NULL
		AND rdsogg.data_cancellazione IS NULL
		AND ts.data_cancellazione IS NULL
		AND td.data_cancellazione IS NULL
		AND ddt.data_cancellazione IS NULL
		AND rds.data_cancellazione IS NULL
		AND dds.data_cancellazione IS NULL
	) AS doc_id;

	RETURN total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;