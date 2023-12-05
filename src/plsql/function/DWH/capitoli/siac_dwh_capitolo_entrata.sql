/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_capitolo_entrata (
  ente_proprietario_id INTEGER NOT NULL,
  ente_denominazione VARCHAR(500),
  bil_anno VARCHAR(4),
  cod_fase_operativa VARCHAR(200),
  desc_fase_operativa VARCHAR(500),
  cod_capitolo VARCHAR(200),
  cod_articolo VARCHAR(200),
  cod_ueb VARCHAR(200),
  desc_capitolo VARCHAR,
  desc_articolo VARCHAR,
  cod_tipo_capitolo VARCHAR(200),
  desc_tipo_capitolo VARCHAR(500),
  cod_stato_capitolo VARCHAR(200),
  desc_stato_capitolo VARCHAR(500),
  cod_classificazione_capitolo VARCHAR(200),
  desc_classificazione_capitolo VARCHAR(500),
  cod_titolo_entrata VARCHAR(200),
  desc_titolo_entrata VARCHAR(500),
  cod_tipologia_entrata VARCHAR(200),
  desc_tipologia_entrata VARCHAR(500),
  cod_categoria_entrata VARCHAR(200),
  desc_categoria_entrata VARCHAR(500),
  cod_pdc_finanziario_i VARCHAR(200),
  desc_pdc_finanziario_i VARCHAR(500),
  cod_pdc_finanziario_ii VARCHAR(200),
  desc_pdc_finanziario_ii VARCHAR(500),
  cod_pdc_finanziario_iii VARCHAR(200),
  desc_pdc_finanziario_iii VARCHAR(500),
  cod_pdc_finanziario_iv VARCHAR(200),
  desc_pdc_finanziario_iv VARCHAR(500),
  cod_pdc_finanziario_v VARCHAR(200),
  desc_pdc_finanziario_v VARCHAR(500),
  cod_cofog_divisione VARCHAR(200),
  desc_cofog_divisione VARCHAR(500),
  cod_cofog_gruppo VARCHAR(200),
  desc_cofog_gruppo VARCHAR(500),
  cod_cdr VARCHAR(200),
  desc_cdr VARCHAR(500),
  cod_cdc VARCHAR(200),
  desc_cdc VARCHAR(500),
  cod_siope_i_entrata VARCHAR(200),
  desc_siope_i_entrata VARCHAR(500),
  cod_siope_ii_entrata VARCHAR(200),
  desc_siope_ii_entrata VARCHAR(500),
  cod_siope_iii_entrata VARCHAR(200),
  desc_siope_iii_entrata VARCHAR(500),
  cod_entrata_ricorrente VARCHAR(200),
  desc_entrata_ricorrente VARCHAR(500),
  cod_transazione_entrata_ue VARCHAR(200),
  desc_transazione_entrata_ue VARCHAR(500),
  cod_tipo_fondo VARCHAR(200),
  desc_tipo_fondo VARCHAR(500),
  cod_tipo_finanziamento VARCHAR(200),
  desc_tipo_finanziamento VARCHAR(500),
  cod_perimetro_sanita_entrata VARCHAR(200),
  desc_perimetro_sanita_entrata VARCHAR(500),
  classificatore_1 VARCHAR(500),
  classificatore_1_valore VARCHAR(200),
  classificatore_1_desc_valore VARCHAR(500),
  classificatore_2 VARCHAR(500),
  classificatore_2_valore VARCHAR(200),
  classificatore_2_desc_valore VARCHAR(500),
  classificatore_3 VARCHAR(500),
  classificatore_3_valore VARCHAR(200),
  classificatore_3_desc_valore VARCHAR(500),
  classificatore_4 VARCHAR(500),
  classificatore_4_valore VARCHAR(200),
  classificatore_4_desc_valore VARCHAR(500),
  classificatore_5 VARCHAR(500),
  classificatore_5_valore VARCHAR(200),
  classificatore_5_desc_valore VARCHAR(500),
  classificatore_6 VARCHAR(500),
  classificatore_6_valore VARCHAR(200),
  classificatore_6_desc_valore VARCHAR(500),
  classificatore_7 VARCHAR(500),
  classificatore_7_valore VARCHAR(200),
  classificatore_7_desc_valore VARCHAR(500),
  classificatore_8 VARCHAR(500),
  classificatore_8_valore VARCHAR(200),
  classificatore_8_desc_valore VARCHAR(500),
  classificatore_9 VARCHAR(500),
  classificatore_9_valore VARCHAR(200),
  classificatore_9_desc_valore VARCHAR(500),
  classificatore_10 VARCHAR(500),
  classificatore_10_valore VARCHAR(200),
  classificatore_10_desc_valore VARCHAR(500),
  classificatore_11 VARCHAR(500),
  classificatore_11_valore VARCHAR(200),
  classificatore_11_desc_valore VARCHAR(500),
  classificatore_12 VARCHAR(500),
  classificatore_12_valore VARCHAR(200),
  classificatore_12_desc_valore VARCHAR(500),
  classificatore_13 VARCHAR(500),
  classificatore_13_valore VARCHAR(200),
  classificatore_13_desc_valore VARCHAR(500),
  classificatore_14 VARCHAR(500),
  classificatore_14_valore VARCHAR(200),
  classificatore_14_desc_valore VARCHAR(500),
  classificatore_15 VARCHAR(500),
  classificatore_15_valore VARCHAR(200),
  classificatore_15_desc_valore VARCHAR(500),
  flagentratericorrenti VARCHAR(1),
  flagimpegnabile VARCHAR(1),
  flagpermemoria VARCHAR(1),
  flagrilevanteiva VARCHAR(1),
  flag_trasf_organi_comunitari VARCHAR(1),
  note VARCHAR(500),
  cod_stipendio VARCHAR(200),
  desc_stipendio VARCHAR(500),
  cod_attivita_iva VARCHAR(200),
  desc_attivita_iva VARCHAR(500),
  massimo_impegnabile_anno1 NUMERIC,
  stanz_cassa_anno1 NUMERIC,
  stanz_cassa_iniziale_anno1 NUMERIC,
  stanz_residuo_iniziale_anno1 NUMERIC,
  stanz_anno1 NUMERIC,
  stanz_iniziale_anno1 NUMERIC,
  stanz_residuo_anno1 NUMERIC,
  flag_anno1 VARCHAR(1),
  massimo_impegnabile_anno2 NUMERIC,
  stanz_cassa_anno2 NUMERIC,
  stanz_cassa_iniziale_anno2 NUMERIC,
  stanz_residuo_iniziale_anno2 NUMERIC,
  stanz_anno2 NUMERIC,
  stanz_iniziale_anno2 NUMERIC,
  stanz_residuo_anno2 NUMERIC,
  flag_anno2 VARCHAR(1),
  massimo_impegnabile_anno3 NUMERIC,
  stanz_cassa_anno3 NUMERIC,
  stanz_cassa_iniziale_anno3 NUMERIC,
  stanz_residuo_iniziale_anno3 NUMERIC,
  stanz_anno3 NUMERIC,
  stanz_iniziale_anno3 NUMERIC,
  stanz_residuo_anno3 NUMERIC,
  flag_anno3 VARCHAR(1),
  disponibilita_accertare_anno1 NUMERIC,
  disponibilita_accertare_anno2 NUMERIC,
  disponibilita_accertare_anno3 NUMERIC,
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  flagaccertatopercassa VARCHAR(1),
  ex_anno VARCHAR(4),
  ex_capitolo VARCHAR(200),
  ex_articolo VARCHAR(200),
  flag_pertinente_fcde varchar(1) NULL
)
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.ente_proprietario_id
IS 'ente (siac_t_ente_proprietario)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.ente_denominazione
IS 'denominazione ente (siac_t_ente_proprietario.ente_denominazione)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.bil_anno
IS 'anno bilancio (siac_t_periodo.anno)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_fase_operativa
IS 'cod fase operativa bilancio (siac_d_fase_operativa.fase_operativa_code,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_fase_operativa
IS 'desc fase operativa bilancio (siac_d_fase_operativa.fase_operativa_desc,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_capitolo
IS 'cod capitolo (siac_t_bil_elem.elem_code)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_articolo
IS 'cod articolo (siac_t_bil_elem.elem_code2)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_ueb
IS 'cod ueb (siac_t_bil_elem.elem_code3)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_capitolo
IS 'desc capitolo (siac_t_bil_elem.elem_desc)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_articolo
IS 'desc articolo (siac_t_bil_elem.elem_desc2)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_tipo_capitolo
IS 'cod tipo capitolo (siac_d_bil_elem_tipo.elem_tipo_code)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_tipo_capitolo
IS 'desc tipo capitolo siac_d_bil_elem_tipo.elem_tipo_desc)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_stato_capitolo
IS 'cod stato capitolo (siac_d_bil_elem_stato.elem_stato_code,siac_r_bil_elem_stato)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_stato_capitolo
IS 'cod stato capitolo (siac_d_bil_elem_stato.elem_stato_desc,siac_r_bil_elem_stato)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_classificazione_capitolo
IS 'cod categoria capitolo siac_d_bil_elem_categoria.elem_cat_code, siac_r_bil_elem_categoria';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_classificazione_capitolo
IS 'desc categoria capitolo siac_d_bil_elem_categoria.elem_cat_desc, siac_r_bil_elem_categoria';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_titolo_entrata
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_titolo_entrata
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_tipologia_entrata
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_tipologia_entrata
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_categoria_entrata
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_categoria_entrata
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_pdc_finanziario_i
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_pdc_finanziario_i
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_pdc_finanziario_ii
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_pdc_finanziario_ii
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_pdc_finanziario_iii
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_pdc_finanziario_iii
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_pdc_finanziario_iv
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_pdc_finanziario_iv
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_pdc_finanziario_v
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_pdc_finanziario_v
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_cofog_divisione
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_cofog_divisione
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_cofog_gruppo
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_cofog_gruppo
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_cdr
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_cdr
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_cdc
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_cdc
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_siope_i_entrata
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_siope_i_entrata
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_siope_ii_entrata
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_siope_ii_entrata
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_siope_iii_entrata
IS 'classificatore cod (siac_t_class.classif_code, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_siope_iii_entrata
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_entrata_ricorrente
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_entrata_ricorrente
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_transazione_entrata_ue
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_transazione_entrata_ue
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_tipo_fondo
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_tipo_fondo
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_tipo_finanziamento
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_tipo_finanziamento
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_perimetro_sanita_entrata
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_perimetro_sanita_entrata
IS 'classificatore desc (siac_t_class.classif_desc, siac_r_bil_elem_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_1
IS 'classificatore cod (siac_d_class_tipo.classif_tipo_desc) - i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_1_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_1_desc_valore
IS 'classificatore cod (siac_t_class.classif_desc,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_2
IS 'classificatore cod (siac_d_class_tipo.classif_tipo_desc) - i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_2_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_2_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_3
IS 'classificatore cod (siac_d_class_tipo.classif_tipo_desc) - i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_3_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_3_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_4
IS 'classificatore cod (siac_d_class_tipo.classif_tipo_desc) - i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_4_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_4_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_5
IS 'classificatore cod (siac_d_class_tipo.classif_tipo_desc) - i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_5_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_5_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_6
IS 'classificatore cod (siac_d_class_tipo.classif_tipo_desc) - i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_6_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_6_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_7
IS 'classificatore cod (siac_d_class_tipo.classif_tipo_desc) - i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_7_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_7_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_8
IS 'classificatore cod (siac_d_class_tipo.classif_tipo_desc) - i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_8_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_8_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_9
IS 'classificatore cod (siac_d_class_tipo.classif_tipo_desc) - i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_9_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_9_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_10
IS 'classificatore cod (siac_d_class_tipo.classif_tipo_desc) - i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_10_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_10_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_11
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_11_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_11_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_12
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_12_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_12_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_13
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_13_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_13_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_14
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_14_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_14_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_15
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_15_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.classificatore_15_desc_valore
IS 'classificatore cod (siac_t_class.classif_code,siac_r_bil_elem_class) i classificatori generici di entrata e spesa sono diversi';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.flagentratericorrenti
IS 'attributo (siac_t_attr, siac_r_bil_elem_attr)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.flagimpegnabile
IS 'attributo (siac_t_attr, siac_r_bil_elem_attr)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.flagpermemoria
IS 'attributo (siac_t_attr, siac_r_bil_elem_attr)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.flagrilevanteiva
IS 'attributo (siac_t_attr, siac_r_bil_elem_attr)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.flag_trasf_organi_comunitari
IS 'attributo (siac_t_attr, siac_r_bil_elem_attr)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.note
IS 'attributo (siac_t_attr, siac_r_bil_elem_attr)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_stipendio
IS 'cod stipendio (siac_r_bil_elem_stipendio_cod,siac_d_stipendio_cod.stipcode_code)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_stipendio
IS 'desc stipendio (siac_r_bil_elem_stipendio_cod,siac_d_stipendio_cod.stipcode_desc';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.cod_attivita_iva
IS 'cod attività iva (siac_r_bil_elem_iva_attivita,siac_t_iva_attivita.ivaatt_code)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.desc_attivita_iva
IS 'desc attività iva  (siac_r_bil_elem_iva_attivita,siac_t_iva_attivita.ivaatt_desc)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.massimo_impegnabile_anno1
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_cassa_anno1
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_cassa_iniziale_anno1
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_residuo_iniziale_anno1
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_anno1
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_iniziale_anno1
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_residuo_anno1
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.flag_anno1
IS 'dettaglio - deriva da boolean -- impostare T o F';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.massimo_impegnabile_anno2
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_cassa_anno2
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_cassa_iniziale_anno2
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_residuo_iniziale_anno2
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_anno2
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_iniziale_anno2
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_residuo_anno2
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.flag_anno2
IS 'dettaglio - deriva da boolean -- impostare T o F';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.massimo_impegnabile_anno3
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_cassa_anno3
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_cassa_iniziale_anno3
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_residuo_iniziale_anno3
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_anno3
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_iniziale_anno3
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.stanz_residuo_anno3
IS 'dettaglio (siac_t_bil_elem_det.elem_det.importo di tipo su siac_d_bil_elem_det_tipo)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.flag_anno3
IS 'dettaglio - deriva da boolean -- impostare T o F';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.disponibilita_accertare_anno1
IS 'calcolato con function fnc_siac_disponibilitaaccertareeg_anno1 (parametro in elem_id output numeric)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.disponibilita_accertare_anno2
IS 'calcolato con function fnc_siac_disponibilitaaccertareeg_anno2 (parametro in elem_id output numeric)';

COMMENT ON COLUMN siac.siac_dwh_capitolo_entrata.disponibilita_accertare_anno3
IS 'calcolato con function fnc_siac_disponibilitaaccertareeg_anno2 (parametro in elem_id output numeric)';