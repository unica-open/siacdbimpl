/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5030 Sofia INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_accertamento (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

rec_movgest_ts_id record;
rec_classif_id record;
rec_classif_id_attr record;
rec_attr record;
rec_movgest_ts_id_dett record;
rec_movgest_ts_id_perimp record;
-- Variabili per campi estratti dal cursore rec_movgest_ts_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_anno VARCHAR := null;
v_fase_operativa_code VARCHAR := null;
v_fase_operativa_desc VARCHAR := null;
v_movgest_anno INTEGER := null;
v_movgest_numero NUMERIC := null;
v_movgest_desc VARCHAR := null;
v_movgest_ts_code VARCHAR := null;
v_movgest_ts_desc VARCHAR := null;
v_movgest_stato_code VARCHAR := null;
v_movgest_stato_desc VARCHAR := null;
v_data_scadenza TIMESTAMP := null;
v_parere_finanziario VARCHAR := null;
v_codice_capitolo VARCHAR := null;
v_codice_articolo VARCHAR := null;
v_codice_ueb VARCHAR := null;
v_descrizione_capitolo VARCHAR := null;
v_descrizione_articolo VARCHAR := null;
-- Variabili relative agli attributi associati a un movgest_ts_id
v_soggetto_id INTEGER := null;
v_codice_soggetto VARCHAR := null;
v_descrizione_soggetto VARCHAR := null;
v_codice_fiscale_soggetto VARCHAR := null;
v_codice_fiscale_estero_soggetto VARCHAR := null;
v_partita_iva_soggetto VARCHAR := null;
v_codice_classe_soggetto VARCHAR := null;
v_descrizione_classe_soggetto VARCHAR := null;
-- Variabili per classificatori in gerarchia
v_codice_pdc_finanziario_I VARCHAR := null;
v_descrizione_pdc_finanziario_I VARCHAR := null;
v_codice_pdc_finanziario_II VARCHAR := null;
v_descrizione_pdc_finanziario_II VARCHAR := null;
v_codice_pdc_finanziario_III VARCHAR := null;
v_descrizione_pdc_finanziario_III VARCHAR := null;
v_codice_pdc_finanziario_IV VARCHAR := null;
v_descrizione_pdc_finanziario_IV VARCHAR := null;
v_codice_pdc_finanziario_V VARCHAR := null;
v_descrizione_pdc_finanziario_V VARCHAR := null;
v_codice_pdc_economico_I VARCHAR := null;
v_descrizione_pdc_economico_I VARCHAR := null;
v_codice_pdc_economico_II VARCHAR := null;
v_descrizione_pdc_economico_II VARCHAR := null;
v_codice_pdc_economico_III VARCHAR := null;
v_descrizione_pdc_economico_III VARCHAR := null;
v_codice_pdc_economico_IV VARCHAR := null;
v_descrizione_pdc_economico_IV VARCHAR := null;
v_codice_pdc_economico_V VARCHAR := null;
v_descrizione_pdc_economico_V VARCHAR := null;
v_codice_cofog_divisione VARCHAR := null;
v_descrizione_cofog_divisione VARCHAR := null;
v_codice_cofog_gruppo VARCHAR := null;
v_descrizione_cofog_gruppo VARCHAR := null;
-- Variabili per classificatori non in gerarchia
v_codice_entrata_ricorrente VARCHAR := null;
v_descrizione_entrata_ricorrente VARCHAR := null;
v_codice_transazione_entrata_ue VARCHAR := null;
v_descrizione_transazione_entrata_ue VARCHAR := null;
v_codice_perimetro_sanitario_entrata VARCHAR := null;
v_descrizione_perimetro_sanitario_entrata VARCHAR := null;
v_classificatore_generico_1 VARCHAR := null;
v_classificatore_generico_1_descrizione_valore VARCHAR := null;
v_classificatore_generico_1_valore VARCHAR := null;
v_classificatore_generico_2 VARCHAR := null;
v_classificatore_generico_2_descrizione_valore VARCHAR := null;
v_classificatore_generico_2_valore VARCHAR := null;
v_classificatore_generico_3 VARCHAR := null;
v_classificatore_generico_3_descrizione_valore VARCHAR := null;
v_classificatore_generico_3_valore VARCHAR := null;
v_classificatore_generico_4 VARCHAR := null;
v_classificatore_generico_4_descrizione_valore VARCHAR := null;
v_classificatore_generico_4_valore VARCHAR := null;
v_classificatore_generico_5 VARCHAR := null;
v_classificatore_generico_5_descrizione_valore VARCHAR := null;
v_classificatore_generico_5_valore VARCHAR := null;
-- Variabili attributo
v_annoCapitoloOrigine VARCHAR := null;
v_numeroCapitoloOrigine VARCHAR := null;
v_annoOriginePlur VARCHAR := null;
v_numeroArticoloOrigine VARCHAR := null;
v_annoRiaccertato VARCHAR := null;
v_numeroRiaccertato VARCHAR := null;
v_numeroOriginePlur VARCHAR := null;
v_flagDaRiaccertamento VARCHAR := null;
v_automatico VARCHAR := null;
v_note VARCHAR := null;
v_validato VARCHAR := null;
v_numero_ueb_origine VARCHAR := null;
v_anno_atto_amministrativo VARCHAR := null;
v_numero_atto_amministrativo INTEGER := null;
v_oggetto_atto_amministrativo VARCHAR := null;
v_note_atto_amministrativo VARCHAR := null;
v_codice_tipo_atto_amministrativo VARCHAR := null;
v_descrizione_tipo_atto_amministrativo VARCHAR := null;
v_descrizione_stato_atto_amministrativo VARCHAR := null;
v_cod_cdr_atto_amministrativo VARCHAR := null;
v_desc_cdr_atto_amministrativo VARCHAR := null;
v_cod_cdc_atto_amministrativo VARCHAR := null;
v_desc_cdc_atto_amministrativo VARCHAR := null;
-- Variabili di dettaglio
v_importo_iniziale NUMERIC := null;
v_importo_attuale NUMERIC := null;
v_importo_utilizzabile NUMERIC := null;
v_importo_emesso NUMERIC := null;
v_importo_quietanziato NUMERIC := null;
v_importo_emesso_tot NUMERIC := null;
v_importo_quietanziato_tot NUMERIC := null;

v_classif_code VARCHAR := null;
v_classif_desc VARCHAR := null;
v_classif_tipo_code VARCHAR := null;
v_classif_tipo_desc VARCHAR := null;
v_flag_attributo VARCHAR := null;
v_movgest_ts_tipo_code VARCHAR := null;

v_movgest_id INTEGER := null;
v_movgest_ts_id INTEGER := null;
v_classif_id INTEGER := null;
v_classif_id_part INTEGER := null;
v_classif_id_padre INTEGER := null;
v_classif_tipo_id INTEGER := null;
v_classif_fam_id INTEGER := null;
v_conta_ciclo_classif INTEGER := null;
v_bil_id INTEGER := null;
v_attoamm_id INTEGER := null;

v_fnc_result VARCHAR := null;

--nuova sezione coge 26-09-2016
v_FlagCollegamentoAccertamentoFattura VARCHAR := null;

v_data_inizio_val_stato_subaccer TIMESTAMP := null;
v_data_inizio_val_stato_accer TIMESTAMP := null;
v_data_creazione_subaccer TIMESTAMP := null;
v_data_inizio_val_subaccer TIMESTAMP := null;
v_data_modifica_subaccer TIMESTAMP := null;
v_data_creazione_accer TIMESTAMP := null;
v_data_inizio_val_accer TIMESTAMP := null;
v_data_modifica_accer TIMESTAMP := null;

v_programma_code VARCHAR := null;
v_programma_desc VARCHAR := null;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_bko_popola_siac_r_class_fam_class_tipo(p_ente_proprietario_id)
into v_fnc_result;

esito:= 'Inizio funzione carico accertamenti (FNC_SIAC_DWH_ACCERTAMENTO) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_accertamento
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
DELETE FROM siac.siac_dwh_subaccertamento
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre movgest_ts_id
FOR rec_movgest_ts_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tm.movgest_anno, tm.movgest_numero, tm.movgest_desc, tmt.movgest_ts_code, tmt.movgest_ts_desc, dms.movgest_stato_code, dms.movgest_stato_desc,
       tmt.movgest_ts_scadenza_data, tm.parere_finanziario, tm.movgest_id, tmt.movgest_ts_id, dmtt.movgest_ts_tipo_code,
       tbe.elem_code, tbe.elem_code2, tbe.elem_code3, tbe.elem_desc, tbe.elem_desc2, tb.bil_id,
       rmts.validita_inizio as data_inizio_val_stato_subaccer,
       tmt.data_creazione as data_creazione_subaccer,
       tmt.validita_inizio as  data_inizio_val_subaccer,
       tmt.data_modifica as data_modifica_subaccer,
       tm.data_creazione as data_creazione_accer,
       tm.validita_inizio as data_inizio_val_accer,
       tm.data_modifica as data_modifica_accer
FROM   siac.siac_t_movgest_ts tmt
INNER JOIN  siac.siac_t_movgest tm ON  tm.movgest_id = tmt.movgest_id
INNER JOIN  siac.siac_t_bil tb ON tm.bil_id = tb.bil_id
INNER JOIN  siac.siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN  siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = tm.ente_proprietario_id
INNER JOIN  siac.siac_d_movgest_tipo dmt ON tm.movgest_tipo_id = dmt.movgest_tipo_id
INNER JOIN  siac.siac_d_movgest_ts_tipo dmtt ON tmt.movgest_ts_tipo_id = dmtt.movgest_ts_tipo_id
INNER JOIN  siac.siac_r_movgest_ts_stato rmts ON rmts.movgest_ts_id = tmt.movgest_ts_id
INNER JOIN  siac.siac_d_movgest_stato dms ON rmts.movgest_stato_id = dms.movgest_stato_id
LEFT JOIN   siac.siac_r_movgest_bil_elem rmbe ON rmbe.movgest_id = tm.movgest_id
                                              AND p_data BETWEEN rmbe.validita_inizio AND COALESCE(rmbe.validita_fine, p_data)
                                              AND rmbe.data_cancellazione IS NULL
LEFT JOIN  siac.siac_t_bil_elem tbe ON rmbe.elem_id = tbe.elem_id
                                    AND p_data BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, p_data)
                                    AND tbe.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
AND dmt.movgest_tipo_code = 'A'
AND p_data BETWEEN tmt.validita_inizio AND COALESCE(tmt.validita_fine, p_data)
AND tmt.data_cancellazione IS NULL
AND p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
AND tm.data_cancellazione IS NULL
AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
AND tb.data_cancellazione IS NULL
AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND tp.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN dmt.validita_inizio AND COALESCE(dmt.validita_fine, p_data)
AND dmt.data_cancellazione IS NULL
AND p_data BETWEEN dmtt.validita_inizio AND COALESCE(dmtt.validita_fine, p_data)
AND dmtt.data_cancellazione IS NULL
AND p_data BETWEEN rmts.validita_inizio AND COALESCE(rmts.validita_fine, p_data)
AND rmts.data_cancellazione IS NULL
AND p_data BETWEEN dms.validita_inizio AND COALESCE(dms.validita_fine, p_data)
AND dms.data_cancellazione IS NULL

LOOP

v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_anno := null;
v_fase_operativa_code := null;
v_fase_operativa_desc := null;
v_movgest_anno := null;
v_movgest_numero := null;
v_movgest_desc := null;
v_movgest_ts_code := null;
v_movgest_ts_desc := null;
v_movgest_stato_code := null;
v_movgest_stato_desc := null;
v_data_scadenza := null;
v_parere_finanziario := null;
v_codice_capitolo := null;
v_codice_articolo := null;
v_codice_ueb := null;
v_descrizione_capitolo := null;
v_descrizione_articolo := null;
v_soggetto_id := null;
v_codice_soggetto := null;
v_descrizione_soggetto := null;
v_codice_fiscale_soggetto := null;
v_codice_fiscale_estero_soggetto := null;
v_partita_iva_soggetto := null;
v_codice_classe_soggetto := null;
v_descrizione_classe_soggetto := null;
v_codice_entrata_ricorrente := null;
v_descrizione_entrata_ricorrente := null;
v_codice_transazione_entrata_ue := null;
v_descrizione_transazione_entrata_ue := null;
v_codice_perimetro_sanitario_entrata := null;
v_descrizione_perimetro_sanitario_entrata := null;
v_codice_pdc_finanziario_I := null;
v_descrizione_pdc_finanziario_I := null;
v_codice_pdc_finanziario_II := null;
v_descrizione_pdc_finanziario_II := null;
v_codice_pdc_finanziario_III  := null;
v_descrizione_pdc_finanziario_III := null;
v_codice_pdc_finanziario_IV := null;
v_descrizione_pdc_finanziario_IV := null;
v_codice_pdc_finanziario_V := null;
v_descrizione_pdc_finanziario_V := null;
v_codice_pdc_economico_I := null;
v_descrizione_pdc_economico_I := null;
v_codice_pdc_economico_II := null;
v_descrizione_pdc_economico_II := null;
v_codice_pdc_economico_III := null;
v_descrizione_pdc_economico_III := null;
v_codice_pdc_economico_IV:= null;
v_descrizione_pdc_economico_IV := null;
v_codice_pdc_economico_V := null;
v_descrizione_pdc_economico_V := null;
v_codice_cofog_divisione:= null;
v_descrizione_cofog_divisione := null;
v_codice_cofog_gruppo := null;
v_descrizione_cofog_gruppo := null;
v_importo_iniziale := null;
v_importo_attuale := null;
v_importo_utilizzabile := null;
v_importo_emesso := null;
v_importo_quietanziato := null;

v_movgest_id := null;
v_movgest_ts_id := null;
v_movgest_ts_tipo_code := null;
v_classif_id := null;
v_classif_tipo_id := null;
v_bil_id := null;

v_data_inizio_val_stato_subaccer := null;
v_data_inizio_val_stato_accer := null;
v_data_creazione_subaccer := null;
v_data_inizio_val_subaccer := null;
v_data_modifica_subaccer := null;
v_data_creazione_accer := null;
v_data_inizio_val_accer := null;
v_data_modifica_accer := null;

v_ente_proprietario_id := rec_movgest_ts_id.ente_proprietario_id;
v_ente_denominazione := rec_movgest_ts_id.ente_denominazione;
v_anno := rec_movgest_ts_id.anno;
v_movgest_anno := rec_movgest_ts_id.movgest_anno;
v_movgest_numero := rec_movgest_ts_id.movgest_numero;
v_movgest_desc := rec_movgest_ts_id.movgest_desc;
v_movgest_ts_code := rec_movgest_ts_id.movgest_ts_code;
v_movgest_ts_desc := rec_movgest_ts_id.movgest_ts_desc;
v_movgest_stato_code := rec_movgest_ts_id.movgest_stato_code;
v_movgest_stato_desc := rec_movgest_ts_id.movgest_stato_desc;
IF rec_movgest_ts_id.parere_finanziario = 'FALSE' THEN
   v_parere_finanziario := 'F';
ELSE
   v_parere_finanziario := 'T';
END IF;
v_data_scadenza := rec_movgest_ts_id.movgest_ts_scadenza_data;
v_codice_capitolo := rec_movgest_ts_id.elem_code;
v_codice_articolo := rec_movgest_ts_id.elem_code2;
v_codice_ueb := rec_movgest_ts_id.elem_code3;
v_descrizione_capitolo := rec_movgest_ts_id.elem_desc;
v_descrizione_articolo := rec_movgest_ts_id.elem_desc2;

v_movgest_id := rec_movgest_ts_id.movgest_id;
v_movgest_ts_id := rec_movgest_ts_id.movgest_ts_id;
v_movgest_ts_tipo_code := rec_movgest_ts_id.movgest_ts_tipo_code;
v_bil_id := rec_movgest_ts_id.bil_id;

v_data_inizio_val_stato_subaccer := rec_movgest_ts_id.data_inizio_val_stato_subaccer;
v_data_inizio_val_stato_accer := rec_movgest_ts_id.data_inizio_val_stato_subaccer;
v_data_creazione_subaccer := rec_movgest_ts_id.data_creazione_subaccer;
v_data_inizio_val_subaccer := rec_movgest_ts_id.data_inizio_val_subaccer;
v_data_modifica_subaccer := rec_movgest_ts_id.data_modifica_subaccer;
v_data_creazione_accer := rec_movgest_ts_id.data_creazione_accer;
v_data_inizio_val_accer := rec_movgest_ts_id.data_inizio_val_accer;
v_data_modifica_accer := rec_movgest_ts_id.data_modifica_accer;

esito:= '  Inizio ciclo movgest - movgest_ts_id ('||v_movgest_id||') - ('||v_movgest_ts_id||') - ('||v_movgest_ts_tipo_code||') - '||clock_timestamp();
return next;
-- Sezione per estrarre la fase operativa
SELECT dfo.fase_operativa_code, dfo.fase_operativa_desc
INTO v_fase_operativa_code, v_fase_operativa_desc
FROM siac.siac_r_bil_fase_operativa rbfo, siac.siac_d_fase_operativa dfo
WHERE dfo.fase_operativa_id = rbfo.fase_operativa_id
AND   rbfo.bil_id = v_bil_id
AND   p_data BETWEEN rbfo.validita_inizio AND COALESCE(rbfo.validita_fine, p_data)
AND   p_data BETWEEN dfo.validita_inizio AND COALESCE(dfo.validita_fine, p_data)
AND   rbfo.data_cancellazione IS NULL
AND   dfo.data_cancellazione IS NULL;
-- Sezione per estrarre i dati del soggetto associati ad un movgest_ts_id
SELECT ts.soggetto_code, ts.soggetto_desc, ts.codice_fiscale, ts.codice_fiscale_estero, ts.partita_iva, ts.soggetto_id
INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto, v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto, v_soggetto_id
FROM siac.siac_r_movgest_ts_sog rmts, siac.siac_t_soggetto ts
WHERE rmts.soggetto_id = ts.soggetto_id
AND   rmts.movgest_ts_id = v_movgest_ts_id
AND   p_data BETWEEN rmts.validita_inizio AND COALESCE(rmts.validita_fine, p_data)
AND   p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
AND   rmts.data_cancellazione IS NULL
AND   ts.data_cancellazione IS NULL;
-- Sezione per estrarre i dati di classe del soggetto associati ad un movgest_ts_id
SELECT dsc.soggetto_classe_code, dsc.soggetto_classe_desc
INTO v_codice_classe_soggetto, v_descrizione_classe_soggetto
FROM siac.siac_r_movgest_ts_sogclasse rmts, siac.siac_d_soggetto_classe dsc
WHERE rmts.soggetto_classe_id = dsc.soggetto_classe_id
AND   rmts.movgest_ts_id = v_movgest_ts_id
AND   p_data BETWEEN rmts.validita_inizio AND COALESCE(rmts.validita_fine, p_data)
AND   p_data BETWEEN dsc.validita_inizio AND COALESCE(dsc.validita_fine, p_data)
AND   rmts.data_cancellazione IS NULL
AND   dsc.data_cancellazione IS NULL;

v_classificatore_generico_1:= null;
v_classificatore_generico_1_descrizione_valore:= null;
v_classificatore_generico_1_valore:= null;
v_classificatore_generico_2:= null;
v_classificatore_generico_2_descrizione_valore:= null;
v_classificatore_generico_2_valore:= null;
v_classificatore_generico_3:= null;
v_classificatore_generico_3_descrizione_valore:= null;
v_classificatore_generico_3_valore:= null;
v_classificatore_generico_4:= null;
v_classificatore_generico_4_descrizione_valore:= null;
v_classificatore_generico_4_valore:= null;
v_classificatore_generico_5:= null;
v_classificatore_generico_5_descrizione_valore:= null;
v_classificatore_generico_5_valore:= null;
-- Ciclo per estrarre i classificatori relativi ad un dato movimento
FOR rec_classif_id IN
SELECT tc.classif_id, tc.classif_tipo_id,
       tc.classif_code, tc.classif_desc, dct.classif_tipo_code,dct.classif_tipo_desc
FROM  siac.siac_r_movgest_class rmc, siac.siac_t_class tc, siac.siac_d_class_tipo dct
WHERE tc.classif_id = rmc.classif_id
AND   dct.classif_tipo_id = tc.classif_tipo_id
AND   rmc.movgest_ts_id = v_movgest_ts_id
AND   rmc.data_cancellazione IS NULL
AND   tc.data_cancellazione IS NULL
AND   dct.data_cancellazione IS NULL
AND   p_data BETWEEN rmc.validita_inizio AND COALESCE(rmc.validita_fine, p_data)
AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data)

LOOP

v_classif_id :=  rec_classif_id.classif_id;
v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
v_classif_fam_id := null;

-- Estrazione per determinare se un classificatore e' in gerarchia
SELECT rcfct.classif_fam_id
INTO v_classif_fam_id
FROM siac.siac_r_class_fam_class_tipo rcfct
WHERE rcfct.classif_tipo_id = v_classif_tipo_id
AND   rcfct.data_cancellazione IS NULL
AND   p_data BETWEEN rcfct.validita_inizio AND COALESCE(rcfct.validita_fine, p_data);

-- Se il classificatore non e' in gerarchia
IF NOT FOUND THEN
  esito:= '    Inizio step classificatori non in gerarchia - '||clock_timestamp();
  return next;
  v_classif_tipo_code := null;
  v_classif_tipo_desc :=null;
  v_classif_code := rec_classif_id.classif_code;
  v_classif_desc := rec_classif_id.classif_desc;

  SELECT dct.classif_tipo_code,dct.classif_tipo_desc
  INTO   v_classif_tipo_code,v_classif_tipo_desc
  FROM   siac.siac_d_class_tipo dct
  WHERE  dct.classif_tipo_id = v_classif_tipo_id
  AND    dct.data_cancellazione IS NULL
  AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'RICORRENTE_ENTRATA' THEN
     v_codice_entrata_ricorrente      := v_classif_code;
     v_descrizione_entrata_ricorrente := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TRANSAZIONE_UE_ENTRATA' THEN
     v_codice_transazione_entrata_ue      := v_classif_code;
     v_descrizione_transazione_entrata_ue := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PERIMETRO_SANITARIO_ENTRATA' THEN
     v_codice_perimetro_sanitario_entrata      := v_classif_code;
     v_descrizione_perimetro_sanitario_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_16' THEN
     v_classificatore_generico_1      := v_classif_tipo_desc;
     v_classificatore_generico_1_descrizione_valore := v_classif_desc;
     v_classificatore_generico_1_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_17' THEN
     v_classificatore_generico_2     := v_classif_tipo_desc;
     v_classificatore_generico_2_descrizione_valore := v_classif_desc;
     v_classificatore_generico_2_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_18' THEN
     v_classificatore_generico_3      := v_classif_tipo_desc;
     v_classificatore_generico_3_descrizione_valore := v_classif_desc;
     v_classificatore_generico_3_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_19' THEN
     v_classificatore_generico_4     := v_classif_tipo_desc;
     v_classificatore_generico_4_descrizione_valore := v_classif_desc;
     v_classificatore_generico_4_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_20' THEN
     v_classificatore_generico_5     := v_classif_tipo_desc;
     v_classificatore_generico_5_descrizione_valore := v_classif_desc;
     v_classificatore_generico_5_valore      := v_classif_code;
  END IF;
  esito:= '    Fine step classificatori non in gerarchia - '||clock_timestamp();
  return next;
