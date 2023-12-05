/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE VIEW siac.siac_v_dwh_ricevuta_ordinativo
(
  ente_proprietario_id,
  bil_anno_ord,
  anno_ord,
  num_ord,
  cod_stato_ord,
  desc_stato_ord,
  cod_tipo_ord,
  desc_tipo_ord,
  data_ricevuta_ord,
  numero_ricevuta_ord,
  importo_ricevuta_ord,
  tipo_ricevuta_ord,
  validita_inizio,
  validita_fine
)
AS
SELECT
    tep.ente_proprietario_id, tp.anno AS bil_anno_ord,
    sto.ord_anno AS anno_ord, sto.ord_numero AS num_ord,
    dos.ord_stato_code AS cod_stato_ord,
    dos.ord_stato_desc AS desc_stato_ord,
    dot.ord_tipo_code AS cod_tipo_ord,
    dot.ord_tipo_desc AS desc_tipo_ord,
    roq.ord_quietanza_data AS data_ricevuta_ord,
    roq.ord_quietanza_numero AS numero_ricevuta_ord,
    roq.ord_quietanza_importo AS importo_ricevuta_ord,
    'Q'::text AS tipo_ricevuta_ord,
--    ros.validita_inizio,
--    ros.validita_fine
	-- 30.04.2021 Sofia Jira SIAC-8074
  roq.validita_inizio,
  roq.validita_fine

FROM siac_t_ordinativo sto
  JOIN siac_t_bil tb ON sto.bil_id = tb.bil_id
  JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
  JOIN siac_t_ente_proprietario tep ON tep.ente_proprietario_id = sto.ente_proprietario_id
  JOIN siac_d_ordinativo_tipo dot ON sto.ord_tipo_id = dot.ord_tipo_id
  JOIN siac_r_ordinativo_stato ros ON ros.ord_id = sto.ord_id
  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
  JOIN siac_r_ordinativo_quietanza roq ON roq.ord_id = sto.ord_id AND roq.data_cancellazione IS NULL
WHERE sto.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   tep.data_cancellazione IS NULL
AND   dot.data_cancellazione IS NULL
AND   ros.data_cancellazione IS NULL
AND   dos.data_cancellazione IS NULL
-- 26.10.2018 jira siac-6477
and   ros.validita_fine is  null
UNION ALL
SELECT
  tep.ente_proprietario_id, tp.anno AS bil_anno_ord,
  sto.ord_anno AS anno_ord, sto.ord_numero AS num_ord,
  dos.ord_stato_code AS cod_stato_ord,
  dos.ord_stato_desc AS desc_stato_ord,
  dot.ord_tipo_code AS cod_tipo_ord,
  dot.ord_tipo_desc AS desc_tipo_ord,
  os.ord_storno_data AS data_ricevuta_ord,
  os.ord_storno_numero AS numero_ricevuta_ord,
  os.ord_storno_importo AS importo_ricevuta_ord,
  'S'::text AS tipo_ricevuta_ord,
--  ros.validita_inizio,
--  ros.validita_fine
-- 30.04.2021 Sofia Jira SIAC-8074
  os.validita_inizio,
  os.validita_fine
FROM siac_t_ordinativo sto
  JOIN siac_t_bil tb ON sto.bil_id = tb.bil_id
  JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
  JOIN siac_t_ente_proprietario tep ON tep.ente_proprietario_id =  sto.ente_proprietario_id
  JOIN siac_d_ordinativo_tipo dot ON sto.ord_tipo_id = dot.ord_tipo_id
  JOIN siac_r_ordinativo_stato ros ON ros.ord_id = sto.ord_id
  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
  JOIN siac_r_ordinativo_storno os ON os.ord_id = sto.ord_id AND  os.data_cancellazione IS NULL
WHERE sto.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   tep.data_cancellazione IS NULL
AND   dot.data_cancellazione IS NULL
AND   ros.data_cancellazione IS NULL
AND   dos.data_cancellazione IS NULL
-- 26.10.2018 jira siac-6477
and   ros.validita_fine is null;
