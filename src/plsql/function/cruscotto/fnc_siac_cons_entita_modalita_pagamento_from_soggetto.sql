/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿DROP FUNCTION IF EXISTS fnc_siac_cons_entita_modalita_pagamento_from_soggetto(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION fnc_siac_cons_entita_modalita_pagamento_from_soggetto (
	_uid_soggetto INTEGER,
	_limit INTEGER,
	_page INTEGER
)
RETURNS TABLE (
	ordine INTEGER,
	modpag_stato_code VARCHAR,
	modpag_stato_desc VARCHAR,
	associato_a VARCHAR,
	descr_arricchita VARCHAR,
	is_cessione BOOLEAN,
    soggetto_code_princ varchar, -- 26.06.2018 Sofia siac-6193
    soggetto_desc_princ varchar  -- 26.06.2018 Sofia siac-6193
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	rec RECORD;
BEGIN

	FOR rec IN
	SELECT *
	FROM (
		SELECT
			--Codice (numero d'ordine)
			rModpagOrdine.ordine,
			--Descrizione (campo derivato Descrizione della modalita' di pagamento)
			sog1.soggetto_code,
			sog1.soggetto_desc,
			modpag.quietanziante,
			modpag.quietanziante_codice_fiscale,
			modpag.quietanzante_nascita_data,
			modpag.quietanziante_nascita_luogo,
			modpag.quietanziante_nascita_stato,
			modpag.bic,
			modpag.contocorrente,
			modpag.contocorrente_intestazione,
			modpag.iban,
			modpag.banca_denominazione,
			--Associato a (soggetto o <Denominazione> della sede)
			sog_ordine.soggetto_code soggetto_code_ordine,
			sog_ordine.soggetto_desc soggetto_desc_ordine,
			--Stato
			dModpagStato.modpag_stato_code,
			dModpagStato.modpag_stato_desc,
			dAccreditoTipo.accredito_tipo_code mod_pag_tipo_code,
			dAccreditoTipo.accredito_tipo_desc mod_pag_tipo_desc,
			CASE
				WHEN sog1.soggetto_desc = sog_ordine.soggetto_desc THEN 'Soggetto'
				ELSE sog1.soggetto_desc
			END associato_a,
			false is_cessione
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
			rModpagOrdine.ordine,
			sog2.soggetto_code,
			sog2.soggetto_desc,
			modpag.quietanziante,
			modpag.quietanziante_codice_fiscale,
			modpag.quietanzante_nascita_data,
			modpag.quietanziante_nascita_luogo,
			modpag.quietanziante_nascita_stato,
			modpag.bic,
			modpag.contocorrente,
			modpag.contocorrente_intestazione,
			modpag.iban,
			modpag.banca_denominazione,
			sog_ordine.soggetto_code soggetto_code_ordine,
			sog_ordine.soggetto_desc soggetto_desc_ordine,
			dModpagStato.modpag_stato_code,
			dModpagStato.modpag_stato_desc,
			dRelazTipo.relaz_tipo_code mod_pag_tipo_code,
			dRelazTipo.relaz_tipo_desc mod_pag_tipo_desc,
			-- TODO: verificare l'associato_a nel caso di cessione
			'Soggetto' associato_a,
			true is_cessione
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
		WHERE sog_ordine.soggetto_id = _uid_soggetto
		AND   sog1.soggetto_id = soggettorelaz.soggetto_id_da
		AND   soggettorelaz.soggetto_relaz_id = rsoggrelmodpag.soggetto_relaz_id
		AND   rsoggrelmodpag.modpag_id = modpag.modpag_id
		AND   modpag.modpag_id = rModpagStato.modpag_id
		AND   rModpagStato.modpag_stato_id = dModpagStato.modpag_stato_id
		AND   modpag.soggetto_id = sog2.soggetto_id -- a
		AND   rsoggrelmodpag.soggrelmpag_id = rModpagOrdine.soggrelmpag_id
		AND   rModpagOrdine.soggetto_id = sog_ordine.soggetto_id
		AND   dRelazTipo.relaz_tipo_id = soggettorelaz.relaz_tipo_id
		AND   sog1.data_cancellazione IS NULL
		AND   soggettorelaz.data_cancellazione IS NULL
		AND   rsoggrelmodpag.data_cancellazione IS NULL
		AND   modpag.data_cancellazione IS NULL
		AND   sog2.data_cancellazione IS NULL
		AND   rModpagStato.data_cancellazione IS NULL
		AND   dModpagStato.data_cancellazione IS NULL
		AND   rModpagOrdine.data_cancellazione IS NULL
		AND   sog_ordine.data_cancellazione IS NULL
		AND   dRelazTipo.data_cancellazione IS NULL
	) AS tmp
	ORDER BY tmp.ordine
	LIMIT _limit
	OFFSET _offset
	LOOP
		ordine := rec.ordine;
		modpag_stato_code := rec.modpag_stato_code;
		modpag_stato_desc := rec.modpag_stato_desc;
		associato_a := rec.associato_a;
		is_cessione := rec.is_cessione;

		-- Calcolo della descrizione arricchita
		-- Pulizia del campo
		descr_arricchita := '';

        -- 26.06.2018 Sofia siac-6193
        soggetto_code_princ:=rec.soggetto_code_ordine;
        soggetto_desc_princ:=rec.soggetto_desc_ordine;

		-- Soggetto ricevente
		IF rec.is_cessione THEN
			descr_arricchita := descr_arricchita || 'Soggetto ricevente: ' || rec.soggetto_code;
			IF rec.soggetto_desc IS NOT NULL AND (rec.soggetto_desc <> '') THEN
				descr_arricchita := descr_arricchita || ' - ' || rec.soggetto_desc;
			END IF;
		END IF;

		-- Tipo di accredito
		IF rec.mod_pag_tipo_code IS NOT NULL AND (rec.mod_pag_tipo_code <> '') THEN
			IF (descr_arricchita <> '') THEN
				descr_arricchita := descr_arricchita || ' - ';
			END IF;
			descr_arricchita := descr_arricchita || 'Tipo accredito: ' || rec.mod_pag_tipo_code;

			IF rec.mod_pag_tipo_desc IS NOT NULL AND (rec.mod_pag_tipo_desc <> '') THEN
				descr_arricchita := descr_arricchita || ' - ' || rec.mod_pag_tipo_desc;
			END IF;
		END IF;

		-- IBAN
		IF rec.iban IS NOT NULL AND (rec.iban <> '') THEN
			IF (descr_arricchita <> '') THEN
				descr_arricchita := descr_arricchita || ' - ';
			END IF;
			descr_arricchita := descr_arricchita || 'IBAN: ' || rec.iban;
		END IF;

		-- BIC
		IF rec.bic IS NOT NULL AND (rec.bic <> '') THEN
			IF (descr_arricchita <> '') THEN
				descr_arricchita := descr_arricchita || ' - ';
			END IF;
			descr_arricchita := descr_arricchita || 'BIC: ' || rec.bic;
		END IF;

		-- CONTO CORRENTE
		IF rec.contocorrente IS NOT NULL AND (rec.contocorrente <> '') THEN
			IF (descr_arricchita <> '') THEN
				descr_arricchita := descr_arricchita || ' - ';
			END IF;
			descr_arricchita := descr_arricchita || 'Conto: ' || rec.contocorrente;

			IF rec.contocorrente_intestazione IS NOT NULL AND (rec.contocorrente_intestazione <> '') THEN
				descr_arricchita := descr_arricchita || ' intestato a ' || rec.contocorrente_intestazione;
			END IF;
		END IF;

		-- QUIETANZANTE
		IF rec.quietanziante IS NOT NULL AND (rec.quietanziante <> '') THEN
			IF (descr_arricchita <> '') THEN
				descr_arricchita := descr_arricchita || ' - ';
			END IF;
			descr_arricchita := descr_arricchita || 'Quietanzante: ' || rec.quietanziante;

			IF rec.quietanziante_codice_fiscale IS NOT NULL AND (rec.quietanziante_codice_fiscale <> '') THEN
				descr_arricchita := descr_arricchita || ' (CF: ' || rec.quietanziante_codice_fiscale || ')';
			END IF;

			IF rec.quietanzante_nascita_data IS NOT NULL THEN
				descr_arricchita := descr_arricchita || ', nato il ' || rec.quietanzante_nascita_data;
			END IF;

			IF rec.quietanziante_nascita_luogo IS NOT NULL AND (rec.quietanziante_nascita_luogo <> '') THEN
				descr_arricchita := descr_arricchita || ' a ' || rec.quietanziante_nascita_luogo;
			END IF;

			IF rec.quietanziante_nascita_stato IS NOT NULL AND (rec.quietanziante_nascita_stato <> '') THEN
				descr_arricchita := descr_arricchita || ', ' || rec.quietanziante_nascita_stato;
			END IF;
		END IF;

		RETURN NEXT;
	END LOOP;
	RETURN;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;