-- Se il classificatore e' in gerarchia
ELSE
 esito:= '    Inizio step classificatori in gerarchia - '||clock_timestamp();
 return next;
 v_conta_ciclo_classif :=0;
 v_classif_id_padre := null;

 -- Loop per RISALIRE la gerarchia di un dato classificatore
 LOOP

  v_classif_code := null;
  v_classif_desc := null;
  v_classif_id_part := null;
  v_classif_tipo_code := null;
  v_classif_tipo_desc := null;

  IF v_conta_ciclo_classif = 0 THEN
     v_classif_id_part := v_classif_id;
  ELSE
     v_classif_id_part := v_classif_id_padre;
  END IF;

  SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code,dct.classif_tipo_desc
  INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code,v_classif_tipo_desc
  FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
  WHERE rcft.classif_id = tc.classif_id
  AND   dct.classif_tipo_id = tc.classif_tipo_id
  AND   tc.classif_id = v_classif_id_part
  AND   rcft.data_cancellazione IS NULL
  AND   tc.data_cancellazione IS NULL
  AND   dct.data_cancellazione IS NULL
  AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
  AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
  AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'PDC_I' THEN
        v_codice_pdc_finanziario_I := v_classif_code;
        v_descrizione_pdc_finanziario_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_II' THEN
        v_codice_pdc_finanziario_II := v_classif_code;
        v_descrizione_pdc_finanziario_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_III' THEN
        v_codice_pdc_finanziario_III := v_classif_code;
        v_descrizione_pdc_finanziario_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_IV' THEN
        v_codice_pdc_finanziario_IV := v_classif_code;
        v_descrizione_pdc_finanziario_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_V' THEN
        v_codice_pdc_finanziario_V := v_classif_code;
        v_descrizione_pdc_finanziario_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_I' THEN
        v_codice_pdc_economico_I := v_classif_code;
        v_descrizione_pdc_economico_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_II' THEN
        v_codice_pdc_economico_II := v_classif_code;
        v_descrizione_pdc_economico_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_III' THEN
        v_codice_pdc_economico_III := v_classif_code;
        v_descrizione_pdc_economico_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_IV' THEN
        v_codice_pdc_economico_IV := v_classif_code;
        v_descrizione_pdc_economico_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_V' THEN
        v_codice_pdc_economico_V := v_classif_code;
        v_descrizione_pdc_economico_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'DIVISIONE_COFOG' THEN
        v_codice_cofog_divisione := v_classif_code;
        v_descrizione_cofog_divisione := v_classif_desc;
  ELSIF v_classif_tipo_code = 'GRUPPO_COFOG' THEN
        v_codice_cofog_gruppo := v_classif_code;
        v_descrizione_cofog_gruppo := v_classif_desc;
  END IF;

  v_conta_ciclo_classif := v_conta_ciclo_classif +1;
  EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
 esito:= '    Fine step classificatori in gerarchia - '||clock_timestamp();
 return next;
END IF;
END LOOP;

-- Sezione pe gli attributi
v_annoCapitoloOrigine := null;
v_numeroCapitoloOrigine := null;
v_annoOriginePlur := null;
v_numeroArticoloOrigine := null;
v_annoRiaccertato := null;
v_numeroRiaccertato := null;
v_numeroOriginePlur := null;
v_flagDaRiaccertamento := null;
v_automatico := null;
v_note := null;
v_validato := null;
v_numero_ueb_origine := null;
v_anno_atto_amministrativo := null;
v_numero_atto_amministrativo := null;
v_oggetto_atto_amministrativo := null;
v_note_atto_amministrativo := null;
v_codice_tipo_atto_amministrativo := null;
v_descrizione_tipo_atto_amministrativo := null;
v_descrizione_stato_atto_amministrativo := null;
v_cod_cdr_atto_amministrativo := null;
v_desc_cdr_atto_amministrativo := null;
v_cod_cdc_atto_amministrativo := null;
v_desc_cdc_atto_amministrativo := null;
v_attoamm_id := null;

v_flag_attributo := null;

--nuova sezione coge 26-09-2016
v_FlagCollegamentoAccertamentoFattura  := null;

