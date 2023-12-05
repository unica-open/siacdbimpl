/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-6336  Sofia - INIZIO

SELECT fnc_dba_add_column_params('siac_dwh_impegno', 'stato_programma', 'varchar(200)');
SELECT fnc_dba_add_column_params('siac_dwh_impegno', 'versione_cronop', 'varchar(200)');
SELECT fnc_dba_add_column_params('siac_dwh_impegno', 'desc_cronop', 'varchar(500)');
SELECT fnc_dba_add_column_params('siac_dwh_impegno', 'anno_cronop', 'varchar(4)');

SELECT fnc_dba_add_column_params('siac_dwh_accertamento', 'stato_programma', 'varchar(200)');
SELECT fnc_dba_add_column_params('siac_dwh_accertamento', 'versione_cronop', 'varchar(200)');
SELECT fnc_dba_add_column_params('siac_dwh_accertamento', 'desc_cronop', 'varchar(500)');
SELECT fnc_dba_add_column_params('siac_dwh_accertamento', 'anno_cronop', 'varchar(4)');


drop FUNCTION if exists fnc_siac_dwh_impegno 
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

drop FUNCTION if exists fnc_siac_dwh_accertamento (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION fnc_siac_dwh_impegno (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
declare
v_user_table varchar;
params varchar;

begin

select fnc_siac_random_user()
into	v_user_table;

IF p_data IS NULL THEN
   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   ELSE
      p_data := now();
   END IF;
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
'fnc_siac_dwh_impegno',
params,
clock_timestamp(),
v_user_table
);



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
  flagPrenotazione, flagPrenotazioneLiquidabile, flagFrazionabile,
  cod_siope_tipo_debito, desc_siope_tipo_debito, desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione, desc_siope_assenza_motivazione, desc_siope_assenza_motiv_bnkit,
  flag_attiva_gsa, -- 28.05.2018 Sofia siac-6202
  -- 23.10.2018 Sofia siac-6336
  stato_programma,
  versione_cronop,
  desc_cronop,
  anno_cronop
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
xx.flagPrenotazione, xx.flagPrenotazioneLiquidabile, xx.flagFrazionabile,
xx.siope_tipo_debito_code, xx.siope_tipo_debito_desc, xx.siope_tipo_debito_desc_bnkit,
xx.siope_assenza_motivazione_code, xx.siope_assenza_motivazione_desc, xx.siope_assenza_motivazione_desc_bnkit,
xx.flag_attiva_gsa, -- 28.05.2018 Sofia siac-6102
/*xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,*/
-- 23.10.2018 Sofia SIAC-6336
xx.programma_stato,
xx.versione_cronop,
xx.desc_cronop,
xx.anno_cronop
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
       m.fase_operativa_code, m.fase_operativa_desc,
       n.siope_tipo_debito_code, n.siope_tipo_debito_desc, n.siope_tipo_debito_desc_bnkit,
       o.siope_assenza_motivazione_code, o.siope_assenza_motivazione_desc, o.siope_assenza_motivazione_desc_bnkit
FROM
siac_t_movgest_ts a
left join siac_d_siope_tipo_debito n on n.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
left join siac_d_siope_assenza_motivazione o on o.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
, siac_t_movgest b
, siac_t_bil c
, siac_t_periodo d
, siac_t_ente_proprietario e
, siac_d_movgest_tipo f
, siac_d_movgest_ts_tipo g
, siac_r_movgest_ts_stato h
, siac_d_movgest_stato i,
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
--and b.movgest_anno::integer=2018
--and b.movgest_numero::integer between 2550 and 3000
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- SIAC-5883 FINE Daniela 13.02.2018
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- SIAC-5883 FINE Daniela 13.02.2018
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
),
-- 23.10.2018 Sofia siac-6336
progetto as
(
with
 progr as
 (
  select rmtp.movgest_ts_id, tp.programma_code, tp.programma_desc,
         stato.programma_stato_code  programma_stato,
         rmtp.programma_id
  from   siac_r_movgest_ts_programma rmtp, siac_t_programma tp, siac_r_programma_stato rs, siac_d_programma_stato stato
  where  rmtp.programma_id = tp.programma_id
  --and    p_data BETWEEN rmtp.validita_inizio and COALESCE(rmtp.validita_fine,p_data)
  --and    p_data BETWEEN tp.validita_inizio and COALESCE(tp.validita_fine,p_data)
  and    rs.programma_id=tp.programma_id
  and    stato.programma_stato_id=rs.programma_stato_id
  and    rmtp.data_cancellazione IS NULL
  and    tp.data_cancellazione IS NULL
  and    rmtp.validita_fine IS NULL
  and    tp.validita_fine IS NULL
  and    rs.data_cancellazione is null
  and    rs.validita_fine is null
 ),
 -- 23.10.2018 Sofia siac-6336
 cronop as
 (
  select cronop.programma_id,
		 cronop.cronop_id,
         cronop.cronop_code versione_cronop,
         cronop.cronop_desc desc_cronop,
         per.anno::varchar  anno_cronop
  from siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,
       siac_t_periodo per,siac_t_bil bil
  where stato.ente_proprietario_id=p_ente_proprietario_id
  and   stato.cronop_stato_code='VA'
  and   rs.cronop_stato_id=stato.cronop_stato_id
  and   cronop.cronop_id=rs.cronop_id
  and   bil.bil_id=cronop.bil_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::INTEGER=p_anno_bilancio::integer
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   cronop.data_cancellazione is null
  and   cronop.validita_fine is null
  ),
  cronop_ultimo as
  (
  select cronop.programma_id,
		 max(cronop.cronop_id) cronop_id
  from siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,
       siac_t_bil bil ,siac_t_periodo per
  where stato.ente_proprietario_id=p_ente_proprietario_id
  and   stato.cronop_stato_code='VA'
  and   rs.cronop_stato_id=stato.cronop_stato_id
  and   cronop.cronop_id=rs.cronop_id
  and   bil.bil_id=cronop.bil_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::INTEGER=p_anno_bilancio::integer
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   cronop.data_cancellazione is null
  and   cronop.validita_fine is null
  group by cronop.programma_id
  )
  select progr.movgest_ts_id, progr.programma_code, progr.programma_desc,
         progr.programma_stato ,
         cronop.versione_cronop,
         cronop.desc_cronop,
         cronop.anno_cronop
  from progr
   left join cronop join cronop_ultimo on (cronop.cronop_id=cronop_ultimo.cronop_id)
    on (progr.programma_id=cronop.programma_id)
),
impFlagAttivaGsa as -- 28.05.2018 Sofia siac-6102
(
select rattr.movgest_ts_id, rattr.boolean flag_attiva_gsa
from siac_r_movgest_ts_attr rattr, siac_t_attr attr
where attr.ente_proprietario_id=p_ente_proprietario_id
and   attr.attr_code='FlagAttivaGsa'
and   rattr.attr_id=attr.attr_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
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
t_flagFrazionabile.flagFrazionabile,
imp.siope_tipo_debito_code, imp.siope_tipo_debito_desc, imp.siope_tipo_debito_desc_bnkit,
imp.siope_assenza_motivazione_code, imp.siope_assenza_motivazione_desc, imp.siope_assenza_motivazione_desc_bnkit,
coalesce(impFlagAttivaGsa.flag_attiva_gsa,'N') flag_attiva_gsa, -- 28.05.2018 Sofia siac-6102
-- 23.10.2018 Sofia SIAC-6336
progetto.programma_stato,
progetto.versione_cronop,
progetto.desc_cronop,
progetto.anno_cronop
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
left join impFlagAttivaGsa
on
imp.movgest_ts_id=impFlagAttivaGsa.movgest_ts_id -- 28.05.2018 Sofia siac-6102
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
  flagPrenotazione, flagPrenotazioneLiquidabile, flagFrazionabile,
  cod_siope_tipo_debito, desc_siope_tipo_debito, desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione, desc_siope_assenza_motivazione, desc_siope_assenza_motiv_bnkit,
  flag_attiva_gsa -- 28.05.2018 Sofia siac-6202
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
xx.flagPrenotazione, xx.flagPrenotazioneLiquidabile, xx.flagFrazionabile,
xx.siope_tipo_debito_code, xx.siope_tipo_debito_desc, xx.siope_tipo_debito_desc_bnkit,
xx.siope_assenza_motivazione_code, xx.siope_assenza_motivazione_desc, xx.siope_assenza_motivazione_desc_bnkit,
xx.flag_attiva_gsa -- 28.05.2018 Sofia siac-6202
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
       m.fase_operativa_code, m.fase_operativa_desc,
       n.siope_tipo_debito_code, n.siope_tipo_debito_desc, n.siope_tipo_debito_desc_bnkit,
       o.siope_assenza_motivazione_code, o.siope_assenza_motivazione_desc, o.siope_assenza_motivazione_desc_bnkit
FROM
siac_t_movgest_ts a
left join siac_d_siope_tipo_debito n on n.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
left join siac_d_siope_assenza_motivazione o on o.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- FINE SIAC-5883 Daniela 13.02.2018
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- FINE SIAC-5883 Daniela 13.02.2018
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
),
impFlagAttivaGsa as -- 28.05.2018 Sofia siac-6102
(
select rattr.movgest_ts_id, rattr.boolean flag_attiva_gsa
from siac_r_movgest_ts_attr rattr, siac_t_attr attr
where attr.ente_proprietario_id=p_ente_proprietario_id
and   attr.attr_code='FlagAttivaGsa'
and   rattr.attr_id=attr.attr_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
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
t_flagFrazionabile.flagFrazionabile,
imp.siope_tipo_debito_code, imp.siope_tipo_debito_desc, imp.siope_tipo_debito_desc_bnkit,
imp.siope_assenza_motivazione_code, imp.siope_assenza_motivazione_desc, imp.siope_assenza_motivazione_desc_bnkit,
coalesce(impFlagAttivaGsa.flag_attiva_gsa,'N') flag_attiva_gsa -- 28.05.2018 Sofia siac-6102
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
left join impFlagAttivaGsa  -- 28.05.2018 Sofia siac-6102
on
imp.movgest_ts_id=impFlagAttivaGsa.movgest_ts_id
) xx
where xx.movgest_ts_tipo_code='S';

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

esito:='ok';

EXCEPTION
WHEN others THEN
  esito:='Funzione carico impegni (FNC_SIAC_DWH_IMPEGNO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;


