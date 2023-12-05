/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_dba_add_check_constraint (
	table_in text,
	constraint_in text,
	check_definition text
)
RETURNS text AS
$body$
DECLARE
	table_in_trunc text;
	constraint_in_trunc text;

	query_in text;
	esito text;
BEGIN
	esito := '';

	table_in_trunc := table_in;
	IF LENGTH(table_in_trunc) > 63 THEN
		table_in_trunc := LEFT(table_in, 63);
		esito := esito || '- TRUNCATE table_in TO ' || table_in_trunc;
	END IF;
	
	constraint_in_trunc := constraint_in;
	IF LENGTH(constraint_in_trunc) > 63 THEN
		constraint_in_trunc := LEFT(constraint_in, 63);
		esito := esito || '- TRUNCATE constraint_in TO ' || constraint_in_trunc;
	END IF;
 	
	SELECT 'ALTER TABLE ' || table_in_trunc || ' ADD CONSTRAINT ' || constraint_in_trunc || ' CHECK (' || check_definition || ');'
	INTO query_in
	WHERE NOT EXISTS (
		SELECT 1
		FROM information_schema.check_constraints
		WHERE constraint_name = constraint_in_trunc
	);
	IF query_in IS NOT NULL THEN
		esito := esito || '- check contraint creato';
		EXECUTE query_in;
	ELSE
		esito := '- check contraint ' || constraint_in_trunc || ' gia'' presente';
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