-- Ciclo per estrarre gli attibuti relativi ad un movgest_ts_id
FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rmta.tabella_id, rmta.percentuale, rmta."boolean" true_false, rmta.numerico, rmta.testo
FROM   siac.siac_r_movgest_ts_attr rmta, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rmta.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rmta.movgest_ts_id = v_movgest_ts_id
AND    rmta.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rmta.validita_inizio AND COALESCE(rmta.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'annoCapitoloOrigine' THEN
     v_annoCapitoloOrigine := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'numeroCapitoloOrigine' THEN
     v_numeroCapitoloOrigine := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'annoOriginePlur' THEN
     v_annoOriginePlur := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'numeroArticoloOrigine' THEN
     v_numeroArticoloOrigine := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'annoRiaccertato' THEN
     v_annoRiaccertato := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'numeroRiaccertato' THEN
     v_numeroRiaccertato := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'numeroOriginePlur' THEN
     v_numeroOriginePlur := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'flagDaRiaccertamento' THEN
     v_flagDaRiaccertamento := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'numeroUEBOrigine' THEN
     v_numero_ueb_origine := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'ACC_AUTO' THEN
     v_automatico := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'NOTE_MOVGEST' THEN
     v_note := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'validato' THEN
     v_validato := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagCollegamentoAccertamentoFattura' THEN
     v_FlagCollegamentoAccertamentoFattura := v_flag_attributo;
     --nuova sezione coge 26-09-2016
   END IF;

END LOOP;
-- Sezione pe i dati amministrativi
SELECT taa.attoamm_anno, taa.attoamm_numero, taa.attoamm_oggetto, taa.attoamm_note,
       daat.attoamm_tipo_code, daat.attoamm_tipo_desc, daas.attoamm_stato_desc, taa.attoamm_id
INTO   v_anno_atto_amministrativo, v_numero_atto_amministrativo, v_oggetto_atto_amministrativo,
       v_note_atto_amministrativo, v_codice_tipo_atto_amministrativo,
       v_descrizione_tipo_atto_amministrativo, v_descrizione_stato_atto_amministrativo, v_attoamm_id
FROM siac.siac_r_movgest_ts_atto_amm rmtaa, siac.siac_t_atto_amm taa, siac.siac_r_atto_amm_stato raas, siac.siac_d_atto_amm_stato daas,
     siac.siac_d_atto_amm_tipo daat
WHERE taa.attoamm_id = rmtaa.attoamm_id
AND   taa.attoamm_id = raas.attoamm_id
AND   raas.attoamm_stato_id = daas.attoamm_stato_id
AND   taa.attoamm_tipo_id = daat.attoamm_tipo_id
AND   rmtaa.movgest_ts_id = v_movgest_ts_id
AND   rmtaa.data_cancellazione IS NULL
AND   taa.data_cancellazione IS NULL
AND   raas.data_cancellazione IS NULL
AND   daas.data_cancellazione IS NULL
AND   daat.data_cancellazione IS NULL
AND   p_data BETWEEN rmtaa.validita_inizio AND COALESCE(rmtaa.validita_fine, p_data)
AND   p_data BETWEEN taa.validita_inizio AND COALESCE(taa.validita_fine, p_data)
AND   p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
AND   p_data BETWEEN daas.validita_inizio AND COALESCE(daas.validita_fine, p_data)
AND   p_data BETWEEN daat.validita_inizio AND COALESCE(daat.validita_fine, p_data);

-- Sezione per i classificatori legati agli atti amministrativi
esito:= '    Inizio step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
return next;
FOR rec_classif_id_attr IN
SELECT raac.classif_id
FROM  siac.siac_r_atto_amm_class raac
WHERE raac.attoamm_id = v_attoamm_id
AND   raac.data_cancellazione IS NULL
AND   p_data BETWEEN raac.validita_inizio AND COALESCE(raac.validita_fine, p_data)

LOOP

  v_conta_ciclo_classif :=0;
  v_classif_id_padre := null;

  -- Loop per RISALIRE la gerarchia di un dato classificatore
  LOOP

      v_classif_code := null;
      v_classif_desc := null;
      v_classif_id_part := null;
      v_classif_tipo_code := null;
      v_classif_tipo_desc := null;

      IF v_conta_ciclo_classif = 0 THEN
         v_classif_id_part := rec_classif_id_attr.classif_id;
      ELSE
         v_classif_id_part := v_classif_id_padre;
      END IF;

      SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code,dct.classif_tipo_desc
      INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code,v_classif_tipo_desc
      FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
      WHERE rcft.classif_id = tc.classif_id
      AND   dct.classif_tipo_id = tc.classif_tipo_id
      AND   tc.classif_id = v_classif_id_part
      AND   rcft.data_cancellazione IS NULL
      AND   tc.data_cancellazione IS NULL
      AND   dct.data_cancellazione IS NULL
      AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
      AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
      AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

      IF v_classif_tipo_code = 'CDR' THEN
         v_cod_cdr_atto_amministrativo := v_classif_code;
         v_desc_cdr_atto_amministrativo := v_classif_desc;
      ELSIF v_classif_tipo_code = 'CDC' THEN
         v_cod_cdc_atto_amministrativo := v_classif_code;
         v_desc_cdc_atto_amministrativo := v_classif_desc;
      END IF;

      v_conta_ciclo_classif := v_conta_ciclo_classif +1;
      EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
END LOOP;
esito:= '    Fine step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
return next;

-- Sezione per i dati di dettaglio associati ad un movgest_ts_id
FOR rec_movgest_ts_id_dett IN
SELECT COALESCE(SUM(tmtd.movgest_ts_det_importo),0) importo, dmtdt.movgest_ts_det_tipo_code
FROM siac.siac_t_movgest_ts_det tmtd, siac.siac_d_movgest_ts_det_tipo dmtdt
WHERE tmtd.movgest_ts_det_tipo_id = dmtdt.movgest_ts_det_tipo_id
AND   tmtd.movgest_ts_id = v_movgest_ts_id
AND   tmtd.data_cancellazione IS NULL
AND   dmtdt.data_cancellazione IS NULL
AND   p_data BETWEEN tmtd.validita_inizio AND COALESCE(tmtd.validita_fine, p_data)
AND   p_data BETWEEN dmtdt.validita_inizio AND COALESCE(dmtdt.validita_fine, p_data)
GROUP BY dmtdt.movgest_ts_det_tipo_code

LOOP

	IF rec_movgest_ts_id_dett.movgest_ts_det_tipo_code = 'I' THEN
       v_importo_iniziale := rec_movgest_ts_id_dett.importo;
    ELSIF rec_movgest_ts_id_dett.movgest_ts_det_tipo_code = 'A' THEN
       v_importo_attuale := rec_movgest_ts_id_dett.importo;
    ELSIF rec_movgest_ts_id_dett.movgest_ts_det_tipo_code = 'U' THEN
       v_importo_utilizzabile := rec_movgest_ts_id_dett.importo;
    END IF;

END LOOP;

/* 30.06.2016 Sofia SIAC JIRA-5030
v_importo_emesso_tot := 0;
v_importo_quietanziato_tot := 0;

FOR rec_movgest_ts_id_perimp IN
SELECT movgest_ts_id
FROM   siac_t_movgest_ts
WHERE  movgest_id = v_movgest_id
AND    v_movgest_ts_tipo_code = 'T'
AND    ente_proprietario_id = p_ente_proprietario_id
AND    data_cancellazione IS NULL
AND    p_data BETWEEN validita_inizio AND COALESCE(validita_fine, p_data)
UNION
SELECT v_movgest_ts_id
WHERE  v_movgest_ts_tipo_code = 'S'

LOOP
    v_importo_emesso := 0;

    -- Sezione per il calcolo dell'importo emesso
    SELECT COALESCE(SUM(totd.ord_ts_det_importo),0) importo_emesso
    INTO v_importo_emesso
    FROM siac.siac_r_ordinativo_ts_movgest_ts rotmt, siac.siac_t_ordinativo_ts tot,
         siac.siac_r_ordinativo_stato ros, siac.siac_d_ordinativo_stato dos,
         siac.siac_t_ordinativo_ts_det totd, siac.siac_d_ordinativo_ts_det_tipo dotdt
    WHERE rotmt.movgest_ts_id = rec_movgest_ts_id_perimp.movgest_ts_id
    AND  rotmt.ord_ts_id = tot.ord_ts_id
    AND  ros.ord_id = tot.ord_id
    AND  ros.ord_stato_id = dos.ord_stato_id
    AND  totd.ord_ts_id = tot.ord_ts_id
    AND  dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
    AND  dos.ord_stato_code <> 'A'
    AND  dotdt.ord_ts_det_tipo_code = 'A'
    AND  p_data BETWEEN  rotmt.validita_inizio  AND COALESCE(rotmt.validita_fine, p_data)
    AND  p_data BETWEEN  tot.validita_inizio  AND COALESCE(tot.validita_fine, p_data)
    AND  p_data BETWEEN  ros.validita_inizio  AND COALESCE(ros.validita_fine, p_data)
    AND  p_data BETWEEN  dos.validita_inizio  AND COALESCE(dos.validita_fine, p_data)
    AND  p_data BETWEEN  totd.validita_inizio  AND COALESCE(totd.validita_fine, p_data)
    AND  p_data BETWEEN  dotdt.validita_inizio  AND COALESCE(dotdt.validita_fine, p_data)
    AND  rotmt.data_cancellazione IS NULL
    AND  tot.data_cancellazione IS NULL
    AND  ros.data_cancellazione IS NULL
    AND  dos.data_cancellazione IS NULL
    AND  totd.data_cancellazione IS NULL
    AND  dotdt.data_cancellazione IS NULL;
    -- Sezione per il calcolo dell'importo quietanziato
    v_importo_quietanziato := 0;
    SELECT COALESCE(SUM(totd.ord_ts_det_importo),0) importo_quietanziato
    INTO v_importo_quietanziato
    FROM siac.siac_r_ordinativo_ts_movgest_ts rotmt, siac.siac_t_ordinativo_ts tot,
         siac.siac_r_ordinativo_stato ros, siac.siac_d_ordinativo_stato dos,
         siac.siac_t_ordinativo_ts_det totd, siac.siac_d_ordinativo_ts_det_tipo dotdt
    WHERE rotmt.movgest_ts_id = rec_movgest_ts_id_perimp.movgest_ts_id
    AND  rotmt.ord_ts_id = tot.ord_ts_id
    AND  ros.ord_id = tot.ord_id
    AND  ros.ord_stato_id = dos.ord_stato_id
    AND  totd.ord_ts_id = tot.ord_ts_id
    AND  dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
    AND  dos.ord_stato_code = 'Q'
    AND  dotdt.ord_ts_det_tipo_code = 'A'
    AND  p_data BETWEEN  rotmt.validita_inizio  AND COALESCE(rotmt.validita_fine, p_data)
    AND  p_data BETWEEN  tot.validita_inizio  AND COALESCE(tot.validita_fine, p_data)
    AND  p_data BETWEEN  ros.validita_inizio  AND COALESCE(ros.validita_fine, p_data)
    AND  p_data BETWEEN  dos.validita_inizio  AND COALESCE(dos.validita_fine, p_data)
    AND  p_data BETWEEN  totd.validita_inizio  AND COALESCE(totd.validita_fine, p_data)
    AND  p_data BETWEEN  dotdt.validita_inizio  AND COALESCE(dotdt.validita_fine, p_data)
    AND  rotmt.data_cancellazione IS NULL
    AND  tot.data_cancellazione IS NULL
    AND  ros.data_cancellazione IS NULL
    AND  dos.data_cancellazione IS NULL
    AND  totd.data_cancellazione IS NULL
    AND  dotdt.data_cancellazione IS NULL;

    v_importo_quietanziato_tot := v_importo_quietanziato_tot + v_importo_quietanziato;
    v_importo_emesso_tot := v_importo_emesso_tot + v_importo_emesso;

END LOOP;
*/

-- 30.06.2016 Sofia SIAC JIRA-5030   INIZIO
-- Sezione per il calcolo dell'importo emesso
v_importo_emesso_tot := 0;
SELECT COALESCE(SUM(totd.ord_ts_det_importo),0)
INTO v_importo_emesso_tot
FROM siac.siac_r_ordinativo_ts_movgest_ts rotmt, siac.siac_t_ordinativo_ts tot,
     siac.siac_r_ordinativo_stato ros, siac.siac_d_ordinativo_stato dos,
     siac.siac_t_ordinativo_ts_det totd, siac.siac_d_ordinativo_ts_det_tipo dotdt
WHERE rotmt.movgest_ts_id = v_movgest_ts_id
 AND  rotmt.ord_ts_id = tot.ord_ts_id
 AND  ros.ord_id = tot.ord_id
 AND  ros.ord_stato_id = dos.ord_stato_id
 AND  totd.ord_ts_id = tot.ord_ts_id
 AND  dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
 AND  dos.ord_stato_code <> 'A'
 AND  dotdt.ord_ts_det_tipo_code = 'A'
 AND  p_data BETWEEN  rotmt.validita_inizio  AND COALESCE(rotmt.validita_fine, p_data)
 AND  p_data BETWEEN  tot.validita_inizio  AND COALESCE(tot.validita_fine, p_data)
 AND  p_data BETWEEN  ros.validita_inizio  AND COALESCE(ros.validita_fine, p_data)
 AND  p_data BETWEEN  dos.validita_inizio  AND COALESCE(dos.validita_fine, p_data)
 AND  p_data BETWEEN  totd.validita_inizio  AND COALESCE(totd.validita_fine, p_data)
 AND  p_data BETWEEN  dotdt.validita_inizio  AND COALESCE(dotdt.validita_fine, p_data)
 AND  rotmt.data_cancellazione IS NULL
 AND  tot.data_cancellazione IS NULL
 AND  ros.data_cancellazione IS NULL
 AND  dos.data_cancellazione IS NULL
 AND  totd.data_cancellazione IS NULL
 AND  dotdt.data_cancellazione IS NULL;
esito:='Importo emesso='||v_importo_emesso_tot::varchar||' per movgest_ts_id='||v_movgest_ts_id||'.';

return next;
-- Sezione per il calcolo dell'importo quietanziato
v_importo_quietanziato_tot := 0;
SELECT COALESCE(SUM(totd.ord_ts_det_importo),0)
    INTO v_importo_quietanziato_tot
    FROM siac.siac_r_ordinativo_ts_movgest_ts rotmt, siac.siac_t_ordinativo_ts tot,
         siac.siac_r_ordinativo_stato ros, siac.siac_d_ordinativo_stato dos,
         siac.siac_t_ordinativo_ts_det totd, siac.siac_d_ordinativo_ts_det_tipo dotdt
    WHERE rotmt.movgest_ts_id = v_movgest_ts_id
    AND  rotmt.ord_ts_id = tot.ord_ts_id
    AND  ros.ord_id = tot.ord_id
    AND  ros.ord_stato_id = dos.ord_stato_id
    AND  totd.ord_ts_id = tot.ord_ts_id
    AND  dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
    AND  dos.ord_stato_code = 'Q'
    AND  dotdt.ord_ts_det_tipo_code = 'A'
    AND  p_data BETWEEN  rotmt.validita_inizio  AND COALESCE(rotmt.validita_fine, p_data)
    AND  p_data BETWEEN  tot.validita_inizio  AND COALESCE(tot.validita_fine, p_data)
    AND  p_data BETWEEN  ros.validita_inizio  AND COALESCE(ros.validita_fine, p_data)
    AND  p_data BETWEEN  dos.validita_inizio  AND COALESCE(dos.validita_fine, p_data)
    AND  p_data BETWEEN  totd.validita_inizio  AND COALESCE(totd.validita_fine, p_data)
    AND  p_data BETWEEN  dotdt.validita_inizio  AND COALESCE(dotdt.validita_fine, p_data)
    AND  rotmt.data_cancellazione IS NULL
    AND  tot.data_cancellazione IS NULL
    AND  ros.data_cancellazione IS NULL
    AND  dos.data_cancellazione IS NULL
    AND  totd.data_cancellazione IS NULL
    AND  dotdt.data_cancellazione IS NULL;
-- 30.06.2016 Sofia SIAC JIRA-5030   INIZIO


IF v_movgest_ts_tipo_code = 'T' THEN

v_programma_code := null;
v_programma_desc := null;

SELECT tp.programma_code, tp.programma_desc
INTO   v_programma_code, v_programma_desc
FROM   siac_r_movgest_ts_programma rmtp, siac_t_programma tp
WHERE  rmtp.movgest_ts_id = v_movgest_ts_id
AND    rmtp.programma_id = tp.programma_id
AND    p_data BETWEEN rmtp.validita_inizio and COALESCE(rmtp.validita_fine,p_data)
AND    p_data BETWEEN tp.validita_inizio and COALESCE(tp.validita_fine,p_data)
AND    rmtp.data_cancellazione IS NULL
AND    tp.data_cancellazione IS NULL;


  INSERT INTO siac.siac_dwh_accertamento
  (ente_proprietario_id,
ente_denominazione,
bil_anno,
cod_fase_operativa,
desc_fase_operativa,
anno_accertamento,
num_accertamento,
desc_accertamento,
cod_accertamento,
cod_stato_accertamento,
desc_stato_accertamento,
data_scadenza,
parere_finanziario,
cod_capitolo,
cod_articolo,
cod_ueb,
desc_capitolo,
desc_articolo,
soggetto_id,
cod_soggetto,
desc_soggetto,
cf_soggetto,
cf_estero_soggetto,
p_iva_soggetto,
cod_classe_soggetto,
desc_classe_soggetto,
cod_entrata_ricorrente,
desc_entrata_ricorrente,
cod_perimetro_sanita_entrata,
desc_perimetro_sanita_entrata,
cod_transazione_ue_entrata,
desc_transazione_ue_entrata,
cod_pdc_finanziario_i,
desc_pdc_finanziario_i,
cod_pdc_finanziario_ii,
desc_pdc_finanziario_ii,
cod_pdc_finanziario_iii,
desc_pdc_finanziario_iii,
cod_pdc_finanziario_iv,
desc_pdc_finanziario_iv,
cod_pdc_finanziario_v,
desc_pdc_finanziario_v,
cod_pdc_economico_i,
desc_pdc_economico_i,
cod_pdc_economico_ii,
desc_pdc_economico_ii,
cod_pdc_economico_iii,
desc_pdc_economico_iii,
cod_pdc_economico_iv,
desc_pdc_economico_iv,
cod_pdc_economico_v,
desc_pdc_economico_v,
cod_cofog_divisione,
desc_cofog_divisione,
cod_cofog_gruppo,
desc_cofog_gruppo,
classificatore_1,
classificatore_1_valore,
classificatore_1_desc_valore,
classificatore_2,
classificatore_2_valore,
classificatore_2_desc_valore,
classificatore_3,
classificatore_3_valore,
classificatore_3_desc_valore,
classificatore_4,
classificatore_4_valore,
classificatore_4_desc_valore,
classificatore_5,
classificatore_5_valore,
classificatore_5_desc_valore,
annocapitoloorigine,
numcapitoloorigine,
annoorigineplur,
numarticoloorigine,
annoriaccertato,
numriaccertato,
numorigineplur,
flagdariaccertamento,
automatico,
note,
validato,
num_ueb_origine,
anno_atto_amministrativo,
num_atto_amministrativo,
oggetto_atto_amministrativo,
note_atto_amministrativo,
cod_tipo_atto_amministrativo,
desc_tipo_atto_amministrativo,
desc_stato_atto_amministrativo,
cod_cdr_atto_amministrativo,
desc_cdr_atto_amministrativo,
cod_cdc_atto_amministrativo,
desc_cdc_atto_amministrativo,
importo_iniziale,
importo_attuale,
importo_utilizzabile,
importo_emesso,
importo_quietanziato,
FlagCollegamentoAccertamentoFattura,
data_inizio_val_stato_accer,
data_inizio_val_accer,
data_creazione_accer,
data_modifica_accer,
cod_programma,
desc_programma
  )
  VALUES (v_ente_proprietario_id,
          v_ente_denominazione,
          v_anno,
          v_fase_operativa_code,
          v_fase_operativa_desc,
          v_movgest_anno,
          v_movgest_numero,
          v_movgest_desc,
          v_movgest_ts_code,
          v_movgest_stato_code,
          v_movgest_stato_desc,
          v_data_scadenza,
          v_parere_finanziario,
          v_codice_capitolo,
          v_codice_articolo,
          v_codice_ueb,
          v_descrizione_capitolo,
          v_descrizione_articolo,
          v_soggetto_id,
          v_codice_soggetto,
          v_descrizione_soggetto,
          v_codice_fiscale_soggetto,
          v_codice_fiscale_estero_soggetto,
          v_partita_iva_soggetto,
          v_codice_classe_soggetto,
          v_descrizione_classe_soggetto,
          v_codice_entrata_ricorrente,
          v_descrizione_entrata_ricorrente,
          v_codice_perimetro_sanitario_entrata,
          v_descrizione_perimetro_sanitario_entrata,
          v_codice_transazione_entrata_ue,
          v_descrizione_transazione_entrata_ue,
          v_codice_pdc_finanziario_I,
          v_descrizione_pdc_finanziario_I,
          v_codice_pdc_finanziario_II,
          v_descrizione_pdc_finanziario_II,
          v_codice_pdc_finanziario_III,
          v_descrizione_pdc_finanziario_III,
          v_codice_pdc_finanziario_IV,
          v_descrizione_pdc_finanziario_IV,
          v_codice_pdc_finanziario_V,
          v_descrizione_pdc_finanziario_V,
          v_codice_pdc_economico_I,
          v_descrizione_pdc_economico_I,
          v_codice_pdc_economico_II,
          v_descrizione_pdc_economico_II,
          v_codice_pdc_economico_III,
          v_descrizione_pdc_economico_III,
          v_codice_pdc_economico_IV,
          v_descrizione_pdc_economico_IV,
          v_codice_pdc_economico_V,
          v_descrizione_pdc_economico_V,
          v_codice_cofog_divisione,
          v_descrizione_cofog_divisione,
          v_codice_cofog_gruppo,
          v_descrizione_cofog_gruppo,
          v_classificatore_generico_1,
          v_classificatore_generico_1_valore,
          v_classificatore_generico_1_descrizione_valore,
          v_classificatore_generico_2,
          v_classificatore_generico_2_valore,
          v_classificatore_generico_2_descrizione_valore,
          v_classificatore_generico_3,
          v_classificatore_generico_3_valore,
          v_classificatore_generico_3_descrizione_valore,
          v_classificatore_generico_4,
          v_classificatore_generico_4_valore,
          v_classificatore_generico_4_descrizione_valore,
          v_classificatore_generico_5,
          v_classificatore_generico_5_valore,
          v_classificatore_generico_5_descrizione_valore,
          v_annoCapitoloOrigine,
          v_numeroCapitoloOrigine,
          v_annoOriginePlur,
          v_numeroArticoloOrigine,
          v_annoRiaccertato,
          v_numeroRiaccertato,
          v_numeroOriginePlur,
          v_flagDaRiaccertamento,
          v_automatico,
          v_note,
          v_validato,
          v_numero_ueb_origine,
          v_anno_atto_amministrativo,
          v_numero_atto_amministrativo::varchar,
          v_oggetto_atto_amministrativo,
          v_note_atto_amministrativo,
          v_codice_tipo_atto_amministrativo,
          v_descrizione_tipo_atto_amministrativo,
          v_descrizione_stato_atto_amministrativo,
          v_cod_cdr_atto_amministrativo,
          v_desc_cdr_atto_amministrativo,
          v_cod_cdc_atto_amministrativo,
          v_desc_cdc_atto_amministrativo,
          v_importo_iniziale,
          v_importo_attuale,
          v_importo_utilizzabile,
          v_importo_emesso_tot,
          v_importo_quietanziato_tot,
          v_FlagCollegamentoAccertamentoFattura,
          v_data_inizio_val_stato_accer,
          v_data_inizio_val_accer,
          v_data_creazione_accer,
          v_data_modifica_accer,
          v_programma_code,
          v_programma_desc
         );
ELSIF v_movgest_ts_tipo_code = 'S' THEN
  INSERT INTO siac.siac_dwh_subaccertamento
  (ente_proprietario_id,
ente_denominazione,
bil_anno,
cod_fase_operativa,
desc_fase_operativa,
anno_accertamento,
num_accertamento,
desc_accertamento,
cod_subaccertamento,
desc_subaccertamento,
cod_stato_subaccertamento,
desc_stato_subaccertamento,
data_scadenza,
parere_finanziario,
cod_capitolo,
cod_articolo,
cod_ueb,
desc_capitolo,
desc_articolo,
soggetto_id,
cod_soggetto,
desc_soggetto,
cf_soggetto,
cf_estero_soggetto,
p_iva_soggetto,
cod_classe_soggetto,
desc_classe_soggetto,
cod_entrata_ricorrente,
desc_entrata_ricorrente,
cod_perimetro_sanita_entrata,
desc_perimetro_sanita_entrata,
cod_transazione_ue_entrata,
desc_transazione_ue_entrata,
cod_pdc_finanziario_i,
desc_pdc_finanziario_i,
cod_pdc_finanziario_ii,
desc_pdc_finanziario_ii,
cod_pdc_finanziario_iii,
desc_pdc_finanziario_iii,
cod_pdc_finanziario_iv,
desc_pdc_finanziario_iv,
cod_pdc_finanziario_v,
desc_pdc_finanziario_v,
cod_pdc_economico_i,
desc_pdc_economico_i,
cod_pdc_economico_ii,
desc_pdc_economico_ii,
cod_pdc_economico_iii,
desc_pdc_economico_iii,
cod_pdc_economico_iv,
desc_pdc_economico_iv,
cod_pdc_economico_v,
desc_pdc_economico_v,
cod_cofog_divisione,
desc_cofog_divisione,
cod_cofog_gruppo,
desc_cofog_gruppo,
classificatore_1,
classificatore_1_valore,
classificatore_1_desc_valore,
classificatore_2,
classificatore_2_valore,
classificatore_2_desc_valore,
classificatore_3,
classificatore_3_valore,
classificatore_3_desc_valore,
classificatore_4,
classificatore_4_valore,
classificatore_4_desc_valore,
classificatore_5,
classificatore_5_valore,
classificatore_5_desc_valore,
annocapitoloorigine,
numcapitoloorigine,
annoorigineplur,
numarticoloorigine,
annoriaccertato,
numriaccertato,
numorigineplur,
flagdariaccertamento,
automatico,
note,
validato,
num_ueb_origine,
anno_atto_amministrativo,
num_atto_amministrativo,
oggetto_atto_amministrativo,
note_atto_amministrativo,
cod_tipo_atto_amministrativo,
desc_tipo_atto_amministrativo,
desc_stato_atto_amministrativo,
cod_cdr_atto_amministrativo,
desc_cdr_atto_amministrativo,
cod_cdc_atto_amministrativo,
desc_cdc_atto_amministrativo,
importo_iniziale,
importo_attuale,
importo_utilizzabile,
importo_emesso,
importo_quietanziato,
FlagCollegamentoAccertamentoFattura,
data_inizio_val_stato_subaccer,
data_inizio_val_subaccer,
data_creazione_subaccer,
data_modifica_subaccer
  )
  VALUES (v_ente_proprietario_id,
          v_ente_denominazione,
          v_anno,
          v_fase_operativa_code,
          v_fase_operativa_desc,
          v_movgest_anno,
          v_movgest_numero,
          v_movgest_desc,
          v_movgest_ts_code,
          v_movgest_ts_desc,
          v_movgest_stato_code,
          v_movgest_stato_desc,
          v_data_scadenza,
          v_parere_finanziario,
          v_codice_capitolo,
          v_codice_articolo,
          v_codice_ueb,
          v_descrizione_capitolo,
          v_descrizione_articolo,
          v_soggetto_id,
          v_codice_soggetto,
          v_descrizione_soggetto,
          v_codice_fiscale_soggetto,
          v_codice_fiscale_estero_soggetto,
          v_partita_iva_soggetto,
          v_codice_classe_soggetto,
          v_descrizione_classe_soggetto,
          v_codice_entrata_ricorrente,
          v_descrizione_entrata_ricorrente,
          v_codice_perimetro_sanitario_entrata,
          v_descrizione_perimetro_sanitario_entrata,
          v_codice_transazione_entrata_ue,
          v_descrizione_transazione_entrata_ue,
          v_codice_pdc_finanziario_I,
          v_descrizione_pdc_finanziario_I,
          v_codice_pdc_finanziario_II,
          v_descrizione_pdc_finanziario_II,
          v_codice_pdc_finanziario_III,
          v_descrizione_pdc_finanziario_III,
          v_codice_pdc_finanziario_IV,
          v_descrizione_pdc_finanziario_IV,
          v_codice_pdc_finanziario_V,
          v_descrizione_pdc_finanziario_V,
          v_codice_pdc_economico_I,
          v_descrizione_pdc_economico_I,
          v_codice_pdc_economico_II,
          v_descrizione_pdc_economico_II,
          v_codice_pdc_economico_III,
          v_descrizione_pdc_economico_III,
          v_codice_pdc_economico_IV,
          v_descrizione_pdc_economico_IV,
          v_codice_pdc_economico_V,
          v_descrizione_pdc_economico_V,
          v_codice_cofog_divisione,
          v_descrizione_cofog_divisione,
          v_codice_cofog_gruppo,
          v_descrizione_cofog_gruppo,
          v_classificatore_generico_1,
          v_classificatore_generico_1_valore,
          v_classificatore_generico_1_descrizione_valore,
          v_classificatore_generico_2,
          v_classificatore_generico_2_valore,
          v_classificatore_generico_2_descrizione_valore,
          v_classificatore_generico_3,
          v_classificatore_generico_3_valore,
          v_classificatore_generico_3_descrizione_valore,
          v_classificatore_generico_4,
          v_classificatore_generico_4_valore,
          v_classificatore_generico_4_descrizione_valore,
          v_classificatore_generico_5,
          v_classificatore_generico_5_valore,
          v_classificatore_generico_5_descrizione_valore,
          v_annoCapitoloOrigine,
          v_numeroCapitoloOrigine,
          v_annoOriginePlur,
          v_numeroArticoloOrigine,
          v_annoRiaccertato,
          v_numeroRiaccertato,
          v_numeroOriginePlur,
          v_flagDaRiaccertamento,
          v_automatico,
          v_note,
          v_validato,
          v_numero_ueb_origine,
          v_anno_atto_amministrativo,
          v_numero_atto_amministrativo::varchar,
          v_oggetto_atto_amministrativo,
          v_note_atto_amministrativo,
          v_codice_tipo_atto_amministrativo,
          v_descrizione_tipo_atto_amministrativo,
          v_descrizione_stato_atto_amministrativo,
          v_cod_cdr_atto_amministrativo,
          v_desc_cdr_atto_amministrativo,
          v_cod_cdc_atto_amministrativo,
          v_desc_cdc_atto_amministrativo,
          v_importo_iniziale,
          v_importo_attuale,
          v_importo_utilizzabile,
          v_importo_emesso_tot,
          v_importo_quietanziato_tot ,
          v_FlagCollegamentoAccertamentoFattura,
          v_data_inizio_val_stato_subaccer,
          v_data_inizio_val_subaccer,
          v_data_creazione_subaccer,
          v_data_modifica_subaccer
         );
END IF;

esito:= '  Fine ciclo movgest - movgest_ts_id ('||v_movgest_id||') - ('||v_movgest_ts_id||') - ('||v_movgest_ts_tipo_code||') - '||clock_timestamp();
RETURN NEXT;
END LOOP;
esito:= 'Fine funzione carico accertamenti (FNC_SIAC_DWH_ACCERTAMENTO) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico accertamenti (FNC_SIAC_DWH_ACCERTAMENTO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
-- SIAC-5030 Sofia FINE

-- SIAC-5040 Sofia INIZIO

alter table siac_dwh_liquidazione add tipo_cessione varchar(50);
alter table siac_dwh_liquidazione add cod_cessione varchar(100);
alter table siac_dwh_liquidazione add desc_cessione varchar(200);

COMMENT ON COLUMN siac.siac_dwh_liquidazione.tipo_cessione
IS 'tipo cessione CSI/CSC';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.cod_cessione
IS 'codice della cessione del tipo tipo_cessione';

COMMENT ON COLUMN siac.siac_dwh_liquidazione.desc_cessione
IS 'descrizione della cessione del tipo tipo_cessione';

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_liquidazione (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

rec_liq_id record;
rec_classif_id record;
rec_attr record;
rec_classif_id_attr record;
-- Variabili per campi estratti dal cursore rec_liq_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_anno VARCHAR := null;
v_fase_operativa_code VARCHAR := null;
v_fase_operativa_desc VARCHAR := null;
v_liq_anno INTEGER := null;
v_liq_numero NUMERIC := null;
v_liq_desc VARCHAR := null;
v_liq_emissione_data DATE := null;
v_liq_importo NUMERIC := null;
v_liq_automatica VARCHAR := null;
v_liq_convalida_manuale VARCHAR := null;
v_liq_stato_code VARCHAR := null;
v_liq_stato_desc VARCHAR := null;
v_contotes_code VARCHAR := null;
v_contotes_desc VARCHAR := null;
v_dist_code VARCHAR := null;
v_dist_desc VARCHAR := null;
v_modpag_id INTEGER := null;
-- Variabili relative agli attributi associati a un liq_id
v_sogg_id INTEGER := null; -- Assume il valore di v_soggetto_id_intestatario o se è null di v_soggetto_id
v_codice_soggetto VARCHAR := null;
v_descrizione_soggetto VARCHAR := null;
v_codice_fiscale_soggetto VARCHAR := null;
v_codice_fiscale_estero_soggetto VARCHAR := null;
v_partita_iva_soggetto VARCHAR := null;
v_codice_soggetto_modpag VARCHAR := null;
v_descrizione_soggetto_modpag VARCHAR := null;
v_codice_fiscale_soggetto_modpag VARCHAR := null;
v_codice_fiscale_estero_soggetto_modpag VARCHAR := null;
v_partita_iva_soggetto_modpag VARCHAR := null;
v_codice_tipo_accredito VARCHAR := null;
v_descrizione_tipo_accredito VARCHAR := null;
v_quietanziante VARCHAR := null;
v_data_nascita_quietanziante TIMESTAMP := null;
v_luogo_nascita_quietanziante VARCHAR := null;
v_stato_nascita_quietanziante VARCHAR := null;
v_bic VARCHAR := null;
v_contocorrente VARCHAR := null;
v_intestazione_contocorrente VARCHAR := null;
v_iban  VARCHAR := null;
v_note_modalita_pagamento VARCHAR := null;
v_data_scadenza_modalita_pagamento TIMESTAMP := null;
v_anno_impegno INTEGER := null;
v_numero_impegno NUMERIC := null;
v_codice_impegno VARCHAR := null;
v_descrizione_impegno VARCHAR := null;
v_codice_subimpegno VARCHAR := null;
v_descrizione_subimpegno VARCHAR := null;

v_movgest_ts_tipo_code VARCHAR := null;
v_movgest_ts_code VARCHAR := null;
v_movgest_ts_desc VARCHAR := null;

-- Variabili per classificatori in gerarchia
v_codice_pdc_finanziario_I VARCHAR := null;
v_descrizione_pdc_finanziario_I VARCHAR := null;
v_codice_pdc_finanziario_II VARCHAR := null;
v_descrizione_pdc_finanziario_II VARCHAR := null;
v_codice_pdc_finanziario_III VARCHAR := null;
v_descrizione_pdc_finanziario_III VARCHAR := null;
v_codice_pdc_finanziario_IV VARCHAR := null;
v_descrizione_pdc_finanziario_IV VARCHAR := null;
v_codice_pdc_finanziario_V VARCHAR := null;
v_descrizione_pdc_finanziario_V VARCHAR := null;
v_codice_pdc_economico_I VARCHAR := null;
v_descrizione_pdc_economico_I VARCHAR := null;
v_codice_pdc_economico_II VARCHAR := null;
v_descrizione_pdc_economico_II VARCHAR := null;
v_codice_pdc_economico_III VARCHAR := null;
v_descrizione_pdc_economico_III VARCHAR := null;
v_codice_pdc_economico_IV VARCHAR := null;
v_descrizione_pdc_economico_IV VARCHAR := null;
v_codice_pdc_economico_V VARCHAR := null;
v_descrizione_pdc_economico_V VARCHAR := null;
v_codice_cofog_divisione VARCHAR := null;
v_descrizione_cofog_divisione VARCHAR := null;
v_codice_cofog_gruppo VARCHAR := null;
v_descrizione_cofog_gruppo VARCHAR := null;
-- Variabili per classificatori non in gerarchia
v_codice_spesa_ricorrente VARCHAR := null;
v_descrizione_spesa_ricorrente VARCHAR := null;
v_codice_transazione_spesa_ue VARCHAR := null;
v_descrizione_transazione_spesa_ue VARCHAR := null;
v_codice_perimetro_sanitario_spesa VARCHAR := null;
v_descrizione_perimetro_sanitario_spesa VARCHAR := null;
v_codice_politiche_regionali_unitarie VARCHAR := null;
v_descrizione_politiche_regionali_unitarie VARCHAR := null;
-- Variabili attributo
v_cig VARCHAR := null;
v_cup VARCHAR := null;
v_anno_atto_amministrativo VARCHAR := null;
v_numero_atto_amministrativo INTEGER := null;
v_oggetto_atto_amministrativo VARCHAR := null;
v_note_atto_amministrativo VARCHAR := null;
v_codice_tipo_atto_amministrativo VARCHAR := null;
v_descrizione_tipo_atto_amministrativo VARCHAR := null;
v_descrizione_stato_atto_amministrativo VARCHAR := null;
v_cod_cdr_atto_amministrativo VARCHAR := null;
v_desc_cdr_atto_amministrativo VARCHAR := null;
v_cod_cdc_atto_amministrativo VARCHAR := null;
v_desc_cdc_atto_amministrativo VARCHAR := null;

v_classif_code VARCHAR := null;
v_classif_desc VARCHAR := null;
v_classif_tipo_code VARCHAR := null;
v_classif_tipo_desc VARCHAR := null;
v_flag_attributo VARCHAR := null;

v_liq_id INTEGER := null;
v_soggetto_id_intestatario INTEGER := null;
v_soggetto_id INTEGER := null;
v_soggetto_id_modpag INTEGER := null;
v_accredito_tipo_id INTEGER := null;
v_movgest_ts_id INTEGER := null;
v_classif_id INTEGER := null;
v_classif_id_part INTEGER := null;
v_classif_id_padre INTEGER := null;
v_classif_tipo_id INTEGER := null;
v_classif_fam_id INTEGER := null;
v_conta_ciclo_classif INTEGER := null;
v_bil_id INTEGER := null;
v_attoamm_id INTEGER := null;

v_fnc_result VARCHAR := null;

v_data_inizio_val_stato_liquidaz TIMESTAMP := null;
v_data_inizio_val_liquidaz TIMESTAMP := null;
v_data_creazione_liquidaz TIMESTAMP := null;
v_data_modifica_liquidaz TIMESTAMP := null;

-- 04.07.2017 Sofia SIAC-5040
v_tipo_cessione varchar(50):=null;
v_cod_cessione  varchar(100):=null;
v_desc_cessione varchar(200):=null;
v_soggetto_relaz_id integer:=null;
v_modpag_cessione_id integer:=null;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_bko_popola_siac_r_class_fam_class_tipo(p_ente_proprietario_id)
into v_fnc_result;

esito:= 'Inizio funzione carico liquidazione (FNC_SIAC_DWH_LIQUIDAZIONE) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_liquidazione
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;
-- Ciclo per estrarre dati di liquidazione (liq_id)
FOR rec_liq_id IN
SELECT dc.contotes_id, tl.contotes_id, dc.validita_inizio, dc.data_cancellazione, tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tl.liq_anno, tl.liq_numero, tl.liq_desc, tl.liq_emissione_data, tl.liq_importo, tl.liq_automatica,
       tl.liq_convalida_manuale, tl.modpag_id, tl.soggetto_relaz_id, -- 04.07.2017 Sofia SIAC-5040
       dls.liq_stato_code, dls.liq_stato_desc,
       dc.contotes_code, dc.contotes_desc, dd.dist_code, dd.dist_desc, srls.soggetto_id,
       rlm.movgest_ts_id, tl.liq_id, tb.bil_id,
       rls.validita_inizio as data_inizio_val_stato_liquidaz,
	   tl.validita_inizio as data_inizio_val_liquidaz,
       tl.data_creazione as data_creazione_liquidaz,
       tl.data_modifica as data_modifica_liquidaz
FROM   siac.siac_t_liquidazione tl
INNER JOIN siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = tl.ente_proprietario_id
INNER JOIN siac.siac_t_bil tb ON tl.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac.siac_r_liquidazione_stato rls ON tl.liq_id = rls.liq_id
INNER JOIN siac.siac_d_liquidazione_stato dls ON rls.liq_stato_id = dls.liq_stato_id
LEFT JOIN  siac.siac_d_contotesoreria dc ON dc.contotes_id = tl.contotes_id
LEFT JOIN  siac.siac_d_distinta dd ON dd.dist_id = tl.dist_id
LEFT JOIN siac.siac_r_liquidazione_soggetto srls ON srls.liq_id = tl.liq_id
                                                 AND p_data BETWEEN srls.validita_inizio AND COALESCE(srls.validita_fine, p_data)
                                                 AND srls.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_liquidazione_movgest rlm ON rlm.liq_id = tl.liq_id
                                               AND p_data BETWEEN rlm.validita_inizio AND COALESCE(rlm.validita_fine, p_data)
                                               AND rlm.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
AND p_data BETWEEN tl.validita_inizio AND COALESCE(tl.validita_fine, p_data)
AND tl.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
AND tb.data_cancellazione IS NULL
AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND tp.data_cancellazione IS NULL
AND p_data BETWEEN rls.validita_inizio AND COALESCE(rls.validita_fine, p_data)
AND rls.data_cancellazione IS NULL
AND p_data BETWEEN dls.validita_inizio AND COALESCE(dls.validita_fine, p_data)
AND dls.data_cancellazione IS NULL

LOOP

v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_anno := null;
v_fase_operativa_code := null;
v_fase_operativa_desc := null;
v_liq_anno := null;
v_liq_numero := null;
v_liq_desc := null;
v_liq_emissione_data := null;
v_liq_importo := null;
v_liq_automatica := null;
v_liq_convalida_manuale := null;
v_liq_stato_code := null;
v_liq_stato_desc := null;
v_contotes_code := null;
v_contotes_desc = null;
v_dist_code := null;
v_dist_desc := null;
v_modpag_id := null;
v_liq_id := null;

v_sogg_id := null;
v_codice_soggetto := null;
v_descrizione_soggetto := null;
v_codice_fiscale_soggetto := null;
v_codice_fiscale_estero_soggetto := null;
v_partita_iva_soggetto := null;
v_codice_soggetto_modpag := null;
v_descrizione_soggetto_modpag := null;
v_codice_fiscale_soggetto_modpag := null;
v_codice_fiscale_estero_soggetto_modpag := null;
v_partita_iva_soggetto_modpag := null;
v_codice_tipo_accredito := null;
v_descrizione_tipo_accredito := null;
v_quietanziante := null;
v_data_nascita_quietanziante := null;
v_luogo_nascita_quietanziante := null;
v_stato_nascita_quietanziante := null;
v_bic := null;
v_contocorrente := null;
v_intestazione_contocorrente := null;
v_iban := null;
v_note_modalita_pagamento := null;
v_data_scadenza_modalita_pagamento := null;
v_anno_impegno := null;
v_numero_impegno := null;
v_codice_impegno := null;
v_descrizione_impegno := null;
v_codice_subimpegno := null;
v_descrizione_subimpegno := null;

v_movgest_ts_tipo_code := null;
v_movgest_ts_code := null;
v_movgest_ts_desc := null;

v_codice_spesa_ricorrente := null;
v_descrizione_spesa_ricorrente := null;
v_codice_transazione_spesa_ue := null;
v_descrizione_transazione_spesa_ue := null;
v_codice_perimetro_sanitario_spesa := null;
v_descrizione_perimetro_sanitario_spesa := null;
v_codice_politiche_regionali_unitarie := null;
v_descrizione_politiche_regionali_unitarie := null;
v_codice_pdc_finanziario_I := null;
v_descrizione_pdc_finanziario_I := null;
v_codice_pdc_finanziario_II := null;
v_descrizione_pdc_finanziario_II := null;
v_codice_pdc_finanziario_III  := null;
v_descrizione_pdc_finanziario_III := null;
v_codice_pdc_finanziario_IV := null;
v_descrizione_pdc_finanziario_IV := null;
v_codice_pdc_finanziario_V := null;
v_descrizione_pdc_finanziario_V := null;
v_codice_pdc_economico_I := null;
v_descrizione_pdc_economico_I := null;
v_codice_pdc_economico_II := null;
v_descrizione_pdc_economico_II := null;
v_codice_pdc_economico_III := null;
v_descrizione_pdc_economico_III := null;
v_codice_pdc_economico_IV := null;
v_descrizione_pdc_economico_IV := null;
v_codice_pdc_economico_V := null;
v_descrizione_pdc_economico_V := null;
v_codice_cofog_divisione:= null;
v_descrizione_cofog_divisione := null;
v_codice_cofog_gruppo := null;
v_descrizione_cofog_gruppo := null;

v_movgest_ts_tipo_code := null;
v_classif_id := null;
v_classif_tipo_id := null;
v_soggetto_id := null;
v_soggetto_id_intestatario := null;
v_soggetto_id_modpag := null;
v_accredito_tipo_id := null;
v_movgest_ts_id := null;
v_bil_id := null;

v_data_inizio_val_stato_liquidaz := null;
v_data_inizio_val_liquidaz := null;
v_data_creazione_liquidaz := null;
v_data_modifica_liquidaz := null;

-- 04.07.2017 Sofia SIAC-5040
v_tipo_cessione:=null;
v_cod_cessione:=null;
v_desc_cessione:=null;
v_modpag_cessione_id:=null;

v_ente_proprietario_id := rec_liq_id.ente_proprietario_id;
v_ente_denominazione := rec_liq_id.ente_denominazione;
v_anno := rec_liq_id.anno;
v_liq_anno := rec_liq_id.liq_anno;
v_liq_numero := rec_liq_id.liq_numero;
v_liq_desc := rec_liq_id.liq_desc;
v_liq_emissione_data := rec_liq_id.liq_emissione_data;
v_liq_importo := rec_liq_id.liq_importo;
v_liq_automatica := rec_liq_id.liq_automatica;
v_liq_convalida_manuale := rec_liq_id.liq_convalida_manuale;
v_liq_stato_code := rec_liq_id.liq_stato_code;
v_liq_stato_desc := rec_liq_id.liq_stato_desc;
v_contotes_code := rec_liq_id.contotes_code;
v_contotes_desc = rec_liq_id.contotes_desc ;
v_dist_code := rec_liq_id.dist_code;
v_dist_desc := rec_liq_id.dist_desc;
v_modpag_id := rec_liq_id.modpag_id;
v_soggetto_relaz_id := rec_liq_id.soggetto_relaz_id; -- 04.07.2017 Sofia SIAC-5040

v_liq_id := rec_liq_id.liq_id;
v_soggetto_id := rec_liq_id.soggetto_id;
v_movgest_ts_id := rec_liq_id.movgest_ts_id;
v_bil_id := rec_liq_id.bil_id;

v_data_inizio_val_stato_liquidaz := rec_liq_id.data_inizio_val_stato_liquidaz;
v_data_inizio_val_liquidaz := rec_liq_id.data_inizio_val_liquidaz;
v_data_creazione_liquidaz := rec_liq_id.data_creazione_liquidaz;
v_data_modifica_liquidaz := rec_liq_id.data_modifica_liquidaz;

esito:= '  Inizio ciclo liquidazione - liq_id ('||v_liq_id||') - '||clock_timestamp();
return next;

-- Sezione per estrarre la fase operativa
SELECT dfo.fase_operativa_code, dfo.fase_operativa_desc
INTO v_fase_operativa_code, v_fase_operativa_desc
FROM siac.siac_r_bil_fase_operativa rbfo, siac.siac_d_fase_operativa dfo
WHERE dfo.fase_operativa_id = rbfo.fase_operativa_id
AND   rbfo.bil_id = v_bil_id
AND   p_data BETWEEN rbfo.validita_inizio AND COALESCE(rbfo.validita_fine, p_data)
AND   p_data BETWEEN dfo.validita_inizio AND COALESCE(dfo.validita_fine, p_data)
AND   rbfo.data_cancellazione IS NULL
AND   dfo.data_cancellazione IS NULL;
-- Sezione per estrarre il soggetto intestatario
SELECT rsr.soggetto_id_da
INTO v_soggetto_id_intestatario
FROM siac.siac_r_soggetto_relaz rsr, siac.siac_d_relaz_tipo drt
WHERE rsr.relaz_tipo_id = drt.relaz_tipo_id
AND   drt.relaz_tipo_code  = 'SEDE_SECONDARIA'
AND   rsr.soggetto_id_a = v_soggetto_id
AND   p_data BETWEEN rsr.validita_inizio AND COALESCE(rsr.validita_fine, p_data)
AND   p_data BETWEEN drt.validita_inizio AND COALESCE(drt.validita_fine, p_data)
AND   rsr.data_cancellazione IS NULL
AND   drt.data_cancellazione IS NULL;
v_sogg_id := COALESCE(v_soggetto_id_intestatario, v_soggetto_id);
-- Sezione per estrarre i dati relativi ad un soggetto_id
SELECT ts.soggetto_code, ts.soggetto_desc, ts.codice_fiscale, ts.codice_fiscale_estero, ts.partita_iva
INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto, v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto
FROM siac.siac_t_soggetto ts
WHERE soggetto_id = v_sogg_id
AND   p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
AND   ts.data_cancellazione IS NULL;

-- Sezione per le modalità di pagamento
-- 04.07.2017 Sofia JIRA SIAC-5040
/*SELECT tm.soggetto_id, tm.accredito_tipo_id, tm.quietanziante, tm.quietanzante_nascita_data, tm.quietanziante_nascita_luogo,
       tm.quietanziante_nascita_stato, tm.bic, tm.contocorrente, tm.contocorrente_intestazione, tm.iban,
       tm.note, tm.data_scadenza
INTO v_soggetto_id_modpag, v_accredito_tipo_id, v_quietanziante, v_data_nascita_quietanziante, v_luogo_nascita_quietanziante,
     v_stato_nascita_quietanziante, v_bic, v_contocorrente, v_intestazione_contocorrente, v_iban,
     v_note_modalita_pagamento, v_data_scadenza_modalita_pagamento
FROM siac.siac_t_modpag tm
WHERE tm.modpag_id = v_modpag_id
AND   p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
AND   tm.data_cancellazione IS NULL;*/
-- 04.07.2017 Sofia JIRA SIAC-5040
SELECT mdp_query.soggetto_id, mdp_query.modpag_id,
       mdp_query.accredito_tipo_id,
       mdp_query.quietanziante, mdp_query.quietanzante_nascita_data, mdp_query.quietanziante_nascita_luogo,
       mdp_query.quietanziante_nascita_stato, mdp_query.bic, mdp_query.contocorrente,
       mdp_query.contocorrente_intestazione, mdp_query.iban,
       mdp_query.note, mdp_query.data_scadenza,
       mdp_query.oil_relaz_tipo_code, mdp_query.relaz_tipo_code,mdp_query.relaz_tipo_desc
INTO v_soggetto_id_modpag, v_modpag_cessione_id,
     v_accredito_tipo_id, v_quietanziante, v_data_nascita_quietanziante, v_luogo_nascita_quietanziante,
     v_stato_nascita_quietanziante, v_bic, v_contocorrente, v_intestazione_contocorrente, v_iban,
     v_note_modalita_pagamento, v_data_scadenza_modalita_pagamento,
     v_tipo_cessione,
     v_cod_cessione, v_desc_cessione
from
(
 select tm.soggetto_id, tm.modpag_id,
        tm.accredito_tipo_id, tm.quietanziante, tm.quietanzante_nascita_data, tm.quietanziante_nascita_luogo,
        tm.quietanziante_nascita_stato, tm.bic, tm.contocorrente, tm.contocorrente_intestazione, tm.iban,
        tm.note, tm.data_scadenza ,
        null oil_relaz_tipo_code, null relaz_tipo_code, null relaz_tipo_desc
 FROM  siac_t_modpag tm
 WHERE tm.modpag_id = v_modpag_id
 AND   p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
 AND   tm.data_cancellazione IS NULL
 union
 select rel.soggetto_id_a soggetto_id, mdp.modpag_id,
        mdp.accredito_tipo_id, mdp.quietanziante, mdp.quietanzante_nascita_data, mdp.quietanziante_nascita_luogo,
        mdp.quietanziante_nascita_stato, mdp.bic, mdp.contocorrente, mdp.contocorrente_intestazione, mdp.iban,
        mdp.note, mdp.data_scadenza,
        oil.oil_relaz_tipo_code,tipo.relaz_tipo_code, tipo.relaz_tipo_desc
 FROM  siac_r_soggetto_relaz rel, siac_r_soggrel_modpag sogrel, siac_t_modpag mdp,
       siac_r_oil_relaz_tipo roil, siac_d_relaz_tipo tipo , siac_d_oil_relaz_tipo oil
 WHERE rel.soggetto_relaz_id=v_soggetto_relaz_id
 and   sogrel.soggetto_relaz_id=rel.soggetto_relaz_id
 and   mdp.modpag_id=sogrel.modpag_id
 and   tipo.relaz_tipo_id=rel.relaz_tipo_id
 and   roil.relaz_tipo_id=tipo.relaz_tipo_id
 and   oil.oil_relaz_tipo_id=roil.oil_relaz_tipo_id
 AND   p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
 AND   p_data BETWEEN sogrel.validita_inizio AND COALESCE(sogrel.validita_fine, p_data)
 AND   p_data BETWEEN mdp.validita_inizio AND COALESCE(mdp.validita_fine, p_data)
 AND   p_data BETWEEN roil.validita_inizio AND COALESCE(roil.validita_fine, p_data)
 AND   rel.data_cancellazione IS NULL
 AND   sogrel.data_cancellazione IS NULL
 AND   mdp.data_cancellazione IS NULL
 AND   roil.data_cancellazione IS NULL
) mdp_query;
if v_modpag_cessione_id is not null then v_modpag_id:=v_modpag_cessione_id; end if;

-- 04.07.2017 Sofia JIRA SIAC-5040 - FINE

-- Sezione per estrarre i dati relativi ad un modpag_id
SELECT ts.soggetto_code, ts.soggetto_desc, ts.codice_fiscale, ts.codice_fiscale_estero, ts.partita_iva
INTO v_codice_soggetto_modpag, v_descrizione_soggetto_modpag, v_codice_fiscale_soggetto_modpag,
     v_codice_fiscale_estero_soggetto_modpag, v_partita_iva_soggetto_modpag
FROM siac.siac_t_soggetto ts
WHERE soggetto_id = v_soggetto_id_modpag
AND   p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
AND   ts.data_cancellazione IS NULL;
-- Sezione per il tipo di accredito
SELECT dat.accredito_tipo_code, dat.accredito_tipo_desc
INTO v_codice_tipo_accredito, v_descrizione_tipo_accredito
FROM siac.siac_d_accredito_tipo dat
WHERE dat.accredito_tipo_id = v_accredito_tipo_id
AND   p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)
AND   dat.data_cancellazione IS NULL;

-- Sezione per estrarre dati relativi ad un movgest_ts_id
SELECT tmt.movgest_ts_code, tmt.movgest_ts_desc, dmtt.movgest_ts_tipo_code,
       tm.movgest_anno, tm.movgest_numero
INTO  v_movgest_ts_code, v_movgest_ts_desc, v_movgest_ts_tipo_code,
      v_anno_impegno, v_numero_impegno
FROM  siac.siac_t_movgest_ts tmt, siac.siac_d_movgest_ts_tipo dmtt, siac.siac_t_movgest tm
WHERE tmt.movgest_ts_id = v_movgest_ts_id
AND   tmt.movgest_ts_tipo_id = dmtt.movgest_ts_tipo_id
AND   tm.movgest_id = tmt.movgest_id
AND   p_data BETWEEN tmt.validita_inizio AND COALESCE(tmt.validita_fine, p_data)
AND   p_data BETWEEN dmtt.validita_inizio AND COALESCE(dmtt.validita_fine, p_data)
AND   p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
AND   tmt.data_cancellazione IS NULL
AND   dmtt.data_cancellazione IS NULL
AND   tm.data_cancellazione IS NULL;

IF v_movgest_ts_tipo_code = 'T' THEN
   v_codice_impegno       := v_movgest_ts_code;
   v_descrizione_impegno  := v_movgest_ts_desc;
ELSIF v_movgest_ts_tipo_code = 'S' THEN
   v_codice_subimpegno       := v_movgest_ts_code;
   v_descrizione_subimpegno  := v_movgest_ts_desc;
END IF;

-- Ciclo per estrarre i classificatori relativi ad un dato liq_id
FOR rec_classif_id IN
SELECT tc.classif_id, tc.classif_tipo_id,
     tc.classif_code, tc.classif_desc, dct.classif_tipo_code,dct.classif_tipo_desc
FROM  siac.siac_r_liquidazione_class rlc, siac.siac_t_class tc, siac.siac_d_class_tipo dct
WHERE tc.classif_id = rlc.classif_id
AND   dct.classif_tipo_id = tc.classif_tipo_id
AND   rlc.liq_id = v_liq_id
AND   rlc.data_cancellazione IS NULL
AND   tc.data_cancellazione IS NULL
AND   dct.data_cancellazione IS NULL
AND   p_data BETWEEN rlc.validita_inizio AND COALESCE(rlc.validita_fine, p_data)
AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data)

