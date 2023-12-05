/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop VIEW if exists siac.siac_v_dwh_pdce;
CREATE OR REPLACE VIEW siac.siac_v_dwh_pdce (
    ente_proprietario_id,
    pdce_conto_code,
    pdce_conto_desc,
    pdce_ct_tipo_code,
    pdce_ct_tipo_desc,
    pdce_fam_code,
    pdce_fam_desc,
    classif_id,
    ambito_code,
    ambito_desc,
    livello,
    conto_foglia,
    -- 17.02.2021 Sofia SIAC-7907
    validita_inizio,
    validita_fine
    )
AS
SELECT tpc.ente_proprietario_id, tpc.pdce_conto_code, tpc.pdce_conto_desc,
    dpct.pdce_ct_tipo_code, dpct.pdce_ct_tipo_desc, dpf.pdce_fam_code,
    dpf.pdce_fam_desc, rpcc.classif_id, da.ambito_code, da.ambito_desc,
    tpc.livello, tabattr."boolean",
    -- 17.02.2021 Sofia SIAC-7907
    tpc.validita_inizio,
    tpc.validita_fine
FROM siac_t_pdce_conto tpc
   JOIN siac_d_pdce_conto_tipo dpct ON dpct.pdce_ct_tipo_id = tpc.pdce_ct_tipo_id
   JOIN siac_t_pdce_fam_tree tpft ON tpft.pdce_fam_tree_id = tpc.pdce_fam_tree_id
   JOIN siac_d_pdce_fam dpf ON dpf.pdce_fam_id = tpft.pdce_fam_id
   JOIN siac_d_ambito da ON da.ambito_id = dpf.ambito_id
   LEFT JOIN siac_r_pdce_conto_class rpcc ON rpcc.pdce_conto_id = tpc.pdce_conto_id
        AND rpcc.data_cancellazione IS NULL
        AND date_trunc('day'::text, now()) > rpcc.validita_inizio
        AND (date_trunc('day'::text, now()) < rpcc.validita_fine OR rpcc.validita_fine IS NULL)
   LEFT JOIN (SELECT pca.pdce_conto_id, pca."boolean"
              FROM  siac_r_pdce_conto_attr pca
              INNER JOIN siac_t_attr ta ON ta.attr_id = pca.attr_id
              WHERE ta.attr_code = 'pdce_conto_foglia'
              AND pca.data_cancellazione IS NULL
              AND ta.data_cancellazione IS NULL
              AND date_trunc('day'::text, now()) > pca.validita_inizio
              AND (date_trunc('day'::text, now()) < pca.validita_fine OR pca.validita_fine IS NULL)
             ) tabattr ON tabattr.pdce_conto_id = tpc.pdce_conto_id
WHERE tpc.data_cancellazione IS NULL
AND dpct.data_cancellazione IS NULL
AND tpft.data_cancellazione IS NULL
AND dpf.data_cancellazione IS NULL;
alter VIEW siac.siac_v_dwh_pdce owner to siac;