/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_impegno_bil_elem (
    movgest_tipo_code,
    movgest_tipo_desc,
    bil_id,
    ente_proprietario_id,
    movgest_anno,
    movgest_numero,
    movgest_id,
    movgest_desc,
    movgest_ts_tipo_code,
    movgest_ts_tipo_desc,
    movgest_ts_id,
    movgest_ts_id_padre,
    movgest_ts_code,
    movgest_ts_desc,
    movgest_ts_scadenza_data,
    movgest_ts_det_tipo_code,
    movgest_ts_det_tipo_desc,
    movgest_ts_det_id,
    movgest_ts_det_importo,
    elem_id,
    elem_code,
    elem_code2,
    elem_code3,
    elem_desc,
    elem_desc2)
AS
SELECT t.movgest_tipo_code, t.movgest_tipo_desc, m.bil_id,
    m.ente_proprietario_id, m.movgest_anno, m.movgest_numero, m.movgest_id,
    m.movgest_desc, tt.movgest_ts_tipo_code, tt.movgest_ts_tipo_desc,
    mt.movgest_ts_id, mt.movgest_ts_id_padre, mt.movgest_ts_code,
    mt.movgest_ts_desc, mt.movgest_ts_scadenza_data,
    ttd.movgest_ts_det_tipo_code, ttd.movgest_ts_det_tipo_desc,
    mtd.movgest_ts_det_id, mtd.movgest_ts_det_importo, be.elem_id, be.elem_code,
    be.elem_code2, be.elem_code3, be.elem_desc, be.elem_desc2
FROM siac_t_movgest m, siac_t_movgest_ts mt, siac_t_movgest_ts_det mtd,
    siac_d_movgest_tipo t, siac_d_movgest_ts_tipo tt,
    siac_d_movgest_ts_det_tipo ttd, siac_r_movgest_bil_elem mbe,
    siac_t_bil_elem be
WHERE m.movgest_id = mt.movgest_id AND mt.movgest_ts_id = mtd.movgest_ts_id AND
    t.movgest_tipo_id = m.movgest_tipo_id AND tt.movgest_ts_tipo_id = mt.movgest_ts_tipo_id AND ttd.movgest_ts_det_tipo_id = mtd.movgest_ts_det_tipo_id AND mbe.movgest_id = m.movgest_id AND mbe.elem_id = be.elem_id AND t.movgest_tipo_code::text = 'I'::text;