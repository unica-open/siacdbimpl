/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-6126 - Sofia - Inizio
drop view if exists siac_v_dwh_provvisori_cassa;

CREATE OR REPLACE VIEW siac_v_dwh_provvisori_cassa(
    ente_proprietario_id,
    provc_tipo_code,
    provc_tipo_desc,
    provc_anno,
    provc_numero,
    provc_causale,
    provc_subcausale,
    provc_denom_soggetto,
    provc_importo,
    provc_data_annullamento,
    provc_data_convalida,
    provc_data_emissione,
    provc_data_regolarizzazione,
    tipo_sac,
    codice_sac,
    provc_data_trasmissione,
    provc_accettato,
    provc_note,
    provc_conto_evidenza, -- 28.05.2018 Sofia siac-6126
    provc_descrizione_conto_evidenza) -- 28.05.2018 Sofia siac-6126
AS
WITH provv AS(
  SELECT a.ente_proprietario_id,
         b.provc_tipo_code,
         b.provc_tipo_desc,
         a.provc_anno,
         a.provc_numero,
         a.provc_causale,
         a.provc_subcausale,
         a.provc_denom_soggetto,
         a.provc_importo,
         a.provc_data_annullamento,
         a.provc_data_convalida,
         a.provc_data_emissione,
         a.provc_data_regolarizzazione,
         a.provc_id,
         a.provc_data_trasmissione,
         a.provc_accettato,
         a.provc_note
  FROM siac_t_prov_cassa a,
       siac_d_prov_cassa_tipo b
  WHERE a.provc_tipo_id = b.provc_tipo_id AND
        a.data_cancellazione IS NULL), sac AS(
    SELECT n.classif_code AS codice_sac,
           n.classif_desc AS descrizione_cdc,
           o.classif_tipo_code AS tipo_sac,
           m.provc_id
    FROM siac_r_prov_cassa_class m,
         siac_t_class n,
         siac_d_class_tipo o
    WHERE n.classif_id = m.classif_id AND
          o.classif_tipo_id = n.classif_tipo_id AND
          (o.classif_tipo_code::text = ANY (ARRAY [ 'CDC'::text, 'CDR'::text ]))
  AND
          now() >= m.validita_inizio AND
          now() <= COALESCE(m.validita_fine::timestamp with time zone, now())
  AND
          m.data_cancellazione IS NULL),
  provc_conto_evidenza as -- 28.05.2018 Sofia siac-6126
  (
      select query.provc_id,
           query.oil_ricevuta_id,
           query.conto_evidenza,
           query.descrizione_conto_evidenza
  from
  (
  with
  rprov as
  (
  select *
  from siac_r_prov_cassa_oil_ricevuta r
  where r.data_cancellazione is null
  and   r.validita_fine is null
  ),
  ricevuta as
  (
  select oil.*
  from siac_t_oil_ricevuta oil,siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='P'
  and   oil.oil_ricevuta_tipo_id=tipo.oil_ricevuta_tipo_id
  and   oil.oil_ricevuta_errore_id is null
  and   oil.data_cancellazione is null
  and   oil.validita_fine is null
  ),
  giocassa as
  (
  select
         gio.flusso_elab_mif_id,
         gio.mif_t_giornalecassa_id,
         gio.conto_evidenza,
         gio.descrizione_conto_evidenza
  from mif_t_giornalecassa gio
  where gio.tipo_documento in ( 'SOSPESO ENTRATA','SOSPESO USCITA')
  and   gio.data_cancellazione is null
  and   gio.validita_fine is null
  )
  select rprov.provc_id,
         rprov.oil_ricevuta_id, ricevuta.oil_ricevuta_tipo_id,
         ricevuta.oil_progr_ricevuta_id, ricevuta.flusso_elab_mif_id,
         giocassa.conto_evidenza, giocassa.descrizione_conto_evidenza
  from  rprov, ricevuta, giocassa
  where ricevuta.oil_ricevuta_id=rprov.oil_ricevuta_id
  and   giocassa.flusso_elab_mif_id=ricevuta.flusso_elab_mif_id
  and   giocassa.mif_t_giornalecassa_id=ricevuta.oil_progr_ricevuta_id
  ) query, siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='P'
  and   tipo.oil_ricevuta_tipo_id=query.oil_ricevuta_tipo_id
  )
   SELECT provv.ente_proprietario_id,
             provv.provc_tipo_code,
             provv.provc_tipo_desc,
             provv.provc_anno,
             provv.provc_numero,
             provv.provc_causale,
             provv.provc_subcausale,
             provv.provc_denom_soggetto,
             provv.provc_importo,
             provv.provc_data_annullamento,
             provv.provc_data_convalida,
             provv.provc_data_emissione,
             provv.provc_data_regolarizzazione,
             sac.tipo_sac,
             sac.codice_sac,
             provv.provc_data_trasmissione,
             provv.provc_accettato,
             provv.provc_note,
             provc_conto_evidenza.conto_evidenza, -- 28.05.2018 Sofia siac-6126
             provc_conto_evidenza.descrizione_conto_evidenza -- 28.05.2018 Sofia siac-6126
      FROM provv
           LEFT JOIN sac ON sac.provc_id = provv.provc_id
           left join provc_conto_evidenza on (provv.provc_id=provc_conto_evidenza.provc_id) -- 28.05.2018 Sofia siac-6126
      ORDER BY provv.ente_proprietario_id;
	  
-- SIAC-6126 - Sofia - Fine

-- SIAC-6202 - Sofia - Inizio

SELECT fnc_dba_add_column_params(
	'siac_dwh_impegno', 
    'flag_attiva_gsa',
    'varchar(1)'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_subimpegno', 
    'flag_attiva_gsa',
    'varchar(1)'
);


CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_impegno (
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
  flag_attiva_gsa -- 28.05.2018 Sofia siac-6202
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
xx.flag_attiva_gsa -- 28.05.2018 Sofia siac-6102
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


-- SIAC-6202 - Sofia - Fine

-- SIAC-6228 - Sofia - Inizio

ALTER TABLE if exists mif_t_ordinativo_spesa_documenti
  DROP CONSTRAINT if exists mif_t_ordinativo_spesa_mif_t_ordinativo_spesa_doci RESTRICT;
  
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_query='select * from mif_t_ordinativo_spesa_documenti where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id and mif_ord_documento=''E'''
from   mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_nome_file='REVMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='fatture_siope'
and   mif.flusso_elab_mif_code_padre='flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate';

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_query='select * from mif_t_ordinativo_spesa_documenti where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id and mif_ord_documento=''S'''
from   mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_nome_file='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='fatture_siope'
and   mif.flusso_elab_mif_code_padre='flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.classificazione.classificazione_dati_siope_uscite';

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_entrata_splus
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  mifOrdRitrasmElabId integer,
  out flussoElabMifDistOilId integer,
  out flussoElabMifId integer,
  out numeroOrdinativiTrasm integer,
  out nomeFileMif varchar,
  out codiceRisultato integer,
  out messaggioRisultato varchar )
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 strExecSql VARCHAR(1500):='';

 mifOrdinativoIdRec record;

 mifFlussoOrdinativoRec  mif_t_ordinativo_entrata%rowtype;
-- ordinativoRec record;


 enteOilRec record;
 enteProprietarioRec record;
 soggettoRec record;
 isIndirizzoBenef boolean:=false;
 ordRec record;

 bilElemRec record;
 indirizzoRec record;
 ordSostRec record;
 ricevutaRec record;
 quoteOrdinativoRec record;

 flussoElabMifValore varchar (1000):=null;
 flussoElabMifValoreDesc varchar (1000):=null;




 classCdrTipoId INTEGER:=null;
 classCdcTipoId INTEGER:=null;

 codiceCge  varchar(50):=null;
 siopeDef   varchar(50):=null;
 descCge    varchar(500):=null;
 codResult   integer:=null;

 indirizzoEnte varchar(500):=null;
 localitaEnte varchar(500):=null;
 soggettoEnteId INTEGER:=null;
 soggettoRifId integer:=null;
 siopeClassTipoId integer:=null;

 ordTipoCodeId integer :=null;
 ordStatoCodeIId  integer :=null;
 ordStatoCodeAId  integer :=null;
 ordRelazCodeTipoId integer :=null;
 ordDetTsTipoId integer :=null;



 ambitoFinId integer:=null;

 isDefAnnoRedisuo  varchar(5):=null;
 isRicevutaAttivo boolean:=false;
 isGestioneFatture boolean:=false;

 codiceUECodeTipo VARCHAR(50):=null;
 codiceUECodeTipoId integer:=null;


 ordAllegatoCartAttrId integer:=null;
 ordinativoTsDetTipoId integer:=null;
 movgestTsTipoSubId integer:=null;
 ordinativoSpesaTipoId integer:=null;


 flussoElabMifLogId  integer :=null;
 flussoElabMifTipoId integer :=null;
 flussoElabMifTipoNomeFile varchar(500):=null;
 flussoElabMifTipoDec BOOLEAN:=false;

 flussoElabMifOilId integer :=null;
 flussoElabMifDistOilRetId integer:=null;
 mifOrdSpesaId integer:=null;

 NVL_STR               CONSTANT VARCHAR:='';
 dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataFineVal timestamp :=annoBilancio||'-12-31';


 ordImporto numeric :=0;

 dataAvvioSiopeNew VARCHAR(50):=null;
 bAvvioSiopeNew   boolean:=false;


 -- siope plus
 tipoIncassoCode    varchar(100):=null;
 tipoIncassoCodeId  integer:=null;
 tipoRitOrdInc      varchar(100):=null;
 tipoSplitOrdInc    varchar(100):=null;
 tipoSubOrdInc      varchar(100):=null;
 tipoRitenuteInc    varchar(100):=null;
 tipoIncassoCompensazione varchar(100):=null;
 tipoIncassoRegolarizza varchar(100):=null;
 tipoIncassoCassa varchar(100):=null;
 tipoContoCCPCode varchar(100):=null;
 tipoContoCCPCodeId integer:=null;
 siopeCodeTipo varchar(50):=null;
 siopeCodeTipoId integer :=null;
 codiceFinVTbr varchar(50):=null;
 codiceFinVTipoTbrId integer:=null;

 tipoClassFruttifero varchar(100):=null;
 valFruttifero varchar(100):=null;
 valFruttiferoStr varchar(100):=null;
 valFruttiferoStrAltro varchar(100):=null;
 tipoClassFruttiferoId integer:=null;
 valFruttiferoId  integer:=null;
 eventoTipoCodeId integer:=null;
 collEventoCodeId integer:=null;
 ricorrenteCodeTipoId integer:=null;
 ricorrenteCodeTipo varchar(100):=null;

 classVincolatoCode   varchar(100):=null;
 classVincolatoCodeId INTEGER:=null;

 ordCodiceBollo  varchar(10):=null;
 ordCodiceBolloDesc varchar(500):=null;
 codiceBolloPlusDesc   varchar(100):=null;

 codiceBolloPlusEsente boolean:=false;
 isOrdCommerciale boolean:=false;

 attoAmmTipoAllRag varchar(50):=null;
 attoAmmStrTipoRag varchar(50):=null;
 -- siope plus


 ORD_TIPO_CODE_P  CONSTANT  varchar :='P';
 ORD_TIPO_CODE_I  CONSTANT  varchar :='I';
 ORD_STATO_CODE_I CONSTANT  varchar :='I';
 ORD_STATO_CODE_A CONSTANT  varchar :='A';
 ORD_TIPO_IMPORTO_A CONSTANT  varchar :='A';


 AMBITO_FIN CONSTANT  varchar :='AMBITO_FIN';
 ALLEG_CART_ATTR CONSTANT VARCHAR:='flagAllegatoCartaceo';

 CDC CONSTANT varchar:='CDC';
 CDR CONSTANT varchar:='CDR';

 FUNZIONE_CODE_I CONSTANT  varchar :='INSERIMENTO';
 FUNZIONE_CODE_S CONSTANT  varchar :='SOSTITUZIONE';
 FUNZIONE_CODE_N CONSTANT  varchar :='ANNULLO';

 -- annullamenti e variazioni dopo trasmissione
 FUNZIONE_CODE_A CONSTANT  varchar :='ANNULLO';
 FUNZIONE_CODE_VB CONSTANT  varchar :='VARIAZIONE';

 ORD_RELAZ_CODE_SOS  CONSTANT  varchar :='SOS_ORD';
 ORD_TS_DET_TIPO_A CONSTANT varchar:='A';
 MOVGEST_TS_TIPO_S  CONSTANT varchar:='S';


 REGMOVFIN_STATO_A              CONSTANT varchar:='A';
 SEGNO_ECONOMICO				CONSTANT varchar:='Avere';

 SPACE_ASCII CONSTANT integer:=32;
 VT_ASCII CONSTANT integer:=13;
 BS_ASCII CONSTANT integer:=10;

 NUM_SETTE CONSTANT integer:=7;
 ZERO_PAD CONSTANT  varchar :='0';

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='REVMIF_SPLUS';


 SEPARATORE     CONSTANT  varchar :='|';

 mifFlussoElabMifArr flussoElabMifRecType[];

 mifCountTmpRec integer :=null;
 mifCountRec integer:=1;
 mifAFlussoElabTypeRec  flussoElabMifRecType;
 flussoElabMifElabRec  flussoElabMifRecType;
 mifElabRec record;

 tipologiaTipoId integer:=null;
 categoriaTipoId integer:=null;
 famTitEntTipoCategId integer:=null;
 ordinativoSplitId integer:=null;

 -- 20.03.2018 Sofia SIAC-5968
 ordinativoReintroitoId  integer:=null;
 tipoRelREIORD varchar(20):=null;
 tipoRelSPR  varchar(20):=null;
 tipoDocsComm  varchar(50):=null;
 tipoPdcIVA    varchar(50):=null;
 codePdcIVA    varchar(50):=null;

 numeroDocs  varchar(10):=null;
 tipoDocs    varchar(50):=null;
 tipoGruppoDocs   varchar(50):=null;
 docAnalogico varchar(50):=null;
 attrCodeDataScad varchar(50):=null;

 titoloCorrente varchar(10):=null;
 descriTitoloCorrente varchar(50):=null;
 titoloCapitale varchar(10):=null;
 descriTitoloCapitale varchar(50):=null;
 titoloCap varchar(10):=null;
 macroAggrTipoCode varchar(20):=null;
 macroAggrTipoCodeId integer:=null;


 -- 23.02.2018 Sofia jira siac-5849
 defNaturaPag  varchar(100):=null;
 famMacroTitCode varchar(100):=null;
 famMacroTitCodeId integer:=null;

 FAM_TIT_ENT_TIPCATEG CONSTANT varchar:='Entrata - TitoliTipologieCategorie';
 CATEGORIA CONSTANT varchar:='CATEGORIA';
 TIPOLOGIA CONSTANT varchar:='TIPOLOGIA';



 FLUSSO_MIF_ELAB_TEST_COD_ABI_BT      CONSTANT integer:=1;  -- codice_ABI_BT
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA    CONSTANT integer:=4;  -- codice_ente
 FLUSSO_MIF_ELAB_TEST_DESC_ENTE       CONSTANT integer:=5;  -- descrizione_ente
 FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE  CONSTANT integer:=6;  -- codice_istat_ente
 FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE    CONSTANT integer:=7;  -- codice_fiscale_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE CONSTANT integer:=8;  -- codice_tramite_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT   CONSTANT integer:=9;  -- codice_tramite_bt
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT     CONSTANT integer:=10; -- codice_ente_bt
 FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE CONSTANT integer:=11; -- riferimento_ente
 FLUSSO_MIF_ELAB_TEST_ESERCIZIO       CONSTANT integer:=12;  -- esercizio

 FLUSSO_MIF_ELAB_INIZIO_ORD     CONSTANT integer:=13;  -- tipo_operazione
 FLUSSO_MIF_ELAB_FATTURE        CONSTANT integer:=35;  -- codice_ipa_ente_siope
 FLUSSO_MIF_ELAB_FATT_CODFISC   CONSTANT integer:=40;  -- codice_fiscale_emittente_siope
 FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG  CONSTANT integer:=44;  -- data_scadenza_pagam_siope
 FLUSSO_MIF_ELAB_FATT_NATURA_PAG CONSTANT integer:=46;  -- natura_spesa_siope
 FLUSSO_MIF_ELAB_NUM_SOSPESO    CONSTANT integer:=62;  -- numero_provvisorio



BEGIN

	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;

    flussoElabMifDistOilId:=null;

	strMessaggioFinale:='Invio ordinativi di entrata a SIOPE PLUS.';


    -- enteOilRec
    strMessaggio:='Lettura dati ente OIL  per flusso MIF tipo '||MANDMIF_TIPO||'.';
    select * into strict enteOilRec
    from siac_t_ente_oil ente
    where ente.ente_proprietario_id=enteProprietarioId
    and   ente.data_cancellazione is null
    and   ente.validita_fine is null;

    if enteOilRec is null then
    	raise exception ' Errore in reperimento dati';
    end if;

    if enteOilRec.ente_oil_siope_plus=false then
    	raise exception ' SIOPE PLUS non attivo per l''ente.';
    end if;

    -- inserimento record in tabella mif_t_flusso_elaborato
    strMessaggio:='Inserimento mif_t_flusso_elaborato tipo_flusso='||MANDMIF_TIPO||'.';

    insert into mif_t_flusso_elaborato
    (flusso_elab_mif_data ,
     flusso_elab_mif_esito,
     flusso_elab_mif_esito_msg,
     flusso_elab_mif_file_nome,
     flusso_elab_mif_tipo_id,
     flusso_elab_mif_id_flusso_oil, -- da calcolare su tab progressivi
     validita_inizio,
     ente_proprietario_id,
     login_operazione)
     (select dataElaborazione,
             ELAB_MIF_ESITO_IN,
             'Elaborazione in corso per tipo flusso '||MANDMIF_TIPO,
      		 tipo.flusso_elab_mif_nome_file,
     		 tipo.flusso_elab_mif_tipo_id,
     		 null,--flussoElabMifOilId, -- da calcolare su tab progressivi
    		 dataElaborazione,
     		 enteProprietarioId,
      		 loginOperazione
      from mif_d_flusso_elaborato_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null
     )
     returning flusso_elab_mif_id into flussoElabMifLogId;-- valore da restituire

      raise notice 'flussoElabMifLogId %',flussoElabMifLogId;

     if flussoElabMifLogId is null then
       RAISE EXCEPTION ' Errore generico in inserimento %.',MANDMIF_TIPO;
     end if;

    strMessaggio:='Verifica esistenza elaborazioni in corso per tipo flusso '||MANDMIF_TIPO||'.';
	codResult:=null;
    select distinct 1 into codResult
    from mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
    where  elab.flusso_elab_mif_id!=flussoElabMifLogId
    and    elab.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN
    and    elab.data_cancellazione is null
    and    elab.validita_fine is null
    and    tipo.flusso_elab_mif_tipo_id=elab.flusso_elab_mif_tipo_id
    and    tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
    and    tipo.ente_proprietario_id=enteProprietarioId
    and    tipo.data_cancellazione is null
    and    tipo.validita_fine is null;

    if codResult is not null then
    	RAISE EXCEPTION ' Verificare situazioni esistenti.';
    end if;

    -- verifico se la tabella degli id contiene dati in tal caso elaborazioni precedenti sono andate male
    strMessaggio:='Verifica esistenza dati in tabella temporanea id [mif_t_ordinativo_entrata_id].';
    codResult:=null;

    select distinct 1 into codResult
    from mif_t_ordinativo_entrata_id mif
    where mif.ente_proprietario_id=enteProprietarioId;


    if codResult is not null then
      RAISE EXCEPTION ' Dati presenti verificarne il contenuto ed effettuare pulizia prima di rieseguire.';
    end if;



    codResult:=null;
    -- recupero indentificativi tipi codice vari
	begin

        -- ordTipoCodeId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_I||'.';
        select ord_tipo.ord_tipo_id into strict ordTipoCodeId
        from siac_d_ordinativo_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_tipo_code=ORD_TIPO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

		-- ordinativoSpesaTipoId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_P||'.';
        select ord_tipo.ord_tipo_id into strict ordinativoSpesaTipoId
        from siac_d_ordinativo_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_tipo_code=ORD_TIPO_CODE_P
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

		-- ordStatoCodeIId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_I||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeIId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

        -- ordStatoCodeAId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_A||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeAId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- classCdrTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDR||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDR
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

        -- classCdcTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDC||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDC
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


		-- ordAllegatoCartAttrId
        strMessaggio:='Lettura attributo ordinativo  Code Id '||ALLEG_CART_ATTR||'.';
        select attr.attr_id into strict ordAllegatoCartAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=ALLEG_CART_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));

		-- ordDetTsTipoId
        strMessaggio:='Lettura tipo importo ordinativo  Code Id '||ORD_TIPO_IMPORTO_A||'.';
        select ord_tipo.ord_ts_det_tipo_id into strict ordDetTsTipoId
        from siac_d_ordinativo_ts_det_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_ts_det_tipo_code=ORD_TIPO_IMPORTO_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));



		-- ordinativoTsDetTipoId
        strMessaggio:='Lettura ordinativo_ts_det_tipo '||ORD_TS_DET_TIPO_A||'.';
		select ord_tipo.ord_ts_det_tipo_id into strict ordinativoTsDetTipoId
    	from siac_d_ordinativo_ts_det_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

        -- movgestTsTipoSubId
        strMessaggio:='Lettura movgest_ts_tipo  '||MOVGEST_TS_TIPO_S||'.';
		select ord_tipo.movgest_ts_tipo_id into strict movgestTsTipoSubId
    	from siac_d_movgest_ts_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.movgest_ts_tipo_code=MOVGEST_TS_TIPO_S
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

        -- ordRelazCodeTipoId
        strMessaggio:='Lettura relazione   Code Id '||ORD_RELAZ_CODE_SOS||'.';
		select ord_tipo.relaz_tipo_id into strict ordRelazCodeTipoId
    	from siac_d_relaz_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.relaz_tipo_code=ORD_RELAZ_CODE_SOS
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ambitoFinId
        strMessaggio:='Lettura ambito  Code Id '||AMBITO_FIN||'.';
        select a.ambito_id into strict ambitoFinId
        from siac_d_ambito a
        where a.ente_proprietario_id=enteProprietarioId
   		and   a.ambito_code=AMBITO_FIN
        and   a.data_cancellazione is null
        and   a.validita_fine is null;

		-- tipologiaTipoId
        strMessaggio:='Lettura tipologia_code_tipo_id  '||TIPOLOGIA||'.';
		select tipo.classif_tipo_id into strict tipologiaTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=TIPOLOGIA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

   	    -- categoriaTipoId
        strMessaggio:='Lettura categoria_code_tipo_id  '||CATEGORIA||'.';
		select tipo.classif_tipo_id into strict categoriaTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=CATEGORIA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));


		-- famTitEntTipoCategId
		-- FAM_TIT_ENT_TIPCATEG='Entrata - TitoliTipologieCategorie'
        strMessaggio:='Lettura fam_tit_ent_tipcategorie_code_tipo_id  '||FAM_TIT_ENT_TIPCATEG||'.';
		select fam.classif_fam_tree_id into strict famTitEntTipoCategId
        from siac_t_class_fam_tree fam
        where fam.ente_proprietario_id=enteProprietarioId
        and   fam.class_fam_code=FAM_TIT_ENT_TIPCATEG
        and   fam.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
  		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(fam.validita_fine,dataElaborazione));

        -- flussoElabMifTipoId
        strMessaggio:='Lettura tipo flusso MIF  Code Id '||MANDMIF_TIPO||'.';
        select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file, tipo.flusso_elab_mif_tipo_dec
               into strict flussoElabMifTipoId,flussoElabMifTipoNomeFile,flussoElabMifTipoDec
        from mif_d_flusso_elaborato_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
   		and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        -- raise notice 'flussoElabMifTipoId %',flussoElabMifTipoId;


        strMessaggio:='Lettura flusso struttura SIOPE PLUS  per tipo '||MANDMIF_TIPO||'.';
        for mifElabRec IN
        (select m.*
         from mif_d_flusso_elaborato m
         where m.flusso_elab_mif_tipo_id=flussoElabMifTipoId
         and   m.flusso_elab_mif_elab=true
         order by m.flusso_elab_mif_ordine_elab
        )
        loop
        	mifAFlussoElabTypeRec.flussoElabMifId :=mifElabRec.flusso_elab_mif_id;
            mifAFlussoElabTypeRec.flussoElabMifAttivo :=mifElabRec.flusso_elab_mif_attivo;
            mifAFlussoElabTypeRec.flussoElabMifDef :=mifElabRec.flusso_elab_mif_default;
            mifAFlussoElabTypeRec.flussoElabMifElab :=mifElabRec.flusso_elab_mif_elab;
            mifAFlussoElabTypeRec.flussoElabMifParam :=mifElabRec.flusso_elab_mif_param;

            mifAFlussoElabTypeRec.flusso_elab_mif_ordine_elab :=mifElabRec.flusso_elab_mif_ordine_elab;

            mifAFlussoElabTypeRec.flusso_elab_mif_ordine :=mifElabRec.flusso_elab_mif_ordine;

            mifAFlussoElabTypeRec.flusso_elab_mif_code :=mifElabRec.flusso_elab_mif_code;
            mifAFlussoElabTypeRec.flusso_elab_mif_campo :=mifElabRec.flusso_elab_mif_campo;

            mifFlussoElabMifArr[mifElabRec.flusso_elab_mif_ordine_elab]:=mifAFlussoElabTypeRec;

        end loop;


        -- enteProprietarioRec
        strMessaggio:='Lettura dati ente proprietario per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';
        select * into strict enteProprietarioRec
        from siac_t_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        -- soggettoEnteId
        strMessaggio:='Lettura indirizzo ente proprietario [siac_r_soggetto_ente_proprietario] per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';
        select ente.soggetto_id into soggettoEnteId
        from siac_r_soggetto_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        if soggettoEnteId is not null then
            strMessaggio:='Lettura indirizzo ente proprietario [siac_t_indirizzo_soggetto] per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';

        	select viaTipo.via_tipo_code||' '||indir.toponimo||' '||indir.numero_civico,
        		   com.comune_desc
                   into indirizzoEnte,localitaEnte
            from siac_t_indirizzo_soggetto indir,
                 siac_t_comune com,
                 siac_d_via_tipo viaTipo
            where indir.soggetto_id=soggettoEnteId
            and   indir.principale='S'
            and   indir.data_cancellazione is null
            and   indir.validita_fine is null
            and   com.comune_id=indir.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null
            and   viaTipo.via_tipo_id=indir.via_tipo_id
            and   viaTipo.data_cancellazione is null
	   		and   date_trunc('day',dataElaborazione)>=date_trunc('day',viaTipo.validita_inizio)
 			and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(viaTipo.validita_fine,dataElaborazione))
            order by indir.indirizzo_id;
        end if;


        -- calcolo progressivo "distinta" per flusso REVMIF
	    -- calcolo su progressi di flussoElabMifDistOilId flussoOIL univoco per tipo flusso
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';
        codResult:=null;

        select prog.prog_value into flussoElabMifDistOilRetId
          from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifDistOilRetId is null then
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_'||MANDMIF_TIPO||'_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifDistOilRetId:=0;
            end if;
        end if;

        if flussoElabMifDistOilRetId is not null then
	        flussoElabMifDistOilRetId:=flussoElabMifDistOilRetId+1;
        end if;


	    -- calcolo su progressi di flussoElabMifOilId flussoOIL univoco
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
        select prog.prog_value into flussoElabMifOilId
        from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_out_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifOilId is null then
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_out_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifOilId:=0;
            end if;
        end if;

        if flussoElabMifOilId is not null then
	        flussoElabMifOilId:=flussoElabMifOilId+1;
        end if;

        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
        when TOO_MANY_ROWS THEN
            RAISE EXCEPTION ' Diverse righe presenti in archivio.';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;




    --- popolamento mif_t_ordinativo_entrata_id


    -- ordinativi emessi o emessi/spostati non ancora mai trasmessi codice_funzione='I'
    strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_I||'.';

    insert into mif_t_ordinativo_entrata_id
    (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
     mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
     mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
     mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
     mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
     mif_ord_codbollo_id,
     mif_ord_login_creazione,mif_ord_login_modifica,
     ente_proprietario_id, login_operazione)
    (
     with
     ritrasm as
     (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	  from mif_t_ordinativo_ritrasmesso r
	  where mifOrdRitrasmElabId is not null
	  and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	  and   r.ente_proprietario_id=enteProprietarioId
	  and   r.data_cancellazione is null),
     ordinativi as
     (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_I mif_ord_codice_funzione,
             bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
             ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
             extract('year' from ord.ord_emissione_data)||'-'||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
             0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
             0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,ord.contotes_id mif_ord_contotes_id,
             ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id, ord.ord_desc mif_ord_desc ,
             ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
             ord.codbollo_id mif_ord_codbollo_id,
             ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
             enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
      from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,siac_t_bil bil, siac_t_periodo per,siac_r_ordinativo_bil_elem elem
      where  bil.ente_proprietario_id=enteProprietarioId
        and  per.periodo_id=bil.periodo_id
        and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord_stato.ord_id=ord.ord_id
         and  ord_stato.data_cancellazione is null
	   	 and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
		 and  ord_stato.validita_fine is null
         and  ord_stato.ord_stato_id=ordStatoCodeIId
         and  ord.ord_trasm_oil_data is null
         and  ord.ord_emissione_data<=dataElaborazione
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  not exists (select 1 from siac_r_ordinativo rord
                          where rord.ord_id_a=ord.ord_id
                          and   rord.data_cancellazione is null
                          and   rord.validita_fine is null
			              and   rord.relaz_tipo_id=ordRelazCodeTipoId)
      )
      select   o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
      from ordinativi o
	  where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );


      -- ordinativi emessi o emessi/spostati non ancora mai trasmessi, sostituzione di altro ordinativo codice_funzione='S'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_S||'.';

      insert into mif_t_ordinativo_entrata_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
	   with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_S mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
               ord.login_creazione mif_ord_login_creazione, ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem,siac_r_ordinativo rord
  	    where  bil.ente_proprietario_id=enteProprietarioId
   		  and  per.periodo_id=bil.periodo_id
    	  and  per.anno::integer <=annoBilancio::integer
    	  and  ord.bil_id=bil.bil_id
    	  and  ord.ord_tipo_id=ordTipoCodeId
    	  and  ord_stato.ord_id=ord.ord_id
    	  and  ord_stato.data_cancellazione is null
	   	  and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
          and  ord_stato.validita_fine is null
    	  and  ord_stato.ord_stato_id=ordStatoCodeIId
	      and  ord.ord_trasm_oil_data is null
    	  and  ord.ord_emissione_data<=dataElaborazione
    	  and  elem.ord_id=ord.ord_id
    	  and  elem.data_cancellazione is null
          and  elem.validita_fine is null
          and  rord.ord_id_a=ord.ord_id
          and  rord.relaz_tipo_id=ordRelazCodeTipoId
          and  rord.data_cancellazione is null
          and  rord.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );

      -- ordinativi emessi e annullati mai trasmessi codice_funzione='N'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_N||'.';

	  insert into mif_t_ordinativo_entrata_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
	   with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_N mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
      	 	   ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord, siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord_stato.ord_id=ord.ord_id
         and  ord_stato.validita_inizio<=dataElaborazione -- questa e'' la data di annullamento
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord_stato.data_cancellazione is null
         and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
   		 and  ord_stato.validita_fine is null
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ord.ord_trasm_oil_data is null
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        ),
        -- 16.04.2018 Sofia siac-6067
        enteOil as
        (
         select false esclAnnull
         from siac_t_ente_oil oil
         where oil.ente_proprietario_id=enteProprietarioId
         and   oil.ente_oil_invio_escl_annulli=false
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o, enteOil -- 16.04.2018 Sofia siac-6067
	    where
        ( mifOrdRitrasmElabId is null
	      or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
        ) -- 16.04.2018 Sofia siac-6067
        and  enteOil.esclAnnull=false -- 16.04.2018 Sofia siac-6067
	   );

      -- ordinativi emessi tramessi e poi annullati, anche dopo spostamento  codice_funzione='A'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_A||'.';

      insert into mif_t_ordinativo_entrata_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
	   with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_A mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id, ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
   		 and  ord_stato.ord_id=ord.ord_id
  		 and  ord.ord_emissione_data<=dataElaborazione
         and  ord_stato.validita_inizio<=dataElaborazione  -- questa e'' la data di annullamento
  		 and  ord.ord_trasm_oil_data is not null
 		 and  ord.ord_trasm_oil_data<ord_stato.validita_inizio
         and  ord_stato.data_cancellazione is null
         and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
         and  ord_stato.validita_fine is null -- SofiaData
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ( ord.ord_spostamento_data is null or ord.ord_spostamento_data<ord_stato.validita_inizio)
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );

      -- ordinativi emessi , trasmessi  e poi spostati codice_funzione='VB' ( mai annullati )
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_VB||'.';

      insert into mif_t_ordinativo_entrata_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil ,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
	   with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_VB mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord.ord_trasm_oil_data is not null
         and  ord.ord_spostamento_data is not null
         and  ord.ord_trasm_oil_data<ord.ord_spostamento_data
         and  ord.ord_spostamento_data<=dataElaborazione
         and  not exists (select 1 from siac_r_ordinativo_stato ord_stato
  				          where  ord_stato.ord_id=ord.ord_id
					        and  ord_stato.ord_stato_id=ordStatoCodeAId
                            and  ord_stato.data_cancellazione is null)
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
		select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );

      -- aggiornamento mif_t_ordinativo_entrata_id per id


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per soggetto_id.';
      -- soggetto_id
      update mif_t_ordinativo_entrata_id m
      set mif_ord_soggetto_id = (select s.soggetto_id from siac_r_ordinativo_soggetto s
                                 where s.ord_id=m.mif_ord_ord_id
                                   and s.data_cancellazione is null
                                   and s.validita_fine is null);

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per subord_id.';

      -- subord_id
      update mif_t_ordinativo_entrata_id m
      set mif_ord_subord_id =
                             (select s.ord_ts_id from siac_t_ordinativo_ts s
                               where s.ord_id=m.mif_ord_ord_id
                                 and s.data_cancellazione is null
                                 and s.validita_fine is null
                               order by s.ord_ts_id
                               limit 1);



     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_ts_id.';

     -- movgest_ts_id
     update mif_t_ordinativo_entrata_id m
     set mif_ord_movgest_ts_id = (select ts.movgest_ts_id from siac_t_ordinativo_ts s, siac_r_ordinativo_ts_movgest_ts ts
	                              where s.ord_id=m.mif_ord_ord_id
                                  and   ts.ord_ts_id=s.ord_ts_id
                                  and   s.data_cancellazione is null
                                  and   s.validita_fine is null
                                  and   ts.data_cancellazione is null
                                  and   ts.validita_fine is null
                                  order by s.ord_ts_id
                                  limit 1);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_id.';

     -- movgest_id
     update mif_t_ordinativo_entrata_id m
     set mif_ord_movgest_id = (select s.movgest_id from siac_t_movgest_ts s
                               where  s.movgest_ts_id = m.mif_ord_movgest_ts_id
                               and s.data_cancellazione is null
                               and s.validita_fine is null);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_id.';

     -- movgest_anno
     update mif_t_ordinativo_entrata_id m
     set mif_ord_ord_anno_movg = (select s.movgest_anno from siac_t_movgest s
                              	  where  s.movgest_id = m.mif_ord_movgest_id
                             	  and s.data_cancellazione is null
                                  and s.validita_fine is null);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per attoamm_id.';

    -- attoamm_id
    update mif_t_ordinativo_entrata_id m
    set mif_ord_atto_amm_id = (select s.attoamm_id from siac_r_ordinativo_atto_amm s
                                where s.ord_id = m.mif_ord_ord_id
                                  and s.data_cancellazione is null
                                  and s.validita_fine is null);


    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per attoamm_id movgest_ts.';
	-- attoamm_movgest_ts_id
    update mif_t_ordinativo_entrata_id m
    set mif_ord_atto_amm_movg_id = (select s.attoamm_id from siac_r_movgest_ts_atto_amm s
                                    where s.movgest_ts_id = m.mif_ord_movgest_ts_id
                                    and s.data_cancellazione is null
                                    and s.validita_fine is null);


	-- mif_ord_tipologia_id
    -- mif_ord_tipologia_code
    -- mif_ord_tipologia_desc
	strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per mif_ord_tipologia_id mif_ord_tipologia_code mif_ord_tipologia_desc.';
	update mif_t_ordinativo_entrata_id m
    set (mif_ord_tipologia_id, mif_ord_tipologia_code,mif_ord_tipologia_desc) = (cp.classif_id,cp.classif_code,cp.classif_desc)
    from  siac_r_bil_elem_class classElem, siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
	where classElem.elem_id= m.mif_ord_elem_id
	and   cf.classif_id=classElem.classif_id
	and   cf.data_cancellazione is null
	and   cf.classif_tipo_id= categoriaTipoid -- categoria
	and   r.classif_id=cf.classif_id
	and   r.classif_id_padre is not null
	and   r.classif_fam_tree_id=famTitEntTipoCategId -- famiglia
	and   r.data_cancellazione is null
	and   r.validita_fine is null
	and   classElem.data_cancellazione is null
	and   classElem.validita_fine is null
	and   cp.classif_id=r.classif_id_padre
	and   cp.data_cancellazione is null
	and   cp.classif_tipo_id=tipologiaTipoid; --tipologia

    strMessaggio:='Verifica esistenza ordinativi di entrata da trasmettere.';
    codResult:=null;

    select 1 into codResult
    from mif_t_ordinativo_entrata_id where ente_proprietario_id=enteProprietarioId;

    if codResult is null then
      codResult:=-12;
      RAISE EXCEPTION ' Nessun ordinativo di entrata da trasmettere.';
    end if;




   -- <sospesi>
   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_NUM_SOSPESO];

   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   raise notice 'numero_provvisorio FLUSSO_MIF_ELAB_NUM_SOSPESO=% strMessaggio=%',FLUSSO_MIF_ELAB_NUM_SOSPESO,strMessaggio;

   if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
			isRicevutaAttivo:=true;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
   		end if;
   end if;


   flussoElabMifElabRec:=null;
   mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    numeroDocs:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            tipoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            tipoGruppoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            if numeroDocs is not null and numeroDocs!='' and
               tipoDocs is not null and tipoDocs!='' and
               tipoGruppoDocs is not null and tipoGruppoDocs!='' then
                tipoDocs:=tipoDocs||'|'||tipoGruppoDocs;
            	isGestioneFatture:=true;
            end if;
		end if;
    else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
    end if;
   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_CODFISC;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    docAnalogico:=flussoElabMifElabRec.flussoElabMifParam;
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then
    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            attrCodeDataScad:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_NATURA_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            /* 23.02.2018 Sofia JIRA siac-5849
            titoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            descriTitoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            titoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            descriTitoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
            macroAggrTipoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
            if macroAggrTipoCode is not null then
            	strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificato classificatore tipo='||macroAggrTipoCode||'.';
            	select tipo.classif_tipo_id into macroAggrTipoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=macroAggrTipoCode
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;

            end if;*/

            -- 23.02.2018 Sofia JIRA siac-5849
            macroAggrTipoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            if macroAggrTipoCode is not null then
            	strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificato classificatore tipo='||macroAggrTipoCode||'.';
            	select tipo.classif_tipo_id into macroAggrTipoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=macroAggrTipoCode
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;

            end if;
            -- 23.02.2018 Sofia JIRA siac-5849
            famMacroTitCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            if famMacroTitCode is not null then
	            strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificato famiglia tipo='||famMacroTitCode||'.';
	            select tree.classif_fam_tree_id into famMacroTitCodeId
				from siac_t_class_fam_tree tree, siac_d_class_fam d
				where d.ente_proprietario_id=enteProprietarioId
				and   d.classif_fam_desc=famMacroTitCode --'Spesa - TitoliMacroaggregati'
				and   tree.classif_fam_id=d.classif_fam_id
                and   tree.data_cancellazione is null
                and   tree.validita_fine is null
                and   d.data_cancellazione is null
                and   d.validita_fine is null;

            end if;

			-- 23.02.2018 Sofia JIRA siac-5849
	        if flussoElabMifElabRec.flussoElabMifDef is not null then
        		defNaturaPag:=flussoElabMifElabRec.flussoElabMifDef;
    	    end if;

		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

    --- lettura mif_t_ordinativo_entrata_id per popolamento mif_t_ordinativo_entrata
    codResult:=null;
    strMessaggio:='Lettura ordinativi di entrata da migrare [mif_t_ordinativo_entrata_id].Inizio ciclo.';
    for mifOrdinativoIdRec IN
    (select ms.*
     from mif_t_ordinativo_entrata_id ms
     where ms.ente_proprietario_id=enteProprietarioId
     order by ms.mif_ord_anno_bil,
              ms.mif_ord_ord_numero
    )
    loop

