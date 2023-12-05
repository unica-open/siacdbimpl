/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_allegato_atto_flux (
    attoamm_anno,
    attoamm_numero,
    attoamm_tipo_code,
    tipo_sac_atto_amm,
    sac_atto_amm,
    stato_atto_allegato,
    stato_desc_atto_allegato,
    validita_stato_atto_allegato,
    attoal_causale,
    attoal_data_invio_firma,
    ente_proprietario_id)
AS
SELECT d.attoamm_anno, d.attoamm_numero, e.attoamm_tipo_code,
    z.classif_tipo_code AS tipo_sac_atto_amm, y.classif_code AS sac_atto_amm,
    c.attoal_stato_code AS stato_atto_allegato,
    c.attoal_stato_desc AS stato_desc_atto_allegato,
    b.validita_inizio AS validita_stato_atto_allegato, a.attoal_causale,
    a.attoal_data_invio_firma, a.ente_proprietario_id
FROM siac_t_atto_allegato a, siac_r_atto_allegato_stato b,
    siac_d_atto_allegato_stato c,
    siac_t_atto_amm d
   LEFT JOIN siac_r_atto_amm_class x ON x.attoamm_id = d.attoamm_id AND
       x.data_cancellazione IS NULL
   LEFT JOIN siac_t_class y ON x.classif_id = y.classif_id
   LEFT JOIN siac_d_class_tipo z ON z.classif_tipo_id = y.classif_tipo_id AND
       (z.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])),
    siac_d_atto_amm_tipo e
WHERE a.attoal_id = b.attoal_id AND b.attoal_stato_id = c.attoal_stato_id AND
    b.data_cancellazione IS NULL AND b.validita_fine IS NULL AND a.attoamm_id = d.attoamm_id AND e.attoamm_tipo_id = d.attoamm_tipo_id;