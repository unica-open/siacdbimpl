/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_cons_entita_indirizzo_from_soggetto_total(INTEGER);

CREATE OR REPLACE FUNCTION fnc_siac_cons_entita_indirizzo_from_soggetto_total (
	_uid_soggetto INTEGER
)
RETURNS BIGINT AS
$body$
DECLARE
	total BIGINT;
BEGIN
	
	SELECT COALESCE(COUNT(tmp.*), 0)
	INTO total
	FROM (
		SELECT 1
		FROM siac_t_indirizzo_soggetto
		CROSS JOIN siac_r_indirizzo_soggetto_tipo
		CROSS JOIN siac_d_indirizzo_tipo
		CROSS JOIN siac_t_comune
		WHERE siac_t_indirizzo_soggetto.soggetto_id = _uid_soggetto
		AND siac_t_indirizzo_soggetto.indirizzo_id = siac_r_indirizzo_soggetto_tipo.indirizzo_id
		AND siac_r_indirizzo_soggetto_tipo.indirizzo_tipo_id = siac_d_indirizzo_tipo.indirizzo_tipo_id
		AND siac_t_indirizzo_soggetto.comune_id = siac_t_comune.comune_id
		AND siac_t_indirizzo_soggetto.data_cancellazione IS NULL
		AND siac_r_indirizzo_soggetto_tipo.data_cancellazione IS NULL
		AND siac_d_indirizzo_tipo.data_cancellazione IS NULL
		AND siac_t_comune.data_cancellazione IS NULL
	) tmp;
	
RETURN total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;