--		raise notice 'Inizio ciclo numero_ord=%',mifOrdinativoIdRec.mif_ord_ord_numero;
		mifFlussoOrdinativoRec:=null;
		bilElemRec:=null;
        soggettoRec:=null;

        soggettoRifId:=null;

		indirizzoRec:=null;
        mifOrdSpesaId:=null;
	    mifCountRec:=1;
		isIndirizzoBenef:=true;
        bAvvioSiopeNew:=false;

        -- lettura importo ordinativo
		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura importo ordinativo di entrata per tipo flusso '||MANDMIF_TIPO||'.';

        mifFlussoOrdinativoRec.mif_ord_importo:=fnc_mif_importo_ordinativo(mifOrdinativoIdRec.mif_ord_ord_id,ordDetTsTipoId,
        										flussoElabMifTipoDec);
        if flussoElabMifTipoDec=true and
           coalesce(position('.' in mifFlussoOrdinativoRec.mif_ord_importo),0)=0 then
           mifFlussoOrdinativoRec.mif_ord_importo:=mifFlussoOrdinativoRec.mif_ord_importo||'.00';
        end if;

        -- lettura dati soggetto ordinativo
        soggettoRifId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        select * into soggettoRec
   	    from siac_t_soggetto sogg
       	where sogg.soggetto_id=soggettoRifId;

        if soggettoRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id= %].',soggettoRifId;
        end if;


        -- lettura elemento bilancio  ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura elemento bilancio ordinativo di entrata per tipo flusso '||MANDMIF_TIPO||'.';

		select * into bilElemRec
        from siac_t_bil_elem elem
        where elem.elem_id=mifOrdinativoIdRec.mif_ord_elem_id;
        if bilElemRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_bil_elem.';
        end if;

        -- dati testata flusso presenti come tag solo in testata
        -- valorizzati su ogni ordinativo trasmesso
        -- <testata_flusso>
		-- <codice_ABI_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ABI_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_abi is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=enteOilRec.ente_oil_abi;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_ipa is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=trim(both ' ' from enteOilRec.ente_oil_codice_ipa);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <descrizione_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_DESC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.ente_denominazione is not null then
            	mifFlussoOrdinativoRec.mif_ord_desc_ente:=enteProprietarioRec.ente_denominazione;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_desc_ente:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

	    -- <codice_istat_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_istat is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=enteOilRec.ente_oil_codice_istat;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_fiscale_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.codice_fiscale is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=trim(both ' ' from enteProprietarioRec.codice_fiscale);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite_bt is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite_bt);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=trim(both ' ' from enteOilRec.ente_oil_codice);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <riferimento_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_riferimento is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=trim(both ' ' from enteOilRec.ente_oil_riferimento);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_flusso>

        -- <testata_esercizio>
        -- <esercizio>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_ESERCIZIO;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            mifFlussoOrdinativoRec.mif_ord_anno_esercizio:=mifOrdinativoIdRec.mif_ord_anno_bil;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_esercizio>

		-- <reversale>
        mifCountRec :=FLUSSO_MIF_ELAB_INIZIO_ORD;

	    -- <tipo_operazione>
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        raise notice 'tipo_operazione strMessaggio=%',strMessaggio;
        if  flussoElabMifElabRec.flussoElabMifAttivo=true then
         if   flussoElabMifElabRec.flussoElabMifElab=true then
            if flussoElabMifElabRec.flussoElabMifParam is not null then
	            flussoElabMifValore:=fnc_mif_ordinativo_carico_bollo( mifOrdinativoIdRec.mif_ord_codice_funzione,flussoElabMifElabRec.flussoElabMifParam);
            else
            	flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_codice_funzione;
            end if;

            if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_codice_funzione:=flussoElabMifValore;
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <numero_reversale>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifTipoDec=false then
				mifFlussoOrdinativoRec.mif_ord_numero:=lpad(mifOrdinativoIdRec.mif_ord_ord_numero,NUM_SETTE,ZERO_PAD);
            else
	            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non elaborabile.';
         end if;
        end if;


        -- <data_reversale>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true  then
         if  flussoElabMifElabRec.flussoElabMifElab=true then
			mifFlussoOrdinativoRec.mif_ord_data:=mifOrdinativoIdRec.mif_ord_data_emissione;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non  elaborabile.';
         end if;
        end if;

		-- <importo_reversale>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			-- calcolato inizio ciclo
            null;
         else
         	mifFlussoOrdinativoRec.mif_ord_importo:='0';
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <conto_evidenza>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            if mifOrdinativoIdRec.mif_ord_contotes_id is not null then
                 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura conto tesoreria.';

            	select d.contotes_code into flussoElabMifValore
                from siac_d_contotesoreria d
                where d.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id;
                if flussoElabMifValore is null then
                	RAISE EXCEPTION ' Dato non presente in archivio.';
                end if;
            end if;

			if flussoElabMifValore is not null then
             mifFlussoOrdinativoRec.mif_ord_destinazione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <bilancio>
        -- <codifica_bilancio>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        raise notice 'codifica_bilancio strMessaggio=%',strMessaggio;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

         		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio:=
                    substring(mifOrdinativoIdRec.mif_ord_tipologia_code from 1 for 5) ;
            	mifFlussoOrdinativoRec.mif_ord_capitolo:=bilElemRec.elem_code;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


	    -- <descrizione_codifica>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_desc_codifica:=substring( bilElemRec.elem_desc from 1 for 30);
                mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil:=substring( mifOrdinativoIdRec.mif_ord_tipologia_desc from 1 for 30);
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <gestione>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifDef is not null then
            	if mifOrdinativoIdRec.mif_ord_anno_bil=mifOrdinativoIdRec.mif_ord_ord_anno_movg then
	            	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                else
	                flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                end if;
            	mifFlussoOrdinativoRec.mif_ord_gestione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <anno_residuo>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
		  if mifOrdinativoIdRec.mif_ord_anno_bil!=mifOrdinativoIdRec.mif_ord_ord_anno_movg  then
       	 	mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
          end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

		-- <numero_articolo>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_articolo:=bilElemRec.elem_code2;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <voce_economica>
        mifCountRec:=mifCountRec+1;

        -- <importo_bilancio>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           	mifFlussoOrdinativoRec.mif_ord_importo_bil:=mifFlussoOrdinativoRec.mif_ord_importo;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </bilancio>

	    -- <informazioni_versante>

        -- <progressivo_versante>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        raise notice 'progressivo_versante strMessaggio=%',strMessaggio;

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_vers:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <importo_versante>
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  	 	 RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	 if flussoElabMifElabRec.flussoElabMifElab=true then
     		mifFlussoOrdinativoRec.mif_ord_vers_importo:=mifFlussoOrdinativoRec.mif_ord_importo;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
        end if;

	    -- <tipo_riscossione>
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
	    flussoElabMifValore:=null;
        flussoElabMifValoreDesc:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
           RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
            if coalesce(flussoElabMifElabRec.flussoElabMifParam,NVL_STR)!=NVL_STR and
               coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
              if  tipoIncassoCode is null then
            	tipoIncassoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
              end if;
              if tipoRitOrdInc is null then
	              tipoRitOrdInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
              end if;
              if tipoSplitOrdInc is null then
	              tipoSplitOrdInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
              end if;
              if tipoSubOrdInc is null then
	              tipoSubOrdInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
              end if;

              if tipoRitenuteInc is null then
              	tipoRitenuteInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5))||','||
                                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6))||','||
                                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,7));
              end if;

			  if tipoIncassoCompensazione is null then
              	tipoIncassoCompensazione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
              end if;
   			  if tipoIncassoRegolarizza is null then
              	tipoIncassoRegolarizza:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
              end if;

   			  if tipoIncassoCassa is null then
              	tipoIncassoCassa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,3));
              end if;

              if tipoIncassoCode is not null and tipoIncassoCodeId is null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classif_tipo_id per classicatore '||tipoIncassoCode||'.';
              	select tipo.classif_tipo_id into tipoIncassoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=tipoIncassoCode
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;

              end if;

              if tipoIncassoCodeId is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura tipoIncasso '||tipoIncassoCode||' per ordinativo.';

                flussoElabMifValore:=fnc_mif_tipo_incasso_splus
                                     ( mifOrdinativoIdRec.mif_ord_ord_id,
  									   mifFlussoOrdinativoRec.mif_ord_importo::NUMERIC,
                                       tipoRitOrdInc,
                                       tipoSplitOrdInc,
                                       tipoSubOrdInc,
                                       tipoRitenuteInc,
 									   tipoIncassoCodeId,
                                       tipoIncassoCompensazione,
                                       tipoIncassoRegolarizza,
                                       tipoIncassoCassa,
                                       dataElaborazione,
                                       dataFineVal,
                                       enteProprietarioId
                                     );
              end if;

		     if flussoElabMifValore is not null then
	           mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos:=flussoElabMifValore;
             end if;
           end if;
          else
          	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;

	    -- <numero_ccp>
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
	    flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
           RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	if flussoElabMifElabRec.flussoElabMifParam is not null and
               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos is not null then
               if mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) then
                  if tipoContoCCPCode is null then
                  	tipoContoCCPCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                  end if;
                  if tipoContoCCPCodeId is null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificativo classificatore tipo='||tipoContoCCPCode||'.';
                  	select tipo.classif_tipo_id into tipoContoCCPCodeId
                    from siac_d_class_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.classif_tipo_code=tipoContoCCPCode
                    and   tipo.data_cancellazione is null;
                  end if;

                  if tipoContoCCPCodeId is not null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore classificatore tipo='||tipoContoCCPCode||'.';
                  	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoContoCCPCodeId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   c.data_cancellazione is null;
                  end if;
               end if;
               if flussoElabMifValore is not null then
               	mifFlussoOrdinativoRec.mif_ord_vers_cc_postale:=flussoElabMifValore;
               end if;
            end if;
           else
          	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;

		-- <tipo_entrata>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			if coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
              if coalesce(flussoElabMifElabRec.flussoElabMifParam,NVL_STR)!=NVL_STR then
                   if tipoClassFruttifero is null then
                    	tipoClassFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                   end if;

                   if tipoClassFruttifero is not null and valFruttifero is null then
	                   valFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                       valFruttiferoStr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                       valFruttiferoStrAltro:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                   end if;


                   if tipoClassFruttifero is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      tipoClassFruttiferoId is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classifTipoCodeId '||tipoClassFruttifero||'.';
                   	select tipo.classif_tipo_id into tipoClassFruttiferoId
                    from siac_d_class_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.classif_tipo_code=tipoClassFruttifero
                    and   tipo.data_cancellazione is null
                    and   tipo.validita_fine is null;

                   end if;
                   if tipoClassFruttiferoId is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      valFruttiferoId is null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classidId '||tipoClassFruttifero||' [siac_r_ordinativo_class].';


                   	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	                and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoClassFruttiferoId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   c.data_cancellazione is null
                    order by r.ord_classif_id limit 1;

                    if flussoElabMifValore is not null then
                    	if flussoElabMifValore=valFruttifero THEN
                        	flussoElabMifValore=valFruttiferoStr;
                        else
                          flussoElabMifValore=valFruttiferoStrAltro;
                        end if;
                    end if;
                   end if;
				 end if; -- param


	             if flussoElabMifValore is null and
     	            mifOrdinativoIdRec.mif_ord_contotes_id is not null and
        	        mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

    	            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
        	               ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
            	           ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                	       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
	                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
    	                   ||' mifCountRec='||mifCountRec
        	               ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_fruttifero].';
	                -- 16.02.2018 Sofia siac-5874
                    select mif.fruttifero_oi into flussoElabMifValore
    	            from mif_r_conto_tesoreria_fruttifero mif
	                where mif.ente_proprietario_id=enteProprietarioId
    	            and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
	                and   mif.validita_fine is null
    	            and   mif.data_cancellazione is null;


	             end if;


                 if flussoElabMifValore is null then
                   	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                 end if;

                 mifFlussoOrdinativoRec.mif_ord_bci_tipo_entrata:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


		-- <destinazione>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
		   if flussoElabMifElabRec.flussoElabMifParam is not null then

           	if classVincolatoCode is null then
            	classVincolatoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

            if classVincolatoCodeId is null and classVincolatoCode is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificativo classVincolatoCode='||classVincolatoCode||'.';

                select tipo.classif_tipo_id into strict classVincolatoCodeId
    		    from siac_d_class_tipo tipo
		        where tipo.ente_proprietario_id=enteProprietarioId
        		and   tipo.classif_tipo_code=classVincolatoCode
		        and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;
            end if;

            if classVincolatoCodeId is not null then
	            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore classVincolatoCode='||classVincolatoCode||'.';


                 select c.classif_desc into flussoElabMifValore
                 from siac_r_ordinativo_class r, siac_t_class c
                 where r.ord_id=  mifOrdinativoIdRec.mif_ord_ord_id
                 and   c.classif_id=r.classif_id
                 and   c.classif_tipo_id=classVincolatoCodeId
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
                 and   c.data_cancellazione is null;
            end if;
           end if;

		   if flussoElabMifValore is null and
    	 	  mifOrdinativoIdRec.mif_ord_contotes_id is not null and
        	  mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

		      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
    		                   ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
        		               ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
            		           ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                		       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                    		   ||' mifCountRec='||mifCountRec
	                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_vincolato].';

			  select mif.vincolato into flussoElabMifValore
    	      from mif_r_conto_tesoreria_vincolato mif
	    	  where mif.ente_proprietario_id=enteProprietarioId
    	      and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
	          and   mif.validita_fine is null
		      and   mif.data_cancellazione is null;
	       end if;

		   if flussoElabMifValore is null and
           	flussoElabMifElabRec.flussoElabMifDef is not null then
            flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
           end if;

           if flussoElabMifValore is not null then
           	mifFlussoOrdinativoRec.mif_ord_vers_cod_riscos:=flussoElabMifValore;
           end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <classificazione>
        -- <codice_cge>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifValoreDesc:=null;
        codiceCge:=null;
        descCge:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        raise notice 'codice_cge strMessaggio=%',strMessaggio;

        if flussoElabMifElabRec.flussoElabMifAttivo=true  then
         if flussoElabMifElabRec.flussoElabMifElab=true  then
         		if flussoElabMifElabRec.flussoElabMifParam is not null  then
                	if siopeCodeTipo is null and flussoElabMifElabRec.flussoElabMifParam is not null then
                        siopeCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
					if siopeDef is null and flussoElabMifElabRec.flussoElabMifParam is not null then
                        siopeDef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    if coalesce(dataAvvioSiopeNew,NVL_STR)=NVL_STR and
	                  flussoElabMifElabRec.flussoElabMifParam is not null then
    	                	dataAvvioSiopeNew:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
        	        end if;

            	    if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR and codiceFinVTbr is null then
                	  	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
	                end if;

            	    if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR then
                	  	if dataAvvioSiopeNew::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
                    	then
    	                	bAvvioSiopeNew:=true;
	                    end if;
    	            end if;

                    if  bAvvioSiopeNew=true then
                     -- lettura da PDC_V
                  	 if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then --1
						-- codiceFinVTipoTbrId
                        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id class tipo='||codiceFinVTbr||'.';
			   		    select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
				    	from siac_d_class_tipo tipo
						where tipo.ente_proprietario_id=enteProprietarioId
						and   tipo.classif_tipo_code=codiceFinVTbr
						and   tipo.data_cancellazione is null
						and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
						and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
                     end if; --1

                     if codiceFinVTipoTbrId is not null then --2
      		 		  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_ordinativo_class] .';
		    		  select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                       into flussoElabMifValore,flussoElabMifValoreDesc
			  		  from siac_r_ordinativo_class r, siac_t_class class
	       		      where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	      		      and   class.classif_id=r.classif_id
 		              and   class.classif_tipo_id=codiceFinVTipoTbrId
		 	          and   r.data_cancellazione is null
				      and   r.validita_fine is NULL
	  		          and   class.data_cancellazione is null;

			 		  if flussoElabMifValore is null then --3
		               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_movgest_class].';

             		   select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                    	into flussoElabMifValore,flussoElabMifValoreDesc
		    	       from siac_r_movgest_class rclass, siac_t_class class
		               where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
    		           and   rclass.data_cancellazione is null
        		       and   rclass.validita_fine is null
            		   and   class.classif_id=rclass.classif_id
		               and   class.classif_tipo_id=codiceFinVTipoTbrId
    		           and   class.data_cancellazione is null
		               order by rclass.movgest_classif_id
    		           limit 1;
        	           end if; --3
                      end if;--2
                    else
                	 if siopeCodeTipoId is null then --1
                    	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id class tipo='||siopeCodeTipo||'.';

                    	select class.classif_tipo_id into siopeCodeTipoId
                        from siac_d_class_tipo class
                        where class.classif_tipo_code=siopeCodeTipo
                        and   class.ente_proprietario_id=enteProprietarioId
                        and   class.data_cancellazione is null
 				    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
	 		 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(class.validita_fine,dataElaborazione));
                     end if;
                   if siopeCodeTipoId is not null then --2
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore class tipo='||flussoElabMifElabRec.flussoElabMifParam||'.';


                	select class.classif_code, class.classif_desc
                           into flussoElabMifValore,flussoElabMifValoreDesc
                    from siac_r_ordinativo_class cord, siac_t_class class
                    where cord.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and cord.data_cancellazione is null
                    and cord.validita_fine is null
                    and class.classif_id=cord.classif_id
                    and class.classif_tipo_id=siopeCodeTipoId
                    and class.classif_code!=siopeDef
                    and class.data_cancellazione is null;

                    if flussoElabMifValore is null then --3
	                    select class.classif_code, class.classif_desc
    		                   into flussoElabMifValore,flussoElabMifValoreDesc
	                    from siac_r_movgest_class  r,  siac_t_class class
    	                where r.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
        	            and   r.data_cancellazione is null
            	        and   r.validita_fine is null
                	    and class.classif_id=r.classif_id
                    	and class.classif_tipo_id=siopeCodeTipoId
	                    and class.classif_code!=siopeDef
    	                and class.data_cancellazione is null;
                   end if; --3
                  end if; --2
                end if; --if  bAvvioSiopeNew=true then

                if flussoElabMifValore is not null then
                	mifFlussoOrdinativoRec.mif_ord_class_codice_cge:=flussoElabMifValore;
                    codiceCge:=flussoElabMifValore;
	                descCge:=flussoElabMifValoreDesc;


               end if;
            end if; --param
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if; -- elab
        end if; -- attivo

	    -- <importo>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
	    if codiceCge is not null then
    	flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

	    if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	  if flussoElabMifElabRec.flussoElabMifElab=true then
                	mifFlussoOrdinativoRec.mif_ord_class_importo:=mifFlussoOrdinativoRec.mif_ord_importo;
	      else
    	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
    	end if;
	   end if;

       -- <classificazione_dati_siope_entrate>

       -- <tipo_debito_siope_c> COMMERCIALE
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       isOrdCommerciale:=false;
       ordinativoSplitId:=null;
       ordinativoReintroitoId:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   end if;

	   if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
	          if flussoElabMifElabRec.flussoElabMifDef is not null and
                 flussoElabMifElabRec.flussoElabMifParam is not null then
				 -- 20.03.2018 Sofia SIAC-5968
                 if  tipoRelSPR is null then
                 		tipoRelSPR:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                 end if;
   				 -- 20.03.2018 Sofia SIAC-5968
                 if tipoRelREIORD is null then
                    tipoRelREIORD:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                 end if;

                 -- 20.03.2018 Sofia SIAC-5968
			     if tipoRelSPR is not null and tipoRelSPR!='' then
				  -- caso di ordinativo di incasso collegato a ordinativo di pagamento per Split
                  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura ordinativo di pagamento SPLIT.';

  		          select ord.ord_id into ordinativoSplitId
			      from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
			          siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato, siac_d_relaz_tipo tiporel
				  where rord.ord_id_a=mifOrdinativoIdRec.mif_ord_ord_id
				  and   ord.ord_id=rord.ord_id_da
				  and   tipo.ord_tipo_id=ord.ord_tipo_id
				  and   tipo.ord_tipo_code='P'
			      and   rstato.ord_id=ord.ord_id
	              and   stato.ord_stato_id=rstato.ord_stato_id
	              and   stato.ord_stato_code!='A'
				  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
                  --and   tiporel.relaz_tipo_code=flussoElabMifElabRec.flussoElabMifParam -- 20.03.2018 Sofia SIAC-5968
                  and   tiporel.relaz_tipo_code=tipoRelSPR
				  and   rord.data_cancellazione is null
				  and   rord.validita_fine is null
				  and   ord.data_cancellazione is null
			      and   ord.validita_fine is null
			      and   rstato.data_cancellazione is null
	              and   rstato.validita_fine is null
                  limit 1;

            	  if ordinativoSplitId is not null then
                    -- 20.03.2018 Sofia SIAC-5968
                    --mifFlussoOrdinativoRec.mif_ord_class_tipo_debito=flussoElabMifElabRec.flussoElabMifDef;
                    isOrdCommerciale:=true;
        	      end if;
                end if;

                -- 20.03.2018 Sofia SIAC-5968
                if isOrdCommerciale=false and  tipoRelREIORD is not null and tipoRelREIORD!='' then

                  -- caso di ordinativo di incasso collegato a ordinativo di pagamento per Reintroito
                  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura ordinativo di pagamento Rentroito.';

  		          select ord.ord_id into ordinativoReintroitoId
			      from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
			           siac_d_relaz_tipo tiporel
				  where rord.ord_id_da=mifOrdinativoIdRec.mif_ord_ord_id
				  and   ord.ord_id=rord.ord_id_a
				  and   tipo.ord_tipo_id=ord.ord_tipo_id
				  and   tipo.ord_tipo_code='P'
				  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
                  and   tiporel.relaz_tipo_code=tipoRelREIORD
				  and   rord.data_cancellazione is null
				  and   rord.validita_fine is null
				  and   ord.data_cancellazione is null
			      and   ord.validita_fine is null
                  limit 1;


                  if ordinativoReintroitoId is not null then
                  	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura ordinativo di pagamento Rentroito. Commerciale.';

                    if coalesce(tipoDocsComm,'')='' then
                      tipoDocsComm:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))||'|'||
                        trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4))||'|'||
                        trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                    end if;

                  	isOrdCommerciale:=fnc_mif_ordinativo_esiste_documenti_splus(ordinativoReintroitoId,
			                                                                    tipoDocsComm,
                  				                                   	            enteProprietarioId
                                                                               );
                    if isOrdCommerciale=true then
                    	ordinativoSplitId:=ordinativoReintroitoId;
                    end if;

                  end if;

               end if;

               -- 20.03.2018 Sofia SIAC-5968
 			   if isOrdCommerciale=true then
	               mifFlussoOrdinativoRec.mif_ord_class_tipo_debito=flussoElabMifElabRec.flussoElabMifDef;

               end if;

              end if;
	      else
    	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	      end if;
       end if;

	   -- <tipo_debito_siope_nc> NON_COMMERCIALE se non COMMERCIALE -- NON COMMERCIALE
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       codResult:=null;
       mifCountRec:=mifCountRec+1;
       if isOrdCommerciale=false then
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

	    if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
           if flussoElabMifElabRec.flussoElabMifDef is not null then -- 20.03.2018 Sofia SIAC-5968