LOOP

v_classif_id :=  rec_classif_id.classif_id;
v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
v_classif_fam_id := null;

-- Estrazione per determinare se un classificatore e' in gerarchia
SELECT rcfct.classif_fam_id
INTO v_classif_fam_id
FROM siac.siac_r_class_fam_class_tipo rcfct
WHERE rcfct.classif_tipo_id = v_classif_tipo_id
AND   rcfct.data_cancellazione IS NULL
AND   p_data BETWEEN rcfct.validita_inizio AND COALESCE(rcfct.validita_fine, p_data);

-- Se il classificatore non e' in gerarchia
IF NOT FOUND THEN
  esito:= '    Inizio step classificatori non in gerarchia - '||clock_timestamp();
  return next;
  v_classif_tipo_code := null;
  v_classif_tipo_desc :=null;
  v_classif_code := rec_classif_id.classif_code;
  v_classif_desc := rec_classif_id.classif_desc;

  SELECT dct.classif_tipo_code,dct.classif_tipo_desc
  INTO   v_classif_tipo_code,v_classif_tipo_desc
  FROM   siac.siac_d_class_tipo dct
  WHERE  dct.classif_tipo_id = v_classif_tipo_id
  AND    dct.data_cancellazione IS NULL
  AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'RICORRENTE_SPESA' THEN
     v_codice_spesa_ricorrente      := v_classif_code;
     v_descrizione_spesa_ricorrente := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TRANSAZIONE_UE_SPESA' THEN
     v_codice_transazione_spesa_ue      := v_classif_code;
     v_descrizione_transazione_spesa_ue := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PERIMETRO_SANITARIO_SPESA' THEN
     v_codice_perimetro_sanitario_spesa      := v_classif_code;
     v_descrizione_perimetro_sanitario_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'POLITICHE_REGIONALI_UNITARIE' THEN
     v_codice_politiche_regionali_unitarie      := v_classif_code;
     v_descrizione_politiche_regionali_unitarie := v_classif_desc;
  END IF;
  esito:= '    Fine step classificatori non in gerarchia - '||clock_timestamp();
  return next;
-- Se il classificatore e' in gerarchia
ELSE
  esito:= '    Inizio step classificatori in gerarchia - '||clock_timestamp();
  return next;
  v_conta_ciclo_classif :=0;
  v_classif_id_padre := null;

  -- Loop per RISALIRE la gerarchia di un dato classificatore
  LOOP

  v_classif_code := null;
  v_classif_desc := null;
  v_classif_id_part := null;
  v_classif_tipo_code := null;
  v_classif_tipo_desc := null;

  IF v_conta_ciclo_classif = 0 THEN
     v_classif_id_part := v_classif_id;
  ELSE
     v_classif_id_part := v_classif_id_padre;
  END IF;

  SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code,dct.classif_tipo_desc
  INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code,v_classif_tipo_desc
  FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
  WHERE rcft.classif_id = tc.classif_id
  AND   dct.classif_tipo_id = tc.classif_tipo_id
  AND   tc.classif_id = v_classif_id_part
  AND   rcft.data_cancellazione IS NULL
  AND   tc.data_cancellazione IS NULL
  AND   dct.data_cancellazione IS NULL
  AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
  AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
  AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'PDC_I' THEN
        v_codice_pdc_finanziario_I := v_classif_code;
        v_descrizione_pdc_finanziario_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_II' THEN
        v_codice_pdc_finanziario_II := v_classif_code;
        v_descrizione_pdc_finanziario_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_III' THEN
        v_codice_pdc_finanziario_III := v_classif_code;
        v_descrizione_pdc_finanziario_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_IV' THEN
        v_codice_pdc_finanziario_IV := v_classif_code;
        v_descrizione_pdc_finanziario_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_V' THEN
        v_codice_pdc_finanziario_V := v_classif_code;
        v_descrizione_pdc_finanziario_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_I' THEN
        v_codice_pdc_economico_I := v_classif_code;
        v_descrizione_pdc_economico_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_II' THEN
        v_codice_pdc_economico_II := v_classif_code;
        v_descrizione_pdc_economico_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_III' THEN
        v_codice_pdc_economico_III := v_classif_code;
        v_descrizione_pdc_economico_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_IV' THEN
        v_codice_pdc_economico_IV := v_classif_code;
        v_descrizione_pdc_economico_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_V' THEN
        v_codice_pdc_economico_V := v_classif_code;
        v_descrizione_pdc_economico_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'DIVISIONE_COFOG' THEN
        v_codice_cofog_divisione := v_classif_code;
        v_descrizione_cofog_divisione := v_classif_desc;
  ELSIF v_classif_tipo_code = 'GRUPPO_COFOG' THEN
        v_codice_cofog_gruppo := v_classif_code;
        v_descrizione_cofog_gruppo := v_classif_desc;
  END IF;

  v_conta_ciclo_classif := v_conta_ciclo_classif +1;
  EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
  esito:= '    Fine step classificatori in gerarchia - '||clock_timestamp();
  return next;
END IF;
END LOOP;

-- Sezione pe gli attributi
v_cig := null;
v_cup := null;
v_anno_atto_amministrativo := null;
v_numero_atto_amministrativo := null;
v_oggetto_atto_amministrativo := null;
v_note_atto_amministrativo := null;
v_codice_tipo_atto_amministrativo := null;
v_descrizione_tipo_atto_amministrativo := null;
v_descrizione_stato_atto_amministrativo := null;
v_cod_cdr_atto_amministrativo := null;
v_desc_cdr_atto_amministrativo := null;
v_cod_cdc_atto_amministrativo := null;
v_desc_cdc_atto_amministrativo := null;
v_attoamm_id := null;

v_flag_attributo := null;

FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rla.tabella_id, rla.percentuale, rla."boolean" true_false, rla.numerico, rla.testo
FROM   siac.siac_r_liquidazione_attr rla, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rla.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rla.liq_id = v_liq_id
AND    rla.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rla.validita_inizio AND COALESCE(rla.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'cig' THEN
     v_cig := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'cup' THEN
     v_cup := v_flag_attributo;
  END IF;

END LOOP;
-- Sezione pe i dati amministrativi
SELECT taa.attoamm_anno, taa.attoamm_numero, taa.attoamm_oggetto, taa.attoamm_note,
       daat.attoamm_tipo_code, daat.attoamm_tipo_desc, daas.attoamm_stato_desc, taa.attoamm_id
INTO   v_anno_atto_amministrativo, v_numero_atto_amministrativo, v_oggetto_atto_amministrativo,
       v_note_atto_amministrativo, v_codice_tipo_atto_amministrativo,
       v_descrizione_tipo_atto_amministrativo, v_descrizione_stato_atto_amministrativo, v_attoamm_id
FROM siac.siac_r_liquidazione_atto_amm rlaa, siac.siac_t_atto_amm taa, siac.siac_r_atto_amm_stato raas, siac.siac_d_atto_amm_stato daas,
     siac.siac_d_atto_amm_tipo daat
WHERE taa.attoamm_id = rlaa.attoamm_id
AND   taa.attoamm_id = raas.attoamm_id
AND   raas.attoamm_stato_id = daas.attoamm_stato_id
AND   taa.attoamm_tipo_id = daat.attoamm_tipo_id
AND   rlaa.liq_id = v_liq_id
AND   rlaa.data_cancellazione IS NULL
AND   taa.data_cancellazione IS NULL
AND   raas.data_cancellazione IS NULL
AND   daas.data_cancellazione IS NULL
AND   daat.data_cancellazione IS NULL
AND   p_data BETWEEN rlaa.validita_inizio AND COALESCE(rlaa.validita_fine, p_data)
AND   p_data BETWEEN taa.validita_inizio AND COALESCE(taa.validita_fine, p_data)
AND   p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
AND   p_data BETWEEN daas.validita_inizio AND COALESCE(daas.validita_fine, p_data)
AND   p_data BETWEEN daat.validita_inizio AND COALESCE(daat.validita_fine, p_data);

-- Sezione per i classificatori legati agli atti amministrativi
esito:= '    Inizio step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
return next;
FOR rec_classif_id_attr IN
SELECT raac.classif_id
FROM  siac.siac_r_atto_amm_class raac
WHERE raac.attoamm_id = v_attoamm_id
AND   raac.data_cancellazione IS NULL
AND   p_data BETWEEN raac.validita_inizio AND COALESCE(raac.validita_fine, p_data)

LOOP

  v_conta_ciclo_classif :=0;
  v_classif_id_padre := null;

  -- Loop per RISALIRE la gerarchia di un dato classificatore
  LOOP

      v_classif_code := null;
      v_classif_desc := null;
      v_classif_id_part := null;
      v_classif_tipo_code := null;
      v_classif_tipo_desc := null;

      IF v_conta_ciclo_classif = 0 THEN
         v_classif_id_part := rec_classif_id_attr.classif_id;
      ELSE
         v_classif_id_part := v_classif_id_padre;
      END IF;

      SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code,dct.classif_tipo_desc
      INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code,v_classif_tipo_desc
      FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
      WHERE rcft.classif_id = tc.classif_id
      AND   dct.classif_tipo_id = tc.classif_tipo_id
      AND   tc.classif_id = v_classif_id_part
      AND   rcft.data_cancellazione IS NULL
      AND   tc.data_cancellazione IS NULL
      AND   dct.data_cancellazione IS NULL
      AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
      AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
      AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

      IF v_classif_tipo_code = 'CDR' THEN
         v_cod_cdr_atto_amministrativo := v_classif_code;
         v_desc_cdr_atto_amministrativo := v_classif_desc;
      ELSIF v_classif_tipo_code = 'CDC' THEN
         v_cod_cdc_atto_amministrativo := v_classif_code;
         v_desc_cdc_atto_amministrativo := v_classif_desc;
      END IF;

      v_conta_ciclo_classif := v_conta_ciclo_classif +1;
      EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
END LOOP;
esito:= '    Fine step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
return next;


  INSERT INTO siac.siac_dwh_liquidazione
  (ente_proprietario_id,
   ente_denominazione,
   bil_anno,
   cod_fase_operativa,
   desc_fase_operativa,
   anno_liquidazione,
   num_liquidazione,
   desc_liquidazione,
   data_emissione_liquidazione,
   importo_liquidazione,
   liquidazione_automatica,
   liquidazione_convalida_manuale,
   cod_stato_liquidazione,
   desc_stato_liquidazione,
   cod_conto_tesoreria,
   decrizione_conto_tesoreria,
   cod_distinta,
   desc_distinta,
   soggetto_id,
   cod_soggetto,
   desc_soggetto,
   cf_soggetto,
   cf_estero_soggetto,
   p_iva_soggetto,
   soggetto_id_mod_pag,
   cod_soggetto_mod_pag,
   desc_soggetto_mod_pag,
   cf_soggetto_mod_pag,
   cf_estero_soggetto_mod_pag,
   p_iva_soggetto_mod_pag,
   cod_tipo_accredito,
   desc_tipo_accredito,
   mod_pag_id,
   quietanziante,
   data_nascita_quietanziante,
   luogo_nascita_quietanziante,
   stato_nascita_quietanziante,
   bic,
   contocorrente,
   intestazione_contocorrente,
   iban,
   note_mod_pag,
   data_scadenza_mod_pag,
   anno_impegno,
   num_impegno,
   cod_impegno,
   desc_impegno,
   cod_subimpegno,
   desc_subimpegno,
   cod_tipo_atto_amministrativo,
   desc_tipo_atto_amministrativo,
   desc_stato_atto_amministrativo,
   anno_atto_amministrativo,
   num_atto_amministrativo,
   oggetto_atto_amministrativo,
   note_atto_amministrativo,
   cod_spesa_ricorrente,
   desc_spesa_ricorrente,
   cod_perimetro_sanita_spesa,
   desc_perimetro_sanita_spesa,
   cod_politiche_regionali_unit,
   desc_politiche_regionali_unit,
   cod_transazione_ue_spesa,
   desc_transazione_ue_spesa,
   cod_pdc_finanziario_i,
   desc_pdc_finanziario_i,
   cod_pdc_finanziario_ii,
   desc_pdc_finanziario_ii,
   cod_pdc_finanziario_iii,
   desc_pdc_finanziario_iii,
   cod_pdc_finanziario_iv,
   desc_pdc_finanziario_iv,
   cod_pdc_finanziario_v,
   desc_pdc_finanziario_v,
   cod_pdc_economico_i,
   desc_pdc_economico_i,
   cod_pdc_economico_ii,
   desc_pdc_economico_ii,
   cod_pdc_economico_iii,
   desc_pdc_economico_iii,
   cod_pdc_economico_iv,
   desc_pdc_economico_iv,
   cod_pdc_economico_v,
   desc_pdc_economico_v,
   cod_cofog_divisione,
   desc_cofog_divisione,
   cod_cofog_gruppo,
   desc_cofog_gruppo,
   cup,
   cig,
   cod_cdr_atto_amministrativo,
   desc_cdr_atto_amministrativo,
   cod_cdc_atto_amministrativo,
   desc_cdc_atto_amministrativo,
   data_inizio_val_stato_liquidaz,
   data_inizio_val_liquidaz,
   data_creazione_liquidaz,
   data_modifica_liquidaz,
   tipo_cessione, -- 04.07.2017 Sofia SIAC-5040
   cod_cessione,  -- 04.07.2017 Sofia SIAC-5040
   desc_cessione  -- 04.07.2017 Sofia SIAC-5040
   )
  VALUES (v_ente_proprietario_id,
          v_ente_denominazione,
          v_anno,
          v_fase_operativa_code,
          v_fase_operativa_desc,
          v_liq_anno,
          v_liq_numero,
          v_liq_desc,
          v_liq_emissione_data,
          v_liq_importo,
          v_liq_automatica,
          v_liq_convalida_manuale,
          v_liq_stato_code,
          v_liq_stato_desc,
          v_contotes_code,
          v_contotes_desc,
          v_dist_code,
          v_dist_desc,
          v_sogg_id,
          v_codice_soggetto,
          v_descrizione_soggetto,
          v_codice_fiscale_soggetto,
          v_codice_fiscale_estero_soggetto,
          v_partita_iva_soggetto,
          v_soggetto_id_modpag,
          v_codice_soggetto_modpag,
          v_descrizione_soggetto_modpag,
          v_codice_fiscale_soggetto_modpag,
          v_codice_fiscale_estero_soggetto_modpag,
          v_partita_iva_soggetto_modpag,
          v_codice_tipo_accredito,
          v_descrizione_tipo_accredito,
          v_modpag_id,
          v_quietanziante,
          v_data_nascita_quietanziante,
          v_luogo_nascita_quietanziante,
          v_stato_nascita_quietanziante,
          v_bic,
          v_contocorrente,
          v_intestazione_contocorrente,
          v_iban,
          v_note_modalita_pagamento,
          v_data_scadenza_modalita_pagamento,
          v_anno_impegno,
          v_numero_impegno,
          v_codice_impegno,
          v_descrizione_impegno,
          v_codice_subimpegno,
          v_descrizione_subimpegno,
          v_codice_tipo_atto_amministrativo,
          v_descrizione_tipo_atto_amministrativo,
          v_descrizione_stato_atto_amministrativo,
          v_anno_atto_amministrativo,
          v_numero_atto_amministrativo,
          v_oggetto_atto_amministrativo,
          v_note_atto_amministrativo,
          v_codice_spesa_ricorrente,
          v_descrizione_spesa_ricorrente,
          v_codice_perimetro_sanitario_spesa,
          v_descrizione_perimetro_sanitario_spesa,
          v_codice_politiche_regionali_unitarie,
          v_descrizione_politiche_regionali_unitarie,
          v_codice_transazione_spesa_ue,
          v_descrizione_transazione_spesa_ue,
          v_codice_pdc_finanziario_I,
          v_descrizione_pdc_finanziario_I,
          v_codice_pdc_finanziario_II,
          v_descrizione_pdc_finanziario_II,
          v_codice_pdc_finanziario_III,
          v_descrizione_pdc_finanziario_III,
          v_codice_pdc_finanziario_IV,
          v_descrizione_pdc_finanziario_IV,
          v_codice_pdc_finanziario_V,
          v_descrizione_pdc_finanziario_V,
          v_codice_pdc_economico_I,
          v_descrizione_pdc_economico_I,
          v_codice_pdc_economico_II,
          v_descrizione_pdc_economico_II,
          v_codice_pdc_economico_III,
          v_descrizione_pdc_economico_III,
          v_codice_pdc_economico_IV,
          v_descrizione_pdc_economico_IV,
          v_codice_pdc_economico_V,
          v_descrizione_pdc_economico_V,
          v_codice_cofog_divisione,
          v_descrizione_cofog_divisione,
          v_codice_cofog_gruppo,
          v_descrizione_cofog_gruppo,
          v_cup,
          v_cig,
          v_cod_cdr_atto_amministrativo,
          v_desc_cdr_atto_amministrativo,
          v_cod_cdc_atto_amministrativo,
          v_desc_cdc_atto_amministrativo,
          v_data_inizio_val_stato_liquidaz,
          v_data_inizio_val_liquidaz,
          v_data_creazione_liquidaz,
          v_data_modifica_liquidaz,
          v_tipo_cessione, -- 04.07.2017 Sofia SIAC-5040
          v_cod_cessione,  -- 04.07.2017 Sofia SIAC-5040
          v_desc_cessione  -- 04.07.2017 Sofia SIAC-5040
         );
esito:= '  Fine ciclo liquidazione - liq_id ('||v_liq_id||') - '||clock_timestamp();
RETURN NEXT;
END LOOP;
esito:= 'Fine funzione carico liquidazione (FNC_SIAC_DWH_LIQUIDAZIONE) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico liquidazione (FNC_SIAC_DWH_LIQUIDAZIONE) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;


-- SIAC-5040 Sofia Fine

-- SIAC-5037 INIZIO

alter table siac_dwh_subordinativo_pagamento 
	add cod_gruppo_doc VARCHAR(200),
	add desc_gruppo_doc VARCHAR(500),
	add cod_famiglia_doc VARCHAR(200),
	add desc_famiglia_doc VARCHAR(500),
	add cod_tipo_doc VARCHAR(200),
	add desc_tipo_doc VARCHAR(500),
	add anno_doc INTEGER,
	add num_doc VARCHAR(200),
	add num_subdoc INTEGER,
	add cod_sogg_doc VARCHAR(200);
	
	
alter table siac_dwh_subordinativo_incasso
	add cod_gruppo_doc VARCHAR(200),
	add desc_gruppo_doc VARCHAR(500),
	add cod_famiglia_doc VARCHAR(200),
	add desc_famiglia_doc VARCHAR(500),
	add cod_tipo_doc VARCHAR(200),
	add desc_tipo_doc VARCHAR(500),
	add anno_doc INTEGER,
	add num_doc VARCHAR(200),
	add num_subdoc INTEGER,
	add cod_sogg_doc VARCHAR(200);
	
	
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_ordinativo_incasso (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
) 
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

esito:= 'Inizio funzione carico ordinativi in incasso (FNC_SIAC_DWH_ORDINATIVO_INCASSO) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_ordinativo_incasso
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

esito:= '  Inizio eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_subordinativo_incasso
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;


INSERT INTO siac.siac_dwh_ordinativo_incasso
  (
  ente_proprietario_id,
  ente_denominazione,
  bil_anno,
  cod_fase_operativa,
  desc_fase_operativa,
  anno_ord_inc,
  num_ord_inc,
  desc_ord_inc,
  cod_stato_ord_inc,
  desc_stato_ord_inc,
  castelletto_cassa_ord_inc,
  castelletto_competenza_ord_inc,
  castelletto_emessi_ord_inc,
  data_emissione,
  data_riduzione,
  data_spostamento,
  data_variazione,
  beneficiario_multiplo,
  cod_bollo,
  desc_cod_bollo,
  cod_tipo_commissione,
  desc_tipo_commissione,
  cod_conto_tesoreria,
  decrizione_conto_tesoreria,
  cod_distinta,
  desc_distinta,
  soggetto_id,
  cod_soggetto,
  desc_soggetto,
  cf_soggetto,
  cf_estero_soggetto,
  p_iva_soggetto,
  soggetto_id_mod_pag,
  cod_soggetto_mod_pag,
  desc_soggetto_mod_pag,
  cf_soggetto_mod_pag,
  cf_estero_soggetto_mod_pag,
  p_iva_soggetto_mod_pag,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  desc_stato_atto_amministrativo,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  note_atto_amministrativo,
  cod_tipo_avviso,
  desc_tipo_avviso,
  cod_pdc_finanziario_i,
  desc_pdc_finanziario_i,
  cod_pdc_finanziario_ii,
  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,
  desc_pdc_finanziario_iii,
  cod_pdc_finanziario_iv,
  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,
  desc_pdc_finanziario_v,
  cod_pdc_economico_i,
  desc_pdc_economico_i,
  cod_pdc_economico_ii,
  desc_pdc_economico_ii,
  cod_pdc_economico_iii,
  desc_pdc_economico_iii,
  cod_pdc_economico_iv,
  desc_pdc_economico_iv,
  cod_pdc_economico_v,
  desc_pdc_economico_v,
  cod_cofog_divisione,
  desc_cofog_divisione,
  cod_cofog_gruppo,
  desc_cofog_gruppo,
  classificatore_1,
  classificatore_1_valore,
  classificatore_1_desc_valore,
  classificatore_2,
  classificatore_2_valore,
  classificatore_2_desc_valore,
  classificatore_3,
  classificatore_3_valore,
  classificatore_3_desc_valore,
  classificatore_4,
  classificatore_4_valore,
  classificatore_4_desc_valore,
  classificatore_5,
  classificatore_5_valore,
  classificatore_5_desc_valore,
  allegato_cartaceo,
  cup,
  note,
  cod_capitolo,
  cod_articolo,
  cod_ueb,
  desc_capitolo,
  desc_articolo,
  importo_iniziale,
  importo_attuale,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  data_firma,
  firma,
  data_inizio_val_stato_ordin,
  data_inizio_val_ordin,
  data_creazione_ordin,
  data_modifica_ordin,
  data_trasmissione,
  cod_siope,
  desc_siope
  )
select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end, 
tb.codbollo_code, tb.codbollo_desc,
tb.comm_tipo_code, tb.comm_tipo_desc,
tb.contotes_code, tb.contotes_desc,
tb.dist_code, tb.dist_desc,
tb.soggetto_id,tb.soggetto_code, tb.soggetto_desc, tb.codice_fiscale, tb.codice_fiscale_estero, tb.partita_iva,
tb.v_soggetto_id_modpag,  tb.v_codice_soggetto_modpag, tb.v_descrizione_soggetto_modpag,
tb.v_codice_fiscale_soggetto_modpag,tb. v_codice_fiscale_estero_soggetto_modpag,tb.v_partita_iva_soggetto_modpag,
tb.v_codice_tipo_accredito, tb.v_descrizione_tipo_accredito, tb.modpag_id,
tb.v_quietanziante, tb.v_data_nascita_quietanziante,tb.v_luogo_nascita_quietanziante,tb.v_stato_nascita_quietanziante, 
tb.v_bic, tb.v_contocorrente, tb.v_intestazione_contocorrente, tb.v_iban, 
tb.v_note_modalita_pagamento, tb.v_data_scadenza_modalita_pagamento,
tb.attoamm_tipo_code, tb.attoamm_tipo_desc,tb.attoamm_stato_desc,
tb.attoamm_anno, tb.attoamm_numero, tb.attoamm_oggetto, tb.attoamm_note,
tb.v_codice_tipo_avviso, tb.v_descrizione_tipo_avviso,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_I else tb.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_I else tb.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_II else tb.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_II else tb.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_III else tb.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_III else tb.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_IV else tb.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_IV else tb.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_I else tb.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_I else tb.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_II else tb.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_II else tb.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_III else tb.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_III else tb.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_IV else tb.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_IV else tb.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
tb.codice_cofog_divisione, tb.descrizione_cofog_divisione,tb.codice_cofog_gruppo,tb.descrizione_cofog_gruppo,
tb.cla26_classif_tipo_desc,tb.cla26_classif_code,tb.cla26_classif_desc,
tb.cla27_classif_tipo_desc,tb.cla27_classif_code,tb.cla27_classif_desc,
tb.cla28_classif_tipo_desc,tb.cla28_classif_code,tb.cla28_classif_desc,
tb.cla29_classif_tipo_desc,tb.cla29_classif_code,tb.cla29_classif_desc, 
tb.cla30_classif_tipo_desc,tb.cla30_classif_code,tb.cla30_classif_desc, 
tb.v_flagAllegatoCartaceo,
tb.v_cup,
tb.v_note_ordinativo,
tb.v_codice_capitolo, tb.v_codice_articolo, tb.v_codice_ueb, tb.v_descrizione_capitolo , 
tb.v_descrizione_articolo,tb.importo_iniziale,tb.importo_attuale,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_code::varchar else tb.cdr_cdr_code::varchar end cdr_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_desc::varchar else tb.cdr_cdr_desc::varchar end cdr_desc,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_code::varchar else tb.cdr_cdc_code::varchar end cdc_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_desc::varchar else tb.cdr_cdc_desc::varchar end cdc_desc,
tb.v_data_firma,tb.v_firma,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_ordpg,
tb.data_creazione_ordpg,
tb.data_modifica_ordpg,
tb.ord_trasm_oil_data,
tb.mif_ord_class_codice_cge,
tb.descr_siope
from (
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza, 
a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data, 
a.ord_beneficiariomult
,a.ord_id, --q.elem_id,
b.bil_id, a.comm_tipo_id,
f.validita_inizio as data_inizio_val_stato_ordpg,
a.validita_inizio as data_inizio_val_ordpg,
a.data_creazione as data_creazione_ordpg,
a.data_modifica as data_modifica_ordpg,
a.codbollo_id,a.contotes_id,a.dist_id,
a.ord_trasm_oil_data
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i 
where  d.ente_proprietario_id = p_ente_proprietario_id
and 
c.anno = p_anno_bilancio
AND e.ord_tipo_code = 'I' and 
a.bil_id = b.bil_id and 
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id 
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select 
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select 
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from 
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo, 
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo , 
a.elem_desc2 v_descrizione_articolo 
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id        
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL                                
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, --b.accredito_tipo_id v_accredito_tipo_id, 
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante, 
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante, 
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente, 
       b.iban v_iban, 
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag, 
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select 
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT 
c.ord_id,d.soggetto_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data) 
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,a.soggetto_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data) 
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT 
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT 
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT 
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class26 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla26_classif_tipo_desc,      
b.classif_code cla26_classif_code, b.classif_desc cla26_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_26'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class27 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla27_classif_tipo_desc,
b.classif_code cla27_classif_code, b.classif_desc cla27_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_27'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class28 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla28_classif_tipo_desc,
b.classif_code cla28_classif_code, b.classif_desc cla28_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_28'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class29 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla29_classif_tipo_desc,
b.classif_code cla29_classif_code, b.classif_desc cla29_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_29'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class30 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla30_classif_tipo_desc,
b.classif_code cla30_classif_code, b.classif_desc cla30_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_30'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from 
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct 
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT 
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_ordinativo_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND  
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.data_cancellazione is null and 
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siac_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select 
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT 
a.ord_id
, a."boolean" v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagAllegatoCartaceo' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_cup as (
SELECT 
a.ord_id
, a.testo v_cup
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='cup' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT 
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='NOTE_ORDINATIVO' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
,
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale, 
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY 
a.ord_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale, 
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY 
a.ord_id),
firma as (select 
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))
, mif as (        
  select tb.mif_ord_ord_id, tb.mif_ord_class_codice_cge, tb.descr_siope from (
  with mif1 as (        
      select a.mif_ord_anno, a.mif_ord_numero, a.mif_ord_ord_id,
             a.mif_ord_class_codice_cge,
             b.flusso_elab_mif_id, b.flusso_elab_mif_data
      from mif_t_ordinativo_entrata a,  mif_t_flusso_elaborato b 
      where a.ente_proprietario_id=p_ente_proprietario_id  
      and  a.mif_ord_flusso_elab_mif_id=b.flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
     ) ,
      mifmax as (
      select max(b.flusso_elab_mif_id) flusso_elab_mif_id,
      a.mif_ord_anno,a.mif_ord_numero  
      from mif_t_ordinativo_entrata a, mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id   
      and b.flusso_elab_mif_id=a.mif_ord_flusso_elab_mif_id 
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
      group by a.mif_ord_anno,a.mif_ord_numero
    ),
      descsiope as (
      select replace(substring(a.classif_code from 2),'.', '') codice_siope,
         a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'PDC_V'
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   substring(a.classif_code from 1 for 1) = 'E'
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      union
      select a.classif_code codice_siope,
             a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'SIOPE_ENTRATA_I'
      and   a.classif_code not in ('XXXX','YYYY')
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      )
    select mif1.*, descsiope.descr_siope
    from mif1 
    left join descsiope on descsiope.codice_siope = mif1.mif_ord_class_codice_cge
    join mifmax on mif1.flusso_elab_mif_id=mifmax.flusso_elab_mif_id 
    and  mif1.mif_ord_anno=mifmax.mif_ord_anno 
    and  mif1.mif_ord_numero=mifmax.mif_ord_numero) as tb
    ) 
