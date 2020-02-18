/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_bil_fase_operativa (
    ente_proprietario_id,
    bil_id,
    bil_code,
    bil_desc,
    periodo_code,
    periodo_desc,
    data_inizio,
    data_fine,
    fase_operativa_id,
    fase_operativa_code,
    fase_operativa_desc,
    validita_inizio,
    validita_fine)
AS
SELECT b.ente_proprietario_id, b.bil_id, b.bil_code, b.bil_desc,
    per.periodo_code, per.periodo_desc, per.data_inizio, per.data_fine,
    fa.fase_operativa_id, fa.fase_operativa_code, fa.fase_operativa_desc,
    fa.validita_inizio, fa.validita_fine
FROM siac_t_bil b, siac_r_bil_fase_operativa rbf, siac_d_fase_operativa fa,
    siac_t_periodo per
WHERE b.bil_id = rbf.bil_id AND fa.fase_operativa_id = rbf.fase_operativa_id
    AND per.periodo_id = b.periodo_id;