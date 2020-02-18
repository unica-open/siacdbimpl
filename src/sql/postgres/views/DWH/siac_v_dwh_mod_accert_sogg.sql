/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_accert_sogg (
    ente_proprietario_id,
    bil_anno_sogg,
    anno_accertamento_sogg,
    num_accertamento_sogg,
    cod_movgest_ts_sogg,
    desc_movgest_ts_sogg,
    tipo_movgest_ts_sogg,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    cod_soggeto_old,
    desc_soggetto_old,
    cf_old,
    cf_estero_old,
    partita_iva_old,
    cod_soggeto_new,
    desc_soggetto_new,
    cf_new,
    cf_estero_new,
    partita_iva_new,
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
            dms.mod_stato_code, dmt.mod_tipo_code, dmt.mod_tipo_desc, tp.anno,
            stm.movgest_anno, stm.movgest_numero, tmt.movgest_ts_code,
            tmt.movgest_ts_desc, dmtt.movgest_ts_tipo_code,
            ts1.soggetto_code AS cod_soggeto_old,
            ts1.soggetto_desc AS desc_soggetto_old,
            ts1.codice_fiscale AS cf_old,
            ts1.codice_fiscale_estero AS cf_estero_old,
            ts1.partita_iva AS partita_iva_old,
            ts2.soggetto_code AS cod_soggeto_new,
            ts2.soggetto_desc AS desc_soggetto_new,
            ts2.codice_fiscale AS cf_new,
            ts2.codice_fiscale_estero AS cf_estero_new,
            ts2.partita_iva AS partita_iva_new, tam.attoamm_anno,
            tam.attoamm_numero, daat.attoamm_tipo_code, tam.attoamm_id,
            dms.mod_stato_desc,
            tm.data_creazione -- 30.08.2018 Sofia jira-6292
FROM siac_r_movgest_ts_sog_mod rmtsm
      JOIN siac_r_modifica_stato rms ON rms.mod_stato_r_id = rmtsm.mod_stato_r_id
   JOIN siac_t_modifica tm ON tm.mod_id = rms.mod_id
   JOIN siac_d_modifica_stato dms ON rms.mod_stato_id = dms.mod_stato_id
   LEFT JOIN siac_d_modifica_tipo dmt ON dmt.mod_tipo_id = tm.mod_tipo_id AND
       dmt.data_cancellazione IS NULL
   JOIN siac_t_atto_amm tam ON tam.attoamm_id = tm.attoamm_id
   JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id = tam.attoamm_tipo_id
   JOIN siac_t_movgest_ts tmt ON tmt.movgest_ts_id = rmtsm.movgest_ts_id
   JOIN siac_t_soggetto ts1 ON ts1.soggetto_id = rmtsm.soggetto_id_old
   JOIN siac_t_soggetto ts2 ON ts2.soggetto_id = rmtsm.soggetto_id_new
   JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id
   JOIN siac_t_movgest stm ON stm.movgest_id = tmt.movgest_id
   JOIN siac_d_movgest_tipo sdmt ON sdmt.movgest_tipo_id = stm.movgest_tipo_id
   JOIN siac_t_bil tb ON tb.bil_id = stm.bil_id
   JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
WHERE sdmt.movgest_tipo_code::text = 'A'::text AND rmtsm.data_cancellazione IS
    NULL AND rms.data_cancellazione IS NULL AND tm.data_cancellazione IS NULL AND dms.data_cancellazione IS NULL AND tam.data_cancellazione IS NULL AND daat.data_cancellazione IS NULL AND tmt.data_cancellazione IS NULL AND ts1.data_cancellazione IS NULL AND ts2.data_cancellazione IS NULL AND dmtt.data_cancellazione IS NULL AND stm.data_cancellazione IS NULL AND dmt.data_cancellazione IS NULL AND tp.data_cancellazione IS NULL AND tb.data_cancellazione IS NULL
        ), b AS (
    SELECT raac.attoamm_id, tc.classif_id, tc.classif_code,
            tc.classif_desc, dct.classif_tipo_code
    FROM siac_r_atto_amm_class raac, siac_t_class tc,
            siac_d_class_tipo dct, siac_r_class_fam_tree cft,
            siac_t_class_fam_tree tcft, siac_d_class_fam dcf
    WHERE raac.classif_id = tc.classif_id AND dct.classif_tipo_id =
        tc.classif_tipo_id AND cft.classif_id = tc.classif_id AND cft.classif_fam_tree_id = tcft.classif_fam_tree_id AND tcft.classif_fam_id = dcf.classif_fam_id AND dcf.classif_fam_code::text = '00005'::text AND raac.data_cancellazione IS NULL AND tc.data_cancellazione IS NULL AND dct.data_cancellazione IS NULL AND cft.data_cancellazione IS NULL AND tcft.data_cancellazione IS NULL AND dcf.data_cancellazione IS NULL
    )
    SELECT a.ente_proprietario_id, a.anno AS bil_anno_sogg,
    a.movgest_anno AS anno_accertamento_sogg,
    a.movgest_numero AS num_accertamento_sogg,
    a.movgest_ts_code AS cod_movgest_ts_sogg,
    a.movgest_ts_desc AS desc_movgest_ts_sogg,
    a.movgest_ts_tipo_code AS tipo_movgest_ts_sogg,
    a.mod_num AS numero_modifica, a.mod_desc AS desc_modifica,
    a.mod_stato_code AS stato_modifica, a.mod_tipo_code AS cod_tipo_modifica,
    a.mod_tipo_desc AS desc_tipo_modifica, a.cod_soggeto_old,
    a.desc_soggetto_old, a.cf_old, a.cf_estero_old, a.partita_iva_old,
    a.cod_soggeto_new, a.desc_soggetto_new, a.cf_new, a.cf_estero_new,
    a.partita_iva_new, a.attoamm_anno AS anno_atto_amministrativo,
    a.attoamm_numero AS num_atto_amministrativo,
    a.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
    b.classif_code AS cod_sac, b.classif_desc AS desc_sac,
    b.classif_tipo_code AS tipo_sac,
    a.mod_stato_desc AS desc_stato_modifica,
    a.data_creazione -- 30.08.2018 Sofia jira-6292
    FROM a
   LEFT JOIN b ON a.attoamm_id = b.attoamm_id;