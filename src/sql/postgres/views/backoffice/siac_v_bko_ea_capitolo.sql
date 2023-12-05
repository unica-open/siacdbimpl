/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_ea_capitolo (
    ente_proprietario_id,
    ente_denominazione,
    bil_id,
    bil_code,
    bil_desc,
    periodo_code,
    periodo_desc,
    data_inizio,
    data_fine,
    elem_id,
    elem_code,
    elem_code2,
    elem_code3,
    elem_desc,
    elem_desc2,
    elem_tipo_id,
    elem_tipo_code,
    elem_tipo_desc,
    elem_stato_id,
    elem_stato_code,
    elem_stato_desc,
    attolegge_id,
    attolegge_anno,
    attolegge_numero,
    attolegge_articolo,
    attolegge_comma,
    attolegge_punto)
AS
SELECT tb.ente_proprietario_id, tb.ente_denominazione, tb.bil_id, tb.bil_code,
    tb.bil_desc, tb.periodo_code, tb.periodo_desc, tb.data_inizio, tb.data_fine,
    tb.elem_id, tb.elem_code, tb.elem_code2, tb.elem_code3, tb.elem_desc,
    tb.elem_desc2, tb.elem_tipo_id, tb.elem_tipo_code, tb.elem_tipo_desc,
    tb.elem_stato_id, tb.elem_stato_code, tb.elem_stato_desc, al.attolegge_id,
    al.attolegge_anno, al.attolegge_numero, al.attolegge_articolo,
    al.attolegge_comma, al.attolegge_punto
FROM (
    SELECT e.ente_proprietario_id, e.ente_denominazione, b.bil_id,
            b.bil_code, b.bil_desc, per.periodo_code, per.periodo_desc,
            per.data_inizio, per.data_fine, be.elem_id, be.elem_code,
            be.elem_code2, be.elem_code3, be.elem_desc, be.elem_desc2,
            bet.elem_tipo_id, bet.elem_tipo_code, bet.elem_tipo_desc,
            bes.elem_stato_id, bes.elem_stato_code, bes.elem_stato_desc
    FROM siac_t_bil b, siac_t_periodo per, siac_t_bil_elem be,
            siac_d_bil_elem_tipo bet, siac_t_ente_proprietario e,
            siac_r_bil_elem_stato rbes, siac_d_bil_elem_stato bes
    WHERE b.periodo_id = per.periodo_id AND be.bil_id = b.bil_id AND
        bet.elem_tipo_id = be.elem_tipo_id AND e.ente_proprietario_id = b.ente_proprietario_id AND rbes.elem_id = be.elem_id AND rbes.elem_stato_id = bes.elem_stato_id AND now() >= b.validita_inizio AND now() <= COALESCE(b.validita_fine::timestamp with time zone, now()) AND now() >= per.validita_inizio AND now() <= COALESCE(per.validita_fine::timestamp with time zone, now()) AND now() >= be.validita_inizio AND now() <= COALESCE(be.validita_fine::timestamp with time zone, now()) AND now() >= bet.validita_inizio AND now() <= COALESCE(bet.validita_fine::timestamp with time zone, now()) AND now() >= e.validita_inizio AND now() <= COALESCE(e.validita_fine::timestamp with time zone, now()) AND now() >= rbes.validita_inizio AND now() <= COALESCE(rbes.validita_fine::timestamp with time zone, now()) AND now() >= bes.validita_inizio AND now() <= COALESCE(bes.validita_fine::timestamp with time zone, now())
    ) tb
   LEFT JOIN siac_r_bil_elem_atto_legge ral ON tb.elem_id = ral.elem_id
   JOIN siac_t_atto_legge al ON ral.attolegge_id = al.attolegge_id
WHERE now() >= ral.validita_inizio AND now() <=
    COALESCE(ral.validita_fine::timestamp with time zone, now()) AND now() >= al.validita_inizio AND now() <= COALESCE(al.validita_fine::timestamp with time zone, now());