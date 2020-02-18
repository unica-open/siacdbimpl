/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_bil_no_fase_operativa (
    bil_id,
    bil_code,
    bil_desc,
    bil_tipo_id,
    periodo_id,
    validita_inizio,
    validita_fine,
    ente_proprietario_id,
    data_creazione,
    data_modifica,
    data_cancellazione,
    login_operazione)
AS
SELECT b.bil_id, b.bil_code, b.bil_desc, b.bil_tipo_id, b.periodo_id,
    b.validita_inizio, b.validita_fine, b.ente_proprietario_id,
    b.data_creazione, b.data_modifica, b.data_cancellazione, b.login_operazione
FROM siac_t_bil b
WHERE NOT (EXISTS (
    SELECT 1
    FROM siac_r_bil_fase_operativa a
    WHERE a.bil_id = b.bil_id
    ));