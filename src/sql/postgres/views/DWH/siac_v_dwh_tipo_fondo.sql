/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_tipo_fondo (
    cod_tipo_fondo,
    desc_tipo_fondo,
    ente_proprietario_id,
    validita_inizio,
    validita_fine)
AS
SELECT a.classif_code AS cod_tipo_fondo, a.classif_desc AS desc_tipo_fondo,
    a.ente_proprietario_id, a.validita_inizio, a.validita_fine
FROM siac_t_class a, siac_d_class_tipo b
WHERE b.classif_tipo_code::text = 'TIPO_FONDO'::text AND a.classif_tipo_id =
    b.classif_tipo_id AND a.data_cancellazione IS NULL AND a.ente_proprietario_id = b.ente_proprietario_id;