/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
  -- Variabili per attivita' iva
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
  --SIAC-5895
  v_bil_id_prec INTEGER:=null;
  v_anno_prec INTEGER:=null;
  v_elem_tipo_id INTEGER:=null;
  v_ex_anno VARCHAR:=null;
  v_ex_capitolo VARCHAR:= null;
  v_ex_articolo VARCHAR:=null;
  v_FlagEntrataDubbiaEsigFCDE VARCHAR:=null;   -- SIAC-8531   Haitham 17/01/2022   Haitham 17/01/2022

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

select fnc_siac_random_user()
into	v_user_table;

IF p_data IS NULL THEN
   p_data := now();
END IF;

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
'fnc_siac_dwh_capitolo_entrata',
params,
clock_timestamp(),
v_user_table
);

select fnc_siac_bko_popola_siac_r_class_fam_class_tipo(p_ente_proprietario_id)
into v_fnc_result;

esito:= 'Inizio funzione carico capitoli di entrata (FNC_SIAC_DWH_CAPITOLO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

-- SIAC-5895
esito:= '  Inizio Identificazione bilancio precedente - '||clock_timestamp();
RETURN NEXT;
select tb.bil_id,tp.anno
into v_bil_id_prec, v_anno_prec
from siac.siac_t_periodo tp
INNER JOIN siac.siac_t_bil tb  ON tb.periodo_id = tp.periodo_id
where tp.ente_proprietario_id = p_ente_proprietario_id
and   tp.anno::integer = p_anno_bilancio::integer-1;
esito:= '  Fine Identificazione bilancio precedente - '||clock_timestamp();
RETURN NEXT;

-- SIAC-6007
esito:= '  Inizio Identificazione tipo capitolo gestione - '||clock_timestamp();
RETURN NEXT;
select elem_tipo_id
into v_elem_tipo_id
from siac_d_bil_elem_tipo
where elem_tipo_code = 'CAP-EG'
and   ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine Identificazione tipo capitolo gestione - '||clock_timestamp();
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
       --, tbe.elem_tipo_id COMMENTATO PER SIAC-6007
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

-- 17.02.2020 Sofia  Jira SIAC-7329
-- v_elem_desc := rec_elem_id.elem_desc;

v_elem_desc:=
translate( rec_elem_id.elem_desc,
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar);

-- 17.02.2020 Sofia  Jira SIAC-7329
-- v_elem_desc2 := rec_elem_id.elem_desc2;

v_elem_desc2 :=
translate( rec_elem_id.elem_desc2,
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar);



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
--SIAC-5895
--v_elem_tipo_id := rec_elem_id.elem_tipo_id; Commentato per SIAC-6007
v_ex_anno :=null;
v_ex_capitolo := null;
v_ex_articolo :=null;
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
v_FlagEntrataDubbiaEsigFCDE := null; -- SIAC-8531   Haitham 17/01/2022

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
  ELSIF rec_attr.attr_code = 'FlagEntrataDubbiaEsigFCDE' THEN   -- SIAC-8531   Haitham 17/01/2022
     v_FlagEntrataDubbiaEsigFCDE := v_flag_attributo;
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

-- SIAC-5895
esito:= '    Inizio step dati ex capitolo - '||clock_timestamp();
return next;

select per.anno,elem.elem_code,elem.elem_code2
into v_ex_anno, v_ex_capitolo, v_ex_articolo
from siac_r_bil_elem_rel_tempo r_ex
, siac_t_bil_elem elem
, siac_t_bil bil
, siac_t_periodo per
where r_ex.elem_id = v_elem_id
and   r_ex.data_cancellazione is null
and   p_data between r_ex.validita_inizio and coalesce(r_ex.validita_fine,p_data)
and   elem.elem_id = r_ex.elem_id_old
and   elem.bil_id = bil.bil_id
and   bil.periodo_id = per.periodo_id;

IF NOT FOUND then
--SIAC-6007 Indipendentemente dal tipo di capitolo, sia esso di previsione o gestione,
--il capitolo ricercato e di Gestione
  select
    v_anno_prec, elem.elem_code,elem.elem_code2
    into v_ex_anno, v_ex_capitolo, v_ex_articolo
  from siac_t_bil_elem elem
  where elem.elem_code =  v_elem_code
  and   elem.elem_code2 = v_elem_code2
  and   elem.elem_code3 = v_elem_code3
  and   elem.elem_tipo_id = v_elem_tipo_id
  and   elem.bil_id = v_bil_id_prec
  and   elem.data_cancellazione is null;  -- Haitham 10/02/2022 SIAC-8621
END IF;

esito:= '    Fine step dati ex capitolo - '||clock_timestamp();
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
--SIAC-5895
,ex_anno
,ex_capitolo
,ex_articolo
,flag_pertinente_FCDE           -- SIAC-8531   Haitham 17/01/2022
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
        --SIAC-5895
        ,v_ex_anno
        ,v_ex_capitolo
        ,v_ex_articolo
        ,v_FlagEntrataDubbiaEsigFCDE    -- SIAC-8531   Haitham 17/01/2022
       );
esito:= '  Fine ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
END LOOP;
esito:= 'Fine funzione carico capitoli di entrata (FNC_SIAC_DWH_CAPITOLO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico capitoli di entrata (FNC_SIAC_DWH_CAPITOLO_ENTRATA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
