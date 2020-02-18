/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_conto_tesoreria (
    cod_conto_tesoreria,
    desc_conto_tesoreria,
    ente_proprietario_id,
    validita_inizio,
    validita_fine)
AS
SELECT a.contotes_code AS cod_conto_tesoreria,
    a.contotes_desc AS desc_conto_tesoreria, a.ente_proprietario_id,
    a.validita_inizio, a.validita_fine
FROM siac_d_contotesoreria a;
