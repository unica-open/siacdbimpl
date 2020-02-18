/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_cons_entita_sede_secondaria_from_soggetto_total(INTEGER);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_sede_secondaria_from_soggetto_total (
	_uid_soggetto INTEGER
)
RETURNS BIGINT AS
$body$
DECLARE
	total BIGINT;
BEGIN

	WITH sede_sec AS (
		SELECT
			sog2.soggetto_id sede_sec_id,
			sog1.soggetto_id
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
	SELECT COALESCE(COUNT(*), 0)
	INTO total
	FROM siac_t_indirizzo_soggetto
	CROSS JOIN siac_t_comune
	CROSS JOIN sede_sec
	WHERE sede_sec.soggetto_id = _uid_soggetto
	AND siac_t_indirizzo_soggetto.soggetto_id = sede_sec.sede_sec_id
	AND siac_t_indirizzo_soggetto.comune_id = siac_t_comune.comune_id
	AND siac_t_indirizzo_soggetto.data_cancellazione IS NULL
	AND siac_t_comune.data_cancellazione IS NULL;

RETURN total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;