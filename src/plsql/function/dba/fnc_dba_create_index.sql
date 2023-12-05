/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_dba_create_index (
	table_in text,
	index_in text,
	index_columns_in text,
	index_where_def_in text,
	index_unique_in boolean
)
RETURNS text AS
$body$
DECLARE
	table_in_trunc text;
	index_in_trunc text;

	query_var text;
	query_to_exe text;
	esito text;
BEGIN
	esito := '';

	table_in_trunc := table_in;
	IF LENGTH(table_in_trunc) > 63 THEN
		table_in_trunc := LEFT(table_id, 63);
		esito := esito || '- TRUNCATE table_in TO ' || table_in_trunc;
	END IF;

	index_in_trunc := index_in;
	IF LENGTH(index_in_trunc) > 63 THEN
		index_in_trunc := LEFT(index_in, 63);
		esito := esito || '- TRUNCATE index_in TO ' || index_in_trunc;
	END IF;

	query_var:= 'CREATE '
		|| (CASE WHEN index_unique_in = true THEN 'UNIQUE ' ELSE ' ' END)
		|| 'INDEX '
		|| index_in_trunc || ' ON ' || table_in_trunc || ' USING BTREE ( ' || index_columns_in || ' )'
		|| (CASE WHEN COALESCE(index_where_def_in, '') != '' THEN ' WHERE ( ' || index_where_def_in || ' );' ELSE ';' END);
	-- raise notice 'query_var=%',query_var;

	SELECT query_var
	INTO query_to_exe
	WHERE NOT EXISTS (
		SELECT 1
		FROM pg_class pg
		WHERE pg.relname = index_in
		and pg.relkind = 'i'
	);

	IF query_to_exe IS NOT NULL THEN
		esito := esito || '- indice creato';
		execute query_to_exe;
	ELSE
		esito := esito || '- indice ' || index_in_trunc || ' gia'' presente';
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