/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_cons_entita_indirizzo_from_soggetto(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION fnc_siac_cons_entita_indirizzo_from_soggetto (
	_uid_soggetto INTEGER,
	_limit INTEGER,
	_page INTEGER
)
RETURNS TABLE (
	toponimo VARCHAR,
	zip_code VARCHAR,
	principale CHAR,
	avviso CHAR,
	indirizzo_tipo_desc VARCHAR,
	comune_desc VARCHAR,
	sigla_automobilistica VARCHAR,
	via_tipo_desc VARCHAR
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
	)
	SELECT
		siac_t_indirizzo_soggetto.toponimo,
		siac_t_indirizzo_soggetto.zip_code,
		siac_t_indirizzo_soggetto.principale,
		siac_t_indirizzo_soggetto.avviso,
		siac_d_indirizzo_tipo.indirizzo_tipo_desc,
		siac_t_comune.comune_desc,
		provincia.sigla_automobilistica,
		siac_d_via_tipo.via_tipo_desc
	FROM siac_t_indirizzo_soggetto
	CROSS JOIN siac_r_indirizzo_soggetto_tipo
	CROSS JOIN siac_d_indirizzo_tipo
	CROSS JOIN siac_t_comune
	LEFT OUTER JOIN siac_d_via_tipo ON (siac_t_indirizzo_soggetto.via_tipo_id = siac_d_via_tipo.via_tipo_id AND siac_d_via_tipo.data_cancellazione IS NULL)
	LEFT OUTER JOIN provincia ON (provincia.comune_id = siac_t_comune.comune_id)
	WHERE siac_t_indirizzo_soggetto.soggetto_id = _uid_soggetto
	AND siac_t_indirizzo_soggetto.indirizzo_id = siac_r_indirizzo_soggetto_tipo.indirizzo_id
	AND siac_r_indirizzo_soggetto_tipo.indirizzo_tipo_id = siac_d_indirizzo_tipo.indirizzo_tipo_id
	AND siac_t_indirizzo_soggetto.comune_id = siac_t_comune.comune_id
	AND siac_t_indirizzo_soggetto.data_cancellazione IS NULL
	AND siac_r_indirizzo_soggetto_tipo.data_cancellazione IS NULL
	AND siac_d_indirizzo_tipo.data_cancellazione IS NULL
	AND siac_t_comune.data_cancellazione IS NULL
	ORDER BY
		siac_t_comune.comune_desc,
		siac_t_indirizzo_soggetto.principale,
		siac_t_indirizzo_soggetto.toponimo
	LIMIT _limit
	OFFSET _offset;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
