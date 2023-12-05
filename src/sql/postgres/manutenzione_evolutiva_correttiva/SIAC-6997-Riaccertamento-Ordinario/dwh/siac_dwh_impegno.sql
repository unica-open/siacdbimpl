/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE TABLE siac.siac_dwh_impegno (
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  bil_anno VARCHAR(4),
  cod_fase_operativa VARCHAR(200),
  desc_fase_operativa VARCHAR(500),
  anno_impegno INTEGER,
  num_impegno NUMERIC,
  desc_impegno VARCHAR(500),
  cod_impegno VARCHAR(200),
  cod_stato_impegno VARCHAR(200),
  desc_stato_impegno VARCHAR(500),
  data_scadenza TIMESTAMP WITHOUT TIME ZONE,
  parere_finanziario VARCHAR(1) DEFAULT 'FALSE'::character varying,
  cod_capitolo VARCHAR(200),
  cod_articolo VARCHAR(200),
  cod_ueb VARCHAR(200),
  desc_capitolo VARCHAR,
  desc_articolo VARCHAR,
  soggetto_id INTEGER,
  cod_soggetto VARCHAR(200),
  desc_soggetto VARCHAR(500),
  cf_soggetto CHAR(16),
  cf_estero_soggetto VARCHAR(500),
  p_iva_soggetto VARCHAR(500),
  cod_classe_soggetto VARCHAR(200),
  desc_classe_soggetto VARCHAR(500),
  cod_tipo_impegno VARCHAR(200),
  desc_tipo_impegno VARCHAR(500),
  cod_spesa_ricorrente VARCHAR(200),
  desc_spesa_ricorrente VARCHAR(500),
  cod_perimetro_sanita_spesa VARCHAR(200),
  desc_perimetro_sanita_spesa VARCHAR(500),
  cod_transazione_ue_spesa VARCHAR(200),
  desc_transazione_ue_spesa VARCHAR(500),
  cod_politiche_regionali_unit VARCHAR(200),
  desc_politiche_regionali_unit VARCHAR(500),
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
  cod_pdc_economico_i VARCHAR(200),
  desc_pdc_economico_i VARCHAR(500),
  cod_pdc_economico_ii VARCHAR(200),
  desc_pdc_economico_ii VARCHAR(500),
  cod_pdc_economico_iii VARCHAR(200),
  desc_pdc_economico_iii VARCHAR(500),
  cod_pdc_economico_iv VARCHAR(200),
  desc_pdc_economico_iv VARCHAR(500),
  cod_pdc_economico_v VARCHAR(200),
  desc_pdc_economico_v VARCHAR(500),
  cod_cofog_divisione VARCHAR(200),
  desc_cofog_divisione VARCHAR(500),
  cod_cofog_gruppo VARCHAR(200),
  desc_cofog_gruppo VARCHAR(500),
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
  annocapitoloorigine VARCHAR(4),
  numcapitoloorigine VARCHAR(200),
  annoorigineplur VARCHAR(4),
  numarticoloorigine VARCHAR(200),
  annoriaccertato VARCHAR(4),
  numriaccertato VARCHAR(200),
  numorigineplur VARCHAR(200),
  flagdariaccertamento VARCHAR(1),
  flagdareanno         VARCHAR(1), -- 19.02.2020 Sofia jira siac-7292
  anno_atto_amministrativo VARCHAR(4),
  num_atto_amministrativo VARCHAR(200),
  oggetto_atto_amministrativo VARCHAR(500),
  note_atto_amministrativo VARCHAR(500),
  cod_tipo_atto_amministrativo VARCHAR(200),
  desc_tipo_atto_amministrativo VARCHAR(500),
  desc_stato_atto_amministrativo VARCHAR(500),
  cod_cdr_atto_amministrativo VARCHAR(200),
  desc_cdr_atto_amministrativo VARCHAR(500),
  cod_cdc_atto_amministrativo VARCHAR(200),
  desc_cdc_atto_amministrativo VARCHAR(500),
  importo_iniziale NUMERIC,
  importo_attuale NUMERIC,
  importo_utilizzabile NUMERIC,
  note VARCHAR,
  anno_finanziamento VARCHAR(4),
  cig VARCHAR(500),
  cup VARCHAR(500),
  num_ueb_origine VARCHAR(500),
  validato VARCHAR(1),
  num_accertamento_finanziamento VARCHAR(500),
  importo_liquidato NUMERIC,
  importo_quietanziato NUMERIC,
  importo_emesso NUMERIC,
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  flagcassaeconomale VARCHAR(1),
  data_inizio_val_stato_imp TIMESTAMP WITHOUT TIME ZONE,
  data_inizio_val_imp TIMESTAMP WITHOUT TIME ZONE,
  data_creazione_imp TIMESTAMP WITHOUT TIME ZONE,
  data_modifica_imp TIMESTAMP WITHOUT TIME ZONE,
  cod_programma VARCHAR(200),
  desc_programma VARCHAR(500),
  flagprenotazione VARCHAR(1),
  flagprenotazioneliquidabile VARCHAR(1),
  flagfrazionabile VARCHAR(1),
  cod_siope_tipo_debito VARCHAR(200),
  desc_siope_tipo_debito VARCHAR(500),
  desc_siope_tipo_debito_bnkit VARCHAR(500),
  cod_siope_assenza_motivazione VARCHAR(200),
  desc_siope_assenza_motivazione VARCHAR(500),
  desc_siope_assenza_motiv_bnkit VARCHAR(500),
  -- 22.10.2018 Sofia siac-6336
  stato_programma varchar(200),
  versione_cronop varchar(200),
  desc_cronop varchar(500),
  anno_cronop varchar(4)
)
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_impegno.bil_anno
IS 'anno bilancio (siac_t_periodo.anno)';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_fase_operativa
IS 'cod fase operativa bilancio (siac_d_fase_operativa.fase_operativa_code,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_fase_operativa
IS 'desc fase operativa bilancio (siac_d_fase_operativa.fase_operativa_desc,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_impegno.anno_impegno
IS 'siac_t_movgest.movgest_anno con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_impegno.num_impegno
IS 'siac_t_movgest.movgest_num con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_impegno
IS 'siac_t_movgest.movgest_desc con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_impegno
IS 'siac_t_movgest_ts.movgest_ts_code con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_stato_impegno
IS 'siac_d_movgest_ts_stato.movgest_stato_code - stato del movgest_ts_id che ha siac_d_movgest_ts_tipo.movgest_ts_tipo_code=''T'' (testata)';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_stato_impegno
IS 'siac_d_movgest_ts_stato.movgest_stato_desc - stato del movgest_ts_id che ha siac_d_movgest_ts_tipo.movgest_ts_tipo_code=''T'' (testata)';