select ord_pag.*, 
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo, t_cup.v_cup,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,bollo.*,commis.*,contotes.*,dist.*,modpag.*,sogg.*,
tipoavviso.*,ricspesa.*,transue.*,
class26.*,class27.*,class28.*,class29.*,class30.*,
bilelem.*,
mif.mif_ord_class_codice_cge, mif.descr_siope
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class26
on ord_pag.ord_id=class26.ord_id
left join class27
on ord_pag.ord_id=class27.ord_id
left join class28
on ord_pag.ord_id=class28.ord_id
left join class29
on ord_pag.ord_id=class29.ord_id
left join class30
on ord_pag.ord_id=class30.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id  
left join pdc5
on ord_pag.ord_id=pdc5.ord_id  
left join pdc4
on ord_pag.ord_id=pdc4.ord_id  
left join pce5
on ord_pag.ord_id=pce5.ord_id  
left join pce4
on ord_pag.ord_id=pce4.ord_id  
left join attoamm
on ord_pag.ord_id=attoamm.ord_id  
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id  
left join t_cup
on ord_pag.ord_id=t_cup.ord_id  
left join t_noteordinativo
on 
ord_pag.ord_id=t_noteordinativo.ord_id  
left join impiniziale
on ord_pag.ord_id=impiniziale.ord_id  
left join impattuale
on ord_pag.ord_id=impattuale.ord_id  
left join firma
on ord_pag.ord_id=firma.ord_id
left join mif on ord_pag.ord_id = mif.mif_ord_ord_id
) as tb; 

 
    
     INSERT INTO siac.siac_dwh_subordinativo_incasso
    (
    ente_proprietario_id,
    ente_denominazione,
    bil_anno,
    cod_fase_operativa,
    desc_fase_operativa,
    anno_ord_inc,
    num_ord_inc,
    desc_ord_inc,
    cod_stato_ord_inc,
    desc_stato_ord_inc,
    castelletto_cassa_ord_inc,
    castelletto_competenza_ord_inc,
    castelletto_emessi_ord_inc,
    data_emissione,
    data_riduzione,
    data_spostamento,
    data_variazione,
    beneficiario_multiplo,
    num_subord_inc,
    desc_subord_inc,
    data_scadenza,
    importo_iniziale,
    importo_attuale,
    cod_onere,
    desc_onere,
    cod_tipo_onere,
    desc_tipo_onere,
    importo_carico_ente,
    importo_carico_soggetto,
    importo_imponibile,
    inizio_attivita,
    fine_attivita,
    cod_causale,
    desc_causale,
    cod_attivita_onere,
    desc_attivita_onere,
    anno_accertamento,
    num_accertamento,
    desc_accertamento,
    cod_subaccertamento,
    importo_quietanziato,
    data_inizio_val_stato_ordin,
    data_inizio_val_subordin,
    data_creazione_subordin,
    data_modifica_subordin,
      --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
    cod_gruppo_doc,
  	desc_gruppo_doc ,
    cod_famiglia_doc ,
    desc_famiglia_doc ,
    cod_tipo_doc ,
    desc_tipo_doc ,
    anno_doc ,
    num_doc ,
    num_subdoc ,
    cod_sogg_doc     
    )
    select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end, 
tb.ord_ts_code, tb.ord_ts_desc, tb.ord_ts_data_scadenza, tb.importo_iniziale, tb.importo_attuale,
tb.onere_code, tb.onere_desc,tb.onere_tipo_code, tb.onere_tipo_desc   ,
tb.importo_carico_ente, tb.importo_carico_soggetto, tb.importo_imponibile,
tb.attivita_inizio, tb.attivita_fine,tb.v_caus_code, tb.v_caus_desc,
tb.v_onere_att_code, tb.v_onere_att_desc,
tb.movgest_anno,tb.movgest_numero,tb.movgest_desc,tb.movgest_ts_code,
case when tb.ord_stato_code='Q' then tb.importo_attuale else null end importo_quietanziato,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_subordpg,
tb.data_creazione_subordpg,
tb.data_modifica_subordpg,
  --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
tb.doc_gruppo_tipo_code,
tb.doc_gruppo_tipo_desc,
tb.doc_fam_tipo_code,
tb.doc_fam_tipo_desc,
tb.doc_tipo_code,
tb.doc_tipo_desc,
tb.doc_anno,
tb.doc_numero,
tb.subdoc_numero,
tb.soggetto_code from (
--subord
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
       a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza, 
       a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data, 
       a.ord_beneficiariomult
           ,  a.ord_id, --q.elem_id,
       b.bil_id, a.comm_tipo_id,
       f.validita_inizio as data_inizio_val_stato_ordpg,
       a.validita_inizio as data_inizio_val_ordpg,
       a.data_creazione as data_creazione_ordpg,
       a.data_modifica as data_modifica_ordpg,
       a.codbollo_id,a.contotes_id,a.dist_id, l.ord_ts_id,
       l.ord_ts_code, l.ord_ts_desc, l.ord_ts_data_scadenza,
        l.validita_inizio as data_inizio_val_subordpg,
         l.data_creazione as data_creazione_subordpg,
         l.data_modifica as data_modifica_subordpg    
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i ,siac_t_ordinativo_ts l
where  d.ente_proprietario_id = p_ente_proprietario_id--p_ente_proprietario_id 
and 
c.anno = p_anno_bilancio--p_anno_bilancio
AND e.ord_tipo_code = 'I' and 
a.bil_id = b.bil_id and 
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id 
and l.ord_id=a.ord_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select 
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select 
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from 
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo, 
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo , 
a.elem_desc2 v_descrizione_articolo 
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id        
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL                                
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, b.accredito_tipo_id v_accredito_tipo_id, 
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante, 
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante, 
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente, 
       b.iban v_iban, 
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag, 
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select 
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT 
c.ord_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data) 
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data) 
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT 
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT 
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT 
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class26 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_1,
b.classif_code v_classificatore_generico_1_valore, b.classif_desc v_classificatore_generico_1_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_21'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class27 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_2,
b.classif_code v_classificatore_generico_2_valore, b.classif_desc v_classificatore_generico_2_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_22'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class28 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_3,
b.classif_code v_classificatore_generico_3_valore, b.classif_desc v_classificatore_generico_3_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_23'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class29 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_4,
b.classif_code v_classificatore_generico_4_valore, b.classif_desc v_classificatore_generico_4_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_24'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class30 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_5,
b.classif_code v_classificatore_generico_5_valore, b.classif_desc v_classificatore_generico_5_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_25'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),

cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from 
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct 
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT 
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_ordinativo_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND  
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.data_cancellazione is null and 
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select 
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT 
a.ord_id
, a.testo v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagAllegatoCartaceo' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT 
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='NOTE_ORDINATIVO' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL),
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale, 
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY 
b.ord_ts_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale, 
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY 
b.ord_ts_id),
firma as (select 
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)),
ons as (
with  onere as (
select a.ord_ts_id,
c.onere_code, c.onere_desc, d.onere_tipo_code, d.onere_tipo_desc,
b.importo_carico_ente, b.importo_carico_soggetto, b.importo_imponibile,
b.attivita_inizio, b.attivita_fine, b.caus_id, b.onere_att_id 
from  siac_r_doc_onere_ordinativo_ts  a,siac_r_doc_onere b,siac_d_onere c,siac_d_onere_tipo d
where
a.ente_proprietario_id=p_ente_proprietario_id and
 b.doc_onere_id=a.doc_onere_id
and c.onere_id=b.onere_id
and d.onere_tipo_id=c.onere_tipo_id
and a.data_cancellazione is null 
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
 AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
 AND p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data) 
),
 causale as (SELECT 
 dc.caus_id,
 dc.caus_code v_caus_code, dc.caus_desc v_caus_desc
  FROM siac.siac_d_causale dc
  WHERE  dc.ente_proprietario_id=p_ente_proprietario_id and  dc.data_cancellazione IS NULL)
 ,
 onatt as (
 -- Sezione per l'onere
  SELECT 
  doa.onere_att_id,
  doa.onere_att_code v_onere_att_code, doa.onere_att_desc v_onere_att_desc
  FROM siac_d_onere_attivita doa
  WHERE --doa.onere_att_id = v_onere_att_id
  doa.ente_proprietario_id=p_ente_proprietario_id 
    AND doa.data_cancellazione IS NULL)  
select * from onere left join causale
on onere.caus_id= causale.caus_id
left join onatt 
on onere.onere_att_id=onatt.onere_att_id)
,
movgest as (
select a.ord_ts_id, c.movgest_anno,c.movgest_numero,c.movgest_desc,
case when d.movgest_ts_tipo_code = 'T' then
     	null
     else
     	b.movgest_ts_code
end movgest_ts_code 
from  
siac_r_ordinativo_ts_movgest_ts a,siac_t_movgest_ts b,siac_t_movgest c,siac_d_movgest_ts_tipo d
where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.movgest_ts_id=b.movgest_ts_id
and c.movgest_id=b.movgest_id
and d.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and p_data BETWEEN a.validita_inizio and COALESCE (a.validita_fine,p_data)
)  ,
--04/07/2017: SIAC-5037 aggiunta gestione dei documenti
 elenco_doc as (
		select distinct d_doc_gruppo.doc_gruppo_tipo_code, d_doc_gruppo.doc_gruppo_tipo_desc,
    	d_doc_fam_tipo.doc_fam_tipo_code, d_doc_fam_tipo.doc_fam_tipo_desc,
        d_doc_tipo.doc_tipo_code, d_doc_tipo.doc_tipo_desc,    	        
        t_doc.doc_numero, t_doc.doc_anno, t_subdoc.subdoc_numero,
        t_soggetto.soggetto_code,
        r_subdoc_ord_ts.ord_ts_id    
    from siac_t_doc t_doc
    		LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	AND r_doc_sog.data_cancellazione IS NULL
                    AND p_data BETWEEN r_doc_sog.validita_inizio AND 
                    	COALESCE(r_doc_sog.validita_fine, p_data))
            LEFT JOIN siac_t_soggetto t_soggetto
            	ON (t_soggetto.soggetto_id=r_doc_sog.soggetto_id
                	AND t_soggetto.data_cancellazione IS NULL),
		siac_t_subdoc t_subdoc, 
    	siac_d_doc_tipo d_doc_tipo
        	LEFT JOIN siac_d_doc_gruppo d_doc_gruppo
            	ON (d_doc_gruppo.doc_gruppo_tipo_id=d_doc_tipo.doc_gruppo_tipo_id
                	AND d_doc_gruppo.data_cancellazione IS NULL),
    	siac_d_doc_fam_tipo d_doc_fam_tipo,
        siac_r_subdoc_ordinativo_ts r_subdoc_ord_ts
    where t_doc.doc_id=t_subdoc.doc_id
    	and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id    
        and d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id           
        and r_subdoc_ord_ts.subdoc_id=t_subdoc.subdoc_id
    	and t_doc.ente_proprietario_id=p_ente_proprietario_id
    	and t_doc.data_cancellazione IS NULL
   		and t_subdoc.data_cancellazione IS NULL
        AND d_doc_fam_tipo.data_cancellazione IS NULL
        and d_doc_tipo.data_cancellazione IS NULL        
        and r_subdoc_ord_ts.data_cancellazione IS NULL
        and r_subdoc_ord_ts.validita_fine IS NULL
        AND p_data BETWEEN r_subdoc_ord_ts.validita_inizio AND 
                    	COALESCE(r_subdoc_ord_ts.validita_fine, p_data)) 
select ord_pag.*, 
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,
ons.*,
movgest.ord_ts_id, movgest.movgest_anno,movgest.movgest_numero,movgest.movgest_desc,movgest.movgest_ts_code,
elenco_doc.*
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class26
on ord_pag.ord_id=class26.ord_id
left join class27
on ord_pag.ord_id=class27.ord_id
left join class28
on ord_pag.ord_id=class28.ord_id
left join class29
on ord_pag.ord_id=class29.ord_id
left join class30
on ord_pag.ord_id=class30.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id  
left join pdc5
on ord_pag.ord_id=pdc5.ord_id  
left join pdc4
on ord_pag.ord_id=pdc4.ord_id  
left join pce5
on ord_pag.ord_id=pce5.ord_id  
left join pce4
on ord_pag.ord_id=pce4.ord_id  
left join attoamm
on ord_pag.ord_id=attoamm.ord_id  
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id  
left join t_noteordinativo
on 
ord_pag.ord_id=t_noteordinativo.ord_id  
left join impiniziale
on ord_pag.ord_ts_id=impiniziale.ord_ts_id  
left join impattuale
on ord_pag.ord_ts_id=impattuale.ord_ts_id  
left join firma
on ord_pag.ord_id=firma.ord_id 
left join ons
on ord_pag.ord_ts_id=ons.ord_ts_id     
left join movgest
on ord_pag.ord_ts_id=movgest.ord_ts_id 
--04/07/2017: SIAC-5037 aggiunta gestione dei documenti
left join elenco_doc
on elenco_doc.ord_ts_id=ord_pag.ord_ts_id  
) as tb;
  

esito:= 'Fine funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-5037 FINE


-- SIAC-5039 INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_soggetto (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar 
) AS
$body$
DECLARE
rec_soggetto_id record;
rec_indirizzo record;
rec_recapito record;
rec_attr record;
-- Variabili per campi estratti dal cursore rec_soggetto_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_soggetto_code VARCHAR := null;
v_soggetto_tipo_desc VARCHAR := null;
v_soggetto_stato_desc VARCHAR := null;
v_ragione_sociale VARCHAR := null;
v_partita_iva VARCHAR := null;
v_codice_fiscale VARCHAR := null;
v_codice_fiscale_estero VARCHAR := null;
v_nome VARCHAR := null;
v_cognome VARCHAR := null;
v_sesso VARCHAR := null;
v_nascita_data TIMESTAMP := null;
v_comune_nascita VARCHAR := null;
v_codice_istat_comune_nascita VARCHAR := null;
v_codice_catastale_comune_nascita VARCHAR := null;
v_provincia_nascita VARCHAR := null;
v_nazione_nascita VARCHAR := null;
v_indirizzo_principale VARCHAR := null;
v_cap_indirizzo_principale VARCHAR := null;
v_comune_indirizzo_principale VARCHAR := null;
v_codice_istat_comune_indirizzo_principale VARCHAR := null;
v_codice_catastale_comune_indirizzo_principale VARCHAR := null;
v_provincia_indirizzo_principale VARCHAR := null;
v_nazione_indirizzo_principale VARCHAR := null;
v_indirizzo_domicilio_fiscale VARCHAR := null;
v_cap_indirizzo_domicilio_fiscale VARCHAR := null;
v_comune_domicilio_fiscale VARCHAR := null;
v_codice_istat_comune_indirizzo_domicilio_fiscale VARCHAR := null;
v_codice_catastale_comune_indirizzo_domicilio_fiscale VARCHAR := null;
v_provincia_domicilio_fiscale VARCHAR := null;
v_nazione_domicilio_fiscale VARCHAR := null;
v_indirizzo_residenza VARCHAR := null;
v_cap_indirizzo_residenza VARCHAR := null;
v_comune_residenza VARCHAR := null;
v_codice_istat_comune_indirizzo_residenza VARCHAR := null;
v_codice_catastale_comune_indirizzo_residenza VARCHAR := null;
v_provincia_residenza VARCHAR := null;
v_nazione_residenza VARCHAR := null;
v_indirizzo_sede_legale VARCHAR := null;
v_cap_indirizzo_sede_legale VARCHAR := null;
v_comune_sede_legale VARCHAR := null;
v_codice_istat_comune_indirizzo_sede_legale VARCHAR := null;
v_codice_catastale_comune_indirizzo_sede_legale VARCHAR := null;
v_provincia_sede_legale VARCHAR := null;
v_nazione_sede_legale VARCHAR := null;
v_indirizzo_sede_amministrativa VARCHAR := null;
v_cap_indirizzo_sede_amministrativa VARCHAR := null;
v_comune_sede_amministrativa VARCHAR := null;
v_codice_istat_comune_indirizzo_sede_amministrativa VARCHAR := null;
v_codice_catastale_comune_indirizzo_sede_amministrativa VARCHAR := null;
v_provincia_sede_amministrativa VARCHAR := null;
v_nazione_sede_amministrativa VARCHAR := null;
v_indirizzo_sede_operativa VARCHAR := null;
v_cap_indirizzo_sede_operativa VARCHAR := null;
v_comune_sede_operativa VARCHAR := null;
v_codice_istat_comune_indirizzo_sede_operativa VARCHAR := null;
v_codice_catastale_comune_indirizzo_sede_operativa VARCHAR := null;
v_provincia_sede_operativa VARCHAR := null;
v_nazione_sede_operativa VARCHAR := null;
v_telefono VARCHAR := null;
v_cellulare VARCHAR := null;
v_fax VARCHAR := null;
v_email VARCHAR := null;
v_pec VARCHAR := null;
v_sito_web VARCHAR := null;
v_soggetto_recapito VARCHAR := null;
v_avviso VARCHAR := null;
v_NoteSoggetto VARCHAR := null;
v_Matricola VARCHAR := null;
v_soggetto_classe_desc VARCHAR := null;
v_sede_secondaria VARCHAR := null;
v_codice_soggetto_principale VARCHAR := null;
v_soggetto_principale VARCHAR := null;

v_comune_desc VARCHAR := null;
v_comune_istat_code VARCHAR := null;
v_comune_belfiore_catastale_code VARCHAR := null;
v_provincia_desc VARCHAR := null;
v_nazione_desc VARCHAR := null;
v_indirizzo_tipo_code VARCHAR := null;
v_principale VARCHAR := null;
v_zip_code VARCHAR := null;
v_indirizzo VARCHAR := null;
v_via_tipo_desc VARCHAR := null;
v_toponimo VARCHAR := null;
v_numero_civico VARCHAR := null;
v_frazione VARCHAR := null;
v_interno VARCHAR := null;
v_recapito_desc VARCHAR := null;
v_recapito_modo_code VARCHAR := null;
v_flag_attributo VARCHAR := null;

v_comune_id_nascita INTEGER := null;
v_soggetto_id INTEGER := null;
v_comune_id INTEGER := null;
v_comune_id_gen INTEGER := null;
v_soggetto_id_principale INTEGER := null;
v_via_tipo_id INTEGER := null;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

esito:= 'Inizio funzione carico soggetto (FNC_SIAC_DWH_SOGGETTO) - '||clock_timestamp();
RETURN NEXT;


esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_soggetto
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;
-- Ciclo per estrarre i dati relativi ad un soggetto_id
FOR rec_soggetto_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, ts.soggetto_code, dst.soggetto_tipo_desc,
       dss.soggetto_stato_desc, tpg.ragione_sociale, ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
       tpf.nome, tpf.cognome, tpf.sesso, tpf.nascita_data, dsc.soggetto_classe_desc,
       tpf.comune_id_nascita, ts.soggetto_id,
       -- 03/07/2017: aggiunto il campo soggetto_desc
       ts.soggetto_desc
FROM siac.siac_t_soggetto ts
INNER JOIN siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = ts.ente_proprietario_id
                                             AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
                                             AND tep.data_cancellazione IS NULL
INNER JOIN siac.siac_d_ambito da ON da.ambito_id = ts.ambito_id
                                             AND p_data BETWEEN da.validita_inizio AND COALESCE(da.validita_fine, p_data)
                                             AND da.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                        AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                        AND rst.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id= rst.soggetto_tipo_id
                                        AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                        AND dst.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_stato rss ON rss.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
                                         AND rss.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = rss.soggetto_stato_id
                                         AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                         AND dss.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                            AND tpg.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                         AND tpf.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_classe rsc ON rsc.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN rsc.validita_inizio AND COALESCE(rsc.validita_fine, p_data)
                                         AND rsc.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_classe dsc ON dsc.soggetto_classe_id = rsc.soggetto_classe_id
                                         AND p_data BETWEEN dsc.validita_inizio AND COALESCE(dsc.validita_fine, p_data)
                                         AND dsc.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND   da.ambito_code = 'AMBITO_FIN'
AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
AND ts.data_cancellazione IS NULL

LOOP

v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_soggetto_code := null;
v_soggetto_tipo_desc := null;
v_soggetto_stato_desc := null;
v_ragione_sociale := null;
v_partita_iva := null;
v_codice_fiscale := null;
v_codice_fiscale_estero := null;
v_nome := null;
v_cognome := null;
v_sesso := null;
v_nascita_data := null;
v_indirizzo_principale := null;
v_cap_indirizzo_principale := null;
v_comune_indirizzo_principale := null;
v_codice_istat_comune_indirizzo_principale := null;
v_codice_catastale_comune_indirizzo_principale := null;
v_provincia_indirizzo_principale := null;
v_nazione_indirizzo_principale := null;
v_indirizzo_domicilio_fiscale := null;
v_cap_indirizzo_domicilio_fiscale := null;
v_comune_domicilio_fiscale := null;
v_codice_istat_comune_indirizzo_domicilio_fiscale := null;
v_codice_catastale_comune_indirizzo_domicilio_fiscale := null;
v_provincia_domicilio_fiscale := null;
v_nazione_domicilio_fiscale := null;
v_indirizzo_residenza := null;
v_cap_indirizzo_residenza := null;
v_comune_residenza := null;
v_codice_istat_comune_indirizzo_residenza := null;
v_codice_catastale_comune_indirizzo_residenza := null;
v_provincia_residenza := null;
v_nazione_residenza := null;
v_indirizzo_sede_legale := null;
v_cap_indirizzo_sede_legale := null;
v_comune_sede_legale := null;
v_codice_istat_comune_indirizzo_sede_legale := null;
v_codice_catastale_comune_indirizzo_sede_legale := null;
v_provincia_sede_legale := null;
v_nazione_sede_legale := null;
v_indirizzo_sede_amministrativa := null;
v_cap_indirizzo_sede_amministrativa := null;
v_comune_sede_amministrativa := null;
v_codice_istat_comune_indirizzo_sede_amministrativa := null;
v_codice_catastale_comune_indirizzo_sede_amministrativa := null;
v_provincia_sede_amministrativa := null;
v_nazione_sede_amministrativa := null;
v_indirizzo_sede_operativa := null;
v_cap_indirizzo_sede_operativa := null;
v_comune_sede_operativa := null;
v_codice_istat_comune_indirizzo_sede_operativa := null;
v_codice_catastale_comune_indirizzo_sede_operativa := null;
v_provincia_sede_operativa := null;
v_nazione_sede_operativa := null;
v_telefono := null;
v_cellulare := null;
v_fax := null;
v_email := null;
v_pec := null;
v_sito_web := null;
v_soggetto_recapito := null;
v_avviso := null;
v_soggetto_classe_desc := null;
v_sede_secondaria := null;
v_codice_soggetto_principale := null;
v_soggetto_principale := null;

v_comune_id_nascita := null;
v_soggetto_id := null;
v_soggetto_id_principale := null;

v_flag_attributo := null;

v_ente_proprietario_id := rec_soggetto_id.ente_proprietario_id;
v_ente_denominazione := rec_soggetto_id.ente_denominazione;
v_soggetto_code := rec_soggetto_id.soggetto_code;
v_soggetto_tipo_desc := rec_soggetto_id.soggetto_tipo_desc;
v_soggetto_stato_desc := rec_soggetto_id.soggetto_stato_desc;
v_ragione_sociale := rec_soggetto_id.ragione_sociale;
v_partita_iva := rec_soggetto_id.partita_iva;
v_codice_fiscale := rec_soggetto_id.codice_fiscale;
v_codice_fiscale_estero := rec_soggetto_id.codice_fiscale_estero;
v_nome := rec_soggetto_id.nome;
v_cognome := rec_soggetto_id.cognome;
v_sesso := rec_soggetto_id.sesso;
v_nascita_data := rec_soggetto_id.nascita_data;
v_soggetto_classe_desc := rec_soggetto_id.soggetto_classe_desc;

v_comune_id_nascita := rec_soggetto_id.comune_id_nascita;
v_soggetto_id := rec_soggetto_id.soggetto_id;

esito:= '  Inizio ciclo soggetto - soggetto_id ('||v_soggetto_id||') - '||clock_timestamp();
return next;
-- Ciclo pre estrarre l'indirizzo del soggetto
FOR rec_indirizzo IN
SELECT tis.comune_id, dit.indirizzo_tipo_code, tis.principale, tis.zip_code,
       tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
