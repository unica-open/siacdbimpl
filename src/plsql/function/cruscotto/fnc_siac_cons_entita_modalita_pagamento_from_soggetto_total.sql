/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_cons_entita_modalita_pagamento_from_soggetto_total(INTEGER);

CREATE OR REPLACE FUNCTION fnc_siac_cons_entita_modalita_pagamento_from_soggetto_total (
	_uid_soggetto INTEGER
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT COALESCE(COUNT(*), 0)
	INTO total
	FROM (
		SELECT
			1
		FROM
			siac_t_soggetto sog1,
			siac_t_modpag modpag,
			siac_r_modpag_stato rModpagStato,
			siac_d_modpag_stato dModpagStato,
			siac_r_modpag_ordine rModpagOrdine,
			siac_t_soggetto sog_ordine,
			siac_d_accredito_tipo dAccreditoTipo
		WHERE sog_ordine.soggetto_id = _uid_soggetto
		AND sog1.soggetto_id = modpag.soggetto_id
		AND modpag.modpag_id = rModpagStato.modpag_id
		AND rModpagStato.modpag_stato_id = dModpagStato.modpag_stato_id
		AND modpag.modpag_id = rModpagOrdine.modpag_id
		AND rModpagOrdine.soggetto_id = sog_ordine.soggetto_id
		AND dAccreditoTipo.accredito_tipo_id = modpag.accredito_tipo_id
		AND sog1.data_cancellazione IS NULL
		AND modpag.data_cancellazione IS NULL
		AND rModpagStato.data_cancellazione IS NULL
		AND dModpagStato.data_cancellazione IS NULL
		AND rModpagOrdine.data_cancellazione IS NULL
		AND sog_ordine.data_cancellazione IS NULL
		AND dAccreditoTipo.data_cancellazione IS NULL
		-- Union effettuata con l'all in quanto non vi e' possibilita' di record duplicati
		UNION ALL
		--cessioni
		SELECT
			1
		FROM
			siac_t_soggetto sog1,
			siac_r_soggetto_relaz soggettorelaz,
			siac_r_soggrel_modpag rsoggrelmodpag,
			siac_t_modpag modpag,
			siac_t_soggetto sog2,
			siac_r_modpag_stato rModpagStato,
			siac_d_modpag_stato dModpagStato,
			siac_r_modpag_ordine rModpagOrdine,
			siac_t_soggetto sog_ordine,
			siac_d_relaz_tipo dRelazTipo
		where sog_ordine.soggetto_id = _uid_soggetto
		AND sog1.soggetto_id = soggettorelaz.soggetto_id_da
		AND soggettorelaz.soggetto_relaz_id = rsoggrelmodpag.soggetto_relaz_id
		AND rsoggrelmodpag.modpag_id = modpag.modpag_id
		AND modpag.modpag_id = rModpagStato.modpag_id
		AND rModpagStato.modpag_stato_id = dModpagStato.modpag_stato_id
		AND modpag.soggetto_id = sog2.soggetto_id
		AND rsoggrelmodpag.soggrelmpag_id = rModpagOrdine.soggrelmpag_id
		AND rModpagOrdine.soggetto_id = sog_ordine.soggetto_id
		AND dRelazTipo.relaz_tipo_id = soggettorelaz.relaz_tipo_id
		AND sog1.data_cancellazione IS NULL
		AND soggettorelaz.data_cancellazione IS NULL
		AND rsoggrelmodpag.data_cancellazione IS NULL
		AND modpag.data_cancellazione IS NULL
		AND sog2.data_cancellazione IS NULL
		AND rModpagStato.data_cancellazione IS NULL
		AND dModpagStato.data_cancellazione IS NULL
		AND rModpagOrdine.data_cancellazione IS NULL
		AND sog_ordine.data_cancellazione IS NULL
		AND dRelazTipo.data_cancellazione IS NULL
	) AS tmp;

RETURN total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