/*	          if flussoElabMifElabRec.flussoElabMifDef is not null then -- 20.03.2018 Sofia SIAC-5968
                   mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc=flussoElabMifElabRec.flussoElabMifDef;
              end if;*/

              -- 20.03.2018 Sofia SIAC-5968 - test sul pdcFin di OP per verificare se IVA
              if ordinativoReintroitoId is not null and
                 flussoElabMifElabRec.flussoElabMifParam is not null then
                 tipoPdcIVA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                 codePdcIVA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                 if coalesce(tipoPdcIVA ,'')!='' and
                    coalesce(codePdcIVA ,'')!='' then
                        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
		                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
        		               ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                		       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
        		               ||' mifCountRec='||mifCountRec
        					   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura ordinativo di pagamento Rentroito. Iva.';
                    	select 1 into codResult
                        from siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipo
                        where rc.ord_id=ordinativoReintroitoId
                        and   c.classif_id=rc.classif_id
                        and   tipo.classif_tipo_id=c.classif_tipo_id
                        and   tipo.classif_tipo_code=tipoPdcIVA
                        and   c.classif_code like codePdcIVA||'%'
                        and   rc.data_cancellazione is null
                        and   rc.validita_fine is null;

                        if codResult is not null then
                        	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                        end if;
                 end if;
              end if;
              -- 20.03.2018 Sofia SIAC-5968
              if flussoElabMifValore is null then
              	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
              end if;
              -- 20.03.2018 Sofia SIAC-5968
              if flussoElabMifValore is not null then
	              mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc=flussoElabMifValore;
              end if;
            end if;
	      else
    	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	      end if;
        end if;
       end if;


       mifCountRec:=mifCountRec+12;
       -- <fatture_siope>
	   -- </fatture_siope>

       -- <dati_ARCONET_siope>
       -- <codice_economico_siope>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
         if flussoElabMifElabRec.flussoElabMifParam is not null then

         	if codiceFinVTbr is null then
            	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;
 			if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then --1
				-- codiceFinVTipoTbrId
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id class tipo='||codiceFinVTbr||'.';
			   select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			   from siac_d_class_tipo tipo
			   where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.classif_tipo_code=codiceFinVTbr
			   and   tipo.data_cancellazione is null
			   and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
			   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
            end if; --1

            if codiceFinVTipoTbrId is not null then --2
      			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_ordinativo_class] .';
		    	select class.classif_code into flussoElabMifValore
  	  		    from siac_r_ordinativo_class r, siac_t_class class
	       	    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	      	      and   class.classif_id=r.classif_id
 		          and   class.classif_tipo_id=codiceFinVTipoTbrId
		 	      and   r.data_cancellazione is null
			      and   r.validita_fine is NULL
	  		      and   class.data_cancellazione is null;

			   if flussoElabMifValore is null then --3
		     	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_movgest_class].';

             	   select class.classif_desc into flussoElabMifValore
	    	       from siac_r_movgest_class rclass, siac_t_class class
	               where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
   		           and   rclass.data_cancellazione is null
       		       and   rclass.validita_fine is null
           		   and   class.classif_id=rclass.classif_id
	               and   class.classif_tipo_id=codiceFinVTipoTbrId
   		           and   class.data_cancellazione is null
	               order by rclass.movgest_classif_id
   		           limit 1;
   	           end if; --3
           end if;--2
 /*      	  if collEventoCodeId is null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura tipo evento '||flussoElabMifElabRec.flussoElabMifParam||'.';

            select coll.collegamento_tipo_id into collEventoCodeId
            from siac_d_collegamento_tipo coll
            where coll.ente_proprietario_id=enteProprietarioId
            and   coll.collegamento_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))
            and   coll.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',coll.validita_inizio)
		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(coll.validita_fine,dataElaborazione));
         end if;

	     if collEventoCodeId is not null then
		  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura conto economico patrimoniale.';
          select conto.pdce_conto_code into flussoElabMifValore
          from siac_t_pdce_conto conto, siac_t_reg_movfin regMovFin, siac_r_evento_reg_movfin rEvento,
               siac_d_collegamento_tipo coll, siac_d_evento evento,
               siac_t_mov_ep reg, siac_r_reg_movfin_stato regstato, siac_d_reg_movfin_stato stato,
               siac_t_prima_nota pn, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnstato,
               siac_t_mov_ep_det det
          where coll.ente_proprietario_id=enteProprietarioId
          and   coll.collegamento_tipo_id=collEventoCodeId
          and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
          and   rEvento.evento_id=evento.evento_id
          and   rEvento.campo_pk_id=mifOrdinativoIdRec.mif_ord_ord_id
          and   regMovFin.regmovfin_id=rEvento.regmovfin_id
--          and   regMovFin.ambito_id=ambitoFinId  -- AMBITO_FIN
          and   regstato.regmovfin_id=regMovFin.regmovfin_id
          and   stato.regmovfin_stato_id=regstato.regmovfin_stato_id
          and   stato.regmovfin_stato_code!=REGMOVFIN_STATO_A
          and   reg.regmovfin_id=regMovFin.regmovfin_id
          and   pn.pnota_id=reg.regep_id
          and   rpnota.pnota_id=pn.pnota_id
          and   pnstato.pnota_stato_id=rpnota.pnota_stato_id
          and   pnstato.pnota_stato_code!=REGMOVFIN_STATO_A
          and   det.movep_id=reg.movep_id
          and   det.movep_det_segno=SEGNO_ECONOMICO -- Avere
		  and   conto.pdce_conto_id=det.pdce_conto_id
          and   regMovFin.data_cancellazione is null
          and   regMovFin.validita_fine is null
          and   rEvento.data_cancellazione is null
          and   rEvento.validita_fine is null
          and   evento.data_cancellazione is null
          and   evento.validita_fine is null
          and   reg.data_cancellazione is null
          and   reg.validita_fine is null
          and   regstato.data_cancellazione is null
          and   regstato.validita_fine is null
          and   pn.data_cancellazione is null
          and   pn.validita_fine is null
          and   rpnota.data_cancellazione is null
          and   rpnota.validita_fine is null
          and   conto.data_cancellazione is null
          and   conto.validita_fine is null
          order by pn.pnota_id desc
          limit 1;
         end if;*/

	    end if; -- param
        if flussoElabMifValore is not null then
	        mifFlussoOrdinativoRec.mif_ord_class_economico:=flussoElabMifValore;
        end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

	  -- <importo_codice_economico_siope>
	  mifCountRec:=mifCountRec+1;
      if mifFlussoOrdinativoRec.mif_ord_class_economico is not null then
      	flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         		mifFlussoOrdinativoRec.mif_ord_class_importo_economico:=mifFlussoOrdinativoRec.mif_ord_importo;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
      end if;

	  -- <codice_ue_siope>
	  flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  mifCountRec:=mifCountRec+1;
	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then
	     if flussoElabMifElabRec.flussoElabMifParam is not null then
    	 	if codiceUECodeTipo is null then
				codiceUECodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

         	if codiceUECodeTipo is not null and codiceUECodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into codiceUECodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=codiceUECodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
       		end if;

	        if codiceUECodeTipoId is not null then

        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_ordinativo_class].';
        	 select class.classif_code into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=codiceUECodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;

		     if flussoElabMifValore is null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_movgest_class].';
				select class.classif_code into flussoElabMifValore
	    	    from siac_r_movgest_class rclass, siac_t_class class
	            where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
	            and   rclass.data_cancellazione is null
	            and   rclass.validita_fine is null
	            and   class.classif_id=rclass.classif_id
	            and   class.classif_tipo_id=codiceUECodeTipoId
	            and   class.data_cancellazione is null
	            order by rclass.movgest_classif_id
	            limit 1;
             end if;
        	end if;

	        if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_class_transaz_ue:=flussoElabMifValore;
    	    end if;
          end if;
	   else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
      end if;

	  -- <codice_entrata_siope>
	  flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  mifCountRec:=mifCountRec+1;
	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then
	     if flussoElabMifElabRec.flussoElabMifParam is not null then
    	 	if ricorrenteCodeTipo is null then
				ricorrenteCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

         	if ricorrenteCodeTipo is not null and ricorrenteCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into ricorrenteCodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=ricorrenteCodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
       		end if;

	        if ricorrenteCodeTipoId is not null then

        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_ordinativo_class].';
        	 select upper(class.classif_desc) into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=ricorrenteCodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;

		     if flussoElabMifValore is null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_movgest_class].';
				select upper(class.classif_desc) into flussoElabMifValore
	    	    from siac_r_movgest_class rclass, siac_t_class class
	            where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
	            and   rclass.data_cancellazione is null
	            and   rclass.validita_fine is null
	            and   class.classif_id=rclass.classif_id
	            and   class.classif_tipo_id=ricorrenteCodeTipoId
	            and   class.data_cancellazione is null
	            order by rclass.movgest_classif_id
	            limit 1;
             end if;
        	end if;

	        if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_class_ricorrente_entrata:=flussoElabMifValore;
    	    end if;
          end if;
	   else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
      end if;



       -- </dati_ARCONET_siope>
       -- </classificazione_dati_siope_entrate>
       -- </classificazione>

       -- <bollo>
       -- <assoggettamento_bollo>
   	  mifCountRec:=mifCountRec+1;
      ordCodiceBolloDesc:=null;
      codiceBolloPlusDesc:=null;
      codiceBolloPlusEsente:=false;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if mifOrdinativoIdRec.mif_ord_codbollo_id is not null then


	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
            -- se REGOLARIZZAZIONE IMPOSTAZIONE DI ESENTE BOLLO
            if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null and
               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos is not null and
