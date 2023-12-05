/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop VIEW if exists siac.siac_v_dwh_variazione_bil_comp;

CREATE OR REPLACE VIEW siac.siac_v_dwh_variazione_bil_comp
AS SELECT tb.bil_anno,
    tb.numero_variazione,
    tb.desc_variazione,
    tb.cod_stato_variazione,
    tb.desc_stato_variazione,
    tb.cod_tipo_variazione,
    tb.desc_tipo_variazione,
    tb.anno_atto_amministrativo,
    tb.numero_atto_amministrativo,
    tb.cod_tipo_atto_amministrativo,
    tb.cod_capitolo,
    tb.cod_articolo,
    tb.cod_ueb,
    tb.cod_tipo_capitolo,
    tb.importo,
    tb.tipo_importo,
    tb.anno_variazione,
    tb.attoamm_id,
    tb.ente_proprietario_id,
    tb.cod_sac,
    tb.desc_sac,
    tb.tipo_sac,
    tb.data_definizione,
    tb.data_apertura_proposta,
    tb.data_chiusura_proposta,
    tb.cod_sac_proposta,
    tb.desc_sac_proposta,
    tb.tipo_sac_proposta,
    tb.elem_det_comp_tipo_code,
    tb.elem_det_comp_macro_tipo_code,
    tb.elem_det_comp_sotto_tipo_code,
    tb.elem_det_comp_tipo_ambito_code,
    tb.elem_det_comp_tipo_fonte_code,
    tb.elem_det_comp_tipo_fase_code,
    tb.elem_det_comp_tipo_def_code,
    tb.elem_det_comp_tipo_gest_aut,
    tb.componente,
    tb.importo_componente
   FROM ( WITH variaz AS (
                 SELECT p.anno AS bil_anno,
                    e.variazione_num AS numero_variazione,
                    e.variazione_desc AS desc_variazione,
               --     d.variazione_stato_tipo_code AS cod_stato_variazione,
--                    d.variazione_stato_tipo_desc AS desc_stato_variazione,
                     -- siac-8829 - 12.10.2022 Sofia
                    ( case  when d.variazione_stato_tipo_code='BD' then 'B' else  d.variazione_stato_tipo_code end )::varchar(200) as cod_stato_variazione,
                    ( case  when d.variazione_stato_tipo_code='BD' then 'BOZZA' else  d.variazione_stato_tipo_desc end )::varchar(200) as desc_stato_variazione,
                    f.variazione_tipo_code AS cod_tipo_variazione,
                    f.variazione_tipo_desc AS desc_tipo_variazione,
                    a.elem_code AS cod_capitolo,
                    a.elem_code2 AS cod_articolo,
                    a.elem_code3 AS cod_ueb,
                    i.elem_tipo_code AS cod_tipo_capitolo,
                    b.elem_det_importo AS importo,
                    h.elem_det_tipo_desc AS tipo_importo,
                    l.anno AS anno_variazione,
                    c.attoamm_id,
                    a.ente_proprietario_id,
                        CASE
                            WHEN d.variazione_stato_tipo_code::text = 'D'::text THEN c.validita_inizio
                            ELSE NULL::timestamp without time zone
                        END AS data_definizione,
                    e.data_apertura_proposta,
                    e.data_chiusura_proposta,
                    e.classif_id,
                    b.elem_det_var_id AS importo_var_id
                   FROM siac_t_bil_elem a,
                    siac_t_bil_elem_det_var b,
                    siac_r_variazione_stato c,
                    siac_d_variazione_stato d,
                    siac_t_variazione e,
                    siac_d_variazione_tipo f,
                    siac_t_bil g,
                    siac_d_bil_elem_det_tipo h,
                    siac_d_bil_elem_tipo i,
                    siac_t_periodo l,
                    siac_t_periodo p
                  WHERE a.elem_id = b.elem_id AND c.variazione_stato_id = b.variazione_stato_id AND c.variazione_stato_tipo_id = d.variazione_stato_tipo_id AND c.variazione_id = e.variazione_id AND f.variazione_tipo_id = e.variazione_tipo_id AND b.data_cancellazione IS NULL AND a.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND g.bil_id = e.bil_id AND h.elem_det_tipo_id = b.elem_det_tipo_id AND i.elem_tipo_id = a.elem_tipo_id AND l.periodo_id = b.periodo_id AND p.periodo_id = g.periodo_id
                ), attoamm AS (
                 SELECT m.attoamm_id,
                    m.attoamm_anno AS anno_atto_amministrativo,
                    m.attoamm_numero AS numero_atto_amministrativo,
                    q.attoamm_tipo_code AS cod_tipo_atto_amministrativo
                   FROM siac_t_atto_amm m,
                    siac_d_atto_amm_tipo q
                  WHERE q.attoamm_tipo_id = m.attoamm_tipo_id AND m.data_cancellazione IS NULL AND q.data_cancellazione IS NULL
                ), sac AS (
                 SELECT i.attoamm_id,
                    l.classif_id,
                    l.classif_code,
                    l.classif_desc,
                    m.classif_tipo_code
                   FROM siac_r_atto_amm_class i,
                    siac_t_class l,
                    siac_d_class_tipo m,
                    siac_r_class_fam_tree n,
                    siac_t_class_fam_tree o,
                    siac_d_class_fam p
                  WHERE i.classif_id = l.classif_id AND m.classif_tipo_id = l.classif_tipo_id AND n.classif_id = l.classif_id AND n.classif_fam_tree_id = o.classif_fam_tree_id AND o.classif_fam_id = p.classif_fam_id AND p.classif_fam_code::text = '00005'::text AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL AND n.data_cancellazione IS NULL
                ), str_proposta AS (
                 SELECT tipo.classif_tipo_code,
                    c.classif_code,
                    c.classif_desc,
                    c.classif_id
                   FROM siac_t_class c,
                    siac_d_class_tipo tipo
                  WHERE (tipo.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])) AND c.classif_tipo_id = tipo.classif_tipo_id AND c.data_cancellazione IS NULL
                ), componente AS (
                 SELECT macro.elem_det_comp_macro_tipo_code,
                    macro.elem_det_comp_macro_tipo_desc,
                    sotto_tipo.elem_det_comp_sotto_tipo_code,
                    sotto_tipo.elem_det_comp_sotto_tipo_desc,
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
                            WHEN tipo.elem_det_comp_tipo_gest_aut = true THEN 'Solo automatica'::text
                            ELSE 'Manuale'::text
                        END::character varying(50) AS elem_det_comp_tipo_gest_aut,
                    imp_tipo.elem_det_comp_tipo_imp_code,
                    imp_tipo.elem_det_comp_tipo_imp_desc,
                    per.anno::integer AS elem_det_comp_tipo_anno,
                    tipo.elem_det_comp_tipo_id,
                    per.periodo_id AS elem_det_comp_periodo_id,
                    comp.elem_det_comp_id
                   FROM siac_d_bil_elem_det_comp_tipo_stato stato,
                    siac_d_bil_elem_det_comp_macro_tipo macro,
                    siac_d_bil_elem_det_comp_tipo tipo
                     LEFT JOIN siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo ON tipo.elem_det_comp_sotto_tipo_id = sotto_tipo.elem_det_comp_sotto_tipo_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo ON tipo.elem_det_comp_tipo_ambito_id = ambito_tipo.elem_det_comp_tipo_ambito_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fonte fonte_tipo ON tipo.elem_det_comp_tipo_fonte_id = fonte_tipo.elem_det_comp_tipo_fonte_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fase fase_tipo ON tipo.elem_det_comp_tipo_fase_id = fase_tipo.elem_det_comp_tipo_fase_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_def def_tipo ON tipo.elem_det_comp_tipo_def_id = def_tipo.elem_det_comp_tipo_def_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_imp imp_tipo ON tipo.elem_det_comp_tipo_imp_id = imp_tipo.elem_det_comp_tipo_imp_id
                     LEFT JOIN siac_t_periodo per ON tipo.periodo_id = per.periodo_id
                     LEFT JOIN siac_t_bil_elem_det_comp comp ON tipo.elem_det_comp_tipo_id = comp.elem_det_comp_tipo_id
                  WHERE stato.elem_det_comp_tipo_stato_id = tipo.elem_det_comp_tipo_stato_id AND macro.elem_det_comp_macro_tipo_id = tipo.elem_det_comp_macro_tipo_id AND tipo.data_cancellazione IS NULL
                )
         SELECT variaz.bil_anno,
            variaz.numero_variazione,
            variaz.desc_variazione,
            variaz.cod_stato_variazione,
            variaz.desc_stato_variazione,
            variaz.cod_tipo_variazione,
            variaz.desc_tipo_variazione,
            attoamm.anno_atto_amministrativo,
            attoamm.numero_atto_amministrativo,
            attoamm.cod_tipo_atto_amministrativo,
            variaz.cod_capitolo,
            variaz.cod_articolo,
            variaz.cod_ueb,
            variaz.cod_tipo_capitolo,
            variaz.importo,
            variaz.tipo_importo,
            variaz.anno_variazione,
            variaz.attoamm_id,
            variaz.ente_proprietario_id,
            sac.classif_code AS cod_sac,
            sac.classif_desc AS desc_sac,
            sac.classif_tipo_code AS tipo_sac,
            variaz.data_definizione,
            variaz.data_apertura_proposta,
            variaz.data_chiusura_proposta,
            str_proposta.classif_code AS cod_sac_proposta,
            str_proposta.classif_desc AS desc_sac_proposta,
            str_proposta.classif_tipo_code AS tipo_sac_proposta,
            componente.elem_det_comp_tipo_id::character varying(200) AS elem_det_comp_tipo_code,
            componente.elem_det_comp_macro_tipo_code,
            componente.elem_det_comp_sotto_tipo_code,
            componente.elem_det_comp_tipo_ambito_code,
            componente.elem_det_comp_tipo_fonte_code,
            componente.elem_det_comp_tipo_fase_code,
            componente.elem_det_comp_tipo_def_code,
            componente.elem_det_comp_tipo_gest_aut,
            componente.elem_det_comp_tipo_desc AS componente,
            comp_var.elem_det_importo AS importo_componente
           FROM variaz
             LEFT JOIN attoamm ON variaz.attoamm_id = attoamm.attoamm_id
             LEFT JOIN sac ON variaz.attoamm_id = sac.attoamm_id
             LEFT JOIN str_proposta ON variaz.classif_id = str_proposta.classif_id
             LEFT JOIN siac_t_bil_elem_det_var_comp comp_var ON variaz.importo_var_id = comp_var.elem_det_var_id
             LEFT JOIN componente ON comp_var.elem_det_comp_id = componente.elem_det_comp_id) tb
  ORDER BY tb.ente_proprietario_id, tb.bil_anno, tb.numero_variazione, tb.cod_capitolo, tb.anno_variazione;
  
 alter VIEW siac.siac_v_dwh_variazione_bil_comp owner to siac;