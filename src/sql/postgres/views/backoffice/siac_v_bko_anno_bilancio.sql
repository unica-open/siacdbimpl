/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac_v_bko_anno_bilancio (
    ente_proprietario_id,
    ente_denominazione,
    anno_bilancio,
    bil_id,
    bil_code,
    bil_desc,
    periodo_id,
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
SELECT ente.ente_proprietario_id, ente.ente_denominazione,
       per.anno::integer,
       bil.bil_id, bil.bil_code, bil.bil_desc,
       per.periodo_id,
       per.periodo_code, per.periodo_desc,
       per.data_inizio,  per.data_fine,
       fase.fase_operativa_id, fase.fase_operativa_code, fase.fase_operativa_desc,
       fase.validita_inizio, fase.validita_fine
FROM siac_t_bil bil, siac_r_bil_fase_operativa rbil, siac_d_fase_operativa fase,
     siac_t_periodo per,
     siac_t_ente_proprietario ente
WHERE bil.bil_id = rbil.bil_id
AND   fase.fase_operativa_id = rbil.fase_operativa_id
AND   per.periodo_id = bil.periodo_id
and   ente.ente_proprietario_id = bil.ente_proprietario_id
AND   now() >= bil.validita_inizio
AND   now() <= COALESCE(bil.validita_fine::timestamp with time zone, now())
AND   now() >= rbil.validita_inizio
AND   now() <= COALESCE(rbil.validita_fine::timestamp with time zone, now())
AND   now() >= fase.validita_inizio
AND   now() <= COALESCE(fase.validita_fine::timestamp with time zone, now())
AND   now() >= per.validita_inizio AND now() <= COALESCE(per.validita_fine::timestamp with time zone, now())
AND   now() >= ente.validita_inizio AND now() <= COALESCE(ente.validita_fine::timestamp with time zone, now());