/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_stato_liquidazione (
    cod_stato_liquidazione,
    desc_stato_liquidazione,
    ente_proprietario_id)
AS
SELECT a.liq_stato_code AS cod_stato_liquidazione,
    a.liq_stato_desc AS desc_stato_liquidazione, a.ente_proprietario_id
FROM siac_d_liquidazione_stato a;