/*               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos=
                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) -- REGOLARIZZAZIONE*/
               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos in  -- siac-5652 14.12.2017 Sofia
               ( trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)), -- REGOLARIZZAZIONE
                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))  -- REGOLARIZZAZIONE ACCREDITO BANCA d'ITALIA
               )
                  then
                   mifFlussoOrdinativoRec.mif_ord_bollo_carico:=
                       trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                   mifFlussoOrdinativoRec.mif_ord_bollo_esenzione:=
                    trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));

                   codiceBolloPlusEsente:=true;
            end if;

            if mifFlussoOrdinativoRec.mif_ord_bollo_carico  is null then
          	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice bollo.';

             select bollo.codbollo_desc , replace(plus.codbollo_plus_desc,'BENEFICIARIO','VERSANTE'), plus.codbollo_plus_esente
                   into ordCodiceBolloDesc, codiceBolloPlusDesc, codiceBolloPlusEsente
             from siac_d_codicebollo bollo, siac_d_codicebollo_plus plus, siac_r_codicebollo_plus rp
             where bollo.codbollo_id=mifOrdinativoIdRec.mif_ord_codbollo_id
             and   rp.codbollo_id=bollo.codbollo_id
             and   plus.codbollo_plus_id=rp.codbollo_plus_id
             and   rp.data_cancellazione is null
             and   rp.validita_fine is null;

             if coalesce(codiceBolloPlusDesc,NVL_STR)!=NVL_STR  then
            	mifFlussoOrdinativoRec.mif_ord_bollo_carico:=codiceBolloPlusDesc;
             end if;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
       end if;

      -- <causale_esenzione_bollo>
   	  mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      if codiceBolloPlusEsente=true and coalesce(ordCodiceBolloDesc,NVL_STR)!=NVL_STR then
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
          	mifFlussoOrdinativoRec.mif_ord_bollo_esenzione:=substring(ordCodiceBolloDesc from 1 for 30);
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
	  -- </bollo>

      -- <versante>
      -- <anagrafica_versante>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	flussoElabMifValore:=soggettoRec.soggetto_desc;

                if flussoElabMifValore is not null then
	                mifFlussoOrdinativoRec.mif_ord_anag_versante:=substring(flussoElabMifValore from 1 for 140);
                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	   -- <indirizzo_versante>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' indirizzo_benef mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoRifId
                and   indir.principale='S'
                and   indir.data_cancellazione is null
         	    and   indir.validita_fine is null;
	            if indirizzoRec is null then
                    isIndirizzoBenef:=false;
	            end if;

				if isIndirizzoBenef=true then
                 if indirizzoRec.via_tipo_id is not null then
            		select tipo.via_tipo_code into flussoElabMifValore
	                from siac_d_via_tipo tipo
    	            where tipo.via_tipo_id=indirizzoRec.via_tipo_id
        	        and   tipo.data_cancellazione is null
         		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 			and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

         	        if flussoElabMifValore is not null then
        	        	flussoElabMifValore:=flussoElabMifValore||' ';
    	            end if;
             	 end if;

            	 flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
                                 ||' '||coalesce(indirizzoRec.numero_civico,''));

	             if flussoElabMifValore is not null then
		            mifFlussoOrdinativoRec.mif_ord_indir_versante:=substring(flussoElabMifValore from 1 for 30);
        	     end if;
               end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

   	   -- <cap_versante>
       mifCountRec:=mifCountRec+1;
	   if isIndirizzoBenef=true then
        if indirizzoRec.zip_code is not null  then
         flussoElabMifElabRec:=null;

         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
	            mifFlussoOrdinativoRec.mif_ord_cap_versante:=lpad(indirizzoRec.zip_code,5,'0');
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
       end if;


       -- <localita_beneficiario>
       mifCountRec:=mifCountRec+1;
	   if isIndirizzoBenef=true then
        if indirizzoRec.comune_id is not null  then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select com.comune_desc into flussoElabMifValore
            from siac_t_comune com
            where com.comune_id=indirizzoRec.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_localita_versante:=substring(flussoElabMifValore from 1 for 30);
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
	  end if;

	  -- <provincia_beneficiario>
      mifCountRec:=mifCountRec+1;
	  if isIndirizzoBenef=true then
        if indirizzoRec.comune_id is not null  then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select prov.sigla_automobilistica into flussoElabMifValore
            from siac_r_comune_provincia provRel, siac_t_provincia prov
            where provRel.comune_id=indirizzoRec.comune_id
            and   provRel.data_cancellazione is null
            and   provRel.validita_fine is null
            and   prov.provincia_id=provRel.provincia_id
            and   prov.data_cancellazione is null
            and   prov.validita_fine is null
            order by provRel.data_creazione;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_prov_versante:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
	 end if;


	 -- <stato_versante>
  	 mifCountRec:=mifCountRec+1;

     -- <partita_iva_versante>
     mifCountRec:=mifCountRec+1;
     if soggettoRec.partita_iva is not null or
        (soggettoRec.partita_iva is null and soggettoRec.codice_fiscale is not null and length(soggettoRec.codice_fiscale)=11) then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          		if soggettoRec.partita_iva is not null then
                	 mifFlussoOrdinativoRec.mif_ord_partiva_versante:=soggettoRec.partita_iva;
                else
                	mifFlussoOrdinativoRec.mif_ord_partiva_versante:=trim ( both ' ' from soggettoRec.codice_fiscale);
                end if;

          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;
      end if;

      -- <codice_fiscale_versante>
      mifCountRec:=mifCountRec+1;
      if soggettoRec.partita_iva is null  then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	if soggettoRec.codice_fiscale is not null and
  			   length(soggettoRec.codice_fiscale)=16 then
				flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
            end if;

            if flussoElabMifValore is not null then
		            mifFlussoOrdinativoRec.mif_ord_codfisc_versante:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
      end if;
     -- </versante>

     -- <causale>
	 flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
            mifFlussoOrdinativoRec.mif_ord_vers_causale:=
	            replace(replace(substring(mifOrdinativoIdRec.mif_ord_desc from 1 for 370) , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;

      -- <sospeso>
      -- <sospesi>
      -- <numero_provvisorio>
      -- <importo_provvisorio>
      mifCountRec:=mifCountRec+2;


      -- <mandato_associato>
      -- <numero_mandato>
      -- <progressivo_associato>
      mifCountRec:=mifCountRec+2;

      -- <informazioni_aggiuntive>
      -- <lingua>
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifDef is not null then
        		mifFlussoOrdinativoRec.mif_ord_lingua:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

     -- <riferimento_documento_esterno>
     mifCountRec:=mifCountRec+1;
   	 flussoElabMifElabRec:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  		 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
   	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifDef is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura presenza allegati cartacei.';

                	select 1 into codResult
				    from siac_r_ordinativo_attr rattr
					where rattr.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   rattr.attr_id=ordAllegatoCartAttrId
				    and   rattr.boolean='S'
					and   rattr.data_cancellazione is null
				    and   rattr.validita_fine is null;

				if codResult is not null then
	                mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno:=flussoElabMifElabRec.flussoElabMifDef;
		        end if;
             end if;
		else
    		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
      end if;
      -- </informazioni_aggiuntive>

      -- <sostituzione_reversale>
      -- <numero_reversale_da_sostituire>
      flussoElabMifElabRec:=null;
      ordSostRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

      if flussoElabMifElabRec.flussoElabMifId is null then
  		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ordinativi di sostituzione.';
                	select * into ordSostRec
                    from fnc_mif_ordinativo_sostituito( mifOrdinativoIdRec.mif_ord_ord_id,
 														ordRelazCodeTipoId,
                                                        dataElaborazione,dataFineVal);

                    if ordSostRec is not null then
                    	mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=lpad(ordSostRec.ordNumeroSostituto::varchar,NUM_SETTE,ZERO_PAD);
                    end if;
    	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;

      end if;

      mifCountRec:=mifCountRec+1;
      -- <progressivo_reversale_da_sostituire>
      if mifFlussoOrdinativoRec.mif_ord_num_ord_colleg is not null then
       	flussoElabMifElabRec:=null;
  	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;
 	 end if;

     -- <esercizio_reversale_da_sostituire>
     mifCountRec:=mifCountRec+1;
     if mifFlussoOrdinativoRec.mif_ord_num_ord_colleg is not null then
        flussoElabMifElabRec:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
               	mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg:=ordSostRec.ordAnnoSostituto;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;
    end if;
	-- </sostituzione_reversale>

    -- <dati_a_disposizione_ente_versante> facoltativo non valorizzato
    -- </informazioni_versante>

    -- <dati_a_disposizione_ente_reversale>
    -- <codice_distinta>
    flussoElabMifElabRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifValore:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	 end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
      if flussoElabMifElabRec.flussoElabMifElab=true then
      		if mifOrdinativoIdRec.mif_ord_dist_id is not null then
				strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura distinta [siac_d_distinta].';
            	select  d.dist_code into flussoElabMifValore
                from siac_d_distinta d
                where d.dist_id=mifOrdinativoIdRec.mif_ord_dist_id;
            end if;

            if flussoElabMifValore is not null then
              	mifFlussoOrdinativoRec.mif_ord_codice_distinta:=flussoElabMifValore;
            end if;
      else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  end if;
	 end if;

     -- <atto_contabile>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
	     if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
                if attoAmmTipoAllRag is null then
            		attoAmmTipoAllRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if attoAmmStrTipoRag is null then
                	attoAmmStrTipoRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         		end if;

                if attoAmmTipoAllRag is not null and  attoAmmStrTipoRag is not null then

                 flussoElabMifValore:=fnc_mif_estremi_attoamm_all(mifOrdinativoIdRec.mif_ord_atto_amm_id,
                 										          attoAmmTipoAllRag,attoAmmStrTipoRag,
                                                                  dataElaborazione, dataFineVal);

                end if;
          	end if;

            if flussoElabMifValore is not null then
                 	mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile:=flussoElabMifValore;
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


      -- 15.01.2018 Sofia SIAC-5765
      -- <codice_operatore>
	  flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  flussoElabMifValoreDesc:=null;
	  mifCountRec:=mifCountRec+1;
	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then


         if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
         end if;

         if flussoElabMifValore is not null then
        	select substring(s.soggetto_desc  from 1 for 12)  into flussoElabMifValoreDesc
			from siac_t_account a, siac_r_soggetto_ruolo r, siac_t_soggetto s
			where a.ente_proprietario_id=enteProprietarioId
            and   a.account_code=flussoElabMifValore
			and   r.soggeto_ruolo_id=a.soggeto_ruolo_id
			and   s.soggetto_id=r.soggetto_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   a.data_cancellazione is null
            and   a.validita_fine is null;

            if 	flussoElabMifValoreDesc is not null then
            	flussoElabMifValore:=flussoElabMifValoreDesc;
            end if;
         end if;

         if flussoElabMifValore is not null then
            mifFlussoOrdinativoRec.mif_ord_code_operatore:=substring(flussoElabMifValore from 1 for 12);
         end if;
       else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
     end if;
    -- </dati_a_disposizione_ente_reversale>
    -- </reversale>



  /*raise notice 'codice_funzione= %',mifFlussoOrdinativoRec.mif_ord_codice_funzione;
  raise notice 'numero_reversale= %',mifFlussoOrdinativoRec.mif_ord_numero;
  raise notice 'data_reversale= %',mifFlussoOrdinativoRec.mif_ord_data;
  raise notice 'importo_reversale= %',mifFlussoOrdinativoRec.mif_ord_importo;*/

  strMessaggio:='Inserimento mif_t_ordinativo_entrata per ord. numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        INSERT INTO mif_t_ordinativo_entrata
        (
		 mif_ord_flusso_elab_mif_id,
		 mif_ord_ord_id,
		 mif_ord_bil_id,
		 mif_ord_anno,
		 mif_ord_numero,
         mif_ord_codice_funzione,
		 mif_ord_data,
		 mif_ord_importo,
		 mif_ord_bci_tipo_contabil,
		 mif_ord_bci_tipo_entrata,
		 --mif_ord_bci_numero_doc,
		 mif_ord_destinazione,
		 mif_ord_codice_abi_bt,
		 mif_ord_codice_ente,
		 mif_ord_desc_ente,
		 mif_ord_codice_ente_bt,
		 mif_ord_anno_esercizio,
         mif_ord_codice_flusso_oil,
		 mif_ord_data_creazione_flusso,
		 mif_ord_anno_flusso,
         mif_ord_id_flusso_oil,
		 mif_ord_codice_struttura,
		 mif_ord_ente_localita,
		 mif_ord_ente_indirizzo,
		 mif_ord_cod_raggrup,
		 mif_ord_progr_vers,
		 mif_ord_class_codice_cge,
		 mif_ord_class_importo,
		 mif_ord_codifica_bilancio,
         mif_ord_capitolo,
		 mif_ord_articolo,
		 mif_ord_desc_codifica,
         mif_ord_desc_codifica_bil,
		 mif_ord_gestione,
		 mif_ord_anno_res,
		 mif_ord_importo_bil,
		 mif_ord_anag_versante,
		 mif_ord_indir_versante,
		 mif_ord_cap_versante,
		 mif_ord_localita_versante,
		 mif_ord_prov_versante,
		 mif_ord_partiva_versante,
		 mif_ord_codfisc_versante,
		 mif_ord_bollo_esenzione,
		 mif_ord_vers_tipo_riscos,
		 mif_ord_vers_cod_riscos,
		 mif_ord_vers_importo,
		 mif_ord_vers_causale,
		 mif_ord_lingua,
		 mif_ord_rif_doc_esterno,
		 mif_ord_info_tesoriere,
		 mif_ord_flag_copertura,
		 mif_ord_sost_rev,
		 mif_ord_num_ord_colleg,
		 mif_ord_progr_ord_colleg,
		 mif_ord_anno_ord_colleg,
		 mif_ord_numero_acc,
		 mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
		 mif_ord_siope_codice_cge,
		 mif_ord_siope_descri_cge,
		 mif_ord_descri_estesa_cap,
         mif_ord_codice_ente_ipa, -- newSiope+
	     mif_ord_codice_ente_istat,
		 mif_ord_codice_ente_tramite,
		 mif_ord_codice_ente_tramite_bt,
		 mif_ord_riferimento_ente,
         mif_ord_vers_cc_postale,
		 mif_ord_class_tipo_debito,
         mif_ord_class_tipo_debito_nc,
		 mif_ord_class_economico,
		 mif_ord_class_importo_economico,
		 mif_ord_class_transaz_ue,
		 mif_ord_class_ricorrente_entrata,
		 mif_ord_bollo_carico,
		 mif_ord_stato_versante,
		 mif_ord_codice_distinta,
		 mif_ord_codice_atto_contabile, -- newSiope+
  		 validita_inizio,
         ente_proprietario_id,
  		 login_operazione
		)
		VALUES
        (
  		 flussoElabMifLogId, --idElaborazione univoco -- mif_ord_flusso_elab_mif_id
  		 mifOrdinativoIdRec.mif_ord_ord_id,     -- mif_ord_ord_id
		 mifOrdinativoIdRec.mif_ord_bil_id,     -- mif_ord_bil_id
  		 mifOrdinativoIdRec.mif_ord_ord_anno,   -- mif_ord_anno
  		 mifFlussoOrdinativoRec.mif_ord_numero, -- mif_ord_numero
  		 mifFlussoOrdinativoRec.mif_ord_codice_funzione, -- mif_ord_codice_funzione
  		 mifFlussoOrdinativoRec.mif_ord_data, -- mif_ord_data
--  	     (case when mifFlussoOrdinativoRec.mif_ord_codice_funzione in (FUNZIONE_CODE_N,FUNZIONE_CODE_A) then
--                    '0.00' else mifFlussoOrdinativoRec.mif_ord_importo end), -- mif_ord_importo
         mifFlussoOrdinativoRec.mif_ord_importo,  -- mif_ord_importo
 		 mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil,  -- mif_ord_bci_tipo_contabil
  	     mifFlussoOrdinativoRec.mif_ord_bci_tipo_entrata,   -- mif_ord_bci_tipo_entrata
 		 --mifFlussoOrdinativoRec.mif_ord_bci_numero_doc,   -- mif_ord_bci_numero_doc
 	 	 mifFlussoOrdinativoRec.mif_ord_destinazione,       -- mif_ord_destinazione
 		 mifFlussoOrdinativoRec.mif_ord_codice_abi_bt,      -- mif_ord_codice_abi_bt
 		mifFlussoOrdinativoRec.mif_ord_codice_ente,         -- mif_ord_codice_ente
		mifFlussoOrdinativoRec.mif_ord_desc_ente,           -- mif_ord_desc_ente
  		mifFlussoOrdinativoRec.mif_ord_codice_ente_bt,      -- mif_ord_codice_ente_bt
 		mifFlussoOrdinativoRec.mif_ord_anno_esercizio,      -- mif_ord_anno_esercizio
--  		annoBilancio||flussoElabMifDistOilId::varchar,  -- flussoElabMifDistOilId
  		annoBilancio||flussoElabMifDistOilRetId::varchar,
        extract(year from now())||'-'||
        lpad(extract('month' from now())::varchar,2,'0')||'-'||
        lpad(extract('day' from now())::varchar,2,'0')||'T'||
        lpad(extract('hour' from now())::varchar,2,'0')||':'||
        lpad(extract('minute' from now())::varchar,2,'0')||':'||'00',  -- mif_ord_data_creazione_flusso
        extract(year from now())::integer,                  -- mif_ord_anno_flusso
		flussoElabMifOilId, --idflussoOil                   -- mif_ord_id_flusso_oil
 		mifFlussoOrdinativoRec.mif_ord_codice_struttura,  -- mif_ord_codice_struttura
 		mifFlussoOrdinativoRec.mif_ord_ente_localita,     -- mif_ord_ente_localita
		mifFlussoOrdinativoRec.mif_ord_ente_indirizzo,    -- mif_ord_ente_indirizzo
        mifFlussoOrdinativoRec.mif_ord_cod_raggrup,       -- mif_ord_cod_raggrup
 		mifFlussoOrdinativoRec.mif_ord_progr_vers,        -- mif_ord_progr_vers
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cge,  -- mif_ord_class_codice_cge
        mifFlussoOrdinativoRec.mif_ord_class_importo,     -- mif_ord_class_importo
 		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio, -- mif_ord_codifica_bilancio
        mifFlussoOrdinativoRec.mif_ord_capitolo,          -- mif_ord_capitolo
  		mifFlussoOrdinativoRec.mif_ord_articolo,          -- mif_ord_articolo
 		mifFlussoOrdinativoRec.mif_ord_desc_codifica,     -- mif_ord_desc_codifica
        mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil, -- mif_ord_desc_codifica_bil
		mifFlussoOrdinativoRec.mif_ord_gestione,          -- mif_ord_gestione
 		mifFlussoOrdinativoRec.mif_ord_anno_res,          -- mif_ord_anno_res
        mifFlussoOrdinativoRec.mif_ord_importo_bil,       -- mif_ord_importo_bil
        mifFlussoOrdinativoRec.mif_ord_anag_versante,     -- mif_ord_anag_versante
  		mifFlussoOrdinativoRec.mif_ord_indir_versante,    -- mif_ord_indir_versante
		mifFlussoOrdinativoRec.mif_ord_cap_versante,      -- mif_ord_cap_versante
 		mifFlussoOrdinativoRec.mif_ord_localita_versante, -- mif_ord_localita_versante
  		mifFlussoOrdinativoRec.mif_ord_prov_versante,     -- mif_ord_prov_versante
 		mifFlussoOrdinativoRec.mif_ord_partiva_versante,
  		mifFlussoOrdinativoRec.mif_ord_codfisc_versante,
 		mifFlussoOrdinativoRec.mif_ord_bollo_esenzione,
        mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos,
        mifFlussoOrdinativoRec.mif_ord_vers_cod_riscos,
        mifFlussoOrdinativoRec.mif_ord_vers_importo,
        mifFlussoOrdinativoRec.mif_ord_vers_causale,
 		mifFlussoOrdinativoRec.mif_ord_lingua,
		mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno,
 		mifFlussoOrdinativoRec.mif_ord_info_tesoriere,
 		mifFlussoOrdinativoRec.mif_ord_flag_copertura,
        mifFlussoOrdinativoRec.mif_ord_sost_rev,
		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_numero_acc,
        mifFlussoOrdinativoRec.mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
        mifFlussoOrdinativoRec.mif_ord_siope_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_siope_descri_cge,
        mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa, -- newSiope+
	    mifFlussoOrdinativoRec.mif_ord_codice_ente_istat,
		mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite,
		mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt,
		mifFlussoOrdinativoRec.mif_ord_riferimento_ente,
        mifFlussoOrdinativoRec.mif_ord_vers_cc_postale,
	    mifFlussoOrdinativoRec.mif_ord_class_tipo_debito,    -- commerciale
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc, -- non_commerciale
	    mifFlussoOrdinativoRec.mif_ord_class_economico,
	    mifFlussoOrdinativoRec.mif_ord_class_importo_economico,
	    mifFlussoOrdinativoRec.mif_ord_class_transaz_ue,
	    mifFlussoOrdinativoRec.mif_ord_class_ricorrente_entrata,
	    mifFlussoOrdinativoRec.mif_ord_bollo_carico,
	    mifFlussoOrdinativoRec.mif_ord_stato_versante,
	    mifFlussoOrdinativoRec.mif_ord_codice_distinta,
	    mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile, -- newSiope+
        now(),
        enteProprietarioId,
        loginOperazione
     )
     returning mif_ord_id into mifOrdSpesaId;



   /* da vedere
     if isGestioneQuoteOK=true then
	  quoteOrdinativoRec:=null;
	  mifCountRec:=FLUSSO_MIF_ELAB_NUM_QUOTA_MAND;
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura quote ordinativo.';

	for quoteOrdinativoRec in
    (select *
	 from fnc_mif_ordinativo_quote_entrata(mifOrdinativoIdRec.mif_ord_ord_id,
		 								   ordinativoTsDetTipoId,movgestTsTipoSubId,
                                           classCdrTipoId,classCdcTipoId,
        		                           enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
  		-- <Numero_quota_reversale>
		mifCountRec:=FLUSSO_MIF_ELAB_NUM_QUOTA_MAND;
	    flussoElabMifElabRec:=null;
        codResult:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];


    end loop;

 end if; */





 -- <sospesi>
 -- <sospeso>
 -- <numero_provvisorio>
 -- <importo_provvisorio>
 if  isRicevutaAttivo=true then
    ricevutaRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  provvisori'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ricevutaRec in
    (select *
     from fnc_mif_ordinativo_ricevute(mifOrdinativoIdRec.mif_ord_ord_id,
								      flussoElabMifTipoDec,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento   ricevuta'
                       ||' in mif_t_ordinativo_entrata_ricevute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_entrata_ricevute
        (mif_ord_id,
	     mif_ord_ric_anno,
	     mif_ord_ric_numero,
	     mif_ord_provc_id,
		 mif_ord_ric_importo,
	     validita_inizio,
		 ente_proprietario_id,
	     login_operazione
        )
        values
        (mifOrdSpesaId,
         ricevutaRec.annoRicevuta,
         ricevutaRec.numeroRicevuta,
         ricevutaRec.provRicevutaId,
         ricevutaRec.importoRicevuta,
         now(),
         enteProprietarioId,
         loginOperazione
        );
    end loop;

  end if;

  -- dati fatture da valorizzare se ordinativo commerciale
  -- @@@@ sicuramente da completare
  -- <fattura_siope>
  if isGestioneFatture = true and isOrdCommerciale=true then
   flussoElabMifElabRec:=null;
   mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
   titoloCap:=null;
   codResult:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];

   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Lettura macroaggregato ordinativo di spesa collegato.';
--   select c.classif_code into titoloCap
   -- 23.02.2018 Sofia JIRA siac-5849
   select c.classif_id into codResult
   from siac_r_ordinativo_bil_elem re, siac_r_bil_elem_class rc,
        siac_t_class c
   where re.ord_id=ordinativoSplitId
   and   rc.elem_id=re.elem_id
   and   c.classif_id=rc.classif_id
   and   c.classif_tipo_id=macroAggrTipoCodeId
   and   re.data_cancellazione is null
   and   re.validita_fine is null
   and   rc.data_cancellazione is null
   and   rc.validita_fine is null
   and   c.data_cancellazione is null;

   -- 23.02.2018 Sofia JIRA siac-5849
   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Lettura natura spesa ordinativo di spesa collegato.';
   select oil.oil_natura_spesa_desc into titoloCap
   from siac_d_oil_natura_spesa oil, siac_r_oil_natura_spesa_titolo r,
        siac_r_class_fam_tree rtree
   where rtree.classif_fam_tree_id=famMacroTitCodeId
   and   rtree.classif_id=codResult -- macroaggregatoId
   and   r.oil_natura_spesa_titolo_id=rtree.classif_id_padre
   and   oil.oil_natura_spesa_id=r.oil_natura_spesa_id
   and   rtree.data_cancellazione is null
   and   rtree.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null;

  if titoloCap is null then titoloCap:=defNaturaPag; end if;
  -- 26.02.2018 Sofia JIRA siac-5849 - esclusione note credito  per ordinativi di incasso
  titoloCap:=titoloCap||'|S';

  /**  -- 23.02.2018 Sofia JIRA siac-5849
  if titoloCap is not null then
    if substring(titoloCap from 1 for 1)=titoloCorrente then
	  	titoloCap:=descriTitoloCorrente;
    else
     if substring(titoloCap from 1 for 1)=titoloCapitale then
     	titoloCap:=descriTitoloCapitale;
     end if;
    end if;
   end if; **/

   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.';
   ordRec:=null;
   for ordRec in
   (select * from fnc_mif_ordinativo_documenti_splus( ordinativoSplitId, -- cerco i documenti relativi a ordinativo di pagamento collegato per split
											          numeroDocs::integer,
                                                      tipoDocs,
                                                      docAnalogico,
                                                      attrCodeDataScad,
                                                      titoloCap,
                                                      enteOilRec.ente_oil_codice_pcc_uff,
		   		                        	          enteProprietarioId,
	            		                              dataElaborazione,dataFineVal)
   )
    loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento fatture '
                       ||' in mif_t_ordinativo_spesa_documenti '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         insert into  mif_t_ordinativo_spesa_documenti
         ( mif_ord_id,
		   mif_ord_documento,
           mif_ord_doc_codice_ipa_ente,
	       mif_ord_doc_tipo,
           mif_ord_doc_tipo_a,
		   mif_ord_doc_id_lotto_sdi,
		   mif_ord_doc_tipo_analog,
		   mif_ord_doc_codfisc_emis,
		   mif_ord_doc_anno,
	       mif_ord_doc_numero,
	       mif_ord_doc_importo,
	       mif_ord_doc_data_scadenza,
	       mif_ord_doc_motivo_scadenza,
	       mif_ord_doc_natura_spesa,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
         )
         values
         (mifOrdSpesaId,
--          ordRec.numero_fattura_siope,
          'E', -- 07.06.2018 Sofia SIAC-6228
		  ordRec.codice_ipa_ente_siope,
		  ordRec.tipo_documento_siope,
          ordRec.tipo_documento_siope_a,
          ordRec.identificativo_lotto_sdi_siope,
          ordRec.tipo_documento_analogico_siope,
          trim ( both ' ' from ordRec.codice_fiscale_emittente_siope),
		  ordRec.anno_emissione_fattura_siope,
		  ordRec.numero_fattura_siope,
          --ordRec.importo_siope,     -- 22.12.2017 Sofia siac-5665
          ordRec.importo_siope_split, -- 22.12.2017 Sofia siac-5665
		  ordRec.data_scadenza_pagam_siope,
		  ordRec.motivo_scadenza_siope,
    	  ordRec.natura_spesa_siope,
          now(),
          enteProprietarioId,
          loginOperazione
         );
    end loop;
   end if;

   numeroOrdinativiTrasm:=numeroOrdinativiTrasm+1;

   end loop;

   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifOilId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_out_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifDistOilRetId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   strMessaggio:='Aggiornamento mif_t_flusso_elaborato.';
   update  mif_t_flusso_elaborato
   set (flusso_elab_mif_id_flusso_oil,flusso_elab_mif_codice_flusso_oil,flusso_elab_mif_num_ord_elab,flusso_elab_mif_file_nome,flusso_elab_mif_esito_msg)=
   	   (flussoElabMifOilId,annoBilancio||flussoElabMifDistOilRetId::varchar,numeroOrdinativiTrasm,flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice,
        'Elaborazione in corso tipo flusso '||MANDMIF_TIPO||' - Dati inseriti in mif_t_ordinativo_entrata')
   where flusso_elab_mif_id=flussoElabMifLogId;

    -- gestire aggiornamento mif_t_flusso_elaborato

	RAISE NOTICE 'numeroOrdinativiTrasm %', numeroOrdinativiTrasm;
    messaggioRisultato:=strMessaggioFinale||' Trasmessi '||numeroOrdinativiTrasm||' ordinativi di entrata.';
    messaggioRisultato:=upper(messaggioRisultato);
    flussoElabMifId:=flussoElabMifLogId;
    nomeFileMif:=flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice;
    flussoElabMifDistOilId:=(annoBilancio||flussoElabMifDistOilRetId::varchar)::integer;

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1000),mifCountRec;
        if codResult=-12 then
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1500),'') ||' '||mifCountRec||'.';
          codiceRisultato:=0;
        else
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 1500),'')||' '||mifCountRec||'.' ;
       	  codiceRisultato:=-1;
    	end if;

        numeroOrdinativiTrasm:=0;
		messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when NO_DATA_FOUND THEN
        raise notice '% % ERRORE : % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1500),mifCountRec;
        messaggioRisultato:=coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' Nessun dato presente in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when TOO_MANY_ROWS THEN
        raise notice '% % ERRORE : % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1500),mifCountRec;
        messaggioRisultato:=coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;
        return;
	when others  THEN
		raise notice '% % Errore DB % % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1000),mifCountRec;
        messaggioRisultato:=coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500)||' '||mifCountRec||'.' ;
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa_splus (
  enteproprietarioid integer,
  nomeente varchar,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  mifordritrasmelabid integer,
  out flussoelabmifdistoilid integer,
  out flussoelabmifid integer,
  out numeroordinativitrasm integer,
  out nomefilemif varchar,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 strExecSql VARCHAR(1500):='';

 mifOrdinativoIdRec record;

 mifFlussoOrdinativoRec  mif_t_ordinativo_spesa%rowtype;


 mifFlussoElabMifArr flussoElabMifRecType[];


 mifCountRec integer:=1;
 mifCountTmpRec integer:=1;
 mifAFlussoElabTypeRec  flussoElabMifRecType;
 flussoElabMifElabRec  flussoElabMifRecType;
 mifElabRec record;

 attoAmmRec record;
 enteOilRec record;
 enteProprietarioRec record;
 soggettoRec record;
 soggettoSedeRec record;
 soggettoQuietRec record;
 soggettoQuietRifRec record;
 MDPRec record;
 codAccreRec record;
 bilElemRec record;
 indirizzoRec record;
 ordSostRec record;


 tipoPagamRec record;
 ritenutaRec record;
 ricevutaRec record;
 quoteOrdinativoRec record;
 ordRec record;


 isIndirizzoBenef boolean:=false;
 isIndirizzoBenQuiet boolean:=false;

 flussoElabMifValore varchar (1000):=null;
 flussoElabMifValoreDesc varchar (1000):=null;

 ordNumero numeric:=null;
 ordAnno  integer:=null;
 attoAmmTipoSpr varchar(50):=null;
 attoAmmTipoAll varchar(50):=null;
 attoAmmTipoAllAll varchar(50):=null;

 attoAmmStrTipoRag  varchar(50):=null;
 attoAmmTipoAllRag varchar(50):=null;


 tipoMDPCbi varchar(50):=null;
 tipoMDPCsi varchar(50):=null;
 tipoMDPCo  varchar(50):=null;
 tipoMDPCCP varchar(50):=null;
 tipoMDPCB  varchar(50):=null;
 tipoPaeseCB varchar(50):=null;
 avvisoTipoMDPCo varchar(50):=null;
 codiceCge  varchar(50):=null;
 siopeDef   varchar(50):=null;
 codResult   integer:=null;

 indirizzoEnte varchar(500):=null;
 localitaEnte varchar(500):=null;
 soggettoEnteId INTEGER:=null;
 soggettoRifId integer:=null;
 soggettoSedeSecId integer:=null;
 soggettoQuietId integer:=null;
 soggettoQuietRifId integer:=null;
 accreditoGruppoCode varchar(15):=null;




 flussoElabMifLogId  integer :=null;
 flussoElabMifTipoId integer :=null;
 flussoElabMifTipoNomeFile varchar(500):=null;
 flussoElabMifTipoDec BOOLEAN:=false;
 flussoElabMifOilId integer :=null;
 flussoElabMifDistOilRetId integer:=null;
 mifOrdSpesaId integer:=null;

 dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataFineVal timestamp :=annoBilancio||'-12-31';


 ordImporto numeric :=0;


 ordTipoCodeId integer :=null;
 ordStatoCodeIId  integer :=null;
 ordStatoCodeAId  integer :=null;

 classCdrTipoId INTEGER:=null;
 classCdcTipoId INTEGER:=null;
 ordDetTsTipoId integer :=null;

 ordSedeSecRelazTipoId integer:=null;
 ordRelazCodeTipoId integer :=null;
 ordCsiRelazTipoId  integer:=null;

 noteOrdAttrId integer:=null;

 movgestTsTipoSubId integer:=null;


 famTitSpeMacroAggrCodeId integer:=null;
 titoloUscitaCodeTipoId integer :=null;
 programmaCodeTipoId integer :=null;
 programmaCodeTipo varchar(50):=null;
 famMissProgrCode VARCHAR(50):=null;
 famMissProgrCodeId integer:=null;
 programmaId integer :=null;
 titoloUscitaId integer:=null;



 isPaeseSepa integer:=null;
 ordCodiceBollo  varchar(10):=null;
 ordCodiceBolloDesc varchar(500):=null;
 ordDataScadenza timestamp:=null;

 ordCsiRelazTipo varchar(20):=null;
 ordCsiCOTipo varchar(50):=null;


 ambitoFinId integer:=null;
 anagraficaBenefCBI varchar(500):=null;

 isDefAnnoRedisuo  varchar(5):=null;


 -- ritenute
 tipoRelazRitOrd varchar(10):=null;
 tipoRelazSprOrd varchar(10):=null;
 tipoRelazSubOrd varchar(10):=null;
 tipoRitenuta varchar(10):='R';
 progrRitenuta  varchar(10):=null;
 isRitenutaAttivo boolean:=false;
 tipoOnereIrpefId integer:=null;
 tipoOnereInpsId integer:=null;
 tipoOnereIrpef varchar(10):=null;
 tipoOnereInps varchar(10):=null;

 tipoOnereIrpegId integer:=null;
 tipoOnereIrpeg varchar(10):=null;

 codiceUECodeTipo VARCHAR(50):=null;
 codiceUECodeTipoId integer:=null;
 codiceCofogCodeTipo  VARCHAR(50):=null;
 codiceCofogCodeTipoId integer:=null;
 siopeCodeTipo varchar(50):=null;
 siopeCodeTipoId integer :=null;
 eventoTipoCodeId integer:=null;
 collEventoCodeId integer:=null;

 classifTipoCodeFraz    varchar(50):=null;
 classifTipoCodeFrazVal varchar(50):=null;
 classifTipoCodeFrazId   integer:=null;

 tipoClassFruttifero varchar(100):=null;
 valFruttifero varchar(100):=null;
 valFruttiferoStr varchar(100):=null;
 valFruttiferoStrAltro varchar(100):=null;
 tipoClassFruttiferoId integer:=null;
 valFruttiferoId  integer:=null;

 classVincolatoCode   varchar(100):=null;
 classVincolatoCodeId INTEGER:=null;
 valFruttiferoClassCode   varchar(100):=null;
 valFruttiferoClassCodeId INTEGER:=null;
 valFruttiferoClassCodeSI varchar(100):=null;
 valFruttiferoCodeSI varchar(100):=null;
 valFruttiferoClassCodeNO varchar(100):=null;
 valFruttiferoCodeNO varchar(100):=null;

 cigCausAttrId INTEGER:=null;
 cupCausAttrId INTEGER:=null;
 cigCausAttr   varchar(10):=null;
 cupCausAttr   varchar(10):=null;


 codicePaeseIT varchar(50):=null;
 codiceAccreCB varchar(50):=null;
 codiceAccreCO varchar(50):=null;
 codiceAccreREG varchar(50):=null;
 codiceSepa     varchar(50):=null;
 codiceExtraSepa varchar(50):=null;
 codiceGFB  varchar(50):=null;

 sepaCreditTransfer boolean:=false;
 accreditoGruppoSepaTr varchar(10):=null;
 SepaTr varchar(10):=null;
 paeseSepaTr varchar(10):=null;


 numeroDocs varchar(10):=null;
 tipoDocs varchar(50):=null;
 tipoDocsComm varchar(50):=null;
 tipoGruppoDocs varchar(50):=null;

 tipoEsercizio varchar(50):=null;
 statoBeneficiario boolean :=false;
 bavvioFrazAttr boolean :=false;
 dataAvvioFrazAttr timestamp:=null;
 attrfrazionabile VARCHAR(50):=null;

 dataAvvioSiopeNew VARCHAR(50):=null;
 bAvvioSiopeNew   boolean:=false;


 tipoPagamPostA VARCHAR(100):=null;
 tipoPagamPostB VARCHAR(100):=null;

 cupAttrCodeId INTEGER:=null;
 cupAttrCode   varchar(10):=null;
 cigAttrCodeId INTEGER:=null;
 cigAttrCode   varchar(10):=null;
 ricorrenteCodeTipo varchar(50):=null;
 ricorrenteCodeTipoId integer:=null;

 codiceBolloPlusEsente boolean:=false;
 codiceBolloPlusDesc   varchar(100):=null;

 statoDelegatoCredEff boolean :=false;

 comPccAttrId integer:=null;
 pccOperazTipoId integer:=null;


 -- Transazione elementare
 programmaTbr varchar(50):=null;
 codiceFinVTbr varchar(50):=null;
 codiceEconPatTbr varchar(50):=null;
 cofogTbr varchar(50):=null;
 transazioneUeTbr varchar(50):=null;
 siopeTbr varchar(50):=null;
 cupTbr varchar(50):=null;
 ricorrenteTbr varchar(50):=null;
 aslTbr varchar(50):=null;
 progrRegUnitTbr varchar(50):=null;

 codiceFinVTipoTbrId integer:=null;
 cupAttrId integer:=null;
 ricorrenteTipoTbrId integer:=null;
 aslTipoTbrId integer:=null;
 progrRegUnitTipoTbrId integer:=null;

 codiceFinVCodeTbr varchar(50):=null;
 contoEconCodeTbr varchar(50):=null;
 cofogCodeTbr varchar(50):=null;
 codiceUeCodeTbr varchar(50):=null;
 siopeCodeTbr varchar(50):=null;
 cupAttrTbr varchar(50):=null;
 ricorrenteCodeTbr varchar(50):=null;
 aslCodeTbr  varchar(50):=null;
 progrRegUnitCodeTbr varchar(50):=null;



 isGestioneQuoteOK boolean:=false;
 isGestioneFatture boolean:=false;
 isRicevutaAttivo boolean:=false;
 isTransElemAttiva boolean:=false;
 isMDPCo boolean:=false;
 isOrdPiazzatura boolean:=false;

 docAnalogico    varchar(100):=null;
 titoloCorrente   varchar(100):=null;
 descriTitoloCorrente varchar(100):=null;
 titoloCapitale   varchar(100):=null;
 descriTitoloCapitale varchar(100):=null;

 -- 20.02.2018 Sofia jira siac-5849
 defNaturaPag  varchar(100):=null;

 attrCodeDataScad varchar(100):=null;
 titoloCap  varchar(100):=null;

 isOrdCommerciale boolean:=false;
 -- 20.03.2018 Sofia SIAC-5968
 tipoPdcIVA VARCHAR(100):=null;
 codePdcIVA VARCHAR(100):=null;

 NVL_STR               CONSTANT VARCHAR:='';


 ORD_TIPO_CODE_P  CONSTANT  varchar :='P';
 ORD_STATO_CODE_I CONSTANT  varchar :='I';
 ORD_STATO_CODE_A CONSTANT  varchar :='A';
 ORD_RELAZ_CODE_SOS  CONSTANT  varchar :='SOS_ORD';
 ORD_TIPO_A CONSTANT  varchar :='A';

 ORD_RELAZ_SEDE_SEC CONSTANT  varchar :='SEDE_SECONDARIA';
 AMBITO_FIN CONSTANT  varchar :='AMBITO_FIN';

 NOTE_ORD_ATTR CONSTANT  varchar :='NOTE_ORDINATIVO';

 CDC CONSTANT varchar:='CDC';
 CDR CONSTANT varchar:='CDR';


 PROGRAMMA               CONSTANT varchar:='PROGRAMMA';
 TITOLO_SPESA            CONSTANT varchar:='TITOLO_SPESA';
 FAM_TIT_SPE_MACROAGGREG CONSTANT varchar:='Spesa - TitoliMacroaggregati';

 FUNZIONE_CODE_I CONSTANT  varchar :='INSERIMENTO'; -- inserimenti
 FUNZIONE_CODE_S CONSTANT  varchar :='SOSTITUZIONE'; -- sostituzioni senza trasmissione
 FUNZIONE_CODE_N CONSTANT  varchar :='ANNULLO'; -- annullamenti prima di trasmissione

 FUNZIONE_CODE_A CONSTANT  varchar :='ANNULLO'; -- annullamenti dopo trasmissione
 FUNZIONE_CODE_VB CONSTANT  varchar :='VARIAZIONE'; -- spostamenti dopo trasmissione


 ORD_TS_DET_TIPO_A CONSTANT varchar:='A';
 MOVGEST_TS_TIPO_S  CONSTANT varchar:='S';

 SPACE_ASCII CONSTANT integer:=32;
 VT_ASCII CONSTANT integer:=13;
 BS_ASCII CONSTANT integer:=10;

 NUM_SETTE CONSTANT integer:=7;
 NUM_DODICI CONSTANT integer:=12;
 ZERO_PAD CONSTANT  varchar :='0';

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='MANDMIF_SPLUS';


 COM_PCC_ATTR  CONSTANT  varchar :='flagComunicaPCC';
 PCC_OPERAZ_CPAG  CONSTANT varchar:='CP';

 SEPARATORE     CONSTANT  varchar :='|';



 FLUSSO_MIF_ELAB_TEST_COD_ABI_BT      CONSTANT integer:=1;  -- codice_ABI_BT
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA    CONSTANT integer:=4;  -- codice_ente
 FLUSSO_MIF_ELAB_TEST_DESC_ENTE       CONSTANT integer:=5;  -- descrizione_ente
 FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE  CONSTANT integer:=6;  -- codice_istat_ente
 FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE    CONSTANT integer:=7;  -- codice_fiscale_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE CONSTANT integer:=8;  -- codice_tramite_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT   CONSTANT integer:=9;  -- codice_tramite_bt
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT     CONSTANT integer:=10; -- codice_ente_bt
 FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE CONSTANT integer:=11; -- riferimento_ente
 FLUSSO_MIF_ELAB_TEST_ESERCIZIO       CONSTANT integer:=12; -- riferimento_ente

 FLUSSO_MIF_ELAB_INIZIO_ORD     CONSTANT integer:=13;  -- tipo_operazione

 FLUSSO_MIF_ELAB_FATTURE        CONSTANT integer:=53;  -- fattura_siope_codice_ipa_ente_siope
 FLUSSO_MIF_ELAB_FATT_CODFISC   CONSTANT integer:=58;  -- fattura_siope_codice_fiscale_emittente_siope
 FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG CONSTANT integer:=62; -- data_scadenza_pagam_siope
 FLUSSO_MIF_ELAB_FATT_NATURA_PAG CONSTANT integer:=64; -- natura_spesa_siope
 FLUSSO_MIF_ELAB_NUM_SOSPESO    CONSTANT integer:=122; -- numero_provvisorio
 FLUSSO_MIF_ELAB_RITENUTA       CONSTANT integer:=124; -- importo_ritenuta
 FLUSSO_MIF_ELAB_RITENUTA_PRG   CONSTANT integer:=126; -- progressivo_versante


 REGMOVFIN_STATO_A              CONSTANT varchar:='A';
 SEGNO_ECONOMICO				CONSTANT varchar:='Dare';



BEGIN

	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;

    flussoElabMifDistOilId:=null;

	strMessaggioFinale:='Invio ordinativi di spesa SIOPE PLUS.';


    -- enteOilRec
    strMessaggio:='Lettura dati ente OIL  per flusso MIF tipo '||MANDMIF_TIPO||'.';
    select * into strict enteOilRec
    from siac_t_ente_oil ente
    where ente.ente_proprietario_id=enteProprietarioId
    and   ente.data_cancellazione is null
    and   ente.validita_fine is null;

    if enteOilRec is null then
    	raise exception ' Errore in reperimento dati';
    end if;

    if enteOilRec.ente_oil_siope_plus=false then
    	raise exception ' SIOPE PLUS non attivo per l''ente.';
    end if;

    -- inserimento record in tabella mif_t_flusso_elaborato
    strMessaggio:='Inserimento mif_t_flusso_elaborato tipo flusso='||MANDMIF_TIPO||'.';

    insert into mif_t_flusso_elaborato
    (flusso_elab_mif_data ,
     flusso_elab_mif_esito,
     flusso_elab_mif_esito_msg,
     flusso_elab_mif_file_nome,
     flusso_elab_mif_tipo_id,
     flusso_elab_mif_id_flusso_oil, -- da calcolare su tab progressivi
     flusso_elab_mif_codice_flusso_oil, -- da calcolare su tab progressivi
     validita_inizio,
     ente_proprietario_id,
     login_operazione)
     (select dataElaborazione,
             ELAB_MIF_ESITO_IN,
             'Elaborazione in corso per tipo flusso '||MANDMIF_TIPO,
      		 tipo.flusso_elab_mif_nome_file,
     		 tipo.flusso_elab_mif_tipo_id,
     		 null,--flussoElabMifOilId, -- da calcolare su tab progressivi
             null, -- flussoElabMifDistOilId -- da calcolare su tab progressivi
    		 dataElaborazione,
     		 enteProprietarioId,
      		 loginOperazione
      from mif_d_flusso_elaborato_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null
     )
     returning flusso_elab_mif_id into flussoElabMifLogId;-- valore da restituire

      raise notice 'flussoElabMifLogId %',flussoElabMifLogId;

     if flussoElabMifLogId is null then
       RAISE EXCEPTION ' Errore generico in inserimento %.',MANDMIF_TIPO;
     end if;

    strMessaggio:='Verifica esistenza elaborazioni in corso per tipo flusso '||MANDMIF_TIPO||'.';
	codResult:=null;
    select distinct 1 into codResult
    from mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
    where  elab.flusso_elab_mif_id!=flussoElabMifLogId
    and    elab.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN
    and    elab.data_cancellazione is null
    and    elab.validita_fine is null
    and    tipo.flusso_elab_mif_tipo_id=elab.flusso_elab_mif_tipo_id
    and    tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
    and    tipo.ente_proprietario_id=enteProprietarioId
    and    tipo.data_cancellazione is null
    and    tipo.validita_fine is null;

    if codResult is not null then
    	RAISE EXCEPTION ' Verificare situazioni esistenti.';
    end if;

    -- verifico se la tabella degli id contiene dati in tal caso elaborazioni precedenti sono andate male
    strMessaggio:='Verifica esistenza dati in tabella temporanea id [mif_t_ordinativo_spesa_id].';
    codResult:=null;
    select distinct 1 into codResult
    from mif_t_ordinativo_spesa_id mif
    where mif.ente_proprietario_id=enteProprietarioId;

    if codResult is not null then
      RAISE EXCEPTION ' Dati presenti verificarne il contenuto ed effettuare pulizia prima di rieseguire.';
    end if;



    codResult:=null;
    -- recupero indentificativi tipi codice vari
	begin

        -- ordTipoCodeId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_P||'.';
        select ord_tipo.ord_tipo_id into strict ordTipoCodeId
        from siac_d_ordinativo_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_tipo_code=ORD_TIPO_CODE_P
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
   		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

		-- ordStatoCodeIId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_I||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeIId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ordStatoCodeAId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_A||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeAId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


		-- classCdrTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDR||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDR
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

        -- classCdcTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDC||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDC
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


		-- ordDetTsTipoId
        strMessaggio:='Lettura tipo importo ordinativo  Code Id '||ORD_TS_DET_TIPO_A||'.';
        select ord_tipo.ord_ts_det_tipo_id into strict ordDetTsTipoId
        from siac_d_ordinativo_ts_det_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ordSedeSecRelazTipoId
        strMessaggio:='Lettura relazione sede secondaria  Code Id '||ORD_RELAZ_SEDE_SEC||'.';
        select ord_tipo.relaz_tipo_id into strict ordSedeSecRelazTipoId
        from siac_d_relaz_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.relaz_tipo_code=ORD_RELAZ_SEDE_SEC
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


		-- ordRelazCodeTipoId
        strMessaggio:='Lettura relazione   Code Id '||ORD_RELAZ_CODE_SOS||'.';
		select ord_tipo.relaz_tipo_id into strict ordRelazCodeTipoId
    	from siac_d_relaz_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.relaz_tipo_code=ORD_RELAZ_CODE_SOS
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- movgestTsTipoSubId
        strMessaggio:='Lettura movgest_ts_tipo  '||MOVGEST_TS_TIPO_S||'.';
		select ord_tipo.movgest_ts_tipo_id into strict movgestTsTipoSubId
    	from siac_d_movgest_ts_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.movgest_ts_tipo_code=MOVGEST_TS_TIPO_S
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


    	-- programmaCodeTipoId
        strMessaggio:='Lettura programma_code_tipo_id  '||PROGRAMMA||'.';
		select tipo.classif_tipo_id into strict programmaCodeTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=PROGRAMMA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

		-- famTitSpeMacroAggrCodeId
		-- FAM_TIT_SPE_MACROAGGREG='Spesa - TitoliMacroaggregati'
        strMessaggio:='Lettura fam_tit_spe_macroggregati_code_tipo_id  '||FAM_TIT_SPE_MACROAGGREG||'.';
		select fam.classif_fam_tree_id into strict famTitSpeMacroAggrCodeId
        from siac_t_class_fam_tree fam
        where fam.ente_proprietario_id=enteProprietarioId
        and   fam.class_fam_code=FAM_TIT_SPE_MACROAGGREG
        and   fam.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(fam.validita_fine,dataElaborazione));


    	-- titoloUscitaCodeTipoId
        strMessaggio:='Lettura titolo_spesa_code_tipo_id  '||TITOLO_SPESA||'.';
		select tipo.classif_tipo_id into strict titoloUscitaCodeTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=TITOLO_SPESA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

		-- noteOrdAttrId
        strMessaggio:='Lettura noteOrdAttrId per attributo='||NOTE_ORD_ATTR||'.';
		select attr.attr_id into strict  noteOrdAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NOTE_ORD_ATTR
        and   attr.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
 	 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));


        -- ambitoFinId
        strMessaggio:='Lettura ambito  Code Id '||AMBITO_FIN||'.';
        select a.ambito_id into strict ambitoFinId
        from siac_d_ambito a
        where a.ente_proprietario_id=enteProprietarioId
   		and   a.ambito_code=AMBITO_FIN
        and   a.data_cancellazione is null
        and   a.validita_fine is null;

        -- flussoElabMifTipoId
        strMessaggio:='Lettura tipo flusso MIF  Code Id '||MANDMIF_TIPO||'.';
        select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file, tipo.flusso_elab_mif_tipo_dec
               into strict flussoElabMifTipoId,flussoElabMifTipoNomeFile, flussoElabMifTipoDec
        from mif_d_flusso_elaborato_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
   		and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        -- raise notice 'flussoElabMifTipoId %',flussoElabMifTipoId;
        -- mifFlussoElabTypeRec


        strMessaggio:='Lettura flusso struttura MIF  per tipo '||MANDMIF_TIPO||'.';
        for mifElabRec IN
        (select m.*
         from mif_d_flusso_elaborato m
         where m.flusso_elab_mif_tipo_id=flussoElabMifTipoId
         and   m.flusso_elab_mif_elab=true
         order by m.flusso_elab_mif_ordine_elab
        )
        loop
        	mifAFlussoElabTypeRec.flussoElabMifId :=mifElabRec.flusso_elab_mif_id;
            mifAFlussoElabTypeRec.flussoElabMifAttivo :=mifElabRec.flusso_elab_mif_attivo;
            mifAFlussoElabTypeRec.flussoElabMifDef :=mifElabRec.flusso_elab_mif_default;
            mifAFlussoElabTypeRec.flussoElabMifElab :=mifElabRec.flusso_elab_mif_elab;
            mifAFlussoElabTypeRec.flussoElabMifParam :=mifElabRec.flusso_elab_mif_param;

            mifAFlussoElabTypeRec.flusso_elab_mif_ordine_elab :=mifElabRec.flusso_elab_mif_ordine_elab;
            mifAFlussoElabTypeRec.flusso_elab_mif_ordine :=mifElabRec.flusso_elab_mif_ordine;
            mifAFlussoElabTypeRec.flusso_elab_mif_code :=mifElabRec.flusso_elab_mif_code;
            mifAFlussoElabTypeRec.flusso_elab_mif_campo :=mifElabRec.flusso_elab_mif_campo;

            mifFlussoElabMifArr[mifElabRec.flusso_elab_mif_ordine_elab]:=mifAFlussoElabTypeRec;

        end loop;



		-- Gestione registroPcc per enti che non gestiscono quitanze
        -- Nota : capire se necessario gestire PCC
		/*if enteOilRec.ente_oil_quiet_ord=false then

  			-- comPccAttrId
	        strMessaggio:='Lettura comPccAttrId per attributo='||COM_PCC_ATTR||'.';
			select attr.attr_id into strict  comPccAttrId
	        from siac_t_attr attr
	        where attr.ente_proprietario_id=enteProprietarioId
	        and   attr.attr_code=COM_PCC_ATTR
	        and   attr.data_cancellazione is null
	        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
   	 	    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));

            strMessaggio:='Lettura Id tipo operazine PCC='||PCC_OPERAZ_CPAG||'.';
			select pcc.pccop_tipo_id into strict pccOperazTipoId
		    from siac_d_pcc_operazione_tipo pcc
		    where pcc.ente_proprietario_id=enteProprietarioId
		    and   pcc.pccop_tipo_code=PCC_OPERAZ_CPAG;


        end if;*/

        -- enteProprietarioRec
        strMessaggio:='Lettura dati ente proprietario per flusso MIF tipo '||MANDMIF_TIPO||'.';
        select * into strict enteProprietarioRec
        from siac_t_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
	    and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        -- soggettoEnteId
        strMessaggio:='Lettura indirizzo ente proprietario [siac_r_soggetto_ente_proprietario] per flusso MIF tipo '||MANDMIF_TIPO||'.';
        select ente.soggetto_id into soggettoEnteId
        from siac_r_soggetto_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        if soggettoEnteId is not null then
            strMessaggio:='Lettura indirizzo ente proprietario [siac_t_indirizzo_soggetto] per flusso MIF tipo '||MANDMIF_TIPO||'.';

        	select viaTipo.via_tipo_code||' '||indir.toponimo||' '||indir.numero_civico,
        		   com.comune_desc
                   into indirizzoEnte,localitaEnte
            from siac_t_indirizzo_soggetto indir,
                 siac_t_comune com,
                 siac_d_via_tipo viaTipo
            where indir.soggetto_id=soggettoEnteId
            and   indir.principale='S'
            and   indir.data_cancellazione is null
            and   indir.validita_fine is null
            and   com.comune_id=indir.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null
            and   viaTipo.via_tipo_id=indir.via_tipo_id
            and   viaTipo.data_cancellazione is null
	   		and   date_trunc('day',dataElaborazione)>=date_trunc('day',viaTipo.validita_inizio)
 			and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(viaTipo.validita_fine,dataElaborazione))
            order by indir.indirizzo_id;
        end if;

        -- Calcolo progressivo "distinta" per flusso MANDMIF
	    -- calcolo su progressivi di flussoElabMifDistOilId flussoOIL univoco per tipo flusso
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
        select prog.prog_value into flussoElabMifDistOilRetId -- 25.05.2016 Sofia - JIRA-3619
        from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifDistOilRetId is null then -- 25.05.2016 Sofia - JIRA-3619
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_'||MANDMIF_TIPO||'_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifDistOilRetId:=0;
            end if;
        end if;

        if flussoElabMifDistOilRetId is not null then
	        flussoElabMifDistOilRetId:=flussoElabMifDistOilRetId+1;
        end if;

	    -- calcolo su progressivo di flussoElabMifOilId flussoOIL univoco
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
        select prog.prog_value into flussoElabMifOilId
        from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_out_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifOilId is null then
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_out_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifOilId:=0;
            end if;
        end if;

        if flussoElabMifOilId is not null then
	        flussoElabMifOilId:=flussoElabMifOilId+1;
        end if;

        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
        when TOO_MANY_ROWS THEN
            RAISE EXCEPTION ' Diverse righe presenti in archivio.';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;




    --- popolamento mif_t_ordinativo_spesa_id


    -- ordinativi emessi o emessi/spostati non ancora mai trasmessi codice_funzione='I' -- INSERIMENTO
    strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_I||'.';

    insert into mif_t_ordinativo_spesa_id
    (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
     mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
     mif_ord_soggetto_id, mif_ord_modpag_id,
     mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
     mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
     mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
     mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
     mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
     mif_ord_login_creazione,mif_ord_login_modifica,
     ente_proprietario_id, login_operazione)
    (
     with
     ritrasm as
     (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	  from mif_t_ordinativo_ritrasmesso r
	  where mifOrdRitrasmElabId is not null
	  and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	  and   r.ente_proprietario_id=enteProprietarioId
	  and   r.data_cancellazione is null),
     ordinativi as
     (
      select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_I mif_ord_codice_funzione,
             bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
             ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
             extract('year' from ord.ord_emissione_data)||'-'||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione , 0 mif_ord_ord_anno_movg,
             0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id, elem.elem_id mif_ord_elem_id,
             0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
             ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
             ord.comm_tipo_id mif_ord_comm_tipo_id,ord.notetes_id mif_ord_notetes_id, ord.ord_desc mif_ord_desc,
             ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
             ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
             ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
             enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
      from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,siac_t_bil bil, siac_t_periodo per,siac_r_ordinativo_bil_elem elem
      where  bil.ente_proprietario_id=enteProprietarioId
        and  per.periodo_id=bil.periodo_id
        and  per.anno::integer <=annoBilancio::integer
        and  ord.bil_id=bil.bil_id
        and  ord.ord_tipo_id=ordTipoCodeId
        and  ord_stato.ord_id=ord.ord_id
        and  ord_stato.data_cancellazione is null
	    and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	    and  ord_stato.validita_fine is null
        and  ord_stato.ord_stato_id=ordStatoCodeIId
        and  ord.ord_trasm_oil_data is null
        and  ord.ord_emissione_data<=dataElaborazione
        and  elem.ord_id=ord.ord_id
        and  elem.data_cancellazione is null
        and  not exists (select 1 from siac_r_ordinativo rord
                          where rord.ord_id_a=ord.ord_id
                          and   rord.data_cancellazione is null
                          and   rord.validita_fine is null
			              and   rord.relaz_tipo_id=ordRelazCodeTipoId)
       )
       select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );


      -- ordinativi emessi o emessi/spostati non ancora mai trasmessi, sostituzione di altro ordinativo codice_funzione='S' -- 'SOSPENSIONE'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_S||'.';

      insert into mif_t_ordinativo_spesa_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
 	   mif_ord_soggetto_id, mif_ord_modpag_id,
 	   mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
 	   mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id, mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_S mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id ,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,ord.notetes_id mif_ord_notetes_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione, ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem,siac_r_ordinativo rord
  	    where  bil.ente_proprietario_id=enteProprietarioId
   		  and  per.periodo_id=bil.periodo_id
    	  and  per.anno::integer <=annoBilancio::integer
      	  and  ord.bil_id=bil.bil_id
     	  and  ord.ord_tipo_id=ordTipoCodeId
    	  and  ord_stato.ord_id=ord.ord_id
    	  and  ord_stato.data_cancellazione is null
	   	  and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	      and  ord_stato.validita_fine is null
    	  and  ord_stato.ord_stato_id=ordStatoCodeIId
	      and  ord.ord_trasm_oil_data is null
    	  and  ord.ord_emissione_data<=dataElaborazione
    	  and  elem.ord_id=ord.ord_id
    	  and  elem.data_cancellazione is null
          and  elem.validita_fine is null
          and  rord.ord_id_a=ord.ord_id
          and  rord.relaz_tipo_id=ordRelazCodeTipoId
          and  rord.data_cancellazione is null
          and  rord.validita_fine is null
        )
        select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
		   or (mifOrdRitrasmElabId is not null and exists
              (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );

      -- ordinativi emessi e annullati mai trasmessi codice_funzione='N' -- ANNULLO
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_N||'.';

	  insert into mif_t_ordinativo_spesa_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
	   mif_ord_soggetto_id, mif_ord_modpag_id,
	   mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
 	   mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_N mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
      	 	   ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,
               ord.codbollo_id mif_ord_codbollo_id,ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord, siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord_stato.ord_id=ord.ord_id
         and  ord_stato.validita_inizio<=dataElaborazione -- questa e'' la data di annullamento
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord_stato.data_cancellazione is null
         and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	     and  ord_stato.validita_fine is null
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ord.ord_trasm_oil_data is null
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
       ),
       -- 23.03.2018 Sofia SIAC-5969
       ordSos as
       (
          select rord.ord_id_da, rord.ord_id_a
          from siac_r_ordinativo rOrd
          where rOrd.ente_proprietario_id=enteProprietarioId
          and   rOrd.relaz_tipo_id=ordRelazCodeTipoId
          and   rOrd.data_cancellazione is null
          and   rOrd.validita_fine is null
       ),
       -- 16.04.2018 Sofia siac-6067
       enteOil as
       (
       select false esclAnnull
       from siac_t_ente_oil oil
       where oil.ente_proprietario_id=enteProprietarioId
       and   oil.ente_oil_invio_escl_annulli=false
       )
       select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o, enteOil  -- 16.04.2018 Sofia siac-6067
