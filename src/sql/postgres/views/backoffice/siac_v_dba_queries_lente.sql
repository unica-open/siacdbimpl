/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dba_queries_lente AS
SELECT
  a.query,
  round(a.total_time::numeric, 2) AS tot_millisecondi,
  round(round(round(a.total_time::numeric, 2) / 1000::numeric, 2) / 60::numeric, 2) AS tot_minuti,
  round(round(a.total_time::numeric, 2) / 1000::numeric, 2) AS tot_secondi,
  round(round(round(a.total_time::numeric, 2) / 1000::numeric, 2) / a.calls::numeric, 2) AS secondi_per_esecuzione,
  a.calls AS esecuzioni
FROM pg_stat_statements a
WHERE (a.total_time / 1000::double precision) > 1::double precision
ORDER BY (round(round(round(a.total_time::numeric, 2) / 1000::numeric, 2) / a.calls::numeric, 2)) DESC;