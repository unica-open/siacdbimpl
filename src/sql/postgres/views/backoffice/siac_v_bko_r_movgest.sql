/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_r_movgest (
    impegno_id,
    impegno_anno,
    impegno_numero,
    impegno_ts_id,
    impegno_ts_code,
    impegno_ts_desc,
    impegno_stato_code,
    impegno_bil_id,
    impegno_bil_anno,
    impegno_importo,
    impegno_tipo_importo,
    accertamento_id,
    accertamento_anno,
    accertamento_numero,
    accertamento_ts_id,
    accertamento_ts_code,
    accertamento_ts_desc,
    accerstamento_stato_code,
    accertamento_bil_id,
    accertamento_bil_anno,
    accertamento_importo,
    accertamento_tipo_importo,
    importo_vincolato)
AS
SELECT mgi.movgest_id AS impegno_id, mgi.movgest_anno AS impegno_anno,
    mgi.movgest_numero AS impegno_numero, tsi.movgest_ts_id AS impegno_ts_id,
    tsi.movgest_ts_code AS impegno_ts_code,
    tsi.movgest_ts_desc AS impegno_ts_desc,
    dsti.movgest_stato_code AS impegno_stato_code,
    bili.bil_id AS impegno_bil_id, pei.anno AS impegno_bil_anno,
    tsdi.movgest_ts_det_importo AS impegno_importo,
    mgdti.movgest_ts_det_tipo_code AS impegno_tipo_importo,
    mga.movgest_id AS accertamento_id, mga.movgest_anno AS accertamento_anno,
    mga.movgest_numero AS accertamento_numero,
    tsa.movgest_ts_id AS accertamento_ts_id,
    tsa.movgest_ts_code AS accertamento_ts_code,
    tsa.movgest_ts_desc AS accertamento_ts_desc,
    dsta.movgest_stato_code AS accerstamento_stato_code,
    bila.bil_id AS accertamento_bil_id, pea.anno AS accertamento_bil_anno,
    tsda.movgest_ts_det_importo AS accertamento_importo,
    mgdta.movgest_ts_det_tipo_code AS accertamento_tipo_importo,
    r.movgest_ts_importo AS importo_vincolato
FROM siac_r_movgest_ts r, siac_t_movgest_ts tsi, siac_t_movgest_ts tsa,
    siac_t_movgest mgi, siac_t_movgest mga, siac_t_bil bili, siac_t_bil bila,
    siac_t_periodo pei, siac_t_periodo pea, siac_t_movgest_ts_det tsdi,
    siac_t_movgest_ts_det tsda, siac_d_movgest_ts_det_tipo mgdti,
    siac_d_movgest_ts_det_tipo mgdta, siac_r_movgest_ts_stato rmgsti,
    siac_d_movgest_stato dsti, siac_r_movgest_ts_stato rmgsta,
    siac_d_movgest_stato dsta
WHERE r.movgest_ts_a_id = tsa.movgest_ts_id AND r.movgest_ts_b_id =
    tsi.movgest_ts_id AND mgi.movgest_id = tsi.movgest_id AND mga.movgest_id = tsa.movgest_id AND bili.bil_id = mgi.bil_id AND bila.bil_id = mga.bil_id AND pei.periodo_id = bili.periodo_id AND pea.periodo_id = bila.periodo_id AND tsdi.movgest_ts_id = tsi.movgest_ts_id AND tsda.movgest_ts_id = tsa.movgest_ts_id AND mgdti.movgest_ts_det_tipo_id = tsdi.movgest_ts_det_tipo_id AND mgdta.movgest_ts_det_tipo_id = tsda.movgest_ts_det_tipo_id AND rmgsti.movgest_ts_id = tsi.movgest_id AND rmgsti.movgest_stato_id = dsti.movgest_stato_id AND dsti.movgest_stato_code::text <> 'A'::text AND rmgsta.movgest_ts_id = tsa.movgest_id AND rmgsta.movgest_stato_id = dsta.movgest_stato_id AND dsta.movgest_stato_code::text <> 'A'::text AND r.data_cancellazione IS NULL AND tsi.data_cancellazione IS NULL AND tsa.data_cancellazione IS NULL AND mgi.data_cancellazione IS NULL AND mga.data_cancellazione IS NULL AND bili.data_cancellazione IS NULL AND bila.data_cancellazione IS NULL AND pei.data_cancellazione IS NULL AND pea.data_cancellazione IS NULL AND tsdi.data_cancellazione IS NULL AND tsda.data_cancellazione IS NULL AND mgdti.data_cancellazione IS NULL AND mgdta.data_cancellazione IS NULL AND rmgsti.data_cancellazione IS NULL AND dsti.data_cancellazione IS NULL AND rmgsta.data_cancellazione IS NULL AND dsta.data_cancellazione IS NULL AND now() >= r.validita_inizio AND now() <= COALESCE(r.validita_fine::timestamp with time zone, now()) AND now() >= tsi.validita_inizio AND now() <= COALESCE(tsi.validita_fine::timestamp with time zone, now()) AND now() >= tsa.validita_inizio AND now() <= COALESCE(tsa.validita_fine::timestamp with time zone, now()) AND now() >= mgi.validita_inizio AND now() <= COALESCE(mgi.validita_fine::timestamp with time zone, now()) AND now() >= mga.validita_inizio AND now() <= COALESCE(mga.validita_fine::timestamp with time zone, now()) AND now() >= bili.validita_inizio AND now() <= COALESCE(bili.validita_fine::timestamp with time zone, now()) AND now() >= bila.validita_inizio AND now() <= COALESCE(bila.validita_fine::timestamp with time zone, now()) AND now() >= pei.validita_inizio AND now() <= COALESCE(pei.validita_fine::timestamp with time zone, now()) AND now() >= pea.validita_inizio AND now() <= COALESCE(pea.validita_fine::timestamp with time zone, now()) AND now() >= tsdi.validita_inizio AND now() <= COALESCE(tsdi.validita_fine::timestamp with time zone, now()) AND now() >= tsda.validita_inizio AND now() <= COALESCE(tsda.validita_fine::timestamp with time zone, now()) AND now() >= mgdti.validita_inizio AND now() <= COALESCE(mgdti.validita_fine::timestamp with time zone, now()) AND now() >= mgdta.validita_inizio AND now() <= COALESCE(mgdta.validita_fine::timestamp with time zone, now()) AND now() >= rmgsti.validita_inizio AND now() <= COALESCE(rmgsti.validita_fine::timestamp with time zone, now()) AND now() >= dsti.validita_inizio AND now() <= COALESCE(dsti.validita_fine::timestamp with time zone, now()) AND now() >= rmgsta.validita_inizio AND now() <= COALESCE(rmgsta.validita_fine::timestamp with time zone, now()) AND now() >= dsta.validita_inizio AND now() <= COALESCE(dsta.validita_fine::timestamp with time zone, now());