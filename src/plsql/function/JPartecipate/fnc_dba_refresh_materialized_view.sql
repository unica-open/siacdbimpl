/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


DROP FUNCTION IF EXISTS siac.fnc_dba_refresh_materialized_view(VARIADIC TEXT[]);

CREATE OR REPLACE FUNCTION siac.fnc_dba_refresh_materialized_view (VARIADIC p_names TEXT[])
  RETURNS TEXT
  LANGUAGE plpgsql
AS
$$
DECLARE
  v_sql TEXT;
  v_result TEXT := '';
BEGIN
  FOR i IN 1..array_upper(p_names, 1) LOOP
    IF p_names[i] IS NOT NULL THEN
      v_sql := format('REFRESH MATERIALIZED VIEW %I WITH DATA', p_names[i]);
      EXECUTE v_sql;
      v_result := v_result || 'Refreshed view ' || p_names[i] || '.' || chr(10);
    END IF;
  END LOOP;
  v_result := v_result || 'Done.';
  RETURN v_result;
END;
$$
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
