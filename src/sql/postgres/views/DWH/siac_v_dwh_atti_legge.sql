/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop VIEW siac.siac_v_dwh_atti_legge;
 
CREATE OR REPLACE VIEW siac.siac_v_dwh_atti_legge(
    ente_proprietario_id,
    bil_code,
    bil_desc,
    periodo_code,
    anno,
    elem_code,
    elem_code2,
    elem_code3,
    elem_tipo_code,
    attolegge_tipo_code,
    attolegge_tipo_desc,
    attolegge_anno,
    attolegge_numero,
    attolegge_articolo,
    attolegge_comma,
    attolegge_punto,
    descrizione,
    gerarchia)
AS
  SELECT tb2.ente_proprietario_id,
         tb2.bil_code,
         tb2.bil_desc,
         tb2.periodo_code,
         tb2.anno,
         tb2.elem_code,
         tb2.elem_code2,
         tb2.elem_code3,
         tb2.elem_tipo_code,
         tb2.attolegge_tipo_code,
         tb2.attolegge_tipo_desc,
         tb2.attolegge_anno,
         tb2.attolegge_numero,
         tb2.attolegge_articolo,
         tb2.attolegge_comma,
         tb2.attolegge_punto,
         tb2.descrizione,
         tb2.gerarchia
  FROM (WITH tb AS (
                     SELECT e.ente_proprietario_id,
                            e.ente_denominazione,
                            b.bil_id,
                            b.bil_code,
                            b.bil_desc,
                            per.periodo_code,
                            per.periodo_desc,
                            per.data_inizio,
                            per.data_fine,
                            be.elem_id,
                            be.elem_code,
                            be.elem_code2,
                            be.elem_code3,
                            be.elem_desc,
                            be.elem_desc2,
                            bet.elem_tipo_id,
                            bet.elem_tipo_code,
                            bet.elem_tipo_desc,
                            bes.elem_stato_id,
                            bes.elem_stato_code,
                            bes.elem_stato_desc,
                            per.anno
                     FROM siac_t_bil b,
                          siac_t_periodo per,
                          siac_t_bil_elem be,
                          siac_d_bil_elem_tipo bet,
                          siac_t_ente_proprietario e,
                          siac_r_bil_elem_stato rbes,
                          siac_d_bil_elem_stato bes
                     WHERE b.periodo_id = per.periodo_id AND
                           be.bil_id = b.bil_id AND
                           bet.elem_tipo_id = be.elem_tipo_id AND
                           e.ente_proprietario_id = b.ente_proprietario_id AND
                           rbes.elem_id = be.elem_id AND
                           rbes.elem_stato_id = bes.elem_stato_id AND
                           b.data_cancellazione IS NULL AND
                           per.data_cancellazione IS NULL AND
                           be.data_cancellazione IS NULL AND
                           bet.data_cancellazione IS NULL AND
                           e.data_cancellazione IS NULL AND
                           now() >= rbes.validita_inizio AND
                           now() <= COALESCE(rbes.validita_fine::timestamp with
                             time zone, now()) AND
                           bes.data_cancellazione IS NULL
       ), attoamm AS (
                       SELECT alt.attolegge_tipo_code,
                              alt.attolegge_tipo_desc,
                              al.attolegge_anno,
                              al.attolegge_numero,
                              al.attolegge_articolo,
                              al.attolegge_comma,
                              al.attolegge_punto,
                              ral.elem_id,
                              ral.descrizione,
                              ral.gerarchia
                       FROM siac_r_bil_elem_atto_legge ral,
                            siac_t_atto_legge al,
                            siac_d_atto_legge_tipo alt
                       WHERE ral.attolegge_id = al.attolegge_id AND
                             alt.attolegge_tipo_id = al.attolegge_tipo_id AND
                             now() >= ral.validita_inizio AND
                             now() <= COALESCE(ral.validita_fine::timestamp with
                               time zone, now()) AND
                             ral.data_cancellazione IS NULL AND
                             al.data_cancellazione IS NULL AND
                             alt.data_cancellazione IS NULL
       )
  SELECT tb.ente_proprietario_id, tb.bil_code, tb.bil_desc, tb.periodo_code,
    tb.anno, tb.elem_code, tb.elem_code2, tb.elem_code3, tb.elem_tipo_code,
    attoamm.attolegge_tipo_code, attoamm.attolegge_tipo_desc,
    attoamm.attolegge_anno, attoamm.attolegge_numero,
    attoamm.attolegge_articolo, attoamm.attolegge_comma,
    attoamm.attolegge_punto, attoamm.descrizione, attoamm.gerarchia
  FROM tb
       JOIN attoamm ON tb.elem_id = attoamm.elem_id) tb2;