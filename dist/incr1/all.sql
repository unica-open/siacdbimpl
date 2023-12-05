/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5034;SIAC-5035 INIZIO

alter table siac_dwh_impegno add flagFrazionabile varchar(1);
alter table siac_dwh_subimpegno add flagFrazionabile varchar(1);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_impegno (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
begin 

IF p_data IS NULL THEN
   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   ELSE
      p_data := now();
   END IF;   
END IF;

delete from siac_dwh_impegno where 
ente_proprietario_id=p_ente_proprietario_id 
AND   bil_anno = p_anno_bilancio;
delete from siac_dwh_subimpegno where 
ente_proprietario_id=p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;

INSERT INTO 
  siac.siac_dwh_impegno
(
  ente_proprietario_id,  ente_denominazione,  bil_anno,  cod_fase_operativa,  desc_fase_operativa,
  anno_impegno,  num_impegno,  desc_impegno,  cod_impegno,  cod_stato_impegno,  desc_stato_impegno,
  data_scadenza,  parere_finanziario,  cod_capitolo,  cod_articolo,  cod_ueb,  desc_capitolo,  desc_articolo,  
  soggetto_id, cod_soggetto, desc_soggetto,  cf_soggetto,  cf_estero_soggetto, p_iva_soggetto,  cod_classe_soggetto,  desc_classe_soggetto,  
  cod_tipo_impegno,  desc_tipo_impegno,   cod_spesa_ricorrente,  desc_spesa_ricorrente,  cod_perimetro_sanita_spesa,  desc_perimetro_sanita_spesa,
  cod_transazione_ue_spesa,  desc_transazione_ue_spesa,  cod_politiche_regionali_unit,  desc_politiche_regionali_unit,
  cod_pdc_finanziario_i,  desc_pdc_finanziario_i,  cod_pdc_finanziario_ii,  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,  desc_pdc_finanziario_iii,  cod_pdc_finanziario_iv,  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,  desc_pdc_finanziario_v,  cod_pdc_economico_i,  desc_pdc_economico_i,
  cod_pdc_economico_ii,  desc_pdc_economico_ii,  cod_pdc_economico_iii,  desc_pdc_economico_iii,
  cod_pdc_economico_iv,  desc_pdc_economico_iv,  cod_pdc_economico_v,  desc_pdc_economico_v,
  cod_cofog_divisione,  desc_cofog_divisione,  cod_cofog_gruppo,  desc_cofog_gruppo,
  classificatore_1,  classificatore_1_valore,  classificatore_1_desc_valore,
  classificatore_2,  classificatore_2_valore,  classificatore_2_desc_valore,
  classificatore_3,  classificatore_3_valore,  classificatore_3_desc_valore,
  classificatore_4,  classificatore_4_valore,  classificatore_4_desc_valore,
  classificatore_5,  classificatore_5_valore,  classificatore_5_desc_valore,
  annocapitoloorigine,  numcapitoloorigine,  annoorigineplur, numarticoloorigine,  annoriaccertato,  numriaccertato,  numorigineplur,  
  flagdariaccertamento,  
  anno_atto_amministrativo,  num_atto_amministrativo,  oggetto_atto_amministrativo,  note_atto_amministrativo,  
  cod_tipo_atto_amministrativo, desc_tipo_atto_amministrativo, desc_stato_atto_amministrativo,  
  importo_iniziale,  importo_attuale,  importo_utilizzabile,  
  note,  anno_finanziamento,  cig,  cup,  num_ueb_origine,  validato,
  num_accertamento_finanziamento,  importo_liquidato,  importo_quietanziato,  importo_emesso,
  --data_elaborazione,  
  flagcassaeconomale,  data_inizio_val_stato_imp,  data_inizio_val_imp,
  data_creazione_imp,  data_modifica_imp,                      
  cod_cdc_atto_amministrativo,  desc_cdc_atto_amministrativo,
  cod_cdr_atto_amministrativo,  desc_cdr_atto_amministrativo,
  cod_programma, desc_programma,
  flagPrenotazione, flagPrenotazioneLiquidabile, flagFrazionabile
  )
select 
xx.ente_proprietario_id, xx.ente_denominazione, xx.anno,xx.fase_operativa_code, xx.fase_operativa_desc ,
xx.movgest_anno, xx.movgest_numero, xx.movgest_desc, xx.movgest_ts_code, --xx.movgest_ts_desc, 
xx.movgest_stato_code, xx.movgest_stato_desc, xx.movgest_ts_scadenza_data,
case when xx.parere_finanziario=false then 'F' else 'S' end parere_finanziario
,-- xx.movgest_id, xx.movgest_ts_id, xx.movgest_ts_tipo_code,
xx.elem_code, xx.elem_code2, xx.elem_code3, xx.elem_desc, xx.elem_desc2, --xx.bil_id,
xx.soggetto_id, xx.soggetto_code, xx.soggetto_desc, xx.codice_fiscale,xx.codice_fiscale_estero, xx.partita_iva, xx.soggetto_classe_code, xx.soggetto_classe_desc,
xx.tipoimpegno_classif_code,xx.tipoimpegno_classif_desc,xx.ricorrentespesa_classif_code,xx.ricorrentespesa_classif_desc, 
xx.persaspesa_classif_code,xx.persaspesa_classif_desc, xx.truespesa_classif_code, xx.truespesa_classif_desc, xx.polregunitarie_classif_code,xx.polregunitarie_classif_desc,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_I else xx.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_I else xx.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_II else xx.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_II else xx.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_III else xx.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_III else xx.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_IV else xx.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_IV else xx.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_I else xx.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_I else xx.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_II else xx.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_II else xx.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_III else xx.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_III else xx.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_IV else xx.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_IV else xx.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
xx.codice_cofog_divisione, xx.descrizione_cofog_divisione,xx.codice_cofog_gruppo,xx.descrizione_cofog_gruppo,
xx.cla11_classif_tipo_desc,xx.cla11_classif_code,xx.cla11_classif_desc,
xx.cla12_classif_tipo_desc,xx.cla12_classif_code,xx.cla12_classif_desc,
xx.cla13_classif_tipo_desc,xx.cla13_classif_code,xx.cla13_classif_desc,
xx.cla14_classif_tipo_desc,xx.cla14_classif_code,xx.cla14_classif_desc, 
xx.cla15_classif_tipo_desc,xx.cla15_classif_code,xx.cla15_classif_desc, 
xx.annoCapitoloOrigine,xx.numeroCapitoloOrigine,xx.annoOriginePlur,xx.numeroArticoloOrigine,xx.annoRiaccertato,xx.numeroRiaccertato,
xx.numeroOriginePlur, xx.flagDaRiaccertamento,
xx.attoamm_anno, xx.attoamm_numero, xx.attoamm_oggetto, xx.attoamm_note,
xx.attoamm_tipo_code, xx.attoamm_tipo_desc, xx.attoamm_stato_desc, 
xx.importo_iniziale, xx.importo_attuale, xx.importo_utilizzabile,
xx.NOTE_MOVGEST,  xx.annoFinanziamento, xx.cig,xx.cup, xx.numeroUEBOrigine,  xx.validato,
--xx.attoamm_id,          
xx.numeroAccFinanziamento,  xx.importo_liquidato,  xx.importo_quietanziato, xx.importo_emesso,
xx.flagCassaEconomale, 
xx.data_inizio_val_stato_subimp, xx.data_inizio_val_imp,
xx.data_creazione_imp, xx.data_modifica_imp,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_code::varchar else xx.cdr_cdc_code::varchar end cdc_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_desc::varchar else xx.cdr_cdc_desc::varchar end cdc_desc,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_code::varchar else xx.cdr_cdr_code::varchar end cdr_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_desc::varchar else xx.cdr_cdr_desc::varchar end cdr_desc,
xx.programma_code, xx.programma_desc,
xx.flagPrenotazione, xx.flagPrenotazioneLiquidabile, xx.flagFrazionabile
/*xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,*/
 from (
with imp as (
SELECT 
e.ente_proprietario_id, e.ente_denominazione, d.anno,
       b.movgest_anno, b.movgest_numero, b.movgest_desc, a.movgest_ts_code, a.movgest_ts_desc, 
       i.movgest_stato_code, i.movgest_stato_desc,
       a.movgest_ts_scadenza_data, b.parere_finanziario, b.movgest_id, a.movgest_ts_id, 
       g.movgest_ts_tipo_code,    c.bil_id,
       h.validita_inizio as data_inizio_val_stato_subimp,
       a.data_creazione as data_creazione_subimp, 
       a.validita_inizio as  data_inizio_val_subimp,
       a.data_modifica as data_modifica_subimp,
       b.data_creazione as data_creazione_imp, 
       b.validita_inizio as data_inizio_val_imp, 
       b.data_modifica as data_modifica_imp,
       m.fase_operativa_code, m.fase_operativa_desc 
FROM   
siac_t_movgest_ts a
, siac_t_movgest b
, siac_t_bil c
,  siac_t_periodo d
, siac_t_ente_proprietario e
,  siac_d_movgest_tipo f
,  siac_d_movgest_ts_tipo g
,  siac_r_movgest_ts_stato h
,  siac_d_movgest_stato i,
siac_r_bil_fase_operativa l, siac_d_fase_operativa m
where a.movgest_id=  b.movgest_id and 
 b.bil_id = c.bil_id and 
 d.periodo_id = c.periodo_id and 
 e.ente_proprietario_id = b.ente_proprietario_id   and 
 b.movgest_tipo_id = f.movgest_tipo_id and 
 a.movgest_ts_tipo_id = g.movgest_ts_tipo_id      and 
 h.movgest_ts_id = a.movgest_ts_id   and 
 h.movgest_stato_id = i.movgest_stato_id 
and e.ente_proprietario_id = p_ente_proprietario_id
AND d.anno = p_anno_bilancio
AND f.movgest_tipo_code = 'I' 
--AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and l.bil_id=c.bil_id
and m.fase_operativa_id=l.fase_operativa_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND a.data_cancellazione IS NULL 
AND b.data_cancellazione IS NULL 
AND c.data_cancellazione IS NULL 
AND d.data_cancellazione IS NULL 
AND e.data_cancellazione IS NULL 
AND f.data_cancellazione IS NULL 
AND g.data_cancellazione IS NULL 
AND h.data_cancellazione IS NULL 
AND i.data_cancellazione IS NULL 
AND a.validita_fine IS NULL 
AND b.validita_fine IS NULL 
AND c.validita_fine IS NULL 
AND d.validita_fine IS NULL 
AND e.validita_fine IS NULL 
AND f.validita_fine IS NULL 
AND g.validita_fine IS NULL 
AND h.validita_fine IS NULL 
AND i.validita_fine IS NULL
)
, cap as (
select l.movgest_id 
,m.elem_code, m.elem_code2, m.elem_code3, m.elem_desc, m.elem_desc2
From siac_r_movgest_bil_elem l, siac_t_bil_elem m
where l.elem_id=m.elem_id
and l.ente_proprietario_id=p_ente_proprietario_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND l.data_cancellazione IS NULL 
AND m.data_cancellazione IS NULL
AND l.validita_fine IS NULL 
AND m.validita_fine IS NULL
),
sogg as (SELECT 
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale, 
b.codice_fiscale_estero, b.partita_iva, b.soggetto_id
/*INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto, 
v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto, v_soggetto_id*/
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
and a.ente_proprietario_id=p_ente_proprietario_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
sogcla as (SELECT 
a.movgest_ts_id,b.soggetto_classe_code, b.soggetto_classe_desc
--INTO v_codice_classe_soggetto, v_descrizione_classe_soggetto
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_classe_id = b.soggetto_classe_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
--classificatori non gerarchici
tipoimpegno as (
SELECT 
a.movgest_ts_id,b.classif_code tipoimpegno_classif_code,b.classif_desc tipoimpegno_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_IMPEGNO'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
ricorrentespesa as (
SELECT 
a.movgest_ts_id,b.classif_code ricorrentespesa_classif_code,b.classif_desc ricorrentespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
truespesa as (
SELECT 
a.movgest_ts_id,b.classif_code truespesa_classif_code,b.classif_desc truespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
persaspesa as (
SELECT 
a.movgest_ts_id,b.classif_code persaspesa_classif_code,b.classif_desc persaspesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
polregunitarie as (
SELECT 
a.movgest_ts_id,b.classif_code polregunitarie_classif_code,b.classif_desc polregunitarie_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
cla11 as (
SELECT 
a.movgest_ts_id,b.classif_code cla11_classif_code,b.classif_desc cla11_classif_desc, 
c.classif_tipo_desc cla11_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_11'
-- AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla12 as (
SELECT 
a.movgest_ts_id,b.classif_code cla12_classif_code,b.classif_desc cla12_classif_desc, 
c.classif_tipo_desc cla12_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_12'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla13 as (
SELECT 
a.movgest_ts_id,b.classif_code cla13_classif_code,b.classif_desc cla13_classif_desc, 
c.classif_tipo_desc cla13_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_13'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla14 as (
SELECT 
a.movgest_ts_id,b.classif_code cla14_classif_code,b.classif_desc cla14_classif_desc, 
c.classif_tipo_desc cla14_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_14'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla15 as (
SELECT 
a.movgest_ts_id,b.classif_code cla15_classif_code,b.classif_desc cla15_classif_desc, 
c.classif_tipo_desc cla15_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_15'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
--sezione attributi
, t_annoCapitoloOrigine as (
SELECT 
a.movgest_ts_id
, a.testo annoCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='annoCapitoloOrigine' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroCapitoloOrigine as (
SELECT 
a.movgest_ts_id
, a.testo numeroCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroCapitoloOrigine' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoOriginePlur as (
SELECT 
a.movgest_ts_id
, a.testo annoOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='annoOriginePlur' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroArticoloOrigine as (
SELECT 
a.movgest_ts_id
, a.testo numeroArticoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroArticoloOrigine' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoRiaccertato as (
SELECT 
a.movgest_ts_id
, a.testo annoRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='annoRiaccertato' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroRiaccertato as (
SELECT 
a.movgest_ts_id
, a.testo numeroRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroRiaccertato' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroOriginePlur as (
SELECT 
a.movgest_ts_id
, a.testo numeroOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroOriginePlur' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagDaRiaccertamento as (
SELECT 
a.movgest_ts_id
, a."boolean" flagDaRiaccertamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagDaRiaccertamento' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroUEBOrigine as (
SELECT 
a.movgest_ts_id
, a.testo numeroUEBOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroUEBOrigine' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cig as (
SELECT 
a.movgest_ts_id
, a.testo cig
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='cig' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cup as (
SELECT 
a.movgest_ts_id
, a.testo cup
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='cup' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_NOTE_MOVGEST as (
SELECT 
a.movgest_ts_id
, a.testo NOTE_MOVGEST
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='NOTE_MOVGEST' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_validato as (
SELECT 
a.movgest_ts_id
, a."boolean" validato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='validato' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoFinanziamento as (
SELECT 
a.movgest_ts_id
, a.testo annoFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='annoFinanziamento' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroAccFinanziamento as (
SELECT 
a.movgest_ts_id
, a.testo numeroAccFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroAccFinanziamento' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagCassaEconomale as (
SELECT 
a.movgest_ts_id
, a."boolean" flagCassaEconomale
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagCassaEconomale' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazione as (
SELECT 
a.movgest_ts_id
, a."boolean" flagPrenotazione
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagPrenotazione' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazioneLiquidabile as (
SELECT 
a.movgest_ts_id
, a."boolean" flagPrenotazioneLiquidabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagPrenotazioneLiquidabile' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
t_flagFrazionabile as (
SELECT 
a.movgest_ts_id
, a."boolean" flagFrazionabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagFrazionabile' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT 
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_movgest_ts_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id 
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
AND   d.validita_fine IS NULL
AND   e.validita_fine IS NULL
)
, 
atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.data_cancellazione is null 
and a.validita_fine is null 
--and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
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
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null
and c.validita_fine is null
and a2.validita_fine is null*/
)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null*/
)
select 
atmc.movgest_ts_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id),
impattuale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_attuale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='A'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
impiniziale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_iniziale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='I'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
imputilizzabile as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_utilizzabile, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='U'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
),
impliquidatoemessoquietanziato as (select tz.* from (
with liquid as (
 SELECT sum(COALESCE(b.liq_importo,0)) importo_liquidato, a.movgest_ts_id,
b.liq_id
    FROM siac.siac_r_liquidazione_movgest a, siac.siac_t_liquidazione b, 
    siac.siac_d_liquidazione_stato c, siac.siac_r_liquidazione_stato d 
    WHERE 
    a.ente_proprietario_id=p_ente_proprietario_id 
    AND   a.liq_id = b.liq_id 
    AND   b.liq_id = d.liq_id
    AND   d.liq_stato_id = c.liq_stato_id
    AND   c.liq_stato_code <> 'A'
    --AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
    --AND p_data BETWEEN d.validita_inizio AND COALESCE(d.validita_fine, p_data) 
    AND a.data_cancellazione IS NULL 
    AND b.data_cancellazione IS NULL
    AND c.data_cancellazione IS NULL 
    AND d.data_cancellazione IS NULL
    AND a.validita_fine IS NULL 
    AND b.validita_fine IS NULL
    AND c.validita_fine IS NULL 
    AND d.validita_fine IS NULL    
    group by a.movgest_ts_id, b.liq_id),
emes as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_emesso, a.liq_id
            FROM 
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id  
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code <> 'A'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data) 
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data) 
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL 
            AND  d.data_cancellazione IS NULL  
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL 
            AND  d.validita_fine IS NULL  
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL            
            group by a.liq_id),
quiet as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_quietanziato, a.liq_id
            FROM 
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id  
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code= 'Q'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data) 
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data) 
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL 
            AND  d.data_cancellazione IS NULL  
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL 
            AND  d.validita_fine IS NULL  
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL              
            group by a.liq_id)            
select liquid.movgest_ts_id,coalesce(sum(liquid.importo_liquidato),0) importo_liquidato, 
coalesce(sum(emes.importo_emesso),0) importo_emesso,
coalesce(sum(quiet.importo_quietanziato),0) importo_quietanziato
from liquid left join emes ON
liquid.liq_id=emes.liq_id       
left join quiet ON
liquid.liq_id=quiet.liq_id       
group by liquid.movgest_ts_id
) as tz),
cofog as (
select distinct r.movgest_ts_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from 
siac_r_movgest_class r,
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
--and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
)
, pdc5 as (
select distinct 
r.movgest_ts_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pdc4 as (
select distinct r.movgest_ts_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
, pce5 as (
select distinct r.movgest_ts_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pce4 as (
select distinct r.movgest_ts_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
, progetto as (
select rmtp.movgest_ts_id, tp.programma_code, tp.programma_desc
from   siac_r_movgest_ts_programma rmtp, siac_t_programma tp
where  rmtp.programma_id = tp.programma_id
--and    p_data BETWEEN rmtp.validita_inizio and COALESCE(rmtp.validita_fine,p_data)
--and    p_data BETWEEN tp.validita_inizio and COALESCE(tp.validita_fine,p_data)
and    rmtp.data_cancellazione IS NULL
and    tp.data_cancellazione IS NULL
and    rmtp.validita_fine IS NULL
and    tp.validita_fine IS NULL
)
select 
imp.ente_proprietario_id, imp.ente_denominazione, imp.anno,
imp.movgest_anno, imp.movgest_numero, imp.movgest_desc, imp.movgest_ts_code, imp.movgest_ts_desc, 
imp.movgest_stato_code, imp.movgest_stato_desc,
imp.movgest_ts_scadenza_data, imp.parere_finanziario, imp.movgest_id, imp.movgest_ts_id, 
imp.movgest_ts_tipo_code,
cap.elem_code, cap.elem_code2, cap.elem_code3, cap.elem_desc, cap.elem_desc2, 
imp.bil_id,
imp.data_inizio_val_stato_subimp,
imp.data_creazione_subimp, 
imp.data_inizio_val_subimp,
imp.data_modifica_subimp,
imp.data_creazione_imp, 
imp.data_inizio_val_imp, 
imp.data_modifica_imp,
imp.fase_operativa_code, imp.fase_operativa_desc ,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, 
sogg.codice_fiscale_estero, sogg.partita_iva, sogg.soggetto_id
,sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
tipoimpegno.tipoimpegno_classif_code,
tipoimpegno.tipoimpegno_classif_desc,
ricorrentespesa.ricorrentespesa_classif_code,
ricorrentespesa.ricorrentespesa_classif_desc,
truespesa.truespesa_classif_code,
truespesa.truespesa_classif_desc,
persaspesa.persaspesa_classif_code,
persaspesa.persaspesa_classif_desc,
polregunitarie.polregunitarie_classif_code,
polregunitarie.polregunitarie_classif_desc,
cla11.cla11_classif_code,
cla11.cla11_classif_desc, 
cla11.cla11_classif_tipo_desc,
cla12.cla12_classif_code,
cla12.cla12_classif_desc, 
cla12.cla12_classif_tipo_desc,
cla13.cla13_classif_code,
cla13.cla13_classif_desc, 
cla13.cla13_classif_tipo_desc,
cla14.cla14_classif_code,
cla14.cla14_classif_desc, 
cla14.cla14_classif_tipo_desc,
cla15.cla15_classif_code,
cla15.cla15_classif_desc, 
cla15.cla15_classif_tipo_desc,
t_annoCapitoloOrigine.annoCapitoloOrigine,
t_numeroCapitoloOrigine.numeroCapitoloOrigine,
t_annoOriginePlur.annoOriginePlur,
t_numeroArticoloOrigine.numeroArticoloOrigine,
t_annoRiaccertato.annoRiaccertato,
t_numeroRiaccertato.numeroRiaccertato,
t_numeroOriginePlur.numeroOriginePlur,
t_flagDaRiaccertamento.flagDaRiaccertamento,
t_numeroUEBOrigine.numeroUEBOrigine,
t_cig.cig,
t_cup.cup,
t_NOTE_MOVGEST.NOTE_MOVGEST,
t_validato.validato,
t_annoFinanziamento.annoFinanziamento,
t_numeroAccFinanziamento.numeroAccFinanziamento,
t_flagCassaEconomale.flagCassaEconomale,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
impattuale.importo_attuale,
impiniziale.importo_iniziale,
imputilizzabile.importo_utilizzabile,
impliquidatoemessoquietanziato.importo_liquidato,
impliquidatoemessoquietanziato.importo_emesso,
impliquidatoemessoquietanziato,importo_quietanziato,
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
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
progetto.programma_code, progetto.programma_desc,
t_flagPrenotazione.flagPrenotazione, t_flagPrenotazioneLiquidabile.flagPrenotazioneLiquidabile,
t_flagFrazionabile.flagFrazionabile
from 
imp left join cap
on 
imp.movgest_id=cap.movgest_id
left join sogg
on 
imp.movgest_ts_id=sogg.movgest_ts_id       
left join sogcla
on 
imp.movgest_ts_id=sogcla.movgest_ts_id    
left join tipoimpegno
on 
imp.movgest_ts_id=tipoimpegno.movgest_ts_id 
left join ricorrentespesa
on 
imp.movgest_ts_id=ricorrentespesa.movgest_ts_id  
left join truespesa
on 
imp.movgest_ts_id=truespesa.movgest_ts_id  
left join persaspesa
on 
imp.movgest_ts_id=persaspesa.movgest_ts_id  
left join polregunitarie
on 
imp.movgest_ts_id=polregunitarie.movgest_ts_id  
left join cla11
on 
imp.movgest_ts_id=cla11.movgest_ts_id  
left join cla12
on 
imp.movgest_ts_id=cla12.movgest_ts_id  
left join cla13
on 
imp.movgest_ts_id=cla13.movgest_ts_id  
left join cla14
on 
imp.movgest_ts_id=cla14.movgest_ts_id  
left join cla15
on 
imp.movgest_ts_id=cla15.movgest_ts_id  
left join t_annoCapitoloOrigine
on 
imp.movgest_ts_id=t_annoCapitoloOrigine.movgest_ts_id  
left join t_numeroCapitoloOrigine
on 
imp.movgest_ts_id=t_numeroCapitoloOrigine.movgest_ts_id  
left join t_annoOriginePlur
on 
imp.movgest_ts_id=t_annoOriginePlur.movgest_ts_id
left join t_numeroArticoloOrigine
on 
imp.movgest_ts_id=t_numeroArticoloOrigine.movgest_ts_id  
left join t_annoRiaccertato
on 
imp.movgest_ts_id=t_annoRiaccertato.movgest_ts_id  
left join t_numeroRiaccertato
on 
imp.movgest_ts_id=t_numeroRiaccertato.movgest_ts_id  
left join t_numeroOriginePlur
on 
imp.movgest_ts_id=t_numeroOriginePlur.movgest_ts_id  
left join t_flagDaRiaccertamento
on 
imp.movgest_ts_id=t_flagDaRiaccertamento.movgest_ts_id  
left join t_numeroUEBOrigine
on 
imp.movgest_ts_id=t_numeroUEBOrigine.movgest_ts_id 
left join t_cig
on 
imp.movgest_ts_id=t_cig.movgest_ts_id  
left join t_cup
on 
imp.movgest_ts_id=t_cup.movgest_ts_id  
left join t_NOTE_MOVGEST
on 
imp.movgest_ts_id=t_NOTE_MOVGEST.movgest_ts_id  
left join t_validato
on 
imp.movgest_ts_id=t_validato.movgest_ts_id  
left join t_annoFinanziamento
on 
imp.movgest_ts_id=t_annoFinanziamento.movgest_ts_id  
left join t_numeroAccFinanziamento
on 
imp.movgest_ts_id=t_numeroAccFinanziamento.movgest_ts_id  
left join t_flagCassaEconomale
on 
imp.movgest_ts_id=t_flagCassaEconomale.movgest_ts_id  
left join attoamm
on 
imp.movgest_ts_id=attoamm.movgest_ts_id  
left join impattuale
on 
imp.movgest_ts_id=impattuale.movgest_ts_id  
left join impiniziale
on 
imp.movgest_ts_id=impiniziale.movgest_ts_id  
left join imputilizzabile
on 
imp.movgest_ts_id=imputilizzabile.movgest_ts_id  
left join impliquidatoemessoquietanziato
on 
imp.movgest_ts_id=impliquidatoemessoquietanziato.movgest_ts_id  
left join cofog
on 
imp.movgest_ts_id=cofog.movgest_ts_id  
left join pdc5
on 
imp.movgest_ts_id=pdc5.movgest_ts_id  
left join pdc4
on 
imp.movgest_ts_id=pdc4.movgest_ts_id  
left join pce5
on 
imp.movgest_ts_id=pce5.movgest_ts_id  
left join pce4
on 
imp.movgest_ts_id=pce4.movgest_ts_id
left join progetto
on 
imp.movgest_ts_id=progetto.movgest_ts_id
left join t_flagPrenotazione
on 
imp.movgest_ts_id=t_flagPrenotazione.movgest_ts_id 
left join t_flagPrenotazioneLiquidabile
on 
imp.movgest_ts_id=t_flagPrenotazioneLiquidabile.movgest_ts_id 
left join t_flagFrazionabile
on 
imp.movgest_ts_id=t_flagFrazionabile.movgest_ts_id
) xx 
where xx.movgest_ts_tipo_code='T';



--------subimp

INSERT INTO 
  siac.siac_dwh_subimpegno
(
  ente_proprietario_id,  ente_denominazione,  bil_anno,  cod_fase_operativa,  desc_fase_operativa,
  anno_impegno,  num_impegno,  desc_impegno,  cod_subimpegno,  cod_stato_subimpegno,  desc_stato_subimpegno,
  data_scadenza,  parere_finanziario,  cod_capitolo,  cod_articolo,  cod_ueb,  desc_capitolo,  desc_articolo,  
  soggetto_id, cod_soggetto, desc_soggetto,  cf_soggetto,  cf_estero_soggetto, p_iva_soggetto,  cod_classe_soggetto,  desc_classe_soggetto,  
  cod_tipo_impegno,  desc_tipo_impegno,   cod_spesa_ricorrente,  desc_spesa_ricorrente,  cod_perimetro_sanita_spesa,  desc_perimetro_sanita_spesa,
  cod_transazione_ue_spesa,  desc_transazione_ue_spesa,  cod_politiche_regionali_unit,  desc_politiche_regionali_unit,
  cod_pdc_finanziario_i,  desc_pdc_finanziario_i,  cod_pdc_finanziario_ii,  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,  desc_pdc_finanziario_iii,  cod_pdc_finanziario_iv,  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,  desc_pdc_finanziario_v,  cod_pdc_economico_i,  desc_pdc_economico_i,
  cod_pdc_economico_ii,  desc_pdc_economico_ii,  cod_pdc_economico_iii,  desc_pdc_economico_iii,
  cod_pdc_economico_iv,  desc_pdc_economico_iv,  cod_pdc_economico_v,  desc_pdc_economico_v,
  cod_cofog_divisione,  desc_cofog_divisione,  cod_cofog_gruppo,  desc_cofog_gruppo,
  classificatore_1,  classificatore_1_valore,  classificatore_1_desc_valore,
  classificatore_2,  classificatore_2_valore,  classificatore_2_desc_valore,
  classificatore_3,  classificatore_3_valore,  classificatore_3_desc_valore,
  classificatore_4,  classificatore_4_valore,  classificatore_4_desc_valore,
  classificatore_5,  classificatore_5_valore,  classificatore_5_desc_valore,
  annocapitoloorigine,  numcapitoloorigine,  annoorigineplur, numarticoloorigine,  annoriaccertato,  numriaccertato,  numorigineplur,  
  flagdariaccertamento,  
  anno_atto_amministrativo,  num_atto_amministrativo,  oggetto_atto_amministrativo,  note_atto_amministrativo,  
  cod_tipo_atto_amministrativo, desc_tipo_atto_amministrativo, desc_stato_atto_amministrativo,  
   importo_iniziale,  importo_attuale,  importo_utilizzabile,  
  note,  anno_finanziamento,  cig,  cup,  num_ueb_origine,  validato,
  num_accertamento_finanziamento,  importo_liquidato,  importo_quietanziato,  importo_emesso,
  --data_elaborazione,  
  flagcassaeconomale,  data_inizio_val_stato_subimp,  data_inizio_val_subimp,
  data_creazione_subimp,  data_modifica_subimp,
  cod_cdc_atto_amministrativo,  desc_cdc_atto_amministrativo,
  cod_cdr_atto_amministrativo,  desc_cdr_atto_amministrativo, 
  flagPrenotazione, flagPrenotazioneLiquidabile, flagFrazionabile
  )
select 
xx.ente_proprietario_id, xx.ente_denominazione, xx.anno,xx.fase_operativa_code, xx.fase_operativa_desc ,
xx.movgest_anno, xx.movgest_numero, xx.movgest_desc, xx.movgest_ts_code, --xx.movgest_ts_desc, 
xx.movgest_stato_code, xx.movgest_stato_desc, xx.movgest_ts_scadenza_data, 
case when xx.parere_finanziario=false then 'F' else 'S' end parere_finanziario,-- xx.movgest_id, xx.movgest_ts_id, xx.movgest_ts_tipo_code,
xx.elem_code, xx.elem_code2, xx.elem_code3, xx.elem_desc, xx.elem_desc2, --xx.bil_id,
xx.soggetto_id, xx.soggetto_code, xx.soggetto_desc, xx.codice_fiscale,xx.codice_fiscale_estero, xx.partita_iva, xx.soggetto_classe_code, xx.soggetto_classe_desc,
xx.tipoimpegno_classif_code,xx.tipoimpegno_classif_desc,xx.ricorrentespesa_classif_code,xx.ricorrentespesa_classif_desc, 
xx.persaspesa_classif_code,xx.persaspesa_classif_desc, xx.truespesa_classif_code, xx.truespesa_classif_desc, xx.polregunitarie_classif_code,xx.polregunitarie_classif_desc,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_I else xx.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_I else xx.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_II else xx.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_II else xx.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_III else xx.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_III else xx.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_IV else xx.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_IV else xx.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_I else xx.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_I else xx.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_II else xx.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_II else xx.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_III else xx.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_III else xx.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_IV else xx.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_IV else xx.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
xx.codice_cofog_divisione, xx.descrizione_cofog_divisione,xx.codice_cofog_gruppo,xx.descrizione_cofog_gruppo,
xx.cla11_classif_tipo_code,xx.cla11_classif_code,xx.cla11_classif_desc,xx.cla12_classif_tipo_code,xx.cla12_classif_code,xx.cla12_classif_desc,
xx.cla13_classif_tipo_code,xx.cla13_classif_code,xx.cla13_classif_desc,xx.cla14_classif_tipo_code,xx.cla14_classif_code,xx.cla14_classif_desc, 
xx.cla15_classif_tipo_code,xx.cla15_classif_code,xx.cla15_classif_desc, 
xx.annoCapitoloOrigine,xx.numeroCapitoloOrigine,xx.annoOriginePlur,xx.numeroArticoloOrigine,xx.annoRiaccertato,xx.numeroRiaccertato,
xx.numeroOriginePlur, xx.flagDaRiaccertamento,
xx.attoamm_anno, xx.attoamm_numero, xx.attoamm_oggetto, xx.attoamm_note,
xx.attoamm_tipo_code, xx.attoamm_tipo_desc, xx.attoamm_stato_desc, 
xx.importo_iniziale, xx.importo_attuale, xx.importo_utilizzabile,
xx.NOTE_MOVGEST,  xx.annoFinanziamento, xx.cig,xx.cup, xx.numeroUEBOrigine,  xx.validato,
--xx.attoamm_id,          
xx.numeroAccFinanziamento,  xx.importo_liquidato,  xx.importo_quietanziato, xx.importo_emesso,
xx.flagCassaEconomale, 
xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_code::varchar else xx.cdr_cdc_code::varchar end cdc_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_desc::varchar else xx.cdr_cdc_desc::varchar end cdc_desc,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_code::varchar else xx.cdr_cdr_code::varchar end cdr_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_desc::varchar else xx.cdr_cdr_desc::varchar end cdr_desc,
xx.flagPrenotazione, xx.flagPrenotazioneLiquidabile, xx.flagFrazionabile
/*xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,*/
 from (
with imp as (
SELECT 
e.ente_proprietario_id, e.ente_denominazione, d.anno,
       b.movgest_anno, b.movgest_numero, b.movgest_desc, a.movgest_ts_code, a.movgest_ts_desc, 
       i.movgest_stato_code, i.movgest_stato_desc,
       a.movgest_ts_scadenza_data, b.parere_finanziario, b.movgest_id, a.movgest_ts_id, 
       g.movgest_ts_tipo_code,    c.bil_id,
       h.validita_inizio as data_inizio_val_stato_subimp,
       a.data_creazione as data_creazione_subimp, 
       a.validita_inizio as  data_inizio_val_subimp,
       a.data_modifica as data_modifica_subimp,
       b.data_creazione as data_creazione_imp, 
       b.validita_inizio as data_inizio_val_imp, 
       b.data_modifica as data_modifica_imp,
       m.fase_operativa_code, m.fase_operativa_desc 
FROM   
siac_t_movgest_ts a
, siac_t_movgest b
, siac_t_bil c
,  siac_t_periodo d
, siac_t_ente_proprietario e
,  siac_d_movgest_tipo f
,  siac_d_movgest_ts_tipo g
,  siac_r_movgest_ts_stato h
,  siac_d_movgest_stato i,
siac_r_bil_fase_operativa l, siac_d_fase_operativa m
where a.movgest_id=  b.movgest_id and 
 b.bil_id = c.bil_id and 
 d.periodo_id = c.periodo_id and 
 e.ente_proprietario_id = b.ente_proprietario_id   and 
 b.movgest_tipo_id = f.movgest_tipo_id and 
 a.movgest_ts_tipo_id = g.movgest_ts_tipo_id      and 
 h.movgest_ts_id = a.movgest_ts_id   and 
 h.movgest_stato_id = i.movgest_stato_id 
and e.ente_proprietario_id = p_ente_proprietario_id
AND d.anno = p_anno_bilancio
AND f.movgest_tipo_code = 'I' 
--AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and l.bil_id=c.bil_id
and m.fase_operativa_id=l.fase_operativa_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND a.data_cancellazione IS NULL 
AND b.data_cancellazione IS NULL 
AND c.data_cancellazione IS NULL 
AND d.data_cancellazione IS NULL 
AND e.data_cancellazione IS NULL 
AND f.data_cancellazione IS NULL 
AND g.data_cancellazione IS NULL 
AND h.data_cancellazione IS NULL 
AND i.data_cancellazione IS NULL
AND a.validita_fine IS NULL 
AND b.validita_fine IS NULL 
AND c.validita_fine IS NULL 
AND d.validita_fine IS NULL 
AND e.validita_fine IS NULL 
AND f.validita_fine IS NULL 
AND g.validita_fine IS NULL 
AND h.validita_fine IS NULL 
AND i.validita_fine IS NULL
)
, cap as (
select l.movgest_id 
,m.elem_code, m.elem_code2, m.elem_code3, m.elem_desc, m.elem_desc2
From siac_r_movgest_bil_elem l, siac_t_bil_elem m
where l.elem_id=m.elem_id
and l.ente_proprietario_id=p_ente_proprietario_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND l.data_cancellazione IS NULL 
AND m.data_cancellazione IS NULL
AND l.validita_fine IS NULL 
AND m.validita_fine IS NULL
),
sogg as (SELECT 
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale, 
b.codice_fiscale_estero, b.partita_iva, b.soggetto_id
/*INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto, 
v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto, v_soggetto_id*/
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
and a.ente_proprietario_id=p_ente_proprietario_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
sogcla as (SELECT 
a.movgest_ts_id,b.soggetto_classe_code, b.soggetto_classe_desc
--INTO v_codice_classe_soggetto, v_descrizione_classe_soggetto
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_classe_id = b.soggetto_classe_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
)
,
--classificatori non gerarchici
tipoimpegno as (
SELECT 
a.movgest_ts_id,b.classif_code tipoimpegno_classif_code,b.classif_desc tipoimpegno_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_IMPEGNO'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
ricorrentespesa as (
SELECT 
a.movgest_ts_id,b.classif_code ricorrentespesa_classif_code,b.classif_desc ricorrentespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
truespesa as (
SELECT 
a.movgest_ts_id,b.classif_code truespesa_classif_code,b.classif_desc truespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
persaspesa as (
SELECT 
a.movgest_ts_id,b.classif_code persaspesa_classif_code,b.classif_desc persaspesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
polregunitarie as (
SELECT 
a.movgest_ts_id,b.classif_code polregunitarie_classif_code,b.classif_desc polregunitarie_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
cla11 as (
SELECT 
a.movgest_ts_id,b.classif_code cla11_classif_code,b.classif_desc cla11_classif_desc, c.classif_tipo_code cla11_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_11'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla12 as (
SELECT 
a.movgest_ts_id,b.classif_code cla12_classif_code,b.classif_desc cla12_classif_desc, c.classif_tipo_code cla12_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_12'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla13 as (
SELECT 
a.movgest_ts_id,b.classif_code cla13_classif_code,b.classif_desc cla13_classif_desc, c.classif_tipo_code cla13_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_13'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla14 as (
SELECT 
a.movgest_ts_id,b.classif_code cla14_classif_code,b.classif_desc cla14_classif_desc, c.classif_tipo_code cla14_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_14'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla15 as (
SELECT 
a.movgest_ts_id,b.classif_code cla15_classif_code,b.classif_desc cla15_classif_desc, c.classif_tipo_code cla15_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_15'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
--sezione attributi
, t_annoCapitoloOrigine as (
SELECT 
a.movgest_ts_id
, a.testo annoCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='annoCapitoloOrigine' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroCapitoloOrigine as (
SELECT 
a.movgest_ts_id
, a.testo numeroCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroCapitoloOrigine' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoOriginePlur as (
SELECT 
a.movgest_ts_id
, a.testo annoOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='annoOriginePlur' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroArticoloOrigine as (
SELECT 
a.movgest_ts_id
, a.testo numeroArticoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroArticoloOrigine' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoRiaccertato as (
SELECT 
a.movgest_ts_id
, a.testo annoRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='annoRiaccertato' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroRiaccertato as (
SELECT 
a.movgest_ts_id
, a.testo numeroRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroRiaccertato' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroOriginePlur as (
SELECT 
a.movgest_ts_id
, a.testo numeroOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroOriginePlur' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagDaRiaccertamento as (
SELECT 
a.movgest_ts_id
, a."boolean" flagDaRiaccertamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagDaRiaccertamento' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroUEBOrigine as (
SELECT 
a.movgest_ts_id
, a.testo numeroUEBOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroUEBOrigine' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cig as (
SELECT 
a.movgest_ts_id
, a.testo cig
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='cig' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cup as (
SELECT 
a.movgest_ts_id
, a.testo cup
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='cup' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_NOTE_MOVGEST as (
SELECT 
a.movgest_ts_id
, a.testo NOTE_MOVGEST
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='NOTE_MOVGEST' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_validato as (
SELECT 
a.movgest_ts_id
, a."boolean" validato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='validato' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoFinanziamento as (
SELECT 
a.movgest_ts_id
, a.testo annoFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='annoFinanziamento' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroAccFinanziamento as (
SELECT 
a.movgest_ts_id
, a.testo numeroAccFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='numeroAccFinanziamento' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagCassaEconomale as (
SELECT 
a.movgest_ts_id
, a."boolean" flagCassaEconomale
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagCassaEconomale' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazione as (
SELECT 
a.movgest_ts_id
, a."boolean" flagPrenotazione
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagPrenotazione' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazioneLiquidabile as (
SELECT 
a.movgest_ts_id
, a."boolean" flagPrenotazioneLiquidabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagPrenotazioneLiquidabile' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
t_flagFrazionabile as (
SELECT 
a.movgest_ts_id
, a."boolean" flagFrazionabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagFrazionabile' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT 
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_movgest_ts_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id 
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
AND   d.validita_fine IS NULL
AND   e.validita_fine IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.data_cancellazione is null 
AND   a.validita_fine IS NULL
--and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
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
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null
and a2.classif_id=c.classif_id_padre
/*and a.validita_fine is null
and b.validita_fine is null
and c.validita_fine is null
and a2.validita_fine is null*/
)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null*/
)
select 
atmc.movgest_ts_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id),
impattuale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_attuale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='A'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
impiniziale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_iniziale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='I'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
imputilizzabile as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_utilizzabile, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='U'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
),
impliquidatoemessoquietanziato as (select tz.* from (
with liquid as (
 SELECT sum(COALESCE(b.liq_importo,0)) importo_liquidato, a.movgest_ts_id,
b.liq_id
    FROM siac.siac_r_liquidazione_movgest a, siac.siac_t_liquidazione b, 
    siac.siac_d_liquidazione_stato c, siac.siac_r_liquidazione_stato d 
    WHERE 
    a.ente_proprietario_id=p_ente_proprietario_id 
    AND   a.liq_id = b.liq_id 
    AND   b.liq_id = d.liq_id
    AND   d.liq_stato_id = c.liq_stato_id
    AND   c.liq_stato_code <> 'A'
    --AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
    --AND p_data BETWEEN d.validita_inizio AND COALESCE(d.validita_fine, p_data) 
    AND a.data_cancellazione IS NULL 
    AND b.data_cancellazione IS NULL
    AND c.data_cancellazione IS NULL 
    AND d.data_cancellazione IS NULL
    AND a.validita_fine IS NULL 
    AND b.validita_fine IS NULL
    AND c.validita_fine IS NULL 
    AND d.validita_fine IS NULL    
    group by a.movgest_ts_id, b.liq_id),
emes as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_emesso, a.liq_id
            FROM 
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id  
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code <> 'A'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data) 
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data) 
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL 
            AND  d.data_cancellazione IS NULL  
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL 
            AND  d.validita_fine IS NULL  
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL            
            group by a.liq_id),
quiet as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_quietanziato, a.liq_id
            FROM 
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id  
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code= 'Q'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data) 
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data) 
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL 
            AND  d.data_cancellazione IS NULL  
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL 
            AND  d.validita_fine IS NULL  
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL             
            group by a.liq_id)            
select liquid.movgest_ts_id,coalesce(sum(liquid.importo_liquidato),0) importo_liquidato, 
coalesce(sum(emes.importo_emesso),0) importo_emesso,
coalesce(sum(quiet.importo_quietanziato),0) importo_quietanziato
from liquid left join emes ON
liquid.liq_id=emes.liq_id       
left join quiet ON
liquid.liq_id=quiet.liq_id       
group by liquid.movgest_ts_id
) as tz),
cofog as (
select distinct r.movgest_ts_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from 
siac_r_movgest_class r,
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
--and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
)
, pdc5 as (
select distinct 
r.movgest_ts_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pdc4 as (
select distinct r.movgest_ts_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
, pce5 as (
select distinct r.movgest_ts_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pce4 as (
select distinct r.movgest_ts_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
select 
imp.ente_proprietario_id, imp.ente_denominazione, imp.anno,
imp.movgest_anno, imp.movgest_numero, imp.movgest_desc, imp.movgest_ts_code, imp.movgest_ts_desc, 
imp.movgest_stato_code, imp.movgest_stato_desc,
imp.movgest_ts_scadenza_data, imp.parere_finanziario, imp.movgest_id, imp.movgest_ts_id, 
imp.movgest_ts_tipo_code,
cap.elem_code, cap.elem_code2, cap.elem_code3, cap.elem_desc, cap.elem_desc2, 
imp.bil_id,
imp.data_inizio_val_stato_subimp,
imp.data_creazione_subimp, 
imp.data_inizio_val_subimp,
imp.data_modifica_subimp,
imp.data_creazione_imp, 
imp.data_inizio_val_imp, 
imp.data_modifica_imp,
imp.fase_operativa_code, imp.fase_operativa_desc ,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, 
sogg.codice_fiscale_estero, sogg.partita_iva, sogg.soggetto_id
,sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
tipoimpegno.tipoimpegno_classif_code,
tipoimpegno.tipoimpegno_classif_desc,
ricorrentespesa.ricorrentespesa_classif_code,
ricorrentespesa.ricorrentespesa_classif_desc,
truespesa.truespesa_classif_code,
truespesa.truespesa_classif_desc,
persaspesa.persaspesa_classif_code,
persaspesa.persaspesa_classif_desc,
polregunitarie.polregunitarie_classif_code,
polregunitarie.polregunitarie_classif_desc,
cla11.cla11_classif_code,
cla11.cla11_classif_desc, 
cla11.cla11_classif_tipo_code,
cla12.cla12_classif_code,
cla12.cla12_classif_desc, 
cla12.cla12_classif_tipo_code,
cla13.cla13_classif_code,
cla13.cla13_classif_desc, 
cla13.cla13_classif_tipo_code,
cla14.cla14_classif_code,
cla14.cla14_classif_desc, 
cla14.cla14_classif_tipo_code,
cla15.cla15_classif_code,
cla15.cla15_classif_desc, 
cla15.cla15_classif_tipo_code,
t_annoCapitoloOrigine.annoCapitoloOrigine,
t_numeroCapitoloOrigine.numeroCapitoloOrigine,
t_annoOriginePlur.annoOriginePlur,
t_numeroArticoloOrigine.numeroArticoloOrigine,
t_annoRiaccertato.annoRiaccertato,
t_numeroRiaccertato.numeroRiaccertato,
t_numeroOriginePlur.numeroOriginePlur,
t_flagDaRiaccertamento.flagDaRiaccertamento,
t_numeroUEBOrigine.numeroUEBOrigine,
t_cig.cig,
t_cup.cup,
t_NOTE_MOVGEST.NOTE_MOVGEST,
t_validato.validato,
t_annoFinanziamento.annoFinanziamento,
t_numeroAccFinanziamento.numeroAccFinanziamento,
t_flagCassaEconomale.flagCassaEconomale,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
impattuale.importo_attuale,
impiniziale.importo_iniziale,
imputilizzabile.importo_utilizzabile,
impliquidatoemessoquietanziato.importo_liquidato,
impliquidatoemessoquietanziato.importo_emesso,
impliquidatoemessoquietanziato,importo_quietanziato,
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
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagPrenotazione.flagPrenotazione, t_flagPrenotazioneLiquidabile.flagPrenotazioneLiquidabile,
t_flagFrazionabile.flagFrazionabile
from 
imp left join cap
on 
imp.movgest_id=cap.movgest_id
left join sogg
on 
imp.movgest_ts_id=sogg.movgest_ts_id       
left join sogcla
on 
imp.movgest_ts_id=sogcla.movgest_ts_id    
left join tipoimpegno
on 
imp.movgest_ts_id=tipoimpegno.movgest_ts_id 
left join ricorrentespesa
on 
imp.movgest_ts_id=ricorrentespesa.movgest_ts_id  
left join truespesa
on 
imp.movgest_ts_id=truespesa.movgest_ts_id  
left join persaspesa
on 
imp.movgest_ts_id=persaspesa.movgest_ts_id  
left join polregunitarie
on 
imp.movgest_ts_id=polregunitarie.movgest_ts_id  
left join cla11
on 
imp.movgest_ts_id=cla11.movgest_ts_id  
left join cla12
on 
imp.movgest_ts_id=cla12.movgest_ts_id  
left join cla13
on 
imp.movgest_ts_id=cla13.movgest_ts_id  
left join cla14
on 
imp.movgest_ts_id=cla14.movgest_ts_id  
left join cla15
on 
imp.movgest_ts_id=cla15.movgest_ts_id  
left join t_annoCapitoloOrigine
on 
imp.movgest_ts_id=t_annoCapitoloOrigine.movgest_ts_id  
left join t_numeroCapitoloOrigine
on 
imp.movgest_ts_id=t_numeroCapitoloOrigine.movgest_ts_id  
left join t_annoOriginePlur
on 
imp.movgest_ts_id=t_annoOriginePlur.movgest_ts_id
left join t_numeroArticoloOrigine
on 
imp.movgest_ts_id=t_numeroArticoloOrigine.movgest_ts_id  
left join t_annoRiaccertato
on 
imp.movgest_ts_id=t_annoRiaccertato.movgest_ts_id  
left join t_numeroRiaccertato
on 
imp.movgest_ts_id=t_numeroRiaccertato.movgest_ts_id  
left join t_numeroOriginePlur
on 
imp.movgest_ts_id=t_numeroOriginePlur.movgest_ts_id  
left join t_flagDaRiaccertamento
on 
imp.movgest_ts_id=t_flagDaRiaccertamento.movgest_ts_id  
left join t_numeroUEBOrigine
on 
imp.movgest_ts_id=t_numeroUEBOrigine.movgest_ts_id 
left join t_cig
on 
imp.movgest_ts_id=t_cig.movgest_ts_id  
left join t_cup
on 
imp.movgest_ts_id=t_cup.movgest_ts_id  
left join t_NOTE_MOVGEST
on 
imp.movgest_ts_id=t_NOTE_MOVGEST.movgest_ts_id  
left join t_validato
on 
imp.movgest_ts_id=t_validato.movgest_ts_id  
left join t_annoFinanziamento
on 
imp.movgest_ts_id=t_annoFinanziamento.movgest_ts_id  
left join t_numeroAccFinanziamento
on 
imp.movgest_ts_id=t_numeroAccFinanziamento.movgest_ts_id  
left join t_flagCassaEconomale
on 
imp.movgest_ts_id=t_flagCassaEconomale.movgest_ts_id  
left join attoamm
on 
imp.movgest_ts_id=attoamm.movgest_ts_id  
left join impattuale
on 
imp.movgest_ts_id=impattuale.movgest_ts_id  
left join impiniziale
on 
imp.movgest_ts_id=impiniziale.movgest_ts_id  
left join imputilizzabile
on 
imp.movgest_ts_id=imputilizzabile.movgest_ts_id  
left join impliquidatoemessoquietanziato
on 
imp.movgest_ts_id=impliquidatoemessoquietanziato.movgest_ts_id  
left join cofog
on 
imp.movgest_ts_id=cofog.movgest_ts_id  
left join pdc5
on 
imp.movgest_ts_id=pdc5.movgest_ts_id  
left join pdc4
on 
imp.movgest_ts_id=pdc4.movgest_ts_id  
left join pce5
on 
imp.movgest_ts_id=pce5.movgest_ts_id  
left join pce4
on 
imp.movgest_ts_id=pce4.movgest_ts_id  
left join t_flagPrenotazione
on 
imp.movgest_ts_id=t_flagPrenotazione.movgest_ts_id  
left join t_flagPrenotazioneLiquidabile
on 
imp.movgest_ts_id=t_flagPrenotazioneLiquidabile.movgest_ts_id
left join t_flagFrazionabile
on 
imp.movgest_ts_id=t_flagFrazionabile.movgest_ts_id
) xx 
where xx.movgest_ts_tipo_code='S';


esito:='ok';

EXCEPTION
WHEN others THEN
  esito:='Funzione carico impegni (FNC_SIAC_DWH_IMPEGNO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000; 

-- SIAC-5034;SIAC-5035 FINE

-- SIAC-5029 INIZIO

DROP FUNCTION siac."BILR152_elenco_reversali"(p_ente_prop_id integer, p_anno varchar, p_numero_provv integer, p_anno_provv varchar, p_tipo_provv varchar);

CREATE OR REPLACE FUNCTION siac."BILR152_elenco_reversali" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar
)
RETURNS TABLE (
  num_reversale varchar,
  anno_reversale integer,
  stato_reversale varchar,
  desc_stato_reversale varchar,
  importo_reversale numeric,
  conto_dare varchar,
  conto_avere varchar,
  num_accertamento numeric,
  anno_accertamento integer,
  num_subaccertamento varchar,
  tipo_accert varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  categoria varchar,
  ord_ts_id integer
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;
 

BEGIN


num_reversale:='';
anno_reversale:=0;
stato_reversale:='';
desc_stato_reversale:='';
importo_reversale:=0;
conto_dare:='';
conto_avere:='';
num_accertamento:=0;
anno_accertamento:=0;
num_subaccertamento:='';
tipo_accert:='';
code_soggetto:='';
desc_soggetto:=0;
categoria:=0;
ord_ts_id:=0;

anno_eser_int=p_anno ::INTEGER;


RTN_MESSAGGIO:='Estrazione dei dati delle reversali ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
with reversali as (    
      select t_ordinativo.ord_id,
      		t_ord_ts.ord_ts_id,
          t_ordinativo.ord_anno,
          t_ordinativo.ord_numero,
          d_ord_stato.ord_stato_code,
          d_ord_stato.ord_stato_desc,
          t_ord_ts_det.ord_ts_det_importo     
       from  
                siac_t_ordinativo t_ordinativo,
                siac_d_ordinativo_tipo d_ordinativo_tipo,              
                siac_t_ordinativo_ts t_ord_ts,
                siac_r_ordinativo_stato r_ord_stato,
                siac_d_ordinativo_stato d_ord_stato,
                siac_r_ordinativo_atto_amm r_ord_atto_amm,
                siac_t_ordinativo_ts_det t_ord_ts_det, 
               siac_d_ordinativo_ts_det_tipo ts_det_tipo,
               siac_t_atto_amm t_atto_amm  ,
               siac_d_atto_amm_tipo	tipo_atto  
      where t_ordinativo.ord_tipo_id=   d_ordinativo_tipo.ord_tipo_id
          and t_ordinativo.ord_id= t_ord_ts.ord_id
          AND r_ord_atto_amm.ord_id=t_ordinativo.ord_id
          AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
          AND r_ord_stato.ord_id=t_ordinativo.ord_id
          and t_ord_ts_det.ord_ts_id= t_ord_ts.ord_ts_id  
          and ts_det_tipo.ord_ts_det_tipo_id=  t_ord_ts_det.ord_ts_det_tipo_id
          AND t_atto_amm.attoamm_id=r_ord_atto_amm.attoamm_id
          AND t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
          AND t_ordinativo.ente_proprietario_id=p_ente_prop_id
          AND t_atto_amm.attoamm_numero=p_numero_provv
          AND t_atto_amm.attoamm_anno=p_anno_provv
          AND tipo_atto.attoamm_tipo_code=p_tipo_provv
           AND d_ordinativo_tipo.ord_tipo_code ='I' --Incasso
           AND ts_det_tipo.ord_ts_det_tipo_code='A' --importo Attuale
           AND d_ord_stato.ord_stato_code <>'A' --Annullato
           AND r_ord_stato.validita_fine IS NULL  --Stato ancora valido
           AND t_ordinativo.data_cancellazione IS NULL
           AND d_ordinativo_tipo.data_cancellazione IS NULL 
           AND t_ord_ts.data_cancellazione IS NULL
           AND r_ord_stato.data_cancellazione IS NULL
           AND d_ord_stato.data_cancellazione IS NULL
           AND t_ord_ts_det.data_cancellazione IS NULL
           AND ts_det_tipo.data_cancellazione IS NULL
           AND r_ord_atto_amm.data_cancellazione IS NULL
           AND t_atto_amm.data_cancellazione IS NULL
           AND tipo_atto.data_cancellazione IS NULL)  ,
 accert as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		r_ord_ts_movgest_ts.ord_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,            
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato,
                siac_r_ordinativo_ts_movgest_ts r_ord_ts_movgest_ts 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND r_ord_ts_movgest_ts.movgest_ts_id=t_movgest_ts.movgest_ts_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno
                AND d_movgest_tipo.movgest_tipo_code='A'    --accertamento  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL
                AND r_ord_ts_movgest_ts.data_cancellazione IS NULL),	
soggetto as (
    		SELECT r_ord_soggetto.ord_id,
                t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc
            FROM siac_r_ordinativo_soggetto r_ord_soggetto,
                siac_t_soggetto t_soggetto
            WHERE r_ord_soggetto.soggetto_id=   t_soggetto.soggetto_id
                and t_soggetto.ente_proprietario_id=p_ente_prop_id
                AND t_soggetto.data_cancellazione IS NULL  
                AND r_ord_soggetto.data_cancellazione IS NULL) ,   
	categ as (
	SELECT  r_ord_class.ord_id,
           COALESCE( t_class.classif_code,'') categ_code, 
            COALESCE(t_class.classif_desc,'') categ_desc 
        from siac_r_ordinativo_class r_ord_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where t_class.classif_id 					= 	r_ord_class.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and upper(d_class_tipo.classif_tipo_code) = 'CATEGORIA'			
                 and r_ord_class.ente_proprietario_id=p_ente_prop_id
                   AND r_ord_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL  ),                  	              
	conto_integrato as (    	
      select distinct t_ordinativo.ord_id, 
          t_mov_ep_det.movep_det_segno,
          t_pdce_conto.pdce_conto_code
      from siac_r_evento_reg_movfin r_ev_reg_movfin,
          siac_t_ordinativo t_ordinativo,
          siac_d_evento d_evento,
          siac_d_collegamento_tipo d_coll_tipo,
          siac_t_reg_movfin t_reg_movfin,
          siac_t_mov_ep t_mov_ep,
          siac_t_mov_ep_det t_mov_ep_det,
          siac_t_pdce_conto t_pdce_conto
      where t_ordinativo.ord_id=r_ev_reg_movfin.campo_pk_id
          and d_evento.evento_id=r_ev_reg_movfin.evento_id
          and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
          and t_reg_movfin.regmovfin_id=r_ev_reg_movfin.regmovfin_id
          and t_mov_ep.regmovfin_id=t_reg_movfin.regmovfin_id
          and t_mov_ep_det.movep_id=t_mov_ep.movep_id
          and t_pdce_conto.pdce_conto_id=t_mov_ep_det.pdce_conto_id
          and t_ordinativo.ente_proprietario_id=p_ente_prop_id
          and d_coll_tipo.collegamento_tipo_code='OI'    --Ordinativo di Incasso 
          and r_ev_reg_movfin.data_cancellazione is null
          and t_ordinativo.data_cancellazione is null
          and d_evento.data_cancellazione is null
          and d_coll_tipo.data_cancellazione is null
          and t_reg_movfin.data_cancellazione is null
          and t_mov_ep.data_cancellazione is null
          and t_mov_ep_det.data_cancellazione is null
          and t_pdce_conto.data_cancellazione is null )                                           
SELECT reversali.ord_numero::varchar num_reversale,
	reversali.ord_anno::integer anno_reversale,
	reversali.ord_stato_code::varchar stato_reversale,
	reversali.ord_stato_desc::varchar desc_stato_reversale,
    reversali.ord_ts_det_importo::numeric importo_reversale,
    CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='DARE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_dare,
     CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='AVERE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_avere,
    accert.movgest_numero::numeric num_accertamento,
	accert.movgest_anno::integer anno_accertamento,
	accert.movgest_ts_code::varchar num_subaccertamento,
    accert.movgest_ts_tipo_code::varchar tipo_accert,
    soggetto.soggetto_code::varchar code_soggetto,
	soggetto.soggetto_desc::varchar desc_soggetto,
	COALESCE(categ.categ_code,'')::varchar categoria,
    reversali.ord_ts_id::integer ord_ts_id
FROM reversali
	LEFT JOIN accert on accert.ord_ts_id=reversali.ord_ts_id		
    LEFT JOIN soggetto on soggetto.ord_id=reversali.ord_id
    LEFT JOIN categ on categ.ord_id=reversali.ord_id
    LEFT JOIN conto_integrato on conto_integrato.ord_id = reversali.ord_id     
ORDER BY anno_reversale, num_reversale) query_totale;

RTN_MESSAGGIO:='Estrazione dei dati degli accertamenti ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun accertamento trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

DROP FUNCTION siac."BILR152_elenco_liquidazioni"(p_ente_prop_id integer, p_anno varchar, p_numero_provv integer, p_anno_provv varchar, p_tipo_provv varchar);

CREATE OR REPLACE FUNCTION siac."BILR152_elenco_liquidazioni" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  num_liquidazione varchar,
  anno_liquidazione integer,
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  cup varchar,
  cig varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  tipo varchar,
  tipo_finanz varchar,
  conto_dare varchar,
  conto_avere varchar,
  importo_liquidazione numeric,
  code_cofog varchar,
  code_programma varchar,
  anno_mandato integer,
  numero_mandato numeric,
  code_stato_mandato varchar,
  desc_stato_mandato varchar,
  code_soggetto_mandato varchar,
  desc_soggetto_mandato varchar,
  code_modpag_mandato varchar,
  desc_modpag_mandato varchar,
  importo_mandato numeric,
  pdce_v varchar,
  trans_eu varchar,
  ricorrente varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;
 
sqlQuery varchar;

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
num_liquidazione:='';
anno_liquidazione:=0;
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
code_soggetto:='';
desc_soggetto:=0;
tipo:='';
tipo_finanz:='';
conto_dare:='';
conto_avere:='';
importo_liquidazione:=0;
code_programma:='';
code_cofog:='';
cup:='';
cig:='';
anno_mandato:=0;
numero_mandato:=0;
code_stato_mandato:='';
desc_stato_mandato:='';
code_soggetto_mandato:='';
desc_soggetto_mandato:='';
code_modpag_mandato:='';
desc_modpag_mandato:='';
importo_mandato:=0;
pdce_v:='';
trans_eu:='';
ricorrente :='';

anno_eser_int=p_anno ::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
 with liquidazioni as (
 			select t_liquidazione.liq_anno,
              t_liquidazione.liq_numero,
              t_liquidazione.liq_id,       
              t_liquidazione.liq_importo
           from  siac_t_liquidazione t_liquidazione,     
           		siac_r_liquidazione_atto_amm r_liq_atto_amm ,    
                siac_t_atto_amm t_atto_amm  ,
                siac_d_atto_amm_tipo	tipo_atto,
                siac_t_bil t_bil,
                siac_t_periodo t_periodo
          where t_liquidazione.liq_id=   r_liq_atto_amm.liq_id
          		AND t_atto_amm.attoamm_id=r_liq_atto_amm.attoamm_id
                AND t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
                AND t_bil.bil_id=t_liquidazione.bil_id
                AND t_periodo.periodo_id=t_bil.periodo_id
               	AND t_liquidazione.ente_proprietario_id =p_ente_prop_id
               	AND t_atto_amm.attoamm_numero=p_numero_provv
                AND t_atto_amm.attoamm_anno=p_anno_provv
                AND tipo_atto.attoamm_tipo_code=p_tipo_provv
                AND t_periodo.anno=p_anno
                AND t_liquidazione.data_cancellazione IS NULL
                AND r_liq_atto_amm.data_cancellazione IS NULL
                AND t_atto_amm.data_cancellazione IS NULL
                AND tipo_atto.data_cancellazione IS NULL
                AND t_bil.data_cancellazione IS NULL
                AND t_periodo.data_cancellazione IS NULL),
 impegni as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		r_liq_movgest_ts.liq_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                 CASE WHEN d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'                 
                    THEN 'IMP'
                    ELSE 'SUB' end tipo_impegno,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,        
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato ,
                siac_r_liquidazione_movgest r_liq_movgest_ts
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	               
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND r_liq_movgest_ts.movgest_ts_id=t_movgest_ts.movgest_ts_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno
                AND d_movgest_tipo.movgest_tipo_code='I'    --impegno  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL
                AND r_liq_movgest_ts.data_cancellazione IS NULL),
	soggetto_liq as (
    		SELECT r_liq_sog.liq_id,
                t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc
            FROM siac_r_liquidazione_soggetto r_liq_sog,
                siac_t_soggetto t_soggetto
            WHERE r_liq_sog.soggetto_id=   t_soggetto.soggetto_id
                and t_soggetto.ente_proprietario_id=p_ente_prop_id
                AND t_soggetto.data_cancellazione IS NULL  
                AND r_liq_sog.data_cancellazione IS NULL) ,         	 
    	capitoli as(
        	select r_movgest_bil_elem.movgest_id,
            	t_bil_elem.elem_id,
            	t_bil_elem.elem_code,
                t_bil_elem.elem_code2,
                t_bil_elem.elem_code3,
                t_bil_elem.elem_desc,
                t_bil_elem.elem_desc2
            from 	siac_r_movgest_bil_elem r_movgest_bil_elem,
            	siac_t_bil_elem t_bil_elem
            where r_movgest_bil_elem.elem_id=t_bil_elem.elem_id            
            	AND r_movgest_bil_elem.ente_proprietario_id=p_ente_prop_id
            	AND t_bil_elem.data_cancellazione IS NULL
                AND r_movgest_bil_elem.data_cancellazione IS NULL),
elenco_pdce_finanz as (        
SELECT  r_bil_elem_class.elem_id,
           COALESCE( t_class.classif_code,'') pdce_code, 
            COALESCE(t_class.classif_desc,'') pdce_desc 
        from siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where t_class.classif_id 					= 	r_bil_elem_class.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and d_class_tipo.classif_tipo_code like 'PDC_%'			
                 and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL    )  ,
        elenco_attrib as(
        	select * from "fnc_bilr152_tab_attrib"(p_ente_prop_id))  ,
        programma as (
        	select t_programma.programma_code,
            	r_movgest_ts_prog.movgest_ts_id
            from siac_r_movgest_ts_programma     r_movgest_ts_prog,
            	siac_t_programma t_programma
            where r_movgest_ts_prog.programma_id= t_programma.programma_id
            	and r_movgest_ts_prog.ente_proprietario_id=p_ente_prop_id
            	and t_programma.data_cancellazione is null
                and r_movgest_ts_prog.data_cancellazione is null) ,
        tipo_finanz_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='TIPO_FINANZIAMENTO' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ),
        cofog_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='GRUPPO_COFOG' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ), 
        programma_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='PROGRAMMA' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ),                                        
  elencocig as (
  				select  t_attr.attr_code attr_code_cig, 
                  r_liq_attr.testo testo_cig,
                  r_liq_attr.liq_id
                from siac_t_attr t_attr,
                    siac_r_liquidazione_attr  r_liq_attr
                where  r_liq_attr.attr_id=t_attr.attr_id          
                    and t_attr.ente_proprietario_id=p_ente_prop_id        
                	AND upper(t_attr.attr_code) = 'CIG'          
                    and r_liq_attr.data_cancellazione IS NULL
                    and t_attr.data_cancellazione IS NULL),
    elencocup as (
    			select  t_attr.attr_code attr_code_cup, 
                  r_liq_attr.testo testo_cup,
                  r_liq_attr.liq_id
                from siac_t_attr t_attr,
                       siac_r_liquidazione_attr  r_liq_attr
                where  r_liq_attr.attr_id=t_attr.attr_id          
                        and t_attr.ente_proprietario_id=p_ente_prop_id  
                        AND upper(t_attr.attr_code) = 'CUP'          
                        and r_liq_attr.data_cancellazione IS NULL
                        and t_attr.data_cancellazione IS NULL),
  	elenco_mandati as (    			
        SELECT r_liq_ord.liq_id,
        	t_ord.ord_anno, t_ord.ord_numero,
            d_ord_stato.ord_stato_code, d_ord_stato.ord_stato_desc,
            case when t_modpag.modpag_id is not null 
                then COALESCE(d_accredito_tipo.accredito_tipo_code,'')
                else  COALESCE(d_accredito_tipo1.accredito_tipo_code,'') end code_pagamento,
            case when t_modpag.modpag_id is not null 
                then COALESCE(d_accredito_tipo.accredito_tipo_desc,'')
                else  COALESCE(d_accredito_tipo1.accredito_tipo_desc,'') end desc_pagamento,
            t_soggetto.soggetto_code, t_soggetto.soggetto_desc,
            t_ord_ts_det.ord_ts_det_importo
        FROM siac_r_liquidazione_ord r_liq_ord,
            siac_t_ordinativo_ts t_ord_ts,
            siac_t_ordinativo_ts_det t_ord_ts_det,
            siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
            siac_t_ordinativo t_ord,
            siac_r_ordinativo_stato r_ord_stato,
            siac_d_ordinativo_stato d_ord_stato,
            siac_r_ordinativo_modpag r_ord_modpag
            LEFT JOIN siac_t_modpag t_modpag 
                    ON (t_modpag.modpag_id=r_ord_modpag.modpag_id
                        AND t_modpag.data_cancellazione IS NULL)
            LEFT JOIN siac_d_accredito_tipo d_accredito_tipo 
              ON (d_accredito_tipo.accredito_tipo_id=t_modpag.accredito_tipo_id
                  AND d_accredito_tipo.data_cancellazione IS NULL) 
            /* in caso di cessione di incasso su siac_r_ordinativo_modpag
            non e' valorizzata la modalita' di pagamento.
            Devo cercare quella del soggetto a cui e' stato ceduto l'incasso. */
            LEFT JOIN  siac_r_soggrel_modpag r_sogg_modpag
                ON (r_ord_modpag.soggetto_relaz_id=r_sogg_modpag.soggetto_relaz_id
                    AND r_sogg_modpag.data_cancellazione IS NULL)
            LEFT JOIN siac_t_modpag t_modpag1 
                ON (t_modpag1.modpag_id=r_sogg_modpag.modpag_id
                    AND t_modpag1.data_cancellazione IS NULL)
            LEFT JOIN siac_d_accredito_tipo d_accredito_tipo1 
                ON (d_accredito_tipo1.accredito_tipo_id=t_modpag1.accredito_tipo_id
                    AND d_accredito_tipo1.data_cancellazione IS NULL),
            siac_d_ordinativo_tipo d_ord_tipo ,
            siac_r_ordinativo_soggetto r_ord_soggetto,
            siac_t_soggetto t_soggetto
        WHERE r_liq_ord.sord_id=t_ord_ts.ord_ts_id
            AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
            AND d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
            AND t_ord.ord_id=t_ord_ts.ord_id
            AND r_ord_stato.ord_id=t_ord.ord_id
            AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
            AND r_ord_modpag.ord_id=t_ord.ord_id
            AND d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
            AND r_ord_soggetto.ord_id=t_ord.ord_id
            AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
            AND r_liq_ord.ente_proprietario_id=p_ente_prop_id
            AND d_ord_tipo.ord_tipo_code='P' --Pagamento
            AND d_ord_ts_det_tipo.ord_ts_det_tipo_code='A' -- importo Attuale
            AND d_ord_stato.ord_stato_code <> 'A' --Annullato
            AND r_liq_ord.data_cancellazione IS NULL
            AND t_ord_ts.data_cancellazione IS NULL
            AND t_ord_ts_det.data_cancellazione IS NULL
            AND d_ord_ts_det_tipo.data_cancellazione IS NULL
            AND t_ord.data_cancellazione IS NULL
            AND r_ord_modpag.data_cancellazione IS NULL 
            AND d_ord_tipo.data_cancellazione IS NULL
            AND r_ord_soggetto.data_cancellazione IS NULL
            AND t_soggetto.data_cancellazione IS NULL
            AND r_ord_stato.data_cancellazione IS NULL
            AND d_ord_stato.data_cancellazione IS NULL
            AND r_ord_stato.validita_fine IS NULL)   ,
conto_integrato as (    	
      select distinct t_liq.liq_id, 
          t_mov_ep_det.movep_det_segno,
          t_pdce_conto.pdce_conto_code
      from siac_r_evento_reg_movfin r_ev_reg_movfin,
          siac_t_liquidazione t_liq,
          siac_d_evento d_evento,
          siac_d_collegamento_tipo d_coll_tipo,
          siac_t_reg_movfin t_reg_movfin,
          siac_t_mov_ep t_mov_ep,
          siac_t_mov_ep_det t_mov_ep_det,
          siac_t_pdce_conto t_pdce_conto
      where t_liq.liq_id=r_ev_reg_movfin.campo_pk_id
          and d_evento.evento_id=r_ev_reg_movfin.evento_id
          and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
          and t_reg_movfin.regmovfin_id=r_ev_reg_movfin.regmovfin_id
          and t_mov_ep.regmovfin_id=t_reg_movfin.regmovfin_id
          and t_mov_ep_det.movep_id=t_mov_ep.movep_id
          and t_pdce_conto.pdce_conto_id=t_mov_ep_det.pdce_conto_id
          and t_liq.ente_proprietario_id=p_ente_prop_id
          and d_coll_tipo.collegamento_tipo_code='L' --Liquidazione 
          and r_ev_reg_movfin.data_cancellazione is null
          and t_liq.data_cancellazione is null
          and d_evento.data_cancellazione is null
          and d_coll_tipo.data_cancellazione is null
          and t_reg_movfin.data_cancellazione is null
          and t_mov_ep.data_cancellazione is null
          and t_mov_ep_det.data_cancellazione is null
          and t_pdce_conto.data_cancellazione is null ) ,
      /* 12/06/2017: aggiunta la gestione delle classificazioni dell
      	liquidazioni */
	elenco_class_liq as (select *
    			from "fnc_bilr152_tab_class_liquid"(p_ente_prop_id))                                                   
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
    liquidazioni.liq_numero::varchar num_liquidazione,
    liquidazioni.liq_anno::integer anno_liquidazione,
    COALESCE(impegni.movgest_numero,0)::numeric num_impegno,
    COALESCE(impegni.movgest_anno,0)::integer anno_impegno,
    COALESCE(impegni.movgest_ts_code,'')::varchar num_subimpegno,
    COALESCE(elencocup.testo_cup,'')::varchar cup,
    COALESCE(elencocig.testo_cig,'')::varchar cig,
    COALESCE(soggetto_liq.soggetto_code,'')::varchar code_soggetto,
	COALESCE(soggetto_liq.soggetto_desc,'')::varchar desc_soggetto,
   -- CASE WHEN upper(COALESCE(elenco_attrib.flag_prenotazione,'')) = 'S'
    --	THEN 'PR'::varchar 
     --   ELSE impegni.tipo_impegno::varchar  end tipo,
    'LIQ'::varchar tipo,
    COALESCE(tipo_finanz_cap.classif_code,'')::varchar tipo_finanz,
    CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='DARE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_dare,
     CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='AVERE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_avere,
	liquidazioni.liq_importo::numeric importo_liquidazione,
    COALESCE(cofog_cap.classif_code,'')::varchar code_cofog,
    COALESCE(programma_cap.classif_code,'')::varchar code_programma,
    COALESCE(elenco_mandati.ord_anno,0)::integer anno_mandato,
    COALESCE(elenco_mandati.ord_numero,0)::numeric numero_mandato,
	COALESCE(elenco_mandati.ord_stato_code,'')::varchar code_stato_mandato,
	COALESCE(elenco_mandati.ord_stato_desc,'')::varchar desc_stato_mandato,
	COALESCE(elenco_mandati.soggetto_code,'')::varchar code_soggetto_mandato,
    COALESCE(elenco_mandati.soggetto_desc,'')::varchar desc_soggetto_mandato,
	COALESCE(elenco_mandati.code_pagamento,'')::varchar code_modpag_mandato,
    COALESCE(elenco_mandati.desc_pagamento,'')::varchar desc_modpag_mandato,
	COALESCE(elenco_mandati.ord_ts_det_importo,0)::numeric importo_mandato,
    COALESCE(elenco_class_liq.pdc_v,'')::varchar pdce_v,
    COALESCE(elenco_class_liq.code_transaz_ue,'')::varchar trans_eu,
    COALESCE(elenco_class_liq.ricorrente_spesa,'')::varchar ricorrente
FROM liquidazioni
	LEFT JOIN impegni on impegni.liq_id=liquidazioni.liq_id
	LEFT JOIN soggetto_liq on soggetto_liq.liq_id=liquidazioni.liq_id
	LEFT JOIN capitoli on capitoli.movgest_id = impegni.movgest_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.elem_id = capitoli.elem_id 
    LEFT join elenco_attrib on elenco_attrib.movgest_ts_id = impegni.movgest_ts_id
    LEFT join programma on programma.movgest_ts_id = impegni.movgest_ts_id
    LEFT join tipo_finanz_cap on tipo_finanz_cap.elem_id = capitoli.elem_id 
    LEFT join elencocig on elencocig.liq_id=liquidazioni.liq_id  
    LEFT join elencocup on elencocup.liq_id=liquidazioni.liq_id  
    LEFT join cofog_cap on cofog_cap.elem_id = capitoli.elem_id
    LEFT join programma_cap on programma_cap.elem_id = capitoli.elem_id 
    LEFT JOIN elenco_mandati on elenco_mandati.liq_id=liquidazioni.liq_id 
    LEFT JOIN conto_integrato on conto_integrato.liq_id=liquidazioni.liq_id   
    LEFT JOIN elenco_class_liq on elenco_class_liq.liquid_id=liquidazioni.liq_id                 
ORDER BY anno_impegno, num_impegno, tipo, num_subimpegno) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun accertamento trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-5029 FINE

--CR-407 INIZIO
CREATE OR REPLACE FUNCTION siac."BILR158_strutura_dca_stato_patrimonio" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  nome_ente varchar,
  fam_code varchar,
  fam_desc varchar,
  segno_importo varchar,
  pdce_conto_code varchar,
  pdce_conto_desc varchar,
  importo numeric,
  livello integer
) AS
$body$
DECLARE

elenco_prime_note record;
v_pdce_conto_code varchar;
v_pdce_conto_desc varchar;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		 varchar(1000):=DEF_NULL;

BEGIN

nome_ente := '';
fam_code := '';
fam_desc := '';
segno_importo := '';
pdce_conto_code := '';
pdce_conto_desc := ''; 
importo := 0; 
livello := 0;

SELECT a.ente_denominazione
INTO  nome_ente
FROM  siac_t_ente_proprietario a
WHERE a.ente_proprietario_id = p_ente_prop_id;

FOR elenco_prime_note IN 
SELECT d.pdce_fam_code, d.pdce_fam_desc,
e.movep_det_segno, 
SUM(COALESCE(e.movep_det_importo,0)) AS importo,
b.pdce_conto_code, b.pdce_conto_desc, b.livello,
b.pdce_conto_id_padre
FROM  siac_t_pdce_conto b
INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id   
WHERE b.ente_proprietario_id = p_ente_prop_id
AND   m.pnota_stato_code = 'D'
AND   i.anno = p_anno
AND   d.pdce_fam_code in ('PP','AP','OP','OA')
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   f.data_cancellazione IS NULL
AND   g.data_cancellazione IS NULL
AND   h.data_cancellazione IS NULL
AND   i.data_cancellazione IS NULL
AND   l.data_cancellazione IS NULL
AND   m.data_cancellazione IS NULL 
GROUP BY d.pdce_fam_code, d.pdce_fam_desc, e.movep_det_segno, 
b.pdce_conto_code, b.pdce_conto_desc, b.livello,
b.pdce_conto_id_padre
ORDER BY d.pdce_fam_code, b.pdce_conto_code
  
LOOP

  IF elenco_prime_note.livello = 8 THEN
    
    v_pdce_conto_code := null;
    v_pdce_conto_desc := null;
  
    SELECT b.pdce_conto_code, b.pdce_conto_desc
    INTO  v_pdce_conto_code, v_pdce_conto_desc
    FROM  siac_t_pdce_conto b
    WHERE b.pdce_conto_id = elenco_prime_note.pdce_conto_id_padre
    AND   b.data_cancellazione IS NULL;
  
    pdce_conto_code := v_pdce_conto_code;
    pdce_conto_desc := v_pdce_conto_desc;
  
  ELSE
  
    pdce_conto_code := elenco_prime_note.pdce_conto_code;
    pdce_conto_desc := elenco_prime_note.pdce_conto_desc;
    
  END IF;

  fam_code := elenco_prime_note.pdce_fam_code;
  fam_desc := elenco_prime_note.pdce_fam_desc;
  segno_importo := elenco_prime_note.movep_det_segno;
  importo := elenco_prime_note.importo;
  livello := elenco_prime_note.livello;

  return next;

  fam_code := '';
  fam_desc := '';
  segno_importo := '';
  pdce_conto_code := '';
  pdce_conto_desc := ''; 
  importo := 0; 
  livello := 0;

END LOOP;

EXCEPTION
	when no_data_found THEN
		 raise notice 'Dati non trovati' ;
	when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'DCA Patrimonio',substring(SQLERRM from 1 for 500);
         return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR159_struttura_dca_conto_economico" (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer
)
RETURNS TABLE (
  nome_ente varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  segno_importo varchar,
  importo numeric,
  pdce_conto_code varchar,
  pdce_conto_desc varchar,
  livello integer
) AS
$body$
DECLARE

nome_ente varchar;
bilancio_id integer;
RTN_MESSAGGIO text;

BEGIN
  RTN_MESSAGGIO:='select 1';
  
  SELECT a.ente_denominazione
  INTO  nome_ente
  FROM  siac_t_ente_proprietario a
  WHERE a.ente_proprietario_id = p_ente_proprietario_id;
    
  select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_proprietario_id 
  and b.periodo_id = a.periodo_id
  and b.anno = p_anno_bilancio;

  return query
  select zz.* from (
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
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00001'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
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
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00001'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
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
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00002'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
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
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00002'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
  and b.classif_id_padre is not null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id
  )
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
  from missione , programma,titusc, macroag, siac_r_class progmacro
  where programma.missione_id=missione.missione_id
  and titusc.titusc_id=macroag.titusc_id
  AND programma.programma_id = progmacro.classif_a_id
  AND titusc.titusc_id = progmacro.classif_b_id
  and titusc.ente_proprietario_id=missione.ente_proprietario_id
   ),
  capall as (
  with
  cap as (
  select a.elem_id,
  a.elem_code ,
  a.elem_desc ,
  a.elem_code2 ,
  a.elem_desc2 ,
  a.elem_id_padre ,
  a.elem_code3,
  d.classif_id programma_id,d2.classif_id macroag_id
  from siac_t_bil_elem a,siac_d_bil_elem_tipo b, siac_r_bil_elem_class c,
  siac_r_bil_elem_class c2,
  siac_t_class d,siac_t_class d2,
  siac_d_class_tipo e,siac_d_class_tipo e2, siac_r_bil_elem_categoria f, 
  siac_d_bil_elem_categoria g,siac_r_bil_elem_stato h,siac_d_bil_elem_stato i
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.bil_id=bilancio_id
  and b.elem_tipo_id=a.elem_tipo_id
  and b.elem_tipo_code = 'CAP-UG'
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
  and g.elem_cat_code in	('STD','FPV','FSC','FPVC')
  and h.elem_id=a.elem_id
  and i.elem_stato_id=h.elem_stato_id
  and i.elem_stato_code = 'VA'
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
  dati_prime_note as(
  WITH prime_note AS (
  SELECT d.pdce_fam_code, d.pdce_fam_desc,
  e.movep_det_segno,
  e.movep_det_importo importo,
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_code
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_code
  END pdce_conto_code,   
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_desc
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_desc
  END pdce_conto_desc,
  n.campo_pk_id,
  q.collegamento_tipo_code,
  b.livello
  FROM  siac_t_pdce_conto b
  INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
  INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
  INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
  INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
  INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
  INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
  INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
  INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
  INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id 
  INNER JOIN siac_r_evento_reg_movfin n ON n.regmovfin_id = f.regmovfin_id
  INNER JOIN siac_d_evento p ON p.evento_id = n.evento_id
  INNER JOIN siac_d_collegamento_tipo q ON q.collegamento_tipo_id = p.collegamento_tipo_id
  WHERE b.ente_proprietario_id = p_ente_proprietario_id
  AND   m.pnota_stato_code = 'D'
  AND   i.anno = p_anno_bilancio
  AND   d.pdce_fam_code in ('CE')
  AND   b.data_cancellazione IS NULL
  AND   c.data_cancellazione IS NULL
  AND   d.data_cancellazione IS NULL
  AND   e.data_cancellazione IS NULL
  AND   f.data_cancellazione IS NULL
  AND   g.data_cancellazione IS NULL
  AND   h.data_cancellazione IS NULL
  AND   i.data_cancellazione IS NULL
  AND   l.data_cancellazione IS NULL
  AND   m.data_cancellazione IS NULL
  AND   n.data_cancellazione IS NULL
  AND   p.data_cancellazione IS NULL
  AND   q.data_cancellazione IS NULL
  ), collegamento_MMGS_MMGE_a AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe
  WHERE rms.ente_proprietario_id = p_ente_proprietario_id
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = 'V'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  ),
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe
  WHERE rms.ente_proprietario_id = p_ente_proprietario_id
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = 'V'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  ),
  collegamento_I_A AS (
  SELECT DISTINCT a.elem_id, a.movgest_id
  FROM   siac_r_movgest_bil_elem a
  WHERE  a.ente_proprietario_id = p_ente_proprietario_id
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_SI_SA AS (
  SELECT DISTINCT b.elem_id, a.movgest_ts_id
  FROM  siac_t_movgest_ts a, siac_r_movgest_bil_elem b
  WHERE a.ente_proprietario_id = p_ente_proprietario_id
  AND   a.movgest_id = b.movgest_id
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  ),
  collegamento_SS_SE AS (
  SELECT DISTINCT c.elem_id, a.subdoc_id
  FROM   siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = p_ente_proprietario_id
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_OP_OI AS (
  SELECT DISTINCT a.elem_id, a.ord_id
  FROM   siac_r_ordinativo_bil_elem a
  WHERE  a.ente_proprietario_id = p_ente_proprietario_id
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_L AS (
  SELECT DISTINCT c.elem_id, a.liq_id
  FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = p_ente_proprietario_id
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_RR AS (
  SELECT DISTINCT d.elem_id, a.gst_id
  FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
  WHERE a.ente_proprietario_id = p_ente_proprietario_id
  AND   a.ricecon_id = b.ricecon_id
  AND   b.movgest_ts_id = c.movgest_ts_id
  AND   c.movgest_id = d.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   d.data_cancellazione  IS NULL
  ),
  collegamento_RE AS (
  SELECT DISTINCT c.elem_id, a.ricecon_id
  FROM  siac_r_richiesta_econ_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE b.ente_proprietario_id = p_ente_proprietario_id
  AND   a.movgest_ts_id = b.movgest_ts_id
  AND   b.movgest_id = c.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  )
  SELECT 
  prime_note.movep_det_segno,
  prime_note.importo,
  prime_note.pdce_conto_code,
  prime_note.pdce_conto_desc,
  prime_note.livello,
  -- COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),
  -- collegamento_SS_SE.elem_id,
  -- collegamento_I_A.elem_id,
  -- collegamento_SI_SA.elem_id
  -- collegamento_OP_OI.elem_id
  -- collegamento_L.elem_id
  -- collegamento_RR.elem_id
  -- collegamento_RE.elem_id
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id) elem_id
  FROM   prime_note
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('MMGS','MMGE') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('MMGS','MMGE')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('I','A')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('SI','SA')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('SS','SE')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('OP','OI')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = 'L'
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = 'RR'
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = 'RE'
  )                      
  select distinct
  cap.elem_id bil_ele_id,
  cap.elem_code bil_ele_code,
  cap.elem_desc bil_ele_desc,
  cap.elem_code2 bil_ele_code2,
  cap.elem_desc2 bil_ele_desc2,
  cap.elem_id_padre bil_ele_id_padre,
  cap.elem_code3 bil_ele_code3,
  cap.programma_id,cap.macroag_id,
  dati_prime_note.*
  from cap
  left join dati_prime_note on cap.elem_id = dati_prime_note.elem_id  
  )
  select 
      nome_ente::varchar,
      --''::varchar missione_tipo_code,
      --clas.missione_tipo_desc::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      --''::varchar programma_tipo_code,
      --clas.programma_tipo_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
  /*    ''::varchar	titusc_tipo_code,
      clas.titusc_tipo_desc::varchar,
      clas.titusc_code::varchar,
      clas.titusc_desc::varchar,
      ''::varchar macroag_tipo_code,
      clas.macroag_tipo_desc::varchar,
      clas.macroag_code::varchar,
      clas.macroag_desc::varchar,
      capall.bil_ele_code::varchar,
      capall.bil_ele_desc::varchar,
      capall.bil_ele_code2::varchar,
      capall.bil_ele_desc2::varchar,
      capall.bil_ele_id::integer,
      capall.bil_ele_id_padre::integer,
      capall.bil_ele_code3::varchar,*/
      capall.movep_det_segno::varchar,
      capall.importo::numeric,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null
  union 
    select 
      nome_ente::varchar,
      --''::varchar missione_tipo_code,
      --clas.missione_tipo_desc::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      --''::varchar programma_tipo_code,
      --clas.programma_tipo_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
  /*    ''::varchar	titusc_tipo_code,
      clas.titusc_tipo_desc::varchar,
      clas.titusc_code::varchar,
      clas.titusc_desc::varchar,
      ''::varchar macroag_tipo_code,
      clas.macroag_tipo_desc::varchar,
      clas.macroag_code::varchar,
      clas.macroag_desc::varchar,
      capall.bil_ele_code::varchar,
      capall.bil_ele_desc::varchar,
      capall.bil_ele_code2::varchar,
      capall.bil_ele_desc2::varchar,
      capall.bil_ele_id::integer,
      capall.bil_ele_id_padre::integer,
      capall.bil_ele_code3::varchar,*/
      'Avere',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null
  union
      select 
      nome_ente::varchar,
      --''::varchar missione_tipo_code,
      --clas.missione_tipo_desc::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      --''::varchar programma_tipo_code,
      --clas.programma_tipo_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
  /*    ''::varchar	titusc_tipo_code,
      clas.titusc_tipo_desc::varchar,
      clas.titusc_code::varchar,
      clas.titusc_desc::varchar,
      ''::varchar macroag_tipo_code,
      clas.macroag_tipo_desc::varchar,
      clas.macroag_code::varchar,
      clas.macroag_desc::varchar,
      capall.bil_ele_code::varchar,
      capall.bil_ele_desc::varchar,
      capall.bil_ele_code2::varchar,
      capall.bil_ele_desc2::varchar,
      capall.bil_ele_id::integer,
      capall.bil_ele_id_padre::integer,
      capall.bil_ele_code3::varchar,*/
      'Dare',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null
  ) as zz; 

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
--cr-407 FINE

-- SIAC-4799 INIZIO
ALTER TABLE siac_t_cassa_econ_stampa
	ADD COLUMN attoal_id INTEGER;

ALTER TABLE siac_t_cassa_econ_stampa
	ADD CONSTRAINT siac_t_atto_allegato_siac_t_cassa_econ_stampa
	FOREIGN KEY (attoal_id) REFERENCES siac_t_atto_allegato (attoal_id) 
	ON UPDATE NO ACTION ON DELETE NO ACTION;
-- SIAC-4799 FINE

-- SIAC-4961 INIZIO
INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('GESTIONE_ACCREDITO', 'Codici Accredito Elaborazioni Massive')) AS tmp(code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('ACCREDITO_CONTANTI', '', 'GESTIONE_ACCREDITO'),
	('ACCREDITO_CONTO_BANCA', '', 'GESTIONE_ACCREDITO')) AS tmp(code, descr, tipo)
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
SELECT dgl.gestione_livello_id, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('ACCREDITO_CONTANTI'),
	('ACCREDITO_CONTO_BANCA')) AS tmp(livello)
WHERE dgl.gestione_livello_code = tmp.livello
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
	AND rge.data_cancellazione IS NULL
);
-- SIAC-4961 FINE

-- SIAC-4970 INIZIO
INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('GESTIONE_CONSULTAZIONE_CAP_PRENOTAZIONI', 'Gestione della consultazione delle prenotazioni su capitolo')) AS tmp(code, descr)
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
CROSS JOIN (VALUES ('GESTIONE_CONSULTAZIONE_CAP_PRENOTAZIONI', 'Gestione della consultazione delle prenotazioni su capitolo', 'GESTIONE_CONSULTAZIONE_CAP_PRENOTAZIONI')) AS tmp(code, descr, tipo)
WHERE dgt.gestione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

-- Insert per CMTO
INSERT INTO siac_r_gestione_ente (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dgl.gestione_livello_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('GESTIONE_CONSULTAZIONE_CAP_PRENOTAZIONI', 'CITTA METROPOLITANA DI TORINO')) AS tmp(livello, ente)
WHERE UPPER(TRANSLATE(tep.ente_denominazione, 'àâÀÁèéìíÌÍóÒÓùúÙÚ''', 'aaaaeeiiiiooouuuu')) = tmp.ente
AND dgl.gestione_livello_code = tmp.livello
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
	AND rge.data_cancellazione IS NULL
);
-- SIAC-4970 FINE

-- SIAC-5041 INIZIO
INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
) select 'OP-ENT-PreDocNoModAcc', 'Predoc entrata - modifica acc. non ammessa', ta.azione_tipo_id, ga.gruppo_azioni_id,
 '/../siacbilapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'),
 e.ente_proprietario_id, 'admin'
  from siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
  where  ta.ente_proprietario_id = e.ente_proprietario_id
  and ga.ente_proprietario_id = e.ente_proprietario_id
  and ta.azione_tipo_code = 'AZIONE_SECONDARIA'
  and ga.gruppo_azioni_code = 'FIN_BASE2'
  and not exists (select 1 from siac_t_azione z where z.azione_tipo_id=ta.azione_tipo_id
  and z.azione_code='OP-ENT-PreDocNoModAcc')
  ;
-- SIAC-5041 FINE


