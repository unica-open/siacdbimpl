/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_r_class (
    ente_proprietario_id,
    classif_fam_code_a,
    classif_fam_desc_a,
    classif_id_a,
    classif_code_a,
    classif_desc_a,
    classif_tipo_id_a,
    classif_tipo_desc_a,
    classif_fam_code_b,
    classif_fam_desc_b,
    classif_id_b,
    classif_code_b,
    classif_desc_b,
    classif_tipo_id_b,
    classif_tipo_desc_b)
AS
SELECT c.ente_proprietario_id, cfa.classif_fam_code AS classif_fam_code_a,
    cfa.classif_fam_desc AS classif_fam_desc_a, a.classif_id AS classif_id_a,
    a.classif_code AS classif_code_a, a.classif_desc AS classif_desc_a,
    a.classif_tipo_id AS classif_tipo_id_a,
    d.classif_tipo_desc AS classif_tipo_desc_a,
    cfb.classif_fam_code AS classif_fam_code_b,
    cfb.classif_fam_desc AS classif_fam_desc_b, b.classif_id AS classif_id_b,
    b.classif_code AS classif_code_b, b.classif_desc AS classif_desc_b,
    b.classif_tipo_id AS classif_tipo_id_b,
    e.classif_tipo_desc AS classif_tipo_desc_b
FROM siac_r_class c, siac_t_class a, siac_t_class b, siac_d_class_tipo d,
    siac_d_class_tipo e, siac_r_class_fam_tree ta, siac_r_class_fam_tree tb,
    siac_t_class_fam_tree cta, siac_t_class_fam_tree ctb, siac_d_class_fam cfa,
    siac_d_class_fam cfb
WHERE a.classif_id = c.classif_a_id AND b.classif_id = c.classif_b_id AND
    d.classif_tipo_id = a.classif_tipo_id AND e.classif_tipo_id = b.classif_tipo_id AND ta.classif_id = a.classif_id AND tb.classif_id = b.classif_id AND cta.classif_fam_tree_id = ta.classif_fam_tree_id AND ctb.classif_fam_tree_id = tb.classif_fam_tree_id AND cta.classif_fam_id = cfa.classif_fam_id AND ctb.classif_fam_id = cfb.classif_fam_id AND now() >= c.validita_inizio AND now() <= COALESCE(c.validita_fine::timestamp with time zone, now()) AND now() >= a.validita_inizio AND now() <= COALESCE(a.validita_fine::timestamp with time zone, now()) AND now() >= b.validita_inizio AND now() <= COALESCE(b.validita_fine::timestamp with time zone, now()) AND now() >= d.validita_inizio AND now() <= COALESCE(d.validita_fine::timestamp with time zone, now()) AND now() >= e.validita_inizio AND now() <= COALESCE(e.validita_fine::timestamp with time zone, now()) AND now() >= ta.validita_inizio AND now() <= COALESCE(ta.validita_fine::timestamp with time zone, now()) AND now() >= tb.validita_inizio AND now() <= COALESCE(tb.validita_fine::timestamp with time zone, now()) AND now() >= cta.validita_inizio AND now() <= COALESCE(cta.validita_fine::timestamp with time zone, now()) AND now() >= ctb.validita_inizio AND now() <= COALESCE(ctb.validita_fine::timestamp with time zone, now()) AND now() >= cfa.validita_inizio AND now() <= COALESCE(cfa.validita_fine::timestamp with time zone, now()) AND now() >= cfb.validita_inizio AND now() <= COALESCE(cfb.validita_fine::timestamp with time zone, now());