/*	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))*/
	   where
        -- 23.03.2018 Sofia SIAC-5969
        ( mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
        )
        and  enteOil.esclAnnull=false -- 16.04.2018 Sofia siac-6067
        -- 23.03.2018 Sofia SIAC-5969 : devono essere escludi ordinativi
        -- sostituiti e sostituti
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_da=o.mif_ord_ord_id)
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_a=o.mif_ord_ord_id)
	   );

      -- ordinativi emessi tramessi e poi annullati, anche dopo spostamento  codice_funzione='A' -- ANNULLO
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_A||'.';

      insert into mif_t_ordinativo_spesa_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_modpag_id,
       mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_liq_id, mif_ord_atto_amm_id,mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_A mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
          and  per.periodo_id=bil.periodo_id
          and  per.anno::integer <=annoBilancio::integer
          and  ord.bil_id=bil.bil_id
          and  ord.ord_tipo_id=ordTipoCodeId
   		  and  ord_stato.ord_id=ord.ord_id
  		  and  ord.ord_emissione_data<=dataElaborazione
          and  ord_stato.validita_inizio<=dataElaborazione  -- questa e'' la data di annullamento
  		  and  ord.ord_trasm_oil_data is not null
 		  and  ord.ord_trasm_oil_data<ord_stato.validita_inizio
          and  ord_stato.data_cancellazione is null
          and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	      and  ord_stato.validita_fine is null
          and  ord_stato.ord_stato_id=ordStatoCodeAId
          and  ( ord.ord_spostamento_data is null or ord.ord_spostamento_data<ord_stato.validita_inizio)
          and  elem.ord_id=ord.ord_id
          and  elem.data_cancellazione is null
          and  elem.validita_fine is null
        ),
        -- 23.03.2018 Sofia SIAC-5969
        ordSos as
        (
          select rord.ord_id_da, rord.ord_id_a
          from siac_r_ordinativo rOrd
          where rOrd.ente_proprietario_id=enteProprietarioId
          and   rOrd.relaz_tipo_id=ordRelazCodeTipoId
          and   rOrd.data_cancellazione is null
          and   rOrd.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
        from ordinativi o
        -- 23.03.2018 Sofia SIAC-5969
/*	    where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))*/
	    where
        ( mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
        )
        -- 23.03.2018 Sofia SIAC-5969 : devono essere escludi ordinativi
        -- sostituiti e sostituti
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_da=o.mif_ord_ord_id)
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_a=o.mif_ord_ord_id)
       );

      -- ordinativi emessi , trasmessi  e poi spostati codice_funzione='VB' ( mai annullati ) _--- VARIAZIONE
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_VB||'.';

      insert into mif_t_ordinativo_spesa_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_modpag_id,
       mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_VB mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord.ord_trasm_oil_data is not null
         and  ord.ord_spostamento_data is not null
         and  ord.ord_trasm_oil_data<ord.ord_spostamento_data
         and  ord.ord_spostamento_data<=dataElaborazione
         and  not exists (select 1 from siac_r_ordinativo_stato ord_stato
  				          where  ord_stato.ord_id=ord.ord_id
					        and  ord_stato.ord_stato_id=ordStatoCodeAId
                            and  ord_stato.data_cancellazione is null)
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
       select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );
      -- aggiornamento mif_t_ordinativo_spesa_id per id


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per fase_operativa_code.';
      update mif_t_ordinativo_spesa_id m
      set mif_ord_bil_fase_ope=(select fase.fase_operativa_code from siac_r_bil_fase_operativa rFase, siac_d_fase_operativa fase
      							where rFase.bil_id=m.mif_ord_bil_id
                                and   rFase.data_cancellazione is null
                                and   rFase.validita_fine is null
                                and   fase.fase_operativa_id=rFase.fase_operativa_id
                                and   fase.data_cancellazione is null
                                and   fase.validita_fine is null);


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per soggetto_id.';
      -- soggetto_id

      update mif_t_ordinativo_spesa_id m
      set mif_ord_soggetto_id=coalesce(s.soggetto_id,0)
      from siac_r_ordinativo_soggetto s
      where s.ord_id=m.mif_ord_ord_id
      and s.data_cancellazione is null
      and s.validita_fine is null;

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id.';

      -- modpag_id
      update mif_t_ordinativo_spesa_id m set  mif_ord_modpag_id=coalesce(s.modpag_id,0)
      from siac_r_ordinativo_modpag s
      where s.ord_id=m.mif_ord_ord_id
   	  and s.modpag_id is not null
      and s.data_cancellazione is null
      and s.validita_fine is null;

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id [CSI].';
      update mif_t_ordinativo_spesa_id m set mif_ord_modpag_id=coalesce(rel.modpag_id,0)
      from siac_r_ordinativo_modpag s, siac_r_soggrel_modpag rel
      where s.ord_id=m.mif_ord_ord_id
      and s.soggetto_relaz_id is not null
      and rel.soggetto_relaz_id=s.soggetto_relaz_id
      and s.data_cancellazione is null
      and s.validita_fine is null
      and rel.data_cancellazione is null
      --  and rel.validita_fine is null
      -- 04.04.2018 Sofia SIAC-6064
      and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(rel.validita_fine,dataElaborazione))
      and exists  (select  1 from siac_r_soggrel_modpag rel1
                   where    rel.soggetto_relaz_id=s.soggetto_relaz_id
		           and      rel1.soggrelmpag_id=rel.soggrelmpag_id
         		   order by rel1.modpag_id
			       limit 1);

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per subord_id.';

      -- subord_id
      update mif_t_ordinativo_spesa_id m
      set mif_ord_subord_id =
                             (select s.ord_ts_id from siac_t_ordinativo_ts s
                               where s.ord_id=m.mif_ord_ord_id
                                 and s.data_cancellazione is null
                                 and s.validita_fine is null
                               order by s.ord_ts_id
                               limit 1);

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per liq_id.';

	 -- liq_id
	 update mif_t_ordinativo_spesa_id m
	 set mif_ord_liq_id = (select s.liq_id from siac_r_liquidazione_ord s
                            where s.sord_id = m.mif_ord_subord_id
                              and s.data_cancellazione is null
                              and s.validita_fine is null);
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_ts_id.';

     -- movgest_ts_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_ts_id = (select s.movgest_ts_id from siac_r_liquidazione_movgest s
                                   where s.liq_id = m.mif_ord_liq_id
                                     and s.data_cancellazione is null
                                     and s.validita_fine is null);
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_id = (select s.movgest_id from siac_t_movgest_ts s
                               where  s.movgest_ts_id = m.mif_ord_movgest_ts_id
                               and s.data_cancellazione is null
                               and s.validita_fine is null);

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_anno
     update mif_t_ordinativo_spesa_id m
     set mif_ord_ord_anno_movg = (select s.movgest_anno from siac_t_movgest s
                              	  where  s.movgest_id = m.mif_ord_movgest_id
                             	  and s.data_cancellazione is null
                                  and s.validita_fine is null);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id.';

    -- attoamm_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_id = (select s.attoamm_id from siac_r_liquidazione_atto_amm s
                                where s.liq_id = m.mif_ord_liq_id
                                  and s.data_cancellazione is null
                                  and s.validita_fine is null);

    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id movgest_ts.';
	-- attoamm_movgest_ts_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_movg_id = (select s.attoamm_id from siac_r_movgest_ts_atto_amm s
                                    where s.movgest_ts_id = m.mif_ord_movgest_ts_id
                                    and s.data_cancellazione is null
                                    and s.validita_fine is null);

	-- mif_ord_programma_id
    -- mif_ord_programma_code
    -- mif_ord_programma_desc
    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_programma_id mif_ord_programma_code mif_ord_programma_desc.';
    update mif_t_ordinativo_spesa_id m
    set (mif_ord_programma_id,mif_ord_programma_code,mif_ord_programma_desc) = (class.classif_id,class.classif_code,class.classif_desc) -- 11.01.2016 Sofia
    from siac_r_bil_elem_class classElem, siac_t_class class
    where classElem.elem_id=m.mif_ord_elem_id
    and   class.classif_id=classElem.classif_id
    and   class.classif_tipo_id=programmaCodeTipoId
    and   classElem.data_cancellazione is null
    and   classElem.validita_fine is null
    and   class.data_cancellazione is null;

	-- mif_ord_titolo_id
    -- mif_ord_titolo_code
    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_titolo_id mif_ord_titolo_code.';
    update mif_t_ordinativo_spesa_id m
    set (mif_ord_titolo_id, mif_ord_titolo_code) = (cp.classif_id,cp.classif_code)
	from siac_r_bil_elem_class classElem, siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
	where classElem.elem_id=m.mif_ord_elem_id
    and   cf.classif_id=classElem.classif_id
    and   cf.data_cancellazione is null
    and   classElem.data_cancellazione is null
    and   classElem.validita_fine is null
	and   r.classif_id=cf.classif_id
	and   r.classif_id_padre is not null
	and   r.classif_fam_tree_id=famTitSpeMacroAggrCodeId
    and   r.data_cancellazione is null
    and   r.validita_fine is null
	and   cp.classif_id=r.classif_id_padre
    and   cp.data_cancellazione is null;






	-- mif_ord_note_attr_id
	strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_note_attr_id.';
	update mif_t_ordinativo_spesa_id m
    set mif_ord_note_attr_id= attr.ord_attr_id
    from siac_r_ordinativo_attr attr
    where attr.ord_id=m.mif_ord_ord_id
    and   attr.attr_id=noteOrdAttrId
    and   attr.data_cancellazione is null
    and   attr.validita_fine is null;


    strMessaggio:='Verifica esistenza ordinativi di spesa da trasmettere.';
    codResult:=null;
    select 1 into codResult
    from mif_t_ordinativo_spesa_id where ente_proprietario_id=enteProprietarioId;

    if codResult is null then
      codResult:=-12;
      RAISE EXCEPTION ' Nessun ordinativo di spesa da trasmettere.';
    end if;


    -- <ritenute>
    flussoElabMifElabRec:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_RITENUTA];

    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                   ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
  					tipoRelazRitOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	                tipoRelazSprOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
	                tipoRelazSubOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    tipoOnereIrpef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                    tipoOnereInps:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                    tipoOnereIrpeg:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));


                    if tipoRelazRitOrd is null or tipoRelazSprOrd is null or tipoRelazSubOrd is null
                       or tipoOnereInps is null or tipoOnereIrpef is null
                       or tipoOnereIrpeg is null then
                       RAISE EXCEPTION ' Dati configurazione ritenute non completi.';
                    end if;
                    isRitenutaAttivo:=true;
            end if;
	    else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   	end if;
   end if;

   if isRitenutaAttivo=true then
     	flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_RITENUTA_PRG];
         strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	   	 if flussoElabMifElabRec.flussoElabMifId is null then
  			  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   	 end if;
    	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
    		if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	progrRitenuta:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
	    	else
				RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   		end if;
	     else
    	   isRitenutaAttivo:=false;
		 end if;
   end if;

   if isRitenutaAttivo=true then
           strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereIrpef
                       ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereIrpefId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereIrpef
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
   		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

           if tipoOnereIrpefId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;

           strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereInps
                       ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereInpsId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereInps
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


           if tipoOnereInpsId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;

		   strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereIrpeg
                        ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereIrpegId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereIrpeg
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


           if tipoOnereIrpegId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;
   end if;


   -- <sospesi>
   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_NUM_SOSPESO];
   mifCountRec:=FLUSSO_MIF_ELAB_NUM_SOSPESO;
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
			null;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
   		end if;
        isRicevutaAttivo:=true;
   end if;




   flussoElabMifElabRec:=null;
   mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    numeroDocs:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            tipoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            tipoGruppoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            if numeroDocs is not null and numeroDocs!='' and
               tipoDocs is not null and tipoDocs!='' and
               tipoGruppoDocs is not null and tipoGruppoDocs!='' then
                tipoDocs:=tipoDocs||'|'||tipoGruppoDocs;
            	isGestioneFatture:=true;
            end if;
		end if;
    else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
    end if;
   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_CODFISC;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    docAnalogico:=flussoElabMifElabRec.flussoElabMifParam;
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then
    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            attrCodeDataScad:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_NATURA_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
        -- 20.02.2018 Sofia JIRA siac-5849
        /*
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            titoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            descriTitoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            titoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            descriTitoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));

		end if;*/

        -- 20.02.2018 Sofia JIRA siac-5849
        if flussoElabMifElabRec.flussoElabMifDef is not null then
        	defNaturaPag:=flussoElabMifElabRec.flussoElabMifDef;
        end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   --- lettura mif_t_ordinativo_spesa_id per popolamento mif_t_ordinativo_spesa
   codResult:=null;
   strMessaggio:='Lettura ordinativi di spesa da migrare [mif_t_ordinativo_spesa_id].Inizio ciclo.';
   for mifOrdinativoIdRec IN
   (select ms.*
     from mif_t_ordinativo_spesa_id ms
     where ms.ente_proprietario_id=enteProprietarioId
     order by ms.mif_ord_anno_bil,
              ms.mif_ord_ord_numero
   )
   loop


		mifFlussoOrdinativoRec:=null;
		MDPRec:=null;
        codAccreRec:=null;
		bilElemRec:=null;
        soggettoRec:=null;
        soggettoSedeRec:=null;
        soggettoRifId:=null;
        soggettoSedeSecId:=null;
		indirizzoRec:=null;
        mifOrdSpesaId:=null;




        isIndirizzoBenef:=true;
        isIndirizzoBenQuiet:=true;


        bavvioFrazAttr:=false;
        bAvvioSiopeNew:=false;


	    statoBeneficiario:=false;
		statoDelegatoCredEff:=false;

        -- lettura importo ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura importo ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        mifFlussoOrdinativoRec.mif_ord_importo:=fnc_mif_importo_ordinativo(mifOrdinativoIdRec.mif_ord_ord_id,ordDetTsTipoId,
        													  		       flussoElabMifTipoDec);
        if flussoElabMifTipoDec=true and
           coalesce(position('.' in mifFlussoOrdinativoRec.mif_ord_importo),0)=0 then
           mifFlussoOrdinativoRec.mif_ord_importo:=mifFlussoOrdinativoRec.mif_ord_importo||'.00';
        end if;

        -- lettura MDP ti ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura MDP ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

		select * into MDPRec
        from siac_t_modpag mdp
        where mdp.modpag_id=mifOrdinativoIdRec.mif_ord_modpag_id;
        if MDPRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_modpag.';
        end if;

        -- lettura accreditoTipo ti ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura accredito tipo ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        select tipo.accredito_tipo_id, tipo.accredito_tipo_code,tipo.accredito_tipo_desc,
               gruppo.accredito_gruppo_id, gruppo.accredito_gruppo_code
               into codAccreRec
        from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
        where tipo.accredito_tipo_id=MDPRec.accredito_tipo_id
          and tipo.data_cancellazione is null
          and date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		  and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione))
          and gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id;
        if codAccreRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_d_accredito_tipo siac_d_accredito_gruppo.';
        end if;


        -- lettura dati soggetto ordinativo
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati soggetto [siac_r_soggetto_relaz] ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';
        select rel.soggetto_id_da into soggettoRifId
        from  siac_r_soggetto_relaz rel
        where rel.soggetto_id_a=mifOrdinativoIdRec.mif_ord_soggetto_id
        and   rel.relaz_tipo_id=ordSedeSecRelazTipoId
        and   rel.ente_proprietario_id=enteProprietarioId
        and   rel.data_cancellazione is null
		and   rel.validita_fine is null;

        if soggettoRifId is null then
	        soggettoRifId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        else
        	soggettoSedeSecId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        end if;

        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati soggetto di riferimento ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        select * into soggettoRec
   	    from siac_t_soggetto sogg
       	where sogg.soggetto_id=soggettoRifId;

        if soggettoRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id= %].',soggettoRifId;
        end if;

        if soggettoSedeSecId is not null then
	        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati sede sec. soggetto di riferimento ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

            select * into soggettoSedeRec
   		    from siac_t_soggetto sogg
	       	where sogg.soggetto_id=soggettoSedeSecId;

	        if soggettoSedeRec is null then
    	    	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id=%]',soggettoSedeSecId;
        	end if;

        end if;



        -- lettura elemento bilancio  ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura elemento bilancio ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

		select * into bilElemRec
        from siac_t_bil_elem elem
        where elem.elem_id=mifOrdinativoIdRec.mif_ord_elem_id;
        if bilElemRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_bil_elem.';
        end if;

		-- dati testata flusso presenti come tag solo in testata
        -- valorizzati su ogni ordinativo trasmesso
        -- <testata_flusso>
		-- <codice_ABI_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ABI_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_abi is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=enteOilRec.ente_oil_abi;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_ipa is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=trim(both ' ' from enteOilRec.ente_oil_codice_ipa);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <descrizione_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_DESC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.ente_denominazione is not null then
            	mifFlussoOrdinativoRec.mif_ord_desc_ente:=enteProprietarioRec.ente_denominazione;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_desc_ente:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

	    -- <codice_istat_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_istat is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=enteOilRec.ente_oil_codice_istat;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_fiscale_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.codice_fiscale is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=trim(both ' ' from enteProprietarioRec.codice_fiscale);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite_bt is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite_bt);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=trim(both ' ' from enteOilRec.ente_oil_codice);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <riferimento_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_riferimento is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=trim(both ' ' from enteOilRec.ente_oil_riferimento);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_flusso>

        -- <testata_esercizio>
        -- <esercizio>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_ESERCIZIO;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            mifFlussoOrdinativoRec.mif_ord_anno_esercizio:=mifOrdinativoIdRec.mif_ord_anno_bil;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_esercizio>

        mifCountRec:=FLUSSO_MIF_ELAB_INIZIO_ORD;
        mifCountTmpRec:=FLUSSO_MIF_ELAB_INIZIO_ORD;

        -- <mandato>
		-- <tipo_operazione>
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if  flussoElabMifElabRec.flussoElabMifAttivo=true then
         if   flussoElabMifElabRec.flussoElabMifElab=true then
            if flussoElabMifElabRec.flussoElabMifParam is not null then
	            flussoElabMifValore:=fnc_mif_ordinativo_carico_bollo( mifOrdinativoIdRec.mif_ord_codice_funzione,flussoElabMifElabRec.flussoElabMifParam);
            else
            	flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_codice_funzione;
            end if;
            if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_codice_funzione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <numero_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
/*         	if flussoElabMifTipoDec=false then
				mifFlussoOrdinativoRec.mif_ord_numero:=lpad(mifOrdinativoIdRec.mif_ord_ord_numero,NUM_SETTE,ZERO_PAD);
            else
	            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
            end if;*/
            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non elaborabile.';
         end if;
        end if;


        -- <data_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true  then
         if  flussoElabMifElabRec.flussoElabMifElab=true then
			mifFlussoOrdinativoRec.mif_ord_data:=mifOrdinativoIdRec.mif_ord_data_emissione;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non  elaborabile.';
         end if;
        end if;



		-- <importo_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			-- calcolato inizio ciclo
            null;
         else
         	mifFlussoOrdinativoRec.mif_ord_importo:='0';
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <conto_evidenza>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			if mifOrdinativoIdRec.mif_ord_contotes_id is not null then
                 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura conto tesoreria.';


            	select d.contotes_code into flussoElabMifValore
                from siac_d_contotesoreria d
                where d.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id;
                if flussoElabMifValore is null then
                	RAISE EXCEPTION ' Dato non presente in archivio.';
                end if;
            end if;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_bci_conto_tes:=substring(flussoElabMifValore from 1 for 7 );
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <estremi_provvedimento_autorizzativo>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        flussoElabMifValore:=null;
        attoAmmRec:=null;
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           if mifOrdinativoIdRec.mif_ord_atto_amm_id is not null then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
                if attoAmmTipoSpr is null then
            		attoAmmTipoSpr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if attoAmmTipoAll is null then
                	attoAmmTipoAll:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            	end if;
            end if;

            select * into attoAmmRec
            from fnc_mif_estremi_atto_amm(mifOrdinativoIdRec.mif_ord_atto_amm_id,
                                          mifOrdinativoIdRec.mif_ord_atto_amm_movg_id,
                                          attoAmmTipoSpr,attoAmmTipoAll,
                                          dataElaborazione,dataFineVal);
           end if;

           if attoAmmRec.attoAmmEstremi is not null   then
                mifFlussoOrdinativoRec.mif_ord_estremi_attoamm:=attoAmmRec.attoAmmEstremi;
           elseif flussoElabMifElabRec.flussoElabMifDef is not null then
           		mifFlussoOrdinativoRec.mif_ord_estremi_attoamm:=flussoElabMifElabRec.flussoElabMifDef;
           end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
       end if;


       -- <responsabile_provvedimento>
	   flussoElabMifElabRec:=null;
	   flussoElabMifValore:=null;
	   flussoElabMifValoreDesc:=null;
	   mifCountRec:=mifCountRec+1;
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then


         if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
         end if;

         if flussoElabMifValore is not null then
        	select substring(s.soggetto_desc  from 1 for 12)  into flussoElabMifValoreDesc
			from siac_t_account a, siac_r_soggetto_ruolo r, siac_t_soggetto s
			where a.ente_proprietario_id=enteProprietarioId
            and   a.account_code=flussoElabMifValore
			and   r.soggeto_ruolo_id=a.soggeto_ruolo_id
			and   s.soggetto_id=r.soggetto_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   a.data_cancellazione is null
            and   a.validita_fine is null;

            if 	flussoElabMifValoreDesc is not null then
            	flussoElabMifValore:=flussoElabMifValoreDesc;
            end if;
         end if;

         if flussoElabMifValore is not null then
            mifFlussoOrdinativoRec.mif_ord_resp_attoamm:=substring(flussoElabMifValore from 1 for 12);
         end if;
       else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
     end if;

     -- <ufficio_responsabile>
     mifCountRec:=mifCountRec+1;

     -- <bilancio>
     -- <codifica_bilancio>
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

                mifFlussoOrdinativoRec.mif_ord_codifica_bilancio:=mifOrdinativoIdRec.mif_ord_programma_code
                												||mifOrdinativoIdRec.mif_ord_titolo_code;

                mifFlussoOrdinativoRec.mif_ord_capitolo:=bilElemRec.elem_code;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	  -- <descrizione_codifica>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_desc_codifica:=substring( bilElemRec.elem_desc from 1 for 30);
                mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil:=substring( mifOrdinativoIdRec.mif_ord_programma_desc from 1 for 30);
     	 else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     	 end if;
      end if;

      -- <gestione>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifDef is not null then
            	if mifOrdinativoIdRec.mif_ord_anno_bil=mifOrdinativoIdRec.mif_ord_ord_anno_movg then
	            	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                else
	                flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                end if;
            	mifFlussoOrdinativoRec.mif_ord_gestione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <anno_residuo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

            if  mifOrdinativoIdRec.mif_ord_anno_bil!=mifOrdinativoIdRec.mif_ord_ord_anno_movg  then
               	   mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;


      -- <numero_articolo>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_articolo:=bilElemRec.elem_code2;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <voce_economica>
      mifCountRec:=mifCountRec+1;


      -- <importo_bilancio>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
           	mifFlussoOrdinativoRec.mif_ord_importo_bil:=mifFlussoOrdinativoRec.mif_ord_importo;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;

      -- </bilancio>

      -- <funzionario_delegato>
      -- <codice_funzionario_delegato>
      -- <importo_funzionario_delegato>
      -- <tipologia_funzionario_delegato>
      -- <numero_pagamento_funzionario_delegato>
      mifCountRec:=mifCountRec+5;

      -- <informazioni_beneficiario>

      -- <progressivo_beneficiario>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
