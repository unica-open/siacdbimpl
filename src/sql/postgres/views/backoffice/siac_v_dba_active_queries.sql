/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dba_active_queries AS
SELECT *
FROM (
  SELECT
    pg_stat_activity.datid,
    pg_stat_activity.datname,
    pg_stat_activity.pid AS procpid,
    pg_stat_activity.usesysid,
    pg_stat_activity.usename,
    pg_stat_activity.application_name,
    pg_stat_activity.client_hostname,
    pg_stat_activity.client_port,
    pg_stat_activity.backend_start,
    pg_stat_activity.xact_start,
    pg_stat_activity.query_start,
    pg_stat_activity.state_change,
    pg_stat_activity.wait_event,
    CASE
      WHEN pg_stat_activity.state IS NOT NULL AND pg_stat_activity.state <> ''::text
      THEN
        CASE
          WHEN pg_stat_activity.query IS NOT NULL AND pg_stat_activity.query <> ''::text
          THEN (('<'::text || pg_stat_activity.state) || '>: '::text) || pg_stat_activity.query
          ELSE ('<'::text || pg_stat_activity.state) || '>'::text
        END
      ELSE pg_stat_activity.query
    END AS current_query,
    (regexp_replace(text(pg_stat_activity.client_addr), '/.*'::text, ''::text) || ':'::text) || pg_stat_activity.client_port::text AS addr
  FROM pg_stat_activity
) tb
WHERE tb.current_query NOT LIKE '<idle>%'::text;