COMMENT ON COLUMN siac.siac_dwh_impegno.data_scadenza
IS 'siac_t_movgest_ts.movgest_ts_scadenza_data';

COMMENT ON COLUMN siac.siac_dwh_impegno.parere_finanziario
IS 'siac_t_movgest.parere_finanziario boolean impostare ''T ''o ''F''';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_capitolo
IS 'siac_t_bil_elem.elem_code, siac_r_movgest_bil_elem';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_articolo
IS 'siac_t_bil_elem.elem_code2, siac_r_movgest_bil_elem';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_ueb
IS 'siac_t_bil_elem.elem_code3, siac_r_movgest_bil_elem';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_capitolo
IS 'siac_t_bil_elem.elem_desc, siac_r_movgest_bil_elem';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_articolo
IS 'siac_t_bil_elem.elem_desc2, siac_r_movgest_bil_elem';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_soggetto
IS 'siac_t_soggetto.soggetto_code, siac_r_movgest_ts_sog - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_soggetto
IS 'siac_t_soggetto.soggetto_desc, siac_r_movgest_ts_sog - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_impegno.cf_soggetto
IS 'siac_t_soggetto.soggetto_cod_fiscale, siac_r_movgest_ts_sog - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_impegno.cf_estero_soggetto
IS 'siac_t_soggetto.soggetto_cod_fiscale_estero, siac_r_movgest_ts_sog - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_impegno.p_iva_soggetto
IS 'siac_t_soggetto.soggetto_p_iva, siac_r_movgest_ts_sog - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_classe_soggetto
IS 'siac_d_soggetto_classe.soggetto_classe_code, siac_r_movgest_ts_sogclasse - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_classe_soggetto
IS 'siac_d_soggetto_classe.soggetto_classe_desc, siac_r_movgest_ts_sogclasse - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_tipo_impegno
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) . Il valore può essere Svincolato, Finanziato con mutuo, Legato a progetto';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_tipo_impegno
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) . Il valore può essere Svincolato, Finanziato con mutuo, Legato a progetto';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_spesa_ricorrente
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_spesa_ricorrente
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_perimetro_sanita_spesa
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_perimetro_sanita_spesa
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_transazione_ue_spesa
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_transazione_ue_spesa
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_politiche_regionali_unit
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_politiche_regionali_unit
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_pdc_finanziario_i
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_pdc_finanziario_i
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_pdc_finanziario_ii
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_pdc_finanziario_ii
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_pdc_finanziario_iii
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_pdc_finanziario_iii
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_pdc_finanziario_iv
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_pdc_finanziario_iv
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_pdc_finanziario_v
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_pdc_finanziario_v
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_pdc_economico_i
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_pdc_economico_i
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_pdc_economico_ii
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_pdc_economico_ii
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_pdc_economico_iii
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_pdc_economico_iii
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_pdc_economico_iv
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_pdc_economico_iv
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_pdc_economico_v
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_pdc_economico_v
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_cofog_divisione
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_cofog_divisione
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_cofog_gruppo
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_cofog_gruppo
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_1
IS 'classificatore cod (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_1_valore
IS 'classificatore desc (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_1_desc_valore
IS 'classificatore valore (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_2
IS 'classificatore cod (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_2_valore
IS 'classificatore desc (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_2_desc_valore
IS 'classificatore valore (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_3
IS 'classificatore cod (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_3_valore
IS 'classificatore desc (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_3_desc_valore
IS 'classificatore valore (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_4
IS 'classificatore cod (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_4_valore
IS 'classificatore desc (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_4_desc_valore
IS 'classificatore valore (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_5
IS 'classificatore cod (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_5_valore
IS 'classificatore desc (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.classificatore_5_desc_valore
IS 'classificatore valore (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_impegno.annocapitoloorigine
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.numcapitoloorigine
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.annoorigineplur
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.numarticoloorigine
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.annoriaccertato
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.numriaccertato
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.numorigineplur
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.flagdariaccertamento
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr - boolean valorizzare con T o F';

