/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_dba_add_column_params (
	table_in text,
	field_in text,
	data_type_in text
)
RETURNS text AS
$body$
DECLARE
	table_in_trunc text;
	field_in_trunc text;

	query_in text;
	esito text;
BEGIN
	esito := '';

	table_in_trunc := table_in;
	IF LENGTH(table_in_trunc) > 63 THEN
		table_in_trunc := LEFT(table_in, 63);
		esito := esito || '- TRUNCATE table_in TO ' || table_in_trunc;
	END IF;
	
	field_in_trunc := field_in;
	IF LENGTH(field_in_trunc) > 63 THEN
		field_in_trunc := LEFT(field_in, 63);
		esito := esito || '- TRUNCATE field_in TO ' || field_in_trunc;
	END IF;

	SELECT 'ALTER TABLE ' || table_in_trunc || ' ADD COLUMN ' || field_in_trunc || ' ' || data_type_in || ';'
	INTO query_in
	WHERE NOT EXISTS (
		SELECT 1
		FROM information_schema.columns
		WHERE table_name = table_in_trunc
		AND column_name = field_in_trunc
	);

	IF query_in IS NOT NULL THEN
		esito := esito || '- colonna creata';
		execute query_in;
	ELSE
		esito := esito || '- colonna ' || table_in_trunc || '.' || field_in_trunc || ' gia'' presente';
	END IF;

	RETURN esito;
	EXCEPTION
		WHEN RAISE_EXCEPTION THEN
			esito := esito || '- raise_exception - ' || substring(upper(SQLERRM) from 1 for 2500);
			RETURN esito;
		WHEN others THEN
			esito := esito || '- others - ' ||substring(upper(SQLERRM) from 1 for 2500);
			RETURN esito;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