FROM siac.siac_t_indirizzo_soggetto tis
INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                    AND p_data BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, p_data)
                                                    AND rist.data_cancellazione IS NULL
INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                          AND p_data BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, p_data)
                                          AND dit.data_cancellazione IS NULL
WHERE tis.soggetto_id = v_soggetto_id
AND p_data BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, p_data)
AND tis.data_cancellazione IS NULL
UNION
SELECT NULL, 'NASCITA', NULL, NULL, NULL, NULL, NULL, NULL, NULL

LOOP

v_comune_id := null;
v_comune_id_gen := null;
v_indirizzo_tipo_code := null;

v_principale := null;
v_zip_code := null;
v_comune_desc := null;
v_comune_istat_code := null;
v_comune_belfiore_catastale_code := null;
v_provincia_desc := null;
v_nazione_desc := null;
v_indirizzo := null;
v_via_tipo_desc := null;
v_toponimo := null;
v_numero_civico := null;
v_frazione := null;
v_interno := null;
v_via_tipo_id := null;

v_comune_id := rec_indirizzo.comune_id;
v_indirizzo_tipo_code := rec_indirizzo.indirizzo_tipo_code;
v_principale := rec_indirizzo.principale;
v_zip_code := rec_indirizzo.zip_code;

v_toponimo := rec_indirizzo.toponimo;
v_numero_civico := rec_indirizzo.numero_civico;
v_frazione := rec_indirizzo.frazione;
v_interno := rec_indirizzo.interno;
v_via_tipo_id := rec_indirizzo.via_tipo_id;
-- Estrazione tipo via
SELECT dvt.via_tipo_desc
INTO v_via_tipo_desc
FROM siac.siac_d_via_tipo dvt
WHERE dvt.via_tipo_id = v_via_tipo_id
AND p_data BETWEEN dvt.validita_inizio AND COALESCE(dvt.validita_fine, p_data)
AND dvt.data_cancellazione IS NULL;

IF v_via_tipo_desc IS NOT NULL THEN
   v_indirizzo := v_via_tipo_desc;
END IF;

IF v_toponimo IS NOT NULL THEN
   v_indirizzo := v_indirizzo||' '||v_toponimo;
END IF;

IF v_numero_civico IS NOT NULL THEN
   v_indirizzo := v_indirizzo||' '||v_numero_civico;
END IF;

IF v_frazione IS NOT NULL THEN
   v_indirizzo := v_indirizzo||', frazione '||v_frazione;
END IF;

IF v_interno IS NOT NULL THEN
   v_indirizzo := v_indirizzo||', interno '||v_interno;
END IF;

v_indirizzo := UPPER(v_indirizzo);

IF v_indirizzo_tipo_code = 'NASCITA' THEN
   v_comune_id_gen := v_comune_id_nascita;
ELSE
   v_comune_id_gen := v_comune_id;
END IF;
-- Estrazione dati comune
SELECT tc.comune_desc, tc.comune_istat_code, tc.comune_belfiore_catastale_code, tp.provincia_desc, tn.nazione_desc
INTO  v_comune_desc, v_comune_istat_code, v_comune_belfiore_catastale_code, v_provincia_desc, v_nazione_desc
FROM siac.siac_t_comune tc
LEFT JOIN siac.siac_r_comune_provincia rcp ON rcp.comune_id = tc.comune_id
                                           AND p_data BETWEEN rcp.validita_inizio AND COALESCE(rcp.validita_fine, p_data)
                                           AND rcp.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_provincia tp ON tp.provincia_id = rcp.provincia_id
                                   AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
                                   AND tp.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_nazione tn ON tn.nazione_id = tc.nazione_id
                                 AND p_data BETWEEN tn.validita_inizio AND COALESCE(tn.validita_fine, p_data)
                                 AND tn.data_cancellazione IS NULL
WHERE tc.comune_id = v_comune_id_gen
AND p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
AND tc.data_cancellazione IS NULL;

IF v_principale = 'S' THEN
   v_indirizzo_principale := v_indirizzo;
   v_cap_indirizzo_principale := v_zip_code;
   v_comune_indirizzo_principale := v_comune_desc;
   v_codice_istat_comune_indirizzo_principale := v_comune_istat_code;
   v_codice_catastale_comune_indirizzo_principale := v_comune_belfiore_catastale_code;
   v_provincia_indirizzo_principale := v_provincia_desc;
   v_nazione_indirizzo_principale := v_nazione_desc;
END IF;

IF  v_indirizzo_tipo_code = 'NASCITA' THEN
    v_comune_nascita := v_comune_desc;
    v_codice_istat_comune_nascita := v_comune_istat_code;
    v_codice_catastale_comune_nascita := v_comune_belfiore_catastale_code;
    v_provincia_nascita := v_provincia_desc;
    v_nazione_nascita := v_nazione_desc;
ELSIF  v_indirizzo_tipo_code = 'DOMICILIO' THEN
	v_indirizzo_domicilio_fiscale := v_indirizzo;
    v_cap_indirizzo_domicilio_fiscale := v_zip_code;
    v_comune_domicilio_fiscale := v_comune_desc;
    v_codice_istat_comune_indirizzo_domicilio_fiscale := v_comune_istat_code;
    v_codice_catastale_comune_indirizzo_domicilio_fiscale := v_comune_belfiore_catastale_code;
    v_provincia_domicilio_fiscale := v_provincia_desc;
    v_nazione_domicilio_fiscale := v_nazione_desc;
ELSIF  v_indirizzo_tipo_code = 'RESIDENZA' THEN
	v_indirizzo_residenza := v_indirizzo;
    v_cap_indirizzo_residenza := v_zip_code;
    v_comune_residenza := v_comune_desc;
    v_codice_istat_comune_indirizzo_residenza := v_comune_istat_code;
    v_codice_catastale_comune_indirizzo_residenza := v_comune_belfiore_catastale_code;
    v_provincia_residenza := v_provincia_desc;
    v_nazione_residenza := v_nazione_desc;
ELSIF  v_indirizzo_tipo_code = 'SEDE_LEGALE' THEN
	v_indirizzo_sede_legale := v_indirizzo;
    v_cap_indirizzo_sede_legale := v_zip_code;
    v_comune_sede_legale := v_comune_desc;
    v_codice_istat_comune_indirizzo_sede_legale := v_comune_istat_code;
    v_codice_catastale_comune_indirizzo_sede_legale := v_comune_belfiore_catastale_code;
    v_provincia_sede_legale := v_provincia_desc;
    v_nazione_sede_legale := v_nazione_desc;
ELSIF  v_indirizzo_tipo_code = 'SEDE_AMM' THEN
	v_indirizzo_sede_amministrativa := v_indirizzo;
    v_cap_indirizzo_sede_amministrativa := v_zip_code;
    v_comune_sede_amministrativa := v_comune_desc;
    v_codice_istat_comune_indirizzo_sede_amministrativa := v_comune_istat_code;
    v_codice_catastale_comune_indirizzo_sede_amministrativa := v_comune_belfiore_catastale_code;
    v_provincia_sede_amministrativa := v_provincia_desc;
    v_nazione_sede_amministrativa := v_nazione_desc;
ELSIF  v_indirizzo_tipo_code = 'SEDE_OPERATIVA' THEN
	v_indirizzo_sede_operativa := v_indirizzo;
    v_cap_indirizzo_sede_operativa := v_zip_code;
    v_comune_sede_operativa := v_comune_desc;
    v_codice_istat_comune_indirizzo_sede_operativa := v_comune_istat_code;
    v_codice_catastale_comune_indirizzo_sede_operativa := v_comune_belfiore_catastale_code;
    v_provincia_sede_operativa := v_provincia_desc;
    v_nazione_sede_operativa := v_nazione_desc;
END IF;

END LOOP;
-- Ciclo per estrarre il recapito di un soggetto
FOR rec_recapito IN
SELECT trs.recapito_desc, drm.recapito_modo_code, trs.avviso
FROM siac.siac_t_recapito_soggetto trs
INNER JOIN siac.siac_d_recapito_modo drm ON drm.recapito_modo_id = trs.recapito_modo_id
                                         AND p_data BETWEEN drm.validita_inizio AND COALESCE(drm.validita_fine, p_data)
                                         AND drm.data_cancellazione IS NULL
WHERE trs.soggetto_id = v_soggetto_id
AND p_data BETWEEN trs.validita_inizio AND COALESCE(trs.validita_fine, p_data)
AND trs.data_cancellazione IS NULL

LOOP
  v_recapito_desc := null;
  v_recapito_modo_code := null;

  v_recapito_desc := rec_recapito.recapito_desc;
  v_recapito_modo_code := rec_recapito.recapito_modo_code;

  IF rec_recapito.avviso = 'S' THEN
     v_avviso := rec_recapito.avviso;
  END IF;

  IF v_recapito_modo_code = 'telefono' THEN
     v_telefono := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'cellulare' THEN
     v_cellulare := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'fax' THEN
     v_fax := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'email' THEN
     v_email := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'PEC' THEN
     v_pec := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'sito' THEN
     v_sito_web := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'soggetto' THEN
     v_soggetto_recapito := v_recapito_desc;
  END IF;