COMMENT ON COLUMN siac.siac_dwh_impegno.anno_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_anno, siac_r_movgest_ts_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_impegno.num_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_num, siac_r_movgest_ts_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_impegno.oggetto_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_oggetto, siac_r_movgest_ts_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_impegno.note_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_note, siac_r_movgest_ts_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_stato_atto_amministrativo
IS 'desc stato atto amministrativo siac_d_atto_amm_stato.attoamm_stato_desc, siac_r_atto_amm_stato';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_cdr_atto_amministrativo
IS 'classificatore code collegato tramite siac_r_movgest_ts_atto_amm al movgest_ts_id di tipo ''T'' (testata) poi siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_cdr_atto_amministrativo
IS 'classificatore desc collegato tramite siac_r_movgest_ts_atto_amm al movgest_ts_id di tipo ''T'' (testata) poi siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam';

COMMENT ON COLUMN siac.siac_dwh_impegno.cod_cdc_atto_amministrativo
IS 'classificatore code collegato tramite siac_r_movgest_ts_atto_amm al movgest_ts_id di tipo ''T'' (testata) poi siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam';

COMMENT ON COLUMN siac.siac_dwh_impegno.desc_cdc_atto_amministrativo
IS 'classificatore desc collegato tramite siac_r_movgest_ts_atto_amm al movgest_ts_id di tipo ''T'' (testata) poi siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam';

COMMENT ON COLUMN siac.siac_dwh_impegno.importo_iniziale
IS 'siac_t_movgest_ts_det con movgest_ts_id che ha siac_d_movgest_ts_tipo.movgest_ts_tipo_code=''T'' (testata)';

COMMENT ON COLUMN siac.siac_dwh_impegno.importo_attuale
IS 'siac_t_movgest_ts_det con movgest_ts_id che ha siac_d_movgest_ts_tipo.movgest_ts_tipo_code=''T'' (testata)';

COMMENT ON COLUMN siac.siac_dwh_impegno.importo_utilizzabile
IS 'siac_t_movgest_ts_det con movgest_ts_id che ha siac_d_movgest_ts_tipo.movgest_ts_tipo_code=''T'' (testata)';

COMMENT ON COLUMN siac.siac_dwh_impegno.note
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.anno_finanziamento
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.cig
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.cup
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.num_ueb_origine
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.validato
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.num_accertamento_finanziamento
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_impegno.importo_liquidato
IS ' la somma degli importi delle liquidazioni non annullate collegate all''impegno  è il campo in output tot_imp_liq della fnc_siac_disponibilitaliquidaremovgest  select coalesce(sum(b.liq_importo),0)   tot_imp_liq from siac_r_liquidazione_movgest a, siac_t_liquidazione b, siac_d_liquidazione_stato c, siac_r_liquidazione_stato d where a.movgest_ts_id = :movgest_ts_id_in and a.liq_id = b.liq_id and a.data_cancellazione is null and now() between  a.validita_inizio  and coalesce(a.validita_fine, now())  and b.data_cancellazione is null and now() between  b.validita_inizio  and coalesce(b.validita_fine, now()) and c.data_cancellazione is null and now() between  c.validita_inizio  and coalesce(c.validita_fine, now()) and d.data_cancellazione is null and now() between  d.validita_inizio  and coalesce(d.validita_fine, now()) and b.liq_id = d.liq_id and d.liq_stato_id = c.liq_stato_id and c.liq_stato_code <> ''A'';';

COMMENT ON COLUMN siac.siac_dwh_impegno.importo_quietanziato
IS 'somma delle quote ordinativo degli ordinativi che hanno già la data quietanza collegati a  liquidazioni non annullate collegate all''impegno';

COMMENT ON COLUMN siac.siac_dwh_impegno.importo_emesso
IS 'la somma di tutti i subordinativi validi indipendentemente dalla loro quietanza';

COMMENT ON COLUMN siac.siac_dwh_impegno.flagcassaeconomale
IS 'flagCassaEconomale siac_t_attr.attr_code=''flagCassaEconomale'' , siac_r_movgest_ts_attr (x Coge)';