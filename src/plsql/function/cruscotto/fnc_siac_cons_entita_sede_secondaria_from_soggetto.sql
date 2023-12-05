/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿DROP FUNCTION IF EXISTS fnc_siac_cons_entita_sede_secondaria_from_soggetto(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_sede_secondaria_from_soggetto (
	_uid_soggetto INTEGER,
	_limit INTEGER,
	_page INTEGER
)
RETURNS TABLE (
	toponimo VARCHAR,
	zip_code VARCHAR,
	comune_desc VARCHAR,
	sigla_automobilistica VARCHAR,
	via_tipo_desc VARCHAR,
	soggetto_code VARCHAR,
	soggetto_desc VARCHAR,
	soggetto_stato_code VARCHAR,
	soggetto_stato_desc VARCHAR,
  	soggetto_code_princ VARCHAR, -- 26.06.2018 Sofia siac-6193
  	soggetto_desc_princ VARCHAR  -- 26.06.2018 Sofia siac-6193
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY

	WITH provincia AS (
		SELECT
			siac_r_comune_provincia.comune_id,
			siac_t_provincia.sigla_automobilistica
			-- La relazione tra provincia e regione non e' popolata
		FROM
			siac_r_comune_provincia,
			siac_t_provincia
			--siac_r_provincia_regione
			--siac_t_regione
		WHERE siac_r_comune_provincia.provincia_id = siac_t_provincia.provincia_id
		--AND siac_t_provincia.provincia_id = siac_r_provincia_regione.provincia_id
		--AND siac_r_provincia_regione.regione_id = siac_t_regione.regione_id
		AND siac_r_comune_provincia.data_cancellazione IS NULL
		AND siac_t_provincia.data_cancellazione IS NULL
		--AND siac_r_provincia_regione.data_cancellazione IS NULL
		--AND siac_t_regione.data_cancellazione IS NULL
	),
	sede_sec AS (
		SELECT
			sog2.soggetto_id sede_sec_id,
			sog1.soggetto_id,
			sog2.soggetto_code,
			sog2.soggetto_desc,
			dSogStato.soggetto_stato_code,
			dSogStato.soggetto_stato_desc,
            sog1.soggetto_code soggetto_code_princ, -- 26.06.2018 Sofia siac-6193
            sog1.soggetto_desc soggetto_desc_princ  -- 26.06.2018 Sofia siac-6193
		FROM
			siac_t_soggetto sog1,
			siac_r_soggetto_relaz rSogRelaz,
			siac_d_relaz_tipo dRelTipo,
			siac_t_soggetto sog2,
			siac_r_soggetto_stato rSogStato,
			siac_d_soggetto_stato dSogStato
		WHERE sog1.soggetto_id = rSogRelaz.soggetto_id_da
		AND rSogRelaz.relaz_tipo_id = dRelTipo.relaz_tipo_id
		AND dRelTipo.relaz_tipo_code = 'SEDE_SECONDARIA'
		AND rSogRelaz.soggetto_id_a = sog2.soggetto_id
		AND sog2.soggetto_id = rSogStato.soggetto_id
		AND rSogStato.soggetto_stato_id = dSogStato.soggetto_stato_id
		AND sog1.data_cancellazione IS NULL
		AND rSogRelaz.data_cancellazione IS NULL
		AND dRelTipo.data_cancellazione IS NULL
		AND sog2.data_cancellazione IS NULL
		AND rSogStato.data_cancellazione IS NULL
		AND dSogStato.data_cancellazione IS NULL
	)
	SELECT
		siac_t_indirizzo_soggetto.toponimo,
		siac_t_indirizzo_soggetto.zip_code,
		siac_t_comune.comune_desc,
		provincia.sigla_automobilistica,
		siac_d_via_tipo.via_tipo_desc,
		sede_sec.soggetto_code,
		sede_sec.soggetto_desc,
		sede_sec.soggetto_stato_code,
		sede_sec.soggetto_stato_desc,
   		sede_sec.soggetto_code_princ, -- 26.06.2018 Sofia siac-6193
   		sede_sec.soggetto_desc_princ  -- 26.06.2018 Sofia siac-6193
	FROM siac_t_indirizzo_soggetto
	CROSS JOIN siac_t_comune
	CROSS JOIN sede_sec
	LEFT OUTER JOIN siac_d_via_tipo ON (siac_t_indirizzo_soggetto.via_tipo_id = siac_d_via_tipo.via_tipo_id AND siac_d_via_tipo.data_cancellazione IS NULL)
	LEFT OUTER JOIN provincia ON (provincia.comune_id = siac_t_comune.comune_id)
	WHERE sede_sec.soggetto_id = _uid_soggetto
	AND siac_t_indirizzo_soggetto.soggetto_id = sede_sec.sede_sec_id
	AND siac_t_indirizzo_soggetto.comune_id = siac_t_comune.comune_id
	AND siac_t_indirizzo_soggetto.data_cancellazione IS NULL
	AND siac_t_comune.data_cancellazione IS NULL
	ORDER BY sede_sec.soggetto_desc
	LIMIT _limit
	OFFSET _offset;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


