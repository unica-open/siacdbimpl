/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_bko_stato_patrimoniale_passivo_cod_bil_anni(
    classif_classif_fam_tree_id,
    classif_fam_tree_id,
    classif_code,
    classif_desc,
    classif_tipo_desc,
    classif_id,
    classif_id_padre,
    ente_proprietario_id,
    ordine,
    level,
    validita_inizio,
    validita_fine)
AS
  SELECT tb.classif_classif_fam_tree_id,
         tb.classif_fam_tree_id,
         t1.classif_code,
         t1.classif_desc,
         ti1.classif_tipo_desc,
         tb.classif_id,
         tb.classif_id_padre,
         tb.ente_proprietario_id,
         tb.ordine,
         tb.level,
         tb.validita_inizio,
         tb.validita_fine
  FROM (WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello,
    validita_inizio, validita_fine, level, arrhierarchy) AS (
                                                              SELECT
                                                                rt1.classif_classif_fam_tree_id
  ,
                                                                     rt1.classif_fam_tree_id
  ,
                                                                     rt1.classif_id
  ,
                                                                     rt1.classif_id_padre
  ,
                                                                     rt1.ente_proprietario_id
  ,
                                                                     rt1.ordine,
                                                                     rt1.livello
  ,
                                                                     rt1.validita_inizio
  ,
                                                                     rt1.validita_fine
  ,
                                                                     1,
                                                                     ARRAY [
                                                                       COALESCE(
                                                                       
                                                                       rt1.classif_id,
                                                                       0) ] AS
                                                                       "array"
                                                              FROM
                                                                siac_r_class_fam_tree
                                                                rt1,
                                                                   siac_t_class_fam_tree
                                                                     tt1,
                                                                   siac_d_class_fam
                                                                     cf
                                                              WHERE
                                                                cf.classif_fam_id
                                                                =
                                                                tt1.classif_fam_id
  AND
                                                                    tt1.classif_fam_tree_id
                                                                      =
                                                                      rt1.classif_fam_tree_id
  AND
                                                                    rt1.classif_id_padre
                                                                      IS NULL
  AND
                                                                    cf.classif_fam_code
                                                                      ::text =
                                                                      '00022'::
                                                                      text AND
                                                                    tt1.ente_proprietario_id
                                                                      =
                                                                      rt1.ente_proprietario_id
                                                              UNION ALL
                                                              SELECT
                                                                tn.classif_classif_fam_tree_id
  ,
                                                                     tn.classif_fam_tree_id
  ,
                                                                     tn.classif_id
  ,
                                                                     tn.classif_id_padre
  ,
                                                                     tn.ente_proprietario_id
  ,
                                                                     tn.ordine,
                                                                     tn.livello,
                                                                     tn.validita_inizio
  ,
                                                                     tn.validita_fine
  ,
                                                                     tp.level +
                                                                       1,
                                                                     tp.arrhierarchy
                                                                       ||
                                                                       tn.classif_id
                                                              FROM rqname tp,
                                                                   siac_r_class_fam_tree
                                                                     tn
                                                              WHERE
                                                                tp.classif_id =
                                                                tn.classif_id_padre
  AND
                                                                    tn.ente_proprietario_id
                                                                      =
                                                                      tp.ente_proprietario_id
       )
  SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
    rqname.classif_id, rqname.classif_id_padre, rqname.ente_proprietario_id,
    rqname.ordine, rqname.livello, rqname.validita_inizio, rqname.validita_fine,
    rqname.level
  FROM rqname
  ORDER BY rqname.arrhierarchy) tb,
           siac_t_class t1,
           siac_d_class_tipo ti1
  WHERE t1.classif_id = tb.classif_id AND
        ti1.classif_tipo_id = t1.classif_tipo_id AND
        t1.ente_proprietario_id = tb.ente_proprietario_id AND
        ti1.ente_proprietario_id = t1.ente_proprietario_id;