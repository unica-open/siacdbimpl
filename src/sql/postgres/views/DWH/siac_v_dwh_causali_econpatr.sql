/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_causali_econpatr (
    ente_proprietario_id,
    causale_ep_code,
    causale_ep_desc,
    causale_ep_tipo_code,
    causale_ep_tipo_desc,
    evento_code,
    evento_desc,
    evento_tipo_code,
    evento_tipo_desc,
    pdce_conto_code,
    oper_ep_code,
    oper_ep_desc,
    classif_code,
    classif_desc)
AS
WITH tab1 AS (
SELECT -- DISTINCT 
      tce.causale_ep_id, tce.ente_proprietario_id,
      tce.causale_ep_code, tce.causale_ep_desc,
      CASE
          WHEN dcet.causale_ep_tipo_code::text = 'INT'::text THEN
          CASE
              WHEN de.evento_code::text ~~ '%RES%'::text THEN
                  "substring"(de.evento_code::text, 1, "position"(de.evento_code::text, '-'::text) + "position"("substring"(de.evento_code::text, "position"(de.evento_code::text, '-'::text) + 1), '-'::text) - 1)::character varying
              ELSE btrim("substring"(de.evento_code::text, 1,
                  "position"(de.evento_code::text, '-'::text) - 1), ' '::text)::character varying
          END
          ELSE de.evento_code
      END AS evento_code,
      de.evento_desc, dcet.causale_ep_tipo_code,
      dcet.causale_ep_tipo_desc, det.evento_tipo_code,
      det.evento_tipo_desc,
      max(rces.validita_inizio),
      max(rec.validita_inizio)
FROM siac_t_causale_ep tce
JOIN siac_r_causale_ep_stato rces ON tce.causale_ep_id = rces.causale_ep_id
JOIN siac_d_causale_ep_stato dces ON rces.causale_ep_stato_id = dces.causale_ep_stato_id
JOIN siac_d_causale_ep_tipo dcet ON dcet.causale_ep_tipo_id = tce.causale_ep_tipo_id
JOIN siac_r_evento_causale rec ON rec.causale_ep_id = tce.causale_ep_id
JOIN siac_d_evento de ON rec.evento_id = de.evento_id
JOIN siac_d_evento_tipo det ON det.evento_tipo_id = de.evento_tipo_id
WHERE /*dces.causale_ep_stato_code::text = 'V'::text 
AND */(de.evento_code::text ~~ '%INS'::text 
     AND dcet.causale_ep_tipo_code::text = 'INT'::text 
     OR dcet.causale_ep_tipo_code::text = 'LIB'::text
    ) 
/*AND tce.data_cancellazione IS NULL 
AND rces.data_cancellazione IS NULL 
AND dces.data_cancellazione IS NULL 
AND dcet.data_cancellazione IS NULL 
AND rec.data_cancellazione IS NULL 
AND de.data_cancellazione IS NULL 
AND det.data_cancellazione IS NULL 
AND date_trunc('day'::text, now()) > rces.validita_inizio 
AND (date_trunc('day'::text, now()) < rces.validita_fine OR rces.validita_fine IS NULL) 
AND date_trunc('day'::text, now()) > rec.validita_inizio 
AND (date_trunc('day'::text, now()) < rec.validita_fine OR rec.validita_fine IS NULL)*/
group by tce.causale_ep_id, tce.ente_proprietario_id, evento_code,
         de.evento_desc, dcet.causale_ep_tipo_code,
         dcet.causale_ep_tipo_desc, det.evento_tipo_code,
         det.evento_tipo_desc
), 
tab2 AS (
SELECT rcepc.causale_ep_id, tpc.pdce_conto_code, doe.oper_ep_code, doe.oper_ep_desc
FROM siac_r_causale_ep_pdce_conto rcepc
JOIN siac_t_pdce_conto tpc ON rcepc.pdce_conto_id = tpc.pdce_conto_id
JOIN siac_r_causale_ep_pdce_conto_oper rcepco ON rcepc.causale_ep_pdce_conto_id = rcepco.causale_ep_pdce_conto_id
JOIN siac_d_operazione_ep doe ON doe.oper_ep_id = rcepco.oper_ep_id
WHERE (doe.oper_ep_code::text = ANY (ARRAY['DARE'::character varying::text,'AVERE'::character varying::text])) 
AND  rcepc.data_cancellazione IS NULL 
AND tpc.data_cancellazione IS NULL 
AND rcepco.data_cancellazione IS NULL 
AND doe.data_cancellazione IS NULL 
AND date_trunc('day'::text, now()) > rcepco.validita_inizio 
AND (date_trunc('day'::text, now()) < rcepco.validita_fine OR rcepco.validita_fine IS NULL)
), 
tab3 AS (
SELECT rcep.causale_ep_id, tc.classif_code, tc.classif_desc
FROM siac_r_causale_ep_class rcep
JOIN siac_t_class tc ON tc.classif_id = rcep.classif_id
WHERE rcep.data_cancellazione IS NULL 
AND tc.data_cancellazione IS NULL 
AND date_trunc('day'::text, now()) > rcep.validita_inizio 
AND (date_trunc('day'::text, now()) < rcep.validita_fine OR rcep.validita_fine IS NULL)
)
SELECT tab1.ente_proprietario_id, tab1.causale_ep_code, tab1.causale_ep_desc,
tab1.causale_ep_tipo_code, tab1.causale_ep_tipo_desc, tab1.evento_code,
tab1.evento_desc, tab1.evento_tipo_code, tab1.evento_tipo_desc,
tab2.pdce_conto_code, tab2.oper_ep_code, tab2.oper_ep_desc,
tab3.classif_code, tab3.classif_desc
FROM tab1
LEFT JOIN tab2 ON tab1.causale_ep_id = tab2.causale_ep_id
LEFT JOIN tab3 ON tab1.causale_ep_id = tab3.causale_ep_id;