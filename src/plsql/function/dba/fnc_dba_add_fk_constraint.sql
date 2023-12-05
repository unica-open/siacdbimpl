/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_dba_add_fk_constraint (
	table_in text,
	constraint_in text,
	column_in text,
	table_ref text,
	column_ref text
)
RETURNS text AS
$body$
DECLARE
	table_in_trunc text;
	constraint_in_trunc text;
	column_in_trunc text;
	table_ref_trunc text;
	column_ref_trunc text;

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

	column_in_trunc := column_in;
	IF LENGTH(column_in_trunc) > 63 THEN
		column_in_trunc := LEFT(column_in, 63);
		esito := esito || '- TRUNCATE column_in TO ' || column_in_trunc;
	END IF;

	table_ref_trunc := table_ref;
	IF LENGTH(table_ref_trunc) > 63 THEN
		table_ref_trunc := LEFT(table_ref, 63);
		esito := esito || '- TRUNCATE table_ref TO ' || table_ref_trunc;
	END IF;

	column_ref_trunc := column_ref;
	IF LENGTH(column_ref_trunc) > 63 THEN
		column_ref_trunc := LEFT(column_ref, 63);
		esito := esito || '- TRUNCATE column_ref TO ' || column_ref_trunc;
	END IF;

	SELECT  'ALTER TABLE ' || table_in_trunc || ' ADD CONSTRAINT ' || constraint_in_trunc || ' FOREIGN KEY (' || column_in_trunc ||') ' ||
		' REFERENCES ' || table_ref_trunc || '(' || column_ref_trunc || ') ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE'
	INTO query_in
	WHERE NOT EXISTS (
		SELECT 1
		FROM information_schema.table_constraints tc
		WHERE tc.constraint_schema = 'siac'
		AND tc.table_schema = 'siac'
		AND tc.constraint_type = 'FOREIGN KEY'
		AND tc.table_name = table_in_trunc
		AND tc.constraint_name = constraint_in_trunc
	);
	
	IF query_in IS NOT NULL THEN
		esito := esito || '- fk constraint creato';
		execute query_in;
	ELSE
		esito := esito || '- fk constraint ' || constraint_in_trunc || ' gia'' presente';
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
