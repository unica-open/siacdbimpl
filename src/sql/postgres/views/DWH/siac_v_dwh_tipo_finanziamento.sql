/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_tipo_finanziamento (
    cod_tipo_finanziamento,
    desc_tipo_finanziamento,
    ente_proprietario_id,
    validita_inizio,
    validita_fine)
AS
SELECT a.classif_code AS cod_tipo_finanziamento,
    a.classif_desc AS desc_tipo_finanziamento, a.ente_proprietario_id,
    a.validita_inizio, a.validita_fine
FROM siac_t_class a, siac_d_class_tipo b
WHERE b.classif_tipo_code::text = 'TIPO_FINANZIAMENTO'::text AND
    a.classif_tipo_id = b.classif_tipo_id AND a.data_cancellazione IS NULL AND a.ente_proprietario_id = b.ente_proprietario_id;