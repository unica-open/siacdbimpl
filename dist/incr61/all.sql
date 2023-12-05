/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-6573 - Sofia - Inizio
drop FUNCTION if exists siac.fnc_siac_dwh_accertamento 
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);


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

-- 04.06.2018 Sofia siac-6220
v_FlagAttivaGsa VARCHAR := null;

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

-- 23.10.2018 Sofia jira SIAC-6336
v_programma_stato varchar:=null;
v_versione_cronop varchar:=null;
v_desc_cronop varchar:=null;
v_anno_cronop varchar:=null;
v_programma_id integer:=null;

v_user_table varchar;
params varchar;

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


select fnc_siac_random_user()
into	v_user_table;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_accertamento',
params,
clock_timestamp(),
v_user_table
);



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
and tm.movgest_anno::integer=2015
and tm.movgest_numero::integer=1901
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

-- 04.06.2018 Sofia siac-6220
v_FlagAttivaGsa  := null;


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
  ELSIF rec_attr.attr_code = 'FlagAttivaGsa' THEN
     v_FlagAttivaGsa := v_flag_attributo;
     --nuova sezione GSA 04.06.2018 Sofia siac-6220

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
      AND   dct.data_cancellazione IS NULL;
      -- 27.11.2018 Sofia siac-6573
--      AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
--      AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
--      AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

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
-- 23.10.2018 Sofia SIAC-6336
v_programma_stato:= null;
v_versione_cronop:=null;
v_desc_cronop:=null;
v_anno_cronop:=null;
v_programma_id:=null;

-- 23.10.2018 Sofia SIAC-6336
SELECT tp.programma_code, tp.programma_desc, stato.programma_stato_code, rmtp.programma_id
INTO   v_programma_code, v_programma_desc, v_programma_stato, v_programma_id
FROM   siac_r_movgest_ts_programma rmtp, siac_t_programma tp,
       siac_r_programma_stato rs, siac_d_programma_stato stato
WHERE  rmtp.movgest_ts_id = v_movgest_ts_id
AND    rmtp.programma_id = tp.programma_id
and    rs.programma_id=rmtp.programma_id
and    stato.programma_stato_id=rs.programma_stato_id
AND    p_data BETWEEN rmtp.validita_inizio and COALESCE(rmtp.validita_fine,p_data)
AND    p_data BETWEEN tp.validita_inizio and COALESCE(tp.validita_fine,p_data)
AND    p_data BETWEEN rs.validita_inizio and COALESCE(rs.validita_fine,p_data)
AND    rmtp.data_cancellazione IS NULL
AND    tp.data_cancellazione IS NULL
and    rs.data_cancellazione IS NULL;

-- 23.10.2018 Sofia SIAC-6336
if v_programma_id is not null then
	select cronop.cronop_code, cronop.cronop_desc, per.anno::integer
    into   v_versione_cronop, v_desc_cronop, v_anno_cronop
    from siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,siac_t_bil bil,siac_t_periodo per
    where cronop.programma_id=v_programma_id
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code='VA'
    and   bil.bil_id=cronop.bil_id
    and   per.periodo_id=bil.periodo_id
    and   per.anno::integer=p_anno_bilancio::integer
    AND   p_data BETWEEN rs.validita_inizio and COALESCE(rs.validita_fine,p_data)
    AND   p_data BETWEEN cronop.validita_inizio and COALESCE(cronop.validita_fine,p_data)
    and   rs.data_cancellazione is null
    and   cronop.data_cancellazione is null
    order by cronop.cronop_id desc
    limit 1;

end if;

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
flag_attiva_gsa, -- 04.06.2018 Sofia siac-6220
data_inizio_val_stato_accer,
data_inizio_val_accer,
data_creazione_accer,
data_modifica_accer,
cod_programma,
desc_programma,
-- 23.10.2018 Sofia jira siac-6336
stato_programma,
versione_cronop,
desc_cronop,
anno_cronop
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
          coalesce(v_FlagAttivaGsa,'N'), -- 04.06.2018 Sofia siac-6220
          v_data_inizio_val_stato_accer,
          v_data_inizio_val_accer,
          v_data_creazione_accer,
          v_data_modifica_accer,
          v_programma_code,
          v_programma_desc,
          -- 23.10.2018 Sofia jira siac-6336
		  v_programma_stato,
		  v_versione_cronop,
	      v_desc_cronop,
	      v_anno_cronop
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
flag_attiva_gsa, -- 04.06.2018 Sofia siac-6220
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
          coalesce(v_FlagAttivaGsa,'N'), -- 04.06.2018 Sofia siac-6220
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


update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico accertamenti (FNC_SIAC_DWH_ACCERTAMENTO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-6573 - Sofia - Fine


---MODIFICHE DDL CESPITI INIZIO
SELECT * FROM fnc_dba_add_column_params ('siac_r_cespiti_mov_ep_det', 'importo_su_prima_nota' , 'NUMERIC NOT NULL DEFAULT 0');
---MODIFICHE DDL CESPITI FINE



-- SIAC-6261_impegno INIZIO
INSERT INTO siac_t_attr (
  attr_code,
  attr_desc,
  attr_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  login_operazione)
SELECT 
	'flagSoggettoDurc',
    'Flag Soggetto a DURC',
    (SELECT at.attr_tipo_id FROM siac_d_attr_tipo at WHERE at.attr_tipo_code='B' AND at.ente_proprietario_id=e.ente_proprietario_id),
    now(),
    e.ente_proprietario_id,
    now(),
    now(),
    'admin'
FROM siac_t_ente_proprietario e
WHERE NOT EXISTS (
	SELECT * FROM siac_t_attr a 
    WHERE a.attr_code='flagSoggettoDurc'
    AND a.ente_proprietario_id=e.ente_proprietario_id
);

-- SIAC-6261_impegno FINE


-- Sofia PAGOPA - Inizio
drop table if exists pagopa_t_elaborazione_log;

CREATE TABLE siac.pagopa_t_elaborazione_log (
  pagopa_elab_log_id SERIAL,
  pagopa_elab_id INTEGER,
  pagopa_elab_file_id INTEGER,
  pagopa_elab_log_operazione VARCHAR(2500) NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_elab_t_elaborazione_log PRIMARY KEY(pagopa_elab_log_id),
  CONSTRAINT pagopa_t_elaborazione_pagopa_t_elaborazione_log FOREIGN KEY (pagopa_elab_id)
    REFERENCES siac.pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elaborazione_log FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_file_pagopa_pagopa_t_elaborazione_log FOREIGN KEY (pagopa_elab_file_id)
    REFERENCES siac.siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
) 
WITH (oids = false);

COMMENT ON TABLE siac.pagopa_t_elaborazione_log
IS 'Elaborazioni riconciliazione PAGOPA - LOG.';

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ACQUISITO',
 'ACQUISITO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ACQUISITO');
-- Sofia PAGOPA - Fine


-- SIAC-6261 Sofia - DWH - Inizio 

SELECT fnc_dba_add_column_params('siac_dwh_soggetto', 'soggetto_tipo_fonte_durc', 'varchar(1)');
SELECT fnc_dba_add_column_params('siac_dwh_soggetto', 'soggetto_fonte_durc_automatica', 'varchar(500)');
SELECT fnc_dba_add_column_params('siac_dwh_soggetto', 'soggetto_note_durc', 'varchar(500)');
SELECT fnc_dba_add_column_params('siac_dwh_soggetto', 'soggetto_fine_validita_durc', 'TIMESTAMP WITHOUT TIME ZONE');
SELECT fnc_dba_add_column_params('siac_dwh_soggetto', 'soggetto_fonte_durc_manuale_code', 'varchar(200)');
SELECT fnc_dba_add_column_params('siac_dwh_soggetto', 'soggetto_fonte_durc_manuale_desc', 'varchar(500)');

drop function if exists fnc_siac_dwh_soggetto 
(
  p_ente_proprietario_id integer,
  p_data timestamp
);

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

v_user_table varchar;
params varchar;
fnc_eseguita integer;

-- 05.12.2018 Sofia SIAC-6261
v_soggetto_tipo_fonte_durc varchar:=null;
v_soggetto_fonte_durc_automatica varchar:=null;
v_soggetto_note_durc varchar:=null;
v_soggetto_fine_validita_durc timestamp:=null;
v_soggetto_fonte_durc_manuale_code varchar:=null;
v_soggetto_fonte_durc_manuale_desc varchar:=null;

BEGIN

select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_soggetto';

if fnc_eseguita> 0 then

return;

else

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_soggetto',
params,
clock_timestamp(),
v_user_table
);

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
       ts.soggetto_desc,
       -- 05.12.2018 Sofia SIAC-6261
       ts.soggetto_tipo_fonte_durc,
       substring(ts.soggetto_fonte_durc_automatica from 1 for 500) soggetto_fonte_durc_automatica,
       substring(ts.soggetto_note_durc from 1 for 500) soggetto_note_durc,
       ts.soggetto_fine_validita_durc::timestamp soggetto_fine_validita_durc,
       ts.soggetto_fonte_durc_manuale_classif_id
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
order by ts.soggetto_id desc
limit 3000
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

-- 05.12.2018 Sofia SIAC-6261
v_soggetto_tipo_fonte_durc:=null;
v_soggetto_fonte_durc_automatica:=null;
v_soggetto_note_durc:=null;
v_soggetto_fine_validita_durc:=null;
v_soggetto_fonte_durc_manuale_code:=null;
v_soggetto_fonte_durc_manuale_desc:=null;

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


-- 05.12.2018 Sofia SIAC-6261
v_soggetto_tipo_fonte_durc:=rec_soggetto_id.soggetto_tipo_fonte_durc;
v_soggetto_fonte_durc_automatica:=rec_soggetto_id.soggetto_fonte_durc_automatica;
v_soggetto_note_durc:=rec_soggetto_id.soggetto_note_durc;
v_soggetto_fine_validita_durc:=rec_soggetto_id.soggetto_fine_validita_durc;


if rec_soggetto_id.soggetto_fonte_durc_manuale_classif_id is not null then
	select c.classif_code, c.classif_desc
    into   v_soggetto_fonte_durc_manuale_code,v_soggetto_fonte_durc_manuale_desc
	from siac_t_class c, siac_d_class_tipo tipo
    where c.classif_id=rec_soggetto_id.soggetto_fonte_durc_manuale_classif_id
    and   tipo.classif_tipo_id=c.classif_tipo_id
    and   tipo.classif_tipo_code in ('CDC','CDR')
    and   c.data_cancellazione is null;

