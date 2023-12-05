/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_accertamento(
    bil_anno,
    anno_accertamento,
    num_accertamento,
    cod_movgest_ts,
    desc_movgest_ts,
    tipo_movgest_ts,
    importo_modifica,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    ente_proprietario_id,
    desc_stato_modifica,
    flag_reimputazione,
    anno_reimputazione,
    elab_ror_reanno, -- 19.02.2020 Sofia jira siac-7292
    validita_inizio,
    data_creazione -- 30.08.2018 Sofia jira-6292
    )
AS
WITH zz AS(
  SELECT l.anno,
         b.movgest_anno,
         b.movgest_numero,
         c.movgest_ts_code,
         c.movgest_ts_desc,
         dmtt.movgest_ts_tipo_code,
         a.movgest_ts_det_importo,
         d.mod_num,
         d.mod_desc,
         f.mod_stato_code,
         g.mod_tipo_code,
         g.mod_tipo_desc,
         h.attoamm_anno,
         h.attoamm_numero,
         daat.attoamm_tipo_code,
         a.ente_proprietario_id,
         h.attoamm_id,
         f.mod_stato_desc,
         a.mtdm_reimputazione_flag,
         d.validita_inizio,
         d.elab_ror_reanno, -- 19.02.2020 Sofia jira siac-7292
         a.mtdm_reimputazione_anno,
         d.data_creazione, -- 30.08.2018 Sofia jira-6292
         CASE
           WHEN dmtt.movgest_ts_tipo_code::text = 'S' ::text THEN (SELECT count(a1.*) AS count
                                                                   FROM siac_t_movgest_ts_det_mod a1
                                                                   JOIN siac_t_movgest_ts c1 ON c1.movgest_ts_id = a1.movgest_ts_id
                                                                   JOIN siac_t_movgest b1 ON b1.movgest_id = c1.movgest_id
                                                                   JOIN siac_d_movgest_tipo tt1 ON tt1.movgest_tipo_id = b1.movgest_tipo_id
                                                                   JOIN siac_r_modifica_stato e1 ON e1.mod_stato_r_id = a1.mod_stato_r_id
                                                                   JOIN siac_t_modifica d1 ON d1.mod_id = e1.mod_id
                                                                   JOIN siac_d_modifica_stato f1 ON f1.mod_stato_id = e1.mod_stato_id
                                                                   LEFT JOIN siac_d_modifica_tipo g1 ON g1.mod_tipo_id = d1.mod_tipo_id
                                                                                                     AND g1.data_cancellazione IS NULL
                                                                                                     AND g1.mod_tipo_code::text = g.mod_tipo_code::text
                                                                   JOIN siac_d_movgest_ts_tipo dmtt1 ON dmtt1.movgest_ts_tipo_id = c1.movgest_ts_tipo_id
                                                                   JOIN siac_t_bil i1 ON i1.bil_id = b1.bil_id
                                                                   JOIN siac_t_periodo l1 ON l1.periodo_id = i1.periodo_id
                                                                   WHERE tt1.movgest_tipo_code::text = 'A'::text
																   AND   dmtt1.movgest_ts_tipo_code::text = 'T'::text
																   AND   b1.movgest_anno = b.movgest_anno
																   AND   b1.movgest_numero = b.movgest_numero
																   AND d1.mod_num = d.mod_num
																   AND f1.mod_stato_code::text = f.mod_stato_code::text
																   AND a1.ente_proprietario_id = a.ente_proprietario_id
																   AND l1.anno::text = l.anno::text
																   AND a1.data_cancellazione IS NULL
																   AND b1.data_cancellazione IS NULL
																   AND c1.data_cancellazione IS NULL
																   AND tt1.data_cancellazione IS NULL
																   AND d1.data_cancellazione IS NULL
																   AND e1.data_cancellazione IS NULL
																   AND f1.data_cancellazione IS NULL
																   AND dmtt1.data_cancellazione IS NULL
																   AND i1.data_cancellazione IS NULL
																   AND l1.data_cancellazione IS NULL
         )
           ELSE 0::bigint
         END AS verifica_record_doppi
  FROM siac_t_movgest_ts_det_mod a
       JOIN siac_t_movgest_ts c ON c.movgest_ts_id = a.movgest_ts_id
       JOIN siac_t_movgest b ON b.movgest_id = c.movgest_id
       JOIN siac_d_movgest_tipo tt ON tt.movgest_tipo_id = b.movgest_tipo_id
       JOIN siac_r_modifica_stato e ON e.mod_stato_r_id = a.mod_stato_r_id
       JOIN siac_t_modifica d ON d.mod_id = e.mod_id
       JOIN siac_d_modifica_stato f ON f.mod_stato_id = e.mod_stato_id
       LEFT JOIN siac_d_modifica_tipo g ON g.mod_tipo_id = d.mod_tipo_id AND
         g.data_cancellazione IS NULL
       JOIN siac_t_atto_amm h ON h.attoamm_id = d.attoamm_id
       JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id =
         h.attoamm_tipo_id
       JOIN siac_t_bil i ON i.bil_id = b.bil_id
       JOIN siac_t_periodo l ON l.periodo_id = i.periodo_id
       JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id =
         c.movgest_ts_tipo_id
  WHERE tt.movgest_tipo_code::text = 'A' ::text AND
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        tt.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        e.data_cancellazione IS NULL AND
        f.data_cancellazione IS NULL AND
        h.data_cancellazione IS NULL AND
        daat.data_cancellazione IS NULL AND
        i.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        dmtt.data_cancellazione IS NULL), aa AS (
         SELECT i.attoamm_id,
                l.classif_id,
                l.classif_code,
                l.classif_desc,
                m.classif_tipo_code
         FROM siac_r_atto_amm_class i,
              siac_t_class l,
              siac_d_class_tipo m,
              siac_r_class_fam_tree n,
              siac_t_class_fam_tree o,
              siac_d_class_fam p
         WHERE i.classif_id = l.classif_id AND
               m.classif_tipo_id = l.classif_tipo_id AND
               n.classif_id = l.classif_id AND
               n.classif_fam_tree_id = o.classif_fam_tree_id AND
               o.classif_fam_id = p.classif_fam_id AND
               p.classif_fam_code::text = '00005' ::text AND
               i.data_cancellazione IS NULL AND
               l.data_cancellazione IS NULL AND
               m.data_cancellazione IS NULL AND
               n.data_cancellazione IS NULL AND
               o.data_cancellazione IS NULL AND
               p.data_cancellazione IS NULL)
 SELECT zz.anno AS bil_anno,
        zz.movgest_anno AS anno_accertamento,
        zz.movgest_numero AS num_accertamento,
        zz.movgest_ts_code AS cod_movgest_ts,
        zz.movgest_ts_desc AS desc_movgest_ts,
        zz.movgest_ts_tipo_code AS tipo_movgest_ts,
        zz.movgest_ts_det_importo AS importo_modifica,
        zz.mod_num AS numero_modifica,
        zz.mod_desc AS desc_modifica,
        zz.mod_stato_code AS stato_modifica,
        zz.mod_tipo_code AS cod_tipo_modifica,
        zz.mod_tipo_desc AS desc_tipo_modifica,
        zz.attoamm_anno AS anno_atto_amministrativo,
        zz.attoamm_numero AS num_atto_amministrativo,
        zz.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
        aa.classif_code AS cod_sac,
        aa.classif_desc AS desc_sac,
        aa.classif_tipo_code AS tipo_sac,
        zz.ente_proprietario_id,
        zz.mod_stato_desc AS desc_stato_modifica,
        zz.mtdm_reimputazione_flag AS flag_reimputazione,
        zz.mtdm_reimputazione_anno AS anno_reimputazione,
        zz.elab_ror_reanno, -- 19.02.2020 Sofia jira siac-7292
        zz.validita_inizio,
        zz.data_creazione -- 30.08.2018 Sofia jira-6292
 FROM zz
      LEFT JOIN aa ON zz.attoamm_id = aa.attoamm_id
 WHERE zz.verifica_record_doppi = 0;