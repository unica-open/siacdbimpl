/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop VIEW siac.siac_v_dwh_provvisori_cassa_ord;

CREATE OR REPLACE VIEW siac.siac_v_dwh_provvisori_cassa_ord (
ente_proprietario_id,
provc_tipo_code,
provc_tipo_desc,
provc_anno,
provc_numero,
ord_anno,
ord_numero,
importo_reg,
ord_id)--, 29.05.2017 Sofia HD-INC000001787981
--num_subord)
AS
SELECT tb.ente_proprietario_id, tb.provc_tipo_code, tb.provc_tipo_desc,
tb.provc_anno, tb.provc_numero, tb.ord_anno, tb.ord_numero,
tb.ord_provc_importo AS importo_reg, tb.ord_id--, e.ord_ts_code AS num_subord29.05.2017 Sofia HD-INC000001787981
FROM (
SELECT a.ente_proprietario_id, b.provc_tipo_code, b.provc_tipo_desc,
a.provc_anno, a.provc_numero, d.ord_anno, d.ord_numero,
c.ord_provc_importo, d.ord_id
FROM siac_t_prov_cassa a, siac_d_prov_cassa_tipo b,
siac_r_ordinativo_prov_cassa c, siac_t_ordinativo d
WHERE
a.provc_tipo_id = b.provc_tipo_id
AND c.provc_id = a.provc_id
AND d.ord_id = c.ord_id
AND now() between c.validita_inizio and COALESCE(c.validita_fine,now())
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND c.data_cancellazione IS NULL
AND d.data_cancellazione IS NULL
) tb
-- LEFT JOIN siac_t_ordinativo_ts e ON e.ord_id = tb.ord_id 29.05.2017 Sofia HD-INC000001787981
ORDER BY tb.ente_proprietario_id;