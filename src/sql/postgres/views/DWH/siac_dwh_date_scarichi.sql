/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE or replace VIEW siac.siac_dwh_date_scarichi (
    ente_proprietario_id,
    data_elaborazione_min,
    data_elaborazione_max,
    aggiornato,
    data_aggiornamento)
AS
SELECT a.ente_proprietario_id,
            min(a.data_elaborazione) AS data_elaborazione_min,
            max(a.data_elaborazione) AS data_elaborazione_max,
            'no'::text AS aggiornato,
            max(a.data_elaborazione) AS data_aggiornamento
FROM siac_v_dwh_max_aggiornamento_scarichi_massivi a
WHERE 
a.bil_anno=to_char (now(),'YYYY')
and
NOT EXISTS (
    SELECT 1
    FROM siac_v_dwh_max_aggiornamento_scarichi_massivi a2
    WHERE a2.ente_proprietario_id = a.ente_proprietario_id AND a2.tabella =
        a.tabella AND a2.data_elaborazione >= (date_trunc('day'::text, now()) - '05:00:00'::interval)
    )
GROUP BY a.ente_proprietario_id
UNION
SELECT a.ente_proprietario_id,
            min(a.data_elaborazione) AS data_elaborazione_min,
            max(a.data_elaborazione) AS data_elaborazione_max,
            'si'::text AS aggiornato,
            max(a.data_elaborazione) AS data_aggiornamento
FROM siac_v_dwh_max_aggiornamento_scarichi_massivi a
WHERE NOT (a.ente_proprietario_id IN (
    SELECT DISTINCT a.ente_proprietario_id
    FROM siac_v_dwh_max_aggiornamento_scarichi_massivi a
    WHERE a.bil_anno=to_char (now(),'YYYY')
and NOT EXISTS (
        SELECT 1
        FROM siac_v_dwh_max_aggiornamento_scarichi_massivi a2
        WHERE a2.ente_proprietario_id = a.ente_proprietario_id AND a2.tabella =
            a.tabella AND a2.data_elaborazione >= (date_trunc('day'::text, now()) - '05:00:00'::interval)
        )
    ))
GROUP BY a.ente_proprietario_id;