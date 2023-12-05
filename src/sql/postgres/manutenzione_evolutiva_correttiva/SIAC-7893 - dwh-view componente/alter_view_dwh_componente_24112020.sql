/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 24.11.2020 Sofia Jira SIAC-7893
drop VIEW if exists siac.siac_v_dwh_bil_elem_comp_tipo;
CREATE OR REPLACE VIEW siac.siac_v_dwh_bil_elem_comp_tipo
(
    ente_proprietario_id,
    ente_denominazione,
    elem_det_comp_tipo_code,
    elem_det_comp_tipo_desc,
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_tipo_fonte_code,
    elem_det_comp_tipo_fonte_desc,
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    elem_det_comp_tipo_gest_aut,
    elem_det_comp_tipo_anno,
    elem_det_comp_tipo_stato_code,
    elem_det_comp_tipo_stato_desc,
    validita_inizio,
    validita_fine
)
AS
SELECT ente.ente_proprietario_id,
    ente.ente_denominazione,
--    tipo.elem_det_comp_tipo_code, 24.11.2020 Sofia Jira SIAC-7893
    tipo.elem_det_comp_tipo_id::varchar(200) elem_det_comp_tipo_code,-- 24.11.2020 Sofia Jira SIAC-7893
    tipo.elem_det_comp_tipo_desc,
    macro.elem_det_comp_macro_tipo_code,
    macro.elem_det_comp_macro_tipo_desc,
    sotto_tipo.elem_det_comp_sotto_tipo_code,
    sotto_tipo.elem_det_comp_sotto_tipo_desc,
    ambito_tipo.elem_det_comp_tipo_ambito_code,
    ambito_tipo.elem_det_comp_tipo_ambito_desc,
    fonte_tipo.elem_det_comp_tipo_fonte_code,
    fonte_tipo.elem_det_comp_tipo_fonte_desc,
    fase_tipo.elem_det_comp_tipo_fase_code,
    fase_tipo.elem_det_comp_tipo_fase_desc,
    def_tipo.elem_det_comp_tipo_def_code,
    def_tipo.elem_det_comp_tipo_def_desc,
        CASE
            WHEN tipo.elem_det_comp_tipo_gest_aut = true THEN 'Solo automatica'::text
            ELSE 'Manuale'::text
        END::character varying(50) AS elem_det_comp_tipo_gest_aut,
    per.anno::integer AS elem_det_comp_tipo_anno,
    stato.elem_det_comp_tipo_stato_code,
    stato.elem_det_comp_tipo_stato_desc,
    tipo.validita_inizio,
    tipo.validita_fine
FROM siac_t_ente_proprietario ente,
    siac_d_bil_elem_det_comp_tipo_stato stato,
    siac_d_bil_elem_det_comp_macro_tipo macro,
    siac_d_bil_elem_det_comp_tipo tipo
     LEFT JOIN siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo ON
         tipo.elem_det_comp_sotto_tipo_id = sotto_tipo.elem_det_comp_sotto_tipo_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo ON
         tipo.elem_det_comp_tipo_ambito_id = ambito_tipo.elem_det_comp_tipo_ambito_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fonte fonte_tipo ON
         tipo.elem_det_comp_tipo_fonte_id = fonte_tipo.elem_det_comp_tipo_fonte_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fase fase_tipo ON
         tipo.elem_det_comp_tipo_fase_id = fase_tipo.elem_det_comp_tipo_fase_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_def def_tipo ON
         tipo.elem_det_comp_tipo_def_id = def_tipo.elem_det_comp_tipo_def_id
     LEFT JOIN siac_t_periodo per ON tipo.periodo_id = per.periodo_id
WHERE stato.ente_proprietario_id = ente.ente_proprietario_id AND
    stato.elem_det_comp_tipo_stato_id = tipo.elem_det_comp_tipo_stato_id AND macro.elem_det_comp_macro_tipo_id = tipo.elem_det_comp_macro_tipo_id AND tipo.data_cancellazione IS NULL;


alter view siac_v_dwh_bil_elem_comp_tipo OWNER to siac;


drop VIEW if exists siac.siac_v_dwh_bil_elem_comp_cap;

