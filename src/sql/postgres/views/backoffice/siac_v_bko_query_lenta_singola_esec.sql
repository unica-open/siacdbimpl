/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
 CREATE OR REPLACE VIEW siac.siac_v_bko_query_lenta_singola_esec(
    query,
    tot_millisecondi,
    tot_minuti,
    tot_secondi,
    secondi_per_esecuzione,
    esecuzioni)
AS
  SELECT tb.query,
         tb.tot_millisecondi,
         tb.tot_minuti,
         tb.tot_secondi,
         tb.secondi_per_esecuzione,
         tb.esecuzioni
  FROM (
         SELECT a.query,
                round(a.total_time::numeric, 2) AS tot_millisecondi,
                round(round(round(a.total_time::numeric, 2) / 1000::numeric, 2)
                  / 60::numeric, 2) AS tot_minuti,
                round(round(a.total_time::numeric, 2) / 1000::numeric, 2) AS
                  tot_secondi,
                round(round(round(a.total_time::numeric, 2) / 1000::numeric, 2)
                  / a.calls::numeric, 2) AS secondi_per_esecuzione,
                a.calls AS esecuzioni
         FROM pg_stat_statements a
       ) tb
  WHERE tb.secondi_per_esecuzione > 1::numeric
  ORDER BY tb.secondi_per_esecuzione DESC;