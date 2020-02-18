/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_distinta (
    cod_distinta,
    desc_distinta,
    cod_tipo_distinta,
    desc_tipo_distinta,
    ente_proprietario_id,
    validita_inizio,
    validita_fine)
AS
SELECT a.dist_code AS cod_distinta, a.dist_desc AS desc_distinta,
    b.dist_tipo_code AS cod_tipo_distinta,
    b.dist_tipo_desc AS desc_tipo_distinta, a.ente_proprietario_id,
    a.validita_inizio, a.validita_fine
FROM siac_d_distinta a, siac_d_distinta_tipo b
WHERE a.dist_tipo_id = b.dist_tipo_id;