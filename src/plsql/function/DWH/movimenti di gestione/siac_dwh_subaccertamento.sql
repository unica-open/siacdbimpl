/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_subaccertamento (
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  bil_anno VARCHAR(4),
  cod_fase_operativa VARCHAR(200),
  desc_fase_operativa VARCHAR(500),
  anno_accertamento INTEGER,
  num_accertamento NUMERIC,
  desc_accertamento VARCHAR(500),
  cod_subaccertamento VARCHAR(200),
  desc_subaccertamento VARCHAR(500),
  cod_stato_subaccertamento VARCHAR(200),
  desc_stato_subaccertamento VARCHAR(500),
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
  cod_entrata_ricorrente VARCHAR(200),
  desc_entrata_ricorrente VARCHAR(500),
  cod_perimetro_sanita_entrata VARCHAR(200),
  desc_perimetro_sanita_entrata VARCHAR(500),
  cod_transazione_ue_entrata VARCHAR(200),
  desc_transazione_ue_entrata VARCHAR(500),
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
  numcapitoloorigine VARCHAR(500),
  annoorigineplur VARCHAR(4),
  numarticoloorigine VARCHAR(500),
  annoriaccertato VARCHAR(4),
  numriaccertato VARCHAR(500),
  numorigineplur VARCHAR(500),
  flagdariaccertamento VARCHAR(1),
  anno_atto_amministrativo VARCHAR(4),
  num_atto_amministrativo VARCHAR(500),
  oggetto_atto_amministrativo VARCHAR(500),
  note_atto_amministrativo VARCHAR,
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
  automatico VARCHAR(1),
  note VARCHAR,
  validato VARCHAR(1),
  num_ueb_origine VARCHAR(500),
  importo_quietanziato NUMERIC,
  importo_emesso NUMERIC,
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  flagcollegamentoaccertamentofattura VARCHAR(1)
) 
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.bil_anno
IS 'anno bilancio (siac_t_periodo.anno)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_fase_operativa
IS 'cod fase operativa bilancio (siac_d_fase_operativa.fase_operativa_code,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_fase_operativa
IS 'desc fase operativa bilancio (siac_d_fase_operativa.fase_operativa_desc,siac_r_bil_fase_operativa)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.anno_accertamento
IS 'siac_t_movgest.movgest_anno con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.num_accertamento
IS 'siac_t_movgest.movgest_num con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_accertamento
IS 'siac_t_movgest.movgest_desc con movgest_tipo_id dove siac_d_movgest_tipo.movgest_tipo_code=''I''';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_subaccertamento
IS 'siac_t_movgest_ts.movgest_ts_code con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo S testata';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_subaccertamento
IS 'siac_t_movgest_ts.movgest_ts_desc con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo S testata';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_stato_subaccertamento
IS 'siac_d_movgest_ts_stato.movgest_stato_code - stato del movgest_ts_id che ha siac_d_movgest_ts_tipo.movgest_ts_tipo_code=''S'' (testata)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_stato_subaccertamento
IS 'siac_d_movgest_ts_stato.movgest_stato_desc - stato del movgest_ts_id che ha siac_d_movgest_ts_tipo.movgest_ts_tipo_code=''S'' (testata)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.data_scadenza
IS 'siac_t_movgest_ts.movgest_ts_scadenza_data';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.parere_finanziario
IS 'siac_t_movgest.parere_finanziario boolean impostare ''T ''o ''F''';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_capitolo
IS 'siac_t_bil_elem.elem_code, siac_r_movgest_bil_elem';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_articolo
IS 'siac_t_bil_elem.elem_code2, siac_r_movgest_bil_elem';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_ueb
IS 'siac_t_bil_elem.elem_code3, siac_r_movgest_bil_elem';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_capitolo
IS 'siac_t_bil_elem.elem_desc, siac_r_movgest_bil_elem';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_articolo
IS 'siac_t_bil_elem.elem_desc2, siac_r_movgest_bil_elem';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_soggetto
IS 'siac_t_soggetto.soggetto_code, siac_r_movgest_ts_sog - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_soggetto
IS 'siac_t_soggetto.soggetto_desc, siac_r_movgest_ts_sog - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cf_soggetto
IS 'siac_t_soggetto.soggetto_cod_fiscale, siac_r_movgest_ts_sog - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cf_estero_soggetto
IS 'siac_t_soggetto.soggetto_cod_fiscale_estero, siac_r_movgest_ts_sog - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.p_iva_soggetto
IS 'siac_t_soggetto.soggetto_p_iva, siac_r_movgest_ts_sog - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_classe_soggetto
IS 'siac_d_soggetto_classe.soggetto_classe_code, siac_r_movgest_ts_sogclasse - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_classe_soggetto
IS 'siac_d_soggetto_classe.soggetto_classe_desc, siac_r_movgest_ts_sogclasse - soggetto collegato a movgest_ts_id con siac_d_movgest_ts_tipo.movgest_ts_tipo_code di tipo T testata';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_entrata_ricorrente
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_entrata_ricorrente
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_perimetro_sanita_entrata
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_perimetro_sanita_entrata
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_transazione_ue_entrata
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_transazione_ue_entrata
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_pdc_finanziario_i
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_pdc_finanziario_i
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_pdc_finanziario_ii
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_pdc_finanziario_ii
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_pdc_finanziario_iii
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_pdc_finanziario_iii
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_pdc_finanziario_iv
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_pdc_finanziario_iv
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_pdc_finanziario_v
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_pdc_finanziario_v
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_pdc_economico_i
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_pdc_economico_i
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_pdc_economico_ii
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_pdc_economico_ii
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_pdc_economico_iii
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_pdc_economico_iii
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_pdc_economico_iv
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_pdc_economico_iv
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_pdc_economico_v
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_pdc_economico_v
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_cofog_divisione
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_cofog_divisione
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_cofog_gruppo
IS 'classificatore (siac_t_class.classif_code,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_cofog_gruppo
IS 'classificatore (siac_t_class.classif_desc,siac_r_movgest_class) .';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_1
IS 'classificatore cod (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_1_valore
IS 'classificatore desc (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_1_desc_valore
IS 'classificatore valore (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_2
IS 'classificatore cod (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_2_valore
IS 'classificatore desc (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_2_desc_valore
IS 'classificatore valore (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_3
IS 'classificatore cod (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_3_valore
IS 'classificatore desc (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_3_desc_valore
IS 'classificatore valore (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_4
IS 'classificatore cod (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_4_valore
IS 'classificatore desc (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_4_desc_valore
IS 'classificatore valore (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_5
IS 'classificatore cod (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_5_valore
IS 'classificatore desc (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.classificatore_5_desc_valore
IS 'classificatore valore (siac_t_class.classif_code,siac_r_movgest_class)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.annocapitoloorigine
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.numcapitoloorigine
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.annoorigineplur
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.numarticoloorigine
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.annoriaccertato
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.numriaccertato
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.numorigineplur
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.flagdariaccertamento
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr - boolean valorizzare con T o F';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.anno_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_anno, siac_r_movgest_ts_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.num_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_num, siac_r_movgest_ts_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.oggetto_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_oggetto, siac_r_movgest_ts_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.note_atto_amministrativo
IS 'siac_t_atto_amm.attoamm_note, siac_r_movgest_ts_atto_amm';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_code';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_tipo_atto_amministrativo
IS 'siac_d_atto_amm_tipo.attoamm_tipo_desc';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_stato_atto_amministrativo
IS 'desc stato atto amministrativo siac_d_atto_amm_stato.attoamm_stato_desc, siac_r_atto_amm_stato';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_cdr_atto_amministrativo
IS 'classificatore code (siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_cdr_atto_amministrativo
IS 'classificatore desc (siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.cod_cdc_atto_amministrativo
IS 'classificatore code (siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.desc_cdc_atto_amministrativo
IS 'classificatore desc (siac_t_class.classif_code, siac_r_atto_amm_class, siac_r_class_fam_tree, siac_t_class_fam_tree, siac_d_class_fam)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.importo_iniziale
IS 'siac_t_movgest_ts_det con movgest_ts_id che ha siac_d_movgest_ts_tipo.movgest_ts_tipo_code=''S'' (sub)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.importo_attuale
IS 'siac_t_movgest_ts_det con movgest_ts_id che ha siac_d_movgest_ts_tipo.movgest_ts_tipo_code=''S'' (sub)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.importo_utilizzabile
IS 'siac_t_movgest_ts_det con movgest_ts_id che ha siac_d_movgest_ts_tipo.movgest_ts_tipo_code=''S'' (sub)';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.automatico
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.note
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.validato
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.num_ueb_origine
IS 'attributo - siac_r_movgest_ts_attr, siac_t_attr';

COMMENT ON COLUMN siac.siac_dwh_subaccertamento.flagcollegamentoaccertamentofattura
IS 'FlagCollegamentoAccertamentoFattura siac_t_attr.attr_code=''FlagCollegamentoAccertamentoFattura'' , siac_r_movgest_ts_attr (x Coge)';