--	  raise notice 'progressivo_beneficiario mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
                if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_benef:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;

      -- <importo_beneficiario>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
     		mifFlussoOrdinativoRec.mif_ord_importo_benef:=mifFlussoOrdinativoRec.mif_ord_importo;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;


	  -- <tipo_pagamento>
      flussoElabMifElabRec:=null;
      tipoPagamRec:=null;
	  mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
     	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	 	if flussoElabMifElabRec.flussoElabMifElab=true then
    	   	if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null then
            	if codicePaeseIT is null then
                	codicePaeseIT:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if codiceAccreCB is null then
	                codiceAccreCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
                if codiceAccreREG is null then
	                codiceAccreREG:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                end if;
				if codiceSepa is null then
	                codiceSepa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                end if;
				if codiceExtraSepa is null then
	                codiceExtraSepa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                end if;

                if codiceGFB is null then
	                codiceGFB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));
                end if;

                select * into tipoPagamRec
                from fnc_mif_tipo_pagamento_splus( mifOrdinativoIdRec.mif_ord_ord_id,
											       (case when MDPRec.iban is not null and length(MDPRec.iban)>=2
                                                   then substring(MDPRec.iban from 1 for 2)
                                                   else null end), -- codicePaese
	                                               codicePaeseIT,codiceSepa,codiceExtraSepa,
                                                   codiceAccreCB,codiceAccreREG,
                                                   flussoElabMifElabRec.flussoElabMifDef, -- compensazione
												   MDPRec.accredito_tipo_id,
                                                   codAccreRec.accredito_gruppo_code,
                                                   mifFlussoOrdinativoRec.mif_ord_importo::NUMERIC, -- importo_ordinativo
                                                   (case when codAccreRec.accredito_tipo_code=codiceGFB then true else false end),
	                                               dataElaborazione,dataFineVal,
                                                   enteProprietarioId);
                if tipoPagamRec is not null then
                	if tipoPagamRec.descTipoPagamento is not null then
                    	mifFlussoOrdinativoRec.mif_ord_pagam_tipo:=tipoPagamRec.descTipoPagamento;
                        mifFlussoOrdinativoRec.mif_ord_pagam_code:=tipoPagamRec.codeTipoPagamento;
                    end if;
                end if;

	        end if;
     	else
       		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
      end if;

      -- <impignorabili>
      mifCountRec:=mifCountRec+1;


      -- <frazionabile>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then --1
         if flussoElabMifElabRec.flussoElabMifElab=true then --2
          if flussoElabMifElabRec.flussoElabMifParam is not null and --3
             flussoElabMifElabRec.flussoElabMifDef is not null  then

             if dataAvvioFrazAttr is null then
             	dataAvvioFrazAttr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;

             if dataAvvioFrazAttr is not null and
                dataAvvioFrazAttr::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
                then
                bavvioFrazAttr:=true;
             end if;

             if bavvioFrazAttr=false then
              if classifTipoCodeFraz is null then
               classifTipoCodeFraz:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
              end if;

              if classifTipoCodeFrazVal is null then
               classifTipoCodeFrazVal:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
              end if;
             else
              if attrFrazionabile is null then
	             attrFrazionabile:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
              end if;
             end if;

             if  bavvioFrazAttr = false then
              if classifTipoCodeFraz is not null and
				 classifTipoCodeFrazVal is not null and
                 classifTipoCodeFrazId is null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classificatoreTipoId '||classifTipoCodeFraz||'.';
             	select tipo.classif_tipo_id into classifTipoCodeFrazId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=classifTipoCodeFraz
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null
                order by tipo.classif_tipo_id
                limit 1;
              end if;

              if classifTipoCodeFrazVal is not null and
                 classifTipoCodeFrazId is not null then
               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore classificatore '||classifTipoCodeFraz||' [siac_r_ordinativo_class].';
             	select c.classif_code into flussoElabMifValore
                from siac_r_ordinativo_class r, siac_t_class c
                where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                and   c.classif_id=r.classif_id
                and   c.classif_tipo_id=classifTipoCodeFrazId
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                and   c.data_cancellazione is null
                order by r.ord_classif_id
                limit 1;

              end if;

              if classifTipoCodeFrazVal is not null and
                flussoElabMifValore is not null and
                flussoElabMifValore=classifTipoCodeFrazVal then
             	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=flussoElabMifElabRec.flussoElabMifDef;
             end if;
			else
              if attrFrazionabile is not null then
               --- calcolo su attributo
               codResult:=null;
               select 1 into codResult
               from  siac_t_ordinativo_ts ts,siac_r_liquidazione_ord liqord,
                     siac_r_liquidazione_movgest rmov,
                     siac_r_movgest_ts_attr r, siac_t_attr attr
               where ts.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
               and   liqord.sord_id=ts.ord_ts_id
               and   rmov.liq_id=liqord.liq_id
               and   r.movgest_ts_id=rmov.movgest_ts_id
               and   attr.attr_id=r.attr_id
               and   attr.attr_code=attrFrazionabile
               and   r.boolean='N'
               and   r.data_cancellazione is null
               and   r.validita_fine is null
               and   rmov.data_cancellazione is null
               and   rmov.validita_fine is null
               and   liqord.data_cancellazione is null
               and   liqord.validita_fine is null
			   and   ts.data_cancellazione is null
               and   ts.validita_fine is null;

               if codResult is not null then
               	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=flussoElabMifElabRec.flussoElabMifDef;
               end if;

             end if;

            end if;

          end if; -- 3
      	 else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;  --- 2

        end if; -- 1

  	   -- <gestione_provvisoria>
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
        -- gestione_provvisoria da impostare solo se frazionabile=NO
       if mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz is not null then
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
          if flussoElabMifElabRec.flussoElabMifParam is not null and
             flussoElabMifElabRec.flussoElabMifDef is not null and
             mifOrdinativoIdRec.mif_ord_bil_fase_ope is not null  then

             if tipoEsercizio is null then
	             tipoEsercizio:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;
          	if tipoEsercizio=mifOrdinativoIdRec.mif_ord_bil_fase_ope  then
				mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov=flussoElabMifElabRec.flussoElabMifDef;
            end if;
		   end if;


         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;

        end if;
        --- frazionabile da impostare NO solo se gestione_provvisoria=SI
        if mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov is null then
        	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=null;
        end if;

      else
       	null;
      end if;

      -- <data_esecuzione_pagamento>
      flussoElabMifElabRec:=null;
      ordDataScadenza:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=flussoElabMifElabRec.flussoElabMifParam then
            	flussoElabMifElabRec.flussoElabMifElab:=false; -- se REGOLARIZZAZIONE data_esecuzione_pagamento non deve essere valorizzato
            end if;

            if flussoElabMifElabRec.flussoElabMifElab=true then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura data scadenza.';
        	 select sub.ord_ts_data_scadenza into ordDataScadenza
             from siac_t_ordinativo_ts sub
             where sub.ord_ts_id=mifOrdinativoIdRec.mif_ord_subord_id;

             if ordDataScadenza is not null and
--               date_trunc('DAY',ordDataScadenza)>= date_trunc('DAY',dataElaborazione) and
               date_trunc('DAY',ordDataScadenza)> date_trunc('DAY',dataElaborazione) and -- 13.12.2017 Sofia siac-5653
               extract('year' from ordDataScadenza)::integer<=annoBilancio::integer then
		  		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec:=
    		        extract('year' from ordDataScadenza)||'-'||
    	         	lpad(extract('month' from ordDataScadenza)::varchar,2,'0')||'-'||
            	 	lpad(extract('day' from ordDataScadenza)::varchar,2,'0');
             end if;
            end if;

	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;

      -- <data_scadenza_pagamento>
  	  mifCountRec:=mifCountRec+1;

	  -- <destinazione>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      codResult:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	   RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	   if flussoElabMifElabRec.flussoElabMifElab=true then

        if flussoElabMifElabRec.flussoElabMifParam is not null or
           flussoElabMifElabRec.flussoElabMifDef is not null then --1

           if flussoElabMifElabRec.flussoElabMifParam is not null then --2
		    if classVincolatoCode is null then
	        	classVincolatoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

            if classVincolatoCode is not null and classVincolatoCodeId is null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificativo classVincolatoCode='||classVincolatoCode||'.';

                select tipo.classif_tipo_id into classVincolatoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=classVincolatoCode;

            end if;

            if classVincolatoCodeId is not null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore per classVincolatoCode='||classVincolatoCode||'.';

                         select c.classif_desc into flussoElabMifValore
                         from siac_r_ordinativo_class r, siac_t_class c
                         where r.ord_id=  mifOrdinativoIdRec.mif_ord_ord_id
                         and   c.classif_id=r.classif_id
                         and   c.classif_tipo_id=classVincolatoCodeId
                         and   r.data_cancellazione is null
                         and   r.validita_fine is null
                         and   c.data_cancellazione is null;

            end if;
  	     end if; --2


         if flussoElabMifValore is null and --3
            mifOrdinativoIdRec.mif_ord_contotes_id is not null and
        	mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

		    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
    		                   ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
        		               ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
            		           ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                		       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                    		   ||' mifCountRec='||mifCountRec
	                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_vincolato].';

			select mif.vincolato into flussoElabMifValore
    	    from mif_r_conto_tesoreria_vincolato mif
	    	where mif.ente_proprietario_id=enteProprietarioId
    	    and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
	        and   mif.validita_fine is null
		    and   mif.data_cancellazione is null;


        end if; --3
 	    if flussoElabMifValore is null and
           flussoElabMifElabRec.flussoElabMifDef is not null then
           flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
        end if;

	    if flussoElabMifValore is not null then
        	mifFlussoOrdinativoRec.mif_ord_progr_dest:=flussoElabMifValore;
        end if;

       end if; --1
      else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
      end if;
     end if;


     -- <numero_conto_banca_italia_ente_ricevente>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     codResult:=null;
     if flussoElabMifElabRec.flussoElabMifId is null then
     	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            	-- non esposto se regolarizzazione (provvisori)
                if mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
-- 28.12.2017 Sofia SIAC-5665	   mifFlussoOrdinativoRec.mif_ord_pagam_tipo= trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2)) then
          		   ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                     trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                    or
                     mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                     trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
                    )  then -- 28.12.2017 Sofia SIAC-5665

                   flussoElabMifElabRec.flussoElabMifElab:=false;
                end if;

                if flussoElabMifElabRec.flussoElabMifElab=true then
	             if tipoMDPCbi is null then
                   	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
               	  end if;


                  if tipoMDPCbi is not null then
                  	if codAccreRec.accredito_gruppo_code=tipoMDPCbi then
                        	 mifFlussoOrdinativoRec.mif_ord_bci_conto:=MDPRec.contocorrente;
                    end if;
                  end if;
                 end if;


            end if;
       else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
     end if;


     -- <tipo_contabilita_ente_ricevente>
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     codResult:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
             if flussoElabMifElabRec.flussoElabMifDef is not null then

                if flussoElabMifElabRec.flussoElabMifParam is not null then
                   if tipoClassFruttifero is null then
                    	tipoClassFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                   end if;

                   if tipoClassFruttifero is not null and valFruttifero is null then
	                   valFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                       valFruttiferoStr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                       valFruttiferoStrAltro:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                   end if;

                   if tipoClassFruttifero is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      tipoClassFruttiferoId is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classifTipoCodeId '||tipoClassFruttifero||'.';
                   	select tipo.classif_tipo_id into tipoClassFruttiferoId
                    from siac_d_class_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.classif_tipo_code=tipoClassFruttifero
                    and   tipo.data_cancellazione is null
                    and   tipo.validita_fine is null;

                   end if;


                   if tipoClassFruttiferoId is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      valFruttiferoId is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classidId '||tipoClassFruttifero||' [siac_r_ordinativo_class].';


                   	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	                and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoClassFruttiferoId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   c.data_cancellazione is null
                    order by r.ord_classif_id limit 1;

                    if flussoElabMifValore is not null then
                    	if flussoElabMifValore=valFruttifero THEN
                        	flussoElabMifValore=valFruttiferoStr;
                        else
                          flussoElabMifValore=valFruttiferoStrAltro;
                        end if;
                    end if;

                  end if;

				end if; -- param

				if flussoElabMifValore is not null then
	                mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=flussoElabMifValore;
                end if;

               if mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil is null and
	              mifOrdinativoIdRec.mif_ord_contotes_id is not null and
    	          mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

               	  flussoElabMifValore:=null;
	              strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_fruttifero].';
	           	  select mif.fruttifero into flussoElabMifValore
	              from mif_r_conto_tesoreria_fruttifero mif
    	          where mif.ente_proprietario_id=enteProprietarioId
        	      and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
            	  and   mif.validita_fine is null
	              and   mif.data_cancellazione is null;

    	          if flussoElabMifValore is not null then
        	       	mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=flussoElabMifValore;
            	  end if;

              end if;

              if mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil is null then
                   	mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
              end if;
           end if; -- default
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <tipo_postalizzazione>
      flussoElabMifElabRec:=null;
      codResult:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifValore:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      raise notice 'tipo_postalizzazione mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
         if flussoElabMifElabRec.flussoElabMifParam is not null and
            flussoElabMifElabRec.flussoElabMifDef is not null then
           if tipoPagamPostA is null then
           	tipoPagamPostA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
           end if;

           if tipoPagamPostB is null then
           	tipoPagamPostB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
           end if;


           if tipoPagamPostA is not null or tipoPagamPostB is not null then
			  if tipoPagamRec is not null and tipoPagamRec.descTipoPagamento is not null then
              	if tipoPagamRec.descTipoPagamento in (tipoPagamPostA,tipoPagamPostB) then
	                mifFlussoOrdinativoRec.mif_ord_pagam_postalizza:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
              end if;
           end if;

         end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;


      -- <classificazione>
	  -- <codice_cgu>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      codiceCge:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      raise notice 'classificazione mifCountRec=%',mifCountRec;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then -- attivo
       if flussoElabMifElabRec.flussoElabMifElab=true then -- elab

        if flussoElabMifElabRec.flussoElabMifParam is not null then -- param

       	 if siopeCodeTipo is null and flussoElabMifElabRec.flussoElabMifParam is not null then
         	siopeCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
         end if;

         if siopeDef is null and flussoElabMifElabRec.flussoElabMifParam is not null then
         	siopeDef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)=NVL_STR and
            flussoElabMifElabRec.flussoElabMifParam is not null then
           	dataAvvioSiopeNew:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR and codiceFinVTbr is null then
       	 	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR then
       	  if dataAvvioSiopeNew::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
             then
              bAvvioSiopeNew:=true;
           end if;
         end if;

         if bAvvioSiopeNew=true then -- avvioSiopeNew
           if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
		  	-- codiceFinVTipoTbrId
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||codiceFinVTbr||'.';
			select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			from siac_d_class_tipo tipo
			where tipo.ente_proprietario_id=enteProprietarioId
			and   tipo.classif_tipo_code=codiceFinVTbr
			and   tipo.data_cancellazione is null
			and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
          end if;

          if codiceFinVTipoTbrId is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

            select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
		   	from siac_r_ordinativo_class r, siac_t_class class
			where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
		    and   class.classif_id=r.classif_id
		    and   class.classif_tipo_id=codiceFinVTipoTbrId
		    and   r.data_cancellazione is null
		    and   r.validita_fine is NULL
		    and   class.data_cancellazione is null;

          	if   flussoElabMifValore is null then
             strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

             select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
 		   	 from siac_r_liquidazione_class r, siac_t_class class
			 where r.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
		     and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null;
            end if;

          end if;
         else -- avvioSiopeNew
           strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||siopeCodeTipo||'.';

           if siopeCodeTipoId is null and siopeCodeTipo is not null then
           	select tipo.classif_tipo_id into siopeCodeTipoId
            from siac_d_class_tipo tipo
            where tipo.classif_tipo_code=siopeCodeTipo
            and   tipo.ente_proprietario_id=enteProprietarioId
            and   tipo.data_cancellazione is null
	 		and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
           end if;

           strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||siopeCodeTipo||'.';

           if siopeCodeTipoId is not null then
           	select class.classif_code, class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
            from siac_r_ordinativo_class cord, siac_t_class class
            where cord.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
            and cord.data_cancellazione is null
            and cord.validita_fine is null
            and class.classif_id=cord.classif_id
            and class.classif_code!=siopeDef
            and class.data_cancellazione is null
            and class.classif_tipo_id=siopeCodeTipoId;

            if flussoElabMifValore is null then
             select class.classif_code, class.classif_desc
                    into flussoElabMifValore,flussoElabMifValoreDesc
             from siac_r_liquidazione_class cord, siac_t_class class
             where cord.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
             and cord.data_cancellazione is null
             and cord.validita_fine is null
             and class.classif_id=cord.classif_id
             and class.classif_code!=siopeDef
             and class.data_cancellazione is null
             and class.classif_tipo_id=siopeCodeTipoId;
            end if;


           end if;
         end if; -- avvioSiopeNew


         if flussoElabMifValore is not null then
         	mifFlussoOrdinativoRec.mif_ord_class_codice_cge:=flussoElabMifValore;
            codiceCge:=flussoElabMifValore;
         end if;
        end if; -- param
       else -- elab
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if; -- elab
      end if; -- attivo

	  -- <codice_cup>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
            	if coalesce(cupAttrCode,NVL_STR)=NVL_STR then
                	cupAttrCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

                if coalesce(cupAttrCode,NVL_STR)!=NVL_STR and cupAttrId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cupAttrCode||'.';
                	select attr.attr_id into cupAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cupAttrCode
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;
                end if;

                if cupAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cupAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
                    	mifFlussoOrdinativoRec.mif_ord_class_codice_cup:=flussoElabMifValore;
                    end if;


                    if mifFlussoOrdinativoRec.mif_ord_class_codice_cup is null then
                    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cupAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;


                        if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
    	                	mifFlussoOrdinativoRec.mif_ord_class_codice_cup:=flussoElabMifValore;
	                    end if;
                    end if;
                end if;
            end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <codice_cpv>
      mifCountRec:=mifCountRec+1;

      -- <importo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
 	      	mifFlussoOrdinativoRec.mif_ord_class_importo:=mifFlussoOrdinativoRec.mif_ord_importo;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- </classificazione>

      -- <classificazione_dati_siope_uscite>
	  -- <tipo_debito_siope_c>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      isOrdCommerciale:=false;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        -- 21.12.2017 Sofia JIRA SIAC-5665
        if flussoElabMifElabRec.flussoElabMifParam is not null then
            flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            tipoDocsComm:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))||'|'||
                      trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))||'|'||
                      trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));

            isOrdCommerciale:=fnc_mif_ordinativo_esiste_documenti_splus( mifOrdinativoIdRec.mif_ord_ord_id,
                                                                         tipoDocsComm,
                                                   	                     enteProprietarioId
                                                                        );


/*        	if mifOrdinativoIdRec.mif_ord_siope_tipo_debito_id is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura tipo debito [siac_d_siope_tipo_debito].';
            	select tipo.siope_tipo_debito_desc_bnkit into flussoElabMifValore
                from siac_d_siope_tipo_debito tipo
                where tipo.siope_tipo_debito_id=mifOrdinativoIdRec.mif_ord_siope_tipo_debito_id;
            end if;

            if flussoElabMifValore is not null and
               upper(flussoElabMifValore)=flussoElabMifElabRec.flussoElabMifParam then
               mifFlussoOrdinativoRec.mif_ord_class_tipo_debito:=flussoElabMifElabRec.flussoElabMifParam;
               isOrdCommerciale:=true;
            end if;*/
            -- 21.12.2017 Sofia JIRA SIAC-5665
            if isOrdCommerciale=true then
            	mifFlussoOrdinativoRec.mif_ord_class_tipo_debito:=flussoElabMifValore;
            end if;
        end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

	  -- <tipo_debito_siope_nc>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      codResult:=null;
      if isOrdCommerciale=false then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
         if flussoElabMifElabRec.flussoElabMifDef is not null then
            -- 20.03.2018 Sofia SIAC-5968 - test sul pdcFin di OP per verificare se IVA
            if flussoElabMifElabRec.flussoElabMifParam is not null then
         	 if coalesce(tipoPdcIVA,'')='' then
	         	tipoPdcIVA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;
             if coalesce(codePdcIVA,'')='' then
	         	codePdcIVA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
             end if;

             if coalesce(tipoPdcIVA,'')!=''  and coalesce(codePdcIVA,'')!='' then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Verifica tipo debito IVA.';
             	select 1 into codResult
                from siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipo
                where rc.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                and   c.classif_id=rc.classif_id
                and   tipo.classif_tipo_id=c.classif_tipo_id
                and   tipo.classif_tipo_code=tipoPdcIVA
                and   c.classif_code like codePdcIVA||'%'
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null;

                if codResult is not null then
	               	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                end if;
             end if;

            end if;

            -- 21.12.2017 Sofia JIRA SIAC-5665
            --mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc:=flussoElabMifElabRec.flussoElabMifParam;

            -- 20.03.2018 Sofia SIAC-5968
            if flussoElabMifValore is null then
            	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
            end if;
            -- 20.03.2018 Sofia SIAC-5968
			mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc:=flussoElabMifValore;

         end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;




      -- <codice_cig_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      raise notice 'codice_cig_siope mifCountRec=%',mifCountRec;
      -- solo per COMMERCIALI
	  if isOrdCommerciale=true then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;

       if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
            	if coalesce(cigAttrCode,NVL_STR)=NVL_STR then
                	cigAttrCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

                if coalesce(cigAttrCode,NVL_STR)!=NVL_STR and cigAttrCodeId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cigAttrCode||'.';
                	select attr.attr_id into cigAttrCodeId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cigAttrCode
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;
                end if;

                if cigAttrCodeId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cigAttrCodeId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
                    	mifFlussoOrdinativoRec.mif_ord_class_cig:=flussoElabMifValore;
                    end if;


                    if mifFlussoOrdinativoRec.mif_ord_class_cig is null then
                    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigAttrCode||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cigAttrCodeId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;


                        if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
    	                	mifFlussoOrdinativoRec.mif_ord_class_cig:=flussoElabMifValore;
	                    end if;
                    end if;
                end if;
            end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;

      -- <motivo_esclusione_cig_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      -- solo per COMMERCIALI
      if isOrdCommerciale=true and
         mifFlussoOrdinativoRec.mif_ord_class_cig is null then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;

	   if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
       	  if mifOrdinativoIdRec.mif_ord_siope_assenza_motivazione_id is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura motivazione [siac_d_siope_assenza_motivazione].';
            raise notice 'siope_assenza_motivazione_desc_bnkit';
		  	select upper(ass.siope_assenza_motivazione_desc_bnkit) into flussoElabMifValore
			from siac_d_siope_assenza_motivazione ass
			where ass.siope_assenza_motivazione_id=mifOrdinativoIdRec.mif_ord_siope_assenza_motivazione_id;
          end if;
		  if flussoElabMifValore is not null then
	    	  mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig:=flussoElabMifValore;
              raise notice 'siope_assenza_motivazione_desc_bnkit=%',mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig;

          end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;

      raise notice 'motivo_esclusione_cig_siope mifCountRec=%',mifCountRec;

      -- <fatture_siope>
      -- </fatture_siope>
      mifCountRec:=mifCountRec+12;

      -- <dati_ARCONET_siope>


      -- <codice_missione_siope>
	  flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
    	  mifFlussoOrdinativoRec.mif_ord_class_missione:=SUBSTRING(mifOrdinativoIdRec.mif_ord_programma_code from 1 for 2);
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      raise notice 'codice_missione_siope mifCountRec=%',mifCountRec;

      -- <codice_programma_siope>
	  flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
    	  mifFlussoOrdinativoRec.mif_ord_class_programma:=mifOrdinativoIdRec.mif_ord_programma_code;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <codice_economico_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
                              raise notice 'codice_economico_siope mifCountRec=%',mifCountRec;

      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        if flussoElabMifElabRec.flussoElabMifParam is not null then

          if codiceFinVTbr is null then
				codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
          end if;

		  if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
		  	-- codiceFinVTipoTbrId
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||codiceFinVTbr||'.';
			select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			from siac_d_class_tipo tipo
			where tipo.ente_proprietario_id=enteProprietarioId
			and   tipo.classif_tipo_code=codiceFinVTbr
			and   tipo.data_cancellazione is null
			and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
          end if;

          if codiceFinVTipoTbrId is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

            select class.classif_code  into flussoElabMifValore
		   	from siac_r_ordinativo_class r, siac_t_class class
			where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
		    and   class.classif_id=r.classif_id
		    and   class.classif_tipo_id=codiceFinVTipoTbrId
		    and   r.data_cancellazione is null
		    and   r.validita_fine is NULL
		    and   class.data_cancellazione is null;

          	if   flussoElabMifValore is null then
             strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

             select class.classif_code  into flussoElabMifValore
 		   	 from siac_r_liquidazione_class r, siac_t_class class
			 where r.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
		     and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null;
            end if;
          end if;
/*
       	  if collEventoCodeId is null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura tipo coll. evento '||flussoElabMifElabRec.flussoElabMifParam||'.';


            select coll.collegamento_tipo_id into collEventoCodeId
            from siac_d_collegamento_tipo coll
            where coll.ente_proprietario_id=enteProprietarioId
            and   coll.collegamento_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))
            and   coll.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',coll.validita_inizio)
		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(coll.validita_fine,dataElaborazione));

         end if;

	     if collEventoCodeId is not null then
		  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura conto economico patrimoniale.';
                             raise notice 'QUI QUI strMessaggio=%',strMessaggio;

          select conto.pdce_conto_code into flussoElabMifValore
          from siac_t_pdce_conto conto, siac_t_reg_movfin regMovFin, siac_r_evento_reg_movfin rEvento,
               siac_d_evento evento,
               siac_t_mov_ep reg, siac_r_reg_movfin_stato regstato, siac_d_reg_movfin_stato stato,
               siac_t_prima_nota pn, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnstato,
               siac_t_mov_ep_det det
          where evento.ente_proprietario_id=enteProprietarioId
          and   evento.collegamento_tipo_id=collEventoCodeId -- OP
          and   rEvento.evento_id=evento.evento_id
          and   rEvento.campo_pk_id=mifOrdinativoIdRec.mif_ord_ord_id
          and   regMovFin.regmovfin_id=rEvento.regmovfin_id
--          and   regMovFin.ambito_id=ambitoFinId  -- AMBITO_FIN togliamo ambito
          and   regstato.regmovfin_id=regMovFin.regmovfin_id
          and   stato.regmovfin_stato_id=regstato.regmovfin_stato_id
          and   stato.regmovfin_stato_code!=REGMOVFIN_STATO_A
          and   reg.regmovfin_id=regMovFin.regmovfin_id
          and   pn.pnota_id=reg.regep_id
          and   rpnota.pnota_id=pn.pnota_id
          and   pnstato.pnota_stato_id=rpnota.pnota_stato_id
          and   pnstato.pnota_stato_code!=REGMOVFIN_STATO_A  -- forse sarebbe meglio prendere solo i D
          and   det.movep_id=reg.movep_id
          and   det.movep_det_segno=SEGNO_ECONOMICO -- Dare
		  and   conto.pdce_conto_id=det.pdce_conto_id
          and   regMovFin.data_cancellazione is null
          and   regMovFin.validita_fine is null
          and   rEvento.data_cancellazione is null
          and   rEvento.validita_fine is null
          and   evento.data_cancellazione is null
          and   evento.validita_fine is null
          and   reg.data_cancellazione is null
          and   reg.validita_fine is null
          and   regstato.data_cancellazione is null
          and   regstato.validita_fine is null
          and   pn.data_cancellazione is null
          and   pn.validita_fine is null
          and   rpnota.data_cancellazione is null
          and   rpnota.validita_fine is null
          and   conto.data_cancellazione is null
          and   conto.validita_fine is null
          order by pn.pnota_id desc
          limit 1;
         end if;
*/
       end if;


        if flussoElabMifValore is not null then
	        mifFlussoOrdinativoRec.mif_ord_class_economico:=flussoElabMifValore;
        end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

	  -- <importo_codice_economico_siope>
	  mifCountRec:=mifCountRec+1;
      if mifFlussoOrdinativoRec.mif_ord_class_economico is not null then
      	flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

	    if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         		mifFlussoOrdinativoRec.mif_ord_class_importo_economico:=mifFlussoOrdinativoRec.mif_ord_importo;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
      end if;

      -- <codice_UE_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
            raise notice 'codice_UE_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if codiceUECodeTipo is null then
				codiceUECodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if codiceUECodeTipo is not null and codiceUECodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into codiceUECodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=codiceUECodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if codiceUECodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                             raise notice 'QUI QUI codiceUECodeTipo=% strMessaggio=%',codiceUECodeTipo,strMessaggio;

        	 select class.classif_code into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=codiceUECodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;

                             raise notice '222QUI QUI codiceUECodeTipo=% strMessaggio=%',codiceUECodeTipo,strMessaggio;

             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select class.classif_code into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=codiceUECodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
                raise notice 'QUI QUI flussoElabMifValore=%',flussoElabMifValore;
            	mifFlussoOrdinativoRec.mif_ord_class_transaz_ue:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;

      -- <codice_uscita_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
                  raise notice 'codice_uscita_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if ricorrenteCodeTipo is null then
				ricorrenteCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if ricorrenteCodeTipo is not null and ricorrenteCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into ricorrenteCodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=ricorrenteCodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if ricorrenteCodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

        	 select upper(class.classif_desc) into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=ricorrenteCodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;


             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select upper(class.classif_desc) into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=ricorrenteCodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
            	mifFlussoOrdinativoRec.mif_ord_class_ricorrente_spesa:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;


      -- <codice_cofog_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
                        raise notice 'codice_cofog_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if codiceCofogCodeTipo is null then
				codiceCofogCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if codiceCofogCodeTipo is not null and codiceCofogCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into codiceCofogCodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=codiceCofogCodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if codiceCofogCodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

        	 select class.classif_code into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=codiceCofogCodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;


             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select class.classif_code into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=codiceCofogCodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
            	mifFlussoOrdinativoRec.mif_ord_class_cofog_codice:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;

      -- <importo_cofog_siope>
  	  mifCountRec:=mifCountRec+1;
      if mifFlussoOrdinativoRec.mif_ord_class_cofog_codice is not null then
       flussoElabMifElabRec:=null;
	   flussoElabMifValore:=null;
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
	     if flussoElabMifElabRec.flussoElabMifElab=true then
        		mifFlussoOrdinativoRec.mif_ord_class_cofog_importo:=mifFlussoOrdinativoRec.mif_ord_importo;

         else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		 end if;
	    end if;
       end if;

      -- </dati_ARCONET_siope>

      -- </classificazione_dati_siope_uscite>

      -- <bollo>
      -- <assoggettamento_bollo>
   	  mifCountRec:=mifCountRec+1;
      ordCodiceBolloDesc:=null;
      codiceBolloPlusDesc:=null;
      codiceBolloPlusEsente:=false;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if mifOrdinativoIdRec.mif_ord_codbollo_id is not null then


	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then

          	if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo in
                 (trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)), -- REGOLARIZZAZIONE
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))  -- F24EP
                 ) then

               codiceBolloPlusEsente:=true;
               -- REGOLARIZZAZIONE
               if mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) then
                  mifFlussoOrdinativoRec.mif_ord_bollo_carico:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               	  mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
               end if;
               -- F24EP
               if mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2)) then
                  mifFlussoOrdinativoRec.mif_ord_bollo_carico:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               	  mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               end if;
            end if;

            if mifFlussoOrdinativoRec.mif_ord_bollo_carico is null then
          	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice bollo.';

             select bollo.codbollo_desc , plus.codbollo_plus_desc, plus.codbollo_plus_esente
                   into ordCodiceBolloDesc, codiceBolloPlusDesc, codiceBolloPlusEsente
             from siac_d_codicebollo bollo, siac_d_codicebollo_plus plus, siac_r_codicebollo_plus rp
             where bollo.codbollo_id=mifOrdinativoIdRec.mif_ord_codbollo_id
             and   rp.codbollo_id=bollo.codbollo_id
             and   plus.codbollo_plus_id=rp.codbollo_plus_id
             and   rp.data_cancellazione is null
             and   rp.validita_fine is null;

             if coalesce(codiceBolloPlusDesc,NVL_STR)!=NVL_STR  then
            	mifFlussoOrdinativoRec.mif_ord_bollo_carico:=codiceBolloPlusDesc;
             end if;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
       end if;

      -- <causale_esenzione_bollo>
   	  mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      if codiceBolloPlusEsente=true and coalesce(ordCodiceBolloDesc,NVL_STR)!=NVL_STR then
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
            if mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione is null then
	          	mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=substring(ordCodiceBolloDesc from 1 for 30);
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
      -- </bollo>

	  -- <spese>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      ordCodiceBolloDesc:=null;
      codiceBolloPlusDesc:=null;
      codiceBolloPlusEsente:=false;
      -- <soggetto_destinatario_delle_spese>
      if mifOrdinativoIdRec.mif_ord_comm_tipo_id is not null then
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice commissione.';

            select tipo.comm_tipo_desc , plus.comm_tipo_plus_desc, plus.comm_tipo_plus_esente
                   into ordCodiceBolloDesc, codiceBolloPlusDesc, codiceBolloPlusEsente
            from siac_d_commissione_tipo tipo, siac_d_commissione_tipo_plus plus, siac_r_commissione_tipo_plus rp
            where tipo.comm_tipo_id=mifOrdinativoIdRec.mif_ord_comm_tipo_id
            and   rp.comm_tipo_id=tipo.comm_tipo_id
            and   plus.comm_tipo_plus_id=rp.comm_tipo_plus_id
            and   rp.data_cancellazione is null
            and   rp.validita_fine is null;

            if coalesce(codiceBolloPlusDesc,NVL_STR)!=NVL_STR  then
            	mifFlussoOrdinativoRec.mif_ord_commissioni_carico:=codiceBolloPlusDesc;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
      -- <natura_pagamento>
      mifCountRec:=mifCountRec+1;

      -- <causale_esenzione_spese>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if codiceBolloPlusEsente=true and mifFlussoOrdinativoRec.mif_ord_commissioni_carico is not null then
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	   end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
          	mifFlussoOrdinativoRec.mif_ord_commissioni_esenzione:=ordCodiceBolloDesc;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
       end if;
      end if;
      -- </spese>

	  -- <beneficiario>
      mifCountRec:=mifCountRec+1;
      -- <anagrafica_beneficiario>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      anagraficaBenefCBI:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
