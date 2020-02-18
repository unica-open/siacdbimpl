/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_bil_elem_class (
    ente_proprietario_id,
    bil_id,
    elem_code,
    elem_code2,
    elem_code3,
    elem_desc,
    elem_desc2,
    elem_id,
    elem_id_padre,
    validita_inizio_elem,
    validita_fine_elem,
    classif_id,
    classif_code,
    classif_desc,
    validita_inizio_classif,
    validita_fine_classif,
    classif_tipo_code,
    classif_tipo_desc,
    classif_tipo_id)
AS
SELECT e.ente_proprietario_id, e.bil_id, e.elem_code, e.elem_code2,
    e.elem_code3, e.elem_desc, e.elem_desc2, e.elem_id, e.elem_id_padre,
    e.validita_inizio AS validita_inizio_elem,
    e.validita_fine AS validita_fine_elem, c.classif_id, c.classif_code,
    c.classif_desc, c.validita_inizio AS validita_inizio_classif,
    c.validita_fine AS validita_fine_classif, ct.classif_tipo_code,
    ct.classif_tipo_desc, ct.classif_tipo_id
FROM siac_r_bil_elem_class r, siac_t_bil_elem e, siac_t_class c,
    siac_d_class_tipo ct
WHERE r.elem_id = e.elem_id AND r.classif_id = c.classif_id AND
    r.ente_proprietario_id = e.ente_proprietario_id AND e.ente_proprietario_id = c.ente_proprietario_id AND ct.classif_tipo_id = c.classif_tipo_id AND c.ente_proprietario_id = ct.ente_proprietario_id;