/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE VIEW siac.siac_v_dwh_max_aggiornamento_scarichi_massivi (
tabella,
data_elaborazione,
ente_proprietario_id)
AS
SELECT 'siac_dwh_accertamento'::text AS tabella,
max(siac_dwh_accertamento.data_elaborazione),
siac_dwh_accertamento.ente_proprietario_id,
siac_dwh_accertamento.bil_anno
FROM siac_dwh_accertamento
group by siac_dwh_accertamento.ente_proprietario_id,
siac_dwh_accertamento.bil_anno
UNION
SELECT 'siac_dwh_capitolo_entrata'::text AS tabella,
max(siac_dwh_capitolo_entrata.data_elaborazione),
siac_dwh_capitolo_entrata.ente_proprietario_id,
siac_dwh_capitolo_entrata.bil_anno
FROM siac_dwh_capitolo_entrata
group by 
siac_dwh_capitolo_entrata.ente_proprietario_id,
siac_dwh_capitolo_entrata.bil_anno
UNION
SELECT 'siac_dwh_capitolo_spesa'::text AS tabella,
max(siac_dwh_capitolo_spesa.data_elaborazione),
siac_dwh_capitolo_spesa.ente_proprietario_id,
siac_dwh_capitolo_spesa.bil_anno
FROM siac_dwh_capitolo_spesa
group by siac_dwh_capitolo_spesa.ente_proprietario_id,
siac_dwh_capitolo_spesa.bil_anno
UNION
SELECT 'siac_dwh_contabilita_generale'::text AS tabella,
max(siac_dwh_contabilita_generale.data_elaborazione),
siac_dwh_contabilita_generale.ente_proprietario_id,
siac_dwh_contabilita_generale.bil_anno
from siac_dwh_contabilita_generale
group by siac_dwh_contabilita_generale.ente_proprietario_id,
siac_dwh_contabilita_generale.bil_anno
UNION
SELECT 'siac_dwh_documento_entrata'::text AS tabella,
max(siac_dwh_documento_entrata.data_elaborazione),
siac_dwh_documento_entrata.ente_proprietario_id
,to_char (now(),'YYYY') bil_anno
FROM siac_dwh_documento_entrata
group by
siac_dwh_documento_entrata.ente_proprietario_id
UNION
SELECT 'siac_dwh_documento_spesa'::text AS tabella,
max(siac_dwh_documento_spesa.data_elaborazione),
siac_dwh_documento_spesa.ente_proprietario_id
,to_char (now(),'YYYY') bil_anno
FROM siac_dwh_documento_spesa
group by siac_dwh_documento_spesa.ente_proprietario_id
UNION
SELECT 'siac_dwh_impegno'::text AS tabella,
max(siac_dwh_impegno.data_elaborazione),
siac_dwh_impegno.ente_proprietario_id,
siac_dwh_impegno.bil_anno
FROM siac_dwh_impegno
group by 
siac_dwh_impegno.ente_proprietario_id,
siac_dwh_impegno.bil_anno
UNION
SELECT 'siac_dwh_iva'::text AS tabella,
max(siac_dwh_iva.data_elaborazione),
siac_dwh_iva.ente_proprietario_id
,to_char (now(),'YYYY') bil_anno
from siac_dwh_iva
group by siac_dwh_iva.ente_proprietario_id
UNION
SELECT 'siac_dwh_liquidazione'::text AS tabella,
max(siac_dwh_liquidazione.data_elaborazione),
siac_dwh_liquidazione.ente_proprietario_id,
siac_dwh_liquidazione.bil_anno
FROM siac_dwh_liquidazione
group by siac_dwh_liquidazione.ente_proprietario_id,
siac_dwh_liquidazione.bil_anno
UNION
SELECT 'siac_dwh_ordinativo_incasso'::text AS tabella,
max(siac_dwh_ordinativo_incasso.data_elaborazione),
siac_dwh_ordinativo_incasso.ente_proprietario_id,
siac_dwh_ordinativo_incasso.bil_anno
FROM siac_dwh_ordinativo_incasso
group by siac_dwh_ordinativo_incasso.ente_proprietario_id,
siac_dwh_ordinativo_incasso.bil_anno
UNION
SELECT 'siac_dwh_ordinativo_pagamento'::text AS tabella,
max(siac_dwh_ordinativo_pagamento.data_elaborazione),
siac_dwh_ordinativo_pagamento.ente_proprietario_id,
siac_dwh_ordinativo_pagamento.bil_anno
FROM siac_dwh_ordinativo_pagamento
group by siac_dwh_ordinativo_pagamento.ente_proprietario_id,
siac_dwh_ordinativo_pagamento.bil_anno
UNION
SELECT 'siac_dwh_programma'::text AS tabella,
max(siac_dwh_programma.data_elaborazione),
siac_dwh_programma.ente_proprietario_id,
to_char (now(),'YYYY') bil_anno
FROM siac_dwh_programma
group by siac_dwh_programma.ente_proprietario_id
UNION
SELECT 'siac_dwh_soggetto'::text AS tabella,
max(siac_dwh_soggetto.data_elaborazione),
siac_dwh_soggetto.ente_proprietario_id,
to_char (now(),'YYYY') bil_anno
FROM siac_dwh_soggetto
group by siac_dwh_soggetto.ente_proprietario_id
UNION
SELECT 'siac_dwh_vincolo'::text AS tabella,
max(siac_dwh_vincolo.data_elaborazione),
siac_dwh_vincolo.ente_proprietario_id,
siac_dwh_vincolo.bil_anno
FROM siac_dwh_vincolo
group by siac_dwh_vincolo.ente_proprietario_id,
siac_dwh_vincolo.bil_anno
UNION
SELECT 'siac_dwh_subaccertamento'::text AS tabella,
max(siac_dwh_subaccertamento.data_elaborazione),
siac_dwh_subaccertamento.ente_proprietario_id,
siac_dwh_subaccertamento.bil_anno
FROM siac_dwh_subaccertamento
group by siac_dwh_subaccertamento.ente_proprietario_id,
siac_dwh_subaccertamento.bil_anno
UNION
SELECT 'siac_dwh_subimpegno'::text AS tabella,
max(siac_dwh_subimpegno.data_elaborazione),
siac_dwh_subimpegno.ente_proprietario_id,
siac_dwh_subimpegno.bil_anno
FROM siac_dwh_subimpegno
group by siac_dwh_subimpegno.ente_proprietario_id,
siac_dwh_subimpegno.bil_anno
UNION
SELECT 'siac_dwh_subordinativo_incasso'::text AS tabella,
max(siac_dwh_subordinativo_incasso.data_elaborazione),
siac_dwh_subordinativo_incasso.ente_proprietario_id,
siac_dwh_subordinativo_incasso.bil_anno
FROM siac_dwh_subordinativo_incasso
group by siac_dwh_subordinativo_incasso.ente_proprietario_id,
siac_dwh_subordinativo_incasso.bil_anno
UNION
SELECT 'siac_dwh_subordinativo_pagamento'::text AS tabella,
max(siac_dwh_subordinativo_pagamento.data_elaborazione),
siac_dwh_subordinativo_pagamento.ente_proprietario_id,
siac_dwh_subordinativo_pagamento.bil_anno
FROM siac_dwh_subordinativo_pagamento
group by siac_dwh_subordinativo_pagamento.ente_proprietario_id,
siac_dwh_subordinativo_pagamento.bil_anno