--       raise notice 'beneficiario mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if soggettoSedeSecId is not null then
            	flussoElabMifValore:=soggettoRec.soggetto_desc||' '||soggettoSedeRec.soggetto_desc;
            else
            	flussoElabMifValore:=soggettoRec.soggetto_desc;
            end if;

            /*if flussoElabMifElabRec.flussoElabMifParam is not null and tipoMDPCbi is null then
	           	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if; */

            -- se non e girofondo o se lo e ma il contocorrente_intestazione e vuoto
            -- valorizzo i tag di anagrafica_beneficiario
            -- altrimenti solo anagrafica_beneficiario=contocorrente_intestazione
            -- e anagrafica_beneficiario in dati_a_disposizione_ente
            /*if codAccreRec.accredito_gruppo_code!=tipoMDPCbi or
			   (codAccreRec.accredito_gruppo_code=tipoMDPCbi and
                 (MDPRec.contocorrente_intestazione is null or MDPRec.contocorrente_intestazione='')) then
	           	mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);
            else
	            	anagraficaBenefCBI:=flussoElabMifValore;
	                mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(MDPRec.contocorrente_intestazione from 1 for 140);
            end if;*/

            mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);

       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
     end if;



	 -- <indirizzo_beneficiario>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' indirizzo_benef mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        	if soggettoSedeSecId is not null then
                select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoSedeSecId
                and   indir.data_cancellazione is null
                and   indir.validita_fine is null;

            else
            	select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoRifId
                and   indir.principale='S'
                and   indir.data_cancellazione is null
         	    and   indir.validita_fine is null;

            end if;

            if indirizzoRec is null then
            	-- RAISE EXCEPTION ' Errore in lettura indirizzo soggetto [siac_t_indirizzo_soggetto].';
                isIndirizzoBenef:=false;
            end if;

            if isIndirizzoBenef=true then

             if indirizzoRec.via_tipo_id is not null then
            	select tipo.via_tipo_code into flussoElabMifValore
                from siac_d_via_tipo tipo
                where tipo.via_tipo_id=indirizzoRec.via_tipo_id
                and   tipo.data_cancellazione is null
         	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
                if flussoElabMifValore is not null then
                	flussoElabMifValore:=flussoElabMifValore||' ';
                end if;
             end if;

             flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
                                 ||' '||coalesce(indirizzoRec.numero_civico,''));

             if flussoElabMifValore is not null and anagraficaBenefCBI is null then
	            mifFlussoOrdinativoRec.mif_ord_indir_benef:=substring(flussoElabMifValore from 1 for 30);
             end if;
           end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

   	  -- <cap_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then
        if indirizzoRec.zip_code is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
	            mifFlussoOrdinativoRec.mif_ord_cap_benef:=lpad(indirizzoRec.zip_code,5,'0');
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
	  end if;

      -- <localita_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then

        if indirizzoRec.comune_id is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select com.comune_desc into flussoElabMifValore
            from siac_t_comune com
            where com.comune_id=indirizzoRec.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_localita_benef:=substring(flussoElabMifValore from 1 for 30);
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
      end if;


	  -- <provincia_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then

        if indirizzoRec.comune_id is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select prov.sigla_automobilistica into flussoElabMifValore
            from siac_r_comune_provincia provRel, siac_t_provincia prov
            where provRel.comune_id=indirizzoRec.comune_id
            and   provRel.data_cancellazione is null
            and   provRel.validita_fine is null
            and   prov.provincia_id=provRel.provincia_id
            and   prov.data_cancellazione is null
            and   prov.validita_fine is null
            order by provRel.data_creazione;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_prov_benef:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
      end if;

      -- <stato_beneficiario>
      mifCountRec:=mifCountRec+1; -- popolare in seguito ricavato il codice_paese di piazzatura
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
          if anagraficaBenefCBI is null and
             statoBeneficiario=false then
	            statoBeneficiario:=true;
           end if;
         else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	  -- <partita_iva_beneficiario>
      mifCountRec:=mifCountRec+1;
      if ( anagraficaBenefCBI is null and
            (soggettoRec.partita_iva is not null or
            (soggettoRec.partita_iva is null and soggettoRec.codice_fiscale is not null and length(soggettoRec.codice_fiscale)=11))
          )   then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	    if soggettoRec.partita_iva is not null then
		            mifFlussoOrdinativoRec.mif_ord_partiva_benef:=soggettoRec.partita_iva;
                else
                    if length(trim ( both ' ' from soggettoRec.codice_fiscale))=11 then
                        mifFlussoOrdinativoRec.mif_ord_partiva_benef:=trim ( both ' ' from soggettoRec.codice_fiscale);
                    end if;
                end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
      end if;

       -- <codice_fiscale_beneficiario>
      mifCountRec:=mifCountRec+1;
--      if mifFlussoOrdinativoRec.mif_ord_partiva_benef is null and anagraficaBenefCBI is null then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
            -- se CASSA codice_fiscale obbligatorio
          	if flussoElabMifElabRec.flussoElabMifParam is not null then
		            if tipoMDPCo is null then
                    	tipoMDPCo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;

                    if tipoMDPCo is not null and
                       tipoMDPCo=codAccreRec.accredito_gruppo_code then
                       if soggettoRec.codice_fiscale is not null then
                    	flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
                       else
	                    if mifFlussoOrdinativoRec.mif_ord_partiva_benef is not null then
     	                   flussoElabMifValore:=mifFlussoOrdinativoRec.mif_ord_partiva_benef;
                        end if;
                       end if;
                    end if;
            end if;

            -- se non CASSA valorizzato se partita iva non presente e  codice_fiscale=16
            if flussoElabMifValore is null and
               mifFlussoOrdinativoRec.mif_ord_partiva_benef is null and
               soggettoRec.codice_fiscale is not null and
               length(soggettoRec.codice_fiscale)=16 then
               flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
            end if;

            if flussoElabMifValore is not null then
		             mifFlussoOrdinativoRec.mif_ord_codfisc_benef:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
--        end if;
      -- </beneficiario>


      -- <delegato>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      isMDPCo:=false;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
                    if tipoMDPCo is null then
                    	tipoMDPCo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;

                    if tipoMDPCo is not null and
                       tipoMDPCo=codAccreRec.accredito_gruppo_code then
                    	isMDPCo:=true;
                    end if;

					if isMDPCo=true and -- non esporre se REGOLARIZZAZIONE ( provvisori di cassa )
                       mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
            		   ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                         or
                         mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
                       )  then -- 20.12.2017 Sofia Jira SIAC-5665
			             isMDPCo=false;
			        end if;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <anagrafica_delegato>
      mifCountRec:=mifCountRec+1;
      if isMDPCo=true and MDPRec.quietanziante is not null then
        	flussoElabMifElabRec:=null;
      		flussoElabMifValore:=null;

     	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
		    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        	if flussoElabMifElabRec.flussoElabMifId is null then
	            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	    end if;
            if flussoElabMifElabRec.flussoElabMifAttivo=true then
         		if flussoElabMifElabRec.flussoElabMifElab=true then
                   	mifFlussoOrdinativoRec.mif_ord_anag_quiet:=MDPRec.quietanziante;
           		else
           			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		         end if;
	        end if;
      end if;

      mifCountRec:=mifCountRec+7;
--      raise notice 'codfisc_quiet mifCountRec=%',mifCountRec;
      -- <codice_fiscale_delegato>
      if isMDPCo=true and mifFlussoOrdinativoRec.mif_ord_anag_quiet is not null and
         MDPRec.quietanziante_codice_fiscale is not null  and
         length(MDPRec.quietanziante_codice_fiscale)=16   then
             flussoElabMifElabRec:=null;
      		 flussoElabMifValore:=null;
             flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 72
		     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        	 if flussoElabMifElabRec.flussoElabMifId is null then
	            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	     end if;
             if flussoElabMifElabRec.flussoElabMifAttivo=true then
         		if flussoElabMifElabRec.flussoElabMifElab=true then
                   	flussoElabMifValore:=trim ( both ' ' from MDPRec.quietanziante_codice_fiscale);

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_codfisc_quiet:=flussoElabMifValore;
                    end if;

           		else
           			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		        end if;
	         end if;
      end if;
      -- </delegato>

	  -- <creditore_effettivo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      soggettoQuietRec:=null;
      soggettoQuietRifRec:=null;
      soggettoQuietId:=null;
      soggettoQuietRifId:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

	      /* -- 20.04.2018 Sofia JIRA SIAC-6097
          if flussoElabMifElabRec.flussoElabMifParam is not null and
             mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
             ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
               or
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4))
               or -- 13.04.2018 Sofia JIRA SIAC-6097
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5))
               or
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6))
                 -- 13.04.2018 Sofia JIRA SIAC-6097
               or
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,7))
                 -- 19.04.2018 Sofia JIRA SIAC-6097
             )   then -- 20.12.2017 Sofia JIRA siac-5665

          end if;*/


          -- 20.04.2018 Sofia JIRA SIAC-6097
          if flussoElabMifElabRec.flussoElabMifParam is not null and
           mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null  then

           flussoElabMifValore:= regexp_replace(flussoElabMifElabRec.flussoElabMifParam,
                                                trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))||'.'||
                                                trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))||'.',
							                    '');
 		   if  fnc_mif_ordinativo_esenzione_bollo(mifFlussoOrdinativoRec.mif_ord_pagam_tipo,flussoElabMifValore)=true  then
	           flussoElabMifElabRec.flussoElabMifElab=false;
               flussoElabMifValore:=null;
           end if;
          end if;

          if flussoElabMifElabRec.flussoElabMifElab=true then -- non esporre su regolarizzazione (provvisori)
           if  ordCsiRelazTipoId is null then
            if ordCsiRelazTipo is null then
            	if flussoElabMifElabRec.flussoElabMifParam is not null then
	                ordCsiRelazTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    ordCsiCOTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
            end if;

            if ordCsiRelazTipo is  not null then
                select tipo.oil_relaz_tipo_id into ordCsiRelazTipoId
               	from siac_d_oil_relaz_tipo tipo
	            where tipo.ente_proprietario_id=enteProprietarioId
    	          and tipo.oil_relaz_tipo_code=ordCsiRelazTipo
        	      and tipo.data_cancellazione is null
                  and tipo.validita_fine is null;
            end if;
           end if;

           if ordCsiRelazTipoId is not null and
              ( ordCsiCOTipo is null or ordCsiCOTipo!=codAccreRec.accredito_gruppo_code ) then

                soggettoQuietId:=MDPRec.soggetto_id;

                select sogg.*
                       into  soggettoQuietRec
                from siac_t_soggetto sogg, siac_r_soggrel_modpag relmdp,siac_r_soggetto_relaz relsogg,
                     siac_r_oil_relaz_tipo roil
                where sogg.soggetto_id=MDPRec.soggetto_id
                and   sogg.data_cancellazione is null
                and   sogg.validita_fine is null
                and   relmdp.modpag_id=MDPRec.modpag_id
                and   relmdp.data_cancellazione is null
                -- and   relmdp.validita_fine is null 04.04.2018 Sofia SIAC-6064
                -- 04.04.2018 Sofia SIAC-6064
			    and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(relmdp.validita_fine,dataElaborazione))
    			and   relmdp.soggetto_relaz_id=relsogg.soggetto_relaz_id
                and   relsogg.soggetto_id_a=MDPRec.soggetto_id
                and   relsogg.soggetto_id_da=soggettoRifId
                and   roil.relaz_tipo_id=relsogg.relaz_tipo_id
                and   roil.oil_relaz_tipo_id=ordCsiRelazTipoId
                and   relsogg.data_cancellazione is null
                and   relsogg.validita_fine is null
                and   roil.data_cancellazione is null
                and   roil.validita_fine is null;

				if soggettoQuietRec is null then
                	soggettoQuietId:=null;
                end if;

               if soggettoQuietId is not null then
                 select sogg.*
                        into soggettoQuietRifRec
		         from  siac_t_soggetto sogg, siac_r_soggetto_relaz rel
		         where rel.soggetto_id_a=soggettoQuietRec.soggetto_id
		         and   rel.relaz_tipo_id=ordSedeSecRelazTipoId
		         and   rel.ente_proprietario_id=enteProprietarioId
		         and   rel.data_cancellazione is null
                 and   rel.validita_fine is null
                 and   sogg.soggetto_id=rel.soggetto_id_da
		         and   sogg.data_cancellazione is null
                 and   sogg.validita_fine is null;


                 if soggettoQuietRifRec is null then

                 else
                 	soggettoQuietRifId:=soggettoQuietRifRec.soggetto_id;
                 end if;
               end if;
            end if;
          end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      mifCountRec:=mifCountRec+1;
  	  -- <anagrafica_creditore_effettivo>
      if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --63
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
	            if soggettoQuietRifId is not null then
    	        	flussoElabMifValore:=soggettoQuietRifRec.soggetto_desc||' '||soggettoQuietRec.soggetto_desc;
        	    else
            		flussoElabMifValore:=soggettoQuietRec.soggetto_desc;
	            end if;

                if flussoElabMifValore is not null then
--                	mifFlussoOrdinativoRec.mif_ord_anag_del:=substring(flussoElabMifValore from 1 for 140);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in creditore_effettivo -- anagrafica_beneficiario
                    mifFlussoOrdinativoRec.mif_ord_anag_del:=mifFlussoOrdinativoRec.mif_ord_anag_benef;
                    mifFlussoOrdinativoRec.mif_ord_indir_del:=mifFlussoOrdinativoRec.mif_ord_indir_benef;
                    mifFlussoOrdinativoRec.mif_ord_cap_del:=mifFlussoOrdinativoRec.mif_ord_cap_benef;
                    mifFlussoOrdinativoRec.mif_ord_localita_del:=mifFlussoOrdinativoRec.mif_ord_localita_benef;
                    mifFlussoOrdinativoRec.mif_ord_prov_del:=mifFlussoOrdinativoRec.mif_ord_prov_benef;
                    mifFlussoOrdinativoRec.mif_ord_partiva_del:=mifFlussoOrdinativoRec.mif_ord_partiva_benef;
                    mifFlussoOrdinativoRec.mif_ord_codfisc_del:=mifFlussoOrdinativoRec.mif_ord_codfisc_benef;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
	  end if;

      mifCountRec:=mifCountRec+1;
      -- <indirizzo_creditore_effettivo>
      if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         indirizzoRec:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

                select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoQuietId
                and   (case when soggettoQuietRifId is null
                            then indir.principale='S' else coalesce(indir.principale,'N')='N' end)
                and   indir.data_cancellazione is null
                and   indir.validita_fine is null;

                if indirizzoRec is null then
                    isIndirizzoBenQuiet:=false;
            	end if;

			    if isIndirizzoBenQuiet=true then

            	 if indirizzoRec.via_tipo_id is not null then
            		select tipo.via_tipo_code into flussoElabMifValore
                	from siac_d_via_tipo tipo
               		where tipo.via_tipo_id=indirizzoRec.via_tipo_id
	                and   tipo.data_cancellazione is null
    	     	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 			 		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                	if flussoElabMifValore is not null then
                		flussoElabMifValore:=flussoElabMifValore||' ';
               	    end if;

           		  end if;

	             flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
    	                             ||' '||coalesce(indirizzoRec.numero_civico,''));

        	     if flussoElabMifValore is not null then
--	        	    mifFlussoOrdinativoRec.mif_ord_indir_del:=substring(flussoElabMifValore from 1 for 30);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_indir_benef:=substring(flussoElabMifValore from 1 for 30);
	             end if;
                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

	 -- <cap_creditore_effettivo>
     mifCountRec:=mifCountRec+1;
     if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
--         		mifFlussoOrdinativoRec.mif_ord_cap_del:=lpad(indirizzoRec.zip_code,5,'0');

				-- 24.01.2018 Sofia jira siac-5765 - scambio tag
                -- in anagrafica_beneficiario -- creditore_effettivo
                mifFlussoOrdinativoRec.mif_ord_cap_benef:=lpad(indirizzoRec.zip_code,5,'0');
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;

         end if;
        end if;
     end if;


     -- <localita_creditore_effettivo>
     mifCountRec:=mifCountRec+1;
     if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

            	select com.comune_desc into flussoElabMifValore
           		from siac_t_comune com
	            where com.comune_id=indirizzoRec.comune_id
    	        and   com.data_cancellazione is null
                and   com.validita_fine is null;

	            if flussoElabMifValore is not null then
--		            mifFlussoOrdinativoRec.mif_ord_localita_del:=substring(flussoElabMifValore from 1 for 30);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_localita_benef:=substring(flussoElabMifValore from 1 for 30);
        	    end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
        end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <provincia_creditore_effettivo>
	 if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

            	select prov.sigla_automobilistica into flussoElabMifValore
            	from siac_r_comune_provincia provRel, siac_t_provincia prov
           		where provRel.comune_id=indirizzoRec.comune_id
           	  	and   provRel.data_cancellazione is null
                and   provRel.validita_fine is null
        	    and   prov.provincia_id=provRel.provincia_id
            	and   prov.data_cancellazione is null
                and   prov.validita_fine is null
        	    order by provRel.data_creazione;

	            if flussoElabMifValore is not null then
--		            mifFlussoOrdinativoRec.mif_ord_prov_del:=flussoElabMifValore;
                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_prov_benef:=flussoElabMifValore;
        	    end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
        end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <stato_creditore_effettivo>
     if soggettoQuietId is not null  then
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
         	if statoDelegatoCredEff=false then
	            statoDelegatoCredEff:=true;
                -- valorizzato poi in piazzatura
            end if;
          else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
       end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <partita_iva_creditore_effettivo>
     if soggettoQuietId is not null THEN
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
                if  soggettoQuietRifId is not null then
	            	if soggettoQuietRifRec.partita_iva is not null  or
                       (soggettoQuietRifRec.partita_iva is null and
                        soggettoQuietRifRec.codice_fiscale is not null and length(soggettoQuietRifRec.codice_fiscale)=11)
                       then
                       	if soggettoQuietRifRec.partita_iva is not null then
	    	             flussoElabMifValore:=soggettoQuietRifRec.partita_iva;
                        else
                         flussoElabMifValore:=trim ( both ' ' from soggettoQuietRifRec.codice_fiscale);
                        end if;
                     end if;
				else
                	if soggettoQuietRec.partita_iva is not null  or
                       (soggettoQuietRec.partita_iva is null and
                        soggettoQuietRec.codice_fiscale is not null and length(soggettoQuietRec.codice_fiscale)=11)
                       then
                       	if soggettoQuietRec.partita_iva is not null then
	    	             flussoElabMifValore:=soggettoQuietRec.partita_iva;
                        else
                         flussoElabMifValore:=trim ( both ' ' from soggettoQuietRec.codice_fiscale);
                        end if;
                    end if;
                end if;

			    if flussoElabMifValore is not null then
--	                mifFlussoOrdinativoRec.mif_ord_partiva_del:=flussoElabMifValore;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_partiva_benef:=flussoElabMifValore;

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     mifCountRec:=mifCountRec+1;
     -- <codice_fiscale_creditore_effettivo>
     if soggettoQuietId is not null  then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
            	if soggettoQuietRifId is not null then
                 if mifFlussoOrdinativoRec.mif_ord_partiva_del is null then
                  if soggettoQuietRifRec.codice_fiscale is not null and
                     length(soggettoQuietRifRec.codice_fiscale)= 16 then
	                 flussoElabMifValore:=trim ( both ' ' from soggettoQuietRifRec.codice_fiscale);
                  end if;
                 end if;
                else
                 if soggettoQuietRec.codice_fiscale is not null and
                    length(soggettoQuietRec.codice_fiscale)=16 then
	                 flussoElabMifValore:=trim ( both ' ' from soggettoQuietRec.codice_fiscale);
                 end if;
                end if;

				if flussoElabMifValore is not null then
--	                mifFlussoOrdinativoRec.mif_ord_codfisc_del:=flussoElabMifValore;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
  		            mifFlussoOrdinativoRec.mif_ord_codfisc_benef:=flussoElabMifValore;

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
        end if;
     end if;

     -- </creditore_effettivo>
/**/
	 -- <piazzatura>
     flussoElabMifElabRec:=null;
     isOrdPiazzatura:=false;
     accreditoGruppoCode:=null;
     isPaeseSepa:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--     raise notice 'piazzatura mifCountRec=%',mifCountRec;
     if flussoElabMifElabRec.flussoElabMifId is null then
      	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
       	 if flussoElabMifElabRec.flussoElabMifParam is not null then
            isOrdPiazzatura:=fnc_mif_ordinativo_piazzatura_splus(MDPRec.accredito_tipo_id,
                                                           		 mifOrdinativoIdRec.mif_ord_codice_funzione,
		  												         flussoElabMifElabRec.flussoElabMifParam,
                                                                 mifFlussoOrdinativoRec.mif_ord_pagam_tipo,
			                                                     dataElaborazione,dataFineVal,enteProprietarioId);
         end if;
      	else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
     end if;

     if isOrdPiazzatura=true then

      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura tipo accredito MDP per popolamento  campi relativi a'||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

--        raise notice 'Ordinativo con piazzatura % codice funzione=%',mifOrdinativoIdRec.mif_ord_ord_id,mifOrdinativoIdRec.mif_ord_codice_funzione;

		accreditoGruppoCode:=codAccreRec.accredito_gruppo_code;
	    --raise notice 'accreditoGruppoCode=% ',accreditoGruppoCode;

        if MDPRec.iban is not null and length(MDPRec.iban)>2  then
        	select distinct 1 into isPaeseSepa
            from siac_t_sepa sepa
            where sepa.sepa_iso_code=substring(upper(MDPRec.iban) from 1 for 2)
            and   sepa.ente_proprietario_id=enteProprietarioId
            and   sepa.data_cancellazione is null
      	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',sepa.validita_inizio)
 			and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(sepa.validita_fine,dataElaborazione));
        end if;
     end if;


     -- <abi_beneficiario>
 	 mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;

	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 6 for 5);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;


                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_abi_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
	 end if;

     -- <cab_beneficiario>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
         flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
 	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 11 for 5);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cab_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <numero_conto_corrente_beneficiario>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;
                    if tipoMDPCCP is null or tipoMDPCCP='' then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 16 for 12);
                    end if;

                    if tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode and
                       coalesce(MDPRec.contocorrente,NVL_STR)!=NVL_STR then
                       flussoElabMifValore:=lpad(MDPRec.contocorrente,NUM_DODICI,ZERO_PAD);
                    end if;

                    --raise notice 'numero_conto_corrente_beneficiario';
                    --raise notice 'tipoMDPCCP=% ',tipoMDPCCP;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cc_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <caratteri_controllo>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
	    flussoElabMifElabRec:=null;
    	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 3 for 2);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_ctrl_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;
     end if;


     -- <codice_cin>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;


					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 5 for 1);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cin_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <codice_paese>
	 mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 1 for 2);
                    end if;


					-- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cod_paese_benef:=flussoElabMifValore;
--                        raise notice 'statoBenficiario=%',statoBeneficiario;
                        if statoBeneficiario=true and statoDelegatoCredEff=false then -- se CSI IBAN non riporta dati del beneficiario quindi omettiamo codice_paese
                        	mifFlussoOrdinativoRec.mif_ord_stato_benef:=flussoElabMifValore;
                        end if;
                        if statoDelegatoCredEff=true then
--	                        mifFlussoOrdinativoRec.mif_ord_stato_del:=flussoElabMifValore;
                            -- 24.01.2018 Sofia jira siac-5765
                            mifFlussoOrdinativoRec.mif_ord_stato_del:=mifFlussoOrdinativoRec.mif_ord_stato_benef;
                            mifFlussoOrdinativoRec.mif_ord_stato_benef:=flussoElabMifValore;
                        end if;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
       end if;
     end if;


     -- extra sepa
     -- <denominazione_banca_destinataria>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true and isPaeseSepa is null then
		 flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.banca_denominazione is not null  then
                       	flussoElabMifValore:=MDPRec.banca_denominazione;
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_denom_banca_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;
     -- </piazzatura>

     -- sezione esteri sepa
     -- <sepa_credit_transfer>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and isPaeseSepa is not null then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     if flussoElabMifElabRec.flussoElabMifParam is not null then
                if paeseSepaTr is null then
	        	   	paeseSepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if accreditoGruppoSepaTr is null then
	            	accreditoGruppoSepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
                if SepaTr is null then
		            SepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                end if;

    	        if accreditoGruppoSepaTr is not null and SepaTr is not null and paeseSepaTr is not null then
	    	        sepaCreditTransfer:=true;
            	end if;
             end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     -- <iban>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and sepaCreditTransfer=true
        and isPaeseSepa is not null
        and accreditoGruppoSepaTr=accreditoGruppoCode then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     	if MDPRec.iban is not null and length(MDPRec.iban)>=2 and
        		   substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then
		           	mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr:=MDPRec.iban;
        		end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     -- <bic>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and sepaCreditTransfer=true
        and isPaeseSepa is not null
        and accreditoGruppoSepaTr=accreditoGruppoCode then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     	if MDPRec.bic is not null and
                   MDPRec.iban is not null and length(MDPRec.iban)>=2 and
        		   substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then
		           mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr:=MDPRec.bic;
        		end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;
     mifCountRec:=mifCountRec+5;
     -- </sepa_credit_transfer>


     -- <causale> ancora informazioni_beneficiario
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifValore:=null;
     flussoElabMifValoreDesc:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--     raise notice 'causale mifCountRec=%',mifCountRec;
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura CUP-CIG.';
            	if cupCausAttr is null then
	            	cupCausAttr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if cigCausAttr is null then
	                cigCausAttr:=trim (both ' '	 from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;

                if coalesce(cupCausAttr,NVL_STR)!=NVL_STR  and cupCausAttrId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cupCausAttr||'.';
                	select attr.attr_id into cupCausAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cupCausAttr
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;

                end if;

                if coalesce(cigCausAttr,NVL_STR)!=NVL_STR and cigCausAttrId is null then

                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cigCausAttr||'.';
                	select attr.attr_id into cigCausAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cigCausAttr
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;

                end if;


                if cupCausAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupCausAttr||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cupCausAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)=NVL_STR then
                       	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupCausAttr||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cupCausAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;
                    end if;
                end if;

                if cigCausAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigCausAttr||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValoreDesc
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cigCausAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValoreDesc,NVL_STR)=NVL_STR then
                       	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigCausAttr||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValoreDesc
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cigCausAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;
                    end if;
                end if;

            end if;
            -- cup
			if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
			       	mifFlussoOrdinativoRec.mif_ord_pagam_causale:=cupCausAttr||' '||flussoElabMifValore;

            end if;
            -- cig
			if coalesce(flussoElabMifValoreDesc,NVL_STR)!=NVL_STR  then
                	mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
                      trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||
                           ' '||cigCausAttr||' '||flussoElabMifValoreDesc);
            end if;


			mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
      			replace(replace(substring(trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||' '||mifOrdinativoIdRec.mif_ord_desc )
	                            from 1 for 370) , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);

--			raise notice 'mifFlussoOrdinativoRec.mif_ord_pagam_causale %',mifFlussoOrdinativoRec.mif_ord_pagam_causale;


	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

     -- <sospeso>
     -- <numero_provvisorio>
     -- <importo_provvisorio>
     mifCountRec:=mifCountRec+2;

	 -- <ritenuta>
     -- <importo_ritenute>
     -- <numero_reversale>
     -- <progressivo_versante>
     mifCountRec:=mifCountRec+3;

	 -- <informazioni_aggiuntive>

     -- <lingua>
    flussoElabMifElabRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifDef is not null then
        		mifFlussoOrdinativoRec.mif_ord_lingua:=flussoElabMifElabRec.flussoElabMifDef;

