/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_movgest_tipo_class_tip (
    ente_proprietario_id,
    movgest_tipo_id,
    movgest_tipo_code,
    movgest_tipo_desc,
    classif_tipo_id,
    classif_tipo_code,
    classif_tipo_desc)
AS
SELECT a.ente_proprietario_id, mt.movgest_tipo_id, mt.movgest_tipo_code,
    mt.movgest_tipo_desc, ct.classif_tipo_id, ct.classif_tipo_code,
    ct.classif_tipo_desc
FROM siac_r_movgest_tipo_class_tip a, siac_d_movgest_tipo mt,
    siac_d_class_tipo ct
WHERE a.classif_tipo_id = ct.classif_tipo_id AND mt.movgest_tipo_id =
    a.movgest_tipo_id AND mt.ente_proprietario_id = a.ente_proprietario_id AND mt.ente_proprietario_id = ct.ente_proprietario_id;