CREATE OR REPLACE VIEW siac.siac_v_dwh_bil_elem_comp_cap
(
    ente_proprietario_id,
    ente_denominazione,
    elem_anno_bilancio,
    elem_tipo_code_capitolo,
    elem_tipo_desc_capitolo,
    elem_code_capitolo,
    elem_code_articolo,
    elem_code_ueb,
    elem_stato_code_capitolo,
    elem_stato_desc_capitolo,
    elem_det_anno,
    elem_det_importo,
    elem_det_comp_importo,
    elem_det_comp_tipo_code,
    elem_det_comp_tipo_desc,
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_tipo_fonte_code,
    elem_det_comp_tipo_fonte_desc,
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    elem_det_comp_tipo_gest_aut,
    elem_det_comp_tipo_anno
)
AS
SELECT ente.ente_proprietario_id,
    ente.ente_denominazione,
    query.elem_anno_bilancio,
    query.elem_tipo_code_capitolo,
    query.elem_tipo_desc_capitolo,
    query.elem_code_capitolo,
    query.elem_code_articolo,
    query.elem_code_ueb,
    query.elem_stato_code_capitolo,
    query.elem_stato_desc_capitolo,
    query.elem_det_anno,
    query.elem_det_importo,
    query.elem_det_comp_importo,
    query.elem_det_comp_tipo_code,
    query.elem_det_comp_tipo_desc,
    query.elem_det_comp_macro_tipo_code,
    query.elem_det_comp_macro_tipo_desc,
    query.elem_det_comp_sotto_tipo_code,
    query.elem_det_comp_sotto_tipo_desc,
    query.elem_det_comp_tipo_ambito_code,
    query.elem_det_comp_tipo_ambito_desc,
    query.elem_det_comp_tipo_fonte_code,
    query.elem_det_comp_tipo_fonte_desc,
    query.elem_det_comp_tipo_fase_code,
    query.elem_det_comp_tipo_fase_desc,
    query.elem_det_comp_tipo_def_code,
    query.elem_det_comp_tipo_def_desc,
    query.elem_det_comp_tipo_gest_aut,
    query.elem_det_comp_tipo_anno
