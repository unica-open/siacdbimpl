/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_ea_bilancio (
    ente_proprietario_id,
    ente_denominazione,
    bil_id,
    bil_code,
    bil_desc,
    bil_tipo_id,
    bil_tipo_code,
    bil_tipo_desc,
    periodo_code,
    periodo_desc,
    data_inizio,
    data_fine,
    periodo_tipo_id,
    periodo_tipo_code,
    periodo_tipo_desc,
    fase_operativa_id,
    fase_operativa_code,
    fase_operativa_desc,
    validita_inizio,
    validita_fine,
    bil_stato_op_id,
    bil_stato_op_code,
    bil_stato_op_desc)
AS
SELECT e.ente_proprietario_id, e.ente_denominazione, b.bil_id, b.bil_code,
    b.bil_desc, bt.bil_tipo_id, bt.bil_tipo_code, bt.bil_tipo_desc,
    per.periodo_code, per.periodo_desc, per.data_inizio, per.data_fine,
    pert.periodo_tipo_id, pert.periodo_tipo_code, pert.periodo_tipo_desc,
    fa.fase_operativa_id, fa.fase_operativa_code, fa.fase_operativa_desc,
    fa.validita_inizio, fa.validita_fine, bso.bil_stato_op_id,
    bso.bil_stato_op_code, bso.bil_stato_op_desc
FROM siac_t_bil b, siac_r_bil_fase_operativa rbf, siac_d_fase_operativa fa,
    siac_t_periodo per, siac_d_periodo_tipo pert, siac_d_bil_tipo bt,
    siac_r_bil_stato_op rbso, siac_d_bil_stato_op bso,
    siac_t_ente_proprietario e
WHERE b.bil_id = rbf.bil_id AND fa.fase_operativa_id = rbf.fase_operativa_id
    AND per.periodo_id = b.periodo_id AND pert.periodo_tipo_id = per.periodo_tipo_id AND bt.bil_tipo_id = b.bil_tipo_id AND rbso.bil_id = b.bil_id AND rbso.bil_stato_op_id = bso.bil_stato_op_id AND e.ente_proprietario_id = b.ente_proprietario_id AND now() >= b.validita_inizio AND now() <= COALESCE(b.validita_fine::timestamp with time zone, now()) AND now() >= rbf.validita_inizio AND now() <= COALESCE(rbf.validita_fine::timestamp with time zone, now()) AND now() >= fa.validita_inizio AND now() <= COALESCE(fa.validita_fine::timestamp with time zone, now()) AND now() >= per.validita_inizio AND now() <= COALESCE(per.validita_fine::timestamp with time zone, now()) AND now() >= pert.validita_inizio AND now() <= COALESCE(pert.validita_fine::timestamp with time zone, now()) AND now() >= bt.validita_inizio AND now() <= COALESCE(bt.validita_fine::timestamp with time zone, now()) AND now() >= rbso.validita_inizio AND now() <= COALESCE(rbso.validita_fine::timestamp with time zone, now()) AND now() >= bso.validita_inizio AND now() <= COALESCE(bso.validita_fine::timestamp with time zone, now()) AND now() >= e.validita_inizio AND now() <= COALESCE(e.validita_fine::timestamp with time zone, now());