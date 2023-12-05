/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop view if exists siac.siac_v_dwh_vincoli_movgest;
CREATE OR REPLACE VIEW siac.siac_v_dwh_vincoli_movgest
(
    ente_proprietario_id,
    bil_code,
    anno_bilancio,
    programma_code,
    programma_desc,
    tipo_da,
    anno_da,
    numero_da,
    tipo_a,
    anno_a,
    numero_a,
    importo_vincolo,
    tipo_avanzo_vincolo,
    -- 23.02.2021 Sofia Jira SIAC-8920
    movgest_ts_r_id,
    importo_pending
    )
AS
-- 23.02.2021 Sofia Jira SIAC-8920
select query_vincoli.*,
       coalesce(pending.importo_pending,0) importo_pending

from
(
SELECT bil.ente_proprietario_id,
       bil.bil_code,
       periodo.anno AS anno_bilancio,
       progetto.programma_code, progetto.programma_desc,
       movtipoda.movgest_tipo_code AS tipo_da,  -- accertamento
       movda.movgest_anno AS anno_da,
       movda.movgest_numero AS numero_da,
       movtipoa.movgest_tipo_code AS tipo_a,    -- impegno
       mova.movgest_anno AS anno_a,
       mova.movgest_numero AS numero_a,
       a.movgest_ts_importo AS importo_vincolo,
       dat.avav_tipo_code AS tipo_avanzo_vincolo,
       -- 23.02.2021 Sofia Jira SIAC-8920
       a.movgest_ts_r_id
FROM siac_r_movgest_ts a
     JOIN siac_t_movgest_ts movtsa ON a.movgest_ts_b_id = movtsa.movgest_ts_id -- impegno
     JOIN siac_t_movgest mova ON mova.movgest_id = movtsa.movgest_id
     JOIN siac_d_movgest_tipo movtipoa ON movtipoa.movgest_tipo_id = mova.movgest_tipo_id
     JOIN siac_t_bil bil ON bil.bil_id = mova.bil_id
     JOIN siac_t_periodo periodo ON bil.periodo_id = periodo.periodo_id
     LEFT JOIN siac_t_movgest_ts movtsda ON  -- accertamento
               a.movgest_ts_a_id = movtsda.movgest_ts_id AND movtsda.data_cancellazione IS NULL
     LEFT JOIN siac_t_movgest movda ON
               movda.movgest_id = movtsda.movgest_id AND movda.data_cancellazione IS NULL
     LEFT JOIN siac_d_movgest_tipo movtipoda ON movtipoda.movgest_tipo_id = movda.movgest_tipo_id AND movtipoda.data_cancellazione IS NULL
     LEFT JOIN siac_r_movgest_ts_programma rprogramma ON
               rprogramma.movgest_ts_id = movtsa.movgest_ts_id AND rprogramma.data_cancellazione IS NULL
     LEFT JOIN siac_t_programma progetto ON
               progetto.programma_id = rprogramma.programma_id AND progetto.data_cancellazione IS NULL
     LEFT JOIN siac_t_avanzovincolo ta ON ta.avav_id = a.avav_id AND ta.data_cancellazione IS NULL
     LEFT JOIN siac_d_avanzovincolo_tipo dat ON dat.avav_tipo_id =   ta.avav_tipo_id AND dat.data_cancellazione IS NULL
WHERE a.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   movtsa.data_cancellazione IS NULL
AND   movtsa.validita_fine IS NULL
AND   mova.data_cancellazione IS NULL
AND   mova.validita_fine IS NULL
AND   movtipoa.data_cancellazione IS NULL
AND   movtipoa.validita_fine IS NULL
AND   bil.data_cancellazione IS NULL
AND   periodo.data_cancellazione IS NULL
--UNION -- 28.09.2018 Sofia Jira SIAC-6427 - inverto da, a per avere casi di accertamento (a) senza impegno (da)
UNION ALL -- 18.03.2019 Sofia Jira SIAC-6736
SELECT bil.ente_proprietario_id,
       bil.bil_code, periodo.anno AS anno_bilancio,
       progetto.programma_code, progetto.programma_desc,
       movtipoda.movgest_tipo_code AS tipo_da, -- impegno
       movda.movgest_anno AS anno_da,
       movda.movgest_numero AS numero_da,
       movtipoa.movgest_tipo_code AS tipo_a, -- accertamento
       mova.movgest_anno AS anno_a,
       mova.movgest_numero AS numero_a,
       a.movgest_ts_importo AS importo_vincolo,
       dat.avav_tipo_code AS tipo_avanzo_vincolo,
       -- 23.02.2021 Sofia Jira SIAC-8920
       a.movgest_ts_r_id
FROM siac_r_movgest_ts a
     JOIN siac_t_movgest_ts movtsa ON a.movgest_ts_a_id = movtsa.movgest_ts_id -- accertamento
     JOIN siac_t_movgest mova ON mova.movgest_id = movtsa.movgest_id
     JOIN siac_d_movgest_tipo movtipoa ON movtipoa.movgest_tipo_id = mova.movgest_tipo_id
     JOIN siac_t_bil bil ON bil.bil_id = mova.bil_id
     JOIN siac_t_periodo periodo ON bil.periodo_id = periodo.periodo_id
     LEFT JOIN siac_t_movgest_ts movtsda ON  -- impegno
               a.movgest_ts_b_id = movtsda.movgest_ts_id AND movtsda.data_cancellazione IS NULL
     LEFT JOIN siac_t_movgest movda ON
               movda.movgest_id = movtsda.movgest_id AND movda.data_cancellazione IS NULL
     LEFT JOIN siac_d_movgest_tipo movtipoda ON
               movtipoda.movgest_tipo_id = movda.movgest_tipo_id AND movtipoda.data_cancellazione IS NULL
     LEFT JOIN siac_r_movgest_ts_programma rprogramma ON
               rprogramma.movgest_ts_id = movtsa.movgest_ts_id AND rprogramma.data_cancellazione IS NULL
     LEFT JOIN siac_t_programma progetto ON
               progetto.programma_id = rprogramma.programma_id AND progetto.data_cancellazione IS NULL
     LEFT JOIN siac_t_avanzovincolo ta ON
               ta.avav_id = a.avav_id AND ta.data_cancellazione IS NULL
     LEFT JOIN siac_d_avanzovincolo_tipo dat ON
               dat.avav_tipo_id = ta.avav_tipo_id AND dat.data_cancellazione IS NULL
WHERE a.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   movtsa.data_cancellazione IS NULL
AND   movtsa.validita_fine IS NULL
AND   mova.data_cancellazione IS NULL
AND   mova.validita_fine IS NULL
AND   movtipoa.data_cancellazione IS NULL
AND   movtipoa.validita_fine IS NULL
AND   bil.data_cancellazione IS NULL
AND   periodo.data_cancellazione IS NULL
) query_vincoli
  left join siac_t_vincolo_pending pending on (pending.movgest_ts_r_id=query_vincoli.movgest_ts_r_id and pending.data_cancellazione is null);
alter view siac.siac_v_dwh_vincoli_movgest owner to siac;