END LOOP;
-- Sezione per gli attributi
FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rsa.tabella_id, rsa.percentuale, rsa."boolean" true_false, rsa.numerico, rsa.testo
FROM   siac.siac_r_soggetto_attr rsa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rsa.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rsa.soggetto_id = v_soggetto_id
AND    rsa.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rsa.validita_inizio AND COALESCE(rsa.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'NoteSoggetto' THEN
     v_NoteSoggetto := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'Matricola' THEN
     v_Matricola := v_flag_attributo;
  END IF;

END LOOP;
-- Sezione per estrarre la sede secondaria
SELECT rsr.soggetto_id_da
INTO v_soggetto_id_principale
FROM siac.siac_r_soggetto_relaz rsr, siac.siac_d_relaz_tipo drt
WHERE rsr.relaz_tipo_id = drt.relaz_tipo_id
AND   drt.relaz_tipo_code  = 'SEDE_SECONDARIA'
AND   rsr.soggetto_id_a = v_soggetto_id
AND   p_data BETWEEN rsr.validita_inizio AND COALESCE(rsr.validita_fine, p_data)
AND   p_data BETWEEN drt.validita_inizio AND COALESCE(drt.validita_fine, p_data)
AND   rsr.data_cancellazione IS NULL
AND   drt.data_cancellazione IS NULL;

IF  v_soggetto_id_principale IS NOT NULL THEN
    v_sede_secondaria := 'S';
    
    -- 03/07/2017: Modifiche per SIAC-5039.
    --   Se esiste la sede secondaria, la ragione sociale viene
    --   assegnata con il contenuto della descrizione del soggetto.    
	if v_ragione_sociale IS NULL THEN
    	v_ragione_sociale:=rec_soggetto_id.soggetto_desc;
    end if; 
        
    SELECT ts.soggetto_code,
           CASE
              WHEN dst.soggetto_tipo_code in ('PF', 'PFI') THEN
                   tpf.nome||' '||tpf.cognome
              ELSE
                   tpg.ragione_sociale
           END  soggetto_principale
    INTO v_codice_soggetto_principale, v_soggetto_principale
    FROM siac.siac_t_soggetto ts
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id= rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE ts.soggetto_id = v_soggetto_id_principale
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

END IF;


  INSERT INTO siac.siac_dwh_soggetto
  ( ente_proprietario_id,
    ente_denominazione,
    soggetto_id,
    cod_soggetto,
    tipo_soggetto,
    stato_soggetto,
    ragione_sociale,
    p_iva,
    cf,
    cf_estero,
    nome,
    cognome,
    sesso,
    data_nascita,
    comune_nascita,
    codistat_comune_nascita,
    codcatastale_comune_nascita,
    provincia_nascita,
    nazione_nascita,
    indirizzo_principale,
    cap_indirizzo_principale,
    comune_indirizzo_principale,
    codistat_comune_ind_princ,
    codcatastale_comune_ind_princ,
    provincia_indirizzo_principale,
    nazione_indirizzo_principale,
    indirizzo_domicilio_fiscale,
    cap_domicilio_fiscale,
    comune_domicilio_fiscale,
    codistat_comune_domfiscale,
    codcatastale_comune_domfiscale,
    provincia_domicilio_fiscale,
    nazione_domicilio_fiscale,
    indirizzo_residenza,
    cap_residenza,
    comune_residenza,
    codistat_comune_residenza,
    codcatastale_comune_residenza,
    provincia_residenza,
    nazione_residenza,
    indirizzo_sede_legale,
    cap_sede_legale,
    comune_sede_legale,
    codistat_comune_sedelegale,
    codcatastale_comune_sedelegale,
    provincia_sede_legale,
    nazione_sede_legale,
    indirizzo_sede_amministrativa ,
    cap_sede_amministrativa,
    comune_sede_amministrativa,
    codistat_comune_sede_amm,
    codcatastale_comune_sede_amm,
    provincia_sede_amministrativa,
    nazione_sede_amministrativa,
    indirizzo_sede_operativa,
    cap_sede_operativa,
    comune_sede_operativa,
    codistat_comune_sede_oper ,
    codcatastale_comune_sede_oper,
    provincia_sede_operativa,
    nazione_sede_operativa,
    telefono,
    cellulare,
    fax,
    email,
    pec,
    sito_web,
    soggetto_recapito,
    avviso,
    note,
    matricola_hrspi,
    classe_soggetto,
    sede_secondaria,
    soggetto_id_principale,
    codice_soggetto_principale,
    soggetto_principale
  )
  VALUES (v_ente_proprietario_id,
          v_ente_denominazione,
          v_soggetto_id,
          v_soggetto_code,
          v_soggetto_tipo_desc,
          v_soggetto_stato_desc,
          v_ragione_sociale,
          v_partita_iva,
          v_codice_fiscale,
          v_codice_fiscale_estero,
          v_nome,
          v_cognome,
          v_sesso,
          v_nascita_data,
          v_comune_nascita,
          v_codice_istat_comune_nascita,
          v_codice_catastale_comune_nascita,
          v_provincia_nascita,
          v_nazione_nascita,
          v_indirizzo_principale,
          v_cap_indirizzo_principale,
          v_comune_indirizzo_principale,
          v_codice_istat_comune_indirizzo_principale,
          v_codice_catastale_comune_indirizzo_principale,
          v_provincia_indirizzo_principale,
          v_nazione_indirizzo_principale,
          v_indirizzo_domicilio_fiscale,
          v_cap_indirizzo_domicilio_fiscale,
          v_comune_domicilio_fiscale,
          v_codice_istat_comune_indirizzo_domicilio_fiscale ,
          v_codice_catastale_comune_indirizzo_domicilio_fiscale,
          v_provincia_domicilio_fiscale,
          v_nazione_domicilio_fiscale,
          v_indirizzo_residenza,
          v_cap_indirizzo_residenza,
          v_comune_residenza,
          v_codice_istat_comune_indirizzo_residenza,
          v_codice_catastale_comune_indirizzo_residenza,
          v_provincia_residenza,
          v_nazione_residenza,
          v_indirizzo_sede_legale,
          v_cap_indirizzo_sede_legale,
          v_comune_sede_legale,
          v_codice_istat_comune_indirizzo_sede_legale,
          v_codice_catastale_comune_indirizzo_sede_legale,
          v_provincia_sede_legale,
          v_nazione_sede_legale,
          v_indirizzo_sede_amministrativa,
          v_cap_indirizzo_sede_amministrativa,
          v_comune_sede_amministrativa,
          v_codice_istat_comune_indirizzo_sede_amministrativa,
          v_codice_catastale_comune_indirizzo_sede_amministrativa,
          v_provincia_sede_amministrativa,
          v_nazione_sede_amministrativa,
          v_indirizzo_sede_operativa,
          v_cap_indirizzo_sede_operativa,
          v_comune_sede_operativa,
          v_codice_istat_comune_indirizzo_sede_operativa,
          v_codice_catastale_comune_indirizzo_sede_operativa,
          v_provincia_sede_operativa,
          v_nazione_sede_operativa,
          v_telefono,
          v_cellulare,
          v_fax,
          v_email,
          v_pec,
          v_sito_web,
          v_soggetto_recapito,
          v_avviso,
          v_NoteSoggetto,
          v_Matricola,
          v_soggetto_classe_desc,
          v_sede_secondaria,
          v_soggetto_id_principale,
          v_codice_soggetto_principale,
          v_soggetto_principale
         );

esito:= '  Fine ciclo soggetto - soggetto_id ('||v_soggetto_id||') - '||clock_timestamp();
return next;
END LOOP;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico soggetto (FNC_SIAC_DWH_SOGGETTO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-5039 FINE


-- SIAC-5036 Sofia INIZIO

alter table siac_dwh_ordinativo_pagamento add tipo_cessione varchar(50);
alter table siac_dwh_ordinativo_pagamento add cod_cessione varchar(100);
alter table siac_dwh_ordinativo_pagamento add desc_cessione varchar(200);

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.tipo_cessione
IS 'tipo_cessione incasso CSI/CSC';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.cod_cessione
IS 'codice cessione di tipo tipo_cessione';

COMMENT ON COLUMN siac.siac_dwh_ordinativo_pagamento.desc_cessione
IS 'descrizione cessione di tipo tipo_cessione';

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_ordinativo_pagamento (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

esito:= 'Inizio funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_ordinativo_pagamento
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

esito:= '  Inizio eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_subordinativo_pagamento
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;

INSERT INTO siac.siac_dwh_ordinativo_pagamento
  (
  ente_proprietario_id,
  ente_denominazione,
  bil_anno,
  cod_fase_operativa,
  desc_fase_operativa,
  anno_ord_pag,
  num_ord_pag,
  desc_ord_pag,
  cod_stato_ord_pag,
  desc_stato_ord_pag,
  castelletto_cassa_ord_pag,
  castelletto_competenza_ord_pag,
  castelletto_emessi_ord_pag,
  data_emissione,
  data_riduzione,
  data_spostamento,
  data_variazione,
  beneficiario_multiplo,
  cod_bollo,
  desc_cod_bollo,
  cod_tipo_commissione,
  desc_tipo_commissione,
  cod_conto_tesoreria,
  decrizione_conto_tesoreria,
  cod_distinta,
  desc_distinta,
  soggetto_id,
  cod_soggetto,
  desc_soggetto,
  cf_soggetto,
  cf_estero_soggetto,
  p_iva_soggetto,
  soggetto_id_mod_pag,
  cod_soggetto_mod_pag,
  desc_soggetto_mod_pag,
  cf_soggetto_mod_pag,
  cf_estero_soggetto_mod_pag,
  p_iva_soggetto_mod_pag,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  tipo_cessione, -- 04.07.2017 Sofia SIAC-5036
  cod_cessione,  -- 04.07.2017 Sofia SIAC-5036
  desc_cessione, -- 04.07.2017 Sofia SIAC-5036
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  desc_stato_atto_amministrativo,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  note_atto_amministrativo,
  cod_tipo_avviso,
  desc_tipo_avviso,
  cod_spesa_ricorrente,
  desc_spesa_ricorrente,
  cod_transazione_spesa_ue,
  desc_transazione_spesa_ue,
  cod_pdc_finanziario_i,
  desc_pdc_finanziario_i,
  cod_pdc_finanziario_ii,
  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,
  desc_pdc_finanziario_iii,
  cod_pdc_finanziario_iv,
  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,
  desc_pdc_finanziario_v,
  cod_pdc_economico_i,
  desc_pdc_economico_i,
  cod_pdc_economico_ii,
  desc_pdc_economico_ii,
  cod_pdc_economico_iii,
  desc_pdc_economico_iii,
  cod_pdc_economico_iv,
  desc_pdc_economico_iv,
  cod_pdc_economico_v,
  desc_pdc_economico_v,
  cod_cofog_divisione,
  desc_cofog_divisione,
  cod_cofog_gruppo,
  desc_cofog_gruppo,
  classificatore_1,
  classificatore_1_valore,
  classificatore_1_desc_valore,
  classificatore_2,
  classificatore_2_valore,
  classificatore_2_desc_valore,
  classificatore_3,
  classificatore_3_valore,
  classificatore_3_desc_valore,
  classificatore_4,
  classificatore_4_valore,
  classificatore_4_desc_valore,
  classificatore_5,
  classificatore_5_valore,
  classificatore_5_desc_valore,
  allegato_cartaceo,
  --cup,
  note,
  cod_capitolo,
  cod_articolo,
  cod_ueb,
  desc_capitolo,
  desc_articolo,
  importo_iniziale,
  importo_attuale,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  data_firma,
  firma,
  data_inizio_val_stato_ordpg,
  data_inizio_val_ordpg,
  data_creazione_ordpg,
  data_modifica_ordpg,
  data_trasmissione,
  cod_siope,
  desc_siope
  )
select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end,
tb.codbollo_code, tb.codbollo_desc,
tb.comm_tipo_code, tb.comm_tipo_desc,
tb.contotes_code, tb.contotes_desc,
tb.dist_code, tb.dist_desc,
tb.soggetto_id,tb.soggetto_code, tb.soggetto_desc, tb.codice_fiscale, tb.codice_fiscale_estero, tb.partita_iva,
tb.v_soggetto_id_modpag,  tb.v_codice_soggetto_modpag, tb.v_descrizione_soggetto_modpag,
tb.v_codice_fiscale_soggetto_modpag,tb. v_codice_fiscale_estero_soggetto_modpag,tb.v_partita_iva_soggetto_modpag,
tb.v_codice_tipo_accredito, tb.v_descrizione_tipo_accredito, tb.modpag_id,
tb.v_quietanziante, tb.v_data_nascita_quietanziante,tb.v_luogo_nascita_quietanziante,tb.v_stato_nascita_quietanziante,
tb.v_bic, tb.v_contocorrente, tb.v_intestazione_contocorrente, tb.v_iban,
tb.v_note_modalita_pagamento, tb.v_data_scadenza_modalita_pagamento,
tb.tipo_cessione, tb.cod_cessione, tb.desc_cessione, -- 04.07.2017 Sofia SIAC-5036
tb.attoamm_tipo_code, tb.attoamm_tipo_desc,tb.attoamm_stato_desc,
tb.attoamm_anno, tb.attoamm_numero, tb.attoamm_oggetto, tb.attoamm_note,
tb.v_codice_tipo_avviso, tb.v_descrizione_tipo_avviso,
tb.v_codice_spesa_ricorrente, tb.v_descrizione_spesa_ricorrente,
tb.v_codice_transazione_spesa_ue, tb.v_descrizione_transazione_spesa_ue,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_I else tb.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_I else tb.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_II else tb.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_II else tb.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_III else tb.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_III else tb.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_IV else tb.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_IV else tb.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_I else tb.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_I else tb.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_II else tb.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_II else tb.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_III else tb.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_III else tb.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_IV else tb.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_IV else tb.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
tb.codice_cofog_divisione, tb.descrizione_cofog_divisione,tb.codice_cofog_gruppo,tb.descrizione_cofog_gruppo,
tb.cla21_classif_tipo_desc,tb.cla21_classif_code,tb.cla21_classif_desc,
tb.cla22_classif_tipo_desc,tb.cla22_classif_code,tb.cla22_classif_desc,
tb.cla23_classif_tipo_desc,tb.cla23_classif_code,tb.cla23_classif_desc,
tb.cla24_classif_tipo_desc,tb.cla24_classif_code,tb.cla24_classif_desc,
tb.cla25_classif_tipo_desc,tb.cla25_classif_code,tb.cla25_classif_desc,
tb.v_flagAllegatoCartaceo,tb.v_note_ordinativo,
tb.v_codice_capitolo, tb.v_codice_articolo, tb.v_codice_ueb, tb.v_descrizione_capitolo ,
tb.v_descrizione_articolo,tb.importo_iniziale,tb.importo_attuale,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_code::varchar else tb.cdr_cdr_code::varchar end cdr_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_desc::varchar else tb.cdr_cdr_desc::varchar end cdr_desc,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_code::varchar else tb.cdr_cdc_code::varchar end cdc_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_desc::varchar else tb.cdr_cdc_desc::varchar end cdc_desc,
tb.v_data_firma,tb.v_firma,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_ordpg,
tb.data_creazione_ordpg,
tb.data_modifica_ordpg,
tb.ord_trasm_oil_data,
tb.mif_ord_class_codice_cge,
tb.descr_siope
from (
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza,
a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data,
a.ord_beneficiariomult
,a.ord_id, --q.elem_id,
b.bil_id, a.comm_tipo_id,
f.validita_inizio as data_inizio_val_stato_ordpg,
a.validita_inizio as data_inizio_val_ordpg,
a.data_creazione as data_creazione_ordpg,
a.data_modifica as data_modifica_ordpg,
a.codbollo_id,a.contotes_id,a.dist_id,
a.ord_trasm_oil_data
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i
where  d.ente_proprietario_id = p_ente_proprietario_id--p_ente_proprietario_id
and
c.anno = p_anno_bilancio
AND e.ord_tipo_code = 'P' and
a.bil_id = b.bil_id and
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo,
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo ,
a.elem_desc2 v_descrizione_articolo
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
	   b.soggetto_id v_soggetto_id_modpag, --b.accredito_tipo_id v_accredito_tipo_id,
	   b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
	   b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
	   c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
	   c.codice_fiscale v_codice_fiscale_soggetto_modpag,
	   c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag,
	   b.accredito_tipo_id,
       null tipo_cessione , -- 04.07.2017 Sofia SIAC-5036
       null cod_cessione  , -- 04.07.2017 Sofia SIAC-5036
       null desc_cessione   -- 04.07.2017 Sofia SIAC-5036
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null
UNION -- 04.07.2017 Sofia SIAC-5036
select a.ord_id, b.modpag_id ,
	   b.soggetto_id v_soggetto_id_modpag,
	   b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
	   b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
	   c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
	   c.codice_fiscale v_codice_fiscale_soggetto_modpag,
	   c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag,
	   b.accredito_tipo_id,
       oil.oil_relaz_tipo_code tipo_cessione,
       tipo.relaz_tipo_code cod_cessione,
       tipo.relaz_tipo_desc desc_cessione
from siac_r_ordinativo_modpag a,siac_r_soggetto_relaz rel, siac_r_soggrel_modpag rmdp,
	 siac_r_oil_relaz_tipo roil,siac_d_oil_relaz_tipo oil,siac_d_relaz_tipo tipo,
	 siac_t_modpag b,siac_t_soggetto c
where a.ente_proprietario_id=p_ente_proprietario_id
and   a.modpag_id is NULL
and   rel.soggetto_relaz_id=a.soggetto_relaz_id
and   rmdp.soggetto_relaz_id=rel.soggetto_relaz_id
and   b.modpag_id=rmdp.modpag_id
and   c.soggetto_id=b.soggetto_id
and   roil.relaz_tipo_id=rel.relaz_tipo_id
and   tipo.relaz_tipo_id=roil.relaz_tipo_id
and   oil.oil_relaz_tipo_id=roil.oil_relaz_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
AND   p_data BETWEEN rmdp.validita_inizio AND COALESCE(rmdp.validita_fine, p_data)
AND   p_data BETWEEN roil.validita_inizio AND COALESCE(roil.validita_fine, p_data)
and   a.data_cancellazione is null
and   b.data_cancellazione is null
and   c.data_cancellazione is null
and   rel.data_cancellazione is null
and   rmdp.data_cancellazione is null
and   roil.data_cancellazione is null
),
acc as (select
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT
c.ord_id,d.soggetto_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,a.soggetto_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class21 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla21_classif_tipo_desc,
b.classif_code cla21_classif_code, b.classif_desc cla21_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_21'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class22 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla22_classif_tipo_desc,
b.classif_code cla22_classif_code, b.classif_desc cla22_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_22'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class23 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla23_classif_tipo_desc,
b.classif_code cla23_classif_code, b.classif_desc cla23_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_23'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class24 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla24_classif_tipo_desc,
b.classif_code cla24_classif_code, b.classif_desc cla24_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_24'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class25 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla25_classif_tipo_desc,
b.classif_code cla25_classif_code, b.classif_desc cla25_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_25'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),

cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_ordinativo_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null and
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siac_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT
a.ord_id
, a."boolean" v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagAllegatoCartaceo' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_ORDINATIVO' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
,
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale,
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY
a.ord_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale,
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY
a.ord_id),
firma as (select
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))
, mif as (
  select tb.mif_ord_ord_id, tb.mif_ord_class_codice_cge, tb.descr_siope from (
  with mif1 as (
      select a.mif_ord_anno, a.mif_ord_numero, a.mif_ord_ord_id,
             a.mif_ord_class_codice_cge,
             b.flusso_elab_mif_id, b.flusso_elab_mif_data
      from mif_t_ordinativo_spesa a,  mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id
      and  a.mif_ord_flusso_elab_mif_id=b.flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
     ) ,
      mifmax as (
      select max(b.flusso_elab_mif_id) flusso_elab_mif_id,
      a.mif_ord_anno,a.mif_ord_numero
      from mif_t_ordinativo_spesa a, mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id
      and b.flusso_elab_mif_id=a.mif_ord_flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
      group by a.mif_ord_anno,a.mif_ord_numero
    ),
      descsiope as (
      select replace(substring(a.classif_code from 2),'.', '') codice_siope,
         a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'PDC_V'
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   substring(a.classif_code from 1 for 1) = 'U'
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      union
      select a.classif_code codice_siope,
             a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'SIOPE_SPESA_I'
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      )
    select mif1.*, descsiope.descr_siope
    from mif1
    left join descsiope on descsiope.codice_siope = mif1.mif_ord_class_codice_cge
    join mifmax on mif1.flusso_elab_mif_id=mifmax.flusso_elab_mif_id
    and  mif1.mif_ord_anno=mifmax.mif_ord_anno
    and  mif1.mif_ord_numero=mifmax.mif_ord_numero) as tb
    )
select ord_pag.*,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,bollo.*,commis.*,contotes.*,dist.*,modpag.*,sogg.*,
tipoavviso.*,ricspesa.*,transue.*,
class21.*,class22.*,class23.*,class24.*,class25.*,
bilelem.*,
mif.mif_ord_class_codice_cge, mif.descr_siope
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class21
on ord_pag.ord_id=class21.ord_id
left join class22
on ord_pag.ord_id=class22.ord_id
left join class23
on ord_pag.ord_id=class23.ord_id
left join class24
on ord_pag.ord_id=class24.ord_id
left join class25
on ord_pag.ord_id=class25.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id
left join pdc5
on ord_pag.ord_id=pdc5.ord_id
left join pdc4
on ord_pag.ord_id=pdc4.ord_id
left join pce5
on ord_pag.ord_id=pce5.ord_id
left join pce4
on ord_pag.ord_id=pce4.ord_id
left join attoamm
on ord_pag.ord_id=attoamm.ord_id
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id
left join t_noteordinativo
on
ord_pag.ord_id=t_noteordinativo.ord_id
left join impiniziale
on ord_pag.ord_id=impiniziale.ord_id
left join impattuale
on ord_pag.ord_id=impattuale.ord_id
left join firma
on ord_pag.ord_id=firma.ord_id
left join mif on ord_pag.ord_id = mif.mif_ord_ord_id
) as tb;



    INSERT INTO siac.siac_dwh_subordinativo_pagamento
    (ente_proprietario_id,
    ente_denominazione,
    bil_anno,
    cod_fase_operativa,
    desc_fase_operativa,
    anno_ord_pag,
    num_ord_pag,
    desc_ord_pag,
    cod_stato_ord_pag,
    desc_stato_ord_pag,
    castelletto_cassa_ord_pag,
    castelletto_competenza_ord_pag,
    castelletto_emessi_ord_pag,
    data_emissione,
    data_riduzione,
    data_spostamento,
    data_variazione,
    beneficiario_multiplo,
    num_subord_pag,
    desc_subord_pag,
    data_esecuzione_pagamento,
    importo_iniziale,
    importo_attuale,
    cod_onere,
    desc_onere,
    cod_tipo_onere,
    desc_tipo_onere,
    importo_carico_ente,
    importo_carico_soggetto,
    importo_imponibile,
    inizio_attivita,
    fine_attivita,
    cod_causale,
    desc_causale,
    cod_attivita_onere,
    desc_attivita_onere,
    anno_liquidazione,
    num_liquidazione,
    desc_liquidazione,
    data_emissione_liquidazione,
    importo_liquidazione,
    liquidazione_automatica,
    liquidazione_convalida_manuale,
    cup,
    cig,
    data_inizio_val_stato_ordpg,
    data_inizio_val_subordpg,
    data_creazione_subordpg,
    data_modifica_subordpg,
      --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
    cod_gruppo_doc,
  	desc_gruppo_doc ,
    cod_famiglia_doc ,
    desc_famiglia_doc ,
    cod_tipo_doc ,
    desc_tipo_doc ,
    anno_doc ,
    num_doc ,
    num_subdoc ,
    cod_sogg_doc
    )
    select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end,
tb.ord_ts_code, tb.ord_ts_desc, tb.ord_ts_data_scadenza, tb.importo_iniziale, tb.importo_attuale,
tb.onere_code, tb.onere_desc,tb.onere_tipo_code, tb.onere_tipo_desc   ,
tb.importo_carico_ente, tb.importo_carico_soggetto, tb.importo_imponibile,
tb.attivita_inizio, tb.attivita_fine,tb.v_caus_code, tb.v_caus_desc,
tb.v_onere_att_code, tb.v_onere_att_desc,
tb.v_liq_anno,tb.v_liq_numero, tb.v_liq_desc, tb.v_liq_emissione_data,
tb.v_liq_importo, tb.v_liq_automatica, tb.liq_convalida_manuale,
tb.cup,tb.cig,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_subordpg,
tb.data_creazione_subordpg,
tb.data_modifica_subordpg,
  --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
tb.doc_gruppo_tipo_code,
tb.doc_gruppo_tipo_desc,
tb.doc_fam_tipo_code,
tb.doc_fam_tipo_desc,
tb.doc_tipo_code,
tb.doc_tipo_desc,
tb.doc_anno,
tb.doc_numero,
tb.subdoc_numero,
tb.soggetto_code from (
--subord
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
       a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza,
       a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data,
       a.ord_beneficiariomult
           ,  a.ord_id, --q.elem_id,
       b.bil_id, a.comm_tipo_id,
       f.validita_inizio as data_inizio_val_stato_ordpg,
       a.validita_inizio as data_inizio_val_ordpg,
       a.data_creazione as data_creazione_ordpg,
       a.data_modifica as data_modifica_ordpg,
       a.codbollo_id,a.contotes_id,a.dist_id, l.ord_ts_id,
       l.ord_ts_code, l.ord_ts_desc, l.ord_ts_data_scadenza,
        l.validita_inizio as data_inizio_val_subordpg,
         l.data_creazione as data_creazione_subordpg,
         l.data_modifica as data_modifica_subordpg
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i ,siac_t_ordinativo_ts l
where  d.ente_proprietario_id = p_ente_proprietario_id--p_ente_proprietario_id
and
c.anno = p_anno_bilancio--p_anno_bilancio
AND e.ord_tipo_code = 'P' and
a.bil_id = b.bil_id and
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id
and l.ord_id=a.ord_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo,
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo ,
a.elem_desc2 v_descrizione_articolo
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, b.accredito_tipo_id v_accredito_tipo_id,
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag,
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT
c.ord_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class21 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_1,
b.classif_code v_classificatore_generico_1_valore, b.classif_desc v_classificatore_generico_1_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_21'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class22 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_2,
b.classif_code v_classificatore_generico_2_valore, b.classif_desc v_classificatore_generico_2_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_22'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class23 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_3,
b.classif_code v_classificatore_generico_3_valore, b.classif_desc v_classificatore_generico_3_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_23'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class24 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_4,
b.classif_code v_classificatore_generico_4_valore, b.classif_desc v_classificatore_generico_4_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_24'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class25 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_5,
b.classif_code v_classificatore_generico_5_valore, b.classif_desc v_classificatore_generico_5_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_25'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),

cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_ordinativo_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null and
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT
a.ord_id
, a.testo v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagAllegatoCartaceo' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_ORDINATIVO' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_cig as (
SELECT
a.sord_id
, c.testo cig
FROM   siac_r_liquidazione_ord a, siac_t_attr b,siac_r_liquidazione_attr c
WHERE
b.attr_code='cig' and
a.ente_proprietario_id=p_ente_proprietario_id and
 c.attr_id = b.attr_id
 and c.liq_id=a.liq_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL)
, t_cup as (
SELECT
a.sord_id
, c.testo cup
FROM   siac_r_liquidazione_ord a, siac_t_attr b,siac_r_liquidazione_attr c
WHERE
b.attr_code='cup' and
a.ente_proprietario_id=p_ente_proprietario_id and
 c.attr_id = b.attr_id
 and c.liq_id=a.liq_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL),
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale,
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY
b.ord_ts_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale,
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY
b.ord_ts_id),
firma as (select
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)),
ons as (
with  onere as (
select a.ord_ts_id,
c.onere_code, c.onere_desc, d.onere_tipo_code, d.onere_tipo_desc,
b.importo_carico_ente, b.importo_carico_soggetto, b.importo_imponibile,
b.attivita_inizio, b.attivita_fine, b.caus_id, b.onere_att_id
from  siac_r_doc_onere_ordinativo_ts  a,siac_r_doc_onere b,siac_d_onere c,siac_d_onere_tipo d
where
a.ente_proprietario_id=p_ente_proprietario_id and
 b.doc_onere_id=a.doc_onere_id
and c.onere_id=b.onere_id
and d.onere_tipo_id=c.onere_tipo_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
 AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
),
 causale as (SELECT
 dc.caus_id,
 dc.caus_code v_caus_code, dc.caus_desc v_caus_desc
  FROM siac.siac_d_causale dc
  WHERE  dc.ente_proprietario_id=p_ente_proprietario_id and  dc.data_cancellazione IS NULL)
 ,
 onatt as (
 -- Sezione per l'onere
  SELECT
  doa.onere_att_id,
  doa.onere_att_code v_onere_att_code, doa.onere_att_desc v_onere_att_desc
  FROM siac_d_onere_attivita doa
  WHERE --doa.onere_att_id = v_onere_att_id
  doa.ente_proprietario_id=p_ente_proprietario_id
    AND doa.data_cancellazione IS NULL)
select * from onere left join causale
on onere.caus_id= causale.caus_id
left join onatt
on onere.onere_att_id=onatt.onere_att_id),
liq as (select a.sord_id,
b.liq_anno v_liq_anno, b.liq_numero v_liq_numero, b.liq_desc v_liq_desc, b.liq_emissione_data v_liq_emissione_data,
         b.liq_importo v_liq_importo, b.liq_automatica v_liq_automatica, b.liq_convalida_manuale
 FROM siac_r_liquidazione_ord a, siac_t_liquidazione b
  WHERE a.liq_id = b.liq_id
  AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL ),
 --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
 elenco_doc as (
		select distinct d_doc_gruppo.doc_gruppo_tipo_code, d_doc_gruppo.doc_gruppo_tipo_desc,
    	d_doc_fam_tipo.doc_fam_tipo_code, d_doc_fam_tipo.doc_fam_tipo_desc,
        d_doc_tipo.doc_tipo_code, d_doc_tipo.doc_tipo_desc,
        t_doc.doc_numero, t_doc.doc_anno, t_subdoc.subdoc_numero,
        t_soggetto.soggetto_code,
        r_subdoc_ord_ts.ord_ts_id
    from siac_t_doc t_doc
    		LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	AND r_doc_sog.data_cancellazione IS NULL
                    AND p_data BETWEEN r_doc_sog.validita_inizio AND
                    	COALESCE(r_doc_sog.validita_fine, p_data))
            LEFT JOIN siac_t_soggetto t_soggetto
            	ON (t_soggetto.soggetto_id=r_doc_sog.soggetto_id
                	AND t_soggetto.data_cancellazione IS NULL),
		siac_t_subdoc t_subdoc,
    	siac_d_doc_tipo d_doc_tipo
        	LEFT JOIN siac_d_doc_gruppo d_doc_gruppo
            	ON (d_doc_gruppo.doc_gruppo_tipo_id=d_doc_tipo.doc_gruppo_tipo_id
                	AND d_doc_gruppo.data_cancellazione IS NULL),
    	siac_d_doc_fam_tipo d_doc_fam_tipo,
        siac_r_subdoc_ordinativo_ts r_subdoc_ord_ts
    where t_doc.doc_id=t_subdoc.doc_id
    	and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
        and d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id
        and r_subdoc_ord_ts.subdoc_id=t_subdoc.subdoc_id
    	and t_doc.ente_proprietario_id=p_ente_proprietario_id
    	and t_doc.data_cancellazione IS NULL
   		and t_subdoc.data_cancellazione IS NULL
        AND d_doc_fam_tipo.data_cancellazione IS NULL
        and d_doc_tipo.data_cancellazione IS NULL
        and r_subdoc_ord_ts.data_cancellazione IS NULL
        and r_subdoc_ord_ts.validita_fine IS NULL
        AND p_data BETWEEN r_subdoc_ord_ts.validita_inizio AND
                    	COALESCE(r_subdoc_ord_ts.validita_fine, p_data))
select ord_pag.*,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo,
t_noteordinativo.v_note_ordinativo,
t_cig.cig,
t_cup.cup,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,
ons.*,liq.*, elenco_doc.*
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class21
on ord_pag.ord_id=class21.ord_id
left join class22
on ord_pag.ord_id=class22.ord_id
left join class23
on ord_pag.ord_id=class23.ord_id
left join class24
on ord_pag.ord_id=class24.ord_id
left join class25
on ord_pag.ord_id=class25.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id
left join pdc5
on ord_pag.ord_id=pdc5.ord_id
left join pdc4
on ord_pag.ord_id=pdc4.ord_id
left join pce5
on ord_pag.ord_id=pce5.ord_id
left join pce4
on ord_pag.ord_id=pce4.ord_id
left join attoamm
on ord_pag.ord_id=attoamm.ord_id
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id
left join t_noteordinativo
on
ord_pag.ord_id=t_noteordinativo.ord_id
left join t_cig
on
ord_pag.ord_ts_id=t_cig.sord_id
left join t_cup
on
ord_pag.ord_ts_id=t_cup.sord_id
left join impiniziale
on ord_pag.ord_ts_id=impiniziale.ord_ts_id
left join impattuale
on ord_pag.ord_ts_id=impattuale.ord_ts_id
left join firma
on ord_pag.ord_id=firma.ord_id
left join ons
on ord_pag.ord_ts_id=ons.ord_ts_id
left join liq
on ord_pag.ord_ts_id=liq.sord_id
--04/07/2017: SIAC-5037 aggiunta gestione dei documenti
left join elenco_doc
on elenco_doc.ord_ts_id=ord_pag.ord_ts_id
) as tb;


esito:= 'Fine funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-5036 Sofia FINE

-- SIAC-4996 INIZIO
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.desc, dat.azione_tipo_id, gda.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'), tep.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_t_ente_proprietario tep ON (dat.ente_proprietario_id = tep.ente_proprietario_id)
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = e.ente_proprietario_id)
CROSS JOIN (VALUES ('OP-SPE-CompDefPreDoc', 'Completa e Definisci da Elenco', 'ATTIVITA_SINGOLA', 'FIN2_PREDOC')) AS tmp(code, descr, tipo, gruppo)
WHERE dga.gruppo_azioni_code = tmp.gruppo
AND dat.azione_tipo_id = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_tipo_id = dat.azione_tipo_id
	AND ta.azione_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_r_ruolo_op_azione (ruolo_op_id, azione_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dro.ruolo_op_id, ta.azione_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_ruolo_op dro ON dro.ente_proprietario_id = tep.ente_proprietario_id
JOIN siac_t_azione ta ON ta.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('OP-SPE-CompDefPreDoc', 'ROP_DOCSPESA', '')) AS tmp(azione, ruolo, ente)
WHERE dro.ruolo_op_code = tmp.ruolo
AND ta.azione_code = tmp.azione
--AND UPPER(TRANSATE('', '', tep.ente_denominazione)) = UPPER(tmp.ente)
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_ruolo_op_azione rroa
	WHERE rroa.ente_proprietario_id = tep.ente_proprietario_id
	AND rroa.ruolo_op_id = dro.ruolo_op_id
	AND rroa.azione_id = ta.azione_id
	AND rroa.data_cancellazione IS NULL
);
-- SIAC-4996 FINE

-- SIAC-5023 INIZIO

INSERT INTO siac_d_gestione_tipo
  (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)

  SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'admin'
	FROM siac_t_ente_proprietario tep
	CROSS JOIN (VALUES ('GESTIONE_MESSAGGIO_INFORMATIVO', 'Messaggio informativo sul cruscotto')) AS tmp(code, descr)
	WHERE NOT EXISTS (
		SELECT 1
		FROM siac_d_gestione_tipo dgt
		WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
		AND dgt.gestione_tipo_code = tmp.code
	)
	ORDER BY tep.ente_proprietario_id, tmp.code;


INSERT INTO siac_d_gestione_livello
  (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)

  SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, now(), tep.ente_proprietario_id, 'admin'
	FROM siac_t_ente_proprietario tep
	JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
	CROSS JOIN (VALUES ('MESSAGGIO_INFORMATIVO', '', 'GESTIONE_MESSAGGIO_INFORMATIVO')
			   )
				AS tmp(code, descr, tipo)
	WHERE dgt.gestione_tipo_code = tmp.tipo
	AND NOT EXISTS (
		SELECT 1
		FROM siac_d_gestione_livello dgl
		WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
		AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
		AND dgt.gestione_tipo_code = tmp.code
	)
	ORDER BY tep.ente_proprietario_id, tmp.code;


INSERT INTO siac_r_gestione_ente
  (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)

  SELECT dgl.gestione_livello_id, now(), tep.ente_proprietario_id, 'admin'
	FROM siac_t_ente_proprietario tep
	JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
	CROSS JOIN (VALUES ('MESSAGGIO_INFORMATIVO')
					   )
				AS tmp(livello)
	WHERE dgl.gestione_livello_code = tmp.livello
	AND NOT EXISTS (
		SELECT 1
		FROM siac_r_gestione_ente rge
		WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
		AND rge.gestione_livello_id = dgl.gestione_livello_id
		AND rge.data_cancellazione IS NULL
	);
-- SIAC-5023 FINE
