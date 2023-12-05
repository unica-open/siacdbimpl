/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_class_attr (
    id_classificatore,
    classif_code,
    classif_desc,
    classif_tipo_desc,
    attr_desc,
    class_attr_id,
    classif_id,
    attr_id,
    tabella_id,
    "boolean",
    percentuale,
    stringa,
    numerico,
    validita_inizio,
    validita_fine,
    ente_proprietario_id)
AS
SELECT cl.classif_id AS id_classificatore, cl.classif_code, cl.classif_desc,
    ct.classif_tipo_desc, a.attr_desc, ca.class_attr_id, ca.classif_id,
    ca.attr_id, ca.tabella_id, ca."boolean", ca.percentuale,
    ca.testo AS stringa, ca.numerico, ca.validita_inizio, ca.validita_fine,
    ca.ente_proprietario_id
FROM siac_t_attr a, siac_d_attr_tipo a2, siac_r_class_attr ca,
    siac_t_class cl, siac_d_class_tipo ct
WHERE ca.attr_id = a.attr_id AND a2.attr_tipo_id = a.attr_tipo_id AND
    cl.classif_id = ca.classif_id AND ct.classif_tipo_id = cl.classif_tipo_id;