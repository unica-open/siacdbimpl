/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_codifiche_econpatr (
    ente_proprietario_id,
    tipo_codifica,
    codice_codifica,
    descrizione_codifica,
    codice_codifica_albero,
    livello_codifica,
    classif_id,
    classif_id_padre)
AS
SELECT zz.ente_proprietario_id, zz.classif_tipo_desc AS tipo_codifica,
    zz.classif_code AS codice_codifica, zz.classif_desc AS descrizione_codifica,
    zz.ordine AS codice_codifica_albero, zz.level AS livello_codifica,
    zz.classif_id, zz.classif_id_padre
FROM(        (        (        (        (        (
    SELECT tb.classif_classif_fam_tree_id,
                                    tb.classif_fam_tree_id, t1.classif_code,
                                    t1.classif_desc, ti1.classif_tipo_desc,
                                    tb.classif_id, tb.classif_id_padre,
                                    tb.ente_proprietario_id, tb.ordine,
                                    tb.level
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
        classif_fam_tree_id, classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                                            rt1.classif_fam_tree_id,
                                                            rt1.classif_id,
                                                            rt1.classif_id_padre,
                                                            rt1.ente_proprietario_id,
                                                            rt1.ordine,
                                                            rt1.livello, 1,
                                                            ARRAY[COALESCE(rt1.classif_id,
                                                                0)] AS "array"
        FROM siac_r_class_fam_tree rt1,
                                                            siac_t_class_fam_tree tt1,
                                                            siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id AND
            tt1.classif_fam_tree_id = rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_code::text = '00020'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id AND date_trunc('day'::text, now()) > tt1.validita_inizio AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                                            tn.classif_fam_tree_id,
                                                            tn.classif_id,
                                                            tn.classif_id_padre,
                                                            tn.ente_proprietario_id,
                                                            tn.ordine,
                                                            tn.livello,
                                                            tp.level + 1,
                                                            tp.arrhierarchy ||
                                                                tn.classif_id
        FROM rqname tp,
                                                            siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
            tp.ente_proprietario_id
        )
        SELECT rqname.classif_classif_fam_tree_id,
                                            rqname.classif_fam_tree_id,
                                            rqname.classif_id,
                                            rqname.classif_id_padre,
                                            rqname.ente_proprietario_id,
                                            rqname.ordine, rqname.livello,
                                            rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
                                    siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
        t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id AND ti1.ente_proprietario_id = t1.ente_proprietario_id
    UNION
    SELECT tb.classif_classif_fam_tree_id,
                                    tb.classif_fam_tree_id, t1.classif_code,
                                    t1.classif_desc, ti1.classif_tipo_desc,
                                    tb.classif_id, tb.classif_id_padre,
                                    tb.ente_proprietario_id, tb.ordine,
                                    tb.level
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
        classif_fam_tree_id, classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                                            rt1.classif_fam_tree_id,
                                                            rt1.classif_id,
                                                            rt1.classif_id_padre,
                                                            rt1.ente_proprietario_id,
                                                            rt1.ordine,
                                                            rt1.livello, 1,
                                                            ARRAY[COALESCE(rt1.classif_id,
                                                                0)] AS "array"
        FROM siac_r_class_fam_tree rt1,
                                                            siac_t_class_fam_tree tt1,
                                                            siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id AND
            tt1.classif_fam_tree_id = rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_code::text = '00021'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id AND date_trunc('day'::text, now()) > tt1.validita_inizio AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                                            tn.classif_fam_tree_id,
                                                            tn.classif_id,
                                                            tn.classif_id_padre,
                                                            tn.ente_proprietario_id,
                                                            tn.ordine,
                                                            tn.livello,
                                                            tp.level + 1,
                                                            tp.arrhierarchy ||
                                                                tn.classif_id
        FROM rqname tp,
                                                            siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
            tp.ente_proprietario_id
        )
        SELECT rqname.classif_classif_fam_tree_id,
                                            rqname.classif_fam_tree_id,
                                            rqname.classif_id,
                                            rqname.classif_id_padre,
                                            rqname.ente_proprietario_id,
                                            rqname.ordine, rqname.livello,
                                            rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
                                    siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
        t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id AND ti1.ente_proprietario_id = t1.ente_proprietario_id
    )
UNION
SELECT tb.classif_classif_fam_tree_id,
                            tb.classif_fam_tree_id, t1.classif_code,
                            t1.classif_desc, ti1.classif_tipo_desc,
                            tb.classif_id, tb.classif_id_padre,
                            tb.ente_proprietario_id, tb.ordine, tb.level
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                                                    rt1.classif_fam_tree_id,
                                                    rt1.classif_id,
                                                    rt1.classif_id_padre,
                                                    rt1.ente_proprietario_id,
                                                    rt1.ordine, rt1.livello, 1,
                                                    ARRAY[COALESCE(rt1.classif_id,
                                                        0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                                                    siac_t_class_fam_tree tt1,
                                                    siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_code::text = '00022'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id AND date_trunc('day'::text, now()) > tt1.validita_inizio AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                                                    tn.classif_fam_tree_id,
                                                    tn.classif_id,
                                                    tn.classif_id_padre,
                                                    tn.ente_proprietario_id,
                                                    tn.ordine, tn.livello,
                                                    tp.level + 1,
                                                    tp.arrhierarchy || tn.classif_id
    FROM rqname tp,
                                                    siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id,
                                    rqname.classif_fam_tree_id,
                                    rqname.classif_id, rqname.classif_id_padre,
                                    rqname.ente_proprietario_id, rqname.ordine,
                                    rqname.livello, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb,
                            siac_t_class t1, siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id AND ti1.ente_proprietario_id = t1.ente_proprietario_id
    )
UNION
SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id,
                    t1.classif_code, t1.classif_desc, ti1.classif_tipo_desc,
                    tb.classif_id, tb.classif_id_padre, tb.ente_proprietario_id,
                    tb.ordine, tb.level
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                                            rt1.classif_fam_tree_id,
                                            rt1.classif_id,
                                            rt1.classif_id_padre,
                                            rt1.ente_proprietario_id,
                                            rt1.ordine, rt1.livello, 1,
                                            ARRAY[COALESCE(rt1.classif_id, 0)]
                                                AS "array"
    FROM siac_r_class_fam_tree rt1,
                                            siac_t_class_fam_tree tt1,
                                            siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_code::text = '00023'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id AND date_trunc('day'::text, now()) > tt1.validita_inizio AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                                            tn.classif_fam_tree_id,
                                            tn.classif_id, tn.classif_id_padre,
                                            tn.ente_proprietario_id, tn.ordine,
                                            tn.livello, tp.level + 1,
                                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp,
                                            siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id,
                            rqname.classif_fam_tree_id, rqname.classif_id,
                            rqname.classif_id_padre,
                            rqname.ente_proprietario_id, rqname.ordine,
                            rqname.livello, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
                    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id AND ti1.ente_proprietario_id = t1.ente_proprietario_id
)
UNION 
SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id,
                    t1.classif_code, t1.classif_desc, ti1.classif_tipo_desc,
                    tb.classif_id, tb.classif_id_padre, tb.ente_proprietario_id,
                    tb.ordine, tb.level
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                                            rt1.classif_fam_tree_id,
                                            rt1.classif_id,
                                            rt1.classif_id_padre,
                                            rt1.ente_proprietario_id,
                                            rt1.ordine, rt1.livello, 1,
                                            ARRAY[COALESCE(rt1.classif_id, 0)]
                                                AS "array"
    FROM siac_r_class_fam_tree rt1,
                                            siac_t_class_fam_tree tt1,
                                            siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_code::text = '00024'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id AND date_trunc('day'::text, now()) > tt1.validita_inizio AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                                            tn.classif_fam_tree_id,
                                            tn.classif_id, tn.classif_id_padre,
                                            tn.ente_proprietario_id, tn.ordine,
                                            tn.livello, tp.level + 1,
                                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp,
                                            siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id,
                            rqname.classif_fam_tree_id, rqname.classif_id,
                            rqname.classif_id_padre,
                            rqname.ente_proprietario_id, rqname.ordine,
                            rqname.livello, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
                    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id AND ti1.ente_proprietario_id = t1.ente_proprietario_id
)
UNION
SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id,
                    t1.classif_code, t1.classif_desc, ti1.classif_tipo_desc,
                    tb.classif_id, tb.classif_id_padre, tb.ente_proprietario_id,
                    tb.ordine, tb.level
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                                            rt1.classif_fam_tree_id,
                                            rt1.classif_id,
                                            rt1.classif_id_padre,
                                            rt1.ente_proprietario_id,
                                            rt1.ordine, rt1.livello, 1,
                                            ARRAY[COALESCE(rt1.classif_id, 0)]
                                                AS "array"
    FROM siac_r_class_fam_tree rt1,
                                            siac_t_class_fam_tree tt1,
                                            siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_code::text = '00025'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id AND date_trunc('day'::text, now()) > tt1.validita_inizio AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                                            tn.classif_fam_tree_id,
                                            tn.classif_id, tn.classif_id_padre,
                                            tn.ente_proprietario_id, tn.ordine,
                                            tn.livello, tp.level + 1,
                                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp,
                                            siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id,
                            rqname.classif_fam_tree_id, rqname.classif_id,
                            rqname.classif_id_padre,
                            rqname.ente_proprietario_id, rqname.ordine,
                            rqname.livello, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
                    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id AND ti1.ente_proprietario_id = t1.ente_proprietario_id
   )
   UNION
SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id,
                    t1.classif_code, t1.classif_desc, ti1.classif_tipo_desc,
                    tb.classif_id, tb.classif_id_padre, tb.ente_proprietario_id,
                    tb.ordine, tb.level
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                                            rt1.classif_fam_tree_id,
                                            rt1.classif_id,
                                            rt1.classif_id_padre,
                                            rt1.ente_proprietario_id,
                                            rt1.ordine, rt1.livello, 1,
                                            ARRAY[COALESCE(rt1.classif_id, 0)]
                                                AS "array"
    FROM siac_r_class_fam_tree rt1,
                                            siac_t_class_fam_tree tt1,
                                            siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_code::text = '00026'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id AND date_trunc('day'::text, now()) > tt1.validita_inizio AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                                            tn.classif_fam_tree_id,
                                            tn.classif_id, tn.classif_id_padre,
                                            tn.ente_proprietario_id, tn.ordine,
                                            tn.livello, tp.level + 1,
                                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp,
                                            siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id,
                            rqname.classif_fam_tree_id, rqname.classif_id,
                            rqname.classif_id_padre,
                            rqname.ente_proprietario_id, rqname.ordine,
                            rqname.livello, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
                    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id AND ti1.ente_proprietario_id = t1.ente_proprietario_id            
    ) zz
ORDER BY zz.ente_proprietario_id,
        CASE
            WHEN zz.classif_tipo_desc::text =
                'conti d''ordine (codice di bilancio)'::text THEN 4
            WHEN zz.classif_tipo_desc::text =
                'conto economico (codice di bilancio)'::text THEN 1
            WHEN zz.classif_tipo_desc::text =
                'stato patrimoniale attivo (codice di bilancio)'::text THEN 2
            WHEN zz.classif_tipo_desc::text =
                'stato patrimoniale passivo (codice di bilancio)'::text THEN 3
            WHEN zz.classif_tipo_desc::text =
                'CE_CODBIL_GSA'::text THEN 5
            WHEN zz.classif_tipo_desc::text =
                'SPA_CODBIL_GSA'::text THEN 6        
            WHEN zz.classif_tipo_desc::text =
                'SPP_CODBIL_GSA'::text THEN 7                                        
            ELSE NULL::integer
        END, zz.ordine; 