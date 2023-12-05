/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-6165 - Inizio

  
SELECT fnc_dba_add_column_params('siac_r_soggetto_stato', 'nota_operazione', 'VARCHAR(1000)');


-- SIAC-6165 - Fine

-- SIAC-6220 Sofia - Inizio
SELECT fnc_dba_add_column_params(
	'siac_dwh_accertamento', 
    'flag_attiva_gsa',
    'varchar(1)'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_subaccertamento', 
    'flag_attiva_gsa',
    'varchar(1)'
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
flag_attiva_gsa, -- 04.06.2018 Sofia siac-6220
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
          coalesce(v_FlagAttivaGsa,'N'), -- 04.06.2018 Sofia siac-6220
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

-- SIAC-6220 Sofia - Fine


-- SIAC-6197 - Maurizio - INIZIO

--le tabelle siac_t_report_importi e siac_s_report_importi devono poter accettare importi NULL
ALTER TABLE siac.siac_t_report_importi
  ALTER COLUMN repimp_importo DROP NOT NULL;
  
ALTER TABLE siac.siac_s_report_importi
  ALTER COLUMN repimps_importo DROP NOT NULL;
  
--Aggiornamento delle variabili esistenti antemponendo nella descrizione il codice e cambiando l'ordine di visualizzazione.
update siac_t_report_importi
set repimp_desc = 'A2) ' ||repimp_desc, repimp_progr_riga = 2
where repimp_codice ='fpv_ecc_ncf'
	and bil_id in ( select bil_id
					from siac_t_bil a, siac_t_periodo b
						where a.periodo_id= b.periodo_id
							and b.anno in('2018')--,'2017')
							and a.data_cancellazione IS NULL
							and b.data_cancellazione IS NULL)
	and repimp_id in (select c.repimp_id
						from siac_r_report_importi c, siac_t_report d
						where c.rep_id=d.rep_id
							and d.rep_codice ='BILR143'
							and c.data_cancellazione IS NULL
							and c.data_cancellazione IS NULL)
	and repimp_desc not like 'A2)%'
	and data_cancellazione IS NULL;
	
	
update siac_t_report_importi
set repimp_desc = 'A3) ' ||repimp_desc, repimp_progr_riga = 3
where repimp_codice ='fpv_epf'
	and bil_id in( select bil_id
					from siac_t_bil a, siac_t_periodo b
						where a.periodo_id= b.periodo_id
							and b.anno in('2018')--,'2017')
							and a.data_cancellazione IS NULL
							and b.data_cancellazione IS NULL)
	and repimp_id in (select c.repimp_id
						from siac_r_report_importi c, siac_t_report d
						where c.rep_id=d.rep_id
							and d.rep_codice ='BILR143'
							and c.data_cancellazione IS NULL
							and c.data_cancellazione IS NULL)
	and repimp_desc not like 'A3)%'
	and data_cancellazione IS NULL;

update siac_t_report_importi
set repimp_desc = 'G) ' ||repimp_desc, repimp_progr_riga = 4
where repimp_codice ='spazi_fin_acq'
	and bil_id in( select bil_id
					from siac_t_bil a, siac_t_periodo b
						where a.periodo_id= b.periodo_id
							and b.anno in('2018')--,'2017')
							and a.data_cancellazione IS NULL
							and b.data_cancellazione IS NULL)
	and repimp_id in (select c.repimp_id
						from siac_r_report_importi c, siac_t_report d
						where c.rep_id=d.rep_id
							and d.rep_codice ='BILR143'
							and c.data_cancellazione IS NULL
							and c.data_cancellazione IS NULL)
	and repimp_desc not like 'G)%'
	and data_cancellazione IS NULL;
	
update siac_t_report_importi
set repimp_desc = 'H4) ' ||repimp_desc, repimp_progr_riga = 6
where repimp_codice ='fondo_cont'
	and bil_id in( select bil_id
					from siac_t_bil a, siac_t_periodo b
						where a.periodo_id= b.periodo_id
							and b.anno in('2018')--,'2017')
							and a.data_cancellazione IS NULL
							and b.data_cancellazione IS NULL)
	and repimp_id in (select c.repimp_id
						from siac_r_report_importi c, siac_t_report d
						where c.rep_id=d.rep_id
							and d.rep_codice ='BILR143'
							and c.data_cancellazione IS NULL
							and c.data_cancellazione IS NULL)
	and repimp_desc not like 'H4)%'
	and data_cancellazione IS NULL;
	
update siac_t_report_importi
set repimp_desc = 'H5) ' ||repimp_desc, repimp_progr_riga = 7
where repimp_codice ='altri_acc'
	and bil_id in( select bil_id
					from siac_t_bil a, siac_t_periodo b
						where a.periodo_id= b.periodo_id
							and b.anno in('2018')--,'2017')
							and a.data_cancellazione IS NULL
							and b.data_cancellazione IS NULL)
	and repimp_id in (select c.repimp_id
						from siac_r_report_importi c, siac_t_report d
						where c.rep_id=d.rep_id
							and d.rep_codice ='BILR143'
							and c.data_cancellazione IS NULL
							and c.data_cancellazione IS NULL)
	and repimp_desc not like 'H5)%'
	and data_cancellazione IS NULL;
	
	
update siac_t_report_importi
set repimp_desc = 'L1) ' ||repimp_desc, repimp_progr_riga = 10
where repimp_codice ='spese_incr_att_fin'
	and bil_id in( select bil_id
					from siac_t_bil a, siac_t_periodo b
						where a.periodo_id= b.periodo_id
							and b.anno in('2018')--,'2017')
							and a.data_cancellazione IS NULL
							and b.data_cancellazione IS NULL)
	and repimp_id in (select c.repimp_id
						from siac_r_report_importi c, siac_t_report d
						where c.rep_id=d.rep_id
							and d.rep_codice ='BILR143'
							and c.data_cancellazione IS NULL
							and c.data_cancellazione IS NULL)
	and repimp_desc not like 'L1)%'
	and data_cancellazione IS NULL;
	
update siac_t_report_importi
set repimp_desc = 'L2) ' ||repimp_desc, repimp_progr_riga = 11
where repimp_codice ='fpv_part_fin'
	and bil_id in( select bil_id
					from siac_t_bil a, siac_t_periodo b
						where a.periodo_id= b.periodo_id
							and b.anno in('2018')--,'2017')
							and a.data_cancellazione IS NULL
							and b.data_cancellazione IS NULL)
	and repimp_id in (select c.repimp_id
						from siac_r_report_importi c, siac_t_report d
						where c.rep_id=d.rep_id
							and d.rep_codice ='BILR143'
							and c.data_cancellazione IS NULL
							and c.data_cancellazione IS NULL)
	and repimp_desc not like 'L2)%'
	and data_cancellazione IS NULL;
	

	
update siac_t_report_importi
set repimp_desc = 'M) ' ||repimp_desc, repimp_progr_riga = 12
where repimp_codice ='spazi_fin_ced'
	and bil_id in( select bil_id
					from siac_t_bil a, siac_t_periodo b
						where a.periodo_id= b.periodo_id
							and b.anno in('2018')--,'2017')
							and a.data_cancellazione IS NULL
							and b.data_cancellazione IS NULL)
	and repimp_id in (select c.repimp_id
						from siac_r_report_importi c, siac_t_report d
						where c.rep_id=d.rep_id
							and d.rep_codice ='BILR143'
							and c.data_cancellazione IS NULL
							and c.data_cancellazione IS NULL)
	and repimp_desc not like 'M)%'
	and data_cancellazione IS NULL;
	
--VARIABILI NUOVE
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_ent_spe_corr',
        'A1) Fondo pluriennale vincolato di entrata per spese correnti (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        1,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_ent_spe_corr');	
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_ent_spe_corr',
        'A1) Fondo pluriennale vincolato di entrata per spese correnti (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        1,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_ent_spe_corr');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_ent_spe_corr',
        'A1) Fondo pluriennale vincolato di entrata per spese correnti (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        1,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_ent_spe_corr');	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_parte_corr',
        'H2) Fondo pluriennale vincolato di parte corrente (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        5,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_parte_corr');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_parte_corr',
        'H2) Fondo pluriennale vincolato di parte corrente (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        5,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_parte_corr');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_parte_corr',
        'H2) Fondo pluriennale vincolato di parte corrente (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        5,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_parte_corr');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_conto_capit',
        'I2) Fondo pluriennale vincolato in c/capitale al netto delle quote finanziate da debito (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        8,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_conto_capit');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_conto_capit',
        'I2) Fondo pluriennale vincolato in c/capitale al netto delle quote finanziate da debito (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        8,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_conto_capit');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_conto_capit',
        'I2) Fondo pluriennale vincolato in c/capitale al netto delle quote finanziate da debito (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        8,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_conto_capit');	 
	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'altri_accanton',
        'I4) Altri accantonamenti (destinati a confluire nel risultato di amministrazione)',
        0,
        'N',
        9,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='altri_accanton');	  
	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'altri_accanton',
        'I4) Altri accantonamenti (destinati a confluire nel risultato di amministrazione)',
        0,
        'N',
        9,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='altri_accanton');	  
	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'altri_accanton',
        'I4) Altri accantonamenti (destinati a confluire nel risultato di amministrazione)',
        0,
        'N',
        9,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2018','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2018'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='altri_accanton');	  
      
--LEGAME TRA REPORT E IMPORTI.
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR143'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
to_date('01/01/2018','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice in ('fpv_ent_spe_corr', 'fpv_parte_corr', 
			'fpv_conto_capit', 'altri_accanton')
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id);	  
		      
			  
-- TABELLE BKO
update bko_t_report_importi
set repimp_desc='A2) Fondo pluriennale vincolato di entrata per partite finanziarie (dal 2020 quota finanziata da entrate finali)', repimp_progr_riga = 2
where repimp_codice='fpv_ecc_ncf'
	and rep_codice='BILR143';

update bko_t_report_importi
set repimp_desc='A3) Fondo pluriennale vincolato di entrata per partite finanziarie (dal 2020 quota finanziata da entrate finali)', repimp_progr_riga = 3
where repimp_codice='fpv_epf'
	and rep_codice='BILR143';
	
update bko_t_report_importi
set repimp_desc='G) SPAZI FINANZIARI ACQUISITI', repimp_progr_riga = 4
where repimp_codice='spazi_fin_acq'
	and rep_codice='BILR143';
	
update bko_t_report_importi
set repimp_desc='H4) Fondo contenzioso (destinato a confluire nel risultato di amministrazione)', repimp_progr_riga = 6
where repimp_codice='fondo_cont'
	and rep_codice='BILR143';
	
	
update bko_t_report_importi
set repimp_desc='H5) Altri accantonamenti (destinati a confluire nel risultato di amministrazione)', repimp_progr_riga = 7
where repimp_codice='altri_acc'
	and rep_codice='BILR143';
	
update bko_t_report_importi
set repimp_desc='L1) Titolo 3 - Spese per incremento di attività finanziaria al netto del fondo pluriennale vincolato', repimp_progr_riga = 10
where repimp_codice='spese_incr_att_fin'
	and rep_codice='BILR143';
	
update bko_t_report_importi
set repimp_desc='L2) Fondo pluriennale vincolato per partite finanziarie (dal 2020 quota finanziata da entrate finali)', repimp_progr_riga = 11
where repimp_codice='fpv_part_fin'
	and rep_codice='BILR143';
	
update bko_t_report_importi
set repimp_desc='M) SPAZI FINANZIARI CEDUTI', repimp_progr_riga = 12
where repimp_codice='spazi_fin_ced'
	and rep_codice='BILR143';
	
	
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
select 'BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'fpv_ent_spe_corr',
 'A1) Fondo pluriennale vincolato di entrata per spese correnti (dal 2020 quota finanziata da entrate finali)',
 0,
 'N',
 1
where  not exists (select 1
 from BKO_T_REPORT_IMPORTI a
 where a.rep_codice = 'BILR143'
 	and a.repimp_codice = 'fpv_ent_spe_corr');

INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
select 'BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'fpv_parte_corr',
 'H2) Fondo pluriennale vincolato di parte corrente (dal 2020 quota finanziata da entrate finali)',
 0,
 'N',
 5
where  not exists (select 1
 from BKO_T_REPORT_IMPORTI a
 where a.rep_codice = 'BILR143'
 	and a.repimp_codice = 'fpv_parte_corr');

INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
Select 'BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'fpv_conto_capit',
 'I2) Fondo pluriennale vincolato in c/capitale al netto delle quote finanziate da debito (dal 2020 quota finanziata da entrate finali)',
 0,
 'N',
 8
where  not exists (select 1
 from BKO_T_REPORT_IMPORTI a
 where a.rep_codice = 'BILR143'
 	and a.repimp_codice = 'fpv_conto_capit');

 
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
select 'BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'altri_accanton',
 'I4) Altri accantonamenti (destinati a confluire nel risultato di amministrazione)',
 0,
 'N',
 9
 where  not exists (select 1
 from BKO_T_REPORT_IMPORTI a
 where a.rep_codice = 'BILR143'
 	and a.repimp_codice = 'altri_accanton');
	

--modifica tabella di appoggio usata da BILR143_equilibri_di_finanza_pubblica_entrate
select fnc_dba_add_column_params(
'siac_rep_cap_ep_imp_riga2', 
'fpv_ent_conto_cap_anno',
'numeric');

select fnc_dba_add_column_params(
'siac_rep_cap_ep_imp_riga2', 
'fpv_ent_conto_cap_anno1',
'numeric');

select fnc_dba_add_column_params(
'siac_rep_cap_ep_imp_riga2', 
'fpv_ent_conto_cap_anno2',
'numeric');


--Aggiornamento procedure
DROP FUNCTION if exists siac."BILR143_equilibri_di_finanza_pubblica_entrate"(p_ente_prop_id integer, p_anno varchar, p_pluriennale varchar);

DROP FUNCTION if exists siac."BILR143_equilibri_di_finanza_pubblica_spese"(p_ente_prop_id integer, p_anno varchar, p_pluriennale varchar);

CREATE OR REPLACE FUNCTION siac."BILR143_equilibri_di_finanza_pubblica_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_pluriennale varchar = 'S'::character varying
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  fpv_ent_spese_corr_anno numeric,
  fpv_ent_spese_corr_anno1 numeric,
  fpv_ent_spese_corr_anno2 numeric,
  fpv_ent_conto_cap_anno numeric,
  fpv_ent_conto_cap_anno1 numeric,
  fpv_ent_conto_cap_anno2 numeric
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec varchar;
v_fam_titolotipologiacategoria varchar:='00003';

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
stanziamento_prev_cassa_anno:=0;
fpv_ent_spese_corr_anno=0;
fpv_ent_spese_corr_anno1=0;
fpv_ent_spese_corr_anno2=0;
fpv_ent_conto_cap_anno=0;
fpv_ent_conto_cap_anno1=0;
fpv_ent_conto_cap_anno2=0;

-- lettura della struttura di bilancio
-- impostazione dell'ente proprietario sulle classificazioni


select fnc_siac_random_user()
into	user_table;	


-- carico la struttura di bilancio
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;


insert into siac_rep_cap_ep
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code='CATEGORIA'
and ct.classif_tipo_id=cl.classif_tipo_id
and cl.classif_id=rc.classif_id
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno= p_anno
and bilancio.periodo_id=anno_eserc.periodo_id 
and e.bil_id=bilancio.bil_id 
and e.elem_tipo_id=tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code = elemTipoCode
and e.elem_id=rc.elem_id 
and e.data_cancellazione is null
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	in(	'STD')
--and	cat_del_capitolo.elem_cat_code	in(	'STD')
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());



insert into siac_rep_cap_ep
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 
 		siac_t_bil_elem e,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where  e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno= p_anno
and bilancio.periodo_id=anno_eserc.periodo_id 
and e.bil_id=bilancio.bil_id 
and e.elem_tipo_id=tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code = elemTipoCode
and e.data_cancellazione is null
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--31/05/2018: SIAC-6197 aggiunto anche FPVCC
and	cat_del_capitolo.elem_cat_code	in(	'FPVSC','FPVCC')
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());



--uso la tabella delle spese perche' ha in piu' il tipo_capitolo
insert into siac_rep_cap_up_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)  ,
            cat_del_capitolo.elem_cat_code tipologia_capitolo       
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno= p_anno 												
    	and	bilancio.periodo_id=anno_eserc.periodo_id 								
        and	capitolo.bil_id=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        --31/05/2018: SIAC-6197 aggiunto anche FPVCC
		and	cat_del_capitolo.elem_cat_code		in(	'STD','FPVSC','FPVCC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente,
    	cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga2
select  tb1.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
		tb1.importo 	as 		fpv_ent_spese_corr_anno,
    	tb2.importo 	as		fpv_ent_spese_corr_anno1,
    	tb3.importo		as		fpv_ent_spese_corr_anno2,
        tb1.ente_proprietario,
        user_table utente,
        0, 0, 0
from   
	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
	siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp 	--'STA';  -- competenza
                    	AND tb1.tipo_capitolo 		in ('FPVSC')
                    AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	
                    	AND tb2.tipo_capitolo 		in ('FPVSC')
                    AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	
                    	AND tb1.tipo_capitolo 		in ('FPVSC')
                    AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	--'STR'; -- residui
                    	AND tb4.tipo_capitolo 		in ('FPVSC')
                    AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui --'STI'; -- stanziamento residuo
                    	AND tb5.tipo_capitolo 		in ('FPVSC')
                    AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa --'SCA'; ----- previsioni di cassa
                    	AND tb6.tipo_capitolo 		in ('FPVSC')
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
         

insert into siac_rep_cap_ep_imp_riga2
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		residui_presunti,
    	tb5.importo		as		previsioni_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,
        0,
        0,
        tb1.ente_proprietario,
        user_table utente,
        0, 0, 0
from   
	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
	siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp 	--'STA';  -- competenza
                    	AND tb1.tipo_capitolo 		in ('STD')
                    AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	
                    	AND tb2.tipo_capitolo 		in ('STD')
                    AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	
                    	AND tb1.tipo_capitolo 		in ('STD')
                    AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	--'STR'; -- residui
                    	AND tb4.tipo_capitolo 		in ('STD')
                    AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui --'STI'; -- stanziamento residuo
                    	AND tb5.tipo_capitolo 		in ('STD')
                    AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa --'SCA'; ----- previsioni di cassa
                    	AND tb6.tipo_capitolo 		in ('STD')
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;    

--31/05/2018: SIAC-6197 aggiunto anche FPVCC
insert into siac_rep_cap_ep_imp_riga2
select  tb1.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        0, 0, 0,
        tb1.ente_proprietario,
        user_table utente,
		tb1.importo 	as 		fpv_ent_conto_cap_anno,
    	tb2.importo 	as		fpv_ent_conto_cap_anno1,
    	tb3.importo		as		fpv_ent_conto_cap_anno2
from   
	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
	siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp 	--'STA';  -- competenza
                    	AND tb1.tipo_capitolo 		in ('FPVCC')
                    AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	
                    	AND tb2.tipo_capitolo 		in ('FPVCC')
                    AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	
                    	AND tb1.tipo_capitolo 		in ('FPVCC')
                    AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	--'STR'; -- residui
                    	AND tb4.tipo_capitolo 		in ('FPVCC')
                    AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui --'STI'; -- stanziamento residuo
                    	AND tb5.tipo_capitolo 		in ('FPVCC')
                    AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa --'SCA'; ----- previsioni di cassa
                    	AND tb6.tipo_capitolo 		in ('FPVCC')
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;                    

for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3     				BIL_ELE_CODE3,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE(tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE(tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE(tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE(tb1.residui_presunti,0)			residui_presunti,    	
    	COALESCE(tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(tb1.fpv_ent_spese_corr_anno,0)	fpv_ent_spese_corr_anno,
        COALESCE(tb1.fpv_ent_spese_corr_anno1,0)	fpv_ent_spese_corr_anno1,
        COALESCE(tb1.fpv_ent_spese_corr_anno2,0)	fpv_ent_spese_corr_anno2,
        COALESCE(tb1.fpv_ent_conto_cap_anno,0)	fpv_ent_conto_cap_anno,
        COALESCE(tb1.fpv_ent_conto_cap_anno1,0)	fpv_ent_conto_cap_anno1,
        COALESCE(tb1.fpv_ent_conto_cap_anno2,0)	fpv_ent_conto_cap_anno2
from  	siac_rep_tit_tip_cat_riga_anni v1
			left  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table
                    )
            left	join    siac_rep_cap_ep_imp_riga2 tb1  
              on (tb1.elem_id	=	tb.elem_id
                  AND TB.utente=tb1.utente
                  and tb.utente=user_table)
    where v1.utente = user_table 
    		--and v1.titolo_code in('1','2','3','4','5')              
union 
select 	null    		titoloe_TIPO_DESC,
       	null              		titoloe_ID,
       	null             		titoloe_CODE,
       	null             		titoloe_DESC,
        null  			tipologia_TIPO_DESC,
       	null              	tipologia_ID,
       	null            	tipologia_CODE,
       	null           	tipologia_DESC,
       	null     		categoria_TIPO_DESC,
      	null              	categoria_ID,
       	null            	categoria_CODE,
        null            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3     				BIL_ELE_CODE3,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE(tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE(tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE(tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE(tb1.residui_presunti,0)			residui_presunti,
    	--COALESCE(tb1.previsioni_anno_prec,0)		previsioni_anno_prec,
    	COALESCE(tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(tb1.fpv_ent_spese_corr_anno,0)	fpv_ent_spese_corr_anno,
        COALESCE(tb1.fpv_ent_spese_corr_anno1,0)	fpv_ent_spese_corr_anno1,
        COALESCE(tb1.fpv_ent_spese_corr_anno2,0)	fpv_ent_spese_corr_anno2,
        COALESCE(tb1.fpv_ent_conto_cap_anno,0)	fpv_ent_conto_cap_anno,
        COALESCE(tb1.fpv_ent_conto_cap_anno1,0)	fpv_ent_conto_cap_anno1,
        COALESCE(tb1.fpv_ent_conto_cap_anno2,0)	fpv_ent_conto_cap_anno2
from  	siac_rep_cap_ep tb
            left	join    siac_rep_cap_ep_imp_riga2 tb1  
              on (tb1.elem_id	=	tb.elem_id
                  AND TB.utente=tb1.utente
                  and tb.utente=user_table)
    where tb.utente = user_table 
         and tb.classif_id is null
    		--and v1.titolo_code in('1','2','3','4','5')  	
loop

/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo
--raise notice 'elem_cat_code= %', classifBilRec.elem_cat_code;

titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
fpv_ent_spese_corr_anno =classifBilRec.fpv_ent_spese_corr_anno;
fpv_ent_conto_cap_anno =classifBilRec.fpv_ent_conto_cap_anno;
IF p_pluriennale = 'N' THEN
  stanziamento_prev_anno1:=0;
  stanziamento_prev_anno2:=0;
  fpv_ent_spese_corr_anno1=0;
  fpv_ent_spese_corr_anno2=0;
  fpv_ent_conto_cap_anno1=0;
  fpv_ent_conto_cap_anno2=0;
ELSE
  stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
  stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
  fpv_ent_spese_corr_anno1=classifBilRec.fpv_ent_spese_corr_anno1;
  fpv_ent_spese_corr_anno2=classifBilRec.fpv_ent_spese_corr_anno2;
  fpv_ent_conto_cap_anno1 =classifBilRec.fpv_ent_conto_cap_anno1;
  fpv_ent_conto_cap_anno2 =classifBilRec.fpv_ent_conto_cap_anno2;
END IF;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
residui_presunti:=classifBilRec.residui_presunti;

return next;

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
stanziamento_prev_cassa_anno:=0;
fpv_ent_spese_corr_anno=0;
fpv_ent_spese_corr_anno1=0;
fpv_ent_spese_corr_anno2=0;
fpv_ent_conto_cap_anno=0;
fpv_ent_conto_cap_anno1=0;
fpv_ent_conto_cap_anno2=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
delete from siac_rep_cap_ep where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_ep_imp_riga2 where utente=user_table;

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR143_equilibri_di_finanza_pubblica_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_pluriennale varchar = 'S'::character varying
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  fase_bilancio varchar,
  capitolo_prec integer,
  bil_ele_code3 varchar,
  piano_dei_conti varchar
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
TipoImpstanzresidui varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
esiste_siac_t_dicuiimpegnato_bilprev integer;
annoPrec varchar;
previsioni_anno_prec_cassa_app NUMERIC;
previsioni_anno_prec_comp_app NUMERIC; 
tipo_categ_capitolo varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
classif_tipo_code varchar;
classif_code varchar;
classif_tipo_code_padre varchar;
classif_code_padre varchar;


BEGIN

--raise notice '1: %', clock_timestamp()::varchar;

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
     
RTN_MESSAGGIO:='preparazione fase bilancio ''.';   


--raise notice '2: %', clock_timestamp()::varchar;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
piano_dei_conti='';

select fnc_siac_random_user()
into	user_table;

RTN_MESSAGGIO:='preparazione tabella siac_rep_mis_pro_tit_mac_riga_anni ''.';   


-- caricamento struttura del bilancio
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
    /* 07/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 07/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 
--raise notice '3: %', clock_timestamp()::varchar;
RTN_MESSAGGIO:='preparazione tabella siac_rep_cap_up ''.';   
insert into siac_rep_cap_up
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
    capitolo.elem_id						=	r_capitolo_stato.elem_id	and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')														
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


--10/05/2016: carico nella tabella di appoggio con i capitoli gli eventuali 
-- capitoli presenti sulla tabella con gli importi previsti anni precedenti
-- che possono avere cambiato numero di capitolo. 
insert into siac_rep_cap_up 
select programma.classif_id, macroaggr.classif_id, p_anno, NULL, prec.elem_code, prec.elem_code2, 
      	prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, NULL, user_table utente
      from siac_t_cap_u_importi_anno_prec prec,
        siac_d_class_tipo programma_tipo,
        siac_d_class_tipo macroaggr_tipo,
        siac_t_class programma,
        siac_t_class macroaggr
      where programma_tipo.classif_tipo_id	=	programma.classif_tipo_id
      and programma.classif_code=prec.programma_code
      and programma_tipo.classif_tipo_code	=	'PROGRAMMA'
      and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 	
      and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'
      and macroaggr.classif_code=prec.macroagg_code
      and programma.ente_proprietario_id =prec.ente_proprietario_id
      and macroaggr.ente_proprietario_id =prec.ente_proprietario_id
      and prec.ente_proprietario_id=p_ente_prop_id      
      AND prec.elem_cat_code	in ('STD','FPV','FSC','FPVC')		
      and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy')
		between programma.validita_inizio and
       COALESCE(programma.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
      and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy')
		between macroaggr.validita_inizio and
       COALESCE(macroaggr.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
      and not exists (select 1 from siac_rep_cap_up up
      				where up.elem_code=prec.elem_code
                    	AND up.elem_code2=prec.elem_code2
                        and up.elem_code3=prec.elem_code3
                        and up.macroaggregato_id = macroaggr.classif_id
                        and up.programma_id = programma.classif_id
                        and up.utente=user_table
                        and up.ente_proprietario_id=p_ente_prop_id);
                        
--raise notice '4: %', clock_timestamp()::varchar;

RTN_MESSAGGIO:='preparazione tabella siac_rep_cap_up_imp ''.';  

insert into siac_rep_cap_up_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo        
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno= p_anno 												
    	and	bilancio.periodo_id=anno_eserc.periodo_id 								
        and	capitolo.bil_id=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC', 'FPV','FPVC')								       
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


--raise notice '5: %', clock_timestamp()::varchar;
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga STD''.'; 
     
insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente 
        from 
        siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
         where			
    	tb1.elem_id	=	tb2.elem_id	        and 
        tb2.elem_id	=	tb3.elem_id	        and 
        tb3.elem_id	=	tb4.elem_id	        and 
        tb4.elem_id	=	tb5.elem_id	        and 
        tb5.elem_id	=	tb6.elem_id	        and
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp			and	tb1.tipo_capitolo 		in ('STD','FSC')
        AND
        tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp 		and	tb2.tipo_capitolo		in ('STD','FSC')
        and
        tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp		and	tb3.tipo_capitolo		in ('STD','FSC')		 
        and 
    	tb4.periodo_anno = tb1.periodo_anno AND	tb4.tipo_imp = 	TipoImpRes		and	tb4.tipo_capitolo		in ('STD','FSC')
        and 
    	tb5.periodo_anno = tb1.periodo_anno AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo	in ('STD','FSC')
        and 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa	and	tb6.tipo_capitolo		in ('STD','FSC')
        and tb1.utente 	= 	tb2.utente	
        and	tb2.utente	=	tb3.utente
        and	tb3.utente	=	tb4.utente
        and	tb4.utente	=	tb5.utente
        and tb5.utente	=	tb6.utente
        and	tb6.utente	=	user_table;    
     
            
 
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga FPV''.';  
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where		
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND 
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	IN ('FPV','FPVC')
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		IN ('FPV','FPVC')
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		IN ('FPV','FPVC')
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;
        

     RTN_MESSAGGIO:='insert tabella siac_rep_mptm_up_cap_importi''.';  

insert into siac_rep_mptm_up_cap_importi
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno,
        v1.ente_proprietario_id,
        user_table utente,
        tbprec.elem_id_old,
        '',
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			FULL  join siac_rep_cap_up tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_up_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id 
            			and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)	
            left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id and tbprec.data_cancellazione is null
        where v1.utente = user_table     
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;        
      

RTN_MESSAGGIO:='preparazione file output  ''.'; 

 for classifBilRec in
	select 	t1.missione_tipo_desc	missione_tipo_desc,
            t1.missione_code		missione_code,
            t1.missione_desc		missione_desc,
            t1.programma_tipo_desc	programma_tipo_desc,
            t1.programma_code		programma_code,
            t1.programma_desc		programma_desc,
            t1.titusc_tipo_desc		titusc_tipo_desc,
            t1.titusc_code			titusc_code,
            t1.titusc_desc			titusc_desc,
            t1.macroag_tipo_desc	macroag_tipo_desc,
            t1.macroag_code			macroag_code,
            t1.macroag_desc			macroag_desc,
            t1.bil_anno   			BIL_ANNO,
            t1.elem_code     		BIL_ELE_CODE,
            t1.elem_code2     		BIL_ELE_CODE2,
            t1.elem_code3			BIL_ELE_CODE3,
            t1.elem_desc     		BIL_ELE_DESC,
            t1.elem_desc2     		BIL_ELE_DESC2,
            t1.elem_id      		BIL_ELE_ID,
            t1.elem_id_padre    	BIL_ELE_ID_PADRE,
            COALESCE(t1.stanziamento_prev_anno,0)	stanziamento_prev_anno,
        	COALESCE(t1.stanziamento_prev_anno1,0)	stanziamento_prev_anno1,
        	COALESCE(t1.stanziamento_prev_anno2,0)	stanziamento_prev_anno2,
        	COALESCE(t1.stanziamento_prev_res_anno,0)	stanziamento_prev_res_anno,
        	COALESCE(t1.stanziamento_anno_prec,0)	stanziamento_anno_prec,
        	COALESCE(t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
            COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        	COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        	COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        	COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2,  
            COALESCE(classificazione.classif_code,'') classif_code
  		from      siac_rep_mptm_up_cap_importi t1
            left join ( select distinct t2.elem_id , t3.classif_code
                       FROM siac_r_bil_elem_class t2,
                             siac_t_class t3,
                             siac_d_class_tipo t4
                       where t2.classif_id=t3.classif_id 
                       and t4.classif_tipo_id=t3.classif_tipo_id
                       and t2.ente_proprietario_id=p_ente_prop_id
                       and t4.classif_tipo_code like 'PDC%'
                        and t2.data_cancellazione is NULL
                        and t3.data_cancellazione is NULL
                        and t4.data_cancellazione is NULL ) classificazione
            on t1.elem_id=classificazione.elem_id
        where t1.utente=user_table
        --05/06/2018 - SIAC-6197: aggiunto anche il titolo 3.
        	and t1.titusc_code in ('1','2','3')
        order by missione_code,programma_code,titusc_code,macroag_code,BIL_ELE_CODE,BIL_ELE_CODE2,BIL_ELE_CODE3   	
loop
	raise notice 'classif_code = %', classifBilRec.classif_code;
      missione_tipo_desc:= classifBilRec.missione_tipo_desc;
      missione_code:= classifBilRec.missione_code;
      missione_desc:= classifBilRec.missione_desc;
      programma_tipo_desc:= classifBilRec.programma_tipo_desc;
      programma_code:= classifBilRec.programma_code;
      programma_desc:= classifBilRec.programma_desc;
      titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
      titusc_code:= classifBilRec.titusc_code;
      titusc_desc:= classifBilRec.titusc_desc;
      macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
      macroag_code:= classifBilRec.macroag_code;
      macroag_desc:= classifBilRec.macroag_desc;
      bil_anno:=classifBilRec.bil_anno;
      bil_ele_code:=classifBilRec.bil_ele_code;
      bil_ele_desc:=classifBilRec.bil_ele_desc;
      bil_ele_code2:=classifBilRec.bil_ele_code2;
      bil_ele_code3:=classifBilRec.bil_ele_code3;
      bil_ele_desc2:=classifBilRec.bil_ele_desc2;
      bil_ele_id:=classifBilRec.bil_ele_id;
      bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
      bil_anno:=p_anno;
      stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
      stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno;
      IF p_pluriennale = 'N' THEN      
        stanziamento_prev_anno1:=0;
        stanziamento_prev_anno2:=0;
        stanziamento_fpv_anno1:=0; 
        stanziamento_fpv_anno2:=0;      
      ELSE
        stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
        stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2; 
        stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
        stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;           
      END IF;
      stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
      stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
      stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
                      
      piano_dei_conti=classifBilRec.classif_code;


      IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN    

        raise notice 'ID cap = %',    classifBilRec.BIL_ELE_ID;  
          
        select d_class_tipo.classif_tipo_code,t_class.classif_code, 
            d_class_tipo_padre.classif_tipo_code, t_class_padre.classif_code
          into classif_tipo_code, classif_code, 
                classif_tipo_code_padre, classif_code_padre
          from   siac_t_bil_elem t_bil_elem, 
          siac_r_bil_elem_class r_bil_elem_class, 
          siac_t_class t_class, 
          siac_d_class_tipo d_class_tipo,
          siac_r_class_fam_tree r_class_fam_tree,
          siac_t_class t_class_padre,
          siac_d_class_tipo d_class_tipo_padre
          where t_bil_elem.elem_id=r_bil_elem_class.elem_id
              AND r_bil_elem_class.classif_id= t_class.classif_id
              AND t_class.classif_tipo_id  = d_class_tipo.classif_tipo_id
              AND r_class_fam_tree.classif_id= t_class.classif_id
              AND r_class_fam_tree.classif_id_padre= t_class_padre.classif_id
              AND t_class_padre.classif_tipo_id  = d_class_tipo_padre.classif_tipo_id
              AND t_bil_elem.elem_id= classifBilRec.BIL_ELE_ID
              and d_class_tipo.classif_tipo_code like 'PDC%'
              and t_bil_elem.data_cancellazione IS NULL
              AND r_bil_elem_class.data_cancellazione IS NULL
              AND t_class.data_cancellazione IS NULL
              AND d_class_tipo.data_cancellazione IS NULL
              AND r_class_fam_tree.data_cancellazione IS NULL
              AND t_class_padre.data_cancellazione IS NULL
              AND d_class_tipo_padre.data_cancellazione IS NULL;

            IF  classif_tipo_code = 'PDC_IV' THEN
                piano_dei_conti=classif_code;
            ELSE    
                piano_dei_conti=classif_code_padre;
            END IF;
      END IF;


	return next;
    
    bil_anno='';
    missione_tipo_code='';
    missione_tipo_desc='';
    missione_code='';
    missione_desc='';
    programma_tipo_code='';
    programma_tipo_desc='';
    programma_code='';
    programma_desc='';
    titusc_tipo_code='';
    titusc_tipo_desc='';
    titusc_code='';
    titusc_desc='';
    macroag_tipo_code='';
    macroag_tipo_desc='';
    macroag_code='';
    macroag_desc='';
    bil_ele_code='';
    bil_ele_desc='';
    bil_ele_code2='';
    bil_ele_code3='';
    bil_ele_desc2='';
    bil_ele_id=0;
    bil_ele_id_padre=0;
    stanziamento_prev_res_anno=0;
    stanziamento_anno_prec=0;
    stanziamento_prev_cassa_anno=0;
    stanziamento_prev_anno=0;
    stanziamento_prev_anno1=0;
    stanziamento_prev_anno2=0;
    stanziamento_fpv_anno_prec=0;
    stanziamento_fpv_anno=0;
    stanziamento_fpv_anno1=0;
    stanziamento_fpv_anno2=0;

	piano_dei_conti='';
    
end loop;
--end if;

--raise notice '11: %', clock_timestamp()::varchar;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_up where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;


--raise notice '12: %', clock_timestamp()::varchar;

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
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


-- SIAC-6197 - Maurizio - FINE


-- SIAC-6234 - Maurizio - INIZIO

update siac_t_voce_conf_indicatori_sint 
set voce_conf_ind_decimali=2
where voce_conf_ind_codice='giorni_effett_rnd';

-- SIAC-6234 - Maurizio - FINE