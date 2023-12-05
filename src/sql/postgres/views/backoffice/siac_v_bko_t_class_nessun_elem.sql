/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_t_class_nessun_elem (
    classif_tipo_id,
    classif_tipo_code,
    classif_tipo_desc,
    validita_inizio,
    validita_fine,
    ente_proprietario_id,
    data_creazione,
    data_modifica,
    data_cancellazione,
    login_operazione)
AS
SELECT a.classif_tipo_id, a.classif_tipo_code, a.classif_tipo_desc,
    a.validita_inizio, a.validita_fine, a.ente_proprietario_id,
    a.data_creazione, a.data_modifica, a.data_cancellazione, a.login_operazione
FROM siac_d_class_tipo a
WHERE NOT (EXISTS (
    SELECT 1
    FROM siac_t_class c
    WHERE c.classif_tipo_id = a.classif_tipo_id
    )) AND a.classif_tipo_desc::text !~~ '%Ordinativ%'::text;