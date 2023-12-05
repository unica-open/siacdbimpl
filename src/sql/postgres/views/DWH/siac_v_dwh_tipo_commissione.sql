/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_tipo_commissione (
    cod_tipo_commissione,
    desc_tipo_commissione,
    ente_proprietario_id,
    validita_inizio,
    validita_fine)
AS
SELECT a.comm_tipo_code AS cod_tipo_commissione,
    a.comm_tipo_desc AS desc_tipo_commissione, a.ente_proprietario_id,
    a.validita_inizio, a.validita_fine
FROM siac_d_commissione_tipo a;