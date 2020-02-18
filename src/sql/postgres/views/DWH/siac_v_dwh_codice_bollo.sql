/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_codice_bollo (
    cod_codice_bollo,
    desc_codice_bollo,
    ente_proprietario_id,
    validita_inizio,
    validita_fine)
AS
SELECT a.codbollo_code AS cod_codice_bollo,
    a.codbollo_desc AS desc_codice_bollo, a.ente_proprietario_id,
    a.validita_inizio, a.validita_fine
FROM siac_d_codicebollo a;