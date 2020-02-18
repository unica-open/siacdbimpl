/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
'fnc_siac_dwh_liquidazione',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico liquidazione (FNC_SIAC_DWH_LIQUIDAZIONE) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_liquidazione
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;




insert into siac_dwh_liquidazione(ente_proprietario_id,
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
tipo_cessione,
cod_cessione,
desc_cessione,
soggetto_csc_id,
cod_siope_tipo_debito,
desc_siope_tipo_debito,
desc_siope_tipo_debito_bnkit,
cod_siope_assenza_motivazione,
desc_siope_assenza_motivazione,
desc_siope_assenza_motiv_bnkit)
select tbb.* from (
with liquidaz as (
select 
tb.ente_proprietario_id v_ente_proprietario_id,
tb.ente_denominazione v_ente_denominazione, tb.anno v_anno, tb.v_fase_operativa_code v_fase_operativa_code,
tb.v_fase_operativa_desc v_fase_operativa_desc, tb.liq_anno v_liq_anno,tb.liq_numero v_liq_numero,
tb.liq_desc,
tb.liq_emissione_data::date v_liq_emissione_data,tb.liq_importo v_liq_importo, tb.liq_automatica v_liq_automatica,
tb.liq_convalida_manuale v_liq_convalida_manuale,tb.liq_stato_code v_liq_stato_code,tb.liq_stato_desc v_liq_stato_desc,
tb.contotes_code v_contotes_code,tb.contotes_desc v_contotes_desc,tb.dist_code v_dist_code,tb.dist_desc v_dist_desc,
tb.soggetto_id v_sogg_id,tb.v_codice_soggetto,tb.v_descrizione_soggetto,tb.v_codice_fiscale_soggetto,
tb.v_codice_fiscale_estero_soggetto,tb.v_partita_iva_soggetto,tb.v_soggetto_id_modpag,tb.v_codice_soggetto_modpag,
tb.v_descrizione_soggetto_modpag,
tb.v_codice_fiscale_soggetto_modpag,
tb.v_codice_fiscale_estero_soggetto_modpag,
tb.v_partita_iva_soggetto_modpag,
tb.v_codice_tipo_accredito,tb.v_descrizione_tipo_accredito,
tb.v_modpag_cessione_id,
tb.v_quietanziante,tb.v_data_nascita_quietanziante,
tb.v_luogo_nascita_quietanziante,
tb.v_stato_nascita_quietanziante,
tb.v_bic,
tb.v_contocorrente,
tb.v_intestazione_contocorrente,
tb.v_iban,
tb.v_note_modalita_pagamento, --case when tb.v_note_modalita_pagamento ='' then null else tb.v_note_modalita_pagamento end v_note_modalita_pagamento,
tb.v_data_scadenza_modalita_pagamento,
tb.v_anno_impegno,tb.v_numero_impegno,
tb.v_codice_impegno,
tb.v_descrizione_impegno,
tb.v_codice_subimpegno,
tb.v_descrizione_subimpegno,
/*tb.attoamm_tipo_code v_codice_tipo_atto_amministrativo, tb.attoamm_tipo_desc v_descrizione_tipo_atto_amministrativo, 
tb.attoamm_stato_desc v_descrizione_stato_atto_amministrativo,tb.attoamm_anno v_anno_atto_amministrativo,
tb.attoamm_numero v_numero_atto_amministrativo, 
tb.attoamm_oggetto,
tb.attoamm_note,*/
tb.v_codice_spesa_ricorrente, tb.v_descrizione_spesa_ricorrente,
tb.v_codice_perimetro_sanitario_spesa, tb.v_descrizione_perimetro_sanitario_spesa,
tb.v_codice_politiche_regionali_unitarie, tb.v_descrizione_politiche_regionali_unitarie,
tb.v_codice_transazione_spesa_ue, tb.v_descrizione_transazione_spesa_ue,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_I else tb.pdc4_codice_pdc_finanziario_I end v_codice_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_I else tb.pdc4_descrizione_pdc_finanziario_I end v_descrizione_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_II else tb.pdc4_codice_pdc_finanziario_II end v_codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_II else tb.pdc4_descrizione_pdc_finanziario_II end v_descrizione_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_III else tb.pdc4_codice_pdc_finanziario_III end v_codice_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_III else tb.pdc4_descrizione_pdc_finanziario_III end v_descrizione_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_IV else tb.pdc4_codice_pdc_finanziario_IV end v_codice_pdc_finanziario_IV  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_IV else tb.pdc4_descrizione_pdc_finanziario_IV end v_descrizione_pdc_finanziario_IV,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_V end v_codice_pdc_finanziario_V  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_V end v_descrizione_pdc_finanziario_V,
null::varchar v_codice_pdc_economico_I,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_I else tb.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
null::varchar v_descrizione_pdc_economico_I,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_I else tb.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
null::varchar v_codice_pdc_economico_II,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_II else tb.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
null::varchar v_descrizione_pdc_economico_II,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_II else tb.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
null::varchar v_codice_pdc_economico_III,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_III else tb.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
null::varchar v_descrizione_pdc_economico_III,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_III else tb.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
null::varchar v_codice_pdc_economico_IV,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_IV else tb.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
null::varchar v_descrizione_pdc_economico_IV,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_IV else tb.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
null::varchar v_codice_pdc_economico_V,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
null::varchar v_descrizione_pdc_economico_V,--case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V
/*tb.codice_cofog_divisione v_codice_cofog_divisione,
tb.descrizione_cofog_divisione v_escrizione_cofog_divisione,
tb.codice_cofog_gruppo v_codice_cofog_gruppo,
tb.descrizione_cofog_gruppo v_descrizione_cofog_gruppo,*/
tb.v_cup,
tb.v_cig,
/*case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_code::varchar else tb.cdr_cdr_code::varchar end v_cod_cdr_atto_amministrativo,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_desc::varchar else tb.cdr_cdr_desc::varchar end v_desc_cdr_atto_amministrativo,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_code::varchar else tb.cdr_cdc_code::varchar end v_cod_cdc_atto_amministrativo,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_desc::varchar else tb.cdr_cdc_desc::varchar end v_desc_cdc_atto_amministrativo,
*/
tb.data_inizio_val_stato_liquidaz v_data_inizio_val_stato_liquidaz,
tb.data_inizio_val_liquidaz v_data_inizio_val_liquidaz,
tb.data_creazione_liquidaz v_data_creazione_liquidaz,
tb.data_modifica_liquidaz v_data_modifica_liquidaz,
tb.v_tipo_cessione,
tb.v_cod_cessione,
tb.v_desc_cessione,
tb.v_soggetto_csc_id,
tb.siope_tipo_debito_code, tb.siope_tipo_debito_desc, tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code, tb.siope_assenza_motivazione_desc, tb.siope_assenza_motivazione_desc_bnkit 
,tb.liq_id
from (
with liq as (
SELECT 
a.dist_id,
a.contotes_id,
b.ente_proprietario_id, b.ente_denominazione, d.anno,
a.liq_anno, a.liq_numero, a.liq_desc, a.liq_emissione_data, a.liq_importo, a.liq_automatica,
a.liq_convalida_manuale, a.modpag_id, a.soggetto_relaz_id, -- 04.07.p_ente_proprietario_id017 Sofia SIAC-5040
f.liq_stato_code, f.liq_stato_desc,
h.fase_operativa_code v_fase_operativa_code, h.fase_operativa_desc v_fase_operativa_desc,
a.liq_id, c.bil_id,
e.validita_inizio as data_inizio_val_stato_liquidaz,
a.validita_inizio as data_inizio_val_liquidaz,
a.data_creazione as data_creazione_liquidaz,
a.data_modifica as data_modifica_liquidaz,
i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit 
FROM   siac_t_liquidazione a
left join siac_d_siope_tipo_debito i on i.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and i.data_cancellazione is null
                                     and i.validita_fine is null
left join siac_d_siope_assenza_motivazione l on l.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and l.data_cancellazione is null
                                             and l.validita_fine is null
, siac_t_ente_proprietario b 
, siac_t_bil c  
, siac_t_periodo d 
, siac_r_liquidazione_stato e  
, siac_d_liquidazione_stato f  
, siac_r_bil_fase_operativa g
, siac_d_fase_operativa h
where 
 b.ente_proprietario_id = a.ente_proprietario_id and
 a.bil_id = c.bil_id and 
 d.periodo_id = c.periodo_id and 
 a.liq_id = e.liq_id and 
 e.liq_stato_id = f.liq_stato_id and 
 b.ente_proprietario_id = p_ente_proprietario_id
AND d.anno = p_anno_bilancio
and g.bil_id=c.bil_id
and h.fase_operativa_id = g.fase_operativa_id
and p_data BETWEEN g.validita_inizio AND COALESCE(g.validita_fine, p_data)
and g.data_cancellazione is null
and h.data_cancellazione is null
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND a.data_cancellazione IS NULL
AND p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND b.data_cancellazione IS NULL
AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND c.data_cancellazione IS NULL
AND p_data BETWEEN d.validita_inizio AND COALESCE(d.validita_fine, p_data)
AND d.data_cancellazione IS NULL
AND p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
AND e.data_cancellazione IS NULL
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
AND f.data_cancellazione IS NULL)
,
contotes as (
select contotes_id,validita_inizio, data_cancellazione,
contotes_code, contotes_desc
  From siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null and 
  p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
dist as (  
  select dist_id,dist_code, dist_desc
  From siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null and 
  p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)  
),
sog as (
select tbp_ente_proprietario_id.* from (
 with soggtot as (
select tb.soggetto_id,tb.liq_id from ( 
with sogg as (  
select 
a.soggetto_id, a.liq_id
  From siac_r_liquidazione_soggetto a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null and 
  p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))    
, soggintest as (  
SELECT a.soggetto_id_da v_soggetto_id_intestatario
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b
WHERE 
a.ente_proprietario_id = p_ente_proprietario_id and 
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
--AND   a.soggetto_id_a = v_soggetto_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL)
select case when soggintest.v_soggetto_id_intestatario
is null then sogg.soggetto_id else soggintest.v_soggetto_id_intestatario END as soggetto_id,
sogg.liq_id
  from sogg left join soggintest
on soggintest.v_soggetto_id_intestatario = sogg.soggetto_id
) as tb 
),
tsog as (
select * from siac_t_soggetto c where c.ente_proprietario_id=p_ente_proprietario_id and c.data_cancellazione is null)
select 
soggtot.liq_id,
soggtot.soggetto_id,
tsog.soggetto_code v_codice_soggetto, 
tsog.soggetto_desc v_descrizione_soggetto,
 tsog.codice_fiscale v_codice_fiscale_soggetto, 
 tsog.codice_fiscale_estero v_codice_fiscale_estero_soggetto, 
 tsog.partita_iva v_partita_iva_soggetto
 from  soggtot join tsog
on soggtot.soggetto_id=tsog.soggetto_id
) as tbp_ente_proprietario_id
),
modpag as 
(select a.soggetto_id , a.modpag_id,
a.accredito_tipo_id, a.quietanziante, a.quietanzante_nascita_data, a.quietanziante_nascita_luogo,
a.quietanziante_nascita_stato, a.bic, a.contocorrente, a.contocorrente_intestazione, a.iban,
a.note, a.data_scadenza ,
null::varchar oil_relaz_tipo_code, null::varchar relaz_tipo_code, null::varchar relaz_tipo_desc,
s.soggetto_code, s.soggetto_desc, s.codice_fiscale, s.codice_fiscale_estero, s.partita_iva,
b.accredito_tipo_code , b.accredito_tipo_desc 
FROM  siac_t_modpag a, siac_t_soggetto s ,siac_d_accredito_tipo b
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and 
p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
and s.soggetto_id=a.soggetto_id
and b.accredito_tipo_id=a.accredito_tipo_id
and b.data_Cancellazione is null
),
modpagoil as 
(select 
rel.soggetto_relaz_id,
rel.soggetto_id_a soggetto_id, mdp.modpag_id,
        mdp.accredito_tipo_id, mdp.quietanziante, mdp.quietanzante_nascita_data, mdp.quietanziante_nascita_luogo,
        mdp.quietanziante_nascita_stato, mdp.bic, mdp.contocorrente, mdp.contocorrente_intestazione, mdp.iban,
        mdp.note, mdp.data_scadenza,
        oil.oil_relaz_tipo_code,tipo.relaz_tipo_code, tipo.relaz_tipo_desc,
s.soggetto_code, s.soggetto_desc, s.codice_fiscale, s.codice_fiscale_estero, s.partita_iva,
b.accredito_tipo_code , b.accredito_tipo_desc          
 FROM  siac_r_soggetto_relaz rel, siac_r_soggrel_modpag sogrel, siac_t_modpag mdp,
       siac_r_oil_relaz_tipo roil, siac_d_relaz_tipo tipo , siac_d_oil_relaz_tipo oil,
       siac_t_soggetto s,siac_d_accredito_tipo b
 WHERE
 rel.ente_proprietario_id=p_ente_proprietario_id 
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
 and s.soggetto_id=rel.soggetto_id_a
 and b.accredito_tipo_id=mdp.accredito_tipo_id
and b.data_Cancellazione is null
 ),
movgest as (
SELECT d.liq_id,
a.movgest_ts_id,
a.movgest_ts_code, a.movgest_ts_desc, b.movgest_ts_tipo_code,
       c.movgest_anno, c.movgest_numero
FROM  siac_t_movgest_ts a, siac_d_movgest_ts_tipo b, siac_t_movgest c,
siac_r_liquidazione_movgest d
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id  
and d.movgest_ts_id=a.movgest_ts_id
AND   a.movgest_ts_tipo_id = b.movgest_ts_tipo_id
AND   c.movgest_id = a.movgest_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   p_data BETWEEN d.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
)
, pdc5 as (
select distinct 
r.liq_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
ap_ente_proprietario_id.classif_code pdc5_codice_pdc_finanziario_IV,ap_ente_proprietario_id.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_liquidazione_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree dp_ente_proprietario_id,
siac_t_class ap_ente_proprietario_id,
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
and dp_ente_proprietario_id.classif_id=a.classif_id
and ap_ente_proprietario_id.classif_id=dp_ente_proprietario_id.classif_id_padre
and d3.classif_id=ap_ente_proprietario_id.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN dp_ente_proprietario_id.validita_inizio and COALESCE(dp_ente_proprietario_id.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and dp_ente_proprietario_id.data_cancellazione is null
and ap_ente_proprietario_id.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.liq_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
ap_ente_proprietario_id.classif_code pdc4_codice_pdc_finanziario_III,ap_ente_proprietario_id.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_liquidazione_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree dp_ente_proprietario_id,
siac_t_class ap_ente_proprietario_id,
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
and dp_ente_proprietario_id.classif_id=a.classif_id
and ap_ente_proprietario_id.classif_id=dp_ente_proprietario_id.classif_id_padre
and d3.classif_id=ap_ente_proprietario_id.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN dp_ente_proprietario_id.validita_inizio and COALESCE(dp_ente_proprietario_id.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and dp_ente_proprietario_id.data_cancellazione is null
and ap_ente_proprietario_id.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
ricspesa as (
SELECT 
a.liq_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_liquidazione_class a, siac_t_class b, siac_d_class_tipo c
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
a.liq_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_liquidazione_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
), 
perss as (
SELECT 
a.liq_id ,b.classif_code v_codice_perimetro_sanitario_spesa, b.classif_desc v_descrizione_perimetro_sanitario_spesa
from siac_r_liquidazione_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
), 
pru as (
SELECT 
a.liq_id ,b.classif_code v_codice_politiche_regionali_unitarie, b.classif_desc v_descrizione_politiche_regionali_unitarie
from siac_r_liquidazione_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
/*cofog as (
select distinct r.liq_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
ap_ente_proprietario_id.classif_code codice_cofog_divisione,ap_ente_proprietario_id.classif_desc descrizione_cofog_divisione
from 
siac_r_liquidazione_class r,
siac_t_class a,siac_d_class_tipo b, 
--DIVISIONE_COFOG
siac_r_class_fam_tree dp_ente_proprietario_id,
siac_t_class ap_ente_proprietario_id
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and dp_ente_proprietario_id.classif_id=a.classif_id
and ap_ente_proprietario_id.classif_id=dp_ente_proprietario_id.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN dp_ente_proprietario_id.validita_inizio and COALESCE(dp_ente_proprietario_id.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and dp_ente_proprietario_id.data_cancellazione is null
and ap_ente_proprietario_id.data_cancellazione is null),*/
cig as (
SELECT 
a.liq_id
, a.testo v_cig
FROM   siac_r_liquidazione_attr a, siac_t_attr b
WHERE 
b.attr_code='cig' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL),
csc as (SELECT 
a.liq_id,
d.soggetto_id_da v_soggetto_csc_id,
             g.oil_relaz_tipo_code v_tipo_cessione,
             f.relaz_tipo_code v_cod_cessione,
             f.relaz_tipo_desc v_desc_cessione
      FROM siac_r_subdoc_liquidazione a,
           siac_r_subdoc_modpag b,
           siac_r_soggrel_modpag c,
           siac_r_soggetto_relaz d,
           siac_r_oil_relaz_tipo e,
           siac_d_relaz_tipo f,
           siac_d_oil_relaz_tipo g
      WHERE 
      a.ente_proprietario_id=p_ente_proprietario_id and 
            g.oil_relaz_tipo_code = 'CSC' AND
            a.subdoc_id = b.subdoc_id AND
            c.modpag_id = b.modpag_id AND
            c.soggetto_relaz_id = d.soggetto_relaz_id AND
            d.relaz_tipo_id = e.relaz_tipo_id AND
            f.relaz_tipo_id = e.relaz_tipo_id AND
            g.oil_relaz_tipo_id = e.oil_relaz_tipo_id AND
            p_data BETWEEN a.validita_inizio AND
            COALESCE(a.validita_fine, p_data) AND
            p_data BETWEEN b.validita_inizio AND
            COALESCE(b.validita_fine, p_data) AND
            p_data BETWEEN c.validita_inizio AND
            COALESCE(c.validita_fine, p_data) AND
            p_data BETWEEN d.validita_inizio AND
            COALESCE(d.validita_fine, p_data) AND
            p_data BETWEEN e.validita_inizio AND
            COALESCE(e.validita_fine, p_data) AND
            a.data_cancellazione is null AND
            b.data_cancellazione is null AND
            c.data_cancellazione is null AND
            d.data_cancellazione is null AND
            e.data_cancellazione is null AND
            f.data_cancellazione is null AND
            g.data_cancellazione is null),
cup as (
SELECT 
a.liq_id
, a.testo v_cup
FROM   siac_r_liquidazione_attr a, siac_t_attr b
WHERE 
b.attr_code='cup' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
--atto amm
/*, attoamm as (
with atmc as (
with atm as (
SELECT 
a.liq_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_liquidazione_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
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
,ap_ente_proprietario_id.classif_code cdc_cdr_code,ap_ente_proprietario_id.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class ap_ente_proprietario_id
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and ap_ente_proprietario_id.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and ap_ente_proprietario_id.data_cancellazione is null)
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
atmc.liq_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id)*/
select liq.*, contotes.validita_inizio, contotes.data_cancellazione ,
contotes.contotes_code, contotes.contotes_desc, dist.dist_code, dist.dist_desc,
sog.soggetto_id,
sog.v_codice_soggetto, 
sog.v_descrizione_soggetto,
sog.v_codice_fiscale_soggetto, 
sog.v_codice_fiscale_estero_soggetto, 
sog.v_partita_iva_soggetto,
case when modpagoil.modpag_id is null then 
modpag.soggetto_id else modpagoil.soggetto_id end v_soggetto_id_modpag,
case when modpagoil.modpag_id is null then 
modpag.modpag_id else modpagoil.modpag_id end v_modpag_cessione_id,
case when modpagoil.modpag_id is null then 
modpag.accredito_tipo_id else modpagoil.accredito_tipo_id end v_accredito_tipo_id,
case when modpagoil.modpag_id is null then 
modpag.quietanziante else modpagoil.quietanziante end v_quietanziante,
case when modpagoil.modpag_id is null then 
modpag.quietanzante_nascita_data else modpagoil.quietanzante_nascita_data end v_data_nascita_quietanziante,
case when modpagoil.modpag_id is null then 
modpag.quietanziante_nascita_luogo else modpagoil.quietanziante_nascita_luogo end v_luogo_nascita_quietanziante,
case when modpagoil.modpag_id is null then 
modpag.quietanziante_nascita_stato else modpagoil.quietanziante_nascita_stato end v_stato_nascita_quietanziante,
case when modpagoil.modpag_id is null then 
modpag.bic else modpagoil.bic end v_bic,
case when modpagoil.modpag_id is null then 
modpag.contocorrente else modpagoil.contocorrente end v_contocorrente,
case when modpagoil.modpag_id is null then 
modpag.contocorrente_intestazione else modpagoil.contocorrente_intestazione end v_intestazione_contocorrente,
case when modpagoil.modpag_id is null then 
modpag.iban else modpagoil.iban end v_iban,
case when modpagoil.modpag_id is null then 
modpag.note else modpagoil.note end v_note_modalita_pagamento,
case when modpagoil.modpag_id is null then 
modpag.data_scadenza else modpagoil.data_scadenza end v_data_scadenza_modalita_pagamento,
case when modpagoil.modpag_id is null then 
modpag.oil_relaz_tipo_code else modpagoil.oil_relaz_tipo_code end v_tipo_cessione,
case when modpagoil.modpag_id is null then 
modpag.relaz_tipo_code else modpagoil.relaz_tipo_code end v_cod_cessione,
case when modpagoil.modpag_id is null then 
modpag.relaz_tipo_desc else modpagoil.relaz_tipo_desc end v_desc_cessione,
case when modpagoil.modpag_id is null then 
modpag.soggetto_code else modpagoil.soggetto_code end v_codice_soggetto_modpag,
case when modpagoil.modpag_id is null then 
modpag.soggetto_desc else modpagoil.soggetto_desc end v_descrizione_soggetto_modpag,
case when modpagoil.modpag_id is null then 
modpag.codice_fiscale else modpagoil.codice_fiscale end v_codice_fiscale_soggetto_modpag,
case when modpagoil.modpag_id is null then 
modpag.codice_fiscale_estero else modpagoil.codice_fiscale_estero end v_codice_fiscale_estero_soggetto_modpag,
case when modpagoil.modpag_id is null then   
modpag.partita_iva else modpagoil.partita_iva end v_partita_iva_soggetto_modpag,
case when modpagoil.modpag_id is null then   
modpag.accredito_tipo_code else modpagoil.accredito_tipo_code end v_codice_tipo_accredito,
case when modpagoil.modpag_id is null then   
modpag.accredito_tipo_desc else modpagoil.accredito_tipo_desc end v_descrizione_tipo_accredito,
case when movgest.movgest_ts_tipo_code = 'T' then  movgest.movgest_ts_code else NULL::varchar end v_codice_impegno,
case when movgest.movgest_ts_tipo_code = 'T' then  movgest.movgest_ts_desc else NULL::varchar end v_descrizione_impegno,
case when movgest.movgest_ts_tipo_code = 'S' then  movgest.movgest_ts_code else NULL::varchar end v_codice_subimpegno,
case when movgest.movgest_ts_tipo_code = 'S' then  movgest.movgest_ts_desc else NULL::varchar end v_descrizione_subimpegno,
movgest.movgest_ts_tipo_code v_movgest_ts_tipo_code,movgest.movgest_anno v_anno_impegno, movgest.movgest_numero v_numero_impegno,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
ricspesa.v_codice_spesa_ricorrente, ricspesa.v_descrizione_spesa_ricorrente,
transue.v_codice_transazione_spesa_ue, transue.v_descrizione_transazione_spesa_ue,
perss.v_codice_perimetro_sanitario_spesa, perss.v_descrizione_perimetro_sanitario_spesa,
pru.v_codice_politiche_regionali_unitarie, pru.v_descrizione_politiche_regionali_unitarie,
/*cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,*/
cup.v_cup,
cig.v_cig,
/*attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,*/
csc.v_soggetto_csc_id
from liq
left join contotes on contotes.contotes_id=liq.contotes_id
left join dist on dist.dist_id=liq.dist_id
left join sog on sog.liq_id=liq.liq_id
left join modpag on modpag.modpag_id=liq.modpag_id
left join modpagoil on modpagoil.soggetto_relaz_id=liq.soggetto_relaz_id
left join movgest on movgest.liq_id=liq.liq_id
left join pdc5 on liq.liq_id=pdc5.liq_id  
left join pdc4 on liq.liq_id=pdc4.liq_id 
left join ricspesa on liq.liq_id=ricspesa.liq_id 
left join transue on liq.liq_id=transue.liq_id 
left join perss on liq.liq_id=perss.liq_id 
left join pru on liq.liq_id=pru.liq_id 
--left join cofog on liq.liq_id=cofog.liq_id  
left join cig on liq.liq_id=cig.liq_id  
left join cup on liq.liq_id=cup.liq_id  
--left join attoamm on liq.liq_id=attoamm.liq_id
left join csc  on liq.liq_id=csc.liq_id
) as tb
 ),
  cofog as (
select distinct r.liq_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
ap_ente_proprietario_id.classif_code codice_cofog_divisione,ap_ente_proprietario_id.classif_desc descrizione_cofog_divisione
from 
siac_r_liquidazione_class r,
siac_t_class a,siac_d_class_tipo b, 
--DIVISIONE_COFOG
siac_r_class_fam_tree dp_ente_proprietario_id,
siac_t_class ap_ente_proprietario_id
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and dp_ente_proprietario_id.classif_id=a.classif_id
and ap_ente_proprietario_id.classif_id=dp_ente_proprietario_id.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN dp_ente_proprietario_id.validita_inizio and COALESCE(dp_ente_proprietario_id.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and dp_ente_proprietario_id.data_cancellazione is null
and ap_ente_proprietario_id.data_cancellazione is null),
 attoamm as (
with atmc as (
with atm as (
SELECT 
a.liq_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_liquidazione_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
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
,ap_ente_proprietario_id.classif_code cdc_cdr_code,ap_ente_proprietario_id.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class ap_ente_proprietario_id
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and ap_ente_proprietario_id.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and ap_ente_proprietario_id.data_cancellazione is null)
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
atmc.liq_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id)
select
liquidaz.v_ente_proprietario_id,
liquidaz.v_ente_denominazione, liquidaz.v_anno, liquidaz.v_fase_operativa_code,
liquidaz.v_fase_operativa_desc, liquidaz.v_liq_anno,liquidaz.v_liq_numero,
liquidaz.liq_desc,
liquidaz.v_liq_emissione_data,liquidaz.v_liq_importo,liquidaz.v_liq_automatica,
liquidaz.v_liq_convalida_manuale,liquidaz.v_liq_stato_code,liquidaz.v_liq_stato_desc,
liquidaz.v_contotes_code,liquidaz.v_contotes_desc,liquidaz.v_dist_code,liquidaz.v_dist_desc,
liquidaz.v_sogg_id,liquidaz.v_codice_soggetto,liquidaz.v_descrizione_soggetto,liquidaz.v_codice_fiscale_soggetto,
liquidaz.v_codice_fiscale_estero_soggetto,liquidaz.v_partita_iva_soggetto,liquidaz.v_soggetto_id_modpag,
liquidaz.v_codice_soggetto_modpag,
liquidaz.v_descrizione_soggetto_modpag,
liquidaz.v_codice_fiscale_soggetto_modpag,
liquidaz.v_codice_fiscale_estero_soggetto_modpag,
liquidaz.v_partita_iva_soggetto_modpag,
liquidaz.v_codice_tipo_accredito,liquidaz.v_descrizione_tipo_accredito,
liquidaz.v_modpag_cessione_id,
liquidaz.v_quietanziante,liquidaz.v_data_nascita_quietanziante,
liquidaz.v_luogo_nascita_quietanziante,
liquidaz.v_stato_nascita_quietanziante,
liquidaz.v_bic,
liquidaz.v_contocorrente,
liquidaz.v_intestazione_contocorrente,
liquidaz.v_iban,
liquidaz.v_note_modalita_pagamento, --case when tb.v_note_modalita_pagamento ='' then null else tb.v_note_modalita_pagamento end v_note_modalita_pagamento,
liquidaz.v_data_scadenza_modalita_pagamento,
liquidaz.v_anno_impegno,liquidaz.v_numero_impegno,
liquidaz.v_codice_impegno,
liquidaz.v_descrizione_impegno,
liquidaz.v_codice_subimpegno,
liquidaz.v_descrizione_subimpegno,
attoamm.attoamm_tipo_code v_codice_tipo_atto_amministrativo, 
attoamm.attoamm_tipo_desc v_descrizione_tipo_atto_amministrativo, 
attoamm.attoamm_stato_desc v_descrizione_stato_atto_amministrativo,
attoamm.attoamm_anno v_anno_atto_amministrativo,
attoamm.attoamm_numero v_numero_atto_amministrativo, 
attoamm.attoamm_oggetto,
attoamm.attoamm_note,
liquidaz.v_codice_spesa_ricorrente, liquidaz.v_descrizione_spesa_ricorrente,
liquidaz.v_codice_perimetro_sanitario_spesa, liquidaz.v_descrizione_perimetro_sanitario_spesa,
liquidaz.v_codice_politiche_regionali_unitarie, liquidaz.v_descrizione_politiche_regionali_unitarie,
liquidaz.v_codice_transazione_spesa_ue, liquidaz.v_descrizione_transazione_spesa_ue,
liquidaz.v_codice_pdc_finanziario_I,
liquidaz.v_descrizione_pdc_finanziario_I,
liquidaz.v_codice_pdc_finanziario_II,
liquidaz.v_descrizione_pdc_finanziario_II,
liquidaz.v_codice_pdc_finanziario_III,
liquidaz.v_descrizione_pdc_finanziario_III,
liquidaz.v_codice_pdc_finanziario_IV  ,
liquidaz.v_descrizione_pdc_finanziario_IV,
liquidaz.v_codice_pdc_finanziario_V  ,
v_descrizione_pdc_finanziario_V,
liquidaz.v_codice_pdc_economico_I,
liquidaz.v_descrizione_pdc_economico_I,
liquidaz.v_codice_pdc_economico_II,
liquidaz.v_descrizione_pdc_economico_II,
liquidaz.v_codice_pdc_economico_III,
liquidaz.v_descrizione_pdc_economico_III,
liquidaz.v_codice_pdc_economico_IV,
liquidaz.v_descrizione_pdc_economico_IV,
liquidaz.v_codice_pdc_economico_V,
liquidaz.v_descrizione_pdc_economico_V,
cofog.codice_cofog_divisione v_codice_cofog_divisione,
cofog.descrizione_cofog_divisione v_escrizione_cofog_divisione,
cofog.codice_cofog_gruppo v_codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo v_descrizione_cofog_gruppo,
liquidaz.v_cup,
liquidaz.v_cig,
case when attoamm.cdc_cdc_code::varchar is not null then  attoamm.cdc_cdr_code::varchar else attoamm.cdr_cdr_code::varchar end v_cod_cdr_atto_amministrativo,
case when attoamm.cdc_cdc_code::varchar is not null then  attoamm.cdc_cdr_desc::varchar else attoamm.cdr_cdr_desc::varchar end v_desc_cdr_atto_amministrativo,
case when attoamm.cdc_cdc_code::varchar is not null then  attoamm.cdc_cdc_code::varchar else attoamm.cdr_cdc_code::varchar end v_cod_cdc_atto_amministrativo,
case when attoamm.cdc_cdc_code::varchar is not null then  attoamm.cdc_cdc_desc::varchar else attoamm.cdr_cdc_desc::varchar end v_desc_cdc_atto_amministrativo,
liquidaz.v_data_inizio_val_stato_liquidaz,
liquidaz.v_data_inizio_val_liquidaz,
liquidaz.v_data_creazione_liquidaz,
liquidaz.v_data_modifica_liquidaz,
liquidaz.v_tipo_cessione,
liquidaz.v_cod_cessione,
liquidaz.v_desc_cessione,
liquidaz.v_soggetto_csc_id,
liquidaz.siope_tipo_debito_code, liquidaz.siope_tipo_debito_desc,liquidaz.siope_tipo_debito_desc_bnkit,
liquidaz.siope_assenza_motivazione_code, liquidaz.siope_assenza_motivazione_desc, 
liquidaz.siope_assenza_motivazione_desc_bnkit 
 from liquidaz
left join cofog on liquidaz.liq_id=cofog.liq_id  
left join attoamm on liquidaz.liq_id=attoamm.liq_id
) as tbb;


esito:= 'Fine funzione carico liquidazione (FNC_SIAC_DWH_LIQUIDAZIONE) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico liquidazione (FNC_SIAC_DWH_LIQUIDAZIONE) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
