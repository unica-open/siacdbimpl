/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_accert_classe (
    ente_proprietario_id,
    bil_anno_classe,
    anno_accertamento_classe,
    num_accertamento_classe,
    cod_movgest_ts_classe,
    desc_movgest_ts_classe,
    tipo_movgest_ts_classe,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    cod_soggetto_classe_old,
    desc_soggetto_classe_old,
    cod_tipo_sog_classe_old,
    desc_tipo_sog_classe_old,
    cod_soggetto_classe_new,
    desc_soggetto_classe_new,
    cod_tipo_sog_classe_new,
    desc_tipo_sog_classe_new,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    desc_stato_modifica,
    data_creazione -- 30.08.2018 Sofia jira-6292
    )
AS
 WITH a AS (
SELECT tm.ente_proprietario_id, tm.mod_num, tm.mod_desc,
            dms.mod_stato_code, dmt.mod_tipo_code, dmt.mod_tipo_desc,
            tam.attoamm_anno, tam.attoamm_numero, daat.attoamm_tipo_code,
            tp.anno, stm.movgest_anno, stm.movgest_numero, tmt.movgest_ts_code,
            tmt.movgest_ts_desc, dmtt.movgest_ts_tipo_code,
            dsc1.soggetto_classe_code AS cod_soggetto_classe_old,
            dsc1.soggetto_classe_desc AS desc_soggetto_classe_old,
            dsct1.soggetto_classe_tipo_code AS cod_tipo_sog_classe_old,
            dsct1.soggetto_classe_tipo_desc AS desc_tipo_sog_classe_old,
            dsc2.soggetto_classe_code AS cod_soggetto_classe_new,
            dsc2.soggetto_classe_desc AS desc_soggetto_classe_new,
            dsct2.soggetto_classe_tipo_code AS cod_tipo_sog_classe_new,
            dsct2.soggetto_classe_tipo_desc AS desc_tipo_sog_classe_new,
            tam.attoamm_id,
            dms.mod_stato_desc,
            tm.data_creazione -- 30.08.2018 Sofia jira-6292
FROM siac_r_movgest_ts_sogclasse_mod mtsm
      JOIN siac_r_modifica_stato rms ON rms.mod_stato_r_id = mtsm.mod_stato_r_id
   JOIN siac_t_modifica tm ON tm.mod_id = rms.mod_id
   JOIN siac_d_modifica_stato dms ON dms.mod_stato_id = rms.mod_stato_id
   LEFT JOIN siac_d_modifica_tipo dmt ON dmt.mod_tipo_id = tm.mod_tipo_id AND
       dmt.data_cancellazione IS NULL
   JOIN siac_t_atto_amm tam ON tam.attoamm_id = tm.attoamm_id
   JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id = tam.attoamm_tipo_id
   JOIN siac_t_movgest_ts tmt ON tmt.movgest_ts_id = mtsm.movgest_ts_id
   JOIN siac_d_soggetto_classe dsc1 ON dsc1.soggetto_classe_id =
       mtsm.soggetto_classe_id_old
   JOIN siac_d_soggetto_classe dsc2 ON dsc2.soggetto_classe_id =
       mtsm.soggetto_classe_id_new
   JOIN siac_d_soggetto_classe_tipo dsct1 ON dsct1.soggetto_classe_tipo_id =
       dsc1.soggetto_classe_tipo_id
   JOIN siac_d_soggetto_classe_tipo dsct2 ON dsct2.soggetto_classe_tipo_id =
       dsc2.soggetto_classe_tipo_id
   JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id
   JOIN siac_t_movgest stm ON stm.movgest_id = tmt.movgest_id
   JOIN siac_d_movgest_tipo sdmt ON sdmt.movgest_tipo_id = stm.movgest_tipo_id
   JOIN siac_t_bil tb ON tb.bil_id = stm.bil_id
   JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
WHERE sdmt.movgest_tipo_code::text = 'A'::text AND mtsm.data_cancellazione IS
    NULL AND rms.data_cancellazione IS NULL AND tm.data_cancellazione IS NULL AND dms.data_cancellazione IS NULL AND dmt.data_cancellazione IS NULL AND tam.data_cancellazione IS NULL AND daat.data_cancellazione IS NULL AND tmt.data_cancellazione IS NULL AND dsc1.data_cancellazione IS NULL AND dsc2.data_cancellazione IS NULL AND dsct1.data_cancellazione IS NULL AND dsct2.data_cancellazione IS NULL AND dmtt.data_cancellazione IS NULL AND tm.data_cancellazione IS NULL AND dmt.data_cancellazione IS NULL AND tb.data_cancellazione IS NULL AND tp.data_cancellazione IS NULL
        ), b AS (
    SELECT raac.attoamm_id, tc.classif_id, tc.classif_code,
            tc.classif_desc, dct.classif_tipo_code
    FROM siac_r_atto_amm_class raac, siac_t_class tc,
            siac_d_class_tipo dct, siac_r_class_fam_tree cft,
            siac_t_class_fam_tree tcft, siac_d_class_fam dcf
    WHERE raac.classif_id = tc.classif_id AND dct.classif_tipo_id =
        tc.classif_tipo_id AND cft.classif_id = tc.classif_id AND cft.classif_fam_tree_id = tcft.classif_fam_tree_id AND tcft.classif_fam_id = dcf.classif_fam_id AND dcf.classif_fam_code::text = '00005'::text AND raac.data_cancellazione IS NULL AND tc.data_cancellazione IS NULL AND dct.data_cancellazione IS NULL AND cft.data_cancellazione IS NULL AND tcft.data_cancellazione IS NULL AND dcf.data_cancellazione IS NULL
    )
    SELECT a.ente_proprietario_id, a.anno AS bil_anno_classe,
    a.movgest_anno AS anno_accertamento_classe,
    a.movgest_numero AS num_accertamento_classe,
    a.movgest_ts_code AS cod_movgest_ts_classe,
    a.movgest_ts_desc AS desc_movgest_ts_classe,
    a.movgest_ts_tipo_code AS tipo_movgest_ts_classe,
    a.mod_num AS numero_modifica, a.mod_desc AS desc_modifica,
    a.mod_stato_code AS stato_modifica, a.mod_tipo_code AS cod_tipo_modifica,
    a.mod_tipo_desc AS desc_tipo_modifica, a.cod_soggetto_classe_old,
    a.desc_soggetto_classe_old, a.cod_tipo_sog_classe_old,
    a.desc_tipo_sog_classe_old, a.cod_soggetto_classe_new,
    a.desc_soggetto_classe_new, a.cod_tipo_sog_classe_new,
    a.desc_tipo_sog_classe_new, a.attoamm_anno AS anno_atto_amministrativo,
    a.attoamm_numero AS num_atto_amministrativo,
    a.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
    b.classif_code AS cod_sac, b.classif_desc AS desc_sac,
    b.classif_tipo_code AS tipo_sac,
    a.mod_stato_desc AS desc_stato_modifica,
    a.data_creazione -- 30.08.2018 Sofia jira-6292
    FROM a
   LEFT JOIN b ON a.attoamm_id = b.attoamm_id;