--                raise notice 'LINGUA def % %',flussoElabMifElabRec.flusso_elab_mif_campo,flussoElabMifElabRec.flussoElabMifDef;
            end if;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;


    -- <riferimento_documento_esterno>
    mifCountRec:=mifCountRec+1;
    if tipoPagamRec is not null then
    	flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
  		 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;
    	if flussoElabMifElabRec.flussoElabMifAttivo=true then
    		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifDef is not null and
                   flussoElabMifElabRec.flussoElabMifParam is not null then

                    -- modalita accredito=STI - STIPENDI
                    if codAccreRec.accredito_tipo_code =
                           trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3)) then
                           flussoElabMifValore:=
                             trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                    end if;

                    if  coalesce(flussoElabMifValore,'')='' and
                        tipoPagamRec.descTipoPagamento in
                        (trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)),
                         trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                        ) then
		                flussoElabMifValore:=tipoPagamRec.descTipoPagamento;
                    end if;

                    -- 23.01.2018 Sofia jira siac-5765
			        if codAccreRec.accredito_gruppo_code =
                           trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4)) and
                           MDPRec.contocorrente is not null and MDPRec.contocorrente!=''
                            then
                           flussoElabMifValore:=MDPRec.contocorrente;
                    end if;
                    -- 23.01.2018 Sofia jira siac-5765

                    if coalesce(flussoElabMifValore,'')='' and tipoPagamRec.defRifDocEsterno=true then
                        flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                    end if;

                    if coalesce(flussoElabMifValore,'')!='' then
	                    mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno:=flussoElabMifValore;
                    end if;
		        end if;
			else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		    end if;
    	end if;
    end if;
    -- </informazioni_aggiuntive>

    -- <sostituzione_mandato>

    flussoElabMifElabRec:=null;
    ordSostRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
                	select * into ordSostRec
                    from fnc_mif_ordinativo_sostituito( mifOrdinativoIdRec.mif_ord_ord_id,
 														ordRelazCodeTipoId,
                                                        dataElaborazione,dataFineVal);
    	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;

    end if;

   mifCountRec:=mifCountRec+3;
   if ordSostRec is not null then
   		 flussoElabMifElabRec:=null;
   		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-2];
	     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-2
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         -- <numero_mandato_da_sostituire>
      	 if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;

      	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	   if flussoElabMifElabRec.flussoElabMifElab=true then
--        		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=lpad(ordSostRec.ordNumeroSostituto::varchar,NUM_SETTE,ZERO_PAD);
                mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=ordSostRec.ordNumeroSostituto::varchar;
	    	else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     	end if;
         end if;

     	-- <progressivo_beneficiario_da_sostuire>
     	flussoElabMifElabRec:=null;
  	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-1];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-1
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;

        -- <esercizio_mandato_da_sostituire>
        flussoElabMifElabRec:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
               	mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg:=ordSostRec.ordAnnoSostituto;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;

     end if;


     -- <dati_a_disposizione_ente_beneficiario> facoltativo non valorizzato
     -- </informazioni_beneficiario>

     -- <dati_a_disposizione_ente_mandato>
	 -- <codice_distinta>
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifValore:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	 end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
      if flussoElabMifElabRec.flussoElabMifElab=true then
      		if mifOrdinativoIdRec.mif_ord_dist_id is not null then
				strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura distinta [siac_d_distinta].';
            	select  d.dist_code into flussoElabMifValore
                from siac_d_distinta d
                where d.dist_id=mifOrdinativoIdRec.mif_ord_dist_id;
            end if;

            if flussoElabMifValore is not null then
              	mifFlussoOrdinativoRec.mif_ord_codice_distinta:=flussoElabMifValore;
            end if;
      else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  end if;
	 end if;

     -- <atto_contabile>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
	     if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
                if attoAmmTipoAllRag is null then
            		attoAmmTipoAllRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if attoAmmStrTipoRag is null then
                	attoAmmStrTipoRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         		end if;

                if attoAmmTipoAllRag is not null and  attoAmmStrTipoRag is not null then

                 flussoElabMifValore:=fnc_mif_estremi_attoamm_all(mifOrdinativoIdRec.mif_ord_atto_amm_id,
                 										          attoAmmTipoAllRag,attoAmmStrTipoRag,
                                                                  dataElaborazione, dataFineVal);

                end if;
          	end if;

            if flussoElabMifValore is not null then
                 	mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile:=flussoElabMifValore;
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

      -- 15.01.2018 Sofia SIAC-5765
      -- <codice_operatore>
	  flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  flussoElabMifValoreDesc:=null;
	  mifCountRec:=mifCountRec+1;
	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then


         if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
         end if;

         if flussoElabMifValore is not null then
        	select substring(s.soggetto_desc  from 1 for 12)  into flussoElabMifValoreDesc
			from siac_t_account a, siac_r_soggetto_ruolo r, siac_t_soggetto s
			where a.ente_proprietario_id=enteProprietarioId
            and   a.account_code=flussoElabMifValore
			and   r.soggeto_ruolo_id=a.soggeto_ruolo_id
			and   s.soggetto_id=r.soggetto_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   a.data_cancellazione is null
            and   a.validita_fine is null;

            if 	flussoElabMifValoreDesc is not null then
            	flussoElabMifValore:=flussoElabMifValoreDesc;
            end if;
         end if;

         if flussoElabMifValore is not null then
            mifFlussoOrdinativoRec.mif_ord_code_operatore:=substring(flussoElabMifValore from 1 for 12);
         end if;
       else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
     end if;

     -- </dati_a_disposizione_ente_mandato>

     -- </mandato>
/**/
        /*raise notice 'codice_funzione= %',mifFlussoOrdinativoRec.mif_ord_codice_funzione;
		raise notice 'numero_mandato= %',mifFlussoOrdinativoRec.mif_ord_numero;
        raise notice 'data_mandato= %',mifFlussoOrdinativoRec.mif_ord_data;
        raise notice 'importo_mandato= %',mifFlussoOrdinativoRec.mif_ord_importo;*/

		 strMessaggio:='Inserimento mif_t_ordinativo_spesa per ord. numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        INSERT INTO mif_t_ordinativo_spesa
        (
  		-- mif_ord_data_elab, def now
  		 mif_ord_flusso_elab_mif_id,
 		 mif_ord_bil_id,
 		 mif_ord_ord_id,
  		 mif_ord_anno,
  		 mif_ord_numero,
  		 mif_ord_codice_funzione,
  		 mif_ord_data,
  		 mif_ord_importo,
  		 mif_ord_flag_fin_loc,
  		 mif_ord_documento,
  		 mif_ord_bci_tipo_ente_pag,
  		 mif_ord_bci_dest_ente_pag,
  		 mif_ord_bci_conto_tes,
 		 mif_ord_estremi_attoamm,
         mif_ord_resp_attoamm,
         mif_ord_uff_resp_attomm,
  		 mif_ord_codice_abi_bt,
  		 mif_ord_codice_ente,
  		 mif_ord_desc_ente,
  		 mif_ord_codice_ente_bt,
  		 mif_ord_anno_esercizio,
         mif_ord_codice_flusso_oil,
  		 mif_ord_id_flusso_oil,
  		 mif_ord_data_creazione_flusso,
  		 mif_ord_anno_flusso,
 		 mif_ord_codice_struttura,
  		 mif_ord_ente_localita,
  		 mif_ord_ente_indirizzo,
 		 mif_ord_codice_raggrup,
  		 mif_ord_progr_benef,
         mif_ord_progr_dest,
  		 mif_ord_bci_conto,
  		 mif_ord_bci_tipo_contabil,
  		 mif_ord_class_codice_cge,
  		 mif_ord_class_importo,
  		 mif_ord_class_codice_cup,
  		 mif_ord_class_codice_gest_prov,
  		 mif_ord_class_codice_gest_fraz,
  		 mif_ord_codifica_bilancio,
         mif_ord_capitolo,
  		 mif_ord_articolo,
  		 mif_ord_desc_codifica,
         mif_ord_desc_codifica_bil,
  		 mif_ord_gestione,
  		 mif_ord_anno_res,
  		 mif_ord_importo_bil,
  		 mif_ord_stanz,
    	 mif_ord_mandati_stanz,
  		 mif_ord_disponibilita,
  		 mif_ord_prev,
  		 mif_ord_mandati_prev,
  		 mif_ord_disp_cassa,
  		 mif_ord_anag_benef,
  		 mif_ord_indir_benef,
  		 mif_ord_cap_benef,
  		 mif_ord_localita_benef,
  		 mif_ord_prov_benef,
         mif_ord_stato_benef,
  		 mif_ord_partiva_benef,
  		 mif_ord_codfisc_benef,
  		 mif_ord_anag_quiet,
  		 mif_ord_indir_quiet,
  		 mif_ord_cap_quiet,
  		 mif_ord_localita_quiet,
  		 mif_ord_prov_quiet,
  		 mif_ord_partiva_quiet,
  		 mif_ord_codfisc_quiet,
	     mif_ord_stato_quiet,
  		 mif_ord_anag_del,
         mif_ord_indir_del,
         mif_ord_cap_del,
         mif_ord_localita_del,
         mif_ord_prov_del,
  		 mif_ord_codfisc_del,
         mif_ord_partiva_del,
         mif_ord_stato_del,
  		 mif_ord_invio_avviso,
  		 mif_ord_abi_benef,
  		 mif_ord_cab_benef,
  		 mif_ord_cc_benef_estero,
 		 mif_ord_cc_benef,
         mif_ord_ctrl_benef,
  		 mif_ord_cin_benef,
  		 mif_ord_cod_paese_benef,
  		 mif_ord_denom_banca_benef,
  		 mif_ord_cc_postale_benef,
  		 mif_ord_swift_benef,
  		 mif_ord_iban_benef,
         mif_ord_sepa_iban_tr,
         mif_ord_sepa_bic_tr,
         mif_ord_sepa_id_end_tr,
  		 mif_ord_bollo_esenzione,
  		 mif_ord_bollo_carico,
  		 mif_ordin_bollo_caus_esenzione,
  		 mif_ord_commissioni_carico,
         mif_ord_commissioni_esenzione,
  		 mif_ord_commissioni_importo,
         mif_ord_commissioni_natura,
  		 mif_ord_pagam_tipo,
  		 mif_ord_pagam_code,
  		 mif_ord_pagam_importo,
  		 mif_ord_pagam_causale,
  		 mif_ord_pagam_data_esec,
  		 mif_ord_lingua,
  		 mif_ord_rif_doc_esterno,
  		 mif_ord_info_tesoriere,
  		 mif_ord_flag_copertura,
  		 mif_ord_num_ord_colleg,
  		 mif_ord_progr_ord_colleg,
  		 mif_ord_anno_ord_colleg,
  		 mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
  		 mif_ord_descri_estesa_cap,
  		 mif_ord_siope_codice_cge,
  		 mif_ord_siope_descri_cge,
         mif_ord_codice_ente_ipa,
         mif_ord_codice_ente_istat,
         mif_ord_codice_ente_tramite,
         mif_ord_codice_ente_tramite_bt,
	     mif_ord_riferimento_ente,
         mif_ord_importo_benef,
         mif_ord_pagam_postalizza,
         mif_ord_class_tipo_debito,
         mif_ord_class_tipo_debito_nc,
         mif_ord_class_cig,
         mif_ord_class_motivo_nocig,
         mif_ord_class_missione,
         mif_ord_class_programma,
         mif_ord_class_economico,
         mif_ord_class_importo_economico,
         mif_ord_class_transaz_ue,
         mif_ord_class_ricorrente_spesa,
         mif_ord_class_cofog_codice,
         mif_ord_class_cofog_importo,
         mif_ord_codice_distinta,
         mif_ord_codice_atto_contabile,
  		 validita_inizio,
         ente_proprietario_id,
  		 login_operazione
		)
		VALUES
        (
	  	 --:mif_ord_data_elab,
  		 flussoElabMifLogId, --idElaborazione univoco
  		 mifOrdinativoIdRec.mif_ord_bil_id,
  		 mifOrdinativoIdRec.mif_ord_ord_id,
  		 mifOrdinativoIdRec.mif_ord_ord_anno,
  		 mifFlussoOrdinativoRec.mif_ord_numero,
  		 mifFlussoOrdinativoRec.mif_ord_codice_funzione,
  		 mifFlussoOrdinativoRec.mif_ord_data,
--  	     (case when mifFlussoOrdinativoRec.mif_ord_codice_funzione in (FUNZIONE_CODE_N,FUNZIONE_CODE_A) then
--                    '0.00' else mifFlussoOrdinativoRec.mif_ord_importo end),
         mifFlussoOrdinativoRec.mif_ord_importo,
 		 mifFlussoOrdinativoRec.mif_ord_flag_fin_loc,
  	     mifFlussoOrdinativoRec.mif_ord_documento,
 		 mifFlussoOrdinativoRec.mif_ord_bci_tipo_ente_pag,
 	 	 mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag,
 		 mifFlussoOrdinativoRec.mif_ord_bci_conto_tes,
 		 mifFlussoOrdinativoRec.mif_ord_estremi_attoamm,
         mifFlussoOrdinativoRec.mif_ord_resp_attoamm,
  		 mifFlussoOrdinativoRec.mif_ord_uff_resp_attomm,
 		 mifFlussoOrdinativoRec.mif_ord_codice_abi_bt,
 		 mifFlussoOrdinativoRec.mif_ord_codice_ente,
		 mifFlussoOrdinativoRec.mif_ord_desc_ente,
  		 mifFlussoOrdinativoRec.mif_ord_codice_ente_bt,
 		 mifFlussoOrdinativoRec.mif_ord_anno_esercizio,
  		annoBilancio||flussoElabMifDistOilRetId::varchar,
  		flussoElabMifOilId, --idflussoOil
        extract(year from now())||'-'||
        lpad(extract('month' from now())::varchar,2,'0')||'-'||
        lpad(extract('day' from now())::varchar,2,'0')||'T'||
        lpad(extract('hour' from now())::varchar,2,'0')||':'||
        lpad(extract('minute' from now())::varchar,2,'0')||':'||'00',  -- mif_ord_data_creazione_flusso
        extract(year from now())::integer,
 		mifFlussoOrdinativoRec.mif_ord_codice_struttura,
 		mifFlussoOrdinativoRec.mif_ord_ente_localita,
		mifFlussoOrdinativoRec.mif_ord_ente_indirizzo,
 		mifFlussoOrdinativoRec.mif_ord_codice_raggrup,
 		mifFlussoOrdinativoRec.mif_ord_progr_benef,
 		mifFlussoOrdinativoRec.mif_ord_progr_dest,
 		mifFlussoOrdinativoRec.mif_ord_bci_conto,
  		mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_class_importo,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cup,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz,
 		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio,
        mifFlussoOrdinativoRec.mif_ord_capitolo,
  		mifFlussoOrdinativoRec.mif_ord_articolo,
 		mifFlussoOrdinativoRec.mif_ord_desc_codifica,
        mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil,
		mifFlussoOrdinativoRec.mif_ord_gestione,
 		mifFlussoOrdinativoRec.mif_ord_anno_res,
 		mifFlussoOrdinativoRec.mif_ord_importo_bil,
        mifFlussoOrdinativoRec.mif_ord_stanz,
    	mifFlussoOrdinativoRec.mif_ord_mandati_stanz,
  		mifFlussoOrdinativoRec.mif_ord_disponibilita,
		mifFlussoOrdinativoRec.mif_ord_prev,
  		mifFlussoOrdinativoRec.mif_ord_mandati_prev,
  		mifFlussoOrdinativoRec.mif_ord_disp_cassa,
        mifFlussoOrdinativoRec.mif_ord_anag_benef,
  		mifFlussoOrdinativoRec.mif_ord_indir_benef,
		mifFlussoOrdinativoRec.mif_ord_cap_benef,
 		mifFlussoOrdinativoRec.mif_ord_localita_benef,
  		mifFlussoOrdinativoRec.mif_ord_prov_benef,
        mifFlussoOrdinativoRec.mif_ord_stato_benef,
 		mifFlussoOrdinativoRec.mif_ord_partiva_benef,
  		mifFlussoOrdinativoRec.mif_ord_codfisc_benef,
  		mifFlussoOrdinativoRec.mif_ord_anag_quiet,
        mifFlussoOrdinativoRec.mif_ord_indir_quiet,
  		mifFlussoOrdinativoRec.mif_ord_cap_quiet,
 		mifFlussoOrdinativoRec.mif_ord_localita_quiet,
  		mifFlussoOrdinativoRec.mif_ord_prov_quiet,
 		mifFlussoOrdinativoRec.mif_ord_partiva_quiet,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_quiet,
        mifFlussoOrdinativoRec.mif_ord_stato_quiet,
 		mifFlussoOrdinativoRec.mif_ord_anag_del,
        mifFlussoOrdinativoRec.mif_ord_indir_del,
        mifFlussoOrdinativoRec.mif_ord_cap_del,
 		mifFlussoOrdinativoRec.mif_ord_localita_del,
 		mifFlussoOrdinativoRec.mif_ord_prov_del,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_del,
 		mifFlussoOrdinativoRec.mif_ord_partiva_del,
        mifFlussoOrdinativoRec.mif_ord_stato_del,
 		mifFlussoOrdinativoRec.mif_ord_invio_avviso,
 		mifFlussoOrdinativoRec.mif_ord_abi_benef,
 		mifFlussoOrdinativoRec.mif_ord_cab_benef,
 		mifFlussoOrdinativoRec.mif_ord_cc_benef_estero,
 		mifFlussoOrdinativoRec.mif_ord_cc_benef,
 		mifFlussoOrdinativoRec.mif_ord_ctrl_benef,
 		mifFlussoOrdinativoRec.mif_ord_cin_benef,
 		mifFlussoOrdinativoRec.mif_ord_cod_paese_benef,
  		mifFlussoOrdinativoRec.mif_ord_denom_banca_benef,
 		mifFlussoOrdinativoRec.mif_ord_cc_postale_benef,
  		mifFlussoOrdinativoRec.mif_ord_swift_benef,
  		mifFlussoOrdinativoRec.mif_ord_iban_benef,
        mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr,
        mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr,
        mifFlussoOrdinativoRec.mif_ord_sepa_id_end_tr,
 		mifFlussoOrdinativoRec.mif_ord_bollo_esenzione,
  		mifFlussoOrdinativoRec.mif_ord_bollo_carico,
  		mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione,
 		mifFlussoOrdinativoRec.mif_ord_commissioni_carico,
        mifFlussoOrdinativoRec.mif_ord_commissioni_esenzione,
		mifFlussoOrdinativoRec.mif_ord_commissioni_importo,
        mifFlussoOrdinativoRec.mif_ord_commissioni_natura,
  		mifFlussoOrdinativoRec.mif_ord_pagam_tipo,
 		mifFlussoOrdinativoRec.mif_ord_pagam_code,
	    mifFlussoOrdinativoRec.mif_ord_pagam_importo,
 		mifFlussoOrdinativoRec.mif_ord_pagam_causale,
 		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec,
 		mifFlussoOrdinativoRec.mif_ord_lingua,
		mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno,
 		mifFlussoOrdinativoRec.mif_ord_info_tesoriere,
 		mifFlussoOrdinativoRec.mif_ord_flag_copertura,
		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg,
        mifFlussoOrdinativoRec.mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
        mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap,
        mifFlussoOrdinativoRec.mif_ord_siope_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_siope_descri_cge,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_istat,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt,
	    mifFlussoOrdinativoRec.mif_ord_riferimento_ente,
        mifFlussoOrdinativoRec.mif_ord_importo_benef,
        mifFlussoOrdinativoRec.mif_ord_pagam_postalizza,
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito,
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc,
        mifFlussoOrdinativoRec.mif_ord_class_cig,
        mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig,
        mifFlussoOrdinativoRec.mif_ord_class_missione,
        mifFlussoOrdinativoRec.mif_ord_class_programma,
        mifFlussoOrdinativoRec.mif_ord_class_economico,
        mifFlussoOrdinativoRec.mif_ord_class_importo_economico,
        mifFlussoOrdinativoRec.mif_ord_class_transaz_ue,
        mifFlussoOrdinativoRec.mif_ord_class_ricorrente_spesa,
        mifFlussoOrdinativoRec.mif_ord_class_cofog_codice,
        mifFlussoOrdinativoRec.mif_ord_class_cofog_importo,
	    mifFlussoOrdinativoRec.mif_ord_codice_distinta,
        mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile,
        now(),
        enteProprietarioId,
        loginOperazione
   )
   returning mif_ord_id into mifOrdSpesaId;




 -- dati fatture da valorizzare se ordinativo commerciale
 -- @@@@ sicuramente da completare
 -- <fattura_siope>
 if isGestioneFatture = true and isOrdCommerciale=true then
  flussoElabMifElabRec:=null;
  mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
  titoloCap:=null;
  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Lettura natura spesa.';

  /*if mifOrdinativoIdRec.mif_ord_titolo_code=titoloCorrente then
	  	titoloCap:=descriTitoloCorrente;
  else
   if mifOrdinativoIdRec.mif_ord_titolo_code=titoloCapitale then
     	titoloCap:=descriTitoloCapitale;
   end if;
  end if;*/
  -- 20.02.2018 Sofia JIRA siac-5849
  select oil.oil_natura_spesa_desc into titoloCap
  from siac_d_oil_natura_spesa oil, siac_r_oil_natura_spesa_titolo r
  where r.oil_natura_spesa_titolo_id=mifOrdinativoIdRec.mif_ord_titolo_id
  and   oil.oil_natura_spesa_id=r.oil_natura_spesa_id
  and   r.data_cancellazione is null
  and   r.validita_fine is null;
  if titoloCap is null then titoloCap:=defNaturaPag; end if;
   -- 26.02.2018 Sofia JIRA siac-5849 - inclusione delle note credito  per ordinativi di pagamento
  titoloCap:=titoloCap||'|N'; -- 08.05.2018 Sofia siac-6137
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Inizio ciclo.';
  ordRec:=null;
  for ordRec in
  (select * from fnc_mif_ordinativo_documenti_splus( mifOrdinativoIdRec.mif_ord_ord_id,
											         numeroDocs::integer,
                                                     tipoDocs,
                                                     docAnalogico,
                                                     attrCodeDataScad,
                                                     titoloCap,
                                                     enteOilRec.ente_oil_codice_pcc_uff,
		   		                        	         enteProprietarioId,
	            		                             dataElaborazione,dataFineVal)
  )
  loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento fatture '
                       ||' in mif_t_ordinativo_spesa_documenti '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         insert into  mif_t_ordinativo_spesa_documenti
         ( mif_ord_id,
		   mif_ord_documento,
           mif_ord_doc_codice_ipa_ente,
	       mif_ord_doc_tipo,
           mif_ord_doc_tipo_a,
		   mif_ord_doc_id_lotto_sdi,
		   mif_ord_doc_tipo_analog,
		   mif_ord_doc_codfisc_emis,
		   mif_ord_doc_anno,
	       mif_ord_doc_numero,
	       mif_ord_doc_importo,
	       mif_ord_doc_data_scadenza,
	       mif_ord_doc_motivo_scadenza,
	       mif_ord_doc_natura_spesa,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
         )
         values
         (mifOrdSpesaId,
          --ordRec.numero_fattura_siope,
          'S', -- 07.06.2018 Sofia SIAC-6228
		  ordRec.codice_ipa_ente_siope,
		  ordRec.tipo_documento_siope,
          ordRec.tipo_documento_siope_a,
          ordRec.identificativo_lotto_sdi_siope,
          ordRec.tipo_documento_analogico_siope,
          trim ( both ' ' from ordRec.codice_fiscale_emittente_siope),
		  ordRec.anno_emissione_fattura_siope,
		  ordRec.numero_fattura_siope,
          ordRec.importo_siope,
		  ordRec.data_scadenza_pagam_siope,
		  ordRec.motivo_scadenza_siope,
    	  ordRec.natura_spesa_siope,
          now(),
          enteProprietarioId,
          loginOperazione
         );
  end loop;
 end if;




   -- <ritenuta>
   -- <importo_ritenuta>
   -- <numero_reversale>
   -- <progressivo_reversale>

   if  isRitenutaAttivo=true then
    ritenutaRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  ritenute'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ritenutaRec in
    (select *
     from fnc_mif_ordinativo_ritenute(mifOrdinativoIdRec.mif_ord_ord_id,
         	 					      tipoRelazRitOrd,tipoRelazSubOrd,tipoRelazSprOrd,
                                      tipoOnereIrpefId,tipoOnereInpsId,
                                      tipoOnereIrpegId,
									  ordStatoCodeAId,ordDetTsTipoId,
                                      flussoElabMifTipoDec,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento ritenuta'
                       ||' in mif_t_ordinativo_spesa_ritenute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_spesa_ritenute
        (mif_ord_id,
  		 mif_ord_rit_tipo,
 		 mif_ord_rit_importo,
 		 mif_ord_rit_numero,
  		 mif_ord_rit_ord_id,
 		 mif_ord_rit_progr_rev,
  		 validita_inizio,
		 ente_proprietario_id,
		 login_operazione)
        values
        (mifOrdSpesaId,
         tipoRitenuta,
         ritenutaRec.importoRitenuta,
         ritenutaRec.numeroRitenuta,
         ritenutaRec.ordRitenutaId,
         progrRitenuta,
         now(),
         enteProprietarioId,
         loginOperazione
        );

    end loop;
   end if;

   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
  if  isRicevutaAttivo=true then
    ricevutaRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  provvisori'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ricevutaRec in
    (select *
     from fnc_mif_ordinativo_ricevute(mifOrdinativoIdRec.mif_ord_ord_id,
                                      flussoElabMifTipoDec,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento   ricevuta'
                       ||' in mif_t_ordinativo_spesa_ricevute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_spesa_ricevute
        (mif_ord_id,
	     mif_ord_ric_anno,
	     mif_ord_ric_numero,
	     mif_ord_provc_id,
		 mif_ord_ric_importo,
	     validita_inizio,
		 ente_proprietario_id,
	     login_operazione
        )
        values
        (mifOrdSpesaId,
         ricevutaRec.annoRicevuta,
         ricevutaRec.numeroRicevuta,
         ricevutaRec.provRicevutaId,
         ricevutaRec.importoRicevuta,
         now(),
         enteProprietarioId,
         loginOperazione
        );
    end loop;
  end if;

  numeroOrdinativiTrasm:=numeroOrdinativiTrasm+1;
 end loop;

/* if comPccAttrId is not null and numeroOrdinativiTrasm>0 then
   	   strMessaggio:='Inserimento Registro PCC.';
	   insert into siac_t_registro_pcc
	   (doc_id,
    	subdoc_id,
	    pccop_tipo_id,
    	ordinativo_data_emissione,
	    ordinativo_numero,
    	rpcc_quietanza_data,
        rpcc_quietanza_importo,
	    soggetto_id,
    	validita_inizio,
	    ente_proprietario_id,
    	login_operazione
	    )
    	(
         with
         mif as
         (select m.mif_ord_ord_id ord_id, m.mif_ord_soggetto_id soggetto_id,
                 ord.ord_emissione_data , ord.ord_numero
          from mif_t_ordinativo_spesa_id m, siac_t_ordinativo ord
          where m.ente_proprietario_id=enteProprietarioId
          and   substring(m.mif_ord_codice_funzione from 1 for 1)=FUNZIONE_CODE_I
          and   ord.ord_id=m.mif_ord_ord_id
         ),
         tipodoc as
         (select tipo.doc_tipo_id
          from siac_d_doc_tipo tipo ,siac_r_doc_tipo_attr attr
          where attr.attr_id=comPccAttrId
          and   attr.boolean='S'
          and   tipo.doc_tipo_id=attr.doc_tipo_id
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
          and   tipo.data_cancellazione is null
          and   tipo.validita_fine is null
         ),
         doc as
         (select distinct m.mif_ord_ord_id ord_id, subdoc.doc_id , subdoc.subdoc_id, subdoc.subdoc_importo, doc.doc_tipo_id
	      from  mif_t_ordinativo_spesa_id m, siac_t_ordinativo_ts ts, siac_r_subdoc_ordinativo_ts rsubdoc,
                siac_t_subdoc subdoc, siac_t_doc doc
          where m.ente_proprietario_id=enteProprietarioId
          and   substring(m.mif_ord_codice_funzione from 1 for 1)=FUNZIONE_CODE_I
          and   ts.ord_id=m.mif_ord_ord_id
          and   rsubdoc.ord_ts_id=ts.ord_ts_id
          and   subdoc.subdoc_id=rsubdoc.subdoc_id
          and   doc.doc_id=subdoc.doc_id
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null
          and   rsubdoc.data_cancellazione is null
          and   rsubdoc.validita_fine is null
          and   subdoc.data_cancellazione is null
          and   subdoc.validita_fine is null
          and   doc.data_cancellazione is null
          and   doc.validita_fine is null
         )
         select
          doc.doc_id,
          doc.subdoc_id,
          pccOperazTipoId,
--          mif.ord_emissione_data,
--		  mif.ord_emissione_data+(1*interval '1 day'),
		  mif.ord_emissione_data,
          mif.ord_numero,
          dataElaborazione,
          doc.subdoc_importo,
          mif.soggetto_id,
          now(),
          enteProprietarioId,
          loginOperazione
         from mif, doc,tipodoc
         where mif.ord_id=doc.ord_id
         and   tipodoc.doc_tipo_id=doc.doc_tipo_id
        );
   end if;*/


   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifOilId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_out_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifDistOilRetId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;


   strMessaggio:='Aggiornamento mif_t_flusso_elaborato.';

   update  mif_t_flusso_elaborato
   set (flusso_elab_mif_id_flusso_oil,flusso_elab_mif_codice_flusso_oil,flusso_elab_mif_num_ord_elab,flusso_elab_mif_file_nome,flusso_elab_mif_esito_msg)=
   	   (flussoElabMifOilId,annoBilancio||flussoElabMifDistOilRetId::varchar,numeroOrdinativiTrasm,flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice,
        'Elaborazione in corso tipo flusso '||MANDMIF_TIPO||' - Dati inseriti in mif_t_ordinativo_spesa')
   where flusso_elab_mif_id=flussoElabMifLogId;

    -- gestire aggiornamento mif_t_flusso_elaborato

	RAISE NOTICE 'numeroOrdinativiTrasm %', numeroOrdinativiTrasm;
    messaggioRisultato:=strMessaggioFinale||' Trasmessi '||numeroOrdinativiTrasm||' ordinativi di spesa.';
    messaggioRisultato:=upper(messaggioRisultato);
    flussoElabMifId:=flussoElabMifLogId;
    nomeFileMif:=flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice;


    flussoElabMifDistOilId:=(annoBilancio||flussoElabMifDistOilRetId::varchar)::integer;
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 100),mifCountRec;
        if codResult=-12 then
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||' '||mifCountRec||'.' ;
          codiceRisultato:=0;
        else
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||' '||mifCountRec||'.' ;
       	  codiceRisultato:=-1;
    	end if;

        numeroOrdinativiTrasm:=0;
		messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when NO_DATA_FOUND THEN
        raise notice '% % ERRORE : % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when TOO_MANY_ROWS THEN
        raise notice '% % ERRORE : % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then


            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;
        return;
	when others  THEN
		raise notice '% % Errore DB % % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500)||' '||mifCountRec||'.' ;
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;

        else
        	flussoElabMifId:=null;
        end if;

        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
  
  
-- SIAC-6228 - Sofia - Fine