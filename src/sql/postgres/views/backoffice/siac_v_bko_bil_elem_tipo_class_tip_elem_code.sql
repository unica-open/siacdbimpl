/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_bil_elem_tipo_class_tip_elem_code (
    classif_tipo_code,
    classif_tipo_desc,
    elem_tipo_code,
    elem_tipo_desc,
    elem_tipo_id,
    classif_tipo_id,
    ente_proprietario_id,
    elem_code)
AS
SELECT c.classif_tipo_code, c.classif_tipo_desc, e.elem_tipo_code,
    e.elem_tipo_desc, r.elem_tipo_id, r.classif_tipo_id, r.ente_proprietario_id,
    r.elem_code
FROM siac_r_bil_elem_tipo_class_tip_elem_code r, siac_d_class_tipo c,
    siac_d_bil_elem_tipo e
WHERE r.classif_tipo_id = c.classif_tipo_id AND e.elem_tipo_id = r.elem_tipo_id
    AND e.ente_proprietario_id = c.ente_proprietario_id AND r.ente_proprietario_id = e.ente_proprietario_id;