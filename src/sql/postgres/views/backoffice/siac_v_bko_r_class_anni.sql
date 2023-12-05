/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_r_class_anni (
    ente_proprietario_id,
    classif_fam_code_a,
    classif_fam_desc_a,
    classif_id_a,
    validita_inizio_classif_id_a,
    validita_fine_classif_id_a,
    classif_code_a,
    classif_desc_a,
    classif_tipo_id_a,
    classif_tipo_desc_a,
    classif_fam_code_b,
    classif_fam_desc_b,
    classif_id_b,
    validita_inizio_classif_id_b,
    validita_fine_classif_id_b,
    classif_code_b,
    classif_desc_b,
    classif_tipo_id_b,
    classif_tipo_desc_b,
    validita_inizio_relazione,
    validita_fine_relazione)
AS
SELECT c.ente_proprietario_id, cfa.classif_fam_code AS classif_fam_code_a,
    cfa.classif_fam_desc AS classif_fam_desc_a, a.classif_id AS classif_id_a,
    a.validita_inizio AS validita_inizio_classif_id_a,
    a.validita_fine AS validita_fine_classif_id_a,
    a.classif_code AS classif_code_a, a.classif_desc AS classif_desc_a,
    a.classif_tipo_id AS classif_tipo_id_a,
    d.classif_tipo_desc AS classif_tipo_desc_a,
    cfb.classif_fam_code AS classif_fam_code_b,
    cfb.classif_fam_desc AS classif_fam_desc_b, b.classif_id AS classif_id_b,
    b.validita_inizio AS validita_inizio_classif_id_b,
    b.validita_fine AS validita_fine_classif_id_b,
    b.classif_code AS classif_code_b, b.classif_desc AS classif_desc_b,
    b.classif_tipo_id AS classif_tipo_id_b,
    e.classif_tipo_desc AS classif_tipo_desc_b,
    c.validita_inizio AS validita_inizio_relazione,
    c.validita_fine AS validita_fine_relazione
FROM siac_r_class c, siac_t_class a, siac_t_class b, siac_d_class_tipo d,
    siac_d_class_tipo e, siac_r_class_fam_tree ta, siac_r_class_fam_tree tb,
    siac_t_class_fam_tree cta, siac_t_class_fam_tree ctb, siac_d_class_fam cfa,
    siac_d_class_fam cfb
WHERE a.classif_id = c.classif_a_id AND b.classif_id = c.classif_b_id AND
    d.classif_tipo_id = a.classif_tipo_id AND e.classif_tipo_id = b.classif_tipo_id AND ta.classif_id = a.classif_id AND tb.classif_id = b.classif_id AND cta.classif_fam_tree_id = ta.classif_fam_tree_id AND ctb.classif_fam_tree_id = tb.classif_fam_tree_id AND cta.classif_fam_id = cfa.classif_fam_id AND ctb.classif_fam_id = cfb.classif_fam_id;