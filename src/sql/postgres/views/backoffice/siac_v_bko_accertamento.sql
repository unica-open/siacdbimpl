/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_accertamento (
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
    movgest_ts_det_importo)
AS
SELECT t.movgest_tipo_code, t.movgest_tipo_desc, m.bil_id,
    m.ente_proprietario_id, m.movgest_anno, m.movgest_numero, m.movgest_id,
    m.movgest_desc, tt.movgest_ts_tipo_code, tt.movgest_ts_tipo_desc,
    mt.movgest_ts_id, mt.movgest_ts_id_padre, mt.movgest_ts_code,
    mt.movgest_ts_desc, mt.movgest_ts_scadenza_data,
    ttd.movgest_ts_det_tipo_code, ttd.movgest_ts_det_tipo_desc,
    mtd.movgest_ts_det_id, mtd.movgest_ts_det_importo
FROM siac_t_movgest m, siac_t_movgest_ts mt, siac_t_movgest_ts_det mtd,
    siac_d_movgest_tipo t, siac_d_movgest_ts_tipo tt,
    siac_d_movgest_ts_det_tipo ttd
WHERE m.movgest_id = mt.movgest_id AND mt.movgest_ts_id = mtd.movgest_ts_id AND
    t.movgest_tipo_id = m.movgest_tipo_id AND tt.movgest_ts_tipo_id = mt.movgest_ts_tipo_id AND ttd.movgest_ts_det_tipo_id = mtd.movgest_ts_det_tipo_id AND t.movgest_tipo_code::text = 'A'::text;