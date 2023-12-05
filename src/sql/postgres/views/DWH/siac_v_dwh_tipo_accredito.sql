/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_tipo_accredito (
    cod_tipo_accredito,
    desc_tipo_accredito,
    ente_proprietario_id,
    validita_inizio,
    validita_fine)
AS
SELECT a.accredito_tipo_code AS cod_tipo_accredito,
    a.accredito_tipo_desc AS desc_tipo_accredito, a.ente_proprietario_id,
    a.validita_inizio, a.validita_fine
FROM siac_d_accredito_tipo a
WHERE a.data_cancellazione IS NULL;