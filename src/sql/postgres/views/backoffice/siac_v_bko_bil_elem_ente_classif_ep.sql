/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_bil_elem_ente_classif_ep (
    ente_proprietario_id,
    ente_denominazione,
    codice_fiscale,
    bil_id,
    bil_desc,
    data_inizio,
    data_fine,
    elem_id,
    elem_id_padre,
    elem_code,
    elem_code2,
    elem_desc,
    ordine,
    livello,
    data_inizio_elem,
    data_fine_elem,
    elem_tipo_code,
    elem_tipo_desc,
    classif_tipo_code,
    classif_tipo_desc,
    classif_code,
    classif_desc)
AS
SELECT tb.ente_proprietario_id, tb.ente_denominazione, tb.codice_fiscale,
    tb.bil_id, tb.bil_desc, tb.data_inizio, tb.data_fine, tb.elem_id,
    tb.elem_id_padre, tb.elem_code, tb.elem_code2, tb.elem_desc, tb.ordine,
    tb.livello, tb.data_inizio_elem, tb.data_fine_elem, tb.elem_tipo_code,
    tb.elem_tipo_desc, tb.classif_tipo_code, tb.classif_tipo_desc,
    tb.classif_code, tb.classif_desc
FROM (
    SELECT ep.ente_proprietario_id, ep.ente_denominazione,
            ep.codice_fiscale, b.bil_id, b.bil_desc, tp.data_inizio,
            tp.data_fine, be.elem_id, be.elem_id_padre, be.elem_code,
            be.elem_code2, be.elem_desc, be.ordine, be.livello,
            tp2.data_inizio AS data_inizio_elem,
            tp2.data_fine AS data_fine_elem, et.elem_tipo_code,
            et.elem_tipo_desc, tic.classif_tipo_code, tic.classif_tipo_desc,
            tcl.classif_code, tcl.classif_desc
    FROM siac_t_bil b, siac_t_bil_elem be, siac_d_bil_elem_tipo et,
            siac_t_ente_proprietario ep, siac_t_periodo tp, siac_t_periodo tp2,
            siac_r_bil_elem_class cla, siac_t_class tcl, siac_d_class_tipo tic
    WHERE be.bil_id = b.bil_id AND tp.periodo_id = b.periodo_id AND
        et.elem_tipo_id = be.elem_tipo_id AND ep.ente_proprietario_id = b.ente_proprietario_id AND date_trunc('day'::text, now()) > b.validita_inizio AND (date_trunc('day'::text, now()) < b.validita_fine OR b.validita_fine IS NULL) AND date_trunc('day'::text, now()) > be.validita_inizio AND (date_trunc('day'::text, now()) < be.validita_fine OR be.validita_fine IS NULL) AND date_trunc('day'::text, now()) > et.validita_inizio AND (date_trunc('day'::text, now()) < et.validita_fine OR et.validita_fine IS NULL) AND (et.elem_tipo_id = ANY (ARRAY[7, 8, 9])) AND cla.elem_id = be.elem_id AND tcl.classif_id = cla.classif_id AND tic.classif_tipo_id = tcl.classif_tipo_id AND date_trunc('day'::text, now()) > cla.validita_inizio AND (date_trunc('day'::text, now()) < cla.validita_fine OR cla.validita_fine IS NULL) AND date_trunc('day'::text, now()) > tcl.validita_inizio AND (date_trunc('day'::text, now()) < tcl.validita_fine OR tcl.validita_fine IS NULL) AND date_trunc('day'::text, now()) > tic.validita_inizio AND (date_trunc('day'::text, now()) < tic.validita_fine OR tic.validita_fine IS NULL)
    ORDER BY be.ordine
    ) tb;