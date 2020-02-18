/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_atto_amministrativo (
    ente_proprietario_id,
    anno_atto_amministrativo,
    numero_atto_amministrativo,
    oggetto_atto_amministrativo,
    note_atto_amministrativo,
    parere_regolarita_contabile,
    cod_cdc_atto_amministrativo,
    desc_cdc_atto_amministrativo,
    cod_cdr_atto_amministrativo,
    desc_cdr_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    desc_tipo_atto_amministrativo,
    cod_stato_atto_amministrativo,
    desc_stato_atto_amministrativo)
AS
SELECT a.ente_proprietario_id, a.attoamm_anno AS anno_atto_amministrativo,
    a.attoamm_numero AS numero_atto_amministrativo,
    a.attoamm_oggetto AS oggetto_atto_amministrativo,
    a.attoamm_note AS note_atto_amministrativo, a.parere_regolarita_contabile,
        CASE
            WHEN f.classif_id_padre IS NOT NULL THEN g1.classif_code
            ELSE NULL::character varying
        END AS cod_cdc_atto_amministrativo,
        CASE
            WHEN f.classif_id_padre IS NOT NULL THEN g1.classif_desc
            ELSE NULL::character varying
        END AS desc_cdc_atto_amministrativo,
        CASE
            WHEN f.classif_id_padre IS NOT NULL THEN g2.classif_code
            ELSE g1.classif_code
        END AS cod_cdr_atto_amministrativo,
        CASE
            WHEN f.classif_id_padre IS NOT NULL THEN g2.classif_desc
            ELSE g1.classif_desc
        END AS desc_cdr_atto_amministrativo,
    d.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
    d.attoamm_tipo_desc AS desc_tipo_atto_amministrativo,
    c.attoamm_stato_code AS cod_stato_atto_amministrativo,
    c.attoamm_stato_desc AS desc_stato_atto_amministrativo
FROM siac_t_atto_amm a
   JOIN siac_r_atto_amm_stato b ON a.attoamm_id = b.attoamm_id
   JOIN siac_d_atto_amm_stato c ON b.attoamm_stato_id = c.attoamm_stato_id
   JOIN siac_d_atto_amm_tipo d ON a.attoamm_tipo_id = d.attoamm_tipo_id
   LEFT JOIN siac_r_atto_amm_class e ON e.attoamm_id = a.attoamm_id AND
       e.data_cancellazione IS NULL
   LEFT JOIN siac_r_class_fam_tree f ON e.classif_id = f.classif_id AND
       f.data_cancellazione IS NULL
   LEFT JOIN siac_t_class g1 ON f.classif_id = g1.classif_id AND
       g1.data_cancellazione IS NULL
   LEFT JOIN siac_t_class g2 ON f.classif_id_padre = g2.classif_id AND
       g1.data_cancellazione IS NULL
WHERE a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND
    c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL;