/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5582 - INIZIO

INSERT INTO siac_t_attr (attr_code, attr_desc, attr_tipo_id, tabella_nome, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.attr_tipo_id, null, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_attr_tipo dat ON dat.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES('FlagAccertatoPerCassa', 'FlagAccertatoPerCassa')) AS tmp(code, descr)
WHERE tep.data_cancellazione IS NULL
AND dat.attr_tipo_code = 'B'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_attr ta
	WHERE ta.attr_tipo_id = dat.attr_tipo_id
	AND ta.ente_proprietario_id = tep.ente_proprietario_id
	AND ta.attr_code = tmp.code
);

ALTER TABLE siac_dwh_capitolo_entrata ADD COLUMN flagaccertatopercassa varchar(1);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_capitolo_entrata (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

  rec_elem_id record;
  rec_classif_id record;
  rec_attr record;
  rec_elem_dett record;
  -- Variabili per campi estratti dal cursore rec_elem_id
  v_ente_proprietario_id INTEGER := null;
  v_ente_denominazione VARCHAR := null;
  v_anno VARCHAR := null;
  v_fase_operativa_code VARCHAR := null;
  v_fase_operativa_desc VARCHAR := null;
  v_elem_code VARCHAR := null;
  v_elem_code2 VARCHAR := null;
  v_elem_code3 VARCHAR := null;
  v_elem_desc VARCHAR := null;
  v_elem_desc2 VARCHAR := null;
  v_elem_tipo_code VARCHAR := null;
  v_elem_tipo_desc VARCHAR := null;
  v_elem_stato_code VARCHAR := null;
  v_elem_stato_desc VARCHAR := null;
  v_elem_cat_code VARCHAR := null;
  v_elem_cat_desc VARCHAR := null;
  -- Variabili per classificatori in gerarchia
  v_codice_titolo_entrata VARCHAR := null;
  v_descrizione_titolo_entrata VARCHAR := null;
  v_codice_tipologia_entrata VARCHAR := null;
  v_descrizione_tipologia_entrata VARCHAR := null;
  v_codice_categoria_entrata VARCHAR := null;
  v_descrizione_categoria_entrata VARCHAR := null;
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
  v_codice_cofog_divisione VARCHAR := null;
  v_descrizione_cofog_divisione VARCHAR := null;
  v_codice_cofog_gruppo VARCHAR := null;
  v_descrizione_cofog_gruppo VARCHAR := null;
  v_codice_cdr VARCHAR := null;
  v_descrizione_cdr VARCHAR := null;
  v_codice_cdc VARCHAR := null;
  v_descrizione_cdc VARCHAR := null;
  v_codice_siope_I_entrata VARCHAR := null;
  v_descrizione_siope_I_entrata VARCHAR := null;
  v_codice_siope_II_entrata VARCHAR := null;
  v_descrizione_siope_II_entrata VARCHAR := null;
  v_codice_siope_III_entrata VARCHAR := null;
  v_descrizione_siope_III_entrata VARCHAR := null;
  -- Variabili per classificatori non in gerarchia
  v_codice_entrata_ricorrente VARCHAR := null;
  v_descrizione_entrata_ricorrente VARCHAR := null;
  v_codice_transazione_entrata_ue VARCHAR := null;
  v_descrizione_transazione_entrata_ue VARCHAR := null;
  v_codice_tipo_fondo VARCHAR := null;
  v_descrizione_tipo_fondo VARCHAR := null;
  v_codice_tipo_finanziamento VARCHAR := null;
  v_descrizione_tipo_finanziamento VARCHAR := null;
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
  v_classificatore_generico_6 VARCHAR := null;
  v_classificatore_generico_6_descrizione_valore VARCHAR := null;
  v_classificatore_generico_6_valore VARCHAR := null;
  v_classificatore_generico_7 VARCHAR := null;
  v_classificatore_generico_7_descrizione_valore VARCHAR := null;
  v_classificatore_generico_7_valore VARCHAR := null;
  v_classificatore_generico_8 VARCHAR := null;
  v_classificatore_generico_8_descrizione_valore VARCHAR := null;
  v_classificatore_generico_8_valore VARCHAR := null;
  v_classificatore_generico_9 VARCHAR := null;
  v_classificatore_generico_9_descrizione_valore VARCHAR := null;
  v_classificatore_generico_9_valore VARCHAR := null;
  v_classificatore_generico_10 VARCHAR := null;
  v_classificatore_generico_10_descrizione_valore VARCHAR := null;
  v_classificatore_generico_10_valore VARCHAR := null;
  v_classificatore_generico_11 VARCHAR := null;
  v_classificatore_generico_11_descrizione_valore VARCHAR := null;
  v_classificatore_generico_11_valore VARCHAR := null;
  v_classificatore_generico_12 VARCHAR := null;
  v_classificatore_generico_12_descrizione_valore VARCHAR := null;
  v_classificatore_generico_12_valore VARCHAR := null;
  v_classificatore_generico_13 VARCHAR := null;
  v_classificatore_generico_13_descrizione_valore VARCHAR := null;
  v_classificatore_generico_13_valore VARCHAR:= null;
  v_classificatore_generico_14 VARCHAR := null;
  v_classificatore_generico_14_descrizione_valore VARCHAR := null;
  v_classificatore_generico_14_valore VARCHAR := null;
  v_classificatore_generico_15 VARCHAR := null;
  v_classificatore_generico_15_descrizione_valore VARCHAR := null;
  v_classificatore_generico_15_valore VARCHAR := null;
  -- Variabili per attributi
  v_FlagEntrateRicorrenti VARCHAR := null;
  v_FlagImpegnabile VARCHAR := null;
  v_FlagPerMemoria VARCHAR := null;
  v_FlagRilevanteIva VARCHAR := null;
  v_FlagTrasferimentoOrganiComunitari VARCHAR := null;
  v_Note VARCHAR := null;
  v_FlagAccertatoPerCassa VARCHAR := null;
  -- Variabili per stipendio
  v_codice_stipendio VARCHAR := null;
  v_descrizione_stipendio VARCHAR := null;
  -- Variabili per attivita'� iva
  v_codice_attivita_iva VARCHAR := null;
  v_descrizione_attivita_iva VARCHAR := null;
  -- Variabili per i campi di detaglio degli elementi
  v_massimo_impegnabile_anno1 NUMERIC := null;
  v_stanziamento_cassa_anno1 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno1  NUMERIC := null;
  v_stanziamento_anno1 NUMERIC := null;
  v_stanziamento_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_anno1  NUMERIC := null;
  v_flag_anno1 VARCHAR := null;
  v_massimo_impegnabile_anno2 NUMERIC := null;
  v_stanziamento_cassa_anno2 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno2 NUMERIC := null;
  v_stanziamento_anno2 NUMERIC := null;
  v_stanziamento_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_anno2 NUMERIC := null;
  v_flag_anno2 VARCHAR := null;
  v_massimo_impegnabile_anno3 NUMERIC := null;
  v_stanziamento_cassa_anno3 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno3 NUMERIC := null;
  v_stanziamento_anno3 NUMERIC := null;
  v_stanziamento_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_anno3 NUMERIC := null;
  v_flag_anno3 VARCHAR := null;
  -- Variabili per campi funzione
  v_disponibilita_accertare_anno1 NUMERIC := null;
  v_disponibilita_accertare_anno2 NUMERIC := null;
  v_disponibilita_accertare_anno3 NUMERIC := null;
  -- Variabili utili per il caricamento
  v_classif_code VARCHAR := null;
  v_classif_desc VARCHAR := null;
  v_classif_tipo_code VARCHAR := null;
  v_classif_tipo_desc VARCHAR :=null;
  v_elem_id INTEGER := null;
  v_classif_id INTEGER := null;
  v_classif_id_part INTEGER := null;
  v_classif_id_padre INTEGER := null;
  v_classif_tipo_id INTEGER := null;
  v_classif_fam_id INTEGER := null;
  v_conta_ciclo_classif INTEGER := null;
  v_anno_elem_dett INTEGER := null;
  v_anno_appo INTEGER := null;
  v_flag_attributo VARCHAR := null;
  v_bil_id INTEGER := null;

  v_fnc_result VARCHAR := null;

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

esito:= 'Inizio funzione carico capitoli di entrata (FNC_SIAC_DWH_CAPITOLO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_capitolo_entrata
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre gli elementi
FOR rec_elem_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tbe.elem_code, tbe.elem_code2, tbe.elem_code3, tbe.elem_desc, tbe.elem_desc2, dbet.elem_tipo_code, dbet.elem_tipo_desc,
       dbes.elem_stato_code, dbes.elem_stato_desc, dbec.elem_cat_code, dbec.elem_cat_desc,
       tbe.elem_id,  tb.bil_id
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tb.periodo_id = tp.periodo_id
INNER JOIN siac.siac_t_ente_proprietario tep ON tb.ente_proprietario_id = tep.ente_proprietario_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
LEFT JOIN  siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
                                               AND p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
                                               AND rbec.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
                                              AND p_data BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, p_data)
                                              AND dbec.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
AND dbet.elem_tipo_code in ('CAP-EG', 'CAP-EP')  
AND p_data BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, p_data)
AND tbe.data_cancellazione IS NULL
AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
AND tb.data_cancellazione IS NULL
AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND tp.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, p_data)
AND dbet.data_cancellazione IS NULL
AND p_data BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, p_data)
AND rbes.data_cancellazione IS NULL
AND p_data BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, p_data)
AND dbes.data_cancellazione IS NULL

LOOP
v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_anno := null;
v_fase_operativa_code := null;
v_fase_operativa_desc := null;
v_elem_code := null;
v_elem_code2 := null;
v_elem_code3 := null;
v_elem_desc := null;
v_elem_desc2 := null;
v_elem_tipo_code := null;
v_elem_tipo_desc := null;
v_elem_stato_code := null;
v_elem_stato_desc := null;
v_elem_cat_code := null;
v_elem_cat_desc := null;

v_elem_id := null;
v_classif_id := null;
v_classif_tipo_id := null;
v_bil_id := null; 

v_ente_proprietario_id := rec_elem_id.ente_proprietario_id;
v_ente_denominazione := rec_elem_id.ente_denominazione;
v_anno := rec_elem_id.anno;
v_elem_code := rec_elem_id.elem_code;
v_elem_code2 := rec_elem_id.elem_code2;
v_elem_code3 := rec_elem_id.elem_code3;
v_elem_desc := rec_elem_id.elem_desc;
v_elem_desc2 := rec_elem_id.elem_desc2;
v_elem_tipo_code := rec_elem_id.elem_tipo_code;
v_elem_tipo_desc := rec_elem_id.elem_tipo_desc;
v_elem_stato_code := rec_elem_id.elem_stato_code;
v_elem_stato_desc := rec_elem_id.elem_stato_desc;
v_elem_cat_code := rec_elem_id.elem_cat_code;
v_elem_cat_desc := rec_elem_id.elem_cat_desc;

v_elem_id := rec_elem_id.elem_id;
v_anno_appo := rec_elem_id.anno::integer;
v_bil_id := rec_elem_id.bil_id;

-- Sezione per estrarre i classificatori
v_codice_titolo_entrata := null;
v_descrizione_titolo_entrata := null;
v_codice_tipologia_entrata := null;
v_descrizione_tipologia_entrata := null;
v_codice_categoria_entrata := null;
v_descrizione_categoria_entrata := null;
v_codice_pdc_finanziario_I := null;
v_descrizione_pdc_finanziario_I := null;
v_codice_pdc_finanziario_II := null;
v_descrizione_pdc_finanziario_II := null;
v_codice_pdc_finanziario_III := null;
v_descrizione_pdc_finanziario_III := null;
v_codice_pdc_finanziario_IV := null;
v_descrizione_pdc_finanziario_IV := null;
v_codice_pdc_finanziario_V := null;
v_descrizione_pdc_finanziario_V := null;
v_codice_cofog_divisione := null;
v_descrizione_cofog_divisione := null;
v_codice_cofog_gruppo := null;
v_descrizione_cofog_gruppo := null;
v_codice_cdr := null;
v_descrizione_cdr := null;
v_codice_cdc := null;
v_descrizione_cdc := null;
v_codice_siope_I_entrata := null;
v_descrizione_siope_I_entrata := null;
v_codice_siope_II_entrata := null;
v_descrizione_siope_II_entrata := null;
v_codice_siope_III_entrata := null;
v_descrizione_siope_III_entrata := null;

v_codice_entrata_ricorrente := null;
v_descrizione_entrata_ricorrente := null;
v_codice_transazione_entrata_ue := null;
v_descrizione_transazione_entrata_ue := null;
v_codice_tipo_fondo := null;
v_descrizione_tipo_fondo := null;
v_codice_tipo_finanziamento := null;
v_descrizione_tipo_finanziamento := null;
v_codice_perimetro_sanitario_entrata := null;
v_descrizione_perimetro_sanitario_entrata := null;
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
v_classificatore_generico_6:= null;
v_classificatore_generico_6_descrizione_valore:= null;
v_classificatore_generico_6_valore:= null;
v_classificatore_generico_7:= null;
v_classificatore_generico_7_descrizione_valore:= null;
v_classificatore_generico_7_valore:= null;
v_classificatore_generico_8:= null;
v_classificatore_generico_8_descrizione_valore:= null;
v_classificatore_generico_8_valore:= null;
v_classificatore_generico_9:= null;
v_classificatore_generico_9_descrizione_valore:= null;
v_classificatore_generico_9_valore:= null;
v_classificatore_generico_10:= null;
v_classificatore_generico_10_descrizione_valore:= null;
v_classificatore_generico_10_valore:= null;
v_classificatore_generico_11:= null;
v_classificatore_generico_11_descrizione_valore:= null;
v_classificatore_generico_11_valore:= null;
v_classificatore_generico_12:= null;
v_classificatore_generico_12_descrizione_valore:= null;
v_classificatore_generico_12_valore:= null;
v_classificatore_generico_13:= null;
v_classificatore_generico_13_descrizione_valore:= null;
v_classificatore_generico_13_valore:= null;
v_classificatore_generico_14:= null;
v_classificatore_generico_14_descrizione_valore:= null;
v_classificatore_generico_14_valore:= null;
v_classificatore_generico_15:= null;
v_classificatore_generico_15_descrizione_valore:= null;
v_classificatore_generico_15_valore:= null;
esito:= '  Inizio ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
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
-- Ciclo per estrarre i classificatori relativi ad un dato elemento
FOR rec_classif_id IN
SELECT tc.classif_id, tc.classif_tipo_id, tc.classif_code, tc.classif_desc
FROM siac.siac_r_bil_elem_class rbec, siac.siac_t_class tc
WHERE tc.classif_id = rbec.classif_id
AND   rbec.elem_id = v_elem_id
AND   rbec.data_cancellazione IS NULL
AND   tc.data_cancellazione IS NULL
AND   p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

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
  ELSIF v_classif_tipo_code = 'TIPO_FONDO' THEN
     v_codice_tipo_fondo      := v_classif_code;
     v_descrizione_tipo_fondo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FINANZIAMENTO' THEN
     v_codice_tipo_finanziamento      := v_classif_code;
     v_descrizione_tipo_finanziamento := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PERIMETRO_SANITARIO_ENTRATA' THEN
     v_codice_perimetro_sanitario_entrata      := v_classif_code;
     v_descrizione_perimetro_sanitario_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_36' THEN
     v_classificatore_generico_1      := v_classif_tipo_desc;
     v_classificatore_generico_1_descrizione_valore := v_classif_desc;
     v_classificatore_generico_1_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_37' THEN
     v_classificatore_generico_2     := v_classif_tipo_desc;
     v_classificatore_generico_2_descrizione_valore := v_classif_desc;
     v_classificatore_generico_2_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_38' THEN
     v_classificatore_generico_3      := v_classif_tipo_desc;
     v_classificatore_generico_3_descrizione_valore := v_classif_desc;
     v_classificatore_generico_3_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_39' THEN
     v_classificatore_generico_4     := v_classif_tipo_desc;
     v_classificatore_generico_4_descrizione_valore := v_classif_desc;
     v_classificatore_generico_4_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_40' THEN
     v_classificatore_generico_5     := v_classif_tipo_desc;
     v_classificatore_generico_5_descrizione_valore := v_classif_desc;
     v_classificatore_generico_5_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_41' THEN
     v_classificatore_generico_6      := v_classif_tipo_desc;
     v_classificatore_generico_6_descrizione_valore := v_classif_desc;
     v_classificatore_generico_6_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_42' THEN
     v_classificatore_generico_7      := v_classif_tipo_desc;
     v_classificatore_generico_7_descrizione_valore := v_classif_desc;
     v_classificatore_generico_7_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_43' THEN
     v_classificatore_generico_8      := v_classif_tipo_desc;
     v_classificatore_generico_8_descrizione_valore := v_classif_desc;
     v_classificatore_generico_8_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_44' THEN
     v_classificatore_generico_9      := v_classif_tipo_desc;
     v_classificatore_generico_9_descrizione_valore := v_classif_desc;
     v_classificatore_generico_9_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_45' THEN
     v_classificatore_generico_10      := v_classif_tipo_desc;
     v_classificatore_generico_10_descrizione_valore := v_classif_desc;
     v_classificatore_generico_10_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_46' THEN
     v_classificatore_generico_11      := v_classif_tipo_desc;
     v_classificatore_generico_11_descrizione_valore := v_classif_desc;
     v_classificatore_generico_11_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_47' THEN
     v_classificatore_generico_12     := v_classif_tipo_desc;
     v_classificatore_generico_12_descrizione_valore := v_classif_desc;
     v_classificatore_generico_12_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_48' THEN
     v_classificatore_generico_13      := v_classif_tipo_desc;
     v_classificatore_generico_13_descrizione_valore := v_classif_desc;
     v_classificatore_generico_13_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_49' THEN
     v_classificatore_generico_14     := v_classif_tipo_desc;
     v_classificatore_generico_14_descrizione_valore := v_classif_desc;
     v_classificatore_generico_14_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_50' THEN
     v_classificatore_generico_15      := v_classif_tipo_desc;
     v_classificatore_generico_15_descrizione_valore := v_classif_desc;
     v_classificatore_generico_15_valore      := v_classif_code;
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

  IF v_classif_tipo_code = 'TITOLO_ENTRATA' THEN
        v_codice_titolo_entrata := v_classif_code;
        v_descrizione_titolo_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPOLOGIA' THEN
        v_codice_tipologia_entrata := v_classif_code;
        v_descrizione_tipologia_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CATEGORIA' THEN
        v_codice_categoria_entrata := v_classif_code;
        v_descrizione_categoria_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_I' THEN
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
  ELSIF v_classif_tipo_code = 'DIVISIONE_COFOG' THEN
        v_codice_cofog_divisione := v_classif_code;
        v_descrizione_cofog_divisione := v_classif_desc;
  ELSIF v_classif_tipo_code = 'GRUPPO_COFOG' THEN
        v_codice_cofog_gruppo := v_classif_code;
        v_descrizione_cofog_gruppo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDR' THEN
        v_codice_cdr := v_classif_code;
        v_descrizione_cdr := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDC' THEN
        v_codice_cdc := v_classif_code;
        v_descrizione_cdc := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_ENTRATA_I' THEN
        v_codice_siope_I_entrata := v_classif_code;
        v_descrizione_siope_I_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_ENTRATA_II' THEN
        v_codice_siope_II_entrata := v_classif_code;
        v_descrizione_siope_II_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_ENTRATA_III' THEN
        v_codice_siope_III_entrata := v_classif_code;
        v_descrizione_siope_III_entrata := v_classif_desc;
  END IF;

  v_conta_ciclo_classif := v_conta_ciclo_classif +1;
  EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
 esito:= '    Fine step classificatori in gerarchia - '||clock_timestamp();
 return next;
END IF;
END LOOP;

-- Sezione pe gli attributi
esito:= '    Inizio step attributi - '||clock_timestamp();
return next;
v_FlagEntrateRicorrenti := null;
v_FlagImpegnabile := null;
v_FlagPerMemoria := null;
v_FlagRilevanteIva := null;
v_FlagTrasferimentoOrganiComunitari := null;
v_Note := null;
v_FlagAccertatoPerCassa := null;
v_flag_attributo := null;

FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rbea.tabella_id, rbea.percentuale, rbea."boolean" true_false, rbea.numerico, rbea.testo
FROM   siac.siac_r_bil_elem_attr rbea, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rbea.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rbea.elem_id = v_elem_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rbea.validita_inizio AND COALESCE(rbea.validita_fine, p_data)
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

  IF rec_attr.attr_code = 'FlagEntrateRicorrenti' THEN
     v_FlagEntrateRicorrenti := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagImpegnabile' THEN
     v_FlagImpegnabile := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagPerMemoria' THEN
     v_FlagPerMemoria := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagRilevanteIva' THEN
     v_FlagRilevanteIva := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagTrasferimentoOrganiComunitari' THEN
     v_FlagTrasferimentoOrganiComunitari := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'Note' THEN
     v_Note := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagAccertatoPerCassa' THEN
     v_FlagAccertatoPerCassa := v_flag_attributo;     
  END IF;

END LOOP;
esito:= '    Fine step attributi - '||clock_timestamp();
return next;
esito:= '    Inizio step stipendi - '||clock_timestamp();
return next;
-- Sezione per i dati di stipendio
v_codice_stipendio := null;
v_descrizione_stipendio := null;

SELECT dsc.stipcode_code, dsc.stipcode_desc
INTO v_codice_stipendio, v_descrizione_stipendio
FROM  siac.siac_r_bil_elem_stipendio_codice rbesc, siac.siac_d_stipendio_codice dsc
WHERE rbesc.stipcode_id = dsc.stipcode_id
AND   rbesc.elem_id = v_elem_id
AND   rbesc.data_cancellazione IS NULL
AND   dsc.data_cancellazione IS NULL
AND   p_data between rbesc.validita_inizio and coalesce(rbesc.validita_fine, p_data)
AND   p_data between dsc.validita_inizio and coalesce(dsc.validita_fine, p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step iva - '||clock_timestamp();
return next;
-- Sezione per i dati di iva
v_codice_attivita_iva := null;
v_descrizione_attivita_iva := null;

SELECT tia.ivaatt_code, tia.ivaatt_desc
INTO v_codice_attivita_iva, v_descrizione_attivita_iva
FROM siac.siac_r_bil_elem_iva_attivita rbeia, siac.siac_t_iva_attivita tia
WHERE rbeia.ivaatt_id = tia.ivaatt_id
AND   rbeia.elem_id = v_elem_id
AND   rbeia.data_cancellazione IS NULL
AND   tia.data_cancellazione IS NULL
AND   p_data between rbeia.validita_inizio and coalesce(rbeia.validita_fine,p_data)
AND   p_data between tia.validita_inizio and coalesce(tia.validita_fine,p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step dettagli elementi - '||clock_timestamp();
return next;
-- Sezione per i dati di dettaglio degli elementi
v_massimo_impegnabile_anno1 := null;
v_stanziamento_cassa_anno1 := null;
v_stanziamento_cassa_iniziale_anno1 := null;
v_stanziamento_residuo_iniziale_anno1 := null;
v_stanziamento_anno1 := null;
v_stanziamento_iniziale_anno1 := null;
v_stanziamento_residuo_anno1 := null;
v_flag_anno1 := null;
v_massimo_impegnabile_anno2 := null;
v_stanziamento_cassa_anno2 := null;
v_stanziamento_cassa_iniziale_anno2 := null;
v_stanziamento_residuo_iniziale_anno2 := null;
v_stanziamento_anno2 := null;
v_stanziamento_iniziale_anno2 := null;
v_stanziamento_residuo_anno2 := null;
v_flag_anno2 := null;
v_massimo_impegnabile_anno3 := null;
v_stanziamento_cassa_anno3 := null;
v_stanziamento_cassa_iniziale_anno3 := null;
v_stanziamento_residuo_iniziale_anno3 := null;
v_stanziamento_anno3 := null;
v_stanziamento_iniziale_anno3 := null;
v_stanziamento_residuo_anno3 := null;
v_flag_anno3 := null;

v_anno_elem_dett := null;

FOR rec_elem_dett IN
SELECT dbedt.elem_det_tipo_code, tbed.elem_det_flag, tbed.elem_det_importo, tp.anno
FROM  siac.siac_t_bil_elem_det tbed, siac.siac_d_bil_elem_det_tipo dbedt, siac.siac_t_periodo tp
WHERE tbed.elem_det_tipo_id = dbedt.elem_det_tipo_id
AND   tbed.periodo_id = tp.periodo_id
AND   tbed.elem_id = v_elem_id
AND   tbed.data_cancellazione IS NULL
AND   dbedt.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   p_data between tbed.validita_inizio and coalesce(tbed.validita_fine,p_data)
AND   p_data between dbedt.validita_inizio and coalesce(dbedt.validita_fine,p_data)
AND   p_data between tp.validita_inizio and coalesce(tp.validita_fine,p_data)

LOOP
v_anno_elem_dett := rec_elem_dett.anno::integer;
  IF v_anno_elem_dett = v_anno_appo THEN
    v_flag_anno1 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno1 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 1) THEN
    v_flag_anno2 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno2 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 2) THEN
    v_flag_anno3 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno3 := rec_elem_dett.elem_det_importo;
    END IF;
  END IF;
END LOOP;
esito:= '    Fine step dettagli elementi - '||clock_timestamp();
return next;
esito:= '    Inizio step dati da funzione - '||clock_timestamp();
return next;
-- Sezione per valorizzazione delle variabili per i campi di funzione
v_disponibilita_accertare_anno1 := null;
v_disponibilita_accertare_anno2 := null;
v_disponibilita_accertare_anno3 := null;

IF v_elem_tipo_code = 'CAP-EG' THEN
   v_disponibilita_accertare_anno1 := siac.fnc_siac_disponibilitaaccertareeg_anno1(v_elem_id);
   v_disponibilita_accertare_anno2 := siac.fnc_siac_disponibilitaaccertareeg_anno2(v_elem_id);
   v_disponibilita_accertare_anno3 := siac.fnc_siac_disponibilitaaccertareeg_anno3(v_elem_id);
END IF;
esito:= '    Fine step dati da funzione - '||clock_timestamp();
return next;
INSERT INTO siac.siac_dwh_capitolo_entrata
(ente_proprietario_id,
ente_denominazione,
bil_anno,
cod_fase_operativa,
desc_fase_operativa,
cod_capitolo,
cod_articolo,
cod_ueb,
desc_capitolo,
desc_articolo,
cod_tipo_capitolo,
desc_tipo_capitolo,
cod_stato_capitolo,
desc_stato_capitolo,
cod_classificazione_capitolo,
desc_classificazione_capitolo,
cod_titolo_entrata,
desc_titolo_entrata,
cod_tipologia_entrata,
desc_tipologia_entrata,
cod_categoria_entrata,
desc_categoria_entrata,
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
cod_cofog_divisione,
desc_cofog_divisione,
cod_cofog_gruppo,
desc_cofog_gruppo,
cod_cdr,
desc_cdr,
cod_cdc,
desc_cdc,
cod_siope_i_entrata,
desc_siope_i_entrata,
cod_siope_ii_entrata,
desc_siope_ii_entrata,
cod_siope_iii_entrata,
desc_siope_iii_entrata,
cod_entrata_ricorrente,
desc_entrata_ricorrente,
cod_transazione_entrata_ue,
desc_transazione_entrata_ue,
cod_tipo_fondo,
desc_tipo_fondo,
cod_tipo_finanziamento,
desc_tipo_finanziamento,
cod_perimetro_sanita_entrata,
desc_perimetro_sanita_entrata,
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
classificatore_6,
classificatore_6_valore,
classificatore_6_desc_valore,
classificatore_7,
classificatore_7_valore,
classificatore_7_desc_valore,
classificatore_8,
classificatore_8_valore,
classificatore_8_desc_valore,
classificatore_9,
classificatore_9_valore,
classificatore_9_desc_valore,
classificatore_10,
classificatore_10_valore,
classificatore_10_desc_valore,
classificatore_11,
classificatore_11_valore,
classificatore_11_desc_valore,
classificatore_12,
classificatore_12_valore,
classificatore_12_desc_valore,
classificatore_13,
classificatore_13_valore,
classificatore_13_desc_valore,
classificatore_14,
classificatore_14_valore,
classificatore_14_desc_valore,
classificatore_15,
classificatore_15_valore,
classificatore_15_desc_valore,
flagentratericorrenti,
flagimpegnabile,
flagpermemoria,
flagrilevanteiva,
flag_trasf_organi_comunitari,
note,
cod_stipendio,
desc_stipendio,
cod_attivita_iva,
desc_attivita_iva,
massimo_impegnabile_anno1,
stanz_cassa_anno1,
stanz_cassa_iniziale_anno1,
stanz_residuo_iniziale_anno1,
stanz_anno1,
stanz_iniziale_anno1,
stanz_residuo_anno1,
flag_anno1,
massimo_impegnabile_anno2,
stanz_cassa_anno2,
stanz_cassa_iniziale_anno2,
stanz_residuo_iniziale_anno2,
stanz_anno2,
stanz_iniziale_anno2,
stanz_residuo_anno2,
flag_anno2,
massimo_impegnabile_anno3,
stanz_cassa_anno3,
stanz_cassa_iniziale_anno3,
stanz_residuo_iniziale_anno3,
stanz_anno3,
stanz_iniziale_anno3,
stanz_residuo_anno3,
flag_anno3,
disponibilita_accertare_anno1,
disponibilita_accertare_anno2,
disponibilita_accertare_anno3,
flagaccertatopercassa
)
VALUES (v_ente_proprietario_id,
        v_ente_denominazione,
        v_anno,
        v_fase_operativa_code,
        v_fase_operativa_desc,
        v_elem_code,
        v_elem_code2,
        v_elem_code3,
        v_elem_desc,
        v_elem_desc2,
        v_elem_tipo_code,
        v_elem_tipo_desc,
        v_elem_stato_code,
        v_elem_stato_desc,
        v_elem_cat_code,
        v_elem_cat_desc,
        v_codice_titolo_entrata,
        v_descrizione_titolo_entrata,
        v_codice_tipologia_entrata,
        v_descrizione_tipologia_entrata,
        v_codice_categoria_entrata,
        v_descrizione_categoria_entrata,
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
        v_codice_cofog_divisione,
        v_descrizione_cofog_divisione,
        v_codice_cofog_gruppo,
        v_descrizione_cofog_gruppo,
        v_codice_cdr,
        v_descrizione_cdr,
        v_codice_cdc,
        v_descrizione_cdc,
        v_codice_siope_I_entrata,
        v_descrizione_siope_I_entrata,
        v_codice_siope_II_entrata,
        v_descrizione_siope_II_entrata,
        v_codice_siope_III_entrata,
        v_descrizione_siope_III_entrata,
        v_codice_entrata_ricorrente,
        v_descrizione_entrata_ricorrente,
        v_codice_transazione_entrata_ue,
        v_descrizione_transazione_entrata_ue,
        v_codice_tipo_fondo,
        v_descrizione_tipo_fondo,
        v_codice_tipo_finanziamento,
        v_descrizione_tipo_finanziamento,
        v_codice_perimetro_sanitario_entrata,
        v_descrizione_perimetro_sanitario_entrata,
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
        v_classificatore_generico_6,
        v_classificatore_generico_6_valore,
        v_classificatore_generico_6_descrizione_valore,
        v_classificatore_generico_7,
        v_classificatore_generico_7_valore,
        v_classificatore_generico_7_descrizione_valore,
        v_classificatore_generico_8,
        v_classificatore_generico_8_valore,
        v_classificatore_generico_8_descrizione_valore,
        v_classificatore_generico_9,
        v_classificatore_generico_9_valore,
        v_classificatore_generico_9_descrizione_valore,
        v_classificatore_generico_10,
        v_classificatore_generico_10_valore,
        v_classificatore_generico_10_descrizione_valore,
        v_classificatore_generico_11,
        v_classificatore_generico_11_valore,
        v_classificatore_generico_11_descrizione_valore,
        v_classificatore_generico_12,
        v_classificatore_generico_12_valore,
        v_classificatore_generico_12_descrizione_valore,
        v_classificatore_generico_13,
        v_classificatore_generico_13_valore,
        v_classificatore_generico_13_descrizione_valore,
        v_classificatore_generico_14,
        v_classificatore_generico_14_valore,
        v_classificatore_generico_14_descrizione_valore,
        v_classificatore_generico_15,
        v_classificatore_generico_15_valore,
        v_classificatore_generico_15_descrizione_valore,
        v_FlagEntrateRicorrenti,
        v_FlagImpegnabile,
        v_FlagPerMemoria,
        v_FlagRilevanteIva,
        v_FlagTrasferimentoOrganiComunitari,
        v_Note,
        v_codice_stipendio,
        v_descrizione_stipendio,
        v_codice_attivita_iva,
        v_descrizione_attivita_iva,
        v_massimo_impegnabile_anno1,
        v_stanziamento_cassa_anno1,
        v_stanziamento_cassa_iniziale_anno1,
        v_stanziamento_residuo_iniziale_anno1,
        v_stanziamento_anno1,
        v_stanziamento_iniziale_anno1,
        v_stanziamento_residuo_anno1,
        v_flag_anno1,
        v_massimo_impegnabile_anno2,
        v_stanziamento_cassa_anno2,
        v_stanziamento_cassa_iniziale_anno2,
        v_stanziamento_residuo_iniziale_anno2,
        v_stanziamento_anno2,
        v_stanziamento_iniziale_anno2,
        v_stanziamento_residuo_anno2,
        v_flag_anno2,
        v_massimo_impegnabile_anno3,
        v_stanziamento_cassa_anno3,
        v_stanziamento_cassa_iniziale_anno3,
        v_stanziamento_residuo_iniziale_anno3,
        v_stanziamento_anno3,
        v_stanziamento_iniziale_anno3,
        v_stanziamento_residuo_anno3,
        v_flag_anno3,
        v_disponibilita_accertare_anno1,
        v_disponibilita_accertare_anno2,
        v_disponibilita_accertare_anno3,
        v_FlagAccertatoPerCassa
       );
esito:= '  Fine ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
END LOOP;
esito:= 'Fine funzione carico capitoli di entrata (FNC_SIAC_DWH_CAPITOLO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzzione carico capitoli di entrata (FNC_SIAC_DWH_CAPITOLO_ENTRATA) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-5582 - FINE

-- SIAC-5344 - INIZIO

-- DDL

CREATE TABLE siac_t_elab_threshold (
	elthres_id         SERIAL NOT NULL,
	elthres_code       VARCHAR NOT NULL,
	elthres_value      BIGINT NOT NULL,
	validita_inizio    TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine      TIMESTAMP WITHOUT TIME ZONE,
	data_creazione     TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica      TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione   VARCHAR(200) NOT NULL
);

-- Valutare se il codice possa essere su una tabella di decodifica a parte, e avere la FK corrispondente

ALTER TABLE siac.siac_t_elab_threshold ADD CONSTRAINT PK_siac_t_elab_threshold PRIMARY KEY (elthres_id);

CREATE UNIQUE INDEX IDX_siac_t_elab_threshold_1
ON siac.siac_t_elab_threshold (elthres_code, validita_inizio) WHERE data_cancellazione IS NULL;

-- DML
INSERT INTO siac_t_elab_threshold (elthres_code, elthres_value, validita_inizio, login_operazione)
SELECT tmp.code, tmp.threshold, now(), 'admin'
FROM (VALUES ('COMPLETA_ATTO_ALLEGATO', 50),
	('EMETTITORE_INCASSO', 50),
	('EMETTITORE_PAGAMENTO', 50)) AS tmp(code, threshold)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_t_elab_threshold tet
	WHERE tet.elthres_code = tmp.code
);

-- SIAC-5344 - FINE

-- Modifiche per ottimizzazione CSI - INIZIO - Maurizio

CREATE OR REPLACE FUNCTION siac."BILR150_prosp_dimos_ris_amm_spese" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  pr_totale_pagam_residui numeric,
  pc_totale_pagam_competenza numeric,
  rs_totale_residui_passivi numeric,
  r_totale_riaccertamenti_residui numeric,
  i_totale_importo_impegni numeric,
  totale_importo_fpv_parte_corr numeric,
  totale_importo_fpv_cc numeric
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp_int integer;
TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_movgest_tipo varchar:='A';
v_movgest_ts_tipo varchar :='T';

v_det_tipo_importo_attuale varchar:='A';
v_det_tipo_importo_iniziale varchar:='I';
v_ord_stato_code_annullato varchar:='A';
v_ord_tipo_code_incasso varchar:='I';
v_fam_titolotipologiacategoria varchar:='00003';

bilancio_id integer;

BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;  

TipoImpstanzresidui='SRI'; -- stanziamento residuo post (RS)
TipoImpstanz='STA'; -- stanziamento  (CP)
TipoImpCassa ='SCA'; ----- cassa	(CS)
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

pr_totale_pagam_residui:=0;
pc_totale_pagam_competenza:=0;
rs_totale_residui_passivi:=0;
r_totale_riaccertamenti_residui:=0;
i_totale_importo_impegni:=0;
totale_importo_fpv_parte_corr:=0;
totale_importo_fpv_cc:=0;

RTN_MESSAGGIO:='Estrazione dei dati delle riscossioni e dei pagamenti.';
raise notice '%',RTN_MESSAGGIO;

raise notice '5 - %' , clock_timestamp()::text;

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

raise notice 'bilancio_id = %', bilancio_id;
 
return query
with clas as (
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
and d.classif_fam_code = '00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id )
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
and d.classif_fam_code = '00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id )
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
and d.classif_fam_code = '00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id )
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
and d.classif_fam_code = '00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id )
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
from missione , programma
,titusc, macroag
, siac_r_class progmacro
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 and titusc.ente_proprietario_id=missione.ente_proprietario_id
 ),
 capusc as (
select a.elem_id,  g.elem_cat_code/*,
a.elem_code ,
a.elem_desc ,
a.elem_code2 ,
a.elem_desc2 ,
a.elem_id_padre ,
a.elem_code3,
d.classif_id programma_id,d2.classif_id macroag_id */
from siac_t_bil_elem a,siac_d_bil_elem_tipo b, siac_r_bil_elem_class c,
siac_r_bil_elem_class c2,
siac_t_class d,siac_t_class d2,
siac_d_class_tipo e,siac_d_class_tipo e2, siac_r_bil_elem_categoria f, 
siac_d_bil_elem_categoria g,siac_r_bil_elem_stato h,siac_d_bil_elem_stato i
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.elem_tipo_id=a.elem_tipo_id
and b.elem_tipo_code='CAP-UG' 
and c.elem_id=a.elem_id
and c2.elem_id=a.elem_id
and d.classif_id=c.classif_id
and d2.classif_id=c2.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and e2.classif_tipo_id=d2.classif_tipo_id
and e.classif_tipo_code='PROGRAMMA'
and e2.classif_tipo_code='MACROAGGREGATO'
and g.elem_cat_id=f.elem_cat_id
and f.elem_id=a.elem_id
and g.elem_cat_code in	('STD','FPV','FSC','FPVCC','FPVSC')
and h.elem_id=a.elem_id
and i.elem_stato_id=h.elem_stato_id
and i.elem_stato_code<>'AN'
and h.validita_fine is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and c2.data_cancellazione is null
and d.data_cancellazione is null
and d2.data_cancellazione is null
and e.data_cancellazione is null
and e2.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
), 
pagamenti_residui as (
select 
l.elem_id,sum(coalesce(m.ord_ts_det_importo,0)) pagamenti
 from  siac_T_movgest a, siac_t_movgest_ts b,siac_r_liquidazione_movgest c,siac_r_liquidazione_ord d,
siac_t_ordinativo_ts e,siac_t_ordinativo f,siac_d_ordinativo_tipo g,siac_r_ordinativo_stato h,
siac_d_ordinativo_stato i,siac_r_ordinativo_bil_elem l,siac_t_ordinativo_ts_det m,
siac_d_ordinativo_ts_det_tipo n
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.movgest_id=a.movgest_id
and c.movgest_ts_id=b.movgest_ts_id
and d.liq_id=c.liq_id
and f.ord_id=e.ord_id
and a.movgest_anno < annoCapImp_int
and c.validita_fine is NULL
and d.validita_fine is NULL
and d.sord_id=e.ord_ts_id
and f.ord_id=e.ord_id
and g.ord_tipo_id=f.ord_tipo_id
and g.ord_tipo_code='P'
and h.ord_id=f.ord_id
and i.ord_stato_id=h.ord_stato_id
and i.ord_stato_code<>'A'
and l.ord_id=f.ord_id
and m.ord_ts_id=e.ord_ts_id
and n.ord_ts_det_tipo_id=m.ord_ts_det_tipo_id
and n.ord_ts_det_tipo_code='A'
and l.validita_fine is NULL
and h.validita_fine is NULL
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
group by l.elem_id          ),
pagamenti_comp as (
select 
l.elem_id,sum(coalesce(m.ord_ts_det_importo,0)) pagamenti
 from  siac_T_movgest a, siac_t_movgest_ts b,siac_r_liquidazione_movgest c,siac_r_liquidazione_ord d,
siac_t_ordinativo_ts e,siac_t_ordinativo f,siac_d_ordinativo_tipo g,siac_r_ordinativo_stato h,
siac_d_ordinativo_stato i,siac_r_ordinativo_bil_elem l,siac_t_ordinativo_ts_det m,
siac_d_ordinativo_ts_det_tipo n
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.movgest_id=a.movgest_id
and c.movgest_ts_id=b.movgest_ts_id
and d.liq_id=c.liq_id
and f.ord_id=e.ord_id
and a.movgest_anno =annoCapImp_int
and c.validita_fine is NULL
and d.validita_fine is NULL
and d.sord_id=e.ord_ts_id
and f.ord_id=e.ord_id
and g.ord_tipo_id=f.ord_tipo_id
and g.ord_tipo_code='P'
and h.ord_id=f.ord_id
and i.ord_stato_id=h.ord_stato_id
and i.ord_stato_code<>'A'
and l.ord_id=f.ord_id
and m.ord_ts_id=e.ord_ts_id
and n.ord_ts_det_tipo_id=m.ord_ts_det_tipo_id
and n.ord_ts_det_tipo_code='A'
and l.validita_fine is NULL
and h.validita_fine is NULL
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
group by l.elem_id          ),
residui_pass as (
select d.elem_id,
sum(coalesce(c.movgest_ts_det_importo,0)) residui_passivi 
from siac_t_movgest a,siac_t_movgest_ts b,siac_t_movgest_ts_det c,
siac_r_movgest_bil_elem d,siac_d_movgest_tipo e,siac_r_movgest_ts_stato f,siac_d_movgest_stato g,
siac_d_movgest_ts_tipo h,siac_d_movgest_ts_det_tipo i
 where a.bil_id=bilancio_id
 and b.movgest_id=a.movgest_id
 and c.movgest_ts_id=b.movgest_ts_id
 and a.movgest_anno < annoCapImp_int
and d.movgest_id=a.movgest_id
and e.movgest_tipo_id=a.movgest_tipo_id
and e.movgest_tipo_code='I'
and f.movgest_ts_id=b.movgest_ts_id
and f.movgest_stato_id=g.movgest_stato_id
and g.movgest_stato_code in ('D','N') 
and f.validita_fine is NULL
and h.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and h.movgest_ts_tipo_code='T' 
and  i.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id
and i.movgest_ts_det_tipo_code='I'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
group by d.elem_id),
riacc_residui as (
select  
b.elem_id,sum(coalesce(q.movgest_ts_det_importo,0)) riaccertamenti_residui
from 
siac_r_movgest_bil_elem b,siac_t_movgest c,
      siac_d_movgest_tipo  d,
      siac_t_movgest_ts  e,
      siac_r_movgest_ts_stato f,
      siac_d_movgest_stato   g,
      siac_t_movgest_ts_det h,
      siac_d_movgest_ts_tipo i,
      siac_d_movgest_ts_det_tipo l,
      siac_t_modifica m,
      siac_r_modifica_stato o,
      siac_d_modifica_stato p,
      siac_t_movgest_ts_det_mod q
where c.ente_proprietario_id=p_ente_prop_id
and c.bil_id=bilancio_id
and b.movgest_id = c.movgest_id 
and c.movgest_anno < annoCapImp_int
and c.movgest_tipo_id = d.movgest_tipo_id 
and d.movgest_tipo_code = 'I'
and c.movgest_id = e.movgest_id 
and e.movgest_ts_id  = f.movgest_ts_id 
and f.movgest_stato_id  = g.movgest_stato_id 
and f.validita_fine is NULL
and g.movgest_stato_code   in ('D','N') 
and h.movgest_ts_id = e.movgest_ts_id
and i.movgest_ts_tipo_id  = e.movgest_ts_tipo_id 
and i.movgest_ts_tipo_code  = 'T' 
and l.movgest_ts_det_tipo_id  = h.movgest_ts_det_tipo_id 
and l.movgest_ts_det_tipo_code = 'A' 
and q.movgest_ts_id=e.movgest_ts_id      
and q.mod_stato_r_id=o.mod_stato_r_id
and o.validita_fine is NULL
and p.mod_stato_id=o.mod_stato_id  
and p.mod_stato_code='V'
and o.mod_id=m.mod_id
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and f.data_cancellazione is null 
and e.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null
and m.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
group by b.elem_id),
impegni as (
select d.elem_id,
sum(coalesce(c.movgest_ts_det_importo,0)) importo_impegni 
from siac_t_movgest a,siac_t_movgest_ts b,siac_t_movgest_ts_det c,
siac_r_movgest_bil_elem d,siac_d_movgest_tipo e,siac_r_movgest_ts_stato f,siac_d_movgest_stato g,
siac_d_movgest_ts_tipo h,siac_d_movgest_ts_det_tipo i
 where a.bil_id=bilancio_id
 and b.movgest_id=a.movgest_id
 and c.movgest_ts_id=b.movgest_ts_id
 and a.movgest_anno = annoCapImp_int
and d.movgest_id=a.movgest_id
and e.movgest_tipo_id=a.movgest_tipo_id
and e.movgest_tipo_code='I'
and f.movgest_ts_id=b.movgest_ts_id
and f.movgest_stato_id=g.movgest_stato_id
and g.movgest_stato_code in ('D','N') 
and f.validita_fine is NULL
and h.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and h.movgest_ts_tipo_code='T' 
and  i.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id
and i.movgest_ts_det_tipo_code='A'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
group by d.elem_id),
fpv_tit1 as (
select  
a.elem_id,
sum(d.elem_det_importo) importo_fpv_tit1
 from 
siac_t_bil_elem a, siac_d_bil_elem_tipo b,
siac_t_bil c, siac_t_periodo c2,  siac_t_bil_elem_det d, siac_d_bil_elem_det_tipo e,
siac_r_bil_elem_categoria f,siac_d_bil_elem_categoria g,siac_d_bil_elem_stato h,
siac_r_bil_elem_stato i,siac_r_bil_elem_class j,siac_r_bil_elem_class k,
siac_t_class m,siac_t_class n,
siac_d_class_tipo m2,siac_d_class_tipo n2,siac_t_periodo o
where 
a.ente_proprietario_id=p_ente_prop_id 
and 
a.elem_tipo_id=b.elem_tipo_id
and b.elem_tipo_code='CAP-UG'
and c.bil_id=a.bil_id
and c2.periodo_id=c.periodo_id
and c2.anno=p_anno
and d.elem_id=a.elem_id
and e.elem_det_tipo_id=d.elem_det_tipo_id
and e.elem_det_tipo_code='STA'
and f.elem_id=A.elem_id
and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
and g.elem_cat_id=f.elem_cat_id
and g.elem_cat_code in	('FPV','FPVC')	
and i.elem_id=A.elem_id
and h.elem_stato_id=i.elem_stato_id
and h.elem_stato_code='VA'
and j.elem_id=a.elem_id
and now() between i.validita_inizio and COALESCE(i.validita_fine,now())
and now() between j.validita_inizio and COALESCE(j.validita_fine,now())    
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and c2.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and j.data_cancellazione is null
and k.elem_id=A.elem_id
and now() between k.validita_inizio and COALESCE(k.validita_fine,now())
and m.classif_id=j.classif_id
and n.classif_id=k.classif_id
and m2.classif_tipo_id=m.classif_tipo_id
and m2.classif_tipo_code='MACROAGGREGATO'
and n2.classif_tipo_id=n.classif_tipo_id
and n2.classif_tipo_code='PROGRAMMA'
and substring(m.classif_code from 1 for 1)='1'
and o.periodo_id=d.periodo_id
and o.anno=p_anno
group by a.elem_id
 ),
fpv_tit2 as (
select  
a.elem_id,
sum(d.elem_det_importo) importo_fpv_tit2
 from 
siac_t_bil_elem a, siac_d_bil_elem_tipo b,
siac_t_bil c, siac_t_periodo c2,  siac_t_bil_elem_det d, siac_d_bil_elem_det_tipo e,
siac_r_bil_elem_categoria f,siac_d_bil_elem_categoria g,siac_d_bil_elem_stato h,
siac_r_bil_elem_stato i,siac_r_bil_elem_class j,siac_r_bil_elem_class k,
siac_t_class m,siac_t_class n,
siac_d_class_tipo m2,siac_d_class_tipo n2,siac_t_periodo o
where 
a.ente_proprietario_id=p_ente_prop_id 
and 
a.elem_tipo_id=b.elem_tipo_id
and b.elem_tipo_code='CAP-UG'
and c.bil_id=a.bil_id
and c2.periodo_id=c.periodo_id
and c2.anno=p_anno
and d.elem_id=a.elem_id
and e.elem_det_tipo_id=d.elem_det_tipo_id
and e.elem_det_tipo_code='STA'
and f.elem_id=A.elem_id
and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
and g.elem_cat_id=f.elem_cat_id
and g.elem_cat_code in	('FPV','FPVC')	
and i.elem_id=A.elem_id
and h.elem_stato_id=i.elem_stato_id
and h.elem_stato_code='VA'
and j.elem_id=a.elem_id
and now() between i.validita_inizio and COALESCE(i.validita_fine,now())
and now() between j.validita_inizio and COALESCE(j.validita_fine,now())    
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and c2.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and j.data_cancellazione is null
and k.elem_id=A.elem_id
and now() between k.validita_inizio and COALESCE(k.validita_fine,now())
and m.classif_id=j.classif_id
and n.classif_id=k.classif_id
and m2.classif_tipo_id=m.classif_tipo_id
and m2.classif_tipo_code='MACROAGGREGATO'
and n2.classif_tipo_id=n.classif_tipo_id
and n2.classif_tipo_code='PROGRAMMA'
and substring(m.classif_code from 1 for 1)='2'
and o.periodo_id=d.periodo_id
and o.anno=p_anno
group by a.elem_id
)    
select sum(pagamenti_residui.pagamenti) pr_totale_pagam_residui,
	sum(pagamenti_comp.pagamenti) pc_totale_pagam_competenza,
    sum(residui_pass.residui_passivi) rs_totale_residui_passivi,
    sum(riacc_residui.riaccertamenti_residui) r_totale_riaccertamenti_residui,
    sum(impegni.importo_impegni) i_totale_importo_impegni,
    sum(fpv_tit1.importo_fpv_tit1) totale_importo_fpv_parte_corr,
    sum(fpv_tit2.importo_fpv_tit2) totale_importo_fpv_cc
   from capusc   	
          left join pagamenti_residui 
              on capusc.elem_id=pagamenti_residui.elem_id
          left join pagamenti_comp
              on capusc.elem_id=pagamenti_comp.elem_id
          left join residui_pass
              on capusc.elem_id=residui_pass.elem_id
          left join riacc_residui
          	  on capusc.elem_id=riacc_residui.elem_id
          left join impegni
          	  on capusc.elem_id=impegni.elem_id
          left join fpv_tit1
          	  on capusc.elem_id=fpv_tit1.elem_id 
          left join fpv_tit2
          	  on capusc.elem_id=fpv_tit2.elem_id ;
  


exception
	when no_data_found THEN
		raise notice 'nessun dato trovato per le sspese.' ;
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

-- Modifiche per ottimizzazione CSI - FINE - Maurizio
--SIAC-5333 INIZIO
INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('GESTIONE_PNOTA_DA_FIN', 'Gestione della prima nota da finanziaria')) AS tmp(code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('TRUE', 'TRUE', 'GESTIONE_PNOTA_DA_FIN')) AS tmp(code, descr, tipo)
WHERE dgt.gestione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_r_gestione_ente (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dgl.gestione_livello_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('TRUE', 'Consiglio Regionale Piemonte')) AS tmp(livello, ente)
WHERE tep.ente_denominazione = tmp.ente
AND dgl.gestione_livello_code = tmp.livello
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
	AND rge.data_cancellazione IS NULL
);
--SIAC-5333 FINE

-- Patch urgente fnc_770_tracciato_quadro_c_f
CREATE OR REPLACE FUNCTION siac.fnc_770_tracciato_quadro_c_f (
  p_anno_elab varchar,
  p_ente_proprietario_id integer,
  p_ex_ente varchar,
  p_quadro_c_f varchar
)
RETURNS varchar AS
$body$
DECLARE

rec_tracciato_770 record;
rec_indirizzo record;
rec_inps record;
rec_tracciato_fin_c record;
rec_tracciato_fin_f record;

v_soggetto_id INTEGER; -- SIAC-5485
v_comune_id_nascita INTEGER; 
v_comune_id INTEGER;
v_comune_id_gen INTEGER;
v_via_tipo_id INTEGER;
v_ord_id_a INTEGER;
v_indirizzo_tipo_code VARCHAR;
v_principale VARCHAR;
v_onere_tipo_code VARCHAR;

v_zip_code VARCHAR;
v_comune_desc VARCHAR;
v_provincia_desc VARCHAR;
v_nazione_desc VARCHAR;
v_indirizzo VARCHAR;
v_via_tipo_desc VARCHAR;
v_toponimo VARCHAR;
v_numero_civico VARCHAR;
v_frazione VARCHAR;
v_interno VARCHAR;
-- INPS
v_importoParzInpsImpon NUMERIC;
v_importoParzInpsNetto NUMERIC;
v_importoParzInpsRiten NUMERIC;
v_importoParzInpsEnte NUMERIC;
v_importo_ritenuta_inps NUMERIC;
v_importo_imponibile_inps NUMERIC;
v_importo_ente_inps NUMERIC;
v_importo_netto_inps NUMERIC;
v_idFatturaOld INTEGER;
v_contaQuotaInps INTEGER;
v_percQuota NUMERIC;
v_numeroQuoteFattura INTEGER;
-- INPS 
v_tipo_record VARCHAR;
v_codice_fiscale_ente VARCHAR;
v_codice_fiscale_percipiente VARCHAR;
v_tipo_percipiente VARCHAR;
v_cognome VARCHAR;
v_nome VARCHAR;
v_sesso VARCHAR;
v_data_nascita TIMESTAMP;    
v_comune_nascita VARCHAR;
v_nazione_nascita VARCHAR; 
v_provincia_nascita VARCHAR;
v_comune_indirizzo_principale VARCHAR;
v_provincia_indirizzo_principale VARCHAR;
v_indirizzo_principale VARCHAR;
v_cap_indirizzo_principale VARCHAR;  
 
v_indirizzo_fiscale VARCHAR;
v_cap_indirizzo_fiscale VARCHAR;
v_comune_indirizzo_fiscale VARCHAR;
v_provincia_indirizzo_fiscale VARCHAR;    
        
v_codice_fiscale_estero VARCHAR;
v_causale VARCHAR;
v_importo_lordo NUMERIC;
v_somma_non_soggetta NUMERIC;  
v_importo_imponibile NUMERIC;
v_ord_ts_det_importo NUMERIC;
v_importo_carico_ente NUMERIC;
v_importo_carico_soggetto NUMERIC; 
v_codice VARCHAR;  
v_codice_tributo VARCHAR;
v_matricola_c INTEGER;
v_matricola_f INTEGER;
v_codice_controllo2 VARCHAR;
v_aliquota NUMERIC;
    
v_elab_id INTEGER;
v_elab_id_det INTEGER;
v_elab_id_temp INTEGER;
v_elab_id_det_temp INTEGER;
v_codresult INTEGER := null;
elab_mif_esito_in CONSTANT  VARCHAR := 'IN';
elab_mif_esito_ok CONSTANT  VARCHAR := 'OK';
elab_mif_esito_ko CONSTANT  VARCHAR := 'KO';
v_tipo_flusso  CONSTANT  VARCHAR := 'MOD770';
v_login CONSTANT  VARCHAR := 'SIAC';
messaggioRisultato VARCHAR;

BEGIN

-- Inserimento record in tabella mif_t_flusso_elaborato
INSERT INTO mif_t_flusso_elaborato
(flusso_elab_mif_data,
 flusso_elab_mif_esito,
 flusso_elab_mif_esito_msg,
 flusso_elab_mif_file_nome,
 flusso_elab_mif_tipo_id,
 flusso_elab_mif_id_flusso_oil,
 validita_inizio,
 ente_proprietario_id,
 login_operazione)
 (SELECT now(),
         elab_mif_esito_in,
         'Elaborazione in corso per tipo flusso '||v_tipo_flusso,
         tipo.flusso_elab_mif_nome_file,
         tipo.flusso_elab_mif_tipo_id,
         null, -- flussoElabMifOilId, -- non usato per questo tipo di flusso
         now(),
         p_ente_proprietario_id,
         v_login
  FROM mif_d_flusso_elaborato_tipo tipo
  WHERE tipo.ente_proprietario_id = p_ente_proprietario_id
  AND   tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
  AND   tipo.data_cancellazione IS NULL
  AND   tipo.validita_fine IS NULL
 )
 RETURNING flusso_elab_mif_id into v_elab_id;

IF p_anno_elab IS NULL THEN
   messaggioRisultato := 'Parametro Anno di Elaborazione nullo.';
   -- RETURN NEXT;
   -- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
   UPDATE  mif_t_flusso_elaborato
   SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
       (elab_mif_esito_ko,'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato, now())
   WHERE flusso_elab_mif_id = v_elab_id;
   RETURN messaggioRisultato;
END IF;

IF p_ente_proprietario_id IS NULL THEN
   messaggioRisultato := 'Parametro Ente Propietario nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF p_ex_ente IS NULL THEN
   messaggioRisultato := 'Parametro Ex Ente nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF p_quadro_c_f IS NULL THEN
   messaggioRisultato := 'Parametro Quadro C-F nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF v_elab_id IS NULL THEN
  messaggioRisultato := 'Errore generico in inserimento';
  -- RETURN NEXT;  
  RETURN messaggioRisultato;
END IF;

v_codresult:=null;
-- Verifica esistenza elaborazioni in corso per tipo flusso
SELECT DISTINCT 1 
INTO v_codresult
FROM mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
WHERE  elab.flusso_elab_mif_id != v_elab_id
AND    elab.flusso_elab_mif_esito = elab_mif_esito_in
AND    elab.data_cancellazione IS NULL
AND    elab.validita_fine IS NULL
AND    tipo.flusso_elab_mif_tipo_id = elab.flusso_elab_mif_tipo_id
AND    tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
AND    tipo.ente_proprietario_id = p_ente_proprietario_id
AND    tipo.data_cancellazione IS NULL
AND    tipo.validita_fine IS NULL;

IF v_codresult IS NOT NULL THEN
   messaggioRisultato := 'Verificare situazioni esistenti.';
   -- RETURN NEXT;
   -- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
   UPDATE  mif_t_flusso_elaborato
   SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
       (elab_mif_esito_ko,'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato, now())
   WHERE flusso_elab_mif_id = v_elab_id;
   RETURN messaggioRisultato;  
END IF;

v_elab_id_det := 1;
v_elab_id_det_temp := 1;
v_matricola_c := 8000000;
v_matricola_f := 9000000;

IF p_quadro_c_f in ('C','T') THEN
  DELETE FROM siac.tracciato_770_quadro_c_temp
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab

  DELETE FROM siac.tracciato_770_quadro_c
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab
END IF;

IF p_quadro_c_f in ('F','T') THEN
  DELETE FROM siac.tracciato_770_quadro_f_temp
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab

  DELETE FROM siac.tracciato_770_quadro_f
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab
END IF;

IF p_quadro_c_f = 'C' THEN
   v_onere_tipo_code := 'IRPEF';
ELSIF p_quadro_c_f = 'F' THEN
   v_onere_tipo_code := 'IRPEG';
ELSE
   v_onere_tipo_code := null;
END IF;   

v_codice_fiscale_ente := null;
v_tipo_record := null;

SELECT codice_fiscale
INTO   v_codice_fiscale_ente
FROM   siac_t_ente_proprietario
WHERE  ente_proprietario_id = p_ente_proprietario_id;

--v_importo_lordo := 0;
--v_codice_tributo := null;
--v_causale := null; 

v_idFatturaOld := 0;
v_contaQuotaInps := 0;

FOR rec_tracciato_770 IN
SELECT --sto.ord_id, 
       --SUM(totd.ord_ts_det_importo) IMPORTO_LORDO,
       --totd.ord_ts_det_importo IMPORTO_LORDO,       
       rdo.caus_id,
       sdo.onere_code,
       td.doc_id,
       rdo.doc_onere_id,
       rdo.somma_non_soggetta_tipo_id,
       rdo.onere_id,
       sros.soggetto_id,
       roa.testo
FROM  siac_t_ordinativo sto
INNER JOIN siac_t_ente_proprietario tep ON sto.ente_proprietario_id = tep.ente_proprietario_id
INNER JOIN siac_t_bil tb ON tb.bil_id = sto.bil_id
INNER JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
INNER JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
INNER JOIN siac_d_ordinativo_tipo dot ON dot.ord_tipo_id = sto.ord_tipo_id
INNER JOIN siac_t_ordinativo_ts tot ON tot.ord_id = sto.ord_id
--INNER JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
--INNER JOIN siac_d_ordinativo_ts_det_tipo dotdt ON dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
INNER JOIN siac_r_subdoc_ordinativo_ts rsot ON rsot.ord_ts_id = tot.ord_ts_id
INNER JOIN siac_t_subdoc ts ON ts.subdoc_id = rsot.subdoc_id
INNER JOIN siac_t_doc td ON td.doc_id = ts.doc_id
INNER JOIN siac_r_doc_onere rdo ON rdo.doc_id = td.doc_id
INNER JOIN siac_r_onere_attr roa ON roa.onere_id = rdo.onere_id
INNER JOIN siac_t_attr ta ON ta.attr_id = roa.attr_id
INNER JOIN siac_d_onere sdo ON sdo.onere_id = rdo.onere_id
INNER JOIN siac_d_onere_tipo sdot ON sdot.onere_tipo_id = sdo.onere_tipo_id
INNER JOIN siac_r_ordinativo_soggetto sros ON sros.ord_id = sto.ord_id
WHERE sto.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dos.ord_stato_code <> 'A'
AND   dot.ord_tipo_code = 'P'
--AND   dotdt.ord_ts_det_tipo_code = 'A'
AND   ((roa.testo = p_quadro_c_f) OR ('T' = p_quadro_c_f AND roa.testo IN ('C','F')))
AND   ta.attr_code = 'QUADRO_770'
AND   ((sdot.onere_tipo_code = v_onere_tipo_code) OR ('T' = p_quadro_c_f AND sdot.onere_tipo_code IN ('IRPEF','IRPEG')))
AND   sto.data_cancellazione IS NULL
AND   tep.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   ros.data_cancellazione IS NULL
AND   dos.data_cancellazione IS NULL
AND   dot.data_cancellazione IS NULL
AND   tot.data_cancellazione IS NULL
--AND   totd.data_cancellazione IS NULL
--AND   dotdt.data_cancellazione IS NULL
AND   rsot.data_cancellazione IS NULL
AND   ts.data_cancellazione IS NULL
AND   td.data_cancellazione IS NULL
AND   rdo.data_cancellazione IS NULL
AND   roa.data_cancellazione IS NULL
AND   ta.data_cancellazione IS NULL
AND   sdo.data_cancellazione IS NULL
AND   sdot.data_cancellazione IS NULL
AND   sros.data_cancellazione IS NULL
AND   now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
AND   now() BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, now())
AND   now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND   now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND   now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
AND   now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
AND   now() BETWEEN dot.validita_inizio AND COALESCE(dot.validita_fine, now())
AND   now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
--AND   now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
--AND   now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
AND   now() BETWEEN rsot.validita_inizio AND COALESCE(rsot.validita_fine, now())
AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
AND   now() BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, now())
AND   now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now())
AND   now() BETWEEN roa.validita_inizio AND COALESCE(roa.validita_fine, now())
AND   now() BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, now())
AND   now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
AND   now() BETWEEN sdot.validita_inizio AND COALESCE(sdot.validita_fine, now())
AND   now() BETWEEN sros.validita_inizio AND COALESCE(sros.validita_fine, now())
GROUP BY   rdo.caus_id,
           sdo.onere_code,
           td.doc_id,
           rdo.doc_onere_id,
           rdo.somma_non_soggetta_tipo_id,
           rdo.onere_id,
           sros.soggetto_id,
           roa.testo

LOOP  

  --v_importo_lordo := 0;
  v_importoParzInpsImpon := 0;
  v_importoParzInpsNetto := 0;
  v_importoParzInpsRiten := 0;
  v_importoParzInpsEnte := 0;
  v_importo_ritenuta_inps := 0;
  v_importo_imponibile_inps := 0;
  v_importo_ente_inps := 0;
  v_importo_netto_inps := 0;
  v_codice_tributo := null;

  --v_importo_lordo := rec_tracciato_770.IMPORTO_LORDO;
  v_codice_tributo := rec_tracciato_770.onere_code;
  
  v_causale := null;
  
  BEGIN

    SELECT dc.caus_code
    INTO   STRICT v_causale
    FROM   siac_d_causale dc
    WHERE  dc.caus_id = rec_tracciato_770.caus_id
    AND    dc.data_cancellazione IS NULL
    AND    now() BETWEEN dc.validita_inizio AND COALESCE(dc.validita_fine, now());

  EXCEPTION
      
    WHEN NO_DATA_FOUND THEN
        v_causale := null;
      
  END;

  IF rec_tracciato_770.testo = 'C' THEN
   
    v_tipo_record := 'SC';   
    
    v_codice := null;
    
    IF rec_tracciato_770.somma_non_soggetta_tipo_id IS NULL THEN
    
          SELECT dsnst.somma_non_soggetta_tipo_code::varchar
          --INTO  STRICT v_codice
          INTO  v_codice
          FROM  siac_r_onere_somma_non_soggetta_tipo rosnst,
                siac_d_somma_non_soggetta_tipo dsnst
          WHERE rosnst.somma_non_soggetta_tipo_id = dsnst.somma_non_soggetta_tipo_id   
          AND   rosnst.onere_id = rec_tracciato_770.onere_id
          AND   rosnst.data_cancellazione IS NULL
          AND   dsnst.data_cancellazione IS NULL
          AND   now() BETWEEN rosnst.validita_inizio AND COALESCE(rosnst.validita_fine, now())
          AND   now() BETWEEN dsnst.validita_inizio AND COALESCE(dsnst.validita_fine, now());
                              
    ELSE

        BEGIN

          SELECT dsnst.somma_non_soggetta_tipo_code::varchar
          INTO   STRICT v_codice 
          FROM   siac_d_somma_non_soggetta_tipo dsnst
          WHERE  dsnst.somma_non_soggetta_tipo_id = rec_tracciato_770.somma_non_soggetta_tipo_id
          AND    dsnst.data_cancellazione IS NULL
          AND    now() BETWEEN dsnst.validita_inizio AND COALESCE(dsnst.validita_fine, now());  
      
        EXCEPTION
              
          WHEN NO_DATA_FOUND THEN
              v_codice := null;
              
        END;    
    
    END IF;
    
  ELSE
    
    v_tipo_record := 'SF'; 
    
  END IF;

    -- PARTE RELATIVA AL SOGGETTO INIZIO
    
    v_codice_fiscale_percipiente := null;
    v_codice_fiscale_estero := null;
    v_tipo_percipiente := null;
    v_cognome := null;
    v_nome := null;
    v_sesso := null;
    v_data_nascita := null;
    v_comune_id_nascita := null;
    v_soggetto_id := null; -- SIAC-5485 
    
    BEGIN -- SIAC-5485 INIZIO
    
    SELECT a.soggetto_id_da
    INTO   STRICT v_soggetto_id
    FROM   siac_r_soggetto_relaz a, siac_d_relaz_tipo b
    WHERE  a.ente_proprietario_id = p_ente_proprietario_id
    AND    a.relaz_tipo_id = b.relaz_tipo_id
    AND    b.relaz_tipo_code = 'SEDE_SECONDARIA'
    AND    a.soggetto_id_a = rec_tracciato_770.soggetto_id;
    
    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN      
           v_soggetto_id := rec_tracciato_770.soggetto_id; 
              
    END; -- SIAC-5485 FINE
        
    BEGIN
    
      SELECT ts.codice_fiscale,
             ts.codice_fiscale_estero,
             CASE 
                WHEN dst.soggetto_tipo_code IN ('PF','PFI') THEN
                     1
                ELSE
                     2
             END tipo_percipiente,
             coalesce(tpf.cognome, tpg.ragione_sociale) cognome,
             tpf.nome,
             tpf.sesso,
             tpf.nascita_data,
             tpf.comune_id_nascita
      INTO  STRICT v_codice_fiscale_percipiente,
            v_codice_fiscale_estero,
            v_tipo_percipiente,
            v_cognome,
            v_nome,
            v_sesso,
            v_data_nascita,
            v_comune_id_nascita                
      FROM siac_t_soggetto ts
      INNER JOIN siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
      INNER JOIN siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
      LEFT JOIN  siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                              AND now() BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, now())
                                              AND tpg.data_cancellazione IS NULL
      LEFT JOIN  siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                              AND now() BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, now())
                                              AND tpf.data_cancellazione IS NULL
      WHERE ts.soggetto_id = v_soggetto_id -- rec_tracciato_770.soggetto_id -- SIAC-5485
      AND   ts.data_cancellazione IS NULL
      AND   rst.data_cancellazione IS NULL
      AND   dst.data_cancellazione IS NULL
      AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
      AND   now() BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, now())
      AND   now() BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, now());

      v_cognome := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cognome),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
      v_nome := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_nome),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));

    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN
           null;
              
    END;
    
    v_indirizzo_principale := null;
    v_cap_indirizzo_principale := null;
    v_comune_indirizzo_principale := null;
    v_provincia_indirizzo_principale := null;

    v_indirizzo_fiscale := null; -- SIAC-5485
    v_cap_indirizzo_fiscale := null; -- SIAC-5485
    v_comune_indirizzo_fiscale := null; -- SIAC-5485
    v_provincia_indirizzo_fiscale := null; -- SIAC-5485

    v_comune_nascita := null;
    v_provincia_nascita := null;
    v_nazione_nascita := null;    
    
    FOR rec_indirizzo IN
    SELECT tis.comune_id, dit.indirizzo_tipo_code, tis.principale, tis.zip_code,
           tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
    FROM   siac.siac_t_indirizzo_soggetto tis
    INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                        AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                                        --AND now() BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, now())
                                                        --AND rist.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                              AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                              --AND now() BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, now())
                                              --AND dit.data_cancellazione IS NULL
    WHERE tis.soggetto_id = v_soggetto_id -- rec_tracciato_770.soggetto_id -- SIAC-5485
    AND   tis.principale = 'S'
    AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
    --AND   now() BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, now())
    --AND   tis.data_cancellazione IS NULL
    UNION -- SIAC-5485 INIZIO
    SELECT tis.comune_id, dit.indirizzo_tipo_code, tis.principale, tis.zip_code,
           tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
    FROM   siac.siac_t_indirizzo_soggetto tis
    INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                        AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                                        --AND now() BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, now())
                                                        --AND rist.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                              AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                              --AND now() BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, now())
                                              --AND dit.data_cancellazione IS NULL
    WHERE tis.soggetto_id = rec_tracciato_770.soggetto_id
    AND   dit.indirizzo_tipo_code = 'DOMICILIO'
    --AND   tis.principale = 'S'
    AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
    --AND   now() BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, now())
    --AND   tis.data_cancellazione IS NULL -- SIAC-5485 FINE    
    UNION
    SELECT NULL, 'NASCITA', NULL, NULL, NULL, NULL, NULL, NULL, NULL

    LOOP

      v_comune_id := null;
      v_comune_id_gen := null;
      v_via_tipo_id := null;
      v_indirizzo_tipo_code := null;
      v_principale := null;
      
      v_zip_code := null;
      v_comune_desc := null;
      v_provincia_desc := null;
      v_nazione_desc := null;
      v_indirizzo := null;
      v_via_tipo_desc := null;
      v_toponimo := null;
      v_numero_civico := null;
      v_frazione := null;
      v_interno := null;
      
      v_comune_id := rec_indirizzo.comune_id;
      v_via_tipo_id := rec_indirizzo.via_tipo_id;      
      v_indirizzo_tipo_code := rec_indirizzo.indirizzo_tipo_code;      
      v_principale := rec_indirizzo.principale;
      
      v_zip_code := rec_indirizzo.zip_code;
      v_toponimo := rec_indirizzo.toponimo;
      v_numero_civico := rec_indirizzo.numero_civico;
      v_frazione := rec_indirizzo.frazione;
      v_interno := rec_indirizzo.interno;

      BEGIN
      
        SELECT dvt.via_tipo_desc
        INTO STRICT v_via_tipo_desc
        FROM siac.siac_d_via_tipo dvt
        WHERE dvt.via_tipo_id = v_via_tipo_id
        AND now() BETWEEN dvt.validita_inizio AND COALESCE(dvt.validita_fine, now())
        AND dvt.data_cancellazione IS NULL;
      
      EXCEPTION
      
        WHEN NO_DATA_FOUND THEN
        	v_via_tipo_desc := null;
      
      END;
      
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

      v_indirizzo := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_indirizzo),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''');
      v_indirizzo := UPPER(v_indirizzo);

      IF v_indirizzo_tipo_code = 'NASCITA' THEN
         v_comune_id_gen := v_comune_id_nascita;
      ELSE
         v_comune_id_gen := v_comune_id;
      END IF;

      BEGIN

        SELECT tc.comune_desc, tp.sigla_automobilistica, tn.nazione_desc
        INTO  STRICT v_comune_desc, v_provincia_desc, v_nazione_desc
        FROM siac.siac_t_comune tc
        LEFT JOIN siac.siac_r_comune_provincia rcp ON rcp.comune_id = tc.comune_id
                                                   AND now() BETWEEN rcp.validita_inizio AND COALESCE(rcp.validita_fine, now())
                                                   AND rcp.data_cancellazione IS NULL
        LEFT JOIN siac.siac_t_provincia tp ON tp.provincia_id = rcp.provincia_id
                                           AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
                                           AND tp.data_cancellazione IS NULL
        LEFT JOIN siac.siac_t_nazione tn ON tn.nazione_id = tc.nazione_id
                                         AND now() BETWEEN tn.validita_inizio AND COALESCE(tn.validita_fine, now())
                                         AND tn.data_cancellazione IS NULL
        WHERE tc.comune_id = v_comune_id_gen
        AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
        AND tc.data_cancellazione IS NULL;

      EXCEPTION
                
        WHEN NO_DATA_FOUND THEN
             null;
                
      END;

    
      IF v_principale = 'S' THEN
         v_indirizzo_principale := v_indirizzo;
         v_cap_indirizzo_principale := v_zip_code;
         v_comune_indirizzo_principale := v_comune_desc;
         v_provincia_indirizzo_principale := v_provincia_desc;
      END IF;
       -- SIAC-5485 INIZIO
      IF  v_indirizzo_tipo_code = 'DOMICILIO' THEN
         v_indirizzo_fiscale := v_indirizzo;
         v_cap_indirizzo_fiscale := v_zip_code;
         v_comune_indirizzo_fiscale := v_comune_desc;
         v_provincia_indirizzo_fiscale := v_provincia_desc;      
      END IF;
      -- SIAC-5485 FINE
      IF  v_indirizzo_tipo_code = 'NASCITA' THEN
          v_comune_nascita := v_comune_desc;
          v_provincia_nascita := v_provincia_desc;
          v_nazione_nascita := v_nazione_desc;
      END IF;    

    END LOOP;

    v_cap_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cap_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_comune_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_provincia_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_cap_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cap_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_comune_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_provincia_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_comune_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_provincia_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_nazione_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_nazione_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));

    -- PARTE RELATIVA AL SOGGETTO FINE

    v_somma_non_soggetta := 0;  
    v_importo_imponibile := 0;
    v_importo_lordo := 0;
/*     v_ord_ts_det_importo := 0;

   SELECT rdo.somma_non_soggetta,  --> id 32 
           rdo.importo_imponibile,  --> id 33 
           totd.ord_ts_det_importo  --> id 34 e id 35 a 0
    INTO   v_somma_non_soggetta,   
           v_importo_imponibile,
           v_ord_ts_det_importo -- Ritenute a titolo d' acconto           
    FROM   siac_r_doc_onere_ordinativo_ts rdoot   
    INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
    INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
    INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
    INNER  JOIN siac_r_doc_onere rdo ON rdoot.doc_onere_id = rdo.doc_onere_id
    WHERE  rdoot.doc_onere_id = rec_tracciato_770.doc_onere_id
    AND    dotdt.ord_ts_det_tipo_code = 'A'  
    AND    rdoot.data_cancellazione IS NULL
    AND    tot.data_cancellazione IS NULL
    AND    totd.data_cancellazione IS NULL
    AND    dotdt.data_cancellazione IS NULL
    AND    rdo.data_cancellazione IS NULL
    AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
    AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
    AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
    AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
    AND    now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now());*/

    BEGIN

      SELECT COALESCE(rdo.somma_non_soggetta,0),  --> id 31 
             COALESCE(rdo.importo_imponibile,0)   --> id 32 
      INTO   STRICT v_somma_non_soggetta,   
             v_importo_imponibile    
      FROM   siac_r_doc_onere rdo
      WHERE  rdo.doc_onere_id = rec_tracciato_770.doc_onere_id
      AND    rdo.data_cancellazione IS NULL
      AND    now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now());
      
    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN
           null;
              
    END;
    
    v_importo_lordo := v_importo_imponibile + v_somma_non_soggetta;
      
      v_ord_ts_det_importo := 0;

      BEGIN

        SELECT SUM(totd.ord_ts_det_importo) --> id 34 e id 35 a 0
        INTO   STRICT v_ord_ts_det_importo -- Ritenute a titolo d' acconto           
        FROM   siac_r_doc_onere_ordinativo_ts rdoot 
        INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
        INNER  JOIN siac_t_ordinativo sto ON sto.ord_id = tot.ord_id
        INNER  JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
        INNER  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id      
        INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
        INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
        WHERE  rdoot.doc_onere_id = rec_tracciato_770.doc_onere_id
        AND    dotdt.ord_ts_det_tipo_code = 'A'  
        AND    dos.ord_stato_code <> 'A'
        AND    rdoot.data_cancellazione IS NULL
        AND    tot.data_cancellazione IS NULL
        AND    sto.data_cancellazione IS NULL
        AND    ros.data_cancellazione IS NULL
        AND    dos.data_cancellazione IS NULL    
        AND    totd.data_cancellazione IS NULL
        AND    dotdt.data_cancellazione IS NULL
        AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
        AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
        AND    now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
        AND    now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
        AND    now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
        AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
        AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now());

      EXCEPTION
                
        WHEN NO_DATA_FOUND THEN
             null;
                
      END;

IF rec_tracciato_770.testo = 'F' THEN

  BEGIN

    v_aliquota := 0;

    SELECT roa.percentuale
    INTO   STRICT v_aliquota
    FROM   siac_d_onere sdo, siac_r_onere_attr roa, siac_t_attr ta
    WHERE  sdo.onere_id = rec_tracciato_770.onere_id
    AND    sdo.onere_id = roa.onere_id    
    AND    roa.attr_id = ta.attr_id
    AND    ta.attr_code = 'ALIQUOTA_SOGG'
    AND    sdo.data_cancellazione IS NULL
    AND    roa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
    AND    now() BETWEEN roa.validita_inizio AND COALESCE(roa.validita_fine, now())
    AND    now() BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, now());

  EXCEPTION
                
    WHEN NO_DATA_FOUND THEN
         null;
                
  END;

END IF;

IF rec_tracciato_770.testo = 'C' THEN

      v_importo_carico_ente := 0;
      v_importo_carico_soggetto := 0; 

      /* verifico quante quote ci sono relative alla fattura */
  /*    v_numeroQuoteFattura := 0;
  		            
      SELECT count(*)
      INTO   v_numeroQuoteFattura
      FROM   siac_t_subdoc
      WHERE  doc_id= rec_tracciato_770.doc_id;
                
      IF NOT FOUND THEN
          v_numeroQuoteFattura := 0;
      END IF;*/

      FOR rec_inps IN  
      SELECT td.doc_importo IMPORTO_FATTURA,
             ts.subdoc_importo IMPORTO_QUOTA,
             rdo.importo_carico_ente,
             --totd.ord_ts_det_importo
             --rdo.importo_carico_soggetto
             rdo.doc_onere_id
      FROM  siac_t_ordinativo sto
      INNER JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
      INNER JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
      INNER JOIN siac_t_ordinativo_ts tot ON tot.ord_id = sto.ord_id
      INNER JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
      INNER JOIN siac_d_ordinativo_ts_det_tipo dotdt ON dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
      INNER JOIN siac_r_subdoc_ordinativo_ts rsot ON rsot.ord_ts_id = tot.ord_ts_id
      INNER JOIN siac_t_subdoc ts ON ts.subdoc_id = rsot.subdoc_id
      INNER JOIN siac_t_doc td ON td.doc_id = ts.doc_id
      INNER JOIN siac_r_doc_onere rdo ON rdo.doc_id = td.doc_id
      INNER JOIN siac_d_onere sdo ON sdo.onere_id = rdo.onere_id
      INNER JOIN siac_d_onere_tipo sdot ON sdot.onere_tipo_id = sdo.onere_tipo_id
      WHERE td.doc_id = rec_tracciato_770.doc_id
      AND   dos.ord_stato_code <> 'A'
      AND   dotdt.ord_ts_det_tipo_code = 'A'
      AND   sdot.onere_tipo_code = 'INPS'
      AND   sto.data_cancellazione IS NULL
      AND   ros.data_cancellazione IS NULL
      AND   dos.data_cancellazione IS NULL
      AND   tot.data_cancellazione IS NULL
      AND   totd.data_cancellazione IS NULL
      AND   dotdt.data_cancellazione IS NULL
      AND   rsot.data_cancellazione IS NULL
      AND   ts.data_cancellazione IS NULL
      AND   td.data_cancellazione IS NULL
      AND   rdo.data_cancellazione IS NULL
      AND   sdo.data_cancellazione IS NULL
      AND   sdot.data_cancellazione IS NULL
      AND   now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
      AND   now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
      AND   now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
      AND   now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
      AND   now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
      AND   now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
      AND   now() BETWEEN rsot.validita_inizio AND COALESCE(rsot.validita_fine, now())
      AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
      AND   now() BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, now())
      AND   now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now())
      AND   now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
      AND   now() BETWEEN sdot.validita_inizio AND COALESCE(sdot.validita_fine, now())
       
      LOOP
      
        BEGIN

          SELECT SUM(totd.ord_ts_det_importo)
          INTO   STRICT v_importo_carico_soggetto           
          FROM   siac_r_doc_onere_ordinativo_ts rdoot 
          INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
          INNER  JOIN siac_t_ordinativo sto ON sto.ord_id = tot.ord_id
          INNER  JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
          INNER  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id      
          INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
          INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
          WHERE  rdoot.doc_onere_id = rec_inps.doc_onere_id
          AND    dotdt.ord_ts_det_tipo_code = 'A'  
          AND    dos.ord_stato_code <> 'A'
          AND    rdoot.data_cancellazione IS NULL
          AND    tot.data_cancellazione IS NULL
          AND    sto.data_cancellazione IS NULL
          AND    ros.data_cancellazione IS NULL
          AND    dos.data_cancellazione IS NULL    
          AND    totd.data_cancellazione IS NULL
          AND    dotdt.data_cancellazione IS NULL
          AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
          AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
          AND    now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
          AND    now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
          AND    now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
          AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
          AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now());

        EXCEPTION
                  
          WHEN NO_DATA_FOUND THEN
               null;
                  
        END;    
      
          --v_importo_carico_soggetto := rec_inps.importo_carico_soggetto;
          --v_importo_carico_ente := rec_inps.importo_carico_ente;
          v_percQuota := 0;    	          
                                                  
          -- calcolo la percentuale della quota corrente rispetto
          -- al totale fattura.
          v_percQuota := COALESCE(rec_inps.IMPORTO_QUOTA,0)*100/COALESCE(rec_inps.IMPORTO_FATTURA,0);                
                                                       
          --raise notice 'IRAP ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
          --raise notice 'ESTRATTO: IMPON =%, RITEN = %, ENTE =%', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,elencoMandati.IMPORTO_CARICO_ENTE;          
          --raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
                                
          -- la fattura e' la stessa della quota precedente.       		      
          ----IF v_idFatturaOld = rec_tracciato_770.doc_id THEN
              ----v_contaQuotaInps := v_contaQuotaInps + 1;
              --raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrap;
              -- e' l'ultima quota della fattura:
              -- gli importi sono quelli totali meno quelli delle quote
              -- precedenti, per evitare problemi di arrotondamento.            
  /*          IF v_contaQuotaInps = v_numeroQuoteFattura THEN
              --raise notice 'ULTIMA QUOTA'; 
              v_importo_imponibile_inps := v_importo_imponibile - v_importoParzInpsImpon;
              v_importo_ritenuta_inps := v_importo_carico_soggetto - v_importoParzInpsRiten;
              v_importo_ente_inps := rec_inps.importo_carico_ente - v_importoParzInpsEnte;                                  
              -- azzero gli importi parziali per fattura
              v_importoParzInpsImpon := 0;
              v_importoParzInpsRiten := 0;
              v_importoParzInpsEnte := 0;
              v_importoParzInpsNetto := 0;
              v_contaQuotaInps := 0;      
            ELSE*/
              --raise notice 'ALTRA QUOTA';
              --v_importo_imponibile_inps := v_importo_imponibile*v_percQuota/100;
              --v_importo_ritenuta_inps := v_importo_carico_soggetto*v_percQuota/100; 
              ----v_importo_ente_inps := rec_inps.importo_carico_ente*v_percQuota/100;
              --v_importo_netto_inps := v_importo_lordo-v_importo_ritenuta_inps;                      
              -- sommo l'importo della quota corrente
              -- al parziale per fattura.
              --v_importoParzInpsImpon := v_importoParzInpsImpon + v_importo_imponibile_inps;
              --v_importoParzInpsRiten := v_importoParzInpsRiten + v_importo_ritenuta_inps;
              ----v_importoParzInpsEnte :=  v_importoParzInpsEnte + v_importo_ente_inps;
              --v_importoParzInpsNetto := v_importoParzInpsNetto + v_importo_netto_inps;                      
            --END IF;      
          ----ELSE -- fattura diversa dalla precedente
            --raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            --v_importo_imponibile_inps := v_importo_imponibile*v_percQuota/100;
            --v_importo_ritenuta_inps := v_importo_carico_soggetto*v_percQuota/100; 
            v_importo_ente_inps := COALESCE(rec_inps.importo_carico_ente,0)*v_percQuota/100;
            --v_importo_netto_inps := v_importo_lordo - v_importo_ritenuta_inps;
            -- imposto l'importo della quota corrente
            -- al parziale per fattura.            
            --v_importoParzInpsImpon := v_importo_imponibile_inps;
            --v_importoParzInpsRiten := v_importo_ritenuta_inps;
            ----v_importoParzInpsEnte := v_importo_ente_inps;
            --v_importoParzInpsNetto := v_importo_netto_inps;
            ----v_contaQuotaInps := 1;            
          ----END IF;                                    
          --raise notice 'ParzImpon = %, ParzRiten = %, ParzEnte = %, ParzNetto = %', importoParzIrapImpon,importoParzIrapRiten,importoParzIrapEnte,importoParzIrapNetto;                
          --raise notice 'IMPON =%, RITEN = %, ENTE =%, NETTO= %', importo_imponibile_irap, importo_ritenuta_irap,importo_ente_irap,importo_ente_irap; 
          ----v_idFatturaOld := rec_tracciato_770.doc_id;    
          v_importo_carico_ente :=  v_importo_carico_ente + v_importo_ente_inps;  
      END LOOP;
  
    END IF;  
           
    IF rec_tracciato_770.testo = 'F' THEN
       null;
       -- Aliquota
       -- Ritenute Operate
    END IF;
        
    IF rec_tracciato_770.testo = 'C' THEN
    
      INSERT INTO siac.tracciato_770_quadro_c_temp
       (
        elab_id_temp,
        elab_id_det_temp,
        ente_proprietario_id,
        tipo_record,
        codice_fiscale_ente,
        codice_fiscale_percipiente,
        tipo_percipiente,
        cognome_denominazione,
        nome,
        sesso,
        data_nascita,
        comune_nascita,
        provincia_nascita,
        comune_domicilio_spedizione,
        provincia_domicilio_spedizione,
        indirizzo_domicilio_spedizione,
        cap_domicilio_spedizione,
        percipienti_esteri_cod_fiscale,
        causale,
        ammontare_lordo_corrisposto,
        altre_somme_no_ritenute,
        imponibile_b,
        ritenute_titolo_acconto_b,
        ritenute_titolo_imposta_b,
        contr_prev_carico_sog_erogante,
        contr_prev_carico_sog_percipie,
        codice,
        anno_competenza,
        codice_tributo
        )
         VALUES
        ( v_elab_id,
          v_elab_id_det_temp,
          p_ente_proprietario_id,
          v_tipo_record,
          v_codice_fiscale_ente,
          v_codice_fiscale_percipiente,
          v_tipo_percipiente,
          v_cognome,
          v_nome,
          v_sesso,
          v_data_nascita,    
          COALESCE(v_comune_nascita, v_nazione_nascita), 
          v_provincia_nascita,
          v_comune_indirizzo_principale, 
          v_provincia_indirizzo_principale, 
          v_indirizzo_principale, 
          v_cap_indirizzo_principale,           
          v_codice_fiscale_estero,
          v_causale,
          v_importo_lordo,
          v_somma_non_soggetta,   
          v_importo_imponibile,
          v_ord_ts_det_importo,
          0,
          v_importo_carico_ente,
          v_importo_carico_soggetto,      
          v_codice,
          p_anno_elab,
          v_codice_tributo
        );         
    
    END IF;    
    
    IF rec_tracciato_770.testo = 'F' THEN    
    
      INSERT INTO siac.tracciato_770_quadro_f_temp
       (
        elab_id_temp,
        elab_id_det_temp,
        ente_proprietario_id,
        tipo_record,
        codice_fiscale_ente,
        codice_fiscale_percipiente,
        tipo_percipiente,
        cognome_denominazione,
        nome,
        sesso,
        data_nascita,
        comune_nascita,
        provincia_nascita,
        comune_domicilio_fiscale,
        provincia_domicilio_fiscale,
        indirizzo_domicilio_fiscale,
        cap_domicilio_spedizione,
        codice_identif_fiscale_estero,
        causale,
        ammontare_lordo_corrisposto,
        altre_somme_no_ritenute,
        aliquota,
        ritenute_operate,
        ritenute_sospese,
        rimborsi,
        anno_competenza,
        codice_tributo
        )
         VALUES
        ( v_elab_id,
          v_elab_id_det_temp,
          p_ente_proprietario_id,
          v_tipo_record,
          v_codice_fiscale_ente,
          v_codice_fiscale_percipiente,
          v_tipo_percipiente,
          v_cognome,
          v_nome,
          v_sesso,
          v_data_nascita,    
          COALESCE(v_comune_nascita, v_nazione_nascita), 
          v_provincia_nascita,
          COALESCE(v_comune_indirizzo_fiscale, v_comune_indirizzo_principale), 
          COALESCE(v_provincia_indirizzo_fiscale, v_provincia_indirizzo_principale), 
          COALESCE(v_indirizzo_fiscale, v_indirizzo_principale), 
          COALESCE(v_cap_indirizzo_fiscale, v_cap_indirizzo_principale),           
          v_codice_fiscale_estero,
          v_causale,
          v_importo_lordo,
          v_somma_non_soggetta,   
          v_aliquota,
          v_ord_ts_det_importo,
          0,
          0,    
          p_anno_elab,
          v_codice_tributo
        );         
     
    END IF;
    
  v_elab_id_det_temp := v_elab_id_det_temp + 1;
     
END LOOP;

IF p_quadro_c_f IN ('C','T') THEN
  v_elab_id_det := 1;
  -- Parte relativa al caricamento della tabella finale
  FOR rec_tracciato_fin_c IN
  SELECT   
    tipo_record,
    rpad(substring(coalesce(codice_fiscale_ente,'') from 1 for 16), 16, ' ') codice_fiscale_ente,
    rpad(substring(coalesce(codice_fiscale_percipiente,'') from 1 for 16), 16, ' ') codice_fiscale_percipiente,
    tipo_percipiente,
    rpad(substring(coalesce(cognome_denominazione,'') from 1 for 24), 24, ' ') cognome_denominazione,
    rpad(substring(coalesce(nome,'') from 1 for 20), 20, ' ') nome,
    rpad(coalesce(sesso,''), 1, ' ') sesso,
    lpad(coalesce(to_char(data_nascita,'yyyymmdd'),''),8,'0') data_nascita,
    rpad(substring(coalesce(comune_nascita,'') from 1 for 21), 21, ' ') comune_nascita,
    rpad(substring(coalesce(provincia_nascita,'') from 1 for 2), 2, ' ') provincia_nascita,
    rpad(substring(coalesce(comune_domicilio_spedizione,'') from 1 for 21), 21, ' ') comune_domicilio_spedizione,
    rpad(substring(coalesce(provincia_domicilio_spedizione,'') from 1 for 2), 2, ' ') provincia_domicilio_spedizione,
    rpad(substring(coalesce(indirizzo_domicilio_spedizione,'') from 1 for 35), 35, ' ') indirizzo_domicilio_spedizione,
    rpad(substring(coalesce(cap_domicilio_spedizione,'') from 1 for 5), 5, ' ') cap_domicilio_spedizione,
    rpad(substring(coalesce(percipienti_esteri_cod_fiscale,'') from 1 for 20), 20, ' ') percipienti_esteri_cod_fiscale,
    rpad(substring(coalesce(causale,'') from 1 for 2), 2, ' ') causale,
    rpad(substring(coalesce(codice,'') from 1 for 1), 1, ' ') codice,
    anno_competenza,
    lpad((SUM(coalesce(ammontare_lordo_corrisposto,0))*100)::bigint::varchar, 11, '0')::varchar ammontare_lordo_corrisposto,
    lpad((SUM(coalesce(altre_somme_no_ritenute,0))*100)::bigint::varchar, 11, '0') altre_somme_no_ritenute,
    lpad((SUM(coalesce(imponibile_b,0))*100)::bigint::varchar, 11, '0') imponibile_b,
    lpad((SUM(coalesce(ritenute_titolo_acconto_b,0))*100)::bigint::varchar, 11, '0') ritenute_titolo_acconto_b,
    lpad((SUM(coalesce(ritenute_titolo_imposta_b,0))*100)::bigint::varchar, 11, '0') ritenute_titolo_imposta_b,
    lpad((SUM(coalesce(contr_prev_carico_sog_erogante,0))*100)::bigint::varchar, 11, '0') contr_prev_carico_sog_erogante,
    lpad((SUM(coalesce(contr_prev_carico_sog_percipie,0))*100)::bigint::varchar, 11, '0') contr_prev_carico_sog_percipie,
    lpad(codice_tributo,4,'0') codice_tributo
  FROM tracciato_770_quadro_c_temp
  WHERE elab_id_temp = v_elab_id
  AND   ente_proprietario_id = p_ente_proprietario_id
  AND   anno_competenza = p_anno_elab
  GROUP BY
    tipo_record,
    codice_fiscale_ente,
    codice_fiscale_percipiente,
    tipo_percipiente,
    cognome_denominazione,
    nome,
    sesso,
    data_nascita,
    comune_nascita,
    provincia_nascita,
    comune_domicilio_spedizione,
    provincia_domicilio_spedizione,
    indirizzo_domicilio_spedizione,
    cap_domicilio_spedizione,
    percipienti_esteri_cod_fiscale,
    causale,
    codice,
    anno_competenza,
    codice_tributo
    
  LOOP
            
      INSERT INTO siac.tracciato_770_quadro_c
        ( 
          elab_id,
          elab_id_det,
          elab_data,
          ente_proprietario_id,
          tipo_record,
          codice_fiscale_ente,
          codice_fiscale_percipiente,
          tipo_percipiente,
          cognome_denominazione,
          nome,
          sesso,
          data_nascita,
          comune_nascita,
          provincia_nascita,
          colonna_1,
          colonna_2 ,
          comune_domicilio_fiscale_prec,
          comune_domicilio_spedizione,
          provincia_domicilio_spedizione,
          colonna_3,
          esclusione_precompilata,
          categorie_particolari,
          indirizzo_domicilio_spedizione,
          cap_domicilio_spedizione,
          colonna_4,
          codice_sede,
          comune_domicilio_fiscale,
          rappresentante_codice_fiscale,
          percipienti_esteri_no_res,
          percipienti_esteri_localita,
          percipienti_esteri_stato,
          percipienti_esteri_cod_fiscale,
          ex_causale,
          ammontare_lordo_corrisposto,
          somme_no_ritenute_regime_conv,
          altre_somme_no_ritenute,
          imponibile_b,
          ritenute_titolo_acconto_b,
          ritenute_titolo_imposta_b,
          ritenute_sospese_b,
          anticipazione,
          anno,
          add_reg_titolo_acconto_b,
          add_reg_titolo_imposta_b,
          add_reg_sospesa_b,
          imponibile_anni_prec,
          ritenute_operate_anni_prec,
          contr_prev_carico_sog_erogante,
          contr_prev_carico_sog_percipie,
          spese_rimborsate,
          ritenute_rimborsate,
          colonna_5,
          percipienti_esteri_via_numciv,
          colonna_6,
          eventi_eccezionali,
          somme_prima_data_fallimento,
          somme_curatore_commissario,
          colonna_7,
          colonna_8,
          codice,
          colonna_9,
          codice_fiscale_e,
          imponibile_e,
          ritenute_titolo_acconto_e,
          ritenute_titolo_imposta_e,
          ritenute_sospese_e,
          add_reg_titolo_acconto_e,
          add_reg_titolo_imposta_e,
          add_reg_sospesa_e,
          add_com_titolo_acconto_e,
          add_com_titolo_imposta_e,
          add_com_sospesa_e,
          add_com_titolo_acconto_b,
          add_com_titolo_imposta_b,
          add_com_sospesa_b,
          colonna_10,
          codice_fiscale_redd_diversi_f,
          codice_fiscale_pignoramento_f,
          codice_fiscale_esproprio_f,
          colonna_11,
          colonna_12,
          colonna_13,
          colonna_14,
          colonna_15,
          colonna_16,
          colonna_17,
          colonna_18,
          colonna_19,
          colonna_20,
          colonna_21,
          colonna_22,
          colonna_23,
          codice_fiscale_ente_prev,
          denominazione_ente_prev,
          codice_ente_prev,
          codice_azienda,
          categoria,
          altri_contributi,
          importo_altri_contributi,
          contributi_dovuti,
          contributi_versati,
          causale,
          colonna_24,
          colonna_25,
          colonna_26,
          colonna_27,
          anno_competenza,
          ex_ente,
          progressivo,
          matricola,
          codice_tributo,
          versione_tracciato_procsi,
          colonna_28,
          caratteri_controllo_1,
          caratteri_controllo_2
        )
      VALUES
        ( v_elab_id,
          v_elab_id_det,
          now(),
          p_ente_proprietario_id,
          rec_tracciato_fin_c.tipo_record,
          rec_tracciato_fin_c.codice_fiscale_ente,
          rec_tracciato_fin_c.codice_fiscale_percipiente,
          rec_tracciato_fin_c.tipo_percipiente,
          rec_tracciato_fin_c.cognome_denominazione,
          rec_tracciato_fin_c.nome,
          rec_tracciato_fin_c.sesso,
          rec_tracciato_fin_c.data_nascita,
          rec_tracciato_fin_c.comune_nascita,
          rec_tracciato_fin_c.provincia_nascita,
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rec_tracciato_fin_c.comune_domicilio_spedizione,
          rec_tracciato_fin_c.provincia_domicilio_spedizione,
          rpad(' ',3,' '),
          rpad(' ',1,' '),
          rpad(' ',2,' '),
          rec_tracciato_fin_c.indirizzo_domicilio_spedizione,
          rec_tracciato_fin_c.cap_domicilio_spedizione,
          rpad(' ',57,' '),
          rpad(' ',3,' '),
          rpad(' ',4,' '),
          rpad(' ',16,' '),
          rpad(' ',1,' '),
          rpad(' ',35,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_c.percipienti_esteri_cod_fiscale,
          rpad(' ',1,' '),
          rec_tracciato_fin_c.ammontare_lordo_corrisposto,
          lpad('0',11,'0'),
          rec_tracciato_fin_c.altre_somme_no_ritenute,
          rec_tracciato_fin_c.imponibile_b,
          rec_tracciato_fin_c.ritenute_titolo_acconto_b,
          rec_tracciato_fin_c.ritenute_titolo_imposta_b,
          lpad('0',11,'0'),
          lpad('0',1,'0'),
          lpad('0',4,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rec_tracciato_fin_c.contr_prev_carico_sog_erogante,
          rec_tracciato_fin_c.contr_prev_carico_sog_percipie,
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          rpad(' ',1,' '),
          lpad('0',1,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',11,' '),
          rpad(' ',1,' '),        
          rec_tracciato_fin_c.codice,
          rpad(' ',9,' '),
          rpad(' ',16,' '),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',103,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',1,' '),
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',6,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',4,' '),
          rpad(' ',9,' '),
          rpad(' ',1,' '),
          rpad(' ',16,' '),
          rpad(' ',30,' '),
          rpad(' ',1,' '),
          rpad(' ',15,' '),
          rpad(' ',1,' '),
          lpad('0',1,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rec_tracciato_fin_c.causale,
          rpad(' ',1044,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),          
          rpad(' ',1818,' '),
          rec_tracciato_fin_c.anno_competenza,
          rpad(p_ex_ente,4,' '),
          lpad((v_elab_id_det)::varchar,7,'0'),
          lpad((v_matricola_c)::varchar,7,'0'),
          rec_tracciato_fin_c.codice_tributo,
          'V12',
          rpad(' ',9,' '),
          'A',
          NULL
        );      
    
       v_matricola_c := 8000000 + v_elab_id_det;
       v_elab_id_det := v_elab_id_det + 1;
       
  END LOOP;
  
END IF;

IF p_quadro_c_f IN ('F','T') THEN
  v_elab_id_det := 1;
  -- Parte relativa al caricamento della tabella finale
  FOR rec_tracciato_fin_f IN
  SELECT   
    tipo_record,
    rpad(substring(coalesce(codice_fiscale_ente,'') from 1 for 16), 16, ' ') codice_fiscale_ente,
    rpad(substring(coalesce(codice_fiscale_percipiente,'') from 1 for 16), 16, ' ') codice_fiscale_percipiente,
    tipo_percipiente,
    rpad(substring(coalesce(cognome_denominazione,'') from 1 for 24), 24, ' ') cognome_denominazione,
    rpad(substring(coalesce(nome,'') from 1 for 20), 20, ' ') nome,
    rpad(coalesce(sesso,''), 1, ' ') sesso,
    lpad(coalesce(to_char(data_nascita,'yyyymmdd'),''),8,'0') data_nascita,
    rpad(substring(coalesce(comune_nascita,'') from 1 for 21), 21, ' ') comune_nascita,
    rpad(substring(coalesce(provincia_nascita,'') from 1 for 2), 2, ' ') provincia_nascita,
    rpad(substring(coalesce(comune_domicilio_fiscale,'') from 1 for 21), 21, ' ') comune_domicilio_fiscale,
    rpad(substring(coalesce(provincia_domicilio_fiscale,'') from 1 for 2), 2, ' ') provincia_domicilio_fiscale,
    rpad(substring(coalesce(indirizzo_domicilio_fiscale,'') from 1 for 35), 35, ' ') indirizzo_domicilio_fiscale,
    rpad(substring(coalesce(cap_domicilio_spedizione,'') from 1 for 5), 5, ' ') cap_domicilio_spedizione,
    rpad(substring(coalesce(codice_identif_fiscale_estero,'') from 1 for 20), 20, ' ') codice_identif_fiscale_estero,
    rpad(substring(coalesce(causale,'') from 1 for 1), 1, ' ') causale,
    anno_competenza,
    lpad((SUM(coalesce(ammontare_lordo_corrisposto,0))*100)::bigint::varchar, 13, '0')::varchar ammontare_lordo_corrisposto,
    lpad((SUM(coalesce(altre_somme_no_ritenute,0))*100)::bigint::varchar, 13, '0') altre_somme_no_ritenute,
    lpad((SUM(coalesce(ritenute_operate,0))*100)::bigint::varchar, 13, '0') ritenute_operate,
    lpad((SUM(coalesce(ritenute_sospese,0))*100)::bigint::varchar, 13, '0') ritenute_sospese,
    lpad((SUM(coalesce(rimborsi,0))*100)::bigint::varchar, 13, '0') rimborsi,
    lpad(codice_tributo,4,'0') codice_tributo,
    lpad((coalesce(aliquota,0)*100)::bigint::varchar,5,'0') aliquota
  FROM tracciato_770_quadro_f_temp
  WHERE elab_id_temp = v_elab_id
  AND   ente_proprietario_id = p_ente_proprietario_id
  AND   anno_competenza = p_anno_elab
  GROUP BY
    tipo_record,
    codice_fiscale_ente,
    codice_fiscale_percipiente,
    tipo_percipiente,
    cognome_denominazione,
    nome,
    sesso,
    data_nascita,
    comune_nascita,
    provincia_nascita,
    comune_domicilio_fiscale,
    provincia_domicilio_fiscale,
    indirizzo_domicilio_fiscale,
    cap_domicilio_spedizione,
    codice_identif_fiscale_estero,
    causale,
    anno_competenza,
    codice_tributo,
    aliquota
    
  LOOP
            
      INSERT INTO siac.tracciato_770_quadro_f
        ( 
          elab_id,
          elab_id_det,
          elab_data,
          ente_proprietario_id,
          tipo_record,
          codice_fiscale_ente,
          codice_fiscale_percipiente,
          tipo_percipiente,
          cognome_denominazione,
          nome,
          sesso,
          data_nascita,
          comune_nascita,
          provincia_nascita,
          comune_domicilio_fiscale,
          provincia_domicilio_fiscale,
          indirizzo_domicilio_fiscale,
          colonna_1,
          colonna_2,
          colonna_3,
          colonna_4,
          cap_domicilio_spedizione,
          colonna_5,
          codice_stato_estero,
          codice_identif_fiscale_estero,
          causale,
          ammontare_lordo_corrisposto,
          somme_no_soggette_ritenuta,
          aliquota,
          ritenute_operate,
          ritenute_sospese,
          codice_fiscale_rappr_soc,
          cognome_denom_rappr_soc,
          nome_rappr_soc,
          sesso_rappr_soc,
          data_nascita_rappr_soc,
          comune_nascita_rappr_soc,
          provincia_nascita_rappr_soc,
          comune_dom_fiscale_rappr_soc,
          provincia_rappr_soc,
          indirizzo_rappr_soc,
          codice_stato_estero_rappr_soc,
          rimborsi,
          colonna_6,
          colonna_7,
          colonna_8,
          colonna_9,
          colonna_10,
          colonna_11,
          colonna_12,
          colonna_13,
          colonna_14,
          colonna_15,
          colonna_16,
          colonna_17,
          colonna_18,
          colonna_19,
          colonna_20,
          colonna_21,
          colonna_22,
          colonna_23,
          anno_competenza,
          ex_ente,
          progressivo,
          matricola,
          codice_tributo,
          versione_tracciato_procsi,
          colonna_28,
          caratteri_controllo_1, 
          caratteri_controllo_2
        )
      VALUES
        ( v_elab_id,
          v_elab_id_det,
          now(),
          p_ente_proprietario_id,
          rec_tracciato_fin_f.tipo_record,
          rec_tracciato_fin_f.codice_fiscale_ente,
          rec_tracciato_fin_f.codice_fiscale_percipiente,
          rec_tracciato_fin_f.tipo_percipiente,
          rec_tracciato_fin_f.cognome_denominazione,
          rec_tracciato_fin_f.nome,
          rec_tracciato_fin_f.sesso,
          rec_tracciato_fin_f.data_nascita,
          rec_tracciato_fin_f.comune_nascita,
          rec_tracciato_fin_f.provincia_nascita,
          rec_tracciato_fin_f.comune_domicilio_fiscale,
          rec_tracciato_fin_f.provincia_domicilio_fiscale,
          rec_tracciato_fin_f.indirizzo_domicilio_fiscale,
          rpad(' ',60,' '),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          rec_tracciato_fin_f.cap_domicilio_spedizione,
          rpad(' ',31,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_f.codice_identif_fiscale_estero,
          rec_tracciato_fin_f.causale,
          rec_tracciato_fin_f.ammontare_lordo_corrisposto,
          rec_tracciato_fin_f.altre_somme_no_ritenute,
          rec_tracciato_fin_f.aliquota,
          rec_tracciato_fin_f.ritenute_operate,
          rec_tracciato_fin_f.ritenute_sospese,
          rpad(' ',16,' '),
          rpad(' ',60,' '),
          rpad(' ',20,' '),
          rpad(' ',1,' '),
          lpad('0',8,'0'),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_f.rimborsi,
          rpad(' ',315,' '),
          rpad(' ',16,' '),       
          rpad(' ',1,' '),      
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',6,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',4,' '),
          rpad(' ',9,' '),
          rpad(' ',1,' '),
          rpad(' ',1143,' '),
          rpad(' ',4,' '),    
          rpad(' ',4,' '),
          rpad(' ',1818,' '),                                                                                                                                              
          rec_tracciato_fin_f.anno_competenza,
          rpad(p_ex_ente,4,' '),
          lpad((v_elab_id_det)::varchar,7,'0'),
          lpad((v_matricola_f)::varchar,7,'0'),
          rec_tracciato_fin_f.codice_tributo,
          'V12',
          rpad(' ',9,' '),
          'A',
          NULL
        );      
    
       v_matricola_f := 9000000 + v_elab_id_det;
       v_elab_id_det := v_elab_id_det + 1;
       
  END LOOP;
             
END IF;  

messaggioRisultato := 'OK';

-- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
UPDATE  mif_t_flusso_elaborato
SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
    (elab_mif_esito_ok,'Elaborazione conclusa [stato OK] per tipo flusso '||v_tipo_flusso, now())
WHERE flusso_elab_mif_id = v_elab_id;

RETURN messaggioRisultato;

EXCEPTION

	WHEN OTHERS  THEN
         messaggioRisultato := SUBSTRING(UPPER(SQLERRM) from 1 for 100);
         -- RETURN NEXT;
		 messaggioRisultato := UPPER(messaggioRisultato);
        
        INSERT INTO mif_t_flusso_elaborato
        (flusso_elab_mif_data,
         flusso_elab_mif_esito,
         flusso_elab_mif_esito_msg,
         flusso_elab_mif_file_nome,
         flusso_elab_mif_tipo_id,
         flusso_elab_mif_id_flusso_oil,
         validita_inizio,
         validita_fine,
         ente_proprietario_id,
         login_operazione)
         (SELECT now(),
                 elab_mif_esito_ko,
                 'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato,
                 tipo.flusso_elab_mif_nome_file,
                 tipo.flusso_elab_mif_tipo_id,
                 null, -- flussoElabMifOilId, -- non usato per questo tipo di flusso
                 now(),
                 now(),
                 p_ente_proprietario_id,
                 v_login
          FROM mif_d_flusso_elaborato_tipo tipo
          WHERE tipo.ente_proprietario_id = p_ente_proprietario_id
          AND   tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
          AND   tipo.data_cancellazione IS NULL
          AND   tipo.validita_fine IS NULL
         );
         
         RETURN messaggioRisultato;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;