FROM ( WITH comp_tipo AS (
    SELECT macro.elem_det_comp_macro_tipo_code,
                    macro.elem_det_comp_macro_tipo_desc,
                    sotto_tipo.elem_det_comp_sotto_tipo_code,
                    sotto_tipo.elem_det_comp_sotto_tipo_desc,
					--    tipo.elem_det_comp_tipo_code, 24.11.2020 Sofia Jira SIAC-7893
				    tipo.elem_det_comp_tipo_id::varchar(200) elem_det_comp_tipo_code,-- 24.11.2020 Sofia Jira SIAC-7893
                    tipo.elem_det_comp_tipo_desc,
                    ambito_tipo.elem_det_comp_tipo_ambito_code,
                    ambito_tipo.elem_det_comp_tipo_ambito_desc,
                    fonte_tipo.elem_det_comp_tipo_fonte_code,
                    fonte_tipo.elem_det_comp_tipo_fonte_desc,
                    fase_tipo.elem_det_comp_tipo_fase_code,
                    fase_tipo.elem_det_comp_tipo_fase_desc,
                    def_tipo.elem_det_comp_tipo_def_code,
                    def_tipo.elem_det_comp_tipo_def_desc,
                        CASE
                            WHEN tipo.elem_det_comp_tipo_gest_aut = true THEN
                                'Solo automatica'::text
                            ELSE 'Manuale'::text
                        END::character varying(50) AS elem_det_comp_tipo_gest_aut,
                    per.anno::integer AS elem_det_comp_tipo_anno,
                    tipo.elem_det_comp_tipo_id,
                    per.periodo_id AS elem_det_comp_periodo_id
    FROM siac_d_bil_elem_det_comp_tipo_stato stato,
                    siac_d_bil_elem_det_comp_macro_tipo macro,
                    siac_d_bil_elem_det_comp_tipo tipo
                     LEFT JOIN siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo
                         ON tipo.elem_det_comp_sotto_tipo_id = sotto_tipo.elem_det_comp_sotto_tipo_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo
                         ON tipo.elem_det_comp_tipo_ambito_id = ambito_tipo.elem_det_comp_tipo_ambito_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fonte fonte_tipo
                         ON tipo.elem_det_comp_tipo_fonte_id = fonte_tipo.elem_det_comp_tipo_fonte_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fase fase_tipo ON
                         tipo.elem_det_comp_tipo_fase_id = fase_tipo.elem_det_comp_tipo_fase_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_def def_tipo ON
                         tipo.elem_det_comp_tipo_def_id = def_tipo.elem_det_comp_tipo_def_id
                     LEFT JOIN siac_t_periodo per ON tipo.periodo_id = per.periodo_id
    WHERE stato.elem_det_comp_tipo_stato_id = tipo.elem_det_comp_tipo_stato_id
        AND macro.elem_det_comp_macro_tipo_id = tipo.elem_det_comp_macro_tipo_id AND tipo.data_cancellazione IS NULL
    ), capitolo AS (
    SELECT e.elem_code,
                    e.elem_code2,
                    e.elem_code3,
                    tipo.elem_tipo_code,
                    tipo.elem_tipo_desc,
                    stato.elem_stato_code,
                    stato.elem_stato_desc,
                    per.anno AS elem_anno_bilancio,
                    per_det.anno AS elem_det_anno,
                    det.elem_det_importo,
                    e.elem_id,
                    det.elem_det_id,
                    det.elem_det_tipo_id,
                    bil.bil_id,
                    per.periodo_id,
                    per_det.periodo_id AS periodo_det_id,
                    e.ente_proprietario_id
    FROM siac_t_bil_elem e,
                    siac_d_bil_elem_tipo tipo,
                    siac_r_bil_elem_stato rs,
                    siac_d_bil_elem_stato stato,
                    siac_t_bil bil,
                    siac_t_periodo per,
                    siac_t_bil_elem_det det,
                    siac_d_bil_elem_det_tipo tipo_det,
                    siac_t_periodo per_det
    WHERE (tipo.elem_tipo_code::text = ANY (ARRAY['CAP-UG'::character varying,
        'CAP-UP'::character varying]::text[])) AND e.elem_tipo_id = tipo.elem_tipo_id AND rs.elem_id = e.elem_id AND stato.elem_stato_id = rs.elem_stato_id AND bil.bil_id = e.bil_id AND per.periodo_id = bil.periodo_id AND det.elem_id = e.elem_id AND tipo_det.elem_det_tipo_id = det.elem_det_tipo_id AND tipo_det.elem_det_tipo_code::text = 'STA'::text AND per_det.periodo_id = det.periodo_id AND e.data_cancellazione IS NULL AND det.data_cancellazione IS NULL AND rs.data_cancellazione IS NULL AND rs.validita_fine IS NULL
    ), capitolo_det_comp AS (
    SELECT comp.elem_det_comp_id,
                    comp.elem_det_id,
                    comp.elem_det_comp_tipo_id,
                    comp.elem_det_importo,
                    comp.validita_inizio,
                    comp.validita_fine,
                    comp.ente_proprietario_id,
                    comp.data_creazione,
                    comp.data_modifica,
                    comp.data_cancellazione,
                    comp.login_operazione
    FROM siac_t_bil_elem_det_comp comp
    WHERE comp.data_cancellazione IS NULL
    )
    SELECT capitolo.elem_code AS elem_code_capitolo,
            capitolo.elem_code2 AS elem_code_articolo,
            capitolo.elem_code3 AS elem_code_ueb,
            capitolo.elem_tipo_code AS elem_tipo_code_capitolo,
            capitolo.elem_tipo_desc AS elem_tipo_desc_capitolo,
            capitolo.elem_stato_code AS elem_stato_code_capitolo,
            capitolo.elem_stato_desc AS elem_stato_desc_capitolo,
            capitolo.elem_anno_bilancio,
            capitolo.elem_det_anno,
            capitolo.elem_det_importo,
            capitolo.elem_id,
            capitolo.elem_det_id,
            capitolo.elem_det_tipo_id,
            capitolo.bil_id,
            capitolo.periodo_id,
            capitolo.periodo_det_id,
            capitolo.ente_proprietario_id,
            capitolo_det_comp.elem_det_importo AS elem_det_comp_importo,
            comp_tipo.elem_det_comp_macro_tipo_code,
            comp_tipo.elem_det_comp_macro_tipo_desc,
            comp_tipo.elem_det_comp_sotto_tipo_code,
            comp_tipo.elem_det_comp_sotto_tipo_desc,
            comp_tipo.elem_det_comp_tipo_code,
            comp_tipo.elem_det_comp_tipo_desc,
            comp_tipo.elem_det_comp_tipo_ambito_code,
            comp_tipo.elem_det_comp_tipo_ambito_desc,
            comp_tipo.elem_det_comp_tipo_fonte_code,
            comp_tipo.elem_det_comp_tipo_fonte_desc,
            comp_tipo.elem_det_comp_tipo_fase_code,
            comp_tipo.elem_det_comp_tipo_fase_desc,
            comp_tipo.elem_det_comp_tipo_def_code,
            comp_tipo.elem_det_comp_tipo_def_desc,
            comp_tipo.elem_det_comp_tipo_gest_aut,
            comp_tipo.elem_det_comp_tipo_anno,
            comp_tipo.elem_det_comp_periodo_id
    FROM capitolo,
            capitolo_det_comp,
            comp_tipo
    WHERE capitolo.elem_det_id = capitolo_det_comp.elem_det_id AND
        comp_tipo.elem_det_comp_tipo_id = capitolo_det_comp.elem_det_comp_tipo_id
    ) query,
    siac_t_ente_proprietario ente
WHERE query.ente_proprietario_id = ente.ente_proprietario_id;

alter view siac_v_dwh_bil_elem_comp_cap OWNER to siac;

