/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- View: siac.siac_v_dwh_bil_elem_comp_tipo

-- DROP VIEW siac.siac_v_dwh_bil_elem_comp_tipo;

CREATE OR REPLACE VIEW siac.siac_v_dwh_bil_elem_comp_tipo
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
	imp_tipo.elem_det_comp_tipo_imp_code, 
	imp_tipo.elem_det_comp_tipo_imp_desc,
    per.anno::integer AS elem_det_comp_tipo_anno,
    stato.elem_det_comp_tipo_stato_code,
    stato.elem_det_comp_tipo_stato_desc,
    tipo.validita_inizio,
    tipo.validita_fine
   FROM siac_t_ente_proprietario ente,
    siac_d_bil_elem_det_comp_tipo_stato stato,
    siac_d_bil_elem_det_comp_macro_tipo macro,
    siac_d_bil_elem_det_comp_tipo tipo
     LEFT JOIN siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo ON tipo.elem_det_comp_sotto_tipo_id = sotto_tipo.elem_det_comp_sotto_tipo_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo ON tipo.elem_det_comp_tipo_ambito_id = ambito_tipo.elem_det_comp_tipo_ambito_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fonte fonte_tipo ON tipo.elem_det_comp_tipo_fonte_id = fonte_tipo.elem_det_comp_tipo_fonte_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fase fase_tipo ON tipo.elem_det_comp_tipo_fase_id = fase_tipo.elem_det_comp_tipo_fase_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_def def_tipo ON tipo.elem_det_comp_tipo_def_id = def_tipo.elem_det_comp_tipo_def_id
	 --SIAC-7349
	 LEFT JOIN siac_d_bil_elem_det_comp_tipo_imp imp_tipo ON tipo.elem_det_comp_tipo_imp_id = imp_tipo.elem_det_comp_tipo_imp_id
     LEFT JOIN siac_t_periodo per ON tipo.periodo_id = per.periodo_id
  WHERE stato.ente_proprietario_id = ente.ente_proprietario_id AND stato.elem_det_comp_tipo_stato_id = tipo.elem_det_comp_tipo_stato_id AND macro.elem_det_comp_macro_tipo_id = tipo.elem_det_comp_macro_tipo_id AND tipo.data_cancellazione IS NULL;

ALTER TABLE siac.siac_v_dwh_bil_elem_comp_tipo
    OWNER TO siac;