end if;


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
    soggetto_principale,
    -- 05.12.2018  Sofia Sofia SIAC-6261
    soggetto_tipo_fonte_durc,
    soggetto_fonte_durc_automatica,
    soggetto_note_durc,
    soggetto_fine_validita_durc,
    soggetto_fonte_durc_manuale_code,
    soggetto_fonte_durc_manuale_desc
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
          v_soggetto_principale,
          -- 05.12.2018  Sofia Sofia SIAC-6261
          v_soggetto_tipo_fonte_durc,
	      v_soggetto_fonte_durc_automatica,
	      v_soggetto_note_durc,
	      v_soggetto_fine_validita_durc,
	      v_soggetto_fonte_durc_manuale_code,
	      v_soggetto_fonte_durc_manuale_desc
         );

esito:= '  Fine ciclo soggetto - soggetto_id ('||v_soggetto_id||') - '||clock_timestamp();
return next;
END LOOP;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

end if;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico soggetto (FNC_SIAC_DWH_SOGGETTO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;


-- SIAC-6261 Sofia - DWH - Fine




-- STIPENDI to STIPE - INIZIO
UPDATE siac_d_file_tipo
  SET file_tipo_code='STIPE'
  WHERE UPPER(file_tipo_code)='STIPENDI';
-- STIPENDI to STIPE - FINE

-- 12.12.2018 Sofia - SIAC-6498 - inizio 

drop FUNCTION siac."BILR209_stampa_variazione_spese_def" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_anno_variazione varchar
);

CREATE OR REPLACE FUNCTION siac."BILR209_stampa_variazione_spese_def" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_anno_variazione varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE


classifBilRec record;


annoCapImp varchar;
annoCapImp2 varchar;
annoCapImp3 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:='';
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
sql_query varchar;
strApp varchar;
intApp numeric;

BEGIN

annoCapImp:= p_anno;
annocapimp2:=(p_anno::INTEGER + 1)::varchar;
annocapimp3:=(p_anno::INTEGER + 2)::varchar;

raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;


bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
display_error='';

---------------------------------------------------------------------------------------------------------------------

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';


-- carico struttura del bilancio
with missione as
(select
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 06/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;



 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';
insert into siac_rep_cap_ug
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr,
	 siac_d_bil_elem_stato stato_capitolo,
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	-- INC000001570761 stato_capitolo.elem_stato_code	=	'VA'								and
    stato_capitolo.elem_stato_code	in ('VA', 'PR')							and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
    ------cat_del_capitolo.elem_cat_code	=	'STD'
    -- 06/09/2016: aggiunto FPVC
	--and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null
	and	stato_capitolo.data_cancellazione 			is null
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;


    insert into siac_rep_cap_ug
      select null, null,
        anno_eserc.anno anno_bilancio,
        e.*, ' ', user_table utente
       from
              siac_t_bil_elem e,
              siac_t_bil bilancio,
              siac_t_periodo anno_eserc,
              siac_d_bil_elem_tipo tipo_elemento,
              siac_d_bil_elem_stato stato_capitolo,
              siac_r_bil_elem_stato r_capitolo_stato
      where e.ente_proprietario_id=p_ente_prop_id
      and anno_eserc.anno					= 	p_anno
      and bilancio.periodo_id				=	anno_eserc.periodo_id
      and e.bil_id						=	bilancio.bil_id
      and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id
      and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
      and	e.elem_id						=	r_capitolo_stato.elem_id
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
	  -- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'
      and stato_capitolo.elem_stato_code	in ('VA', 'PR')
      and e.data_cancellazione 				is null
      and	r_capitolo_stato.data_cancellazione	is null
      and	bilancio.data_cancellazione 		is null
      and	anno_eserc.data_cancellazione 		is null
      and	tipo_elemento.data_cancellazione	is null
      and	stato_capitolo.data_cancellazione 	is null
      and not EXISTS
      (
         select 1 from siac_rep_cap_ug x
         where x.elem_id = e.elem_id
         and x.utente=user_table
    );

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';


/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare
    l'importo del capitolo.
*/
/*  10/12/2018    modificata lettura degli importi siac_6498
INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc,
	 		siac_d_bil_elem_stato 		stato_capitolo,
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id
        and	anno_eserc.anno						= 	p_anno
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	capitolo.bil_id						=	bilancio.bil_id
        and	capitolo.elem_id					=	capitolo_importi.elem_id
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id
        and	capitolo_imp_periodo.anno = p_anno_variazione
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
	 	-- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'
        and stato_capitolo.elem_stato_code	in ('VA', 'PR')
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_imp_tipo.elem_det_tipo_code in ('STA', 'SCA','STR')
        -- 06/09/2016: aggiunto FPVC
        --and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
 		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null
	 	and	stato_capitolo.data_cancellazione 			is null
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;
 *****************/
 sql_query:='
with cap as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            capitolo_imp_tipo.elem_det_tipo_id,
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc,
	 		siac_d_bil_elem_stato 		stato_capitolo,
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo
    where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id ||'
        and	anno_eserc.anno						= '''||p_anno ||'''
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	capitolo.bil_id						=	bilancio.bil_id
        and	capitolo.elem_id					=	capitolo_importi.elem_id
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id
        and	capitolo_imp_periodo.anno = '''||p_anno_variazione||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
	 	-- INC000001570761 and stato_capitolo.elem_stato_code	=	''VA''
        and stato_capitolo.elem_stato_code	in (''VA'', ''PR'')
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_imp_tipo.elem_det_tipo_code in (''STA'', ''SCA'',''STR'')
        -- 06/09/2016: aggiunto FPVC
        --and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')
 		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null
	 	and	stato_capitolo.data_cancellazione 			is null
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id,
    capitolo_imp_tipo.elem_det_tipo_id),
importi_variaz as (
		select
              dvarsucc.elem_id elem_id_var,
			  tipoimp.elem_det_tipo_id,
              sum(COALESCE(dvarsucc.elem_det_importo,0)) totale_var_succ
          from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,
              siac_t_variazione avar, siac_r_variazione_stato bvar,
              siac_d_variazione_stato cvarsucc,
              siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvarsucc,
              siac_d_bil_elem_det_tipo tipoimp
          where bvarsucc.validita_inizio >= bvar.validita_inizio
              and avar.ente_proprietario_id=avarsucc.ente_proprietario_id
              and avarsucc.variazione_id= bvarsucc.variazione_id
              and avar.variazione_id=bvar.variazione_id
              and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
              and cvarsucc.variazione_stato_tipo_code=''D''
              and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
              and cvar.variazione_stato_tipo_code=''D''
              and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
              and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
              and bvarsucc.data_cancellazione is null
              and bvar.variazione_stato_id in (
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id  	='||p_ente_prop_id ||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
			group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ' ;


sql_query:=sql_query||'
              INSERT INTO siac_rep_cap_ug_imp
              select 	cap.elem_id,
              			cap.BIL_ELE_IMP_ANNO,
                		cap.TIPO_IMP,
              			cap.ente_proprietario_id,
                        '''||user_table||''' utente,
                		(cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
              from cap LEFT  JOIN importi_variaz
              ON (cap.elem_id = importi_variaz.elem_id_var
              	and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id)';

raise notice 'query: %', sql_query;

execute  sql_query;

     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id,
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente ,
        tb1.periodo_anno
from
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		tb1.periodo_anno 		= p_anno_variazione	AND
                tb1.tipo_imp 	=	tipoImpComp		        AND
        		tb2.periodo_anno		= tb1.periodo_anno	AND
                tb2.tipo_imp 	= 	tipoImpCassa	        and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND
                tb4.tipo_imp 	= 	TipoImpRes		        and
                tb1.ente_proprietario 	=	p_ente_prop_id						and
                tb2.ente_proprietario	=	tb1.ente_proprietario				and
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and
                tb4.utente				=	tb1.utente;

     RTN_MESSAGGIO:='preparazione tabella variazioni''.';


sql_query='insert into siac_rep_var_spese
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, ''';
sql_query=sql_query ||user_table||''' utente,
        testata_variazione.ente_proprietario_id,
        anno_importo.anno
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo              anno_importo ,
        siac_t_bil                  bilancio
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id
and     capitolo.bil_id                                     = bilancio.bil_id
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
sql_query=sql_query ||'and		tipo_capitolo.elem_tipo_code						= '''||elemTipoCode||'''';
sql_query=sql_query ||' and 	testata_variazione.ente_proprietario_id 	= 	'||p_ente_prop_id;
sql_query=sql_query ||' and		anno_eserc.anno					= 	'''||p_anno||'''';
sql_query=sql_query ||' and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 = ''D''
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code,
        	utente,
        	testata_variazione.ente_proprietario_id,
            anno_importo.anno';

raise notice 'sql_query = % ', sql_query;

EXECUTE sql_query;


     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';

insert into siac_rep_var_spese_riga
select  tb0.elem_id,
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno_variazione
from
	siac_rep_cap_ug tb0
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0
        and     tb1.periodo_anno=p_anno_variazione
        and     tb1.utente = tb0.utente
        -- and tb0.tipo_imp =  tb1.tipologia
        )
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0
        and     tb2.periodo_anno=p_anno_variazione
        and     tb2.utente = tb0.utente
        -- and tb0.tipo_imp =  tb2.tipologia
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0
        and     tb3.periodo_anno=p_anno_variazione
        and     tb3.utente = tb0.utente
        -- and tb0.tipo_imp =  tb3.tipologia
          )
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0
        and     tb4.periodo_anno=p_anno_variazione
        and     tb4.utente = tb0.utente
        -- and tb0.tipo_imp =  tb4.tipologia
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno_variazione
        and     tb5.utente = tb0.utente
         --and tb0.tipo_imp =  tb5.tipologia
          )
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno_variazione
        and     tb6.utente = tb0.utente
         --and tb0.tipo_imp =  tb6.tipologia
         )
        where  tb0.utente = user_table
   /*
   union
     select  tb0.elem_id,
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp2
from
	siac_rep_cap_ug tb0
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente
        -- and tb0.tipo_imp =  tb1.tipologia
        )
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente
        -- and tb0.tipo_imp =  tb2.tipologia
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente
        -- and tb0.tipo_imp =  tb3.tipologia
          )
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente
        -- and tb0.tipo_imp =  tb4.tipologia
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente
         --and tb0.tipo_imp =  tb5.tipologia
          )
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente
         --and tb0.tipo_imp =  tb6.tipologia
         )
        where  tb0.utente = user_table
        union
     select  tb0.elem_id,
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp3
from
	siac_rep_cap_ug tb0
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0
        and     tb1.periodo_anno=annocapimp3
        and     tb1.utente = tb0.utente
        -- and tb0.tipo_imp =  tb1.tipologia
        )
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0
        and     tb2.periodo_anno=annocapimp3
        and     tb2.utente = tb0.utente
        -- and tb0.tipo_imp =  tb2.tipologia
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0
        and     tb3.periodo_anno=annocapimp3
        and     tb3.utente = tb0.utente
        -- and tb0.tipo_imp =  tb3.tipologia
          )
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0
        and     tb4.periodo_anno=annocapimp3
        and     tb4.utente = tb0.utente
        -- and tb0.tipo_imp =  tb4.tipologia
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp3
        and     tb5.utente = tb0.utente
         --and tb0.tipo_imp =  tb5.tipologia
          )
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp3
        and     tb6.utente = tb0.utente
         --and tb0.tipo_imp =  tb6.tipologia
         )
        where  tb0.utente = user_table   */ ;


     RTN_MESSAGGIO:='preparazione file output ''.';

/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_spese_riga x, siac_rep_cap_ug y, siac_r_class_fam_tree z
*/
for classifBilRec in
select	v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
         	LEFT join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ug_imp_riga tb1
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table
                    )
            left	join    siac_rep_var_spese_riga tb2
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)
    where v1.utente = user_table
    	and tb1.periodo_anno = p_anno_variazione
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y,
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id
             /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/

    )
    union
    select
    	'0000000'							macroag_code,
      	' '									macroag_desc,
        'Macroaggregato'					macroag_tipo_desc,
        '00'								missione_code,
        ' '									missione_desc,
        'Missione'							missione_tipo_desc,
        '0000'								programma_code,
        ' '									programma_desc,
        'Programma'							programma_tipo_desc,
        '0'									titusc_code,
        ' '									titusc_desc,
        'Titolo Spesa'						titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
from  	siac_t_ente_proprietario t_ente,
		 siac_rep_cap_ug tb
            left	join    siac_rep_cap_ug_imp_riga tb1
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_spese_riga tb2
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)
    where t_ente.ente_proprietario_id=tb.ente_proprietario_id
    and tb.utente = user_table
    and  tb1.periodo_anno=p_anno_variazione
   and (tb.programma_id is null or tb.macroaggregato_id is NULL)


			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop



missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;

return next;
bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';

end loop;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;

delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_cap_ug_imp where utente=user_table;

delete from siac_rep_cap_ug_imp_riga where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;

delete from siac_rep_var_spese_riga where utente=user_table;



raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- 12.12.2018 Sofia - SIAC-6498 - fine

-- 13.12.2018 Sofia - SIAC-6602 - inizio
drop function if exists fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioBck VARCHAR(1500):='';
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(50):='';
	codResult integer:=null;
    codResult1 integer:=null;
    docid integer:=null;
    subDocId integer:=null;
    nProgressivo integer=null;

    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione


    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
    PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO

    DOC_STATO_VALIDO    CONSTANT  varchar :='V';
	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';

    -- attributi siac_t_doc
	ANNO_REPERTORIO_ATTR CONSTANT varchar:='anno_repertorio';
	NUM_REPERTORIO_ATTR CONSTANT varchar:='num_repertorio';
	DATA_REPERTORIO_ATTR CONSTANT varchar:='data_repertorio';
	REG_REPERTORIO_ATTR CONSTANT varchar:='registro_repertorio';
	ARROTONDAMENTO_ATTR CONSTANT varchar:='arrotondamento';

	CAUS_SOSPENSIONE_ATTR CONSTANT varchar:='causale_sospensione';
	DATA_SOSPENSIONE_ATTR CONSTANT varchar:='data_sospensione';
    DATA_RIATTIVAZIONE_ATTR CONSTANT varchar:='data_riattivazione';
    DATA_SCAD_SOSP_ATTR CONSTANT varchar:='dataScadenzaDopoSospensione';
    TERMINE_PAG_ATTR CONSTANT varchar:='terminepagamento';
    NOTE_PAG_INC_ATTR CONSTANT varchar:='notePagamentoIncasso';
    DATA_PAG_INC_ATTR CONSTANT varchar:='dataOperazionePagamentoIncasso';

	FL_AGG_QUOTE_ELE_ATTR CONSTANT varchar:='flagAggiornaQuoteDaElenco';
    FL_SENZA_NUM_ATTR CONSTANT varchar:='flagSenzaNumero';
    FL_REG_RES_ATTR CONSTANT varchar:='flagDisabilitaRegistrazioneResidui';
    FL_PAGATA_INC_ATTR CONSTANT varchar:='flagPagataIncassata';
    COD_FISC_PIGN_ATTR CONSTANT varchar:='codiceFiscalePignorato';
    DATA_RIC_PORTALE_ATTR CONSTANT varchar:='dataRicezionePortale';

	FL_AVVISO_ATTR	 CONSTANT varchar:='flagAvviso';
    FL_ESPROPRIO_ATTR	 CONSTANT varchar:='flagEsproprio';
    FL_ORD_MANUALE_ATTR	 CONSTANT varchar:='flagOrdinativoManuale';
    FL_ORD_SINGOLO_ATTR	 CONSTANT varchar:='flagOrdinativoSingolo';
    FL_RIL_IVA_ATTR	 CONSTANT varchar:='flagRilevanteIVA';

    CAUS_ORDIN_ATTR	 CONSTANT varchar:='causaleOrdinativo';
    DATA_ESEC_PAG_ATTR	 CONSTANT varchar:='dataEsecuzionePagamento';


    TERMINE_PAG_DEF  CONSTANT integer=30;

    provvisorioId integer:=null;
    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;
    filePagoPaFileXMLId             varchar:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;

    docTipoId integer:=null;
    codBolloId integer:=null;
    dDocImporto numeric:=null;
    dispAccertamento numeric:=null;
	dispProvvisorioCassa numeric:=null;

    strElencoFlussi varchar:=null;
    docStatoValId   integer:=null;
    cdrTipoId integer:=null;
    cdcTipoId integer:=null;
    subDocTipoId integer:=null;
	movgestTipoId  integer:=null;
    movgestTsTipoId integer:=null;
    movgestStatoId integer:=null;
    provvisorioTipoId integer:=null;
	movgestTsDetTipoId integer:=null;
	dnumQuote integer:=0;
    movgestTsId integer:=null;
    subdocMovgestTsId integer:=null;

    annoBilancio integer:=null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

BEGIN

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale;
	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

    codiceRisultato:=0;
    messaggioRisultato:='';


    strMessaggio:='Verifica esistenza elaborazione.';
    --select elab.file_pagopa_id, elab.pagopa_elab_file_id into filePagoPaId, filePagoPaFileXMLId
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null
    and   elab.validita_fine  is null;

--	if filePagoPaId is null or filePagoPaFileXMLId is null then
    if codResult is null then
        pagoPaCodeErr:=PAGOPA_ERR_20;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
    else codResult:=null;
    end if;

/*  elaborazioni multi file
    if codResult is null then
     strMessaggio:='Verifica esistenza file di elaborazione per filePagoPaId='||filePagoPaId::varchar||
                   ' filePagoPaFileXMLId='||filePagoPaFileXMLId||'.';
     select 1 into codResult
     from siac_t_file_pagopa file, siac_d_file_pagopa_stato stato
     where file.file_pagopa_id=filePagoPaId
     and   file.file_pagopa_code=filePagoPaFileXMLId
     and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
     and   stato.ente_proprietario_id=enteProprietarioId
     and   file.data_cancellazione is null
     and   file.validita_fine  is null;

     if codResult is null then
    	pagoPaCodeErr:=PAGOPA_ERR_4;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
    end if;
*/


   if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoId
      from siac_d_doc_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_IPA;
      if docTipoId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      end if;
   end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo bollo esente.';
    	-- lettura tipodocumento
		select cod.codbollo_id into codBolloId
		from siac_d_codicebollo cod
		where cod.ente_proprietario_id=enteProprietarioId
		and   cod.codbollo_desc='ESENTE BOLLO';
        if codBolloId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_25;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo documento stato='||DOC_STATO_VALIDO||'.';
		select stato.doc_stato_id into docStatoValId
		from siac_d_doc_stato Stato
		where stato.ente_proprietario_id=enteProprietarioId
		and   stato.doc_stato_code=DOC_STATO_VALIDO;
        if docTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_26;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

    if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDC.';
		select tipo.classif_tipo_id into cdcTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDC';
        if cdcTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDR.';
		select tipo.classif_tipo_id into cdrTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDR';
        if cdrTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo subdocumento SE.';
		select tipo.subdoc_tipo_id into subDocTipoId
		from siac_d_subdoc_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.subdoc_tipo_code='SE';
        if subDocTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_28;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo accertamento.';
		select tipo.movgest_tipo_id into movgestTipoId
		from siac_d_movgest_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_tipo_code='A';
        if movgestTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo testata accertamento.';
		select tipo.movgest_ts_tipo_id into movgestTsTipoId
		from siac_d_movgest_ts_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_tipo_code='T';
        if movgestTsTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo stato DEFINITIVO accertamento.';
		select tipo.movgest_stato_id into movgestStatoId
		from siac_d_movgest_stato tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_stato_code='D';
        if movgestStatoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo ATTUALE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='A';
        if movgestTsDetTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;



	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo provvissorio cassa entrata.';
		select tipo.provc_tipo_id into provvisorioTipoId
		from siac_d_prov_cassa_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.provc_tipo_code='E';
        if provvisorioTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
     strMessaggio:='Gestione scarti di elaborazione. Verifica annoBilancio indicato su dettagli di riconciliazione.';
     select  distinct doc.pagopa_ric_doc_anno_esercizio into annoBilancio
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null
     limit 1;
     if annoBilancio is null then
       	pagoPaCodeErr:=PAGOPA_ERR_12;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else
     	if annoBilancio>annoBilancioElab then
           	pagoPaCodeErr:=PAGOPA_ERR_11;
	        strErrore:=' Anno bilancio successivo ad anno di elaborazione.';
    	    codResult:=-1;
        	bElabora:=false;
        end if;
     end if;
	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     if bilancioId is null then
     	pagoPaCodeErr:=PAGOPA_ERR_18;
        strErrore:=' Fase non ammessa per elaborazione.';
        codResult:=-1;
        bElabora:=false;
	 end if;
   end if;

   if codResult is null then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num per anno='||annoBilancio::varchar||'.';

      nProgressivo:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivo,
             docTipoId,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil
      where bil.bil_id=bilancioId
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=docTipoId
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      )
      returning doc_num_id into codResult;

      if codResult is null then
      	select num.doc_numero into codResult
        from siac_t_doc_num num
        where num.ente_proprietario_id=enteProprietarioId
        and   num.doc_anno::integer=annoBilancio
        and   num.doc_tipo_id=docTipoId;

        if codResult is not null then
        	nProgressivo:=codResult;
            codResult:=null;
        else
            pagoPaCodeErr:=PAGOPA_ERR_37;
        	strErrore:=' Progressivo non reperito.';
	        codResult:=-1;
    	    bElabora:=false;
        end if;
      else codResult:=null;
      end if;

   end if;

   if codResult is null then
    strMessaggio:='Gestione scarti di elaborazione. Inserimento siac_t_registrounico_doc_num per anno='||annoBilancio::varchar||'.';

	insert into  siac_t_registrounico_doc_num
    (
	  rudoc_registrazione_anno,
	  rudoc_registrazione_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select annoBilancio,
           0,
           clock_timestamp(),
           loginOperazione,
           bil.ente_proprietario_id
    from siac_t_bil bil
    where bil.bil_id=bilancioId
    and not exists
    (
    select 1
    from siac_t_registrounico_doc_num num
    where num.ente_proprietario_id=bil.ente_proprietario_id
    and   num.rudoc_registrazione_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
    );
   end if;



    -- gestione scarti
    -- provvisorio non esistente
    if codResult is null then

 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_22||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_22;
        strErrore:=' Provvisori di cassa non esistenti.';
     end if;
	 codResult:=null;
    end if;
--    raise notice 'strErrore=%',strErrore;

    --- provvisorio esistente , ma regolarizzato
    if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_38||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_ordinativo_prov_cassa rp
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   rp.provc_id=prov.provc_id
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     and   rp.data_cancellazione is null
     and   rp.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)=0 then
       update pagopa_t_riconciliazione_doc doc
       set    pagopa_ric_doc_stato_elab='X',
        	   pagopa_ric_errore_id=err.pagopa_ric_errore_id,
               data_modifica=clock_timestamp(),
               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   	   from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
	   where  flusso.pagopa_elab_id=filePagoPaElabId
       and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and    doc.pagopa_ric_doc_stato_elab='N'
       and    doc.pagopa_ric_doc_subdoc_id is null
       and    exists
       (
       select 1
       from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_subdoc_prov_cassa rp
       where tipo.ente_proprietario_id=doc.ente_proprietario_id
       and   tipo.provc_tipo_code='E'
       and   prov.provc_tipo_id=tipo.provc_tipo_id
       and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
       and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
       and   rp.provc_id=prov.provc_id
       and   prov.provc_data_annullamento is null
       and   prov.provc_data_regolarizzazione is null
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   rp.data_cancellazione is null
       and   rp.validita_fine is null
       )
       and    not exists -- esclusione flussi ( per provvisorio ) con scarti
       (
       select 1
       from pagopa_t_riconciliazione_doc doc1
       where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and   doc1.pagopa_ric_doc_stato_elab!='N'
       and   doc1.data_cancellazione is null
       and   doc1.validita_fine is null
       )
       and    err.ente_proprietario_id=flusso.ente_proprietario_id
       and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
       and    flusso.data_cancellazione is null
       and    flusso.validita_fine is null
       and    doc.data_cancellazione is null
       and    doc.validita_fine is null;
       GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_38;
        strErrore:=' Provvisori di cassa regolarizzati.';
     end if;
	 codResult:=null;
    end if;

    if codResult is null then
     -- accertamento non esistente
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_23||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from siac_t_movgest mov, siac_d_movgest_tipo tipo,
          siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
          siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.movgest_tipo_code='A'
     and   mov.movgest_tipo_id=tipo.movgest_tipo_id
     and   mov.bil_id=bilancioId
     and   ts.movgest_id=mov.movgest_id
     and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and   tipots.movgest_ts_tipo_code='T'
     and   rs.movgest_ts_id=ts.movgest_ts_id
     and   stato.movgest_stato_id=rs.movgest_stato_id
     and   stato.movgest_stato_code='D'
     and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
     and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_23
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0  then
     	pagoPaCodeErr:=PAGOPA_ERR_23;
        strErrore:=' Accertamenti non esistenti.';
     end if;
     codResult:=null;
   end if;

--   raise notice 'strErrore=%',strErrore;

   -- soggetto indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_34||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_codice_benef is not null
     and    not exists
     (
     select 1
     from siac_t_soggetto sog
     where sog.ente_proprietario_id=doc.ente_proprietario_id
     and   sog.soggetto_code=doc.pagopa_ric_doc_codice_benef
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_34
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_34;
        strErrore:=' Soggetto indicato non esistente.';
     end if;
     codResult:=null;
   end if;

   -- struttura amministrativa indicata non esistente indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_35||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    coalesce(doc.pagopa_ric_doc_str_amm,'')!=''
     and    not exists
     (
     select 1
     from siac_t_class c
     where c.ente_proprietario_id=doc.ente_proprietario_id
     and   c.classif_code=doc.pagopa_ric_doc_str_amm
     and   c.classif_tipo_id in (cdcTipoId,cdrTipoId)
     and   c.data_cancellazione is null
     and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine, date_trunc('DAY',now())))
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_35
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_35;
        strErrore:=' Struttura amministrativa indicata non esistente o non valida.';
     end if;
     codResult:=null;
   end if;


  ---  aggiornamento di pagopa_t_riconciliazione a partire da pagopa_t_riconciliazione_doc
  ---  per gli scarti prodotti in questa elaborazione
  if codResult is null then
   strMessaggio:='Gestione scarti di elaborazione. Aggiornamento pagopa_t_riconciliazione da pagopa_t_riconciliazione_doc.';

   update pagopa_t_riconciliazione ric
   set    pagopa_ric_flusso_stato_elab='X',
  	      pagopa_ric_errore_id=doc.pagopa_ric_errore_id,
          data_modifica=clock_timestamp(),
          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='X'
   and   doc.login_operazione like '%@ELAB-'|| filePagoPaElabId::varchar||'%'
   and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId --- per elab_id
   and   ric.pagopa_ric_id=doc.pagopa_ric_id;
  end if;
  ---

   if codResult is null then
     strMessaggio:='Verifica esistenza dettagli di riconciliazione da elaborare.';

--     raise notice 'strMessaggio=%',strMessaggio;
     select 1 into codresult
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null;
 --    raise notice 'codREsult=%',codResult;
     if codResult is null then
       	pagoPaCodeErr:=PAGOPA_ERR_7;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
   end if;



   if pagoPaCodeErr is not null then
     -- aggiornare anche pagopa_t_riconciliazione e pagopa_t_riconciliazione_doc
     strmessaggioBck:=strMessaggio;
     strMessaggio:=strMessaggio||' '||strErrore||' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=upper(strMessaggioFinale||' '||strMessaggio)
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=(case when bElabora=false then ELABORATO_ERRATO_ST else ELABORATO_IN_CORSO_SC_ST end)
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=pagoPaCodeErr
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;


     strMessaggio:=strmessaggioBck||' '||strErrore||' Aggiornamento siac_t_file_pagopa.';
     update siac_t_file_pagopa file
     set    data_modifica=clock_timestamp(),
            file_pagopa_stato_id=stato.file_pagopa_stato_id,
            file_pagopa_errore_id=err.pagopa_ric_errore_id,
            file_pagopa_note=upper(strMessaggioFinale||' '||strMessaggio),
            login_operazione=file.login_operazione||'-'||loginOperazione
        from  pagopa_r_elaborazione_file r,
              siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where r.pagopa_elab_id=filePagoPaElabId
        and   file.file_pagopa_id=r.file_pagopa_id
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaCodeErr
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

     if bElabora= false then
      codiceRisultato:=-1;
      messaggioRisultato:= upper(strMessaggioFinale||' '||strmessaggioBck||' '||strErrore||'.');
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_esegui - '||messaggioRisultato;
      insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      return;
     end if;
   end if;


  pagoPaCodeErr:=null;
  strMessaggio:='Inizio inserimento documenti.';
  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  raise notice 'strMessaggio=%',strMessaggio;
  for pagoPaFlussoRec in
  (
   with
   pagopa_sogg as
   (
   with
   pagopa as
   (
   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
		  doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
          doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
          doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and   doc.pagopa_ric_doc_subdoc_id is null
   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
   )
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   flusso.data_cancellazione is null
   and   flusso.validita_fine is null
   group by doc.pagopa_ric_doc_codice_benef,
			doc.pagopa_ric_doc_str_amm,
            doc.pagopa_ric_doc_voce_tematica,
            doc.pagopa_ric_doc_voce_code,
            doc.pagopa_ric_doc_voce_desc,
            doc.pagopa_ric_doc_anno_accertamento,
            doc.pagopa_ric_doc_num_accertamento
   ),
   sogg as
   (
   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
   from siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   sog.data_cancellazione is null
   and   sog.validita_fine is null
   )
   select pagopa.*,
          sogg.soggetto_id,
          sogg.soggetto_desc
   from pagopa
        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
   ),
   accertamenti_sogg as
   (
   with
   accertamenti as
   (
   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
           mov.movgest_id, ts.movgest_ts_id
    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code='D'
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
   ),
   soggetto_acc as
   (
   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   rsog.soggetto_id=sog.soggetto_id
   and   rsog.data_cancellazione is null
   and   rsog.validita_fine is null
   )
   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
   from   accertamenti , soggetto_acc
   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc
   order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
   			 pagopa_sogg.pagopa_str_amm,
             pagopa_sogg.pagopa_voce_tematica,
			 pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc
  )
  loop
   		-- filePagoPaElabId - elaborazione id
        -- filePagoPaId     - file pagopa id
        -- filePagoPaFileXMLId  - file pagopa id XML
        -- pagopa_soggetto_id
        -- pagopa_soggetto_code
        -- pagopa_voce_code
        -- pagopa_voce_desc
        -- pagopa_str_amm

        -- elementi per inserimento documento

        -- inserimento documento
        -- siac_t_doc ok
        -- siac_r_doc_sog ok
        -- siac_r_doc_stato ok
        -- siac_r_doc_class ok struttura amministrativa
        -- siac_r_doc_attr ok
        -- siac_t_registrounico_doc ok
        -- siac_t_subdoc_num ok

        -- siac_t_subdoc ok
        -- siac_r_subdoc_attr ok
        -- siac_r_subdoc_class -- non ce ne sono

        -- siac_r_subdoc_atto_amm ok
        -- siac_r_subdoc_movgest_ts ok
        -- siac_r_subdoc_prov_cassa ok

        dDocImporto:=0;
        strElencoFlussi:=' ';
        dnumQuote:=0;
        bErrore:=false;

		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].';
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
		docId:=null;
        nProgressivo:=nProgressivo+1;
		-- siac_t_doc
        insert into siac_t_doc
        (
        	doc_anno,
		    doc_numero,
			doc_desc,
		    doc_importo,
		    doc_data_emissione, -- dataElaborazione
			doc_data_scadenza,  -- dataSistema
		    doc_tipo_id,
		    codbollo_id,
		    validita_inizio,
		    ente_proprietario_id,
		    login_operazione,
		    login_creazione,
            login_modifica,
			pcccod_id, -- null ??
	        pccuff_id -- null ??
        )
        select annoBilancio,
               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivo::varchar,
               upper('Incassi '
               		 ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_tematica,' '),1,30)||' '
                     ||pagoPaFlussoRec.pagopa_voce_code||' '
                     ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_desc,' '),1,30) ||' '||strElencoFlussi),
			   dDocImporto,
               dataElaborazione,
               dataElaborazione,
			   docTipoId,
               codBolloId,
               clock_timestamp(),
               enteProprietarioId,
               loginOperazione,
               loginOperazione,
               loginOperazione,
               null,
               null
        returning doc_id into docId;
	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore=false then
		 codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_sog].';
		 -- siac_r_doc_sog
         insert into siac_r_doc_sog
         (
        	doc_id,
            soggetto_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select  docId,
                 pagoPaFlussoRec.pagopa_soggetto_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
         returning  doc_sog_id into codResult;

         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';

         end if;
        end if;

	    if bErrore=false then
         codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_stato].';
         insert into siac_r_doc_stato
         (
        	doc_id,
            doc_stato_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select docId,
                docStatoValId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         returning doc_stato_r_id into codResult;
		 if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
		end if;

        if bErrore=false then
         -- siac_r_doc_attr
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ANNO_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- anno_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    --annoBilancio::varchar,
                NULL,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ANNO_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then

	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||NUM_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- num_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=NUM_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||DATA_REPERTORIO_ATTR||' [siac_r_doc_attr].';
		 -- data_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
--        	    extract( 'day' from now())::varchar||'/'||
--               lpad(extract( 'month' from now())::varchar,2,'0')||'/'||
--               extract( 'year' from now())::varchar,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=DATA_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

        if bErrore=false then
		 -- registro_repertorio
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||REG_REPERTORIO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=REG_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- arrotondamento
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ARROTONDAMENTO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                0,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ARROTONDAMENTO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
         -- causale_sospensione
 		 -- data_sospensione
 		 -- data_riattivazione
   		 -- dataScadenzaDopoSospensione
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi sospensione [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (CAUS_SOSPENSIONE_ATTR,DATA_SOSPENSIONE_ATTR,DATA_RIATTIVAZIONE_ATTR/*,DATA_SCAD_SOSP_ATTR*/);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

        if bErrore=false then
		 -- terminepagamento
		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||TERMINE_PAG_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                TERMINE_PAG_DEF,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=TERMINE_PAG_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
	     -- notePagamentoIncasso
    	 -- dataOperazionePagamentoIncasso
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi pagamento incasso [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (NOTE_PAG_INC_ATTR,DATA_PAG_INC_ATTR);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

		if bErrore=false then
         -- flagAggiornaQuoteDaElenco
		 -- flagSenzaNumero
		 -- flagDisabilitaRegistrazioneResidui
		 -- flagPagataIncassata
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi flag [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            boolean,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                'N',
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (/*FL_AGG_QUOTE_ELE_ATTR,*/FL_SENZA_NUM_ATTR,FL_REG_RES_ATTR);--,FL_PAGATA_INC_ATTR);
         and   a.attr_code=FL_REG_RES_ATTR;

         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- codiceFiscalePignorato
		 -- dataRicezionePortale

		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi vari [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (COD_FISC_PIGN_ATTR,DATA_RIC_PORTALE_ATTR);
         and   a.attr_code=DATA_RIC_PORTALE_ATTR;
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;
        if bErrore=false then
		 -- siac_r_doc_class
         if coalesce(pagoPaFlussoRec.pagopa_str_amm ,'')!='' then
            strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDC.';

        	codResult:=null;
            select c.classif_id into codResult
            from siac_t_class c
            where c.classif_tipo_id=cdcTipoId
            and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
            and   c.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            if codResult is null then
                strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDR.';
	            select c.classif_id into codResult
    	        from siac_t_class c
        	    where c.classif_tipo_id=cdrTipoId
	           	and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
    	        and   c.data_cancellazione is null
        	    and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            end if;
            if codResult is not null then
               codResult1:=codResult;
               codResult:=null;
	           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class].';

            	insert into siac_r_doc_class
                (
                	doc_id,
                    classif_id,
                    validita_inizio,
                    login_operazione,
                    ente_proprietario_id
                )
                values
                (
                	docId,
                    codResult1,
                    clock_timestamp(),
                    loginOperazione,
                    enteProprietarioId
                )
                returning doc_classif_id into codResult;

                if codResult is null then
                	bErrore:=true;
		            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
                end if;
            end if;
         end if;
        end if;

		if bErrore =false then
		 --  siac_t_registrounico_doc
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento registro unico documento [siac_t_registrounico_doc].';

      	 codResult:=null;
         insert into siac_t_registrounico_doc
         (
        	rudoc_registrazione_anno,
 			rudoc_registrazione_numero,
			rudoc_registrazione_data,
			doc_id,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select num.rudoc_registrazione_anno,
                num.rudoc_registrazione_numero+1,
                clock_timestamp(),
                docId,
                loginOperazione,
                clock_timestamp(),
                num.ente_proprietario_id
         from siac_t_registrounico_doc_num num
         where num.ente_proprietario_id=enteProprietarioId
         and   num.rudoc_registrazione_anno=annoBilancio
         and   num.data_cancellazione is null
         and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
         returning rudoc_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
         if bErrore=false then
            codResult:=null;
         	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento registro unico documento [siac_t_registrounico_doc_num].';
         	update siac_t_registrounico_doc_num num
            set    rudoc_registrazione_numero=num.rudoc_registrazione_numero+1,
                   data_modifica=clock_timestamp()
        	where num.ente_proprietario_id=enteProprietarioId
	        and   num.rudoc_registrazione_anno=annoBilancio
         	and   num.data_cancellazione is null
	        and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
            returning num.rudoc_num_id into codResult;
            if codResult is null  then
               bErrore:=true;
               strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
         end if;
        end if;

		if bErrore =false then
         codResult:=null;
		 --  siac_t_doc_num
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento progressivi documenti [siac_t_doc_num].';
         update siac_t_doc_num num
         set    doc_numero=num.doc_numero+1,
         	    data_modifica=clock_timestamp()
         where  num.ente_proprietario_id=enteProprietarioid
         and    num.doc_anno=annoBilancio
         and    num.doc_tipo_id=docTipoId
         returning num.doc_num_id into codResult;
         if codResult is null then
         	 bErrore:=true;
             strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
         end if;
        end if;

        if bErrore=true then
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        end if;


		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento.';
        raise notice 'strMessaggio=%',strMessaggio;
		if bErrore=false then
			strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
	    end if;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

        for pagoPaFlussoQuoteRec in
  		(
  	     with
           pagopa_sogg as
		   (
           with
		   pagopa as
		   (
		   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
			      doc.pagopa_ric_doc_str_amm pagopa_str_amm,
                  doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
           		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                  doc.pagopa_ric_doc_sottovoce_code pagopa_sottovoce_code, doc.pagopa_ric_doc_sottovoce_desc pagopa_sottovoce_desc,
                  flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
                  flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio,
                  flusso.pagopa_elab_ric_flusso_id pagopa_flusso_id,
                  flusso.pagopa_elab_flusso_nome_mittente pagopa_flusso_nome_mittente,
        		  doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
		          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                  doc.pagopa_ric_doc_sottovoce_importo pagopa_sottovoce_importo
		   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
		   where flusso.pagopa_elab_id=filePagoPaElabId
		   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
           and   coalesce(doc.pagopa_ric_doc_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
           and   doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
           and   coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
           and   coalesce(doc.pagopa_ric_doc_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
		   and   doc.pagopa_ric_doc_stato_elab='N'
		   and   doc.pagopa_ric_doc_subdoc_id is null
		   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
		   (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		   )
		   and   doc.data_cancellazione is null
		   and   doc.validita_fine is null
		   and   flusso.data_cancellazione is null
		   and   flusso.validita_fine is null
		   ),
		   sogg as
		   (
			   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
			   from siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   sog.data_cancellazione is null
			   and   sog.validita_fine is null
		   )
		   select pagopa.*,
		          sogg.soggetto_id,
        		  sogg.soggetto_desc
		   from pagopa
		        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
		   ),
		   accertamenti_sogg as
		   (
             with
			 accertamenti as
			 (
			   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
		    	       mov.movgest_id, ts.movgest_ts_id
			    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
			         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
			         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
			    where tipo.ente_proprietario_id=enteProprietarioId
			    and   tipo.movgest_tipo_code='A'
			    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			    and   mov.bil_id=bilancioId
			    and   ts.movgest_id=mov.movgest_id
			    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			    and   tipots.movgest_ts_tipo_code='T'
			    and   rs.movgest_ts_id=ts.movgest_ts_id
			    and   stato.movgest_stato_id=rs.movgest_stato_id
			    and   stato.movgest_stato_code='D'
			    and   mov.data_cancellazione is null
			    and   mov.validita_fine is null
			    and   ts.data_cancellazione is null
			    and   ts.validita_fine is null
			    and   rs.data_cancellazione is null
			    and   rs.validita_fine is null
		   ),
		   soggetto_acc as
		   (
			   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
			   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   rsog.soggetto_id=sog.soggetto_id
			   and   rsog.data_cancellazione is null
			   and   rsog.validita_fine is null
		   )
		   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
		   from   accertamenti , soggetto_acc
		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id
	  	 )
		 select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   				 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc	,
                 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                 pagopa_sogg.pagopa_str_amm,
                 pagopa_sogg.pagopa_voce_tematica,
                 pagopa_sogg.pagopa_voce_code,  pagopa_sogg.pagopa_voce_desc,
                 pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                 pagopa_sogg.pagopa_flusso_id,
                 pagopa_sogg.pagopa_flusso_nome_mittente,
                 pagopa_sogg.pagopa_anno_provvisorio,
                 pagopa_sogg.pagopa_num_provvisorio,
                 pagopa_sogg.pagopa_anno_accertamento,
		         pagopa_sogg.pagopa_num_accertamento,
                 sum(pagopa_sogg.pagopa_sottovoce_importo) pagopa_sottovoce_importo
  	     from  pagopa_sogg, accertamenti_sogg
 	     where bErrore=false
         and   pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
	   	 and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
         and   (case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )=
	           pagoPaFlussoRec.pagopa_soggetto_id
	     group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
        	      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ),
                  pagopa_sogg.pagopa_str_amm,
                  pagopa_sogg.pagopa_voce_tematica,
                  pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                  pagopa_sogg.pagopa_flusso_id,pagopa_sogg.pagopa_flusso_nome_mittente,
                  pagopa_sogg.pagopa_anno_provvisorio,
                  pagopa_sogg.pagopa_num_provvisorio,
                  pagopa_sogg.pagopa_anno_accertamento,
		          pagopa_sogg.pagopa_num_accertamento
	     order by  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                   pagopa_sogg.pagopa_anno_provvisorio,
                   pagopa_sogg.pagopa_num_provvisorio,
				   pagopa_sogg.pagopa_anno_accertamento,
		           pagopa_sogg.pagopa_num_accertamento
  	   )
       loop

        codResult:=null;
        codResult1:=null;
        subdocId:=null;
        subdocMovgestTsId:=null;
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_t_subdoc].';
        raise notice 'strMessagio=%',strMessaggio;
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		-- siac_t_subdoc
        insert into siac_t_subdoc
        (
        	subdoc_numero,
			subdoc_desc,
			subdoc_importo,
--		    subdoc_nreg_iva,
	        subdoc_data_scadenza,
	        subdoc_convalida_manuale,
--	        subdoc_importo_da_dedurre,
--	        subdoc_splitreverse_importo,
--	        subdoc_pagato_cec,
--	        subdoc_data_pagamento_cec,
--	        contotes_id INTEGER,
--	        dist_id INTEGER,
--	        comm_tipo_id INTEGER,
	        doc_id,
	        subdoc_tipo_id,
--	        notetes_id INTEGER,
	        validita_inizio,
			ente_proprietario_id,
		    login_operazione,
	        login_creazione,
            login_modifica
        )
        values
        (
        	dnumQuote+1,
            upper('Voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' ' ),1,30)||
            pagoPaFlussoQuoteRec.pagopa_flusso_id||' PSP '||pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente||
            ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
            pagoPaFlussoQuoteRec.pagopa_num_provvisorio),
            pagoPaFlussoQuoteRec.pagopa_sottovoce_importo,
            dataElaborazione,
            'M', -- 13.12.2018 Sofia siac-6602
  			docId,
            subDocTipoId,
            clock_timestamp(),
            enteProprietarioId,
            loginOperazione,
            loginOperazione,
            loginOperazione
        )
        returning subdoc_id into subDocId;
        raise notice 'subdocId=%',subdocId;
        if subDocId is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- siac_r_subdoc_attr
		-- flagAvviso
		-- flagEsproprio
		-- flagOrdinativoManuale
		-- flagOrdinativoSingolo
		-- flagRilevanteIVA
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr vari].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            boolean,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               'N',
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code in
        (
         FL_AVVISO_ATTR,
	     FL_ESPROPRIO_ATTR,
	     FL_ORD_MANUALE_ATTR,
		 FL_ORD_SINGOLO_ATTR,
	     FL_RIL_IVA_ATTR
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if coalesce(codResult,0)=0 then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;

        end if;

		-- causaleOrdinativo
        /*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||CAUS_ORDIN_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               upper('Regolarizzazione incasso voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
	            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' '),1,30)||
    	        ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
        	    pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' '),
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=CAUS_ORDIN_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

		-- dataEsecuzionePagamento
    	/*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||DATA_ESEC_PAG_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               null,
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=DATA_ESEC_PAG_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

  	    -- controllo sfondamento e adeguamento accertamento
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica esistenza accertamento.';

		codResult:=null;
        dispAccertamento:=null;
        movgestTsId:=null;
        select ts.movgest_ts_id into movgestTsId
        from siac_t_movgest mov, siac_t_movgest_ts ts,
             siac_r_movgest_ts_stato rs
        where mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=movgestTipoId
        and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=movgestTsTipoId
        and   rs.movgest_ts_id=ts.movgest_ts_id
        and   rs.movgest_stato_id=movgestStatoId
        and   rs.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
        and   ts.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
        and   mov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())));

        if movgestTsId is not null then
       		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.';

	        select * into dispAccertamento
            from fnc_siac_disponibilitaincassaremovgest (movgestTsId) disponibilita;
		    raise notice 'dispAccertamento=%',dispAccertamento;
            if dispAccertamento is not null then
            	if dispAccertamento-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
		      		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.'
                         ||' Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'.';

                	update siac_t_movgest_ts_det det
                    set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                  (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                           data_modifica=clock_timestamp(),
                           login_operazione=det.login_operazione||'-'||loginOperazione
                    where det.movgest_ts_id=movgestTsId
                    and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                    and   det.data_cancellazione is null
                    and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                    returning det.movgest_ts_det_id into codResult;
                    if codResult is null then
                        bErrore:=true;
                        pagoPaCodeErr:=PAGOPA_ERR_31;
                    	strMessaggio:=strMessaggio||' Errore in adeguamento.';
                        continue;
                    end if;
                end if;
            else
            	bErrore:=true;
           		pagoPaCodeErr:=PAGOPA_ERR_31;
                strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' errore.';
	            continue;
            end if;
        else
            bErrore:=true;
            pagoPaCodeErr:=PAGOPA_ERR_31;
            strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' movgest_ts_id='||movgestTsId::varchar||' [siac_r_subdoc_movgest_ts].';
		-- siac_r_subdoc_movgest_ts
        insert into siac_r_subdoc_movgest_ts
        (
        	subdoc_id,
            movgest_ts_id,
            validita_inizio,
            login_Operazione,
            ente_proprietario_id
        )
        values
        (
               subdocId,
               movgestTsId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
        )
		returning subdoc_movgest_ts_id into codResult;
		if codResult is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;
		subdocMovgestTsId:=  codResult;
raise notice 'subdocMovgestTsId=%',subdocMovgestTsId;
        -- siac_r_subdoc_atto_amm
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_atto_amm].';
        insert into siac_r_subdoc_atto_amm
        (
        	subdoc_id,
            attoamm_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               atto.attoamm_id,
               clock_timestamp(),
               loginOperazione,
               atto.ente_proprietario_id
        from siac_r_subdoc_movgest_ts rts, siac_r_movgest_ts_atto_amm atto
        where rts.subdoc_movgest_ts_id=subdocMovgestTsId
        and   atto.movgest_ts_id=rts.movgest_ts_id
        and   atto.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',atto.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(atto.validita_fine,date_trunc('DAY',now())))
        returning subdoc_atto_amm_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- controllo esistenza e sfondamento disp. provvisorio
        codResult:=null;
        provvisorioId:=null;
        dispProvvisorioCassa:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa].';
        select prov.provc_id into provvisorioId
        from siac_t_prov_cassa prov
        where prov.provc_tipo_id=provvisorioTipoId
        and   prov.provc_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        and   prov.provc_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        and   prov.provc_data_annullamento is null
        and   prov.provc_data_regolarizzazione is null
        and   prov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',prov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(prov.validita_fine,date_trunc('DAY',now())));
        raise notice 'provvisorioId=%',provvisorioId;

        if provvisorioId is not null then
        	select 1 into codResult
            from siac_r_ordinativo_prov_cassa r
            where r.provc_id=provvisorioId
            and   r.data_cancellazione is null
            and   r.validita_fine is null;
            if codResult is null then
            	select 1 into codResult
	            from siac_r_subdoc_prov_cassa r
    	        where r.provc_id=provvisorioId
                and   r.login_operazione not like '%@PAGOPA-'||filePagoPaElabId::varchar||'%'
        	    and   r.data_cancellazione is null
            	and   r.validita_fine is null;
            end if;
            if codResult is not null then
            	pagoPaCodeErr:=PAGOPA_ERR_39;
	            bErrore:=true;
                strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' regolarizzato.';
       		    continue;
            end if;
        end if;
        if provvisorioId is not null then
           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::VARCHAR||'. Verifica disponibilita''.';
			select * into dispProvvisorioCassa
            from fnc_siac_daregolarizzareprovvisorio(provvisorioId) disponibilita;
            raise notice 'dispProvvisorioCassa=%',dispProvvisorioCassa;
            raise notice 'pagoPaFlussoQuoteRec.pagopa_sottovoce_importo=%',pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

            if dispProvvisorioCassa is not null then
            	if dispProvvisorioCassa-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                	pagoPaCodeErr:=PAGOPA_ERR_33;
		            bErrore:=true;
                    strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' disp. insufficiente.';
        		    continue;
                end if;
            else
            	pagoPaCodeErr:=PAGOPA_ERR_32;
	            bErrore:=true;
               strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' Errore.';

    	        continue;
            end if;
        else
        	pagoPaCodeErr:=PAGOPA_ERR_32;
            bErrore:=true;
            strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::varchar||'.';
		-- siac_r_subdoc_prov_cassa
        insert into siac_r_subdoc_prov_cassa
        (
        	subdoc_id,
            provc_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        VALUES
        (
               subdocId,
               provvisorioId,
               clock_timestamp(),
               loginOperazione||'@PAGOPA-'||filePagoPaElabId::varchar,
               enteProprietarioId
        )
        returning subdoc_provc_id into codResult;
        raise notice 'subdoc_provc_id=%',codResult;

        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end  if;

		codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione_doc per subdoc_id.';
        -- aggiornare pagopa_t_riconciliazione_doc
        update pagopa_t_riconciliazione_doc docUPD
        set    pagopa_ric_doc_subdoc_id=subdocId,
		       pagopa_ric_doc_stato_elab='S',
               pagopa_ric_errore_id=null,
               pagopa_ric_doc_movgest_ts_id=movgestTsId,
               pagopa_ric_doc_provc_id=provvisorioId,
               data_modifica=clock_timestamp(),
               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
        from
        (
         with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab='N'
     	    and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
        ) QUERY
        where docUPD.ente_proprietario_id=enteProprietarioId
        and   docUPD.pagopa_ric_doc_stato_elab='N'
        and   docUPD.pagopa_ric_doc_subdoc_id is null
        and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
        and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
        and   docUPD.data_cancellazione is null
        and   docUPD.validita_fine is null;
        GET DIAGNOSTICS codResult = ROW_COUNT;
		raise notice 'Aggiornati pagopa_t_riconciliazione_doc=%',codResult;
		if coalesce(codResult,0)=0 then
            raise exception ' Errore in aggiornamento.';
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione per subdoc_id.';
		codResult:=null;
        -- aggiornare pagopa_t_riconciliazione
        update pagopa_t_riconciliazione ric
        set    pagopa_ric_flusso_stato_elab='S',
			   pagopa_ric_errore_id=null,
               data_modifica=clock_timestamp(),
               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
		from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
        where flusso.pagopa_elab_id=filePagoPaElabId
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   doc.pagopa_ric_doc_subdoc_id=subdocId
        and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
        and   ric.pagopa_ric_id=doc.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
   		raise notice 'Aggiornati pagopa_t_riconciliazione=%',codResult;

--        returning ric.pagopa_ric_id into codResult;
		if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in aggiornamento.';
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
            insert into pagopa_t_elaborazione_log
            (
            pagopa_elab_id,
            pagopa_elab_file_id,
            pagopa_elab_log_operazione,
            ente_proprietario_id,
            login_operazione,
            data_creazione
            )
            values
            (
            filePagoPaElabId,
            null,
            strMessaggioLog,
            enteProprietarioId,
            loginOperazione,
            clock_timestamp()
            );


            continue;
        end if;

		dnumQuote:=dnumQuote+1;
        dDocImporto:=dDocImporto+pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

       end loop;

	   if dnumQuote>0 and bErrore=false then
        -- siac_t_subdoc_num
        codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento numero quote [siac_t_subdoc_num].';
 	    insert into siac_t_subdoc_num
        (
         doc_id,
         subdoc_numero,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        values
        (
         docId,
         dnumQuote,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
        )
        returning subdoc_num_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore =false then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento importo documento.';
        	update siac_t_doc doc
            set    doc_importo=dDocImporto
            where doc.doc_id=docId
            returning doc.doc_id into codResult;
            if codResult is null then
            	bErrore:=true;
            	strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
        end if;
       else
        -- non ha inserito quote
        if bErrore=false  then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote non effettuato.';
            bErrore:=true;
        end if;
       end if;



	   if bErrore=true then

    	 strMessaggioBck:=strMessaggio;
         strMessaggio:='Cancellazione dati documento inseriti.'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;
                  raise notice 'pagoPaCodeErr=%',pagoPaCodeErr;

		 if pagoPaCodeErr is null then
         	pagoPaCodeErr:=PAGOPA_ERR_30;
         end if;

         -- pulizia delle tabella pagopa_t_riconciliazione

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione S].'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;
  		 update pagopa_t_riconciliazione ric
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
   	     from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   ric.pagopa_ric_id=doc.pagopa_ric_id
         and   exists
         (
         select 1
         from pagopa_t_riconciliazione_doc doc1
         where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc1.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   doc1.pagopa_ric_id=ric.pagopa_ric_id
         and   doc1.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   doc1.validita_fine is null
         and   doc1.data_cancellazione is null
         )
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
         )
         values
         (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione N].'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

         strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc S].'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;

         update pagopa_t_riconciliazione_doc doc
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from pagopa_t_elaborazione_flusso flusso,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

	     strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc N].'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione_doc  docUPD
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_doc_stato_elab='N'
         and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

  		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_movgest_ts].'||strMessaggioBck;
         raise notice 'strMessaggio=%',strMessaggio;

         delete from siac_r_subdoc_movgest_ts r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_attr].'||strMessaggioBck;
         delete from siac_r_subdoc_attr r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_atto_amm].'||strMessaggioBck;
         delete from siac_r_subdoc_atto_amm r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_prov_cassa].'||strMessaggioBck;
         delete from siac_r_subdoc_prov_cassa r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc].'||strMessaggioBck;
         delete from siac_t_subdoc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_sog].'||strMessaggioBck;
         delete from siac_r_doc_sog doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_stato].'||strMessaggioBck;
         delete from siac_r_doc_stato doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_attr].'||strMessaggioBck;
         delete from siac_r_doc_attr doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_class].'||strMessaggioBck;
         delete from siac_r_doc_class doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_registrounico_doc].'||strMessaggioBck;
         delete from siac_t_registrounico_doc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc_num].'||strMessaggioBck;
         delete from siac_t_subdoc_num doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_doc].'||strMessaggioBck;
         delete from siac_t_doc doc where doc.doc_id=docId;

		 strMessaggioLog:=strMessaggioFinale||strMessaggio||' - Continue fnc_pagopa_t_elaborazione_riconc_esegui.';
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

       end if;


  end loop;


  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - Fine ciclo caricamento documenti - '||strMessaggioFinale;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  -- richiamare function per gestire anomalie e errori su provvisori e flussi in generale
  -- su elaborazione
  -- controllare ogni flusso/provvisorio
  strMessaggio:='Chiamata fnc.';
  select * into  fncRec
  from fnc_pagopa_t_elaborazione_riconc_esegui_clean
  (
    filePagoPaElabId,
    annoBilancioElab,
    enteProprietarioId,
    loginOperazione,
    dataElaborazione
  );
  if fncRec.codiceRisultato=0 then
    if fncRec.pagopaBckSubdoc=true then
    	pagoPaCodeErr:=PAGOPA_ERR_36;
    end if;
  else
  	raise exception '%',fncRec.messaggiorisultato;
  end if;

  -- aggiornare siac_t_registrounico_doc_num
  codResult:=null;
  strMessaggio:='Aggiornamento numerazione su siac_t_registrounico_doc_num.';
  update siac_t_registrounico_doc_num num
  set    rudoc_registrazione_numero= coalesce(QUERY.rudoc_registrazione_numero,0),
         data_modifica=clock_timestamp(),
         login_operazione=num.login_operazione||'-'||loginOperazione
  from
  (
   select max(doc.rudoc_registrazione_numero::integer) rudoc_registrazione_numero
   from  siac_t_registrounico_doc doc
   where doc.ente_proprietario_id=enteProprietarioId
   and   doc.rudoc_registrazione_anno::integer=annoBilancio
   and   doc.data_cancellazione is null
   and   date_trunc('DAY',now())>=date_trunc('DAY',doc.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(doc.validita_fine,date_trunc('DAY',now())))
  ) QUERY
  where num.ente_proprietario_id=enteProprietarioId
  and   num.rudoc_registrazione_anno=annoBilancio
  and   num.data_cancellazione is null
  and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())));
 -- returning num.rudoc_num_id into codResult;
  --if codResult is null then
  --	raise exception 'Errore in fase di aggiornamento.';
  --end if;



  -- chiusura della elaborazione, siac_t_file per errore in generazione per aggiornare pagopa_ric_errore_id
  if coalesce(pagoPaCodeErr,' ') in (PAGOPA_ERR_30,PAGOPA_ERR_31,PAGOPA_ERR_32,PAGOPA_ERR_33,PAGOPA_ERR_36,PAGOPA_ERR_39) then
     strMessaggio:=' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=elab.pagopa_elab_note
            ||' AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;



    strMessaggio:=' Aggiornamento siac_t_file_pagopa.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=stato.file_pagopa_stato_id,
           file_pagopa_errore_id=err.pagopa_ric_errore_id,
           file_pagopa_note=file.file_pagopa_note
                    ||' AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.',
           login_operazione=file.login_operazione||'-'||loginOperazione
    from  pagopa_r_elaborazione_file r,
          siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
    where r.pagopa_elab_id=filePagoPaElabId
    and   file.file_pagopa_id=r.file_pagopa_id
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   err.ente_proprietario_id=stato.ente_proprietario_id
    and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

  end if;

  strMessaggio:='Verifica dettaglio elaborati per chiusura pagopa_t_elaborazione.';
  codResult:=null;
  select 1 into codResult
  from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
  where flusso.pagopa_elab_id=filePagoPaElabId
  and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
  and   doc.pagopa_ric_doc_subdoc_id is not null
  and   doc.pagopa_ric_doc_stato_elab='S'
  and   flusso.data_cancellazione is null
  and   flusso.validita_fine is null
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null;
  -- ELABORATO_KO_ST ELABORATO_OK_SE
  if codResult is not null then
  	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_stato_elab in ('X','E','N')
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      -- se ci sono S e X,E,N KO
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_KO_ST;
      -- se si sono solo S OK
      else  pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;
  else -- se non esiste neanche un S allora elaborazione errata o scartata
	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_stato_elab='X'
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_SCARTATO_ST;
      else  pagoPaCodeErr:=ELABORATO_ERRATO_ST;
      end if;
  end if;

  strMessaggio:='Aggiornamento pagopa_t_elaborazione in stato='||pagoPaCodeErr||'.';
  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio);
  update pagopa_t_elaborazione elab
  set    data_modifica=clock_timestamp(),
  		 validita_fine=clock_timestamp(),
         pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
         pagopa_elab_note=strMessaggioFinale
  from  pagopa_d_elaborazione_stato statonew
  where elab.pagopa_elab_id=filePagoPaElabId
  and   statonew.ente_proprietario_id=elab.ente_proprietario_id
  and   statonew.pagopa_elab_stato_code=pagoPaCodeErr
  and   elab.data_cancellazione is null
  and   elab.validita_fine is null;

  strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa.';
  for elabRec in
  (
  select r.file_pagopa_id
  from pagopa_r_elaborazione_file r
  where r.pagopa_elab_id=filePagoPaElabId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  order by r.file_pagopa_id
  )
  loop

    -- chiusura per siac_t_file_pagopa
    -- capire se ho chiuso per bene pagopa_t_riconciliazione
    -- se esistono S Ok o in corso
    --    se esistono N non elaborati  IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC no chiusura
    --    se esistono E errati   IN_CORSO_ER no chiusura
    --    se non esistono!=S FINE ELABORATO_Ok con chiusura
    -- se non esistono S, in corso
    --    se esistono N IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC non chiusura
    --    se esistono E errati IN_CORSO_ER non chiusura
    strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa file_pagopa_id='||elabRec.file_pagopa_id::varchar||'.';
    codResult:=null;
    pagoPaCodeErr:=null;
    select 1 into codResult
    from  pagopa_t_riconciliazione ric
    where  ric.file_pagopa_id=elabRec.file_pagopa_id
    and   ric.pagopa_ric_flusso_stato_elab='S'
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is not null then
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab!='S'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is null then
          pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;

    else
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

    end if;

    if pagoPaCodeErr is not null then
       strMessaggio:='Aggiornamento siac_t_file_pagopa in stato='||pagoPaCodeErr||'.';
       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio);
       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
              login_operazione=file.login_operazione||'-'||loginOperazione
       from  siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
       where file.file_pagopa_id=elabRec.file_pagopa_id
       and   stato.ente_proprietario_id=file.ente_proprietario_id
       and   stato.file_pagopa_stato_code=pagoPaCodeErr;

    end if;

  end loop;

  messaggioRisultato:='OK VERIFICARE STATO ELAB. - '||upper(strMessaggioFinale);

  return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


-- 13.12.2018 Sofia - SIAC-6602 - fine



-- 18.12.2018 Sofia - SIAC-6609 - inizio
drop FUNCTION if exists siac.fnc_siac_dwh_accertamento 
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

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

-- 04.06.2018 Sofia siac-6220
v_FlagAttivaGsa VARCHAR := null;

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

-- 23.10.2018 Sofia jira SIAC-6336
v_programma_stato varchar:=null;
v_versione_cronop varchar:=null;
v_desc_cronop varchar:=null;
v_anno_cronop varchar:=null;
v_programma_id integer:=null;

v_user_table varchar;
params varchar;

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


select fnc_siac_random_user()
into	v_user_table;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_accertamento',
params,
clock_timestamp(),
v_user_table
);



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
--and tm.movgest_anno::integer=2015
--and tm.movgest_numero::integer=1901
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

-- 04.06.2018 Sofia siac-6220
v_FlagAttivaGsa  := null;


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
  ELSIF rec_attr.attr_code = 'FlagAttivaGsa' THEN
     v_FlagAttivaGsa := v_flag_attributo;
     --nuova sezione GSA 04.06.2018 Sofia siac-6220

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
      AND   dct.data_cancellazione IS NULL;
      -- 27.11.2018 Sofia siac-6573
--      AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
--      AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
--      AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

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
-- 23.10.2018 Sofia SIAC-6336
v_programma_stato:= null;
v_versione_cronop:=null;
v_desc_cronop:=null;
v_anno_cronop:=null;
v_programma_id:=null;

-- 23.10.2018 Sofia SIAC-6336
SELECT tp.programma_code, tp.programma_desc, stato.programma_stato_code, rmtp.programma_id
INTO   v_programma_code, v_programma_desc, v_programma_stato, v_programma_id
FROM   siac_r_movgest_ts_programma rmtp, siac_t_programma tp,
       siac_r_programma_stato rs, siac_d_programma_stato stato
WHERE  rmtp.movgest_ts_id = v_movgest_ts_id
AND    rmtp.programma_id = tp.programma_id
and    rs.programma_id=rmtp.programma_id
and    stato.programma_stato_id=rs.programma_stato_id
AND    p_data BETWEEN rmtp.validita_inizio and COALESCE(rmtp.validita_fine,p_data)
AND    p_data BETWEEN tp.validita_inizio and COALESCE(tp.validita_fine,p_data)
AND    p_data BETWEEN rs.validita_inizio and COALESCE(rs.validita_fine,p_data)
AND    rmtp.data_cancellazione IS NULL
AND    tp.data_cancellazione IS NULL
and    rs.data_cancellazione IS NULL;

-- 23.10.2018 Sofia SIAC-6336
if v_programma_id is not null then
	select cronop.cronop_code, cronop.cronop_desc, per.anno::integer
    into   v_versione_cronop, v_desc_cronop, v_anno_cronop
    from siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,siac_t_bil bil,siac_t_periodo per
    where cronop.programma_id=v_programma_id
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code='VA'
    and   bil.bil_id=cronop.bil_id
    and   per.periodo_id=bil.periodo_id
    and   per.anno::integer=p_anno_bilancio::integer
    AND   p_data BETWEEN rs.validita_inizio and COALESCE(rs.validita_fine,p_data)
    AND   p_data BETWEEN cronop.validita_inizio and COALESCE(cronop.validita_fine,p_data)
    and   rs.data_cancellazione is null
    and   cronop.data_cancellazione is null
    order by cronop.cronop_id desc
    limit 1;

end if;

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
flag_attiva_gsa, -- 04.06.2018 Sofia siac-6220
data_inizio_val_stato_accer,
data_inizio_val_accer,
data_creazione_accer,
data_modifica_accer,
cod_programma,
desc_programma,
-- 23.10.2018 Sofia jira siac-6336
stato_programma,
versione_cronop,
desc_cronop,
anno_cronop
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
          coalesce(v_FlagAttivaGsa,'N'), -- 04.06.2018 Sofia siac-6220
          v_data_inizio_val_stato_accer,
          v_data_inizio_val_accer,
          v_data_creazione_accer,
          v_data_modifica_accer,
          v_programma_code,
          v_programma_desc,
          -- 23.10.2018 Sofia jira siac-6336
		  v_programma_stato,
		  v_versione_cronop,
	      v_desc_cronop,
	      v_anno_cronop
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
flag_attiva_gsa, -- 04.06.2018 Sofia siac-6220
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
          coalesce(v_FlagAttivaGsa,'N'), -- 04.06.2018 Sofia siac-6220
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


update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico accertamenti (FNC_SIAC_DWH_ACCERTAMENTO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- 18.12.2018 Sofia - SIAC-6609 - fine

-- 18.12.2018 Sofia - SIAC-6610 - inizio

drop FUNCTION if exists siac.fnc_siac_dwh_soggetto (
  p_ente_proprietario_id integer,
  p_data timestamp
);

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

v_user_table varchar;
params varchar;
fnc_eseguita integer;

-- 05.12.2018 Sofia SIAC-6261
v_soggetto_tipo_fonte_durc varchar:=null;
v_soggetto_fonte_durc_automatica varchar:=null;
v_soggetto_note_durc varchar:=null;
v_soggetto_fine_validita_durc timestamp:=null;
v_soggetto_fonte_durc_manuale_code varchar:=null;
v_soggetto_fonte_durc_manuale_desc varchar:=null;

BEGIN

select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_soggetto';

if fnc_eseguita> 0 then

return;

else

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_soggetto',
params,
clock_timestamp(),
v_user_table
);

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
       ts.soggetto_desc,
       -- 05.12.2018 Sofia SIAC-6261
       ts.soggetto_tipo_fonte_durc,
       substring(ts.soggetto_fonte_durc_automatica from 1 for 500) soggetto_fonte_durc_automatica,
       substring(ts.soggetto_note_durc from 1 for 500) soggetto_note_durc,
       ts.soggetto_fine_validita_durc::timestamp soggetto_fine_validita_durc,
       ts.soggetto_fonte_durc_manuale_classif_id
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
order by ts.soggetto_id desc
--limit 3000
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

-- 05.12.2018 Sofia SIAC-6261
v_soggetto_tipo_fonte_durc:=null;
v_soggetto_fonte_durc_automatica:=null;
v_soggetto_note_durc:=null;
v_soggetto_fine_validita_durc:=null;
v_soggetto_fonte_durc_manuale_code:=null;
v_soggetto_fonte_durc_manuale_desc:=null;

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


-- 05.12.2018 Sofia SIAC-6261
v_soggetto_tipo_fonte_durc:=rec_soggetto_id.soggetto_tipo_fonte_durc;
v_soggetto_fonte_durc_automatica:=rec_soggetto_id.soggetto_fonte_durc_automatica;
v_soggetto_note_durc:=rec_soggetto_id.soggetto_note_durc;
v_soggetto_fine_validita_durc:=rec_soggetto_id.soggetto_fine_validita_durc;


if rec_soggetto_id.soggetto_fonte_durc_manuale_classif_id is not null then
	select c.classif_code, c.classif_desc
    into   v_soggetto_fonte_durc_manuale_code,v_soggetto_fonte_durc_manuale_desc
	from siac_t_class c, siac_d_class_tipo tipo
    where c.classif_id=rec_soggetto_id.soggetto_fonte_durc_manuale_classif_id
    and   tipo.classif_tipo_id=c.classif_tipo_id
    and   tipo.classif_tipo_code in ('CDC','CDR')
    and   c.data_cancellazione is null;

end if;


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
    soggetto_principale,
    -- 05.12.2018  Sofia Sofia SIAC-6261
    soggetto_tipo_fonte_durc,
    soggetto_fonte_durc_automatica,
    soggetto_note_durc,
    soggetto_fine_validita_durc,
    soggetto_fonte_durc_manuale_code,
    soggetto_fonte_durc_manuale_desc
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
          v_soggetto_principale,
          -- 05.12.2018  Sofia Sofia SIAC-6261
          v_soggetto_tipo_fonte_durc,
	      v_soggetto_fonte_durc_automatica,
	      v_soggetto_note_durc,
	      v_soggetto_fine_validita_durc,
	      v_soggetto_fonte_durc_manuale_code,
	      v_soggetto_fonte_durc_manuale_desc
         );

esito:= '  Fine ciclo soggetto - soggetto_id ('||v_soggetto_id||') - '||clock_timestamp();
return next;
END LOOP;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

end if;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico soggetto (FNC_SIAC_DWH_SOGGETTO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- 18.12.2018 Sofia - SIAC-6610 - fine

-- 18.12.2018 Sofia - SIAC-6608 - inizio

SELECT * from fnc_dba_add_column_params ('siac_dwh_capitolo_fpv', 'data_elaborazione' , 'TIMESTAMP WITHOUT TIME ZONE DEFAULT now()');

-- 18.12.2018 Sofia - SIAC-6608 - fine