CREATE OR REPLACE FUNCTION fnc_siac_dwh_accertamento (
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
--and tm.movgest_anno::integer=2018
--and tm.movgest_numero::integer<1000
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


CREATE TABLE if not exists siac_dwh_programma_cronop
(
ente_proprietario_id    INTEGER,
ente_denominazione      VARCHAR(500),
data_elaborazione       TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
programma_code          VARCHAR(200),
programma_desc          VARCHAR(500),
programma_stato_code    VARCHAR(200),
programma_stato_desc    VARCHAR(500),
programma_ambito_code   VARCHAR(200),
programma_ambito_desc   VARCHAR(500),
programma_rilevante_fpv VARCHAR(1),
programma_valore_complessivo   numeric,
programma_gara_data_indizione  TIMESTAMP WITHOUT TIME ZONE,
programma_gara_data_aggiudic           TIMESTAMP WITHOUT TIME ZONE,
programma_investimento_in_def            BOOLEAN,
programma_note                           VARCHAR(500),
programma_anno_atto_amm                  VARCHAR(4),
programma_num_atto_amm                   VARCHAR(500),
programma_oggetto_atto_amm               VARCHAR(500),
programma_note_atto_amm                  VARCHAR(500),
programma_code_tipo_atto_amm             VARCHAR(200),
programma_desc_tipo_atto_amm             VARCHAR(500),
programma_code_stato_atto_amm            VARCHAR(200),
programma_desc_stato_atto_amm            VARCHAR(500),
programma_code_cdr_atto_amm              VARCHAR(200),
programma_desc_cdr_atto_amm              VARCHAR(500),
programma_code_cdc_atto_amm              VARCHAR(200),
programma_desc_cdc_atto_amm              VARCHAR(500),
programma_cronop_bil_anno                varchar(4),
programma_cronop_tipo                    VARCHAR(1),
programma_cronop_versione                varchar(200),
programma_cronop_desc                    varchar(500),
programma_cronop_anno_comp               varchar(4),
programma_cronop_cap_tipo                VARCHAR(200),
programma_cronop_cap_articolo            VARCHAR(200),
programma_cronop_classif_bil             VARCHAR(200),
programma_cronop_anno_entrata            varchar(4),
programma_cronop_valore_prev             numeric
)
WITH (oids = false);



COMMENT ON TABLE siac_dwh_programma_cronop
IS 'Scarico programmi-cronoprammi validi';


COMMENT ON COLUMN siac_dwh_programma_cronop.programma_code
IS 'Codice programma (siac_t_programma.programma_code)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_desc
IS 'Descrizione programma (siac_t_programma.programma_desc)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_stato_code
IS 'Codice stato programma (siac_d_programma_stato.programma_stato_code)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_stato_desc
IS 'Descrizione stato programma (siac_d_programma_stato.programma_stato_desc)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_ambito_code
IS 'Codice ambito programma (siac_t_class.classif_code [TIPO_AMBITO] siac_r_programma_class)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_ambito_desc
IS 'Descrizione ambito programma (siac_t_class.classif_desc [TIPO_AMBITO] siac_r_programma_class)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_rilevante_fpv
IS 'Rilevanza FPV  (siac_r_programma_attr.boolean, siac_t_attr [FlagRilevanteFPV])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_valore_complessivo
IS 'Importo complessivo programma (siac_r_programma_attr.numerico, siac_t_attr [ValoreComplessivoProgramma])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_gara_data_indizione
IS 'Data indizione gara  programma (siac_t_programma.programma_data_gara_indizione)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_gara_data_aggiudic
IS 'Data aggiudicazione gara  programma (siac_t_programma.programma_data_gara_aggiudicazione)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_investimento_in_def
IS 'Investimento in definizione per  programma (siac_t_programma.programma_investimento_in_def)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_note
IS 'Note  programma (siac_r_programma_attr.testo, siac_t_attr [Note])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_anno_atto_amm
IS 'Anno Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_anno)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_num_atto_amm
IS 'Numero Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_numero)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_oggetto_atto_amm
IS 'Oggetto Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_oggetto)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_note_atto_amm
IS 'Note Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_note)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_code_tipo_atto_amm
IS 'Codice tipo Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_tipo_id, siac_d_attoamm_tipo)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_desc_tipo_atto_amm
IS 'Descrizione tipo Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_tipo_id, siac_d_attoamm_tipo)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_code_stato_atto_amm
IS 'Codice stato Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm , siac_d_atto_amm_stato)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_desc_stato_atto_amm
IS 'Descrizione stato Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm , siac_d_atto_amm_stato)';


COMMENT ON COLUMN siac_dwh_programma_cronop.programma_code_cdr_atto_amm
IS 'Codice CDR Atto amministrativo programma (siac_r_programma_atto_amm, siac_r_atto_amm_class , siac_t_class [CDR])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_desc_cdr_atto_amm
IS 'Descrizione CDR Atto amministrativo programma (siac_r_programma_atto_amm, siac_r_atto_amm_class , siac_t_class [CDR])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_code_cdr_atto_amm
IS 'Codice CDC Atto amministrativo programma (siac_r_programma_atto_amm, siac_r_atto_amm_class , siac_t_class [CDC])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_desc_cdr_atto_amm
IS 'Descrizione CDC Atto amministrativo programma (siac_r_programma_atto_amm, siac_r_atto_amm_class , siac_t_class [CDC])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_tipo
IS 'Cronoprogramma tipo  (Uscita [CAP-UP,CAP-UG], Entrata [CAP-EP,CAP-EG])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_cap_tipo
IS 'Cronoprogramma tipo capitolo associato (siac_t_cronop_elem.elem_tipo_id [CAP-UP,CAP-UG,CAP-EP,CAP-EG])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_versione
IS 'Cronoprogramma versione (siac_t_cronop.cronop_code)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_desc
IS 'Cronoprogramma descrizione (siac_t_cronop.cronop_desc)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_bil_anno
IS 'Cronoprogramma anno di bilancio (siac_t_cronop.bil_id [siac_t_periodo.anno])';


COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_anno_comp
IS 'Cronoprogramma anno di competenza (siac_t_cronop_elem_det.periodo_id [siac_t_periodo.anno])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_cap_articolo
IS 'Cronoprogramma capitolo-articolo (siac_t_cronop_elem.cronop_elem_code/siac_t_cronop_elem.cronop_elem_code)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_classif_bil
IS 'Cronoprogramma classificazione bilancio capitolo-articolo ( titolo_code-tipologia_code,  siac_r_cronop_elem_class,siac_t_cronop_elem , siac_t_class [TIPOLOGIA])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_anno_entrata
IS 'Cronoprogramma spesa, anno rif. entrata ( siac_t_cronop_elem_det.anno_entrata [CAP-UP,CAP-UG] )';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_valore_prev
IS 'Cronoprogramma valore di riferimento ( siac_t_cronop_elem_det.cronop_elem_det_importo )';


drop function if exists fnc_siac_dwh_programma_cronop
(
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION fnc_siac_dwh_programma_cronop
(
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE


v_user_table varchar;
params varchar;
fnc_eseguita integer;
interval_esec integer:=1;

BEGIN

esito:='fnc_siac_dwh_programma_cronop : inizio - '||clock_timestamp()||'.';
return next;

IF p_ente_proprietario_id IS NULL THEN
	   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo.';
END IF;

IF p_anno_bilancio IS NULL THEN
	   RAISE EXCEPTION 'Errore: Parametro Anno Bilancio nullo.';
END IF;


select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni log
where log.ente_proprietario_id=p_ente_proprietario_id
and	  log.fnc_elaborazione_inizio >= (now() - interval '1 hours' )::timestamp -- non deve esistere  una elaborazione uguale nelle 1 ore che precedono la chimata
and   log.fnc_name='fnc_siac_dwh_programma_cronop';

if fnc_eseguita<= 0 then
	esito:= 'fnc_siac_dwh_programma_cronop : continue - eseguita da piu'' di '|| interval_esec::varchar||' ore - '||clock_timestamp()||'.';
	return next;


	IF p_data IS NULL THEN
	   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
    	  p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
	   ELSE
    	  p_data := now();
	   END IF;
	END IF;


	select fnc_siac_random_user() into	v_user_table;

	params := p_ente_proprietario_id::varchar||' - '||p_anno_bilancio||' - '||p_data::varchar;


	insert into	siac_dwh_log_elaborazioni
    (
		ente_proprietario_id,
		fnc_name ,
		fnc_parameters ,
		fnc_elaborazione_inizio ,
		fnc_user
	)
	values
    (
		p_ente_proprietario_id,
		'fnc_siac_dwh_programma_cronop',
		params,
		clock_timestamp(),
		v_user_table
	);


	esito:= 'fnc_siac_dwh_programma_cronop : continue - inizio eliminazione dati pregressi (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	return next;
	DELETE FROM siac_dwh_programma_cronop
    WHERE ente_proprietario_id = p_ente_proprietario_id
    and   programma_cronop_bil_anno=p_anno_bilancio;
	esito:= 'fnc_siac_dwh_programma_cronop : continue - fine eliminazione dati pregressi (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	return next;

	esito:= 'fnc_siac_dwh_programma_cronop : continue - inizio caricamento programmi-cronop (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	RETURN NEXT;

    insert into siac_dwh_programma_cronop
    (
      ente_proprietario_id,
      ente_denominazione,
      programma_code,
      programma_desc,
      programma_stato_code,
      programma_stato_desc,
      programma_ambito_code,
      programma_ambito_desc,
      programma_rilevante_fpv,
      programma_valore_complessivo,
      programma_gara_data_indizione,
      programma_gara_data_aggiudic,
      programma_investimento_in_def,
      programma_note,
      programma_anno_atto_amm,
      programma_num_atto_amm,
      programma_oggetto_atto_amm,
      programma_note_atto_amm,
      programma_code_tipo_atto_amm,
      programma_desc_tipo_atto_amm,
      programma_code_stato_atto_amm,
      programma_desc_stato_atto_amm,
      programma_code_cdr_atto_amm,
      programma_desc_cdr_atto_amm,
      programma_code_cdc_atto_amm,
      programma_desc_cdc_atto_amm,
      programma_cronop_bil_anno,
      programma_cronop_tipo,
      programma_cronop_versione,
      programma_cronop_desc,
      programma_cronop_anno_comp,
      programma_cronop_cap_tipo,
      programma_cronop_cap_articolo,
      programma_cronop_classif_bil,
      programma_cronop_anno_entrata,
      programma_cronop_valore_prev
    )
    select
      ente.ente_proprietario_id,
      ente.ente_denominazione,
      query.programma_code,
      query.programma_desc,
      query.programma_stato_code,
      query.programma_stato_desc,
      query.programma_ambito_code,
      query.programma_ambito_desc,
      query.programma_rilevante_fpv,
      query.programma_valore_complessivo,
      query.programma_gara_data_indizione,
      query.programma_gara_data_aggiudic,
      query.programma_investimento_in_def,
      query.programma_note,
      query.programma_anno_atto_amm,
      query.programma_num_atto_amm,
      query.programma_oggetto_atto_amm,
      query.programma_note_atto_amm,
      query.programma_code_tipo_atto_amm,
      query.programma_desc_tipo_atto_amm,
      query.programma_code_stato_atto_amm,
      query.programma_desc_stato_atto_amm,
      query.programma_code_cdr_atto_amm,
      query.programma_desc_cdr_atto_amm,
      query.programma_code_cdc_atto_amm,
      query.programma_desc_cdc_atto_amm,
      query.programma_cronop_bil_anno,
      query.programma_cronop_tipo,
      query.programma_cronop_versione,
      query.programma_cronop_desc,
      query.programma_cronop_anno_comp,
      query.programma_cronop_cap_tipo,
      query.programma_cronop_cap_articolo,
      query.programma_cronop_classif_bil,
      query.programma_cronop_anno_entrata,
      query.programma_cronop_valore_prev
    from
    (
    with
    programma as
    (
      select progr.ente_proprietario_id,
             progr.programma_id,
             progr.programma_code,
             progr.programma_desc,
             stato.programma_stato_code,
             stato.programma_stato_desc,
             progr.programma_data_gara_indizione programma_gara_data_indizione,
		     progr.programma_data_gara_aggiudicazione programma_gara_data_aggiudic,
		     progr.investimento_in_definizione programma_investimento_in_def
      from siac_t_programma progr, siac_r_programma_stato rs, siac_d_programma_stato stato
      where stato.ente_proprietario_id=p_ente_proprietario_id
      and   rs.programma_stato_id=stato.programma_stato_id
      and   progr.programma_id=rs.programma_id
      and   p_data BETWEEN progr.validita_inizio AND COALESCE(progr.validita_fine, p_data)
      and   progr.data_cancellazione is null
      AND   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
      and   rs.data_cancellazione  is null
    ),
    progr_ambito_class as
    (
    select rc.programma_id,
           c.classif_code programma_ambito_code,
           c.classif_desc  programma_ambito_desc
    from siac_r_programma_class rc, siac_t_class c, siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=p_ente_proprietario_id
    and   tipo.classif_tipo_code='TIPO_AMBITO'
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
    and   rc.data_cancellazione is null
    and   c.data_cancellazione is null
    ),
    progr_note_attr_ril_fpv as
    (
    select rattr.programma_id,
           rattr.boolean programma_rilevante_fpv
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='FlagRilevanteFPV'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_note_attr_note as
    (
    select rattr.programma_id,
           rattr.boolean programma_note
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='Note'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_note_attr_val_compl as
    (
    select rattr.programma_id,
           rattr.numerico programma_valore_complessivo
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='ValoreComplessivoProgramma'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_atto_amm as
    (
     with
     progr_atto as
     (
      select ratto.programma_id,
             ratto.attoamm_id,
             atto.attoamm_anno        programma_anno_atto_amm,
             atto.attoamm_numero      programma_num_atto_amm,
             atto.attoamm_oggetto     programma_oggetto_atto_amm,
             atto.attoamm_note        programma_note_atto_amm,
             tipo.attoamm_tipo_code   programma_code_tipo_atto_amm,
             tipo.attoamm_tipo_desc   programma_desc_tipo_atto_amm,
             stato.attoamm_stato_code programma_code_stato_atto_amm,
             stato.attoamm_stato_desc programma_desc_stato_atto_amm
      from siac_r_programma_atto_amm ratto , siac_t_atto_amm atto,siac_d_atto_amm_tipo tipo,
           siac_r_atto_amm_stato rs, siac_d_atto_amm_stato stato
      where ratto.ente_proprietario_id=p_ente_proprietario_id
      and   atto.attoamm_id=ratto.attoamm_id
      and   tipo.attoamm_tipo_id=atto.attoamm_tipo_id
      and   rs.attoamm_id=atto.attoamm_id
      and   stato.attoamm_stato_id=rs.attoamm_stato_id
      and   p_data BETWEEN ratto.validita_inizio AND COALESCE(ratto.validita_fine, p_data)
      and   ratto.data_cancellazione is null
      and   p_data BETWEEN atto.validita_inizio AND COALESCE(atto.validita_fine, p_data)
      and   atto.data_cancellazione is null
      and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
      and   rs.data_cancellazione is null
     ),
     atto_cdr as
     (
     select rc.attoamm_id,
            c.classif_code programma_code_cdr_atto_amm,
            c.classif_desc programma_desc_cdr_atto_amm
     from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=p_ente_proprietario_id
     and   tipo.classif_tipo_code='CDR'
     and   c.classif_tipo_id=tipo.classif_tipo_id
     and   rc.classif_id=c.classif_id
     and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
     and   rc.data_cancellazione is null
     and   c.data_cancellazione is null
     ),
     atto_cdc as
     (
     select rc.attoamm_id,
            c.classif_code programma_code_cdc_atto_amm,
            c.classif_desc programma_desc_cdc_atto_amm
     from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=p_ente_proprietario_id
     and   tipo.classif_tipo_code='CDC'
     and   c.classif_tipo_id=tipo.classif_tipo_id
     and   rc.classif_id=c.classif_id
     and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
     and   rc.data_cancellazione is null
     and   c.data_cancellazione is null
     )
     select progr_atto.*,
            atto_cdr.programma_code_cdr_atto_amm,
            atto_cdr.programma_desc_cdr_atto_amm,
            atto_cdc.programma_code_cdc_atto_amm,
            atto_cdc.programma_desc_cdc_atto_amm
     from progr_atto
           left join atto_cdr on (progr_atto.attoamm_id=atto_cdr.attoamm_id)
           left join atto_cdc on (progr_atto.attoamm_id=atto_cdc.attoamm_id)
    ),
    cronop_progr as
    (
    with
     cronop_entrata as
     (
       with
         ce as
         (
           select cronop.programma_id,
                  per_bil.anno::varchar programma_cronop_bil_anno,
                  'E'::varchar programma_cronop_tipo,
                  cronop.cronop_code programma_cronop_versione,
                  cronop.cronop_desc programma_cronop_desc,
                  per.anno::varchar  programma_cronop_anno_comp,
                  tipo.elem_tipo_code programma_cronop_cap_tipo,
                  cronop_elem.cronop_elem_code||'/'||cronop_elem.cronop_elem_code2 programma_cronop_cap_articolo,
                  ''::varchar programma_cronop_anno_entrata,
                  cronop_elem_det.cronop_elem_det_importo programma_cronop_valore_prev,
                  cronop_elem.cronop_elem_id
           from siac_t_cronop cronop,siac_r_cronop_stato rs, siac_d_cronop_stato stato,
                siac_t_bil bil, siac_t_periodo per_bil,
                siac_t_periodo per,
                siac_t_cronop_elem cronop_elem,
                siac_d_bil_elem_tipo tipo,
                siac_t_cronop_elem_det cronop_elem_det
           where stato.ente_proprietario_id=p_ente_proprietario_id
           and   stato.cronop_stato_code='VA'
           and   rs.cronop_stato_id=stato.cronop_stato_id
           and   cronop.cronop_id=rs.cronop_id
           and   bil.bil_id=cronop.bil_id
           and   per_bil.periodo_id=bil.periodo_id
           and   per_bil.anno::integer=p_anno_bilancio::integer
           and   cronop_elem.cronop_id=cronop.cronop_id
           and   tipo.elem_tipo_id=cronop_elem.elem_tipo_id
           and   tipo.elem_tipo_code in ('CAP-EP','CAP-EG')
           and   cronop_elem_det.cronop_elem_id=cronop_elem.cronop_elem_id
           and   per.periodo_id=cronop_elem_det.periodo_id
           and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
           and   rs.data_cancellazione is null
           and   p_data BETWEEN cronop.validita_inizio AND COALESCE(cronop.validita_fine, p_data)
           and   cronop.data_cancellazione is null
           and   p_data BETWEEN cronop_elem.validita_inizio AND COALESCE(cronop_elem.validita_fine, p_data)
           and   cronop_elem.data_cancellazione is null
           and   p_data BETWEEN cronop_elem_det.validita_inizio AND COALESCE(cronop_elem_det.validita_fine, p_data)
           and   cronop_elem_det.data_cancellazione is null
         ),
         classif_bil as
         (
            select distinct
                   r_cronp_class.cronop_elem_id,
		           titolo.classif_code            				titolo_code ,
	               titolo.classif_desc            				titolo_desc,
	               tipologia.classif_code           			tipologia_code,
	               tipologia.classif_desc           			tipologia_desc
            from siac_t_class_fam_tree 			titolo_tree,
            	 siac_d_class_fam 				titolo_fam,
	             siac_r_class_fam_tree 			titolo_r_cft,
	             siac_t_class 					titolo,
	             siac_d_class_tipo 				titolo_tipo,
	             siac_d_class_tipo 				tipologia_tipo,
     	         siac_t_class 					tipologia,
	             siac_r_cronop_elem_class		r_cronp_class
            where 	titolo_fam.classif_fam_desc					=	'Entrata - TitoliTipologieCategorie'
            and 	titolo_tree.classif_fam_id					=	titolo_fam.classif_fam_id
            and 	titolo_r_cft.classif_fam_tree_id			=	titolo_tree.classif_fam_tree_id
            and 	titolo.classif_id							=	titolo_r_cft.classif_id_padre
            and 	titolo_tipo.classif_tipo_code				=	'TITOLO_ENTRATA'
            and 	titolo.classif_tipo_id						=	titolo_tipo.classif_tipo_id
            and 	tipologia_tipo.classif_tipo_code			=	'TIPOLOGIA'
            and 	tipologia.classif_tipo_id					=	tipologia_tipo.classif_tipo_id
            and 	titolo_r_cft.classif_id						=	tipologia.classif_id
            and 	r_cronp_class.classif_id					=	tipologia.classif_id
            and 	titolo.ente_proprietario_id					=	p_ente_proprietario_id
            and 	titolo.data_cancellazione					is null
            and 	tipologia.data_cancellazione				is null
            and		r_cronp_class.data_cancellazione			is null
            and 	titolo_tree.data_cancellazione				is null
            and 	titolo_fam.data_cancellazione				is null
            and 	titolo_r_cft.data_cancellazione				is null
            and 	titolo_tipo.data_cancellazione				is null
            and 	tipologia_tipo.data_cancellazione			is null
          )
          select ce.programma_id,
                 ce.programma_cronop_bil_anno,
                 ce.programma_cronop_tipo,
                 ce.programma_cronop_versione,
                 ce.programma_cronop_desc,
                 ce.programma_cronop_anno_comp,
                 ce.programma_cronop_cap_tipo,
                 ce.programma_cronop_cap_articolo,
                 (coalesce(classif_bil.titolo_code,' ') ||' - ' ||coalesce(classif_bil.tipologia_code,' '))::varchar programma_cronop_classif_bil,
                 ce.programma_cronop_anno_entrata,
                 ce.programma_cronop_valore_prev
          from ce left join classif_bil on (ce.cronop_elem_id=classif_bil.cronop_elem_id)
     ),
     cronop_uscita as
     (
     with
     ce as
     (
       select cronop.programma_id,
              per_bil.anno::varchar programma_cronop_bil_anno,
              'U'::varchar programma_cronop_tipo,
              cronop.cronop_code programma_cronop_versione,
              cronop.cronop_desc programma_cronop_desc,
              per.anno::varchar  programma_cronop_anno_comp,
              tipo.elem_tipo_code programma_cronop_cap_tipo,
              cronop_elem.cronop_elem_code||'/'||cronop_elem.cronop_elem_code2 programma_cronop_cap_articolo,
              cronop_elem_det.anno_entrata::varchar programma_cronop_anno_entrata,
              cronop_elem_det.cronop_elem_det_importo programma_cronop_valore_prev,
              cronop_elem.cronop_elem_id
       from siac_t_cronop cronop,siac_r_cronop_stato rs, siac_d_cronop_stato stato,
            siac_t_bil bil, siac_t_periodo per_bil,
            siac_t_periodo per,
            siac_t_cronop_elem cronop_elem,
            siac_d_bil_elem_tipo tipo,
            siac_t_cronop_elem_det cronop_elem_det
       where stato.ente_proprietario_id=p_ente_proprietario_id
       and   stato.cronop_stato_code='VA'
       and   rs.cronop_stato_id=stato.cronop_stato_id
       and   cronop.cronop_id=rs.cronop_id
       and   bil.bil_id=cronop.bil_id
       and   per_bil.periodo_id=bil.periodo_id
       and   per_bil.anno::integer=p_anno_bilancio::integer
       and   cronop_elem.cronop_id=cronop.cronop_id
       and   tipo.elem_tipo_id=cronop_elem.elem_tipo_id
       and   tipo.elem_tipo_code in ('CAP-UP','CAP-UG')
       and   cronop_elem_det.cronop_elem_id=cronop_elem.cronop_elem_id
       and   per.periodo_id=cronop_elem_det.periodo_id
       and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
       and   rs.data_cancellazione is null
       and   p_data BETWEEN cronop.validita_inizio AND COALESCE(cronop.validita_fine, p_data)
       and   cronop.data_cancellazione is null
       and   p_data BETWEEN cronop_elem.validita_inizio AND COALESCE(cronop_elem.validita_fine, p_data)
       and   cronop_elem.data_cancellazione is null
       and   p_data BETWEEN cronop_elem_det.validita_inizio AND COALESCE(cronop_elem_det.validita_fine, p_data)
       and   cronop_elem_det.data_cancellazione is null
     ),
     classif_bil as
     (
        select  distinct
        		r_cronp_class_titolo.cronop_elem_id,
		        missione.classif_code 					missione_code,
		        missione.classif_desc 					missione_desc,
		        programma.classif_code 					programma_code,
		        programma.classif_desc 					programma_desc,
		        titusc.classif_code 					titolo_code,
		        titusc.classif_desc 					titolo_desc
        from siac_t_class_fam_tree 			missione_tree,
             siac_d_class_fam 				missione_fam,
	         siac_r_class_fam_tree 			missione_r_cft,
	         siac_t_class 					missione,
	         siac_d_class_tipo 				missione_tipo ,
     	     siac_d_class_tipo 				programma_tipo,
	         siac_t_class 					programma,
      	     siac_t_class_fam_tree 			titusc_tree,
	         siac_d_class_fam 				titusc_fam,
	         siac_r_class_fam_tree 			titusc_r_cft,
	         siac_t_class 					titusc,
	         siac_d_class_tipo 				titusc_tipo,
	         siac_r_cronop_elem_class		r_cronp_class_programma,
	         siac_r_cronop_elem_class		r_cronp_class_titolo
        where missione_fam.classif_fam_desc						=	'Spesa - MissioniProgrammi'
        and	  missione_tree.classif_fam_id				=	missione_fam.classif_fam_id
        and	  missione_r_cft.classif_fam_tree_id			=	missione_tree.classif_fam_tree_id
        and	  missione.classif_id							=	missione_r_cft.classif_id_padre
        and	  missione_tipo.classif_tipo_code				=	'MISSIONE'
        and	  missione.classif_tipo_id					=	missione_tipo.classif_tipo_id
        and	  programma_tipo.classif_tipo_code			=	'PROGRAMMA'
        and	  programma.classif_tipo_id					=	programma_tipo.classif_tipo_id
        and	  missione_r_cft.classif_id					=	programma.classif_id
        and	  programma.classif_id						=	r_cronp_class_programma.classif_id
        and	  titusc_fam.classif_fam_desc					=	'Spesa - TitoliMacroaggregati'
        and	  titusc_tree.classif_fam_id					=	titusc_fam.classif_fam_id
        and	  titusc_r_cft.classif_fam_tree_id			=	titusc_tree.classif_fam_tree_id
        and	  titusc.classif_id							=	titusc_r_cft.classif_id_padre
        and	  titusc_tipo.classif_tipo_code				=	'TITOLO_SPESA'
        and	  titusc.classif_tipo_id						=	titusc_tipo.classif_tipo_id
        and	  titusc.classif_id							=	r_cronp_class_titolo.classif_id
        and   r_cronp_class_programma.cronop_elem_id		= 	r_cronp_class_titolo.cronop_elem_id
        and   missione_tree.ente_proprietario_id			=	p_ente_proprietario_id
        and   missione_tree.data_cancellazione			is null
        and   missione_fam.data_cancellazione			is null
        AND   missione_r_cft.data_cancellazione			is null
        and   missione.data_cancellazione				is null
        AND   missione_tipo.data_cancellazione			is null
        AND   programma_tipo.data_cancellazione			is null
        AND   programma.data_cancellazione				is null
        and   titusc_tree.data_cancellazione			is null
        AND   titusc_fam.data_cancellazione				is null
        and   titusc_r_cft.data_cancellazione			is null
        and   titusc.data_cancellazione					is null
        AND   titusc_tipo.data_cancellazione			is null
        and	  r_cronp_class_titolo.data_cancellazione	is null
     )
     select ce.programma_id,
            ce.programma_cronop_bil_anno,
            ce.programma_cronop_tipo,
            ce.programma_cronop_versione,
            ce.programma_cronop_desc,
            ce.programma_cronop_anno_comp,
            ce.programma_cronop_cap_tipo,
            ce.programma_cronop_cap_articolo,
            (coalesce(classif_bil.missione_code,' ')||
             ' - '||coalesce(classif_bil.programma_code,' ')||
             ' - '||coalesce(classif_bil.titolo_code,' '))::varchar programma_cronop_classif_bil,
            ce.programma_cronop_anno_entrata,
            ce.programma_cronop_valore_prev
     from ce left join classif_bil on (ce.cronop_elem_id=classif_bil.cronop_elem_id)
     )
     select cronop_entrata.programma_id,
     	    cronop_entrata.programma_cronop_bil_anno,
            cronop_entrata.programma_cronop_tipo,
            cronop_entrata.programma_cronop_versione,
            cronop_entrata.programma_cronop_desc,
	        cronop_entrata.programma_cronop_anno_comp,
            cronop_entrata.programma_cronop_cap_tipo,
	        cronop_entrata.programma_cronop_cap_articolo,
	        cronop_entrata.programma_cronop_classif_bil,
	        cronop_entrata.programma_cronop_anno_entrata,
            cronop_entrata.programma_cronop_valore_prev
     from cronop_entrata
     union
     select cronop_uscita.programma_id,
     	    cronop_uscita.programma_cronop_bil_anno,
            cronop_uscita.programma_cronop_tipo,
            cronop_uscita.programma_cronop_versione,
            cronop_uscita.programma_cronop_desc,
	        cronop_uscita.programma_cronop_anno_comp,
            cronop_uscita.programma_cronop_cap_tipo,
	        cronop_uscita.programma_cronop_cap_articolo,
	        cronop_uscita.programma_cronop_classif_bil,
	        cronop_uscita.programma_cronop_anno_entrata,
            cronop_uscita.programma_cronop_valore_prev

     from cronop_uscita
    )
    select programma.*,
           progr_ambito_class.programma_ambito_code,
           progr_ambito_class.programma_ambito_desc,
           progr_note_attr_ril_fpv.programma_rilevante_fpv,
           progr_note_attr_note.programma_note,
           progr_note_attr_val_compl.programma_valore_complessivo,
           progr_atto_amm.programma_anno_atto_amm,
           progr_atto_amm.programma_num_atto_amm,
           progr_atto_amm.programma_oggetto_atto_amm,
           progr_atto_amm.programma_note_atto_amm,
           progr_atto_amm.programma_code_tipo_atto_amm,
           progr_atto_amm.programma_desc_tipo_atto_amm,
           progr_atto_amm.programma_code_stato_atto_amm,
           progr_atto_amm.programma_desc_stato_atto_amm,
           progr_atto_amm.programma_code_cdr_atto_amm,
           progr_atto_amm.programma_desc_cdr_atto_amm,
           progr_atto_amm.programma_code_cdc_atto_amm,
           progr_atto_amm.programma_desc_cdc_atto_amm,
	       cronop_progr.programma_cronop_bil_anno,
           cronop_progr.programma_cronop_tipo,
           cronop_progr.programma_cronop_versione,
      	   cronop_progr.programma_cronop_desc,
	       cronop_progr.programma_cronop_anno_comp,
	       cronop_progr.programma_cronop_cap_tipo,
	       cronop_progr.programma_cronop_cap_articolo,
	       cronop_progr.programma_cronop_classif_bil,
		   cronop_progr.programma_cronop_anno_entrata,
	       cronop_progr.programma_cronop_valore_prev
    from cronop_progr,
         programma
          left join progr_ambito_class           on (programma.programma_id=progr_ambito_class.programma_id)
          left join progr_note_attr_ril_fpv      on (programma.programma_id=progr_note_attr_ril_fpv.programma_id)
          left join progr_note_attr_note         on (programma.programma_id=progr_note_attr_note.programma_id)
          left join progr_note_attr_val_compl    on (programma.programma_id=progr_note_attr_val_compl.programma_id)
          left join progr_atto_amm               on (programma.programma_id=progr_atto_amm.programma_id)
    where programma.programma_id=cronop_progr.programma_id
    ) query,siac_t_ente_proprietario ente
    where ente.ente_proprietario_id=p_ente_proprietario_id
    and   query.ente_proprietario_id=ente.ente_proprietario_id;


	esito:= 'fnc_siac_dwh_programma_cronop : continue - aggiornamento durata su  siac_dwh_log_elaborazioni - '||clock_timestamp()||'.';
	update siac_dwh_log_elaborazioni
    set    fnc_elaborazione_fine = clock_timestamp(),
	       fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
	where  fnc_user=v_user_table;
	return next;

    esito:= 'fnc_siac_dwh_programma_cronop : fine - esito OK  - '||clock_timestamp()||'.';
    return next;
else
	esito:= 'fnc_siac_dwh_programma_cronop : fine - eseguita da meno di '|| interval_esec::varchar||' ore - '||clock_timestamp()||'.';

	return next;

end if;

return;

EXCEPTION
 WHEN RAISE_EXCEPTION THEN
  esito:='fnc_siac_dwh_programma_cronop : fine con errori - '||clock_timestamp();
  esito:=esito||' - '||SQLSTATE||'-'||substring(upper(SQLERRM) from 1 for 2500)||'.';
  RAISE NOTICE '%',esito;
  RETURN next;
  return;
 WHEN others THEN
  esito:='fnc_siac_dwh_programma_cronop : fine con errori - '||clock_timestamp();
  esito:=esito||' - '||SQLSTATE||'-'||substring(upper(SQLERRM) from 1 for 2500)||'.';
  RAISE NOTICE '%',esito;
  RETURN next;
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;

-- SIAC-6336  Sofia - FINE


-- SIAC-6477 Sofia - Inizio
drop view if exists siac_v_dwh_ricevuta_ordinativo;

CREATE OR REPLACE VIEW siac_v_dwh_ricevuta_ordinativo
(
  ente_proprietario_id,
  bil_anno_ord,
  anno_ord,
  num_ord,
  cod_stato_ord,
  desc_stato_ord,
  cod_tipo_ord,
  desc_tipo_ord,
  data_ricevuta_ord,
  numero_ricevuta_ord,
  importo_ricevuta_ord,
  tipo_ricevuta_ord,
  validita_inizio,
  validita_fine
)
AS
SELECT
    tep.ente_proprietario_id, tp.anno AS bil_anno_ord,
    sto.ord_anno AS anno_ord, sto.ord_numero AS num_ord,
    dos.ord_stato_code AS cod_stato_ord,
    dos.ord_stato_desc AS desc_stato_ord,
    dot.ord_tipo_code AS cod_tipo_ord,
    dot.ord_tipo_desc AS desc_tipo_ord,
    roq.ord_quietanza_data AS data_ricevuta_ord,
    roq.ord_quietanza_numero AS numero_ricevuta_ord,
    roq.ord_quietanza_importo AS importo_ricevuta_ord,
    'Q'::text AS tipo_ricevuta_ord,
    ros.validita_inizio,
    ros.validita_fine
FROM siac_t_ordinativo sto
  JOIN siac_t_bil tb ON sto.bil_id = tb.bil_id
  JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
  JOIN siac_t_ente_proprietario tep ON tep.ente_proprietario_id = sto.ente_proprietario_id
  JOIN siac_d_ordinativo_tipo dot ON sto.ord_tipo_id = dot.ord_tipo_id
  JOIN siac_r_ordinativo_stato ros ON ros.ord_id = sto.ord_id
  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
  JOIN siac_r_ordinativo_quietanza roq ON roq.ord_id = sto.ord_id AND roq.data_cancellazione IS NULL
WHERE sto.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   tep.data_cancellazione IS NULL
AND   dot.data_cancellazione IS NULL
AND   ros.data_cancellazione IS NULL
AND   dos.data_cancellazione IS NULL
-- 26.10.2018 jira siac-6477
and   ros.validita_fine is  null
UNION ALL
SELECT
  tep.ente_proprietario_id, tp.anno AS bil_anno_ord,
  sto.ord_anno AS anno_ord, sto.ord_numero AS num_ord,
  dos.ord_stato_code AS cod_stato_ord,
  dos.ord_stato_desc AS desc_stato_ord,
  dot.ord_tipo_code AS cod_tipo_ord,
  dot.ord_tipo_desc AS desc_tipo_ord,
  os.ord_storno_data AS data_ricevuta_ord,
  os.ord_storno_numero AS numero_ricevuta_ord,
  os.ord_storno_importo AS importo_ricevuta_ord,
  'S'::text AS tipo_ricevuta_ord,
  ros.validita_inizio,
  ros.validita_fine
FROM siac_t_ordinativo sto
  JOIN siac_t_bil tb ON sto.bil_id = tb.bil_id
  JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
  JOIN siac_t_ente_proprietario tep ON tep.ente_proprietario_id =  sto.ente_proprietario_id
  JOIN siac_d_ordinativo_tipo dot ON sto.ord_tipo_id = dot.ord_tipo_id
  JOIN siac_r_ordinativo_stato ros ON ros.ord_id = sto.ord_id
  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
  JOIN siac_r_ordinativo_storno os ON os.ord_id = sto.ord_id AND  os.data_cancellazione IS NULL
WHERE sto.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   tep.data_cancellazione IS NULL
AND   dot.data_cancellazione IS NULL
AND   ros.data_cancellazione IS NULL
AND   dos.data_cancellazione IS NULL
-- 26.10.2018 jira siac-6477
and   ros.validita_fine is null;

-- SIAC-6477 Sofia - Fine

-- SIAC-6482 Sofia - Inizio

drop view if exists siac_v_dwh_registrazioni;

CREATE OR REPLACE VIEW siac_v_dwh_registrazioni
(
    ente_proprietario_id,
    anno_bilancio,
    cod_tipo_evento,
    desc_tipo_evento,
    cod_tipo_mov_finanziario,
    desc_tipo_mov_finanziario,
    cod_evento,
    desc_evento,
    data_creazione_registrazione,
    cod_stato_registrazione,
    desc_stato_registrazione,
    ambito,
    validita_inizio,
    validita_fine,
    cod_pdc_fin_orig,
    desc_pdc_fin_orig,
    cod_pdc_fin_agg,
    desc_pdc_fin_agg,
    anno_movimento_mod,
    numero_movimento_mod,
    cod_submovimento_mod,
    anno_movimento,
    numero_movimento,
    cod_submovimento,
    doc_id,
    anno_doc,
    num_doc,
    cod_tipo_doc,
    data_emissione_doc,
    num_subdoc,
    cod_sogg_doc,
    anno_ordinativo,
    numero_ordinativo,
    anno_liquidazione,
    numero_liquidazione,
    numero_ricecon,
    anno_rateo_risconto,
    numero_pn_rateo_risconto,
    anno_pn_rateo_risconto
)
AS
WITH
registrazioni AS
(
    SELECT
      reg.ente_proprietario_id,
      per.anno,
      tipo.evento_tipo_code,
      tipo.evento_tipo_desc,
      coll.collegamento_tipo_code,
      coll.collegamento_tipo_desc,
      evento.evento_code,
      evento.evento_desc,
      reg.data_creazione,
      stato.regmovfin_stato_code,
      stato.regmovfin_stato_desc,
      ambito.ambito_code,
      reg.validita_inizio,
      reg.validita_fine,
      reg.classif_id_iniziale, reg.classif_id_aggiornato,
      revento.campo_pk_id, revento.campo_pk_id_2,
      revento.regmovfin_id
    FROM  siac_t_reg_movfin reg, siac_r_reg_movfin_stato rs, siac_d_reg_movfin_stato stato,
          siac_r_evento_reg_movfin revento,
          siac_d_evento evento, siac_d_collegamento_tipo coll,
          siac_d_evento_tipo tipo,
          siac_t_bil bil, siac_t_periodo per, siac_d_ambito ambito
    WHERE reg.regmovfin_id = rs.regmovfin_id
    AND   stato.regmovfin_stato_id = rs.regmovfin_stato_id
    AND   revento.regmovfin_id = reg.regmovfin_id
    AND   evento.evento_id = revento.evento_id
    AND   coll.collegamento_tipo_id = evento.collegamento_tipo_id
    AND   tipo.evento_tipo_id = evento.evento_tipo_id
    AND   bil.bil_id = reg.bil_id
    AND   per.periodo_id = bil.periodo_id
    AND   ambito.ambito_id = reg.ambito_id
    AND   reg.data_cancellazione IS NULL
    AND   rs.data_cancellazione IS NULL
    AND   revento.data_cancellazione IS NULL
    AND   evento.data_cancellazione IS NULL
    AND   stato.data_cancellazione IS NULL
    AND   tipo.data_cancellazione IS NULL
    AND   coll.data_cancellazione IS NULL
    AND   bil.data_cancellazione IS NULL
    AND   per.data_cancellazione IS NULL
    AND   ambito.data_cancellazione IS NULL
),
collegamento_I_A AS
(
SELECT a.movgest_id, a.movgest_anno, a.movgest_numero,revento.regmovfin_id
FROM   siac_t_movgest a,siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE  coll.collegamento_tipo_code in ('A','I')
and    evento.collegamento_tipo_id=coll.collegamento_tipo_id
and    revento.evento_id=evento.evento_id
and    a.movgest_id=revento.regmovfin_id
and    a.data_cancellazione IS NULL
),
collegamento_OP_OI AS
(
  SELECT a.ord_id, a.ord_anno, a.ord_numero, revento.regmovfin_id
  FROM   siac_t_ordinativo a,siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
  WHERE  coll.collegamento_tipo_code in ('OP','OI')
  and    evento.collegamento_tipo_id=coll.collegamento_tipo_id
  and    revento.evento_id=evento.evento_id
  and    a.ord_id=revento.campo_pk_id
  and    a.data_cancellazione IS NULL
  and    revento.data_cancellazione is null
),
collegamento_SI_SA AS
(
SELECT a.movgest_ts_id, b.movgest_anno, b.movgest_numero, a.movgest_ts_code,  revento.regmovfin_id
FROM  siac_t_movgest_ts a, siac_t_movgest b, siac_d_movgest_ts_tipo tipo,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE tipo.movgest_ts_tipo_code='S'
and   a.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
and   b.movgest_id = a.movgest_id
and   revento.campo_pk_id=a.movgest_ts_id
and   evento.evento_id=revento.evento_id
and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
and   coll.collegamento_tipo_code in ('SI','SA')
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
and   revento.data_cancellazione is null
),
collegamento_L AS
(
SELECT a.liq_id, a.liq_anno, a.liq_numero, revento.regmovfin_id
FROM   siac_t_liquidazione a,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE  coll.collegamento_tipo_code='L'
and    evento.collegamento_tipo_id=coll.collegamento_tipo_id
and    revento.evento_id=evento.evento_id
and    a.liq_id=revento.campo_pk_id
and    a.data_cancellazione IS NULL
and    revento.data_cancellazione is null
),
collegamento_MMGS_MMGE_a AS
(
SELECT DISTINCT tm.mod_id, tmov.movgest_anno, tmov.movgest_numero, tmt.movgest_ts_code,revento.regmovfin_id
FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
	  siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt, siac_t_movgest tmov,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE tm.mod_id = rms.mod_id
AND   rms.mod_stato_id = dms.mod_stato_id
AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
AND   tmov.movgest_id = tmt.movgest_id
AND   dms.mod_stato_code = 'V'
and   revento.campo_pk_id=tm.mod_id
and   evento.evento_id=revento.evento_id
and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
and   coll.collegamento_tipo_code in ('MMGS','MMGE')
AND   tm.data_cancellazione IS NULL
AND   rms.data_cancellazione IS NULL
AND   dms.data_cancellazione IS NULL
AND   tmtdm.data_cancellazione IS NULL
AND   tmt.data_cancellazione IS NULL
AND   tmov.data_cancellazione IS NULL
and    revento.data_cancellazione is null
),
collegamento_MMGS_MMGE_b AS
(
SELECT DISTINCT tm.mod_id, tmov.movgest_anno, tmov.movgest_numero, tmt.movgest_ts_code,revento.regmovfin_id
FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
      siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt, siac_t_movgest tmov,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE tm.mod_id = rms.mod_id
AND   rms.mod_stato_id = dms.mod_stato_id
AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
AND   tmov.movgest_id = tmt.movgest_id
AND   dms.mod_stato_code = 'V'
and   revento.campo_pk_id=tm.mod_id
and   evento.evento_id=revento.evento_id
and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
and   coll.collegamento_tipo_code in ('MMGS','MMGE')
AND   tm.data_cancellazione IS NULL
AND   rms.data_cancellazione IS NULL
AND   dms.data_cancellazione IS NULL
AND   rmtsm.data_cancellazione IS NULL
AND   tmt.data_cancellazione IS NULL
AND   tmov.data_cancellazione IS NULL
and   revento.data_cancellazione is null
),
collegamento_SS_SE AS
(

SELECT a.subdoc_id, b.doc_id, b.doc_anno, b.doc_numero, b.doc_data_emissione, a.subdoc_numero,
       c.doc_tipo_code, sog.soggetto_code,
       revento.regmovfin_id
FROM   siac_t_subdoc a, siac_t_doc b, siac_d_doc_tipo c ,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_r_doc_sog rsog, siac_t_soggetto sog
WHERE  a.doc_id = b.doc_id
AND    c.doc_tipo_id = b.doc_tipo_id
and    revento.campo_pk_id=a.subdoc_id
and    evento.evento_id=revento.evento_id
and    coll.collegamento_tipo_id=evento.collegamento_tipo_id
and    coll.collegamento_tipo_code in ('SS','SE')
and    rsog.doc_id=b.doc_id
and    sog.soggetto_id=rsog.soggetto_id
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL
and    revento.data_cancellazione is null
and    rsog.validita_fine is null
and    rsog.data_cancellazione is null
and    revento.data_cancellazione is null
),
collegamento_RT_RS AS
(
with
collegamento_RT as
(
SELECT revento.regmovfin_id,
       coll.collegamento_tipo_code,
	   pnrts.anno as anno_rateo_risconto,
       pn.pnota_progressivogiornale as numero_pn_rateo_risconto,
	   per.anno as anno_pn_rateo_risconto
FROM  siac_t_prima_nota pn,  siac_t_prima_nota_ratei_risconti pnrts, siac_t_bil bil, siac_t_periodo per,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE coll.collegamento_tipo_code='RT'
and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
and   revento.evento_id=evento.evento_id
and   pnrts.pnotarr_id=revento.campo_pk_id
and   pn.pnota_id=pnrts.pnota_id
and   bil.bil_id=pn.bil_id
and   per.periodo_id=bil.periodo_id
AND   pn.data_cancellazione IS NULL
AND   pnrts.data_cancellazione IS NULL
and   revento.data_cancellazione is null
),
collegamento_RS as
(
SELECT revento.regmovfin_id,
       coll.collegamento_tipo_code,
	   pnrts.anno as anno_rateo_risconto,
       pn.pnota_progressivogiornale as numero_pn_rateo_risconto,
	   per.anno as anno_pn_rateo_risconto
FROM  siac_t_prima_nota pn,  siac_t_prima_nota_ratei_risconti pnrts, siac_t_bil bil, siac_t_periodo per,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE coll.collegamento_tipo_code='RS'
and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
and   revento.evento_id=evento.evento_id
and   pnrts.pnotarr_id=revento.campo_pk_id
and   pn.pnota_id=pnrts.pnota_id
and   bil.bil_id=pn.bil_id
and   per.periodo_id=bil.periodo_id
AND   pn.data_cancellazione IS NULL
AND   pnrts.data_cancellazione IS NULL
and   revento.data_cancellazione is null
)
SELECT collegamento_RT.regmovfin_id,
       collegamento_RT.collegamento_tipo_code,
	   collegamento_RT.anno_rateo_risconto,
       collegamento_RT.numero_pn_rateo_risconto,
	   collegamento_RT.anno_pn_rateo_risconto
FROM  collegamento_RT
union
SELECT collegamento_RS.regmovfin_id,
       collegamento_RS.collegamento_tipo_code,
	   collegamento_RS.anno_rateo_risconto,
       collegamento_RS.numero_pn_rateo_risconto,
	   collegamento_RS.anno_pn_rateo_risconto
FROM  collegamento_RS
),
collegamento_RR_RE as
(
with
collegamento_RR AS
(
SELECT revento.regmovfin_id,
       coll.collegamento_tipo_code,
       ric_econ.ricecon_numero
FROM  siac_t_giustificativo giust, siac_t_richiesta_econ ric_econ,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE giust.ricecon_id = ric_econ.ricecon_id
and   revento.campo_pk_id=giust.gst_id
and   evento.evento_id=revento.evento_id
and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
and   coll.collegamento_tipo_code='RR'
AND   giust.data_cancellazione  IS NULL
AND   ric_econ.data_cancellazione  IS NULL
and   revento.data_cancellazione is null
),
collegamento_RE AS
(
SELECT revento.regmovfin_id,
       coll.collegamento_tipo_code,
       a.ricecon_numero
FROM  siac_t_richiesta_econ a,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE coll.collegamento_tipo_code='RE'
and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
and   revento.evento_id=evento.evento_id
and   a.ricecon_id=revento.campo_pk_id
and   a.data_cancellazione  IS NULL
and   revento.data_cancellazione is null
)
select collegamento_RR.regmovfin_id,
       collegamento_RR.collegamento_tipo_code,
       collegamento_RR.ricecon_numero
from collegamento_RR
union
select collegamento_RE.regmovfin_id,
       collegamento_RE.collegamento_tipo_code,
       collegamento_RE.ricecon_numero
from collegamento_RE
),
pdcFin as
(
select c.classif_id, c.classif_code,c.classif_desc
from siac_d_class_tipo tipo,siac_t_class c
where tipo.classif_tipo_code='PDC_V'
and   c.classif_tipo_id=tipo.classif_tipo_id
and   c.data_cancellazione is null
)
select
    registrazioni.ente_proprietario_id,
    registrazioni.anno as anno_bilancio,
    registrazioni.evento_tipo_code as cod_tipo_evento,
    registrazioni.evento_tipo_desc as desc_tipo_evento,
    registrazioni.collegamento_tipo_code as cod_tipo_mov_finanziario,
    registrazioni.collegamento_tipo_desc as desc_tipo_mov_finanziario,
    registrazioni.evento_code as cod_evento,
    registrazioni.evento_desc as desc_evento,
    registrazioni.data_creazione as data_creazione_registrazione,
    registrazioni.regmovfin_stato_code as cod_stato_registrazione,
    registrazioni.regmovfin_stato_desc as desc_stato_registrazione,
    registrazioni.ambito_code as ambito,
    registrazioni.validita_inizio,
    registrazioni.validita_fine,
    pdcFinOrig.classif_code as cod_pdc_fin_orig,
    pdcFinOrig.classif_desc as desc_pdc_fin_orig,
    pdcFinAgg.classif_code as cod_pdc_fin_agg,
    pdcFinAgg.classif_desc as desc_pdc_fin_agg,
    COALESCE(collegamento_MMGS_MMGE_a.movgest_anno,collegamento_MMGS_MMGE_b.movgest_anno) as anno_movimento_mod,
    COALESCE(collegamento_MMGS_MMGE_a.movgest_numero,collegamento_MMGS_MMGE_b.movgest_numero) as numero_movimento_mod,
    COALESCE(collegamento_MMGS_MMGE_a.movgest_ts_code,collegamento_MMGS_MMGE_b.movgest_ts_code) as cod_submovimento_mod,
    COALESCE(collegamento_I_A.movgest_anno,collegamento_SI_SA.movgest_anno) as anno_movimento,
    COALESCE(collegamento_I_A.movgest_numero,collegamento_SI_SA.movgest_numero) as numero_movimento,
    collegamento_SI_SA.movgest_ts_code as cod_submovimento,
    collegamento_SS_SE.doc_id,
    collegamento_SS_SE.doc_anno as anno_doc,
    collegamento_SS_SE.doc_numero as num_doc,
    collegamento_SS_SE.doc_tipo_code as cod_tipo_doc,
    collegamento_SS_SE.doc_data_emissione as data_emissione_doc,
    collegamento_SS_SE.subdoc_numero as num_subdoc,
    collegamento_SS_SE.soggetto_code as cod_sogg_doc,
    collegamento_OP_OI.ord_anno as anno_ordinativo,
    collegamento_OP_OI.ord_numero as numero_ordinativo,
    collegamento_L.liq_anno as anno_liquidazione,
    collegamento_L.liq_numero as numero_liquidazione,
    collegamento_RR_RE.ricecon_numero as numero_ricecon,
    collegamento_RT_RS.anno_rateo_risconto,
    collegamento_RT_RS.numero_pn_rateo_risconto,
    collegamento_RT_RS.anno_pn_rateo_risconto
FROM registrazioni
	  left join  collegamento_OP_OI on
        (collegamento_OP_OI.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_I_A on
        (collegamento_I_A.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_SI_SA on
        (collegamento_SI_SA.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_L on
        (collegamento_L.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_MMGS_MMGE_a on
        (collegamento_MMGS_MMGE_a.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_MMGS_MMGE_b on
        (collegamento_MMGS_MMGE_b.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_SS_SE on
        (collegamento_SS_SE.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_RT_RS on
        (collegamento_RT_RS.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_RR_RE on
         (collegamento_RR_RE.regmovfin_id = registrazioni.regmovfin_id)
      left join pdcFin pdcFinOrig on (pdcFinOrig.classif_id=registrazioni.classif_id_iniziale)
      left join pdcFin pdcFinAgg on (pdcFinAgg.classif_id=registrazioni.classif_id_aggiornato);

-- SIAC-6483 Sofia - Fine

-- siac-6488 Sofia - Inizio

drop FUNCTION if exists siac.fnc_siac_dwh_ordinativo_pagamento 
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

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

v_user_table varchar;
params varchar;


BEGIN


select fnc_siac_random_user()
into	v_user_table;


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
'fnc_siac_dwh_ordinativo_pagamento',
params,
clock_timestamp(),
v_user_table
);


esito:= 'Inizio funzione carico ordinativi in pagamento (fnc_siac_dwh_ordinativo_pagamento) - '||clock_timestamp();
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
  desc_siope,
  soggetto_csc_id, -- SIAC-5228
  cod_siope_tipo_debito,
  desc_siope_tipo_debito,
  desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione,
  desc_siope_assenza_motivazione,
  desc_siope_assenza_motiv_bnkit,
  ord_da_trasmettere -- 20.06.2018 Sofia siac-6175
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
--tb.tipo_cessione, tb.cod_cessione, tb.desc_cessione, -- 04.07.2017 Sofia SIAC-5036
COALESCE(tb.tipo_cessione, tb.oil_relaz_tipo_code) tipo_cessione, -- SIAC-5228
COALESCE(tb.cod_cessione, tb.relaz_tipo_code) cod_cessione, -- SIAC-5228
COALESCE(tb.desc_cessione, tb.relaz_tipo_desc) desc_cessione, -- SIAC-5228
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
tb.descr_siope,
tb.soggetto_id_da soggetto_csc_id, -- SIAC-5228
tb.siope_tipo_debito_code, tb.siope_tipo_debito_desc, tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code, tb.siope_assenza_motivazione_desc, tb.siope_assenza_motivazione_desc_bnkit,
tb.ord_da_trasmettere -- 20.06.2018 Sofia siac-6175
from (
with ordinativipag as (
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
a.ord_trasm_oil_data,
l.siope_tipo_debito_code, l.siope_tipo_debito_desc, l.siope_tipo_debito_desc_bnkit,
m.siope_assenza_motivazione_code, m.siope_assenza_motivazione_desc, m.siope_assenza_motivazione_desc_bnkit,
a.ord_da_trasmettere  -- 20.06.2018 Sofia siac-6175
FROM siac_t_ordinativo a
left join siac_d_siope_tipo_debito l on l.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and l.data_cancellazione is null
                                     and l.validita_fine is null
left join siac_d_siope_assenza_motivazione m on m.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and m.data_cancellazione is null
                                             and m.validita_fine is null
,siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i
where  d.ente_proprietario_id = p_ente_proprietario_id--p_ente_proprietario_id
and
c.anno = p_anno_bilancio
AND e.ord_tipo_code = 'P'
--and  a.ord_numero<1500
and a.bil_id = b.bil_id and
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
select mod.*,acc.v_codice_tipo_accredito, acc.v_descrizione_tipo_accredito
 from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as
(
  -- 30.10.2018 Sofia Jira siac-6488 - gestione sedi secondarie
  SELECT c.ord_id,d.soggetto_id,
         d.soggetto_code, da.soggetto_desc||' - '|| d.soggetto_desc soggetto_desc, da.codice_fiscale, da.codice_fiscale_estero, da.partita_iva
  FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d,
	   siac_t_soggetto da
  WHERE  a.ente_proprietario_id=p_ente_proprietario_id
  and    a.relaz_tipo_id = b.relaz_tipo_id
  AND    b.relaz_tipo_code  = 'SEDE_SECONDARIA'
  and    c.soggetto_id=a.soggetto_id_a
  and    da.soggetto_id=a.soggetto_id_da
  and    p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and    d.soggetto_id=c.soggetto_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  AND    da.data_cancellazione IS NULL
  union
  select b.ord_id,a.soggetto_id,
		 a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
  from siac_t_soggetto a, siac_r_ordinativo_soggetto b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.soggetto_id=b.soggetto_id
  and   not exists
  (
  select 1
  from siac_r_soggetto_relaz rel , siac_d_relaz_tipo tipo
  where tipo.ente_proprietario_id=a.ente_proprietario_id
  and   tipo.relaz_tipo_code='SEDE_SECONDARIA'
  and   rel.relaz_tipo_id=tipo.relaz_tipo_id
  and   rel.soggetto_id_a=a.soggetto_id
  AND    p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
  and   rel.data_cancellazione is null
  )
  and   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
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
select ord_pag.*, bollo.codbollo_code, bollo.codbollo_desc,
--bollo.codbollo_id,
contotes.contotes_code, contotes.contotes_desc,--contotes.contotes_id,
dist.dist_code, dist.dist_desc,--dist.dist_id,
commis.comm_tipo_code, commis.comm_tipo_desc,
--commis.comm_tipo_id ,
bilelem.v_codice_capitolo, bilelem.v_codice_articolo,
bilelem.v_codice_ueb, bilelem.v_descrizione_capitolo ,
bilelem.v_descrizione_articolo,
modpag.modpag_id,modpag.v_soggetto_id_modpag,modpag.v_quietanziante,modpag.v_data_nascita_quietanziante,
modpag.v_luogo_nascita_quietanziante,
modpag.v_stato_nascita_quietanziante,
modpag.v_bic,modpag.v_contocorrente, modpag.v_intestazione_contocorrente,
modpag.v_iban,
modpag.v_note_modalita_pagamento,modpag.v_data_scadenza_modalita_pagamento,
modpag.v_codice_soggetto_modpag, modpag.v_descrizione_soggetto_modpag,
modpag.v_codice_fiscale_soggetto_modpag,
modpag.v_codice_fiscale_estero_soggetto_modpag,modpag.v_partita_iva_soggetto_modpag,
modpag.accredito_tipo_id,
modpag.tipo_cessione, modpag.cod_cessione,modpag.desc_cessione,
modpag.v_codice_tipo_accredito, modpag.v_descrizione_tipo_accredito,
sogg.soggetto_id,sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, sogg.codice_fiscale_estero, sogg.partita_iva
,tipoavviso.v_codice_tipo_avviso, tipoavviso.v_descrizione_tipo_avviso,
ricspesa.v_codice_spesa_ricorrente, ricspesa.v_descrizione_spesa_ricorrente,
transue.v_codice_transazione_spesa_ue, transue.v_descrizione_transazione_spesa_ue
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
      a.mif_ord_anno,a.mif_ord_numero::integer
      from mif_t_ordinativo_spesa a, mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id
      and b.flusso_elab_mif_id=a.mif_ord_flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
      group by a.mif_ord_anno,a.mif_ord_numero::integer
    ),
      descsiope as (
      select replace(substring(a.classif_code from p_ente_proprietario_id),'.', '') codice_siope,
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
    and  mif1.mif_ord_numero::integer=mifmax.mif_ord_numero) as tb
    ),
modpagcsc as ( -- SIAC-5228
SELECT  ordts.ord_id, rel.soggetto_id_da, oil.oil_relaz_tipo_code, tipo.relaz_tipo_code, tipo.relaz_tipo_desc
FROM  siac_t_ordinativo_ts ordts, siac_r_subdoc_ordinativo_ts subdocordts, siac_r_subdoc_modpag subdocmodpag, siac_r_soggrel_modpag sogrel,
      siac_r_soggetto_relaz rel, siac_r_oil_relaz_tipo roil, siac_d_relaz_tipo tipo , siac_d_oil_relaz_tipo oil
WHERE  ordts.ente_proprietario_id = p_ente_proprietario_id
AND    oil.oil_relaz_tipo_code = 'CSC'
AND    ordts.ord_ts_id = subdocordts.ord_ts_id
AND    subdocordts.subdoc_id = subdocmodpag.subdoc_id
AND    sogrel.modpag_id = subdocmodpag.modpag_id
AND    sogrel.soggetto_relaz_id = rel.soggetto_relaz_id
AND    rel.relaz_tipo_id = roil.relaz_tipo_id
AND    tipo.relaz_tipo_id = roil.relaz_tipo_id
AND    oil.oil_relaz_tipo_id = roil.oil_relaz_tipo_id
AND    p_data BETWEEN subdocordts.validita_inizio AND COALESCE(subdocordts.validita_fine, p_data)
AND    p_data BETWEEN subdocmodpag.validita_inizio AND COALESCE(subdocmodpag.validita_fine, p_data)
AND    p_data BETWEEN sogrel.validita_inizio AND COALESCE(sogrel.validita_fine, p_data)
AND    p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
AND    p_data BETWEEN roil.validita_inizio AND COALESCE(roil.validita_fine, p_data)
AND    ordts.data_cancellazione is null
AND    subdocordts.data_cancellazione is null
AND    subdocmodpag.data_cancellazione is null
AND    sogrel.data_cancellazione is null
AND    rel.data_cancellazione is null
AND    roil.data_cancellazione is null
AND    tipo.data_cancellazione is null
AND    oil.data_cancellazione is null
)
select ordinativipag.ente_proprietario_id, ordinativipag.ente_denominazione, ordinativipag.anno,
ordinativipag.fase_operativa_code, ordinativipag.fase_operativa_desc,
ordinativipag.ord_anno, ordinativipag.ord_numero, ordinativipag.ord_desc, ordinativipag.ord_stato_code,
ordinativipag.ord_stato_desc, ordinativipag.ord_cast_cassa, ordinativipag.ord_cast_competenza,
ordinativipag.ord_cast_emessi, ordinativipag.ord_emissione_data, ordinativipag.ord_riduzione_data,
ordinativipag.ord_spostamento_data, ordinativipag.ord_variazione_data,ordinativipag.ord_beneficiariomult
,ordinativipag.ord_id, ordinativipag.bil_id, ordinativipag.comm_tipo_id,
ordinativipag.data_inizio_val_stato_ordpg,
ordinativipag.data_inizio_val_ordpg,
ordinativipag.data_creazione_ordpg,
ordinativipag.data_modifica_ordpg,
ordinativipag.codbollo_id,ordinativipag.contotes_id,
ordinativipag.dist_id,
ordinativipag.ord_trasm_oil_data,ordinativipag.siope_tipo_debito_code, ordinativipag.siope_tipo_debito_desc,
ordinativipag.siope_tipo_debito_desc_bnkit,ordinativipag.siope_assenza_motivazione_code,
ordinativipag.siope_assenza_motivazione_desc, ordinativipag.siope_assenza_motivazione_desc_bnkit,
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
ordinativipag.codbollo_code, ordinativipag.codbollo_desc,
ordinativipag.codbollo_id,
ordinativipag.comm_tipo_code, ordinativipag.comm_tipo_desc, ordinativipag.comm_tipo_id,
ordinativipag.contotes_code, ordinativipag.contotes_desc,ordinativipag.contotes_id,
ordinativipag.dist_code, ordinativipag.dist_desc,ordinativipag.dist_id,
--ordinativipag.ord_id,
ordinativipag.modpag_id ,
ordinativipag.v_soggetto_id_modpag,
ordinativipag.v_quietanziante,
ordinativipag.v_data_nascita_quietanziante,
ordinativipag.v_luogo_nascita_quietanziante,
ordinativipag.v_stato_nascita_quietanziante,
ordinativipag.v_bic, ordinativipag.v_contocorrente, ordinativipag.v_intestazione_contocorrente,
ordinativipag.v_iban,
ordinativipag.v_note_modalita_pagamento, ordinativipag.v_data_scadenza_modalita_pagamento,
ordinativipag.v_codice_soggetto_modpag, ordinativipag.v_descrizione_soggetto_modpag,
ordinativipag.v_codice_fiscale_soggetto_modpag,
ordinativipag.v_codice_fiscale_estero_soggetto_modpag, ordinativipag.v_partita_iva_soggetto_modpag,
ordinativipag.tipo_cessione ,
ordinativipag.cod_cessione  ,
ordinativipag.desc_cessione,
ordinativipag.accredito_tipo_id,
ordinativipag.v_codice_tipo_accredito,
ordinativipag.v_descrizione_tipo_accredito,
--ordinativipag.ord_id,
ordinativipag.soggetto_id,
ordinativipag.soggetto_code, ordinativipag.soggetto_desc, ordinativipag.codice_fiscale,
ordinativipag.codice_fiscale_estero, ordinativipag.partita_iva,
--ordinativipag.ord_id ,
ordinativipag.v_codice_tipo_avviso, ordinativipag.v_descrizione_tipo_avviso,
--ordinativipag.ord_id ,
ordinativipag.v_codice_spesa_ricorrente,
ordinativipag.v_descrizione_spesa_ricorrente,
--ordinativipag.ord_id ,
ordinativipag.v_codice_transazione_spesa_ue,
ordinativipag.v_descrizione_transazione_spesa_ue,
class21.*,class22.*,class23.*,class24.*,class25.*,
ordinativipag.v_codice_capitolo, ordinativipag.v_codice_articolo,
ordinativipag.v_codice_ueb, ordinativipag.v_descrizione_capitolo ,
ordinativipag.v_descrizione_articolo,
mif.mif_ord_class_codice_cge, mif.descr_siope,
modpagcsc.soggetto_id_da,      -- SIAC-5228
modpagcsc.oil_relaz_tipo_code, -- SIAC-5228
modpagcsc.relaz_tipo_code,     -- SIAC-5228
modpagcsc.relaz_tipo_desc,     -- SIAC-5228
ordinativipag.ord_da_trasmettere -- 20.06.2018 Sofia siac-6175
from ordinativipag
left join class21
on ordinativipag.ord_id=class21.ord_id
left join class22
on ordinativipag.ord_id=class22.ord_id
left join class23
on ordinativipag.ord_id=class23.ord_id
left join class24
on ordinativipag.ord_id=class24.ord_id
left join class25
on ordinativipag.ord_id=class25.ord_id
left join cofog
on ordinativipag.ord_id=cofog.ord_id
left join pdc5
on ordinativipag.ord_id=pdc5.ord_id
left join pdc4
on ordinativipag.ord_id=pdc4.ord_id
left join pce5
on ordinativipag.ord_id=pce5.ord_id
left join pce4
on ordinativipag.ord_id=pce4.ord_id
left join attoamm
on ordinativipag.ord_id=attoamm.ord_id
left join t_flagAllegatoCartaceo
on ordinativipag.ord_id=t_flagAllegatoCartaceo.ord_id
left join t_noteordinativo
on
ordinativipag.ord_id=t_noteordinativo.ord_id
left join impiniziale
on ordinativipag.ord_id=impiniziale.ord_id
left join impattuale
on ordinativipag.ord_id=impattuale.ord_id
left join firma
on ordinativipag.ord_id=firma.ord_id
left join mif on ordinativipag.ord_id = mif.mif_ord_ord_id
left join modpagcsc on ordinativipag.ord_id = modpagcsc.ord_id
) as tb;

esito:= 'Fine inserimento ordinativi in pagamento (siac_dwh_ordinativo_pagamento) - '||clock_timestamp();
RETURN NEXT;

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
    cod_sogg_doc,
    doc_id -- SIAC-5573
    )
select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end ord_beneficiariomult,

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
tb.soggetto_code,
tb.doc_id
-- SIAC-5573
from (
with suball as (
with subordinativipag as (
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
       a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza,
       a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data,
       a.ord_beneficiariomult,a.ord_id,
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
where  d.ente_proprietario_id = p_ente_proprietario_id and
c.anno = p_anno_bilancio
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
a.ente_proprietario_id =p_ente_proprietario_id
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
a.ente_proprietario_id =p_ente_proprietario_id
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
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
select ord_pag.*,
bollo.codbollo_code, bollo.codbollo_desc,
contotes.contotes_code, contotes.contotes_desc,
dist.dist_code, dist.dist_desc,
commis.comm_tipo_code, commis.comm_tipo_desc,
bilelem.v_codice_capitolo,bilelem.v_codice_articolo,
bilelem.v_codice_ueb,bilelem.v_descrizione_capitolo ,
bilelem.v_descrizione_articolo,
modpag.modpag_id,modpag.v_soggetto_id_modpag, modpag.v_accredito_tipo_id,
modpag.v_quietanziante,modpag.v_data_nascita_quietanziante,
modpag.v_luogo_nascita_quietanziante,modpag.v_stato_nascita_quietanziante,modpag.v_bic, modpag.v_contocorrente,
modpag.v_intestazione_contocorrente,modpag.v_iban,
modpag.v_note_modalita_pagamento,modpag.v_data_scadenza_modalita_pagamento,
modpag.v_codice_soggetto_modpag,modpag.v_descrizione_soggetto_modpag,
modpag.v_codice_fiscale_soggetto_modpag,modpag.v_codice_fiscale_estero_soggetto_modpag,
modpag.v_partita_iva_soggetto_modpag,--modpag.accredito_tipo_id,
modpag.v_codice_tipo_accredito,modpag.v_descrizione_tipo_accredito,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, sogg.codice_fiscale_estero, sogg.partita_iva,
tipoavviso.v_codice_tipo_avviso,tipoavviso.v_descrizione_tipo_avviso,
ricspesa.v_codice_spesa_ricorrente, ricspesa.v_descrizione_spesa_ricorrente,
transue.v_codice_transazione_spesa_ue, transue.v_descrizione_transazione_spesa_ue
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
)--fine sub ordinativipag
,
class21 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_1,
b.classif_code v_classificatore_generico_1_valore, b.classif_desc v_classificatore_generico_1_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
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
a.ente_proprietario_id =p_ente_proprietario_id
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
a.ente_proprietario_id =p_ente_proprietario_id
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
a.ente_proprietario_id =p_ente_proprietario_id
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
a.ente_proprietario_id =p_ente_proprietario_id
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
select
subordinativipag.ente_proprietario_id, subordinativipag.ente_denominazione, subordinativipag.anno, subordinativipag.fase_operativa_code,
subordinativipag.fase_operativa_desc,subordinativipag.ord_anno, subordinativipag.ord_numero, subordinativipag.ord_desc,
 subordinativipag.ord_stato_code, subordinativipag.ord_stato_desc, subordinativipag.ord_cast_cassa, subordinativipag.ord_cast_competenza,
subordinativipag.ord_cast_emessi, subordinativipag.ord_emissione_data, subordinativipag.ord_riduzione_data,
subordinativipag.ord_spostamento_data, subordinativipag.ord_variazione_data, subordinativipag.ord_beneficiariomult,
subordinativipag.ord_ts_code, subordinativipag.ord_ts_desc, subordinativipag.ord_ts_data_scadenza,
subordinativipag.ord_id,subordinativipag.bil_id, subordinativipag.comm_tipo_id,
subordinativipag.data_inizio_val_stato_ordpg,subordinativipag.data_inizio_val_ordpg,subordinativipag.data_creazione_ordpg,
subordinativipag.data_modifica_ordpg,subordinativipag.codbollo_id,subordinativipag.contotes_id,subordinativipag.dist_id,
subordinativipag.ord_ts_id,
subordinativipag.data_inizio_val_subordpg,subordinativipag.data_creazione_subordpg,subordinativipag.data_modifica_subordpg,
cofog.codice_cofog_gruppo,cofog.descrizione_cofog_gruppo,cofog.codice_cofog_divisione,cofog.descrizione_cofog_divisione,
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
t_noteordinativo.v_note_ordinativo
from subordinativipag
left join class21
on subordinativipag.ord_id=class21.ord_id
left join class22
on subordinativipag.ord_id=class22.ord_id
left join class23
on subordinativipag.ord_id=class23.ord_id
left join class24
on subordinativipag.ord_id=class24.ord_id
left join class25
on subordinativipag.ord_id=class25.ord_id
left join cofog
on subordinativipag.ord_id=cofog.ord_id
left join pdc5
on subordinativipag.ord_id=pdc5.ord_id
left join pdc4
on subordinativipag.ord_id=pdc4.ord_id
left join pce5
on subordinativipag.ord_id=pce5.ord_id
left join pce4
on subordinativipag.ord_id=pce4.ord_id
left join attoamm
on subordinativipag.ord_id=attoamm.ord_id
left join t_flagAllegatoCartaceo
on subordinativipag.ord_id=t_flagAllegatoCartaceo.ord_id
left join t_noteordinativo
on subordinativipag.ord_id=t_noteordinativo.ord_id
)
select suball.*
,
t_cig.cig,
t_cup.cup,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,
ons.*,liq.*, elenco_doc.*
 from suball
 left join
 (
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
AND    c.data_cancellazione IS NULL) t_cig on t_cig.sord_id=suball.ord_ts_id
  left join (SELECT a.sord_id, c.testo cup
FROM   siac_r_liquidazione_ord a, siac_t_attr b,siac_r_liquidazione_attr c
WHERE b.attr_code='cup' and a.ente_proprietario_id=p_ente_proprietario_id and
 c.attr_id = b.attr_id and c.liq_id=a.liq_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL) t_cup on t_cup.sord_id=suball.ord_ts_id
left join (SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale, b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE a.ente_proprietario_id=p_ente_proprietario_id and a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY b.ord_ts_id) impiniziale on suball.ord_ts_id=impiniziale.ord_ts_id
left join (SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale,
b.ord_ts_id FROM siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE a.ente_proprietario_id=p_ente_proprietario_id and a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY
b.ord_ts_id) impattuale on suball.ord_ts_id=impattuale.ord_ts_id
left join (select a.ord_id, a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))
firma  on suball.ord_id=firma.ord_id
left join (
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
on onere.onere_att_id=onatt.onere_att_id) ons
on suball.ord_ts_id=ons.ord_ts_id
left join (select a.sord_id,
b.liq_anno v_liq_anno, b.liq_numero v_liq_numero, b.liq_desc v_liq_desc, b.liq_emissione_data v_liq_emissione_data,
         b.liq_importo v_liq_importo, b.liq_automatica v_liq_automatica, b.liq_convalida_manuale
 FROM siac_r_liquidazione_ord a, siac_t_liquidazione b
  WHERE a.liq_id = b.liq_id
  AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL ) liq
  on suball.ord_ts_id=liq.sord_id
left join   (
		select distinct d_doc_gruppo.doc_gruppo_tipo_code, d_doc_gruppo.doc_gruppo_tipo_desc,
    	d_doc_fam_tipo.doc_fam_tipo_code, d_doc_fam_tipo.doc_fam_tipo_desc,
        d_doc_tipo.doc_tipo_code, d_doc_tipo.doc_tipo_desc,
        t_doc.doc_numero, t_doc.doc_anno, t_subdoc.subdoc_numero,
        t_soggetto.soggetto_code,
        r_subdoc_ord_ts.ord_ts_id,
        t_doc.doc_id -- SIAC-5573
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
 --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
 elenco_doc on elenco_doc.ord_ts_id=suball.ord_ts_id
) as tb;


esito:= 'Fine funzione carico ordinativi in pagamento (fnc_siac_dwh_ordinativo_pagamento) - '||clock_timestamp();
RETURN NEXT;



update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()- fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi in pagamento (fnc_siac_dwh_ordinativo_pagamento) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- siac-6488 Sofia - Fine


--- siac-6347 Sofia - Inizio


SELECT fnc_dba_add_column_params('siac_t_doc_num', 'doc_tipo_id', 'integer not null');

SELECT fnc_dba_add_fk_constraint 
(
	'siac_t_doc_num',
	'siac_d_doc_tipo_siac_t_doc_num',
    'doc_tipo_id',
  	'siac_d_doc_tipo',
    'doc_tipo_id'
);
	
insert into siac_d_doc_tipo
(
  doc_tipo_code,
  doc_tipo_desc,
  doc_fam_tipo_id,
  doc_gruppo_tipo_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select 'IPA',
       'INCASSI PAGOPA',
       tipo.doc_fam_tipo_id,
       tipo.doc_gruppo_tipo_id,
       now(),
       'admin_pagoPA',
       tipo.ente_proprietario_id
from siac_d_doc_tipo tipo,siac_t_ente_proprietario ente
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.doc_tipo_code='DSI'
and   not exists
(select 1 from siac_d_doc_tipo tipo1 where tipo1.ente_proprietario_id=ente.ente_proprietario_id and tipo1.doc_tipo_code='IPA');

insert into siac_r_doc_tipo_attr
(
  doc_tipo_id,
  attr_id,
  tabella_id,
  boolean,
  percentuale,
  testo,
  numerico,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select tipoipa.doc_tipo_id,
       r.attr_id,
       r.tabella_id,
       r.boolean,
       r.percentuale,
       r.testo,
       r.numerico,
       now(),
       'admin_pagoPA',
       tipoipa.ente_proprietario_id
from siac_r_doc_tipo_attr r, siac_d_doc_tipo tipo,siac_t_ente_proprietario ente,
     siac_d_doc_tipo tipoipa
where tipo.doc_tipo_code='DSI'
and   ente.ente_proprietario_id=tipo.ente_proprietario_id
and   tipoipa.ente_proprietario_id=ente.ente_proprietario_id
and   tipoipa.doc_tipo_code='IPA'
and   r.doc_tipo_id=tipo.doc_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   not exists
(
 select 1 from siac_r_doc_tipo_attr r1
 where r1.doc_tipo_id=tipoipa.doc_tipo_id
 and   r1.attr_id=r.attr_id
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null
);
	
drop table if exists pagopa_t_elaborazione_log cascade;

drop table if exists pagopa_bck_t_subdoc cascade;

drop table if exists pagopa_bck_t_subdoc_attr cascade;
drop table if exists pagopa_bck_t_subdoc_atto_amm cascade;
drop table if exists pagopa_bck_t_subdoc_prov_cassa cascade;
drop table if exists pagopa_bck_t_subdoc_movgest_ts cascade;
drop table if exists pagopa_bck_t_doc_sog cascade;
drop table if exists pagopa_bck_t_doc_stato cascade;
drop table if exists pagopa_bck_t_doc_attr cascade;
drop table if exists pagopa_bck_t_doc_class cascade;
drop table if exists pagopa_bck_t_registrounico_doc cascade;
drop table if exists pagopa_bck_t_subdoc_num cascade;
drop table if exists pagopa_bck_t_doc cascade;


drop table if exists pagopa_t_riconciliazione_doc cascade;
drop table if exists pagopa_t_elaborazione_flusso cascade;
drop table if exists pagopa_t_riconciliazione cascade;
drop table if exists pagopa_r_elaborazione_file cascade;
drop table if exists pagopa_t_elaborazione cascade;
drop table if exists siac_t_file_pagopa cascade;
drop table if exists pagopa_d_elaborazione_stato cascade;
drop table if exists siac_d_file_pagopa_stato cascade;
drop table if exists pagopa_d_riconciliazione_errore cascade;



-- pagopa_d_riconciliazione_errore

CREATE TABLE pagopa_d_riconciliazione_errore (
  pagopa_ric_errore_id SERIAL,
  pagopa_ric_errore_code VARCHAR(200) NOT NULL,
  pagopa_ric_errore_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_d_ric_errore PRIMARY KEY(pagopa_ric_errore_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_d_ric_errore FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_pagopa_d_ric_errore_1 ON pagopa_d_riconciliazione_errore
  USING btree (pagopa_ric_errore_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX pagopa_d_ric_errore_stato_fk_ente_proprietario_id_idx ON pagopa_d_riconciliazione_errore
  USING btree (ente_proprietario_id);



-- siac_d_file_pagopo_stato
CREATE TABLE siac_d_file_pagopa_stato (
  file_pagopa_stato_id SERIAL,
  file_pagopa_stato_code VARCHAR(200) NOT NULL,
  file_pagopa_stato_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_file_pagopa_stato PRIMARY KEY(file_pagopa_stato_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_file_pagopa_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_file_pagopa_stato_1 ON siac_d_file_pagopa_stato
  USING btree (file_pagopa_stato_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX siac_d_file_pagopa_stato_fk_ente_proprietario_id_idx ON siac_d_file_pagopa_stato
  USING btree (ente_proprietario_id);



-- siac_t_file_pagopa
CREATE TABLE siac_t_file_pagopa (
  file_pagopa_id SERIAL,
  file_pagopa_size NUMERIC NOT NULL,
  file_pagopa BYTEA,
  file_pagopa_code VARCHAR NOT NULL,
  file_pagopa_note VARCHAR,
  file_pagopa_anno integer not NULL,
  file_pagopa_stato_id INTEGER NOT NULL,
  file_pagopa_errore_id integer,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_t_file_pagopa PRIMARY KEY(file_pagopa_id),
  CONSTRAINT siac_d_file_pagopa_stato_siac_t_file_pagopa FOREIGN KEY (file_pagopa_stato_id)
    REFERENCES siac_d_file_pagopa_stato(file_pagopa_stato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_riconciliazione_errore_siac_t_file_pagopa FOREIGN KEY (file_pagopa_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_t_file_pagopa FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE siac_t_file_pagopa
IS 'Tabella di archivio file XML riconciliazione PAGOPA';



CREATE INDEX siac_t_file_pagopa_fk_ente_proprietario_id_idx ON siac_t_file_pagopa
  USING btree (ente_proprietario_id);

CREATE INDEX siac_t_file_pagopa_fk_file_pagopa_stato_id_idx ON siac_t_file_pagopa
  USING btree (file_pagopa_stato_id);

-- pagopa_d_elaborazione_stato
CREATE TABLE pagopa_d_elaborazione_stato (
  pagopa_elab_stato_id SERIAL,
  pagopa_elab_stato_code VARCHAR(200) NOT NULL,
  pagopa_elab_stato_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_d_elab_stato PRIMARY KEY(pagopa_elab_stato_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_d_elaborazione_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_pagopa_d_elaborazione_stato_1 ON pagopa_d_elaborazione_stato
  USING btree (pagopa_elab_stato_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX pagopa_d_elaborazione_stato_fk_ente_proprietario_id_idx ON pagopa_d_elaborazione_stato
  USING btree (ente_proprietario_id);

-- pagopa_t_elaborazione

CREATE TABLE pagopa_t_elaborazione (
  pagopa_elab_id SERIAL,
  pagopa_elab_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_elab_stato_id INTEGER NOT NULL,
  pagopa_elab_note VARCHAR(1500) NOT NULL,
  pagopa_elab_file_id  varchar(250),
  pagopa_elab_file_ora varchar(250),
  pagopa_elab_file_ente varchar(250),
  pagopa_elab_file_fruitore varchar(250),
  file_pagopa_id   integer  null,
  pagopa_elab_errore_id integer,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_elaborazione PRIMARY KEY(pagopa_elab_id),
  CONSTRAINT siac_t_file_pagopa_pagopa_t_elaborazione FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elaborazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_elaborazione_stato_pagopa_t_elaborazione FOREIGN KEY (pagopa_elab_stato_id)
    REFERENCES pagopa_d_elaborazione_stato(pagopa_elab_stato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_riconciliazione_errore_pagopa_t_elaborazione FOREIGN KEY (pagopa_elab_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_elaborazione
IS 'Tabella di elaborazione dei file XML riconciliazione PAGOPO';



COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_id
IS 'Identificativo file XML';

COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_ora
IS 'Ora generazione file XML';

COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_ente
IS 'Codice Ente file  XML';

COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_fruitore
IS 'Codice Fruitore file XML';

COMMENT ON COLUMN pagopa_t_elaborazione.file_pagopa_id
IS 'Identificativo file XML in siac_t_file_pagopa.';


CREATE INDEX pagopa_t_elaborazione_fk_ente_proprietario_id_idx ON pagopa_t_elaborazione
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_elaborazione_fk_pagopa_elab_stato_id_idx ON pagopa_t_elaborazione
  USING btree (pagopa_elab_stato_id);


CREATE INDEX pagopa_t_elaborazione_fk_siac_t_file_pagopa_idx ON pagopa_t_elaborazione
  USING btree (file_pagopa_id);


CREATE TABLE pagopa_r_elaborazione_file (
  pagopa_r_elab_id SERIAL,
  pagopa_elab_id integer not null,
  file_pagopa_id   integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_r_elaborazione_file PRIMARY KEY(pagopa_r_elab_id),
  CONSTRAINT siac_t_file_pagopa_pagopa_r_elaborazione_file FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_r_elaborazione_file FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_r_elaborazione_file FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_r_elaborazione_file
IS 'Tabella di relazione tra PAGOPA file XML e PAGOPA elaborazione.';

COMMENT ON COLUMN pagopa_r_elaborazione_file.pagopa_elab_id
IS 'Identificativo elaborazione';

COMMENT ON COLUMN pagopa_r_elaborazione_file.file_pagopa_id
IS 'Identificativo file XML';


CREATE INDEX pagopa_r_elaborazione_file_fk_ente_proprietario_id_idx ON pagopa_r_elaborazione_file
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_r_elaborazione_file_fk_file_pagopa_id_idx ON pagopa_r_elaborazione_file
  USING btree (file_pagopa_id);



CREATE INDEX pagopa_r_elaborazione_file_fk_pagopa_elab_id_idx ON pagopa_r_elaborazione_file
  USING btree (pagopa_elab_id);



CREATE TABLE pagopa_t_elaborazione_log
(
  pagopa_elab_log_id SERIAL,
  pagopa_elab_id INTEGER  NULL,
  pagopa_file_id integer null,
  pagopa_elab_log_operazione VARCHAR(2500) NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_elab_t_elaborazione_log PRIMARY KEY(pagopa_elab_log_id),
  CONSTRAINT pagopa_t_elaborazione_pagopa_t_elaborazione_log FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_file_pagopa_pagopa_t_elaborazione_log FOREIGN KEY (pagopa_file_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elaborazione_log FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_elaborazione_log
IS 'Elaborazioni riconciliazione PAGOPA - LOG.';

-- pagopa_t_riconciliazione

CREATE TABLE pagopa_t_riconciliazione (
  pagopa_ric_id SERIAL,
  pagopa_ric_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  -- XML - inizio
  -- intestazione XML
  pagopa_ric_file_id  varchar,
  pagopa_ric_file_ora TIMESTAMP WITHOUT TIME ZONE,
  pagopa_ric_file_ente varchar,
  pagopa_ric_file_fruitore varchar,
  pagopa_ric_file_num_flussi integer,
  pagopa_ric_file_tot_flussi  numeric, -- importo
  -- intestazione FLUSSO
  pagopa_ric_flusso_id  varchar,
  pagopa_ric_flusso_nome_mittente  varchar,
  pagopa_ric_flusso_data  TIMESTAMP WITHOUT TIME ZONE,
  pagopa_ric_flusso_tot_pagam  numeric, -- importo
  pagopa_ric_flusso_anno_esercizio  integer,
  pagopa_ric_flusso_anno_provvisorio  integer,
  pagopa_ric_flusso_num_provvisorio  integer,
  -- dettaglio flusso
  pagopa_ric_flusso_voce_code  varchar,
  pagopa_ric_flusso_voce_desc  varchar,
  pagopa_ric_flusso_tematica varchar,
  pagopa_ric_flusso_sottovoce_code  varchar,
  pagopa_ric_flusso_sottovoce_desc  varchar,
  pagopa_ric_flusso_sottovoce_importo  numeric, -- importo
  pagopa_ric_flusso_anno_accertamento  integer,
  pagopa_ric_flusso_num_accertamento  integer,
  pagopa_ric_flusso_num_capitolo  integer,
  pagopa_ric_flusso_num_articolo  integer,
  pagopa_ric_flusso_pdc_v_fin  varchar,
  pagopa_ric_flusso_titolo  varchar,
  pagopa_ric_flusso_tipologia varchar,
  pagopa_ric_flusso_categoria  varchar,
  pagopa_ric_flusso_codice_benef  varchar,
  pagopa_ric_flusso_str_amm  varchar,
  -- XML - fine
  file_pagopa_id integer not null,
  pagopa_ric_flusso_stato_elab varchar default 'N' not null ,
  pagopa_ric_errore_id integer, -- riferimento errore_id in caso di errore
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_riconciliazione PRIMARY KEY(pagopa_ric_id),
  CONSTRAINT siac_t_file_pagopa_pagopa_t_riconciliazione FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_ric_err_pagopa_t_riconciliazione FOREIGN KEY (pagopa_ric_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_riconciliazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_riconciliazione
IS 'Tabella di tracciatura piatta dati presenti in  file XML riconciliazione PAGOPO';



COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_id
IS 'Identificativo XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_ora
IS 'Ora generazione file complessivo XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_ente
IS 'Codice Ente file  XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_fruitore
IS 'Codice Fruitore file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_num_flussi
IS 'Numero di flussi contenuti in file XML';


COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_tot_flussi
IS 'Totale dei flussi contenuti in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_id
IS 'Identificativo flusso contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_anno_esercizio
IS 'Anno esercizio di riferimento del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_anno_provvisorio
IS 'Anno provvisorio di riferimento del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_num_provvisorio
IS 'Numero provvisorio di riferimento del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_voce_code
IS 'Codice voce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_sottovoce_code
IS 'Codice sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_sottovoce_importo
IS 'Importo dettaglio  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_anno_accertamento
IS 'Anno accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_num_accertamento
IS 'Numero accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';



COMMENT ON COLUMN pagopa_t_riconciliazione.file_pagopa_id
IS 'Identificativo file XML in siac_t_file_pagopa.';


COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_stato_elab
IS 'Stato di elaborazione del singolo dettaglio  - dettaglio del singolo flusso  contenuto in file XML - [N-No S-Si E-Err X-Scarto]';


CREATE INDEX pagopa_t_riconciliazione_ric_file_id_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_file_id);

CREATE INDEX pagopa_t_riconciliazione_ric_flusso_id_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_provvisorio_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_anno_esercizio,pagopa_ric_flusso_anno_provvisorio,pagopa_ric_flusso_num_provvisorio,
               pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_voce_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_voce_code,
  			   pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_sottovoce_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_sottovoce_code,
               pagopa_ric_flusso_voce_code,
               pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_accertamento_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_anno_esercizio,pagopa_ric_flusso_anno_accertamento,pagopa_ric_flusso_num_accertamento,
               pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_fk_file_pagopa_id_idx ON pagopa_t_riconciliazione
  USING btree (file_pagopa_id);

CREATE INDEX pagopa_t_riconciliazione_fk_ente_proprietario_id_idx ON pagopa_t_riconciliazione
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_riconciliazione_ric_errore_id_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_errore_id);



-- pagopa_t_elaborazione_flusso
CREATE TABLE pagopa_t_elaborazione_flusso (
  pagopa_elab_flusso_id SERIAL,
  pagopa_elab_flusso_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_elab_flusso_stato_id INTEGER NOT NULL,
  pagopa_elab_flusso_note VARCHAR(750) NOT NULL,
  pagopa_elab_ric_flusso_id  varchar,
  pagopa_elab_flusso_nome_mittente  varchar,
  pagopa_elab_ric_flusso_data  varchar,
  pagopa_elab_flusso_tot_pagam  numeric, -- importo
  pagopa_elab_flusso_anno_esercizio  integer,
  pagopa_elab_flusso_anno_provvisorio  integer,
  pagopa_elab_flusso_num_provvisorio  integer,
  pagopa_elab_flusso_provc_id  integer,
  pagopa_elab_id  integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_elaborazione_flusso PRIMARY KEY(pagopa_elab_flusso_id),
  CONSTRAINT pagopa_t_elaborazione_pagopa_t_elab_flusso FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_t_elab_flusso FOREIGN KEY (pagopa_elab_flusso_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elab_flusso FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_elaborazione_stato_pagopa_t_elab_flusso FOREIGN KEY (pagopa_elab_flusso_stato_id)
    REFERENCES pagopa_d_elaborazione_stato(pagopa_elab_stato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_elaborazione_flusso
IS 'Tabella di elaborazione del singolo flusso riconciliazione PAGOPO contenuto nel file XML ';



COMMENT ON COLUMN pagopa_t_elaborazione_flusso.pagopa_elab_ric_flusso_id
IS 'Identificativo flusso riconciliazione PAGOPO nel file XML';

COMMENT ON COLUMN pagopa_t_elaborazione_flusso.pagopa_elab_ric_flusso_data
IS 'Ora generazione flusso riconciliazione PAGOPO nel file XML';

COMMENT ON COLUMN pagopa_t_elaborazione_flusso.pagopa_elab_id
IS 'Identificativo elaborazione file XML in pagopa_t_elaborazione.';


CREATE INDEX pagopa_t_elaborazione_flusso_fk_ente_proprietario_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_elaborazione_flusso_fk_pagopa_elab_stato_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_flusso_stato_id);


CREATE INDEX pagopa_t_elaborazione_flusso_fk_pagopa_t_elab_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_id);

CREATE INDEX pagopa_t_elaborazione_flusso_pagopa_elab_ric_flusso_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_ric_flusso_id);


CREATE INDEX pagopa_t_elaborazione_flusso_provvisorio_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_flusso_anno_esercizio,pagopa_elab_flusso_anno_provvisorio,pagopa_elab_flusso_num_provvisorio,
               pagopa_elab_ric_flusso_id);

CREATE INDEX pagopa_t_elaborazione_flusso_provvisorio_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_flusso_provc_id);




-- pagopa_t_riconciliazione_doc
CREATE TABLE pagopa_t_riconciliazione_doc (
  pagopa_ric_doc_id SERIAL,
  pagopa_ric_doc_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_ric_doc_voce_code  varchar,
  pagopa_ric_doc_voce_desc  varchar,
  pagopa_ric_doc_voce_tematica  varchar,
  pagopa_ric_doc_sottovoce_code  varchar,
  pagopa_ric_doc_sottovoce_desc  varchar,
  pagopa_ric_doc_sottovoce_importo  numeric,
  pagopa_ric_doc_anno_esercizio  integer,
  pagopa_ric_doc_anno_accertamento  integer,
  pagopa_ric_doc_num_accertamento  integer,
  pagopa_ric_doc_num_capitolo  integer,
  pagopa_ric_doc_num_articolo  integer,
  pagopa_ric_doc_pdc_v_fin  varchar,
  pagopa_ric_doc_titolo  varchar,
  pagopa_ric_doc_tipologia varchar,
  pagopa_ric_doc_categoria  varchar,
  pagopa_ric_doc_codice_benef  varchar,
  pagopa_ric_doc_str_amm  varchar,
  -- identificativi contabilia - associati dopo elaborazione
  pagopa_ric_doc_subdoc_id integer,
  pagopa_ric_doc_provc_id integer,
  pagopa_ric_doc_movgest_ts_id integer,
  pagopa_ric_doc_stato_elab varchar default 'N' not null ,
  pagopa_ric_errore_id integer, -- riferimento errore_id in caso di errore
  pagopa_ric_id  integer, -- riferimento t_riconciliazione
  pagopa_elab_flusso_id integer, -- riferimento t_elaborazione_flusso
    -- XML - fine
  file_pagopa_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_riconciliazione_doc PRIMARY KEY(pagopa_ric_doc_id),
  CONSTRAINT pagopa_t_elaborazione_flusso_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_elab_flusso_id)
    REFERENCES pagopa_t_elaborazione_flusso(pagopa_elab_flusso_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_riconciliazione_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_id)
    REFERENCES pagopa_t_riconciliazione(pagopa_ric_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_file_pagopa_pagopa_t_riconciliazione_doc FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_movgest_ts_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_doc_movgest_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_doc_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_riconc_err_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_riconciliazione_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_riconciliazione_doc
IS 'Tabella di elaborazione dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_id
IS 'Riferimento identificativo relativo dettaglio in pagopa_t_riconciliazione';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_elab_flusso_id
IS 'Riferimento identificativo elaborazione flusso in pagopa_t_elaborazione_flusso';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_subdoc_id
IS 'Riferimento identificativo subdocumento emesso in Contabilia';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_movgest_ts_id
IS 'Riferimento identificativo accertamento Contabilia collegato';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_provc_id
IS 'Riferimento identificativo provvisorio di cassa Contabilia collegato';


COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_anno_esercizio
IS 'Anno esercizio di riferimento';


COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_voce_code
IS 'Codice voce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_sottovoce_code
IS 'Codice sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_sottovoce_importo
IS 'Importo dettaglio  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_anno_accertamento
IS 'Anno accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_num_accertamento
IS 'Numero accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_stato_elab
IS 'Stato di elaborazione del singolo dettaglio  - dettaglio del singolo flusso  contenuto in file XML - [N-No S-Si E-Err X-Scarto]';


CREATE INDEX pagopa_t_riconciliazione_doc_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_id);

CREATE INDEX pagopa_t_riconciliazione_doc_flusso_elab_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_elab_flusso_id);


CREATE INDEX pagopa_t_riconciliazione_doc_sottovoce_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_sottovoce_code,
               pagopa_ric_doc_voce_code);

CREATE INDEX pagopa_t_riconciliazione_doc_accertamento_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_anno_esercizio,pagopa_ric_doc_anno_accertamento,pagopa_ric_doc_num_accertamento);

CREATE INDEX pagopa_t_riconciliazione_doc_subdoc_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_subdoc_id);

CREATE INDEX pagopa_t_riconciliazione_doc_movgest_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_movgest_ts_id);

CREATE INDEX pagopa_t_riconciliazione_doc_provc_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_provc_id);


CREATE INDEX pagopa_t_riconciliazione_doc_fk_ente_proprietario_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (ente_proprietario_id);


CREATE INDEX pagopa_t_riconciliazione_doc_fk_file_pagopa_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (file_pagopa_id);

-------------------------- BACKUP



CREATE TABLE pagopa_bck_t_subdoc
(
  pagopa_bck_subdoc_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  subdoc_id integer,
  subdoc_numero INTEGER,
  subdoc_desc VARCHAR(500),
  subdoc_importo NUMERIC,
  subdoc_nreg_iva VARCHAR(500),
  subdoc_data_scadenza TIMESTAMP WITHOUT TIME ZONE,
  subdoc_convalida_manuale CHAR(1),
  subdoc_importo_da_dedurre NUMERIC,
  subdoc_splitreverse_importo NUMERIC,
  subdoc_pagato_cec BOOLEAN,
  subdoc_data_pagamento_cec TIMESTAMP WITHOUT TIME ZONE,
  contotes_id INTEGER,
  dist_id INTEGER,
  comm_tipo_id INTEGER,
  doc_id INTEGER NOT NULL,
  subdoc_tipo_id INTEGER NOT NULL,
  notetes_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  bck_login_creazione VARCHAR(200),
  bck_login_modifica VARCHAR(200),
  bck_login_cancellazione VARCHAR(200),
  siope_tipo_debito_id INTEGER,
  siope_assenza_motivazione_id INTEGER,
  siope_scadenza_motivo_id INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc PRIMARY KEY(pagopa_bck_subdoc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc
IS 'Tabella di backup siac_t_subdoc per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_id_idx ON pagopa_bck_t_subdoc
  USING btree (pagopa_bck_subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_subdoc_id_idx ON pagopa_bck_t_subdoc
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_id_idx ON pagopa_bck_t_subdoc
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_elab_id_idx ON pagopa_bck_t_subdoc
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_subdoc_attr
(
  pagopa_bck_subdoc_attr_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  subdoc_attr_id integer,
  subdoc_id INTEGER,
  attr_id INTEGER,
  tabella_id integer,
  "boolean" CHAR(1),
  percentuale NUMERIC,
  testo VARCHAR(500),
  numerico NUMERIC,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_attr PRIMARY KEY(pagopa_bck_subdoc_attr_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_attr FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_attr FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_attr FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc_attr
IS 'Tabella di backup siac_r_subdoc_attr per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_attr.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_attr.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_attr_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (pagopa_bck_subdoc_attr_id);

CREATE INDEX pagopa_bck_t_subdoc_attr_subdoc_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_attr_provc_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_attr_elab_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_subdoc_atto_amm
(
  pagopa_bck_subdoc_attoamm_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  subdoc_atto_amm_id integer,
  subdoc_id INTEGER,
  attoamm_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_atto_amm PRIMARY KEY(pagopa_bck_subdoc_attoamm_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_attoamm FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_attoamm FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_attoamm FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_subdoc_atto_amm
IS 'Tabella di backup siac_r_subdoc_atto_amm per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_atto_amm.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_atto_amm.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_attoamm_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (pagopa_bck_subdoc_attoamm_id);

CREATE INDEX pagopa_bck_t_subdoc_attoamm_subdoc_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_attoamm_provc_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_attoamm_elab_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (pagopa_elab_id);

create table pagopa_bck_t_subdoc_prov_cassa
(
  pagopa_bck_subdoc_provc_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  subdoc_provc_id integer,
  subdoc_id INTEGER,
  provc_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_provc PRIMARY KEY(pagopa_bck_subdoc_provc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_provc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_provc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_provc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc_prov_cassa
IS 'Tabella di backup siac_r_subdoc_prov_cassa per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_prov_cassa.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_prov_cassa.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_provc_subdoc_provc_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (pagopa_bck_subdoc_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_subdoc_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_provc_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_elab_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_subdoc_movgest_ts
(
  pagopa_bck_subdoc_movgest_ts_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  subdoc_movgest_ts_id integer,
  subdoc_id INTEGER,
  movgest_ts_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_mov PRIMARY KEY(pagopa_bck_subdoc_movgest_ts_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_mov FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_mov FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_mov FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc_movgest_ts
IS 'Tabella di backup siac_r_subdoc_movgest_ts per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_movgest_ts.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_movgest_ts.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_movgest_ts_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (pagopa_bck_subdoc_movgest_ts_id);

CREATE INDEX pagopa_bck_t_subdoc_mov_subdoc_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_mov_provc_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_mov_elab_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc_sog
(
  pagopa_bck_doc_sog_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  doc_sog_id integer,
  doc_id INTEGER,
  soggetto_id INTEGER,
  ruolo_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_sog PRIMARY KEY(pagopa_bck_doc_sog_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_sog FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_sog FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_sog FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_sog
IS 'Tabella di backup siac_r_doc_sog per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_sog.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_sog.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_sog_id_idx ON pagopa_bck_t_doc_sog
  USING btree (pagopa_bck_doc_sog_id);

CREATE INDEX pagopa_bck_t_doc_sog_doc_id_idx ON pagopa_bck_t_doc_sog
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_sog_provc_id_idx ON pagopa_bck_t_doc_sog
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_sog_elab_id_idx ON pagopa_bck_t_doc_sog
  USING btree (pagopa_elab_id);

create TABLE pagopa_bck_t_doc_stato
(
  pagopa_bck_doc_stato_r_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  doc_stato_r_id integer,
  doc_id INTEGER,
  doc_stato_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_stato PRIMARY KEY(pagopa_bck_doc_stato_r_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_stato FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_stato FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_stato
IS 'Tabella di backup siac_r_doc_stato per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_stato.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_stato.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_stato_stato_r_id_idx ON pagopa_bck_t_doc_stato
  USING btree (pagopa_bck_doc_stato_r_id);

CREATE INDEX pagopa_bck_t_doc_stato_doc_id_idx ON pagopa_bck_t_doc_stato
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_stato_provc_id_idx ON pagopa_bck_t_doc_stato
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_stato_elab_id_idx ON pagopa_bck_t_doc_stato
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc_attr
(
  pagopa_bck_doc_attr_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  doc_attr_id integer,
  doc_id INTEGER,
  attr_id INTEGER,
  tabella_id integer,
  "boolean" CHAR(1),
  percentuale NUMERIC,
  testo VARCHAR(500),
  numerico NUMERIC,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_attr PRIMARY KEY(pagopa_bck_doc_attr_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_attr FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_attr FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_attr FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_attr
IS 'Tabella di backup siac_r_doc_attr per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_attr.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_attr.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_attr_id_idx ON pagopa_bck_t_doc_attr
  USING btree (pagopa_bck_doc_attr_id);

CREATE INDEX pagopa_bck_t_doc_attr_doc_id_idx ON pagopa_bck_t_doc_attr
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_attr_provc_id_idx ON pagopa_bck_t_doc_attr
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_attr_elab_id_idx ON pagopa_bck_t_doc_attr
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc_class
(
  pagopa_bck_doc_classif_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  doc_classif_id integer,
  doc_id INTEGER,
  classif_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_class PRIMARY KEY(pagopa_bck_doc_classif_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_class FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_class FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_class FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_class
IS 'Tabella di backup siac_r_doc_class per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_class.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_Class.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_classif_id_idx ON pagopa_bck_t_doc_class
  USING btree (pagopa_bck_doc_classif_id);

CREATE INDEX pagopa_bck_t_doc_class_doc_id_idx ON pagopa_bck_t_doc_class
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_class_provc_id_idx ON pagopa_bck_t_doc_class
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_class_elab_id_idx ON pagopa_bck_t_doc_class
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_registrounico_doc
(
  pagopa_bck_rudoc_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  rudoc_id integer,
  rudoc_registrazione_anno INTEGER,
  rudoc_registrazione_numero INTEGER,
  rudoc_registrazione_data TIMESTAMP WITHOUT TIME ZONE,
  doc_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_reg_doc PRIMARY KEY(pagopa_bck_rudoc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_reg_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_reg_doc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_reg_doc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_registrounico_doc
IS 'Tabella di backup siac_t_registrounico_doc per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_registrounico_doc.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_registrounico_doc.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_reg_doc_rudoc_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (pagopa_bck_rudoc_id);

CREATE INDEX pagopa_bck_t_doc_reg_doc_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_reg_doc_provc_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_reg_doc_elab_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (pagopa_elab_id);

create table pagopa_bck_t_subdoc_num
(
   pagopa_bck_subdoc_num_id	 serial,
   pagopa_provc_id integer not null,
   pagopa_elab_id integer not null,
   subdoc_num_id integer,
   doc_id INTEGER,
   subdoc_numero INTEGER,
   bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
   bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
   bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
   bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
   bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
   bck_login_operazione  VARCHAR(200),
   validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
   validita_fine TIMESTAMP WITHOUT TIME ZONE,
   ente_proprietario_id INTEGER NOT NULL,
   data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
   data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
   data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
   login_operazione  VARCHAR(200) NOT NULL,
   CONSTRAINT pk_pagopa_bck_t_subdoc_num PRIMARY KEY(pagopa_bck_subdoc_num_id),
   CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_num FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_sudoc_num FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_num FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_subdoc_num
IS 'Tabella di backup pagopa_bck_t_subdoc_num per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_num.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_num.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_num_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (pagopa_bck_subdoc_num_id);

CREATE INDEX pagopa_bck_t_subdoc_num_doc_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_subdoc_num_provc_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_num_elab_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc
(
  pagopa_bck_doc_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  doc_id integer,
  doc_anno INTEGER,
  doc_numero VARCHAR(200),
  doc_desc VARCHAR(500),
  doc_importo NUMERIC,
  doc_beneficiariomult BOOLEAN,
  doc_data_emissione TIMESTAMP WITHOUT TIME ZONE,
  doc_data_scadenza TIMESTAMP WITHOUT TIME ZONE,
  doc_tipo_id INTEGER,
  codbollo_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  bck_login_creazione VARCHAR(200),
  bck_login_modifica VARCHAR(200),
  bck_login_cancellazione VARCHAR,
  pcccod_id INTEGER,
  pccuff_id INTEGER,
  doc_collegato_cec BOOLEAN,
  doc_contabilizza_genpcc BOOLEAN,
  siope_documento_tipo_id INTEGER,
  siope_documento_tipo_analogico_id INTEGER,
  doc_sdi_lotto_siope VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc PRIMARY KEY(pagopa_bck_doc_id),
   CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_num FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_doc
IS 'Tabella di backup pagopa_bck_t_doc per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_id_idx ON pagopa_bck_t_doc
  USING btree (pagopa_bck_doc_id);

CREATE INDEX pagopa_bck_t_doc_doc_id_idx ON pagopa_bck_t_doc
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_provc_id_idx ON pagopa_bck_t_doc
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_elab_id_idx ON pagopa_bck_t_doc
  USING btree (pagopa_elab_id);
  

  
  
  
insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'TRASMESSO',
 'TRASMESSO DA EPAY',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='TRASMESSO');




insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'RIFIUTATO',
 'RIFIUTATO PER ERRORI IN FASE DI ACQUISIZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='RIFIUTATO');


insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO',
 'ELABORAZIONE IN CORSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_IN_CORSO');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_ER',
 'ELABORAZIONE IN CORSO CON ESITI ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_IN_CORSO_ER');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_SC',
 'ELABORAZIONE IN CORSO CON ESITI SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_IN_CORSO_SC');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_OK',
 'ELABORATO CON ESITO POSITIVO - DOCUMENTI EMESSI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_OK');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_KO',
 'ELABORATO CON ESITO ERRATO -  DOCUMENTI EMESSI - PRESENZA ERRORI - SCARTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_KO');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_ERRATO',
 'ELABORATO CON ESITO ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_ERRATO');


insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_SCARTATO',
 'ELABORATO CON ESITO SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_SCARTATO');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ANNULLATO',
 'ANNULLATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ANNULLATO');

-- siac_d_file_pagopa_stato

 
 
 
insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'TRASMESSO',
 'TRASMESSO DA EPAY',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='TRASMESSO');



insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'IN_ACQUISIZIONE',
 'ACQUISIZIONE IN CORSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='IN_ACQUISIZIONE');


 
 
 
insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ACQUISITO',
 'ACQUISITO IN ATTESA DI ELABORAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ACQUISITO');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'RIFIUTATO',
 'RIFIUTATO PER ERRORI IN FASE DI ACQUISIZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='RIFIUTATO');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO',
 'ELABORAZIONE IN CORSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_IN_CORSO');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_ER',
 'ELABORAZIONE IN CORSO CON ESITI ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_IN_CORSO_ER');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_SC',
 'ELABORAZIONE IN CORSO CON ESITI SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_IN_CORSO_SC');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_OK',
 'ELABORATO CON ESITO POSITIVO -  DOCUMENTI EMESSI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_OK');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_KO',
 'ELABORATO CON ESITO ERRATO -  DOCUMENTI EMESSI - PRESENZA ERRORI - SCARTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_KO');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_ERRATO',
 'ELABORATO CON ESITO ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_ERRATO');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_SCARTATO',
 'ELABORATO CON ESITO SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_SCARTATO');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ANNULLATO',
 'ANNULLATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ANNULLATO');
 
 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '1','ANNULLATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='1');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '2','SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='2');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '3','ERRORE GENERICO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='3');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '4','FILE NON ESISTENTE O STATO NON RICHIESTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='4');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '5','FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='5');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '6','DATI DI RICONCILIAZIONE NON PRESENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='6');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '7','DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='7');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '8','DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='8');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '9','DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='9');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '10','DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='10');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '11','DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='11');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '12','DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='12');



insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '13','DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='13');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '14','DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='14');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '15','DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='15');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '16','DATI DI RICONCILIAZIONE SENZA IMPORTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='16');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '17','ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='17');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '18','ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='18');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '19','ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='19');



insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '20','DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='20');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '21','ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='21');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '22','DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='22');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '23','DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='23');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '24','TIPO DOCUMENTO IPA NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='24');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '25','BOLLO ESENTE NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='25');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '26','ERRORE IN LETTURA ID. STATO DOCUMENTO VALIDO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='26');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '27','ERRORE IN LETTURA ID. TIPO CDC-CDR',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='27');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '28','IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='28');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '29','IDENTIFICATIVI VARI INESISTENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='29');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '30','ERRORE IN FASE DI INSERIMENTO DOCUMENTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='30');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '31','ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='31');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '32','ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='32');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '33','DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='33');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '34','DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='34');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '35','DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='35');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '36','DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='36');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '37','ERRORE IN LETTURA PROGRESSIVI DOCUMENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='37');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '38','DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='38');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '39','PROVVISORIO DI CASSA REGOLARIZZATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='39');
 
 
 
drop FUNCTION if exists fnc_pagopa_t_elaborazione_riconc_aggiorna_elab 
(
  pagoPaElabId            integer,
  pagoPaElabFileXMLId     varchar,
  pagoPaElabFileOra       varchar,
  pagoPaElabFileEnte      varchar,
  pagoPaElabFileFruitore  varchar,
  pagoPaElabFileStatoCode varchar,
  dataChiusuraElab        timestamp,
  enteProprietarioId      integer,
  loginoperazione         varchar,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
);

drop FUNCTION if exists fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out pagopaBckSubdoc             BOOLEAN,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

drop FUNCTION if exists fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc
(
  docId                           integer,
  filePagoPaElabId                integer,
  enteProprietarioId	          integer,
  loginOperazione                 varchar,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

drop FUNCTION if exists fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

drop FUNCTION if exists fnc_pagopa_t_elaborazione_riconc_insert
(
  filepagopaid integer,
  filepagopaFileXMLId     varchar,
  filepagopaFileOra       varchar,
  filepagopaFileEnte      varchar,
  filepagopaFileFruitore  varchar,
  inPagoPaElabId          integer,
  annoBilancioElab        integer,
  enteproprietarioid      integer,
  loginoperazione         varchar,
  dataelaborazione        timestamp,
  out outPagoPaElabId     integer,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
);

drop FUNCTION if exists fnc_pagopa_t_elaborazione_riconc
(
  enteproprietarioid      integer,
  loginoperazione         varchar,
  dataelaborazione        timestamp,
  out outPagoPaElabId     integer,
  out outPagoPaElabPrecId     integer,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
);



CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_aggiorna_elab
(
  pagoPaElabId            integer,
  pagoPaElabFileXMLId     varchar,
  pagoPaElabFileOra       varchar,
  pagoPaElabFileEnte      varchar,
  pagoPaElabFileFruitore  varchar,
  pagoPaElabFileStatoCode varchar,
  dataChiusuraElab        timestamp,
  enteProprietarioId      integer,
  loginoperazione         varchar,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult integer:=null;


BEGIN

	strMessaggioFinale:='Aggiornamento elaborazione PAGOPA per pagopa_elab_id='||pagoPaElabId::varchar
                      ||'. PagoPaElabStatoCode='||coalesce(pagoPaElabFileStatoCode,' ')||'.';

    codiceRisultato:=0;
    messaggioRisultato:='';

    codResult:=null;
    strmessaggio:='Verifica esistenza elaborazione.';
	select 1 into codResult
    from pagopa_t_elaborazione elab
    where     elab.pagopa_elab_id=pagoPaElabId
    and       elab.data_cancellazione is null
    and       elab.validita_fine is null;

    if codResult is null then
    	RAISE EXCEPTION ' NON EFFETTUATO.Elaborazione non esistente.';
    end if;


    strmessaggio:='Aggiornamento [pagopa_t_elaborazione].';
    codResult:=null;
    update pagopa_t_elaborazione elab
    set    pagopa_elab_file_id= (case when coalesce(pagoPaElabFileXMLId,'')='' then elab.pagopa_elab_file_id
                                      else pagoPaElabFileXMLId end ),
           pagopa_elab_file_ora=(case when coalesce(pagoPaElabFileOra,'')='' then elab.pagopa_elab_file_ora
                                      else pagoPaElabFileOra end ),
           pagopa_elab_file_ente=(case when coalesce(pagoPaElabFileEnte,'')='' then elab.pagopa_elab_file_ente
                                      else pagoPaElabFileEnte end ),
           pagopa_elab_file_fruitore=(case when coalesce(pagoPaElabFileFruitore,'')='' then elab.pagopa_elab_file_fruitore
                                      else pagoPaElabFileFruitore end ),
    	   pagopa_elab_stato_id=(case when coalesce(pagoPaElabFileStatoCode,'')='' then elab.pagopa_elab_stato_id
                                      else (select stato.pagopa_elab_stato_id
                                            from pagopa_d_elaborazione_stato stato
                                            where stato.ente_proprietario_id=enteProprietarioId
                                            and   stato.pagopa_elab_stato_code=pagoPaElabFileStatoCode) end ),
           login_operazione=elab.login_operazione||'-'||loginOperazione,
           validita_fine=(case when dataChiusuraElab is null then null
                          else dataChiusuraElab end),
		   data_modifica=now()
    where elab.pagopa_elab_id=pagoPaElabId
    and   elab.data_cancellazione is null
    and   elab.validita_fine is null
    returning elab.pagopa_elab_id into codResult;

    if codResult is null then
    	RAISE EXCEPTION ' NON EFFETTUATO.Verificare.';
    end if;

	-- verificare quando fare chiusura della siac_t_file_pagopa

    messaggioRisultato:=upper(strMessaggioFinale||' Effettuato.');
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


CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out pagopaBckSubdoc             BOOLEAN,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):='';
	strMessaggioBck VARCHAR(2500):='';
    strMessaggioLog VARCHAR(2500):='';
	strMessaggioFinale VARCHAR(2500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(10):='';
	codResult integer:=null;


	PagoPaRecClean record;
    AggRec record;

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA


begin

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' Pulizia documenti creati per provvisori in errore-non completi.';
    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale;
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
	raise notice 'strMessaggioFinale=%',strMessaggioFinale;
    codiceRisultato:=0;
    messaggioRisultato:='';
    pagopaBckSubdoc:=false;

    strMessaggio:='Inizio ciclo su pagopa_t_riconciliazione_doc.';
  --        raise notice 'strMessaggio=%',strMessaggio;

    for PagoPaRecClean in
    (
     select doc.pagopa_ric_doc_provc_id pagopa_provc_id,
            flusso.pagopa_elab_flusso_anno_esercizio pagopa_anno_esercizio,
            flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
            flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio
     from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
	 and   doc.pagopa_ric_doc_subdoc_id is not null
	 and   doc.pagopa_ric_doc_stato_elab='S'
	 and   exists
	 (
      select 1
	  from  pagopa_t_elaborazione_flusso flusso1, pagopa_t_riconciliazione_doc doc1
	  where flusso1.pagopa_elab_id=flusso.pagopa_elab_id
	  and   flusso1.pagopa_elab_flusso_anno_esercizio=flusso.pagopa_elab_flusso_anno_esercizio
	  and   flusso1.pagopa_elab_flusso_anno_provvisorio=flusso.pagopa_elab_flusso_anno_provvisorio
	  and   flusso1.pagopa_elab_flusso_num_provvisorio=flusso.pagopa_elab_flusso_num_provvisorio
	  and   doc1.pagopa_elab_flusso_id=flusso1.pagopa_elab_flusso_id
	  and   doc1.pagopa_ric_doc_subdoc_id is null
	  and   doc1.pagopa_ric_doc_stato_elab!='S'
	  and   flusso1.data_cancellazione is null
	  and   flusso1.validita_fine is null
	  and   doc1.data_cancellazione is null
	  and   doc1.validita_fine is null
	 ) -- per provvisorio scarti,non elaborati o errori
     and flusso.data_cancellazione is null
	 and flusso.validita_fine is null
	 and doc.data_cancellazione is null
	 and doc.validita_fine is null
	 order by 2,3,4
	)
    loop

	  codResult:=null;
      -- tabelle backup
      -- pagopa_bck_t_subdoc
      --  raise notice '@@@@@@@@@@@@@@@@@@@@ strMessaggio=%',strMessaggio;
      strMessaggio:='In ciclo su pagopa_t_riconciliazione_doc. Per provvisorio di cassa Prov. '
                  ||PagoPaRecClean.pagopa_anno_provvisorio::varchar||'/'||PagoPaRecClean.pagopa_num_provvisorio::varchar
                  ||' provcId='||PagoPaRecClean.pagopa_provc_id::varchar||'.';
      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
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

      strMessaggioBck:=strMessaggio;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc.';
      insert into pagopa_bck_t_subdoc
      (
        pagopa_provc_id,
        pagopa_elab_id,
        subdoc_id,
        subdoc_numero,
        subdoc_desc,
        subdoc_importo,
        subdoc_nreg_iva,
        subdoc_data_scadenza,
        subdoc_convalida_manuale,
        subdoc_importo_da_dedurre,
        subdoc_splitreverse_importo,
        subdoc_pagato_cec,
        subdoc_data_pagamento_cec,
        contotes_id,
        dist_id,
        comm_tipo_id,
        doc_id,
        subdoc_tipo_id,
        notetes_id,
        bck_validita_inizio,
        bck_validita_fine,
        bck_data_creazione,
        bck_data_modifica,
        bck_data_cancellazione,
        bck_login_operazione,
        bck_login_creazione,
        bck_login_modifica,
        bck_login_cancellazione,
        siope_tipo_debito_id,
        siope_assenza_motivazione_id,
        siope_scadenza_motivo_id,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
      )
      select
        PagoPaRecClean.pagopa_provc_id,
        filePagoPaElabId,
        sub.subdoc_id,
        sub.subdoc_numero,
        sub.subdoc_desc,
        sub.subdoc_importo,
        sub.subdoc_nreg_iva,
        sub.subdoc_data_scadenza,
        sub.subdoc_convalida_manuale,
        sub.subdoc_importo_da_dedurre,
        sub.subdoc_splitreverse_importo,
        sub.subdoc_pagato_cec,
        sub.subdoc_data_pagamento_cec,
        sub.contotes_id,
        sub.dist_id,
        sub.comm_tipo_id,
        sub.doc_id,
        sub.subdoc_tipo_id,
        sub.notetes_id,
        sub.validita_inizio,
        sub.validita_fine,
        sub.data_creazione,
        sub.data_modifica,
        sub.data_cancellazione,
        sub.login_operazione,
        sub.login_creazione,
        sub.login_modifica,
        sub.login_cancellazione,
        sub.siope_tipo_debito_id,
        sub.siope_assenza_motivazione_id,
        sub.siope_scadenza_motivo_id,
        clock_timestamp(),
        sub.ente_proprietario_id,
        loginOperazione
      from siac_t_subdoc sub,siac_r_doc_stato rs, siac_d_doc_stato stato,
	   	   pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc ric
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   ric.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   ric.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   ric.pagopa_ric_doc_stato_elab='S'
      and   sub.subdoc_id=ric.pagopa_ric_doc_subdoc_id
      and   rs.doc_id=sub.doc_id
      and   stato.doc_stato_id=rs.doc_stato_id
      and   stato.doc_stato_code not in ('A','ST','EM')
      and   not exists
      (
        select 1
        from siac_r_subdoc_ordinativo_ts rsub
        where rsub.subdoc_id=sub.subdoc_id
        and   rsub.data_cancellazione is null
        and   rsub.validita_fine is null
      )
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null
     -- and   sub.data_cancellazione is null
     -- and   sub.validita_fine is null
      and   rs.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())));
      GET DIAGNOSTICS codResult = ROW_COUNT;

      if pagopaBckSubdoc=false and coalesce(codResult,0) !=0 then
      	pagopaBckSubdoc:=true;
      end if;

	  -- pagopa_bck_t_subdoc_attr
      strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_attr.';
      insert into pagopa_bck_t_subdoc_attr
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_attr_id,
          subdoc_id,
          attr_id,
          tabella_id,
          boolean,
          percentuale,
          testo,
          numerico,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_attr_id,
          r.subdoc_id,
          r.attr_id,
          r.tabella_id,
          r.boolean,
          r.percentuale,
          r.testo,
          r.numerico,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          r.ente_proprietario_id,
          loginOperazione
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_attr r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_atto_amm
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_atto_amm.';
      insert into pagopa_bck_t_subdoc_atto_amm
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_atto_amm_id,
          subdoc_id,
          attoamm_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_atto_amm_id,
          r.subdoc_id,
          r.attoamm_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_atto_amm r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_prov_cassa
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_prov_cassa.';

      insert into pagopa_bck_t_subdoc_prov_cassa
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_provc_id,
          subdoc_id,
          provc_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_provc_id,
          r.subdoc_id,
          r.provc_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_prov_cassa r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_movgest_ts
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_movgest_ts.';

      insert into pagopa_bck_t_subdoc_movgest_ts
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_movgest_ts_id,
          subdoc_id,
          movgest_ts_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_movgest_ts_id,
          r.subdoc_id,
          r.movgest_ts_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_movgest_ts r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc.';
      insert into pagopa_bck_t_doc
      (
          pagopa_provc_id,
          pagopa_elab_id,
          doc_id,
          doc_anno,
          doc_numero,
          doc_desc,
          doc_importo,
          doc_beneficiariomult,
          doc_data_emissione,
          doc_data_scadenza,
          doc_tipo_id,
          codbollo_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          bck_login_creazione,
          bck_login_modifica,
          bck_login_cancellazione,
          pcccod_id,
          pccuff_id,
          doc_collegato_cec,
          doc_contabilizza_genpcc,
          siope_documento_tipo_id,
          siope_documento_tipo_analogico_id,
          doc_sdi_lotto_siope,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select distinct
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.doc_id,
          r.doc_anno,
          r.doc_numero,
          r.doc_desc,
          r.doc_importo,
          r.doc_beneficiariomult,
          r.doc_data_emissione,
          r.doc_data_scadenza,
          r.doc_tipo_id,
          r.codbollo_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          r.login_creazione,
          r.login_modifica,
          r.login_cancellazione,
          r.pcccod_id,
          r.pccuff_id,
          r.doc_collegato_cec,
          r.doc_contabilizza_genpcc,
          r.siope_documento_tipo_id,
          r.siope_documento_tipo_analogico_id,
          r.doc_sdi_lotto_siope,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_t_doc r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=sub.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


	  -- pagopa_bck_t_doc_stato
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_stato.';
      insert into pagopa_bck_t_doc_stato
      (
          pagopa_provc_id,
          pagopa_elab_id,
          doc_stato_r_id,
          doc_id,
          doc_stato_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_stato_r_id,
          r.doc_id,
          r.doc_stato_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_stato r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


	  -- pagopa_bck_t_subdoc_num
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_num.';
      insert into pagopa_bck_t_subdoc_num
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_num_id,
          doc_id,
          subdoc_numero,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.subdoc_num_id,
          r.doc_id,
          r.subdoc_numero,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_t_subdoc_num r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


      -- pagopa_bck_t_doc_sog
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_sog.';
      insert into pagopa_bck_t_doc_sog
      (
         pagopa_provc_id,
         pagopa_elab_id,
         doc_sog_id,
         doc_id,
         soggetto_id,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_sog_id,
          r.doc_id,
          r.soggetto_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_sog r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc_attr
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_attr.';

      insert into pagopa_bck_t_doc_attr
      (
         pagopa_provc_id,
         pagopa_elab_id,
         doc_attr_id,
         doc_id,
         attr_id,
         tabella_id,
         boolean,
         percentuale,
         testo,
         numerico,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_attr_id,
          r.doc_id,
          r.attr_id,
          r.tabella_id,
          r.boolean,
          r.percentuale,
          r.testo,
          r.numerico,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_attr r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc_class
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_class.';

      insert into pagopa_bck_t_doc_class
      (
      	 pagopa_provc_id,
         pagopa_elab_id,
         doc_classif_id,
         doc_id,
         classif_id,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_classif_id,
          r.doc_id,
          r.classif_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_class r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_registrounico_doc
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_registrounico_doc.';

      insert into pagopa_bck_t_registrounico_doc
      (
         pagopa_provc_id,
         pagopa_elab_id,
         rudoc_id,
         rudoc_registrazione_anno,
         rudoc_registrazione_numero,
         rudoc_registrazione_data,
         doc_id,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.rudoc_id,
          r.rudoc_registrazione_anno,
          r.rudoc_registrazione_numero,
          r.rudoc_registrazione_data,
          r.doc_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_t_registrounico_doc r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


   	  -- aggiornare importo documenti collegati
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Aggiornamento importo documenti.';

      update siac_t_doc doc
      set    doc_importo=doc.doc_importo-coalesce(query.subdoc_importo,0),
             data_modifica=clock_timestamp(),
             login_operazione=doc.login_operazione||'-'||loginOperazione
      from
      (
      select sub.doc_id,coalesce(sum(sub.subdoc_importo),0) subdoc_importo
      from siac_t_subdoc sub, pagopa_bck_t_doc pagodoc, pagopa_bck_t_subdoc pagosubdoc
      where pagodoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagodoc.pagopa_elab_id=filePagoPaElabId
      and   pagosubdoc.pagopa_provc_id=pagodoc.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=pagodoc.pagopa_elab_id
      and   pagosubdoc.doc_id=pagodoc.doc_id
      and   sub.subdoc_id=pagosubdoc.subdoc_id
      and   pagodoc.data_cancellazione is null
      and   pagodoc.validita_fine is null
      and   pagosubdoc.data_cancellazione is null
      and   pagosubdoc.validita_fine is null
      and   sub.data_cancellazione is null
      and   sub.validita_fine is null
      group by sub.doc_id
      ) query
      where doc.ente_proprietario_id=enteProprietarioId
      and   doc.doc_id=query.doc_id
      and   exists
      (
      select 1
      from pagopa_bck_t_doc pagodoc1, pagopa_bck_t_subdoc pagosubdoc1
      where pagodoc1.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagodoc1.pagopa_elab_id=filePagoPaElabId
      and   pagodoc1.doc_id=doc.doc_id
      and   pagosubdoc1.pagopa_provc_id=pagodoc1.pagopa_provc_id
      and   pagosubdoc1.pagopa_elab_id=pagodoc1.pagopa_elab_id
      and   pagosubdoc1.doc_id=pagodoc1.doc_id
      and   pagodoc1.data_cancellazione is null
      and   pagodoc1.validita_fine is null
      and   pagosubdoc1.data_cancellazione is null
      and   pagosubdoc1.validita_fine is null
      )
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;


      -- cancellare quote documenti collegati
  	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_attr].';

      -- siac_r_subdoc_attr
      delete from siac_r_subdoc_attr r
      using pagopa_bck_t_subdoc_attr pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_attr_id=pagosubdoc.subdoc_attr_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
 --     and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_atto_amm].';
      -- siac_r_subdoc_atto_amm
      delete from siac_r_subdoc_atto_amm r
      using pagopa_bck_t_subdoc_atto_amm pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_atto_amm_id=pagosubdoc.subdoc_atto_amm_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_prov_cassa].';

      -- siac_r_subdoc_prov_cassa
      delete from siac_r_subdoc_prov_cassa r
      using pagopa_bck_t_subdoc_prov_cassa pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_provc_id=pagosubdoc.subdoc_provc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_movgest_ts].';

      -- siac_r_subdoc_movgest_ts
      delete from siac_r_subdoc_movgest_ts r
      using pagopa_bck_t_subdoc_movgest_ts pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_movgest_ts_id=pagosubdoc.subdoc_movgest_ts_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_t_subdoc].';

      -- siac_t_subdoc
      delete from siac_t_subdoc r
      using pagopa_bck_t_subdoc pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_id=pagosubdoc.subdoc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;


	  -- cancellazione su documenti senza quote
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_sog].';

      -- siac_r_doc_sog

      delete from siac_r_doc_sog r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_sog pagopaDel
      where r.doc_sog_id=pagopaDel.doc_sog_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
     -- and   sub.data_cancellazione is null
     -- and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_stato].';

      -- siac_r_doc_stato
      delete from siac_r_doc_stato r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_stato pagopaDel
      where r.doc_stato_id=pagopaDel.doc_stato_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
   --   and   sub.data_cancellazione is null
--      and   sub.validita_fine is null
      );


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_attr].';

      -- siac_r_doc_attr
      delete from siac_r_doc_attr r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_attr pagopaDel
      where r.doc_attr_id=pagopaDel.doc_attr_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
    --  and   sub.data_cancellazione is null
    --  and   sub.validita_fine is null
      );


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_class].';

      -- siac_r_doc_class
      delete from siac_r_doc_class r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_class pagopaDel
      where r.doc_classif_id=pagopaDel.doc_classif_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
    --  and   sub.data_cancellazione is null
    --  and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_registrounico_doc].';

      -- siac_t_registrounico_doc
      delete from siac_t_registrounico_doc r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_registrounico_doc pagopaDel
      where r.rudoc_id=pagopaDel.rudoc_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
   --   and   sub.data_cancellazione is null
   --   and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_subdoc_num].';

      -- siac_t_subdoc_num
      delete from siac_t_subdoc_num r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_subdoc_num pagopaDel
      where r.subdoc_num_id=pagopaDel.subdoc_num_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
  --    and   sub.data_cancellazione is null
  --    and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_doc].';

      -- siac_t_doc
      delete from siac_t_doc r
      using pagopa_bck_t_doc pagopaDel
      where r.doc_id=pagopaDel.doc_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopaDel.doc_id
  --    and   sub.data_cancellazione is null
  --    and   sub.validita_fine is null
      );


      strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Aggiornamento stato documenti rimanenti in vita.';
      -- aggiornamento stato documenti per rimanenti in vita con quote
      -- esecuzione fnc per
      select
       fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc
	   (
		pagopadoc.doc_id,
        filePagoPaElabId,
		enteProprietarioId,
		loginOperazione
		) into AggRec
	  from pagopa_bck_t_doc pagopadoc, pagopa_bck_t_subdoc pagopasub
      where pagopadoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopadoc.pagopa_elab_id=filePagoPaElabId
      and   pagopasub.pagopa_provc_id=pagopadoc.pagopa_provc_id
      and   pagopasub.pagopa_elab_id=pagopadoc.pagopa_elab_id
      and   pagopasub.doc_id=pagopadoc.doc_id
      and   pagopadoc.data_cancellazione is null
      and   pagopadoc.validita_fine is null
      and   pagopasub.data_cancellazione is null
      and   pagopasub.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - Fine cancellazione doc. - '||strMessaggioFinale;
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

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||'Aggiornamento  pagopa_t_riconciliazione.';

      -- aggiornare pagopa_t_riconciliazione
      update pagopa_t_riconciliazione ric
      set    pagopa_ric_flusso_stato_elab='X',
             data_modifica=clock_timestamp(),
             pagopa_ric_errore_id=errore.pagopa_ric_errore_id
      from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc,
           pagopa_d_riconciliazione_errore errore, pagopa_bck_t_subdoc pagopa
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.pagopa_ric_doc_stato_elab='S'
      and   doc.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.subdoc_id=doc.pagopa_ric_doc_subdoc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   ric.pagopa_ric_id=doc.pagopa_ric_id
      and   errore.ente_proprietario_id=flusso.ente_proprietario_id
      and   errore.pagopa_ric_errore_code=PAGOPA_ERR_36
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
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
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||'Aggiornamento  pagopa_t_riconciliazione_doc.';
      -- aggiornare pagopa_t_riconciliazione_doc
      update pagopa_t_riconciliazione_doc doc
      set    pagopa_ric_doc_stato_elab='X',
             pagopa_ric_doc_subdoc_id=null,
             pagopa_ric_doc_provc_id=null,
             pagopa_ric_doc_movgest_ts_id=null,
             data_modifica=clock_timestamp(),
             pagopa_ric_errore_id=errore.pagopa_ric_errore_id
      from pagopa_t_elaborazione_flusso flusso,
           pagopa_d_riconciliazione_errore errore, pagopa_bck_t_subdoc pagopa
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.pagopa_ric_doc_stato_elab='S'
      and   doc.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.subdoc_id=doc.pagopa_ric_doc_subdoc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   errore.ente_proprietario_id=flusso.ente_proprietario_id
      and   errore.pagopa_ric_errore_code=PAGOPA_ERR_36
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
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

  end loop;

  /* sostituito con diagnostic dopo insert tabella
  strMessaggio:=' Verifica esistenza in pagopa_bck_t_subdoc a termine aggiornamento.';
  select (case when count(*)!=0 then true else false end ) into pagopaBckSubdoc
  from pagopa_bck_t_subdoc bck
  where bck.pagopa_elab_id=filePagoPaElabId
  and   bck.data_cancellazione is null
  and   bck.validita_fine is null;*/



  messaggioRisultato:='OK - '||upper(strMessaggioFinale);

  strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||messaggioRisultato;
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


CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc
(
  docId                           integer,
  filePagoPaElabId                integer,
  enteProprietarioId	          integer,
  loginOperazione                 varchar,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioLog VARCHAR(2500):='';

 codResult integer:=null;
 statoDoc  varchar:=null;


begin

  codicerisultato:=0;
  messaggiorisultato:='';

  strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                      'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                      ' Aggiornamento stato documento docId='||docId::varchar||'.';
  strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc - '||strMessaggioFinale;
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

  strMessaggio:=' Verifica esistenza documento.';
  select 1 into codResult
  from siac_t_subdoc sub, siac_t_doc doc
  where doc.doc_id=docId
  and   sub.doc_id=doc.doc_id
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null
  and   sub.data_cancellazione is null
  and   sub.validita_fine is null;
  if codResult is null then
  	strMessaggio:=strMessaggio||' Non esistente.';
    codiceRisultato:=-1;
    messaggioRisultato:=strMessaggioFinale||' '||strMessaggio;
    return;
  end if;

  strMessaggio:=' Verifica esistenza quote incassate per stato EM.';
  codResult:=null;
  select 1 into codResult
  from siac_t_subdoc sub, siac_r_subdoc_ordinativo_ts rts,
       siac_t_ordinativo_ts ts, siac_t_ordinativo ord,  siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
  where sub.doc_id=docId
  and   rts.subdoc_id=sub.subdoc_id
  and   ts.ord_ts_id=rts.ord_ts_id
  and   ord.ord_id=ts.ord_id
  and   rs.ord_id=ord.ord_id
  and   stato.ord_stato_id=rs.ord_stato_id
  and   stato.ord_stato_code!='A'
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   rts.data_cancellazione is null
  and   rts.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   sub.data_cancellazione is null
  and   sub.validita_fine is null;
  if codResult is not null then
  	statoDoc:='EM';
  end if;

  strMessaggio:=' Verifica esistenza quote incassate per stato PE.';
  if codResult is not null	 then
   codResult:=null;
   select 1 into codResult
   from siac_t_subdoc sub
   where sub.doc_id=docId
   and   not exists
   (select 1
    from siac_r_subdoc_ordinativo_ts rts,
         siac_t_ordinativo_ts ts, siac_t_ordinativo ord,  siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
    where rts.subdoc_id=sub.subdoc_id
    and   ts.ord_ts_id=rts.ord_ts_id
    and   ord.ord_id=ts.ord_id
    and   rs.ord_id=ord.ord_id
    and   stato.ord_stato_id=rs.ord_stato_id
    and   stato.ord_stato_code!='A'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   rts.data_cancellazione is null
    and   rts.validita_fine is null
    and   ord.data_cancellazione is null
    and   ord.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
   )
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null;
   if codResult is not null then
   	statoDoc:='PE';
   end if;
  end if;

  if statoDoc is null then
    strMessaggio:=' Verifica esistenza quote incassate per stati V,I.';
  	codResult:=null;
    select 1 into codResult
    from siac_t_subdoc sub,siac_r_subdoc_movgest_ts rmov, siac_t_movgest_ts ts, siac_t_movgest mov,
         siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
    where sub.doc_id=docId
    and   rmov.subdoc_id=sub.subdoc_id
    and   ts.movgest_ts_id=rmov.movgest_ts_id
    and   mov.movgest_id=ts.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   rmov.data_cancellazione is null
    and   rmov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   sub.data_cancellazione is null
    and   sub.validita_fine is null;
    if codResult is null then
    	statoDoc:='I';
    else
    	statoDoc:='V';
    end if;
  end if;

  if statoDoc is not null then
    strMessaggio:=' Chiusura stato precedente.';
    codResult:=null;
  	update siac_r_doc_stato rs
    set    data_cancellazione=clock_timestamp(),
           validita_fine=clock_timestamp(),
           login_operazione=rs.login_operazione||'-'||loginOperazione
    where rs.doc_id=docId
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    returning rs.doc_stato_r_id into codResult;
    if codResult is not null then
     codResult:=null;
     strMessaggio:=' Inserimento nuovo stato='||statoDoc||'.';
     insert into siac_r_doc_stato
     (
    	doc_id,
        doc_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select docId,
            stato.doc_stato_id,
            clock_timestamp(),
            loginOperazione,
            stato.ente_proprietario_id
     from siac_d_doc_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.doc_stato_code=statoDoc
     returning doc_stato_r_id into codResult;
   end if;

   if codResult is not null then
    strMessaggio:=strMessaggio||' Effettuato.';
   else
   	codiceRisultato:=-1;
    strMessaggio:=strMessaggio||' Non effettuato.';
   end if;
  else
     codiceRisultato:=-1;
     strMessaggio:=strMessaggio||' Nuovo stato non determinato.';
  end if;

  messaggioRisultato:=upper(strMessaggioFinale||' '||strMessaggio);
  strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc - '||messaggioRisultato;
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
            null,
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


CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_insert
(
  filepagopaid integer,
  filepagopaFileXMLId     varchar,
  filepagopaFileOra       varchar,
  filepagopaFileEnte      varchar,
  filepagopaFileFruitore  varchar,
  inPagoPaElabId          integer,
  annoBilancioElab        integer,
  enteproprietarioid      integer,
  loginoperazione         varchar,
  dataelaborazione        timestamp,
  out outPagoPaElabId     integer,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
    strMessaggioBck  VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
    strMessaggioLog VARCHAR(2500):='';
	codResult integer:=null;
	annoBilancio integer:=null;

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

    PAGOPA_ERR_40   CONSTANT  varchar :='40';--PROVVISORIO DI CASSA REGOLARIZZATO

    filePagoPaElabId integer:=null;

    pagoPaFlussoAnnoEsercizio integer:=null;
    pagoPaFlussoNomeMittente  varchar(500):=null;
    pagoPaFlussoData  varchar(50):=null;
    pagoPaFlussoTotPagam  numeric:=null;

    pagoPaFlussoRec record;

    pagopaElabFlussoId integer:=null;
    strNote varchar(500):=null;

    bilancioId integer:=null;
    periodoid integer:=null;
    pagoPaErrCode varchar(10):=null;

BEGIN

    if coalesce(filepagopaFileXMLId,'')='' THEN
     strMessaggioFinale:='Elaborazione PAGOPA per file_pagopa_id='||filepagopaid::varchar||'.';
    else
	 strMessaggioFinale:='Elaborazione PAGOPA per file_pagopa_id='||filepagopaid::varchar
                       ||' filepagopaFileXMLId='||coalesce(filepagopaFileXMLId,' ')||'.';
    end if;

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale;
    raise notice 'strMessaggioLog=% ',strMessaggioLog;
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
     inPagoPaElabId,
     filepagopaid,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

   	outPagoPaElabId:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';

    if coalesce(inPagoPaElabId,0)!=0 then
    	outPagoPaElabId:=inPagoPaElabId;
        filePagoPaElabId:=inPagoPaElabId;
    end if;


    ---------- inizio controlli su siac_t_file_pagopa e piano_t_riconciliazione  --------------------------------
	-- verifica esistenza file_pagopa per filePagoPaId passato
    -- un file XML puo essere in stato
    -- ACQUISITO - dati XML flussi caricati - pronti per inizio elaborazione
    -- ELABORATO_IN_CORSO* - dati XML flussi caricati - elaborazione in corso
    -- ELABORATO_OK - dati XML flussi elaborati e conclusi correttamente
    -- ANNULLATO, RIFIUTATO  - errore - file chiuso

   strMessaggio:='Verifica esistenza filePagoPa da elaborare per filePagoPaid e filepagopaFileXMLId.';
   codResult:=null;
   select 1 into codResult
   from siac_t_file_pagopa pagopa,siac_d_file_pagopa_stato stato
   where pagopa.file_pagopa_id=filePagoPaId
   and   pagopa.file_pagopa_code=(case when coalesce(filepagopaFileXMLId,'')!='' then filepagopaFileXMLId
                                 else pagopa.file_pagopa_code end )
   and   stato.file_pagopa_stato_id=pagopa.file_pagopa_stato_id
   and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
   and   pagopa.data_cancellazione is null
   and   pagopa.validita_fine is null;

   if codResult is  null then
      -- errore bloccante
      strErrore:=' File non esistente o in stato differente.Verificare.';
      codiceRisultato:=-1;
      --outPagoPaElabId:=-1;
      messaggioRisultato:=strMessaggioFinale||strMessaggio||strErrore;
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
      raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
       inPagoPaElabId,
       filepagopaid,
       strMessaggioLog,
	   enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      return;
   end if;


   if codResult is null then
     strMessaggio:='Verifica esistenza filePagoPa  elaborato per filePagoPaid e filepagopaFileXMLId.';
     select 1 into codResult
     from siac_t_file_pagopa pagopa,siac_d_file_pagopa_stato stato
     where pagopa.file_pagopa_id=filePagoPaId
     and   pagopa.file_pagopa_code=(case when coalesce(filepagopaFileXMLId,'')!='' then filepagopaFileXMLId
                                   else pagopa.file_pagopa_code end )
     and   stato.file_pagopa_stato_id=pagopa.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code=ELABORATO_OK_ST
     and   pagopa.data_cancellazione is null;
     if codResult is not null then
      -- errore bloccante
      strErrore:=' File gia'' elaborato.Verificare.';
      codiceRisultato:=-1;
      -- pagoPaElabId:=-1;
      messaggioRisultato:=strMessaggioFinale||strMessaggio||strErrore;
      messaggioRisultato:=strMessaggioFinale||strMessaggio||strErrore;
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
      raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
       inPagoPaElabId,
       filepagopaid,
       strMessaggioLog,
	   enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );
      return;
     end if;
   end if;


   codResult:=null;
   if coalesce(filepagopaFileXMLId,'')!=''  then
      strMessaggio:='Verifica univocita'' file filepagopaFileXMLId.';
      select count(*) into codResult
      from siac_t_file_pagopa pagopa,siac_d_file_pagopa_stato stato
      where pagopa.file_pagopa_code=filepagopaFileXMLId
      and   stato.file_pagopa_stato_id=pagopa.file_pagopa_stato_id
      and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
      and   pagopa.data_cancellazione is null
      and   pagopa.validita_fine is null;

      if codResult is not null and codResult>1 then
          strErrore:=' File caricato piu'' volte. Verificare.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_5;
      else codResult:=null;
      end if;
   end if;

   if codResult is null then
        -- errore bloccante
        strMessaggio:='Verifica esistenza pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;

		if codResult is null then
        	codResult:=-1;
            strErrore:=' Non esistente.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_6;
        else codResult:=null;
        end if;

		-- errore bloccante
		if codResult is null then
         strMessaggio:='Verifica esistenza pagopa_t_riconciliazione da elaborare.';
    	 select 1 into codResult
         from pagopa_t_riconciliazione ric
         where ric.file_pagopa_id=filePagoPaId
         and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
         /*and   not exists
         (select 1
          from pagopa_t_riconciliazione_doc doc
          where doc.pagopa_ric_id=ric.pagopa_ric_id
          and   doc.pagopa_ric_doc_subdoc_id is not null
          and   doc.data_cancellazione is null
          and   doc.validita_fine is null
         )*/
         /*and   not exists
         (select 1
          from pagopa_t_riconciliazione_doc doc
          where doc.pagopa_ric_id=ric.pagopa_ric_id
          and   doc.pagopa_ric_doc_subdoc_id is null
          and   doc.pagopa_ric_doc_stato_elab in ('E')
          and   doc.data_cancellazione is null
          and   doc.validita_fine is null
         )*/
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null;

         if codResult is null then
         	codResult:=-1;
            strErrore:=' Non esistente.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_7;
         else codResult:=null;
         end if;
        end if;
   end if;


   -- controlli correttezza del filepagopaFileXMLId in pagopa_t_riconciliazione
   if codResult is null and coalesce(filepagopaFileXMLId,'')!='' then
    strMessaggio:='Verifica congruenza filepagopaFileXMLId su pagopa_t_riconciliazione.';
    select count(distinct ric.file_pagopa_id) into codResult
   	from pagopa_t_riconciliazione ric
    where ric.pagopa_ric_file_id=filepagopaFileXMLId
    and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is null then
    	codResult:=-1;
        strErrore:=' File non presenti per identificativo.Verificare.';
    else
      if codResult >1 then
           codResult:=-1;
           strErrore:=' Esistenza diversi file presenti con stesso identificativo.Verificare.';
		   pagoPaErrCode:=PAGOPA_ERR_9;
      else codResult:=null;
      end if;
   end if;

  end if;

   -- errore bloccante - da verificare se possono in un file XML inserire dati di diversi anno_esercizio
   -- commentato in quanto anno_esercizio=annoProvvisorio univoco per flusso
   /*if codResult is null then
    	strMessaggio:='Verifica annoEsercizio su pagopa_t_riconciliazione.';
    	select count(distinct ric.pagopa_ric_flusso_anno_esercizio) into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if coalesce(codResult,0)>1 then
        	codResult:=-1;
            strErrore:=' Esistenza diversi annoEsercizio su dati riconciliazione.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_10;


            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';
	        update pagopa_t_riconciliazione ric
    	    set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	       data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='E',
            	   login_operazione=ric.login_operazione||'-'||loginOperazione
	        from pagopa_d_riconciliazione_errore err
    	    where ric.file_pagopa_id=filePagoPaId
            and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        	and   err.ente_proprietario_id=ric.ente_proprietario_id
	        and   err.pagopa_ric_errore_code=pagoPaErrCode
    	    and   ric.data_cancellazione is null
	        and   ric.validita_fine is null;

        else codResult:=null;
        end if;


    end if;*/

   -- errore bloccante
   if codResult is null then
    	strMessaggio:='Verifica annoEsercizio su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ric.pagopa_ric_flusso_anno_esercizio>annoBilancioElab
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza annoEsercizio su dati riconciliazione successivo ad annoBilancio di elab .Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_11;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';
            update pagopa_t_riconciliazione ric
    	    set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	       data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='E',
            	   login_operazione=ric.login_operazione||'-'||loginOperazione
	        from pagopa_d_riconciliazione_errore err
    	    where ric.file_pagopa_id=filePagoPaId
            and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
            and   ric.pagopa_ric_flusso_anno_esercizio>annoBilancioElab
        	and   err.ente_proprietario_id=ric.ente_proprietario_id
	        and   err.pagopa_ric_errore_code=pagoPaErrCode
    	    and   ric.data_cancellazione is null
	        and   ric.validita_fine is null;

        end if;


    end if;

    if codResult is null then
    	strMessaggio:='Lettura annoEsercizio su pagopa_t_riconciliazione.';
    	select distinct ric.pagopa_ric_flusso_anno_esercizio into annoBilancio
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null
        limit 1;
        if annoBilancio is  null or AnnoBilancio!=annoBilancioElab then
        	codResult:=-1;
            strErrore:=' Non effettuata .Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_12;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';
            update pagopa_t_riconciliazione ric
    	    set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	       data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='E',
            	   login_operazione=ric.login_operazione||'-'||loginOperazione
	        from pagopa_d_riconciliazione_errore err
    	    where ric.file_pagopa_id=filePagoPaId
            and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        	and   err.ente_proprietario_id=ric.ente_proprietario_id
	        and   err.pagopa_ric_errore_code=pagoPaErrCode
    	    and   ric.data_cancellazione is null
	        and   ric.validita_fine is null;

        end if;
    end if;

    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - controllo dati pagopa_t_riconciliazione - '||strMessaggioFinale;
    raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
       inPagoPaElabId,
       filepagopaid,
       strMessaggioLog,
	   enteProprietarioId,
       loginOperazione,
       clock_timestamp()
    );

    -- controlli campi obbligatori su pagopa_t_riconciliazione
    -- senza anno_esercizio
    if codResult is null then
    	strMessaggio:='Verifica annoEsercizio su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   coalesce(ric.pagopa_ric_flusso_anno_esercizio,0)=0
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza annoEsercizio.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_12;

           strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
	       and   coalesce(ric.pagopa_ric_flusso_anno_esercizio,0)=0
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;
        end if;
    end if;

    -- senza dati provvisori
    if codResult is null then
    	strMessaggio:='Verifica Provvisori di cassa su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ( coalesce(ric.pagopa_ric_flusso_anno_provvisorio,0)=0  or coalesce(ric.pagopa_ric_flusso_num_provvisorio,0)=0)
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza provvisorio di cassa.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_13;

           strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
           and   ( coalesce(ric.pagopa_ric_flusso_anno_provvisorio,0)=0  or coalesce(ric.pagopa_ric_flusso_num_provvisorio,0)=0)
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;


        end if;
    end if;


    -- senza accertamento
    if codResult is null then
    	strMessaggio:='Verifica Accertamenti su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ( coalesce(ric.pagopa_ric_flusso_anno_accertamento,0)=0  or coalesce(ric.pagopa_ric_flusso_num_accertamento,0)=0)
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza accertamento.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_14;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
           and   ( coalesce(ric.pagopa_ric_flusso_anno_accertamento,0)=0  or coalesce(ric.pagopa_ric_flusso_num_accertamento,0)=0)
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;
        end if;
    end if;

	-- senza voce/sottovoce
    if codResult is null then
    	strMessaggio:='Verifica Voci su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ( coalesce(ric.pagopa_ric_flusso_voce_code,'')=''  or coalesce(ric.pagopa_ric_flusso_sottovoce_code,'')='')
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza estremi voce/sottovoce.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_15;


            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
           and   ( coalesce(ric.pagopa_ric_flusso_voce_code,'')=''  or coalesce(ric.pagopa_ric_flusso_sottovoce_code,'')='')
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;

        end if;
    end if;

    -- senza importo
    if codResult is null then
    	strMessaggio:='Verifica importi su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   coalesce(ric.pagopa_ric_flusso_sottovoce_importo,0)=0
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza importo.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_16;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
           and   coalesce(ric.pagopa_ric_flusso_sottovoce_importo,0)=0
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;

        end if;
    end if;

    -- chiusura siac_t_file_pagopa
    if codResult is not null then
        -- errore bloccante
        strMessaggioBck:=strMessaggio;
        strMessaggio:=' Chiusura siac_t_file_pagopa.';
    	update siac_t_file_pagopa file
        set    data_modifica=clock_timestamp(),
         	   validita_fine=clock_timestamp(),
               file_pagopa_stato_id=stato.file_pagopa_stato_id,
               file_pagopa_errore_id=err.pagopa_ric_errore_id,
               file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
               file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggioBck,'  ')||coalesce(strErrore,' ')),
               login_operazione=file.login_operazione||'-'||loginOperazione
        from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where file.file_pagopa_id=filePagoPaId
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_ERRATO_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaErrCode;

		-- errore bloccante per elaborazione del filePagoPaId passato per cui si esce ma senza errore bloccante per elaborazione complessiva
        -- pagoPaElabId:=-1;
        -- codiceRisultato:=-1;
        messaggioRisultato:=strMessaggioFinale||strMessaggioBck||strErrore||strMessaggio;
        strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
        raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
          inPagoPaElabId,
          filepagopaid,
          strMessaggioLog,
          enteProprietarioId,
          loginOperazione,
          clock_timestamp()
        );

        return;
    end if;


    ---------- fine controlli su siac_t_file_pagopa e piano_t_riconciliazione  --------------------------------


    ---------- inizio inserimento pagopa_t_elaborazione -------------------------------
    -- se inPagoPaElabId=0 inizio nuovo idElaborazione
    if coalesce(inPagoPaElabId,0) = 0 then
      codResult:=null;
      strMessaggio:='Inserimento elaborazione PagoPa in stato '||acquisito_st||'.';
      --- inserimento in stato ACQUISITO
      insert into pagopa_t_elaborazione
      (
          pagopa_elab_data,
          pagopa_elab_stato_id,
          pagopa_elab_file_id,
          pagopa_elab_file_ora,
          pagopa_elab_file_ente,
          pagopa_elab_file_fruitore,
          pagopa_elab_note,
         -- file_pagopa_id ,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
             dataelaborazione,
             stato.pagopa_elab_stato_id,
             filepagopaFileXMLId,
             filepagopaFileOra,
             filepagopaFileEnte,
             filepagopaFileFruitore,
             'AVVIO ELABORAZIONE SU FILE file_pagopa_id='||filePagoPaId::varchar||' IN STATO '||ACQUISITO_ST||' ',
           --  filePagoPaId,
             clock_timestamp(),
             loginOperazione,
             stato.ente_proprietario_id
      from pagopa_d_elaborazione_stato stato
      where stato.ente_proprietario_id=enteProprietarioId
      and   stato.pagopa_elab_stato_code=ACQUISITO_ST
      returning pagopa_elab_id into filePagoPaElabId;


      if filePagoPaElabId is null then
          -- bloccante per elaborazione del file ma puo essere rielaborato
          strMessaggioBck:=strMessaggio;
          strMessaggio:=strMessaggio||' Inserimento non effettuato. Aggiornamento siac_t_file_pagopa.';
          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=stato.file_pagopa_stato_id,
                 file_pagopa_errore_id=err.pagopa_ric_errore_id,
                 file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
                 file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggioBck,' ')||' Inserimento non effettuato. Aggiornamento siac_t_file_pagopa.'),
                 login_operazione=file.login_operazione||'-'||loginOperazione
          from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
          and   err.ente_proprietario_id=stato.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_17;


          strMessaggio:=strMessaggioBck||'  Inserimento non effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_17||'.';

          update pagopa_t_riconciliazione ric
          set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                 data_modifica=clock_timestamp(),
                 pagopa_ric_flusso_stato_elab='X',
                 login_operazione=ric.login_operazione||'-'||loginOperazione
          from pagopa_d_riconciliazione_errore err
          where ric.file_pagopa_id=filePagoPaId
          and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
          and   err.ente_proprietario_id=ric.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_17
          and   ric.data_cancellazione is null
          and   ric.validita_fine is null;

          --pagoPaElabId:=-1;
          codiceRisultato:=0; -- puo' essere rielaborato
          messaggioRisultato:=strMessaggioFinale||strMessaggioBck||' Inserimento non effettuato.Aggiornamento siac_t_file_pagopa e pagopa_t_riconciliazione.';

		  strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
          raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
     	     inPagoPaElabId,
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );

          return;

      else
          -- elaborazione in corso
          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
          raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );

/**          -- fare qui modifica per aggiornare solo se non in stato IN_CORSO_ST
          strMessaggioBck:=strMessaggio;
          strMessaggio:=strMessaggio||' Aggiornamento siac_t_file_pagopa.';

          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=(case when statocor.file_pagopa_stato_code not in (ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST) then stato.file_pagopa_stato_id
                                       else  file.file_pagopa_stato_id end ),
                 file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
                 login_operazione=file.login_operazione||'-'||loginOperazione
          from siac_d_file_pagopa_stato stato, siac_d_file_pagopa_stato statocor
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ST
          and   statocor.file_pagopa_stato_id=file.file_pagopa_stato_id;
	  */
      end if;
    end if;

    -- elaborazione in corso
    -- fare qui modifica per aggiornare solo se non in stato IN_CORSO_ST
    strMessaggio:='Aggiornamento siac_t_file_pagopa per elaborazione in corso.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=(case when statocor.file_pagopa_stato_code not in (ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST) then stato.file_pagopa_stato_id
                                 else  file.file_pagopa_stato_id end ),
           file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
           file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggio,' ')),
           login_operazione=file.login_operazione||'-'||loginOperazione
    from siac_d_file_pagopa_stato stato, siac_d_file_pagopa_stato statocor
    where file.file_pagopa_id=filePagoPaId
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ST
    and   statocor.file_pagopa_stato_id=file.file_pagopa_stato_id;

    -- inserimento pagopa_r_elaborazione_file
    codResult:=null;
    strMessaggio:='Inserimento pagopa_r_elaborazione_file.';
    insert into pagopa_r_elaborazione_file
    (
          pagopa_elab_id,
          file_pagopa_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
	)
    values
    (
        filePagoPaElabId,
        filePagoPaId,
        clock_timestamp(),
        loginOperazione,
        enteProprietarioId
    )
    returning pagopa_r_elab_id into codResult;
    if codResult is null then
    	 -- bloccante per elaborazione, ma il file puo' essere rielaborato
    	 -- chiusura elaborazione
    	 codResult:=null;
         strMessaggioBck:=strMessaggio;
         strmessaggio:=strMessaggioBck||' Non effettuato. Aggiornamento pagopa_t_elaborazione.';
       	 update pagopa_t_elaborazione elab
         set    data_modifica=clock_timestamp(),
                validita_fine=clock_timestamp(),
                pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
         from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
         where elab.pagopa_elab_id=filePagoPaElabId
          and  stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
          and  stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
          and  statonew.ente_proprietario_id=stato.ente_proprietario_id
          and  statonew.pagopa_elab_stato_code=ELABORATO_ERRATO_ST
          and  err.ente_proprietario_id=stato.ente_proprietario_id
          and  err.pagopa_ric_errore_code=PAGOPA_ERR_17
          and  elab.data_cancellazione is null
          and  elab.validita_fine is null;

          strmessaggio:=strMessaggioBck||' Non effettuato. Aggiornamento siac_t_file_pagopa.';
          -- chiusura file_pagopa
          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=stato.file_pagopa_stato_id,
                 file_pagopa_errore_id=err.pagopa_ric_errore_id,
                 file_pagopa_code=coalesce(filepagopaFileXMLId,pagopa.file_pagopa_code),
                 file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strmessaggio,' ')),
                 login_operazione=file.login_operazione||'-'||loginOperazione
          from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
          and   err.ente_proprietario_id=stato.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_17;


		  strMessaggio:=strMessaggioBck||' Inserimento non effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_17||'.';

          update pagopa_t_riconciliazione ric
          set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                 data_modifica=clock_timestamp(),
                 pagopa_ric_flusso_stato_elab='X',
                 login_operazione=ric.login_operazione||'-'||loginOperazione
          from pagopa_d_riconciliazione_errore err
      	  where ric.file_pagopa_id=filePagoPaId
          and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
          and   err.ente_proprietario_id=ric.ente_proprietario_id
	      and   err.pagopa_ric_errore_code=PAGOPA_ERR_17
          and   ric.data_cancellazione is null
  	      and   ric.validita_fine is null;


          outPagoPaElabId:=filePagoPaElabId;
          codiceRisultato:=0;
          messaggioRisultato:=strMessaggioFinale||strMessaggioBck||' Inserimento non effettuato.';
          strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
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
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );
         return;
    end if;


	-- controllo su annoBilancio
    strMessaggio:='Verifica stato annoBilancio di elaborazione='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per, siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
    where fase.ente_proprietario_id=enteProprietarioid
    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST)
    and   per.ente_proprietario_id=fase.ente_proprietario_id
    and   per.anno::integer=annoBilancio
    and   bil.periodo_id=per.periodo_id
    and   r.fase_operativa_id=fase.fase_operativa_id
    and   r.bil_id=r.bil_id;

    if bilancioId is null then
         -- bloccante per elaborazione, ma il file puo' essere rielaborato
    	 -- chiusura elaborazione
    	 codResult:=null;
         strMessaggioBck:=strMessaggio;
         strmessaggio:=strMessaggioBck||' Fase non valida. Aggiornamento pagopa_t_elaborazione.';
       	 update pagopa_t_elaborazione elab
         set    data_modifica=clock_timestamp(),
                validita_fine=clock_timestamp(),
                pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                pagopa_elab_note=upper(strMessaggioFinale||' '||strMessaggioBck||'Fase bilancio non valida.')
         from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
         where elab.pagopa_elab_id=filePagoPaElabId
          and  stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
          and  stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
          and  statonew.ente_proprietario_id=stato.ente_proprietario_id
          and  statonew.pagopa_elab_stato_code=ELABORATO_ERRATO_ST
          and  err.ente_proprietario_id=stato.ente_proprietario_id
          and  err.pagopa_ric_errore_code=PAGOPA_ERR_18
          and  elab.data_cancellazione is null
          and  elab.validita_fine is null;

          strMessaggio:=strMessaggioBck;
          strmessaggio:=strMessaggioBck||' Fase non valida. Aggiornamento siac_t_file_pagopa.';
          -- chiusura file_pagopa
          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=stato.file_pagopa_stato_id,
                 file_pagopa_errore_id=err.pagopa_ric_errore_id,
                 file_pagopa_code=coalesce(filepagopaFileXMLId,pagopa.file_pagopa_code),
                 file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggioBck,' ')||' Fase bilancio non valida.'),
                 login_operazione=file.login_operazione||'-'||loginOperazione
          from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
          and   err.ente_proprietario_id=stato.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_18;


		  strMessaggio:=strMessaggioBck||'  Inserimento non effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_18||'.';

          update pagopa_t_riconciliazione ric
          set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                 data_modifica=clock_timestamp(),
                 pagopa_ric_flusso_stato_elab='X',
                 login_operazione=ric.login_operazione||'-'||loginOperazione
          from pagopa_d_riconciliazione_errore err
      	  where ric.file_pagopa_id=filePagoPaId
          and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
          and   err.ente_proprietario_id=ric.ente_proprietario_id
	      and   err.pagopa_ric_errore_code=PAGOPA_ERR_18
          and   ric.data_cancellazione is null
  	      and   ric.validita_fine is null;


          outPagoPaElabId:=filePagoPaElabId;
          codiceRisultato:=0; -- il file puo essere rielaborato
          messaggioRisultato:=strMessaggioFinale||strMessaggioBck||' Fase bilancio non valida.';

          strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
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
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );
         return;
    end if;


    codResult:=null;
    ---------- fine inserimento pagopa_t_elaborazione --------------------------------

    ---------- inizio gestione flussi su piano_t_riconciliazione per pagopa_elab_id ----------------


    -- per file_pagopa_id, file_pagopa_id ( XML )
    -- distinct su pagopa_t_riconciliazione su file_pagopa_id, file_pagopa_id ( XML ) pagopa_flusso_id ( XML )
    -- per cui non esiste corrispondenza su
    --   pagopa_t_riconciliazione_doc con subdoc_id valorizzato
    --   pagopa_t_riconciliazione_doc con subdoc_id non valorizzato e errore bloccante
    --   pagopa_t_riconciliazione con errore bloccante
    strMessaggio:='Inserimento dati per elaborazione flussi.Inizio ciclo.';
    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
       filepagopaid,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
    );

    for pagoPaFlussoRec in
    (
    select distinct ric.pagopa_ric_file_id pagopa_file_id,
                    ric.pagopa_ric_flusso_id pagopa_flusso_id,
                    ric.pagopa_ric_flusso_anno_provvisorio pagopa_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio pagopa_num_provvisorio
    from pagopa_t_riconciliazione ric
    where ric.file_pagopa_id=filePagoPaId
    and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
    /*and   not exists
    ( select 1
      from pagopa_t_riconciliazione_doc doc
      where doc.pagopa_ric_id=ric.pagopa_ric_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
    )*/
   /* and   not exists
    ( select 1
      from pagopa_t_riconciliazione_doc doc
      where doc.pagopa_ric_id=ric.pagopa_ric_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_stato_elab in ('E')
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
    )*/
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null
    order by        ric.pagopa_ric_flusso_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio
    )
    loop

	    strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.';

        strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );


	    --   inserimento in pagopa_t_elaborazione_flusso

        pagoPaFlussoAnnoEsercizio :=null;
	    pagoPaFlussoNomeMittente  :=null;
	    pagoPaFlussoData  :=null;
    	pagoPaFlussoTotPagam  :=null;
        codResult:=null;
        strNote:=null;
        pagopaElabFlussoId:=null;

        strMessaggio:=strmessaggio||' Ricava dati.';
		select ric.pagopa_ric_flusso_anno_esercizio,
    	       ric.pagopa_ric_flusso_nome_mittente,
 	    	   ric.pagopa_ric_flusso_data::varchar,
			   ric.pagopa_ric_flusso_tot_pagam,
               ric.pagopa_ric_id
    	       into
        	   pagoPaFlussoAnnoEsercizio,
	           pagoPaFlussoNomeMittente,
    	       pagoPaFlussoData,
	       	   pagoPaFlussoTotPagam,
               codResult
	    from pagopa_t_riconciliazione ric
	    where ric.file_pagopa_id=filePagoPaId
    	and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
	    and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
    	and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
		and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
        /*and   not exists
	    ( select 1
    	  from pagopa_t_riconciliazione_doc doc
	      where doc.pagopa_ric_id=ric.pagopa_ric_id
    	  and   doc.pagopa_ric_doc_subdoc_id is not null
	      and   doc.data_cancellazione is null
    	  and   doc.validita_fine is null
	    )*/
    	/*and   not exists
	    ( select 1
    	  from pagopa_t_riconciliazione_doc doc
	      where doc.pagopa_ric_id=ric.pagopa_ric_id
    	  and   doc.pagopa_ric_doc_subdoc_id is null
	      and   doc.pagopa_ric_doc_stato_elab in ('E')
    	  and  doc.data_cancellazione is null
	      and   doc.validita_fine is null
	    )*/
    	and   ric.data_cancellazione is null
	    and   ric.validita_fine is null
    	limit 1;

		if  codResult is null then
        	strNote:='Dati testata mancanti.';
        end if;

	    strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Inserimento pagopa_t_elaborazione_flusso.';

	    insert into pagopa_t_elaborazione_flusso
    	(
    	 pagopa_elab_flusso_data,
	     pagopa_elab_flusso_stato_id,
		 pagopa_elab_flusso_note,
		 pagopa_elab_ric_flusso_id,
		 pagopa_elab_flusso_nome_mittente,
		 pagopa_elab_ric_flusso_data,
	     pagopa_elab_flusso_tot_pagam,
	     pagopa_elab_flusso_anno_esercizio,
	     pagopa_elab_flusso_anno_provvisorio,
	     pagopa_elab_flusso_num_provvisorio,
		 pagopa_elab_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
	    )
    	select dataElaborazione,
        	   stato.pagopa_elab_stato_id,
	           'AVVIO ELABORAZIONE FILE file_pagopa_id='||filePagoPaId::varchar||
               upper(' FLUSSO_ID='||pagoPaFlussoRec.pagopa_flusso_id||' IN STATO '||ACQUISITO_ST||' '||
               coalesce(strNote,' ')),
               pagoPaFlussoRec.pagopa_flusso_id,
   	           pagoPaFlussoNomeMittente,
			   pagoPaFlussoData,
               pagoPaFlussoTotPagam,
               pagoPaFlussoAnnoEsercizio,
               pagoPaFlussoRec.pagopa_anno_provvisorio,
               pagoPaFlussoRec.pagopa_num_provvisorio,
               filePagoPaElabId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
    	from pagopa_d_elaborazione_stato stato
	    where stato.ente_proprietario_id=enteProprietarioId
    	and   stato.pagopa_elab_stato_code=ACQUISITO_ST
        returning pagopa_elab_flusso_id into pagopaElabFlussoId;

        codResult:=null;
        if pagopaElabFlussoId is null then
            strMessaggioBck:=strMessaggio;
            strmessaggio:=strMessaggioBck||' NON Effettuato. Aggiornamento pagopa_t_elaborazione.';
        	update pagopa_t_elaborazione elab
            set    data_modifica=clock_timestamp(),
                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                   pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                   pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
            from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
            where elab.pagopa_elab_id=filePagoPaElabId
            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
            and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
            and   statonew.ente_proprietario_id=stato.ente_proprietario_id
            and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
            and   err.ente_proprietario_id=stato.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_19
            and   elab.data_cancellazione is null
            and   elab.validita_fine is null;

             strMessaggio:=strMessaggioBck||' NON effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_19||'.';
             update pagopa_t_riconciliazione ric
             set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                    data_modifica=clock_timestamp(),
                    pagopa_ric_flusso_stato_elab='X',
                    login_operazione=ric.login_operazione||'-'||loginOperazione
             from pagopa_d_riconciliazione_errore err
             where ric.file_pagopa_id=filePagoPaId
             and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
             and   err.ente_proprietario_id=ric.ente_proprietario_id
             and   err.pagopa_ric_errore_code=PAGOPA_ERR_19
             and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
             and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
             and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
             /*and   not exists
             ( select 1
               from pagopa_t_riconciliazione_doc doc
               where doc.pagopa_ric_id=ric.pagopa_ric_id
               and   doc.pagopa_ric_doc_subdoc_id is not null
               and   doc.data_cancellazione is null
               and   doc.validita_fine is null
             )*/
             /*and   not exists
             ( select 1
               from pagopa_t_riconciliazione_doc doc
               where doc.pagopa_ric_id=ric.pagopa_ric_id
               and   doc.pagopa_ric_doc_subdoc_id is null
               and   doc.pagopa_ric_doc_stato_elab in ('E')
               and   doc.data_cancellazione is null
               and   doc.validita_fine is null
             )*/
             and   ric.data_cancellazione is null
             and   ric.validita_fine is null;

            codResult:=-1;
            pagoPaErrCode:=PAGOPA_ERR_19;

        end if;

        if  pagopaElabFlussoId is not null then
         strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                        pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                        pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                        pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                        ' Inserimento pagopa_t_riconciliazione_doc.';
		 --   inserimento in pagopa_t_riconciliazione_doc
         insert into pagopa_t_riconciliazione_doc
         (
        	pagopa_ric_doc_data,
            pagopa_ric_doc_voce_tematica,
  	        pagopa_ric_doc_voce_code,
			pagopa_ric_doc_voce_desc,
			pagopa_ric_doc_sottovoce_code,
		    pagopa_ric_doc_sottovoce_desc,
			pagopa_ric_doc_sottovoce_importo,
		    pagopa_ric_doc_anno_esercizio,
		    pagopa_ric_doc_anno_accertamento,
			pagopa_ric_doc_num_accertamento,
		    pagopa_ric_doc_num_capitolo,
		    pagopa_ric_doc_num_articolo,
		    pagopa_ric_doc_pdc_v_fin,
		    pagopa_ric_doc_titolo,
		    pagopa_ric_doc_tipologia,
		    pagopa_ric_doc_categoria,
		    pagopa_ric_doc_codice_benef,
		    pagopa_ric_doc_str_amm,
            pagopa_ric_id,
	        pagopa_elab_flusso_id,
            file_pagopa_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select dataElaborazione,
                ric.pagopa_ric_flusso_tematica,
                ric.pagopa_ric_flusso_voce_code,
                ric.pagopa_ric_flusso_voce_desc,
                ric.pagopa_ric_flusso_sottovoce_code,
                ric.pagopa_ric_flusso_sottovoce_desc,
                ric.pagopa_ric_flusso_sottovoce_importo,
                ric.pagopa_ric_flusso_anno_esercizio,
                ric.pagopa_ric_flusso_anno_accertamento,
                ric.pagopa_ric_flusso_num_accertamento,
                ric.pagopa_ric_flusso_num_capitolo,
                ric.pagopa_ric_flusso_num_articolo,
                ric.pagopa_ric_flusso_pdc_v_fin,
                ric.pagopa_ric_flusso_titolo,
                ric.pagopa_ric_flusso_tipologia,
                ric.pagopa_ric_flusso_categoria,
                ric.pagopa_ric_flusso_codice_benef,
                ric.pagopa_ric_flusso_str_amm,
                ric.pagopa_ric_id,
                pagopaElabFlussoId,
                filePagoPaId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         from pagopa_t_riconciliazione ric
         where ric.file_pagopa_id=filePagoPaId
    	 and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
	     and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
    	 and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
		 and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
         /*and   not exists
    	 ( select 1
	       from pagopa_t_riconciliazione_doc doc
    	   where doc.pagopa_ric_id=ric.pagopa_ric_id
	       and   doc.pagopa_ric_doc_subdoc_id is not null
    	   and   doc.data_cancellazione is null
	       and   doc.validita_fine is null
    	 )*/
	     /*and   not exists
	     ( select 1
    	   from pagopa_t_riconciliazione_doc doc
	       where doc.pagopa_ric_id=ric.pagopa_ric_id
      	   and   doc.pagopa_ric_doc_subdoc_id is null
	       and   doc.pagopa_ric_doc_stato_elab in ('E')
    	   and   doc.data_cancellazione is null
	       and   doc.validita_fine is null
    	 )*/
    	 and   ric.data_cancellazione is null
	     and   ric.validita_fine is null;

         strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica inserimento pagopa_t_riconciliazione_doc.';
         -- controllo inserimento
		 codResult:=null;
         select 1 into codResult
         from pagopa_t_riconciliazione_doc doc
         where doc.pagopa_elab_flusso_id=pagopaElabFlussoId;
         if codResult is null then
             strMessaggioBck:=strMessaggio;
             strmessaggio:=strMessaggioBck||'. NON Effettuato. Aggiornamento pagopa_t_elaborazione.';
          	 update pagopa_t_elaborazione elab
             set   data_modifica=clock_timestamp(),
                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                   pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                   pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
             from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
             where elab.pagopa_elab_id=filePagoPaElabId
             and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
             and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
             and   statonew.ente_proprietario_id=stato.ente_proprietario_id
             and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
             and   err.ente_proprietario_id=stato.ente_proprietario_id
             and   err.pagopa_ric_errore_code=PAGOPA_ERR_21
             and   elab.data_cancellazione is null
             and   elab.validita_fine is null;


             codResult:=-1;
             pagoPaErrCode:=PAGOPA_ERR_21;

             strMessaggio:=strMessaggioBck||' NON effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_19||'.';
			 update pagopa_t_riconciliazione ric
    	     set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	        data_modifica=clock_timestamp(),
            	    pagopa_ric_flusso_stato_elab='X',
                	login_operazione=ric.login_operazione||'-'||loginOperazione
	         from pagopa_d_riconciliazione_errore err
    	     where ric.file_pagopa_id=filePagoPaId
    		 and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
	         and   err.ente_proprietario_id=ric.ente_proprietario_id
    	     and   err.pagopa_ric_errore_code=PAGOPA_ERR_21
	    	 and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
	    	 and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
			 and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
        	 /*and   not exists
	    	 ( select 1
		       from pagopa_t_riconciliazione_doc doc
    		   where doc.pagopa_ric_id=ric.pagopa_ric_id
		       and   doc.pagopa_ric_doc_subdoc_id is not null
    		   and   doc.data_cancellazione is null
	    	   and   doc.validita_fine is null
	    	 )*/
		     /*and   not exists
	    	 ( select 1
	    	   from pagopa_t_riconciliazione_doc doc
		       where doc.pagopa_ric_id=ric.pagopa_ric_id
      		   and   doc.pagopa_ric_doc_subdoc_id is null
		       and   doc.pagopa_ric_doc_stato_elab in ('E')
    		   and   doc.data_cancellazione is null
	    	   and   doc.validita_fine is null
	    	 )*/
    		 and   ric.data_cancellazione is null
	    	 and   ric.validita_fine is null;


         else
         	codResult:=null;
            strMessaggio:=strMessaggio||' Inserimento effettuato.';
         end if;
		end if;

	    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );

        -- controllo dati su
        -- pagopa_t_elaborazione_flusso
        -- pagopa_t_riconciliazione_doc
        if codResult is null then
        	-- esistenza provvisorio di cassa
            strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza provvisorio di cassa.';
            select 1 into codResult
            from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
            where  tipo.ente_proprietario_id=enteProprietarioid
            and    tipo.provc_tipo_code='E'
            and    prov.provc_tipo_id=tipo.provc_tipo_id
            and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
            and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
            and    prov.provc_data_annullamento is null
            and    prov.provc_data_regolarizzazione is null
            and    prov.data_cancellazione  is null
			and    prov.validita_fine is null;
		    if codResult is null then
            	pagoPaErrCode:=PAGOPA_ERR_22;
                codResult:=-1;
            else codResult:=null;
            end if;
            if codResult is null then
            	strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza provvisorio di cassa regolarizzato [Ord.].';
                select 1 into codResult
                from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo,siac_r_ordinativo_prov_cassa rp
                where  tipo.ente_proprietario_id=enteProprietarioid
                and    tipo.provc_tipo_code='E'
                and    prov.provc_tipo_id=tipo.provc_tipo_id
                and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
                and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
                and    rp.provc_id=prov.provc_id
                and    prov.provc_data_annullamento is null
                and    prov.provc_data_regolarizzazione is null
                and    prov.data_cancellazione  is null
                and    prov.validita_fine is null
                and    rp.data_cancellazione  is null
                and    rp.validita_fine is null;
                if codResult is null then
                    strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza provvisorio di cassa regolarizzato [Doc.].';
                	select 1 into codResult
                    from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo,siac_r_subdoc_prov_cassa rp
                    where  tipo.ente_proprietario_id=enteProprietarioid
                    and    tipo.provc_tipo_code='E'
                    and    prov.provc_tipo_id=tipo.provc_tipo_id
                    and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
                    and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
                    and    rp.provc_id=prov.provc_id
                    and    prov.provc_data_annullamento is null
                    and    prov.provc_data_regolarizzazione is null
                    and    prov.data_cancellazione  is null
                    and    prov.validita_fine is null
                    and    rp.data_cancellazione  is null
                    and    rp.validita_fine is null;
                end if;
                if codResult is not null then
                	pagoPaErrCode:=PAGOPA_ERR_38;
	                codResult:=-1;
                end if;
            end if;

            if pagoPaErrCode is not null then
              strMessaggioBck:=strMessaggio;
              strmessaggio:=strMessaggio||' NON esistente o regolarizzato. Aggiornamento pagopa_t_elaborazione.';
              update pagopa_t_elaborazione elab
              set    data_modifica=clock_timestamp(),
                     pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                     pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                     pagopa_elab_note=upper(strMessaggioFinale||' '||strMessaggio)
              from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
              where elab.pagopa_elab_id=filePagoPaElabId
              and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
              and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
              and   statonew.ente_proprietario_id=stato.ente_proprietario_id
              and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_SC_ST
              and   err.ente_proprietario_id=stato.ente_proprietario_id
              and   err.pagopa_ric_errore_code=pagoPaErrCode
              and   elab.data_cancellazione is null
              and   elab.validita_fine is null;

              codResult:=-1;


              strMessaggio:=strMessaggioBck||' NON esistente o regolarizzato.Aggiornamento pagopa_t_riconciliazione_doc PAGOPA_ERR='||pagoPaErrCode||'.';
              update pagopa_t_riconciliazione_doc doc
              set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                     data_modifica=clock_timestamp(),
                     pagopa_ric_doc_stato_elab='X',
                     login_operazione=doc.login_operazione||'-'||loginOperazione
              from pagopa_d_riconciliazione_errore err
              where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
              and   err.ente_proprietario_id=doc.ente_proprietario_id
              and   err.pagopa_ric_errore_code=pagoPaErrCode
              and   doc.data_cancellazione is null
              and   doc.validita_fine is null;


              strMessaggio:=strMessaggioBck||' NON esistente o regolarizzato.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||pagoPaErrCode||'.';
              update pagopa_t_riconciliazione ric
              set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                     data_modifica=clock_timestamp(),
                     pagopa_ric_flusso_stato_elab='X',
                     login_operazione=ric.login_operazione||'-'||loginOperazione
              from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
              where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
              and   ric.pagopa_ric_id=doc.pagopa_ric_id
              and   err.ente_proprietario_id=doc.ente_proprietario_id
              and   err.pagopa_ric_errore_code=pagoPaErrCode
              and   doc.data_cancellazione is null
              and   doc.validita_fine is null
              and   ric.data_cancellazione is null
              and   ric.validita_fine is null;
            else codResult:=null;
            end if;

            -- esistenza accertamento
            if codResult is null then
                strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza accertamenti.';
            	select 1 into codResult
                from pagopa_t_riconciliazione_doc doc
                where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
                and   not exists
                (
                select 1
				from siac_t_movgest mov, siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                     siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato
                where   mov.bil_id=bilancioId
                and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
                and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
                and   tipo.movgest_tipo_id=mov.movgest_tipo_id
                and   tipo.movgest_tipo_code='A'
                and   ts.movgest_id=mov.movgest_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   tipots.movgest_ts_tipo_code='T'
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   stato.movgest_stato_id=rs.movgest_stato_id
                and   stato.movgest_stato_code='D'
                and   rs.data_cancellazione is null
                and   rs.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                );

				if codResult is not null then
             		strMessaggioBck:=strMessaggio;
		            strmessaggio:=strMessaggio||' NON esistente. Aggiornamento pagopa_t_elaborazione.';
		          	update pagopa_t_elaborazione elab
		            set    data_modifica=clock_timestamp(),
    	                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                           pagopa_elab_errore_id=err.pagopa_ric_errore_id,
        	               pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
            		from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
	                where elab.pagopa_elab_id=filePagoPaElabId
    	            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
        	        and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
            	    and   statonew.ente_proprietario_id=stato.ente_proprietario_id
	                and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_SC_ST
                    and   err.ente_proprietario_id=stato.ente_proprietario_id
                    and   err.pagopa_ric_errore_code=PAGOPA_ERR_23
    	            and   elab.data_cancellazione is null
        	        and   elab.validita_fine is null;

					pagoPaErrCode:=PAGOPA_ERR_23;
		            codResult:=-1;

                    strMessaggio:=strMessaggioBck||' NON esistente.Aggiornamento pagopa_t_riconciliazione_doc PAGOPA_ERR='||PAGOPA_ERR_23||'.';
			     	update pagopa_t_riconciliazione_doc doc
	     	        set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
    	    	           data_modifica=clock_timestamp(),
        	      	       pagopa_ric_doc_stato_elab='X',
                 		   login_operazione=doc.login_operazione||'-'||loginOperazione
	                from pagopa_d_riconciliazione_errore err
    	            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
	                and   err.ente_proprietario_id=doc.ente_proprietario_id
     	            and   err.pagopa_ric_errore_code=PAGOPA_ERR_23
    		        and   doc.data_cancellazione is null
	    	        and   doc.validita_fine is null;


            	    strMessaggio:=strMessaggioBck||' NON esistente.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||PAGOPA_ERR_23||'.';
			        update pagopa_t_riconciliazione ric
     	            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	               data_modifica=clock_timestamp(),
              	           pagopa_ric_flusso_stato_elab='X',
                 	       login_operazione=ric.login_operazione||'-'||loginOperazione
	                from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
    	            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
                    and   ric.pagopa_ric_id=doc.pagopa_ric_id
	                and   err.ente_proprietario_id=doc.ente_proprietario_id
     	            and   err.pagopa_ric_errore_code=PAGOPA_ERR_23
    		        and   doc.data_cancellazione is null
	    	        and   doc.validita_fine is null
                    and   ric.data_cancellazione is null
	    	        and   ric.validita_fine is null;
        	    end if;
            end if;
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );

		-- sono stati inseriti
        -- pagopa_t_elaborazione_flusso
        -- pagopa_t_riconciliazione_doc
        -- posso aggiornare su pagopa_t_elaborazione per elab=elaborato_in_corso
		if codResult is null then
		            strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Aggiornamento pagopa_t_elaborazione '||ELABORATO_IN_CORSO_ST||'.';
		          	update pagopa_t_elaborazione elab
		            set    data_modifica=clock_timestamp(),
    	                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
        	               pagopa_elab_note='AGGIORNAMENTO ELABORAZIONE SU FILE file_pagopa_id='||filePagoPaId::varchar||' IN STATO '||ELABORATO_IN_CORSO_ST||' '
            		from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew
	                where elab.pagopa_elab_id=filePagoPaElabId
    	            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
        	        and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST)
            	    and   statonew.ente_proprietario_id=stato.ente_proprietario_id
	                and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ST
    	            and   elab.data_cancellazione is null
        	        and   elab.validita_fine is null;
        end if;

		-- non sono stati inseriti
        -- pagopa_t_elaborazione_flusso
        -- pagopa_t_riconciliazione_doc
        -- quindi aggiornare siac_t_file_pagopa
        if codResult is not null then
	        strmessaggio:=strMessaggioBck||' Errore. Aggiornamento siac_t_file_pagopa.';
	       	update siac_t_file_pagopa file
          	set    data_modifica=clock_timestamp(),
            	   file_pagopa_stato_id=stato.file_pagopa_stato_id,
                   file_pagopa_errore_id=err.pagopa_ric_errore_id,
                   file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
                   file_pagopa_note=coalesce(strMessaggioFinale,' ' )||coalesce(strmessaggio,' '),
                   login_operazione=file.login_operazione||'-'||loginOperazione
            from siac_d_file_pagopa_stato stato, pagopa_d_riconciliazione_errore err
            where file.file_pagopa_id=filePagoPaId
            and   stato.ente_proprietario_id=file.ente_proprietario_id
            and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_SC_ST
            and   err.ente_proprietario_id=stato.ente_proprietario_id
            and   err.pagopa_ric_errore_code=pagoPaErrCode;
        end if;

	    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );

    end loop;
    ---------- fine gestione flussi su piano_t_riconciliazione per pagopa_elab_id ----------------

    outPagoPaElabId:=filePagoPaElabId;
    messaggioRisultato:=upper(strMessaggioFinale||' OK');
    strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
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
       filepagopaid,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
    );

    return;
exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outPagoPaElabId:=-1;

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc
(
  enteproprietarioid      integer,
  loginoperazione         varchar,
  dataelaborazione        timestamp,
  out outPagoPaElabId     integer,
  out outPagoPaElabPrecId     integer,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
    strMessaggioBck  VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
	strMessaggioLog VARCHAR(2500):='';

	codResult integer:=null;
	annoBilancio integer:=null;
    annoBilancio_ini integer:=null;

    filePagoPaElabId integer:=null;
    filePagoPaElabPrecId integer:=null;

    elabRec record;
    elabResRec record;
    annoRec record;
    elabEsecResRec record;

    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti


	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione


BEGIN

	strMessaggioFinale:='Elaborazione PAGOPA.';
    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale;
    raise notice 'strMessaggioLog=%',strMessaggioLog;

	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

   	outPagoPaElabId:=null;
    outPagoPaElabPrecId:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';

    strMessaggio:='Verifica esistenza elaborazione acquisita, in corso.';
    select 1 into codResult
    from pagopa_t_elaborazione pagopa, pagopa_d_elaborazione_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   pagopa.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
    and   pagopa.data_cancellazione is null
    and   pagopa.validita_fine is null;
    if codResult is not null then
         outPagoPaElabId:=-1;
         outPagoPaElabPrecId:=-1;
         messaggioRisultato:=upper(strMessaggioFinale||' Elaborazione acquisita, in corso esistente.');
         strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
	     insert into pagopa_t_elaborazione_log
         (
     		pagopa_elab_id,
		    pagopa_elab_log_operazione,
		    ente_proprietario_id,
		    login_operazione,
            data_creazione
	     )
	     values
	     (
	      null,
	      strMessaggioLog,
	 	  enteProprietarioId,
     	  loginOperazione,
          clock_timestamp()
    	 );

         codiceRisultato:=-1;
    	 return;
    end if;




    annoBilancio:=extract('YEAR' from now())::integer;
    annoBilancio_ini:=annoBilancio;
    strMessaggio:='Verifica fase bilancio annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select 1 into codResult
    from siac_t_bil bil,siac_t_periodo per,
         siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
    where per.ente_proprietario_id=enteProprietarioid
    and   per.anno::integer=annoBilancio-1
    and   bil.periodo_id=per.periodo_id
    and   r.bil_id=bil.bil_id
    and   fase.fase_operativa_id=r.fase_operativa_id
    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
    if codResult is not null then
    	annoBilancio_ini:=annoBilancio-1;
    end if;


    strMessaggio:='Verifica esistenza file da elaborare.';
    select 1 into codResult
    from siac_t_file_pagopa pagopa, siac_d_file_pagopa_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
    and   pagopa.file_pagopa_stato_id=stato.file_pagopa_stato_id
    and   pagopa.file_pagopa_anno in (annoBilancio_ini,annoBilancio)
    and   pagopa.data_cancellazione is null
    and   pagopa.validita_fine is null;
    if codResult is null then
           outPagoPaElabId:=-1;
           outPagoPaElabPrecId:=-1;
           messaggioRisultato:=upper(strMessaggioFinale||' File da elaborare non esistenti.');
           codiceRisultato:=-1;
           strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
	       insert into pagopa_t_elaborazione_log
           (
     		pagopa_elab_id,
		    pagopa_elab_log_operazione,
		    ente_proprietario_id,
		    login_operazione,
            data_creazione
	       )
	       values
	       (
	        null,
	        strMessaggioLog,
	 	    enteProprietarioId,
     	    loginOperazione,
            clock_timestamp()
    	   );

           return;
    end if;

   codResult:=null;
   strMessaggio:='Inizio elaborazioni anni.';
   strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
   raise notice 'strMessaggioLog=%',strMessaggioLog;
   insert into pagopa_t_elaborazione_log
   (
      pagopa_elab_id,
      pagopa_elab_log_operazione,
      ente_proprietario_id,
      login_operazione,
      data_creazione
   )
   values
   (
    null,
    strMessaggioLog,
    enteProprietarioId,
    loginOperazione,
    clock_timestamp()
   );

   for annoRec in
   (
    select *
    from
   	(select annoBilancio_ini anno_elab
     union
     select annoBilancio anno_elab
    ) query
    where codiceRisultato=0
    order by 1
   )
   loop

    if annoRec.anno_elab>annoBilancio_ini then
    	filePagoPaElabPrecId:=filePagoPaElabId;
    end if;
    filePagoPaElabId:=null;
    strMessaggio:='Inizio elaborazione file PAGOPA per annoBilancio='||annoRec.anno_elab::varchar||'.';
    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
    raise notice 'strMessaggioLog=%',strMessaggioLog;
    insert into pagopa_t_elaborazione_log
    (
      pagopa_elab_id,
      pagopa_elab_log_operazione,
      ente_proprietario_id,
      login_operazione,
      data_creazione
    )
    values
    (
     null,
     strMessaggioLog,
     enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

    for  elabRec in
    (
      select pagopa.*
      from siac_t_file_pagopa pagopa, siac_d_file_pagopa_stato stato
      where stato.ente_proprietario_id=enteProprietarioId
      and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
      and   pagopa.file_pagopa_stato_id=stato.file_pagopa_stato_id
      and   pagopa.file_pagopa_anno=annoRec.anno_elab
      and   pagopa.data_cancellazione is null
      and   pagopa.validita_fine is null
      and   codiceRisultato=0
      order by pagopa.file_pagopa_id
    )
    loop
       strMessaggio:='Elaborazione File PAGOPA ID='||elabRec.file_pagopa_id||' Identificativo='||coalesce(elabRec.file_pagopa_code,' ')
                      ||' annoBilancio='||annoRec.anno_elab::varchar||'.';

       strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
       raise notice '1strMessaggioLog=%',strMessaggioLog;
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
    	null,
        elabRec.file_pagopa_id,
	    strMessaggioLog,
	    enteProprietarioId,
	    loginOperazione,
        clock_timestamp()
	   );
       raise notice '2strMessaggioLog=%',strMessaggioLog;

       select * into elabResRec
       from fnc_pagopa_t_elaborazione_riconc_insert
       (
          elabRec.file_pagopa_id,
          null,--filepagopaFileXMLId     varchar,
          null,--filepagopaFileOra       varchar,
          null,--filepagopaFileEnte      varchar,
          null,--filepagopaFileFruitore  varchar,
          filePagoPaElabId,
          annoRec.anno_elab,
          enteProprietarioId,
          loginOperazione,
          dataElaborazione
       );
              raise notice '2strMessaggioLog dopo=%',elabResRec.messaggiorisultato;

       if elabResRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabResRec.codiceRisultato;
          strMessaggio:=elabResRec.messaggiorisultato;
       else
          filePagoPaElabId:=elabResRec.outPagoPaElabId;
       end if;

		raise notice 'codiceRisultato=%',codiceRisultato;
        raise notice 'strMessaggio=%',strMessaggio;
    end loop;

	if codiceRisultato=0 and coalesce(filePagoPaElabId,0)!=0 then
    	strMessaggio:='Elaborazione documenti  annoBilancio='||annoRec.anno_elab::varchar
                      ||' Identificativo elab='||coalesce((filePagoPaElabId::varchar),' ')||'.';
        strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
        raise notice 'strMessaggioLog=%',strMessaggioLog;
	    insert into pagopa_t_elaborazione_log
   	    (
	      pagopa_elab_id,
    	  pagopa_elab_log_operazione,
	      ente_proprietario_id,
    	  login_operazione,
          data_creazione
	    )
	    values
	    (
     	  filePagoPaElabId,
	      strMessaggioLog,
	      enteProprietarioId,
	      loginOperazione,
          clock_timestamp()
	    );

        select * into elabEsecResRec
       	from fnc_pagopa_t_elaborazione_riconc_esegui
		(
		  filePagoPaElabId,
	      annoRec.anno_elab,
  		  enteProprietarioId,
		  loginOperazione,
	      dataElaborazione
        );
        if elabEsecResRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabEsecResRec.codiceRisultato;
          strMessaggio:=elabEsecResRec.messaggiorisultato;
        end if;
    end if;

   end loop;

   if codiceRisultato=0 then
	    outPagoPaElabId:=filePagoPaElabId;
        outPagoPaElabPrecId:=filePagoPaElabPrecId;
    	messaggioRisultato:=upper(strMessaggioFinale||' TERMINE OK.');
   else
    	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
    	messaggioRisultato:=upper(strMessaggioFinale||'TERMINE KO.'||strMessaggio);
   end if;

   strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
   insert into pagopa_t_elaborazione_log
   (
    pagopa_elab_id,
    pagopa_elab_log_operazione,
    ente_proprietario_id,
    login_operazione,
    data_creazione
   )
   values
   (
    filePagoPaElabId ,
    strMessaggioLog,
    enteProprietarioId,
    loginOperazione,
    clock_timestamp()
   );

   return;
exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
--- siac-6347 Sofia - Fine

--MODIFICHE DDL CESPITI

DROP TABLE IF EXISTS siac_r_cespiti_mov_ep_det cascade;

CREATE TABLE IF NOT EXISTS siac.siac_r_cespiti_mov_ep_det(
  ces_movep_det_id SERIAL,
  ces_id INTEGER NOT NULL,
  movep_det_id INTEGER NOT NULL,
  pnota_id INTEGER, --valutare se tenere
  ente_proprietario_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_cespiti_mov_ep_det PRIMARY KEY(ces_movep_det_id),
  CONSTRAINT siac_t_cespiti_siac_r_cespiti_mov_ep_det FOREIGN KEY (ces_id)
    REFERENCES siac.siac_t_cespiti(ces_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_mov_ep_det_siac_r_cespiti_mov_ep_det FOREIGN KEY (movep_det_id)
    REFERENCES siac.siac_t_mov_ep_det(movep_det_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prima_nota_siac_r_cespiti_cespiti_elab_ammortamenti FOREIGN KEY (pnota_id)
    REFERENCES siac.siac_t_prima_nota(pnota_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_mov_ep_det FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE  
);

CREATE INDEX siac_r_cespiti_mov_ep_det_fk_ces_id_idx ON siac.siac_r_cespiti_mov_ep_det
  USING btree (ces_id, movep_det_id,ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX siac_r_cespiti_mov_ep_det_fk_ente_proprietario_id_idx ON siac.siac_r_cespiti_mov_ep_det
  USING btree (ente